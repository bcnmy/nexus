// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../shared/TestAccountExecution_Base.t.sol";

/// @title Gas benchmark tests for AccountExecution
contract TestGas_ExecutionHelper is TestAccountExecution_Base {
    MockExecutor public mockExecutor;

    function setUp() public {
        setUpTestAccountExecution_Base();

        mockExecutor = new MockExecutor();

        // Install MockExecutor as executor module on BOB_ACCOUNT
        bytes memory callDataInstall = abi.encodeWithSelector(IModuleManager.installModule.selector, uint256(2), address(mockExecutor), "");
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callDataInstall);

        PackedUserOperation[] memory userOpsInstall = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            execution,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(userOpsInstall, payable(address(BOB.addr)));
    }

    // Execute Tests
    function test_Gas_Execute_Single() public {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(0), 0, "");

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for single empty execution: ", gasUsed);
    }

    function test_Gas_Execute_TrySingle() public {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(0), 0, "");

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for try single empty execution: ", gasUsed);
    }

    function test_Gas_Execute_Batch() public {
        Execution[] memory executions = new Execution[](10);
        for (uint256 i = 0; i < executions.length; i++) {
            executions[i] = Execution(address(0), 0, "");
        }

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for batch empty execution: ", gasUsed);
    }

    function test_Gas_Execute_TryBatch() public {
        Execution[] memory executions = new Execution[](10);
        for (uint256 i = 0; i < executions.length; i++) {
            executions[i] = Execution(address(0), 0, "");
        }

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, executions, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for try batch empty execution: ", gasUsed);
    }

    // ExecuteFromExecutor Tests
    function test_Gas_ExecuteFromExecutor_Single() public {
        prank(address(mockExecutor));

        uint256 initialGas = gasleft();
        BOB_ACCOUNT.executeFromExecutor(ModeLib.encodeSimpleSingle(), ExecLib.encodeSingle(address(0), 0, ""));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for single empty execution from executor: ", gasUsed);
    }

    function test_Gas_ExecuteFromExecutor_TrySingle() public {
        prank(address(mockExecutor));

        uint256 initialGas = gasleft();
        BOB_ACCOUNT.executeFromExecutor(ModeLib.encodeTrySingle(), ExecLib.encodeSingle(address(0), 0, ""));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for try single empty execution from executor: ", gasUsed);
    }

    function test_Gas_ExecuteFromExecutor_Batch() public {
        Execution[] memory executions = new Execution[](10);
        for (uint256 i = 0; i < executions.length; i++) {
            executions[i] = Execution(address(0), 0, "");
        }

        prank(address(mockExecutor));

        uint256 initialGas = gasleft();
        BOB_ACCOUNT.executeFromExecutor(ModeLib.encodeSimpleBatch(), ExecLib.encodeBatch(executions));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for batch empty execution from executor: ", gasUsed);
    }

    function test_Gas_ExecuteFromExecutor_TryBatch() public {
        Execution[] memory executions = new Execution[](10);
        for (uint256 i = 0; i < executions.length; i++) {
            executions[i] = Execution(address(0), 0, "");
        }

        prank(address(mockExecutor));

        uint256 initialGas = gasleft();
        BOB_ACCOUNT.executeFromExecutor(ModeLib.encodeTryBatch(), ExecLib.encodeBatch(executions));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for try batch empty execution from executor: ", gasUsed);
    }
}
