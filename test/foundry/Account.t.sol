// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24 <0.9.0;

import "./utils/BicoTestBase.t.sol";
import "./utils/Imports.sol";
import { ModeCode } from "../../contracts/lib/ModeLib.sol";

contract SmartAccountTest is BicoTestBase {
    SmartAccount public BOB_ACCOUNT;
    SmartAccount public  ALICE_ACCOUNT;
    SmartAccount public CHARLIE_ACCOUNT;
    Counter public COUNTER;
    uint256 public snapshotId;

    function setUp() public {
        init();
        BOB_ACCOUNT = SmartAccount(deploySmartAccount(BOB));
        ALICE_ACCOUNT = SmartAccount(deploySmartAccount(ALICE));
        CHARLIE_ACCOUNT = SmartAccount(deploySmartAccount(CHARLIE));
        COUNTER = new Counter();
    }

    function testAccountAddress() public {
        address validatorModuleAddress = address(VALIDATOR_MODULE);
        uint256 validationModuleType = uint256(ModuleType.Validation);
        uint256 saDeploymentIndex = 0;

        // Compute and assert the account addresses for BOB, ALICE, and CHARLIE
        assertEq(
            address(BOB_ACCOUNT),
            FACTORY.getAddress(validatorModuleAddress, abi.encodePacked(BOB.addr), saDeploymentIndex)
        );
        assertEq(
            address(ALICE_ACCOUNT),
            FACTORY.getAddress(validatorModuleAddress, abi.encodePacked(ALICE.addr), saDeploymentIndex)
        );
        assertEq(
            address(CHARLIE_ACCOUNT),
            FACTORY.getAddress(validatorModuleAddress, abi.encodePacked(CHARLIE.addr), saDeploymentIndex)
        );
    }

    function testAccountId() public {
        string memory expectedAccountId = "biconomy.modular-smart-account.1.0.0-alpha";
        // Assuming `accountId` is set in the `SmartAccount` constructor or through some initialization function
        assertEq(BOB_ACCOUNT.accountId(), expectedAccountId);
        assertEq(ALICE_ACCOUNT.accountId(), expectedAccountId);
        assertEq(CHARLIE_ACCOUNT.accountId(), expectedAccountId);
    }

    function testSupportsExecutionMode() public {
        // Example encodedMode, replace with actual data
        bytes32 encodedMode = keccak256(abi.encodePacked("exampleMode"));
    }

    function testSupportsModule() public {
        uint256 moduleTypeId = 1; // Example module type ID
        // Assuming the SmartAccount contract has logic to support certain module types
        assertTrue(BOB_ACCOUNT.supportsModule(moduleTypeId));
        assertTrue(ALICE_ACCOUNT.supportsModule(moduleTypeId));
        assertTrue(CHARLIE_ACCOUNT.supportsModule(moduleTypeId));
    }

    function testInstallAndCheckModule(bytes calldata dummyInitData) public {
        uint256 moduleTypeId = uint256(ModuleType.Validation);
        BOB_ACCOUNT.installModule(moduleTypeId, address(VALIDATOR_MODULE), dummyInitData);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, address(VALIDATOR_MODULE), dummyInitData));
        snapshotId = createSnapshot();
    }

    function testUninstallAndCheckModule(bytes calldata dummyInitData) public {
        revertToSnapshot(snapshotId);
        uint256 moduleTypeId = uint256(ModuleType.Validation);
        vm.assume(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, address(VALIDATOR_MODULE), dummyInitData));
        BOB_ACCOUNT.uninstallModule(moduleTypeId, address(VALIDATOR_MODULE), dummyInitData);
        assertFalse(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, address(VALIDATOR_MODULE), "0x"));
    }

    function testExecute() public {
        assertEq(COUNTER.getNumber(), 0);
        bytes32 mode = keccak256("EXECUTE_MODE");

        bytes memory counterCallData = abi.encodeWithSignature("incrementNumber()");

        bytes memory executionCalldata = abi.encode(address(COUNTER), 0, counterCallData);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);

        userOps[0] =
            buildPackedUserOp(address(ALICE_ACCOUNT), _getNonce(address(ALICE_ACCOUNT), address(VALIDATOR_MODULE)));
        userOps[0].callData = abi.encodeWithSignature("execute(bytes32,bytes)", mode, executionCalldata);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessageAndGetSignatureBytes(ALICE, userOpHash);

        ENTRYPOINT.handleOps(userOps, payable(ALICE.addr));
        assertEq(COUNTER.getNumber(), 1);
    }

    function testExecuteFromExecutor() public {
        // Similar setup to testExecute, adapted for executeFromExecutor specifics
        assertEq(COUNTER.getNumber(), 0);
        COUNTER.incrementNumber();
        assertEq(COUNTER.getNumber(), 1);

        bytes32 mode = keccak256("EXECUTOR_MODE");

        bytes memory counterCallData = abi.encodeWithSignature("decrementNumber()");

        bytes memory executionCalldata = abi.encode(address(COUNTER), 0, counterCallData);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);

        userOps[0] =
            buildPackedUserOp(address(ALICE_ACCOUNT), _getNonce(address(ALICE_ACCOUNT), address(VALIDATOR_MODULE)));
        userOps[0].callData = abi.encodeWithSignature("executeFromExecutor(bytes32,bytes)", mode, executionCalldata);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessageAndGetSignatureBytes(ALICE, userOpHash);

        ENTRYPOINT.handleOps(userOps, payable(ALICE.addr));
        assertEq(COUNTER.getNumber(), 0);
    }

    function testExecuteUserOp() public {
        assertEq(COUNTER.getNumber(), 0);
        bytes32 mode = keccak256("EXECUTOR_MODE");

        bytes memory counterCallData = abi.encodeWithSignature("incrementNumber()");

        bytes memory executionCalldata = abi.encode(address(COUNTER), 0, counterCallData);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);

        userOps[0] =
            buildPackedUserOp(address(ALICE_ACCOUNT), _getNonce(address(ALICE_ACCOUNT), address(VALIDATOR_MODULE)));

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Review: Note discarded
        // required from entrypoint or self
        // BOB_ACCOUNT.executeUserOp(userOps[0], userOpHash);
    }

    function testIsValidSignatureWithSender() public {
        bytes memory data = abi.encodeWithSignature("incrementNumber()");
        bytes4 result = VALIDATOR_MODULE.isValidSignatureWithSender(ALICE.addr, keccak256(data), "0x");
    }
}
