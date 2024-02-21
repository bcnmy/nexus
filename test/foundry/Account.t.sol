// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24 <0.9.0;

import "./Imports.sol";

contract SmartAccountTest is PRBTest, StdCheats {
    SmartAccount public smartAccount;

    function setUp() public {
        smartAccount = new SmartAccount();
    }

    function testAccountId() public {
        string memory expectedAccountId = "biconomy.modular-smart-account.3.0.0-alpha";
        // Assuming `accountId` is set in the `SmartAccount` constructor or through some initialization function
        assertEq(smartAccount.accountId(), expectedAccountId);
    }

    function testSupportsAccountMode() public {
        // Example encodedMode, replace with actual data
        bytes32 encodedMode = keccak256("exampleMode");
        // Assuming the SmartAccount contract has logic to support certain modes
        assertTrue(smartAccount.supportsAccountMode(encodedMode));
    }

    function testSupportsModule() public {
        uint256 moduleTypeId = 1; // Example module type ID
        // Assuming the SmartAccount contract has logic to support certain module types
        assertTrue(smartAccount.supportsModule(moduleTypeId));
    }

    function testInstallAndCheckModule(
        uint256 dummyModuleType,
        address dummyModuleAddress,
        bytes calldata dummyInitData
    )
        public
    {
        vm.assume(dummyModuleAddress != address(0));
        vm.assume(dummyModuleType != 0);
        smartAccount.installModule(dummyModuleType, dummyModuleAddress, dummyInitData);
        assertTrue(smartAccount.isModuleInstalled(dummyModuleType, dummyModuleAddress, dummyInitData));
    }

    function testUninstallAndCheckModule(
        uint256 dummyModuleType,
        address dummyModuleAddress,
        bytes calldata dummyInitData
    )
        public
    {
        smartAccount.uninstallModule(dummyModuleType, dummyModuleAddress, dummyInitData);
        // assertFalse(smartAccount.isModuleInstalled(dummyModuleType, dummyModuleAddress, "0x"));
    }

    function testExecute() public {
        // Prepare test data
        bytes32 mode = keccak256("TEST_MODE");
        bytes memory executionCalldata = abi.encodeWithSignature("testFunction()");

        // Since the execute function doesn't have actual logic, can't directly test its effects.
        smartAccount.execute(mode, executionCalldata);
    }

    function testExecuteFromExecutor() public {
        // Similar setup to testExecute, adapted for executeFromExecutor specifics
        bytes32 mode = keccak256("EXECUTOR_MODE");
        bytes memory executionCalldata = abi.encodeWithSignature("executorFunction()");

        // Since the execute function doesn't have actual logic, can't directly test its effects.
        bytes[] memory res = smartAccount.executeFromExecutor(mode, executionCalldata);
        assertEq(res.length, 0);
    }

    function testExecuteUserOp() public {
        // Mock a PackedUserOperation struct
        PackedUserOperation memory userOp = PackedUserOperation({
            sender: address(this),
            nonce: 1,
            initCode: "",
            callData: abi.encodeWithSignature("test()"),
            accountGasLimits: bytes32(0),
            preVerificationGas: 0,
            gasFees: bytes32(0),
            paymasterAndData: "",
            signature: ""
        });
        bytes32 userOpHash = keccak256(abi.encode(userOp));

        smartAccount.executeUserOp(userOp, userOpHash);
    }

    function testValidateUserOp() public {
        MockValidator mockValidator = new MockValidator();

        PackedUserOperation memory userOp = PackedUserOperation({
            sender: address(this),
            nonce: getNonce(address(this), address(mockValidator)),
            initCode: "",
            callData: abi.encodeWithSignature("test()"),
            accountGasLimits: bytes32(0),
            preVerificationGas: 0,
            gasFees: bytes32(0),
            paymasterAndData: "",
            signature: ""
        });
        bytes32 userOpHash = keccak256(abi.encode(userOp));

        uint256 missingAccountFunds = 0;
        uint256 res = smartAccount.validateUserOp(userOp, userOpHash, missingAccountFunds);
        assertEq(res, 0);
    }

    // HELPERS
    // @TODO : move to a common file
    // @TODO : make the proper nonce retrieval via EP
    function getNonce(address account, address validator) internal returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(address(validator))));
        //nonce = entrypoint.getNonce(address(account), key);
        nonce = 1 | (uint256(key) << 64);
    }
}
