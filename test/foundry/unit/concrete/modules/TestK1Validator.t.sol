// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";

/// @title TestK1Validator
/// @notice Unit tests for the K1Validator contract
contract TestK1Validator is NexusTest_Base {
    K1Validator private validator;
    bytes private initData;
    PackedUserOperation private userOp;
    bytes32 private userOpHash;
    bytes private signature;

    /// @notice Sets up the testing environment by deploying the contract and initializing variables
    function setUp() public {
        init();

        // Deploy a new K1Validator instance
        validator = new K1Validator();

        // Prepare the call data for installing the validator module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(validator),
            abi.encodePacked(BOB_ADDRESS)
        );

        // Create an execution array with the installation call data
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Build a packed user operation for the installation
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        // Execute the user operation to install the validator module
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Verify that the validator module is installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(validator), ""));

        // Encode the initialization data with the owner address
        initData = abi.encodePacked(BOB_ADDRESS);

        // Set up a mock PackedUserOperation for testing
        userOp = buildPackedUserOp(address(BOB_ACCOUNT), 0);

        // Create a user operation hash
        userOpHash = ENTRYPOINT.getUserOpHash(userOp);

        // Generate a signature for the user operation hash
        signature = signMessage(BOB, userOpHash);
    }

    /// @notice Tests the onInstall function with valid initialization data
    function test_OnInstall_Success() public {
        // Simulate a transaction from ALICE_ACCOUNT
        prank(address(ALICE_ACCOUNT));

        // Call the onInstall function with the initialization data
        validator.onInstall(abi.encodePacked(ALICE_ADDRESS));

        // Verify that the owner was correctly set in the smartAccountOwners mapping
        assertEq(validator.smartAccountOwners(address(ALICE_ACCOUNT)), ALICE_ADDRESS, "Owner should be correctly set");
    }

    /// @notice Tests the onInstall function with no initialization data, expecting a revert
    function test_OnInstall_NoOwnerProvided() public {
        // Expect the NoOwnerProvided error to be thrown
        vm.expectRevert(abi.encodeWithSignature("NoOwnerProvided()"));

        // Call the onInstall function with empty data
        validator.onInstall("");
    }

    /// @notice Tests the onUninstall function to ensure the owner is removed
    function test_OnUninstall_Success() public {
        // Find the previous module for uninstallation
        (address[] memory array, ) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(validator);
        address prev = SentinelListHelper.findPrevious(array, remove);
        if (prev == address(0)) prev = address(0x01); // Default to sentinel address if not found

        // Prepare call data for uninstalling the module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(validator),
            abi.encode(prev, "")
        );

        // Create an execution array with the uninstallation call data
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Build a packed user operation for the uninstallation
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        // Execute the user operation to uninstall the validator module
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Verify that the owner was removed from the smartAccountOwners mapping
        assertEq(validator.smartAccountOwners(address(BOB_ACCOUNT)), address(0), "Owner should be removed");

        // Verify that the validator module is no longer installed
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(validator), ""));
    }

    /// @notice Tests the isInitialized function to check if the smart account is initialized
    function test_IsInitialized() public {
        // Verify that the smart account is initialized
        assertTrue(validator.isInitialized(address(BOB_ACCOUNT)), "Smart account should be initialized");
    }

    /// @notice Tests the validateUserOp function with a valid signature
    function test_ValidateUserOp_Success() public {
        prank(address(BOB_ACCOUNT));

        // Install the owner first
        validator.onInstall(initData);

        // Set the signature in the userOp
        userOp.signature = signature;

        // Call the validateUserOp function
        uint256 validationResult = validator.validateUserOp(userOp, userOpHash);

        // Verify that the validation was successful
        assertEq(validationResult, VALIDATION_SUCCESS, "Validation should be successful");
    }

    /// @notice Tests the validateUserOp function with an invalid signature
    function test_ValidateUserOp_Failure() public {
        prank(address(BOB_ACCOUNT));

        // Install the owner first
        validator.onInstall(initData);

        // Set an invalid signature in the userOp
        userOp.signature = abi.encodePacked(signMessage(BOB, keccak256(abi.encodePacked("invalid"))));

        // Call the validateUserOp function
        uint256 validationResult = validator.validateUserOp(userOp, userOpHash);

        // Verify that the validation failed
        assertEq(validationResult, VALIDATION_FAILED, "Validation should fail");
    }

    /// @notice Tests the isValidSignatureWithSender function with a valid signature
    function test_IsValidSignatureWithSender_Success() public {
        startPrank(address(BOB_ACCOUNT));

        // Generate a hash for the signed message
        bytes32 originalHash = keccak256(abi.encodePacked("123"));

        // Sign the message using BOB's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, toERC1271HashPersonalSign(originalHash));
        bytes memory signedMessage = abi.encodePacked(r, s, v);
        bytes memory completeSignature = abi.encodePacked(address(validator), signedMessage);

        // Call the isValidSignature function
        bytes4 result = BOB_ACCOUNT.isValidSignature(originalHash, completeSignature);

        stopPrank();

        // Verify that the result is ERC1271_MAGICVALUE
        assertEq(result, ERC1271_MAGICVALUE, "Signature should be valid");
    }

    /// @notice Tests the isValidSignatureWithSender function with an invalid signature
    function test_IsValidSignatureWithSender_Failure() public {
        prank(address(BOB_ACCOUNT));

        // Install the owner first
        validator.onInstall(initData);

        // Call the isValidSignatureWithSender function with an invalid signature
        bytes4 result = validator.isValidSignatureWithSender(
            address(BOB_ACCOUNT),
            userOpHash,
            abi.encodePacked(signMessage(BOB, keccak256(abi.encodePacked("invalid"))))
        );

        // Verify that the result is ERC1271_INVALID
        assertEq(result, ERC1271_INVALID, "Signature should be invalid");
    }

    /// @notice Tests the name function to return the correct contract name
    function test_Name() public {
        // Call the name function
        string memory contractName = validator.name();

        // Verify that the contract name is correct
        assertEq(contractName, "K1Validator", "Contract name should be 'K1Validator'");
    }

    /// @notice Tests the version function to return the correct contract version
    function test_Version() public {
        // Call the version function
        string memory contractVersion = validator.version();

        // Verify that the contract version is correct
        assertEq(contractVersion, "0.0.1", "Contract version should be '0.0.1'");
    }

    /// @notice Tests the isModuleType function to return the correct module type
    function test_IsModuleType() public {
        // Call the isModuleType function with MODULE_TYPE_VALIDATOR
        bool result = validator.isModuleType(MODULE_TYPE_VALIDATOR);

        // Verify that the result is true
        assertTrue(result, "Module type should be VALIDATOR");

        // Call the isModuleType function with an invalid type
        result = validator.isModuleType(9999);

        // Verify that the result is false
        assertFalse(result, "Module type should be invalid");
    }

    /// @notice Generates an ERC-1271 hash for personal sign
    /// @param childHash The child hash
    /// @return The ERC-1271 hash for personal sign
    function toERC1271HashPersonalSign(bytes32 childHash) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Nexus"),
                keccak256("0.0.1"),
                block.chainid,
                address(BOB_ACCOUNT)
            )
        );
        bytes32 parentStructHash = keccak256(abi.encode(keccak256("PersonalSign(bytes prefixed)"), childHash));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, parentStructHash));
    }
}
