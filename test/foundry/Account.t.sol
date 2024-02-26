// // SPDX-License-Identifier: UNLICENSED
// pragma solidity >=0.8.24 <0.9.0;

// import "./utils/BicoTestBase.t.sol";

// contract SmartAccountTest is BicoTestBase {
//     function setUp() public override {
//         super.setUp();
//     }

//     function testAccountId() public {
//         string memory expectedAccountId = "biconomy.modular-smart-account.3.0.0-alpha";
//         // Assuming `accountId` is set in the `SmartAccount` constructor or through some initialization function
//         assertEq(smartAccount.accountId(), expectedAccountId);
//     }

//     function testSupportsAccountMode() public {
//         // Example encodedMode, replace with actual data
//         bytes32 encodedMode = keccak256("exampleMode");
//         // Assuming the SmartAccount contract has logic to support certain modes
//         assertTrue(smartAccount.supportsAccountMode(encodedMode));
//     }

//     function testSupportsModule() public {
//         uint256 moduleTypeId = 1; // Example module type ID
//         // Assuming the SmartAccount contract has logic to support certain module types
//         assertTrue(smartAccount.supportsModule(moduleTypeId));
//     }

//     function testInstallAndCheckModule(
//         uint256 dummyModuleType,
//         address dummyModuleAddress,
//         bytes calldata dummyInitData
//     )
//         public
//     {
//         vm.assume(dummyModuleAddress != address(0));
//         vm.assume(dummyModuleType != 0);
//         smartAccount.installModule(dummyModuleType, dummyModuleAddress, dummyInitData);
//         assertTrue(smartAccount.isModuleInstalled(dummyModuleType, dummyModuleAddress, dummyInitData));
//     }

//     function testUninstallAndCheckModule(
//         uint256 dummyModuleType,
//         address dummyModuleAddress,
//         bytes calldata dummyInitData
//     )
//         public
//     {
//         smartAccount.uninstallModule(dummyModuleType, dummyModuleAddress, dummyInitData);
//         // assertFalse(smartAccount.isModuleInstalled(dummyModuleType, dummyModuleAddress, "0x"));
//     }

//     function testExecute() public {
//         // Prepare test data
//         bytes32 mode = keccak256("TEST_MODE");
//         uint256 amountToSend = 1 ether;
//         uint256 targetBalanceBefore = address(target).balance;

//         bytes memory callData = "0x";
//         bytes memory packedCalldata = abi.encodePacked(target, amountToSend, callData);

//         // Since the execute function doesn't have actual logic, can't directly test its effects.
//         smartAccount.execute(mode, packedCalldata);
//         assertEq(address(target).balance, targetBalanceBefore + amountToSend);
//     }

//     function testExecuteFromExecutor() public {
//         // Similar setup to testExecute, adapted for executeFromExecutor specifics
//         bytes32 mode = keccak256("EXECUTOR_MODE");
//         bytes memory executionCalldata = abi.encodeWithSignature("executorFunction()");

//         // Since the execute function doesn't have actual logic, can't directly test its effects.
//         bytes[] memory res = smartAccount.executeFromExecutor(mode, executionCalldata);
//         assertEq(res.length, 0);
//     }

//     function testExecuteUserOp() public {
//         // Mock a PackedUserOperation struct
//         PackedUserOperation memory userOp = PackedUserOperation({
//             sender: address(this),
//             nonce: 1,
//             initCode: "",
//             callData: abi.encodeWithSignature("test()"),
//             accountGasLimits: bytes32(0),
//             preVerificationGas: 0,
//             gasFees: bytes32(0),
//             paymasterAndData: "",
//             signature: ""
//         });
//         bytes32 userOpHash = keccak256(abi.encode(userOp));

//         smartAccount.executeUserOp(userOp, userOpHash);
//     }

//     function testValidateUserOp() public {
//         PackedUserOperation memory userOp = PackedUserOperation({
//             sender: address(this),
//             nonce: _getNonce(address(smartAccount), address(mockValidator)),
//             initCode: "",
//             callData: abi.encodeWithSignature("test()"),
//             accountGasLimits: bytes32(0),
//             preVerificationGas: 0,
//             gasFees: bytes32(0),
//             paymasterAndData: "",
//             signature: ""
//         });
//         bytes32 userOpHash = keccak256(abi.encode(userOp));

//         uint256 missingAccountFunds = 0;
//         uint256 res = smartAccount.validateUserOp(userOp, userOpHash, missingAccountFunds);
//         assertEq(res, 0);
//     }

//     function testExecuteViaEntryPoint() public {
//         uint256 amountToSend = 1 ether;
//         uint256 targetBalanceBefore = address(target).balance;

//         // Mock a target address and call data
//         PackedUserOperation memory userOp = PackedUserOperation({
//             sender: address(smartAccount),
//             nonce: _getNonce(address(smartAccount), address(mockValidator)),
//             initCode: "",
//             callData: abi.encodeCall(
//                 IAccountExecution.execute, (keccak256("TEST_MODE"), abi.encodePacked(target, amountToSend, "0x"))
//                 ),
//             accountGasLimits: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
//             preVerificationGas: 2e6,
//             gasFees: bytes32(abi.encodePacked(uint128(2e6), uint128(2e6))),
//             paymasterAndData: "",
//             signature: ""
//         });
//         bytes32 userOpHash = keccak256(abi.encode(userOp));

//         PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
//         userOps[0] = userOp;

//         // Handle Ops via entrypoint
//         entrypoint.handleOps(userOps, alice);

//         assertEq(address(target).balance, targetBalanceBefore + amountToSend);
//     }
// }
