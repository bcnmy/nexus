// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";
import { ERC1271_MAGICVALUE, ERC1271_INVALID } from "contracts/types/Constants.sol";

/// @title TestK1Validator
/// @notice Unit tests for the K1Validator contract
contract TestK1Validator is NexusTest_Base {
    K1Validator private validator;
    PackedUserOperation private userOp;
    bytes32 private userOpHash;
    bytes private signature;
    MockSafe1271Caller mockSafe1271Caller;

    /// @notice Sets up the testing environment by deploying the contract and initializing variables
    function setUp() public {
        init();

        // Deploy a new K1Validator instance
        validator = new K1Validator();
        mockSafe1271Caller = new MockSafe1271Caller();

        bytes memory k1ValidatorSetupData = abi.encodePacked(
            BOB_ADDRESS, //owner
            address(mockSafe1271Caller) //safe sender
        );
        // Prepare the call data for installing the validator module
        bytes memory callData1 =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(validator), k1ValidatorSetupData);
        bytes memory callData2 =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockSafe1271Caller), "");            

        // Create an execution array with the installation call data
        Execution[] memory execution = new Execution[](2);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData1);
        execution[1] = Execution(address(BOB_ACCOUNT), 0, callData2);

        // Build a packed user operation for the installation
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        // Execute the user operation to install the modules
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Set up a mock PackedUserOperation for testing
        userOp = buildPackedUserOp(address(BOB_ACCOUNT), 0);

        // Create a user operation hash
        userOpHash = ENTRYPOINT.getUserOpHash(userOp);

        // Generate a signature for the user operation hash
        signature = signMessage(BOB, userOpHash);
    }

    /// @notice Ensures the setUp function works as expected
    function test_SetUpState() public {
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(validator), "Module should be installed in setUp"));
    }

    /// @notice Tests the onInstall function with valid initialization data
    function test_OnInstall_Success() public {
        prank(address(ALICE_ACCOUNT));

        validator.onInstall(abi.encodePacked(ALICE_ADDRESS));

        assertEq(validator.smartAccountOwners(address(ALICE_ACCOUNT)), ALICE_ADDRESS, "Owner should be correctly set");
    }

    /// @notice Tests the onInstall function with no initialization data, expecting a revert
    function test_RevertWhen_OnInstall_NoOwnerProvided() public {
        vm.expectRevert(abi.encodeWithSignature("NoOwnerProvided()"));

        validator.onInstall("");
    }

    /// @notice Tests the onUninstall function to ensure the owner is removed
    function test_OnUninstall_Success() public {
        (address[] memory array,) = BOB_ACCOUNT.getValidatorsPaginated(address(0x1), 100);
        address remove = address(validator);
        address prev = SentinelListHelper.findPrevious(array, remove);
        if (prev == address(0)) prev = address(0x01);

        bytes memory k1OnUninstallData = bytes("");
        bytes memory callData = abi.encodeWithSelector(IModuleManager.uninstallModule.selector, MODULE_TYPE_VALIDATOR, address(validator), abi.encode(prev, k1OnUninstallData));

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(validator.smartAccountOwners(address(BOB_ACCOUNT)), address(0), "Owner should be removed");
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(validator), ""));
    }

    /// @notice Tests the isInitialized function to check if the smart account is initialized
    function test_IsInitialized() public {
        assertTrue(validator.isInitialized(address(BOB_ACCOUNT)), "Smart account should be initialized");
    }

    /// @notice Tests the validateUserOp function with a valid signature
    function test_ValidateUserOp_toEthSignedMessageHash_Success() public {
        prank(address(BOB_ACCOUNT));

        userOp.signature = signature;

        uint256 validationResult = validator.validateUserOp(userOp, userOpHash);

        assertEq(validationResult, VALIDATION_SUCCESS, "Validation should be successful");
    }

    /// @notice Tests the validateUserOp function with an invalid signature
    function test_ValidateUserOp_Failure() public {
        prank(address(BOB_ACCOUNT));

        userOp.signature = abi.encodePacked(signMessage(BOB, keccak256(abi.encodePacked("invalid"))));

        uint256 validationResult = validator.validateUserOp(userOp, userOpHash);

        assertEq(validationResult, VALIDATION_FAILED, "Validation should fail");
    }

    /// @notice Tests the isValidSignatureWithSender function with a valid signature
    function test_IsValidSignatureWithSender_Success() public {
        startPrank(address(BOB_ACCOUNT));

        bytes32 originalHash = keccak256(abi.encodePacked("valid message"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, toERC1271HashPersonalSign(originalHash));
        bytes memory signedMessage = abi.encodePacked(r, s, v);
        bytes memory completeSignature = abi.encodePacked(address(validator), signedMessage);

        bytes4 result = BOB_ACCOUNT.isValidSignature(originalHash, completeSignature);

        stopPrank();

        assertEq(result, ERC1271_MAGICVALUE, "Signature should be valid");
    }

    /// @notice Tests the validateUserOp function with a valid signature
    function test_ValidateUserOp_Success() public {
        startPrank(address(BOB_ACCOUNT));

        bytes32 originalHash = keccak256(abi.encodePacked("123"));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, originalHash);

        userOp.signature = abi.encodePacked(r, s, v);

        uint256 res = validator.validateUserOp(userOp, originalHash);

        stopPrank();

        assertEq(res, VALIDATION_SUCCESS, "Signature should be valid");
    }

    /// @notice Tests the isValidSignatureWithSender function with an invalid signature
    function test_IsValidSignatureWithSender_Failure() public {
        prank(address(BOB_ACCOUNT));

        vm.expectRevert(); //it should revert as last try to check if it's an RPC call which reverts if called on-chain
        validator.isValidSignatureWithSender(address(BOB_ACCOUNT), userOpHash, abi.encodePacked(signMessage(BOB, keccak256(abi.encodePacked("invalid")))));
    }

    /// @notice Tests the transferOwnership function to ensure ownership is transferred correctly
    function test_TransferOwnership_Success() public {
        startPrank(address(BOB_ACCOUNT));

        // Transfer ownership to ALICE
        validator.transferOwnership(ALICE_ADDRESS);

        // Verify that the ownership is transferred
        assertEq(validator.smartAccountOwners(address(BOB_ACCOUNT)), ALICE_ADDRESS, "Ownership should be transferred to ALICE");

        stopPrank();
    }

    /// @notice Tests the transferOwnership function to ensure it reverts when transferring to the zero address
    function test_RevertWhen_TransferOwnership_ToZeroAddress() public {
        startPrank(address(BOB_ACCOUNT));

        // Expect the ZeroAddressNotAllowed error to be thrown
        vm.expectRevert(ZeroAddressNotAllowed.selector);

        // Attempt to transfer ownership to the zero address
        validator.transferOwnership(address(0));

        stopPrank();
    }

    /// @notice Tests the name function to return the correct contract name
    function test_Name() public {
        string memory contractName = validator.name();

        assertEq(contractName, "K1Validator", "Contract name should be 'K1Validator'");
    }

    /// @notice Tests the version function to return the correct contract version
    function test_Version() public {
        string memory contractVersion = validator.version();

        assertEq(contractVersion, "1.0.0-beta", "Contract version should be '1.0.0-beta'");
    }

    /// @notice Tests the isModuleType function to return the correct module type
    function test_IsModuleType() public {
        bool result = validator.isModuleType(MODULE_TYPE_VALIDATOR);

        assertTrue(result, "Module type should be VALIDATOR");

        result = validator.isModuleType(9999);

        assertFalse(result, "Module type should be invalid");
    }

    /// @notice Ensures the transferOwnership function reverts when transferring to a contract address
    function test_RevertWhen_TransferOwnership_ToContract() public {
        startPrank(address(BOB_ACCOUNT));

        // Deploy a dummy contract to use as the new owner
        address dummyContract = address(new K1Validator());

        // Expect the NewOwnerIsContract error to be thrown
        vm.expectRevert(K1Validator.NewOwnerIsContract.selector);

        // Attempt to transfer ownership to the dummy contract address
        validator.transferOwnership(dummyContract);

        stopPrank();
    }

    /// @notice Tests that a valid signature with a valid 's' value is accepted
    function test_ValidateUserOp_ValidSignature() public {
        startPrank(address(BOB_ACCOUNT));

        bytes32 originalHash = keccak256(abi.encodePacked("valid message"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, originalHash);

        // Ensure 's' is in the lower range
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid 's' value");

        userOp.signature = abi.encodePacked(r, s, v);

        uint256 res = validator.validateUserOp(userOp, originalHash);

        stopPrank();

        assertEq(res, VALIDATION_SUCCESS, "Valid signature should be accepted");
    }

    /// @notice Tests that a signature with an invalid 's' value is rejected
    function test_ValidateUserOp_InvalidSValue() public {
        startPrank(address(BOB_ACCOUNT));

        bytes32 originalHash = keccak256(abi.encodePacked("invalid message"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, originalHash);

        // Ensure 's' is in the upper range (invalid)
        if (uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            s = bytes32(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1); // Set an invalid 's' value
        }

        userOp.signature = abi.encodePacked(r, s, v);

        uint256 res = validator.validateUserOp(userOp, originalHash);

        stopPrank();

        assertEq(res, VALIDATION_FAILED, "Signature with invalid 's' value should be rejected");
    }

    /// @notice Tests that a valid signature with a valid 's' value is accepted for isValidSignatureWithSender
    function test_IsValidSignatureWithSender_ValidSignature() public {
        startPrank(address(BOB_ACCOUNT));

        // Generate a valid message hash
        bytes32 originalHash = keccak256(abi.encodePacked("valid message"));

        // Sign the message hash with BOB's private key
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, toERC1271HashPersonalSign(originalHash));

        // Ensure 's' is in the lower range
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "Invalid 's' value");

        // Construct the signature from r, s, v
        bytes memory signedMessage = abi.encodePacked(r, s, v);

        // Call isValidSignatureWithSender on the validator contract with the correct parameters
        bytes4 result = validator.isValidSignatureWithSender(address(BOB_ACCOUNT), originalHash, signedMessage);

        stopPrank();

        // Ensure the result is the expected ERC1271_MAGICVALUE
        assertEq(result, ERC1271_MAGICVALUE, "Valid signature should be accepted");
    }

    /// @notice Tests that a signature with an invalid 's' value is rejected for isValidSignatureWithSender
    function test_IsValidSignatureWithSender_InvalidSValue() public {
        startPrank(address(BOB_ACCOUNT));

        bytes32 originalHash = keccak256(abi.encodePacked("invalid message"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, originalHash);

        // Ensure 's' is in the upper range (invalid)
        if (uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            s = bytes32(0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A1); // Set an invalid 's' value
        }

        bytes memory signedMessage = abi.encodePacked(r, s, v);
        bytes memory completeSignature = abi.encodePacked(address(validator), signedMessage);

        bytes4 result = BOB_ACCOUNT.isValidSignature(originalHash, completeSignature);

        stopPrank();

        assertEq(result, ERC1271_INVALID, "Signature with invalid 's' value should be rejected");
    }

    function test_IsValidSignatureWithSender_SafeCaller_Success() public {
        assertEq(mockSafe1271Caller.balanceOf(address(BOB_ACCOUNT)), 0);

        vm.startPrank(address(BOB_ACCOUNT));
       
       // alternative way of setting mockSafe1271Caller as safe sender in k1 validator
       // commented out as it was already set at setup
       // validator.addSafeSender(address(mockSafe1271Caller));

        bytes32 mockUserOpHash = keccak256(abi.encodePacked("123"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, mockUserOpHash);
        bytes memory userOpSig = abi.encodePacked(r, s, v);

        bytes memory verifData = bytes("some data");
        bytes32 secure1271Hash = keccak256(
            abi.encode(
                address(BOB_ACCOUNT),
                block.chainid,
                keccak256(verifData)
            )
        );
        (v,r,s) = vm.sign(BOB.privateKey, secure1271Hash);

        userOp.signature = abi.encode(
            verifData,
            abi.encodePacked(address(validator), r,s,v), // erc1271sig
            userOpSig
        );

        uint256 res = mockSafe1271Caller.validateUserOp(userOp, mockUserOpHash);

        stopPrank();

        assertEq(res, VALIDATION_SUCCESS, "Signature should be valid");
        assertEq(mockSafe1271Caller.balanceOf(address(BOB_ACCOUNT)), 1);
    }

    /// @notice Generates an ERC-1271 hash for personal sign
    /// @param childHash The child hash
    /// @return The ERC-1271 hash for personal sign
    function toERC1271HashPersonalSign(bytes32 childHash) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Nexus"),
                keccak256("1.0.0-beta"),
                block.chainid,
                address(BOB_ACCOUNT)
            )
        );
        bytes32 parentStructHash = keccak256(abi.encode(keccak256("PersonalSign(bytes prefixed)"), childHash));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, parentStructHash));
    }
}
