// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24 <0.9.0;

import "./utils/BicoTestBase.t.sol";
import "./utils/Imports.sol";
import { ModeCode, ModeLib } from "../../contracts/lib/ModeLib.sol";
import { ExecLib } from "../../contracts/lib/ExecLib.sol";

contract SmartAccountTest is BicoTestBase {
    SmartAccount public BOB_ACCOUNT;
    SmartAccount public ALICE_ACCOUNT;
    SmartAccount public CHARLIE_ACCOUNT;
    Counter public COUNTER;
    uint256 public snapshotId;
    address public mockNewValidator;

    function setUp() public {
        init();
        BOB_ACCOUNT = SmartAccount(deploySmartAccount(BOB));
        ALICE_ACCOUNT = SmartAccount(deploySmartAccount(ALICE));
        CHARLIE_ACCOUNT = SmartAccount(deploySmartAccount(CHARLIE));
        COUNTER = new Counter();
        mockNewValidator = address(new MockValidator());
    }

    function testAccountAddress() public {
        address validatorModuleAddress = address(VALIDATOR_MODULE);
        uint256 validationModuleType = uint256(MODULE_TYPE_VALIDATOR);
        uint256 saDeploymentIndex = 0;

        // Compute and assert the account addresses for BOB, ALICE, and CHARLIE
        assertEq(
            address(BOB_ACCOUNT),
            FACTORY.getCounterFactualAddress(validatorModuleAddress, abi.encodePacked(BOB.addr), saDeploymentIndex)
        );
        assertEq(
            address(ALICE_ACCOUNT),
            FACTORY.getCounterFactualAddress(validatorModuleAddress, abi.encodePacked(ALICE.addr), saDeploymentIndex)
        );
        assertEq(
            address(CHARLIE_ACCOUNT),
            FACTORY.getCounterFactualAddress(validatorModuleAddress, abi.encodePacked(CHARLIE.addr), saDeploymentIndex)
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
        assertEq(BOB_ACCOUNT.supportsExecutionMode(ModeLib.encodeSimpleSingle()), true);
        assertEq(BOB_ACCOUNT.supportsExecutionMode(ModeLib.encodeSimpleBatch()), true);
    }

    function testSupportsModule() public {
        uint256 moduleTypeId = MODULE_TYPE_VALIDATOR;
        // SmartAccount (by means of deployment and implementation) has logic to support certain module types
        assertTrue(BOB_ACCOUNT.supportsModule(moduleTypeId));
        assertTrue(ALICE_ACCOUNT.supportsModule(moduleTypeId));
        assertTrue(CHARLIE_ACCOUNT.supportsModule(moduleTypeId));
    }

     // TODO: prank should be removed and it should happen from real userOp via EP / account calling itself
    function testInstallAndCheckModule(bytes calldata dummyInitData) public {
        uint256 moduleTypeId = uint256(MODULE_TYPE_VALIDATOR);
        prank(address(ENTRYPOINT));
        BOB_ACCOUNT.installModule(moduleTypeId, mockNewValidator, dummyInitData);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, mockNewValidator, dummyInitData));
        snapshotId = createSnapshot();
    }

    // TODO: prank should be removed and it should happen from real userOp via EP / account calling itself
    // Review onUninstall does not work (sending wrong 'prev')
    // function testUninstallAndCheckModule(bytes calldata dummyInitData) public {
    //     revertToSnapshot(snapshotId);
    //     uint256 moduleTypeId = uint256(MODULE_TYPE_VALIDATOR); // comes from own defined enum
    //     // vm.assume(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, mockNewValidator, dummyInitData));
    //     bytes memory uninstallData = abi.encode(address(VALIDATOR_MODULE), dummyInitData);
    //     prank(address(ENTRYPOINT));
    //     BOB_ACCOUNT.uninstallModule(moduleTypeId, mockNewValidator, uninstallData);
    //     assertFalse(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, mockNewValidator, "0x"));
    // }

    function testExecute() public {
        assertEq(COUNTER.getNumber(), 0);
        bytes32 mode = keccak256("EXECUTE_MODE");

        bytes memory counterCallData = abi.encodeWithSignature("incrementNumber()");

        bytes memory executionCalldata = abi.encode(address(COUNTER), 0, counterCallData);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);

        userOps[0] =
            buildPackedUserOp(address(ALICE_ACCOUNT), _getNonce(address(ALICE_ACCOUNT), address(VALIDATOR_MODULE)));
        userOps[0].callData = abi.encodeWithSignature("execute(bytes32,bytes)", mode, executionCalldata);

bytes memory userOpCalldata = abi.encodeCall(
            IAccountExecution.execute,
            (
                ModeLib.encodeSimpleSingle(),
                ExecLib.encodeSingle(
                    address(COUNTER),
                    uint256(0),
                    counterCallData
                )
            )
        );

        userOps[0].callData = userOpCalldata;

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
