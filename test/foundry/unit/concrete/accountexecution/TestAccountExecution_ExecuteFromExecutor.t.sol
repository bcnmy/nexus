// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import { MockExecutor } from "../../../mocks/MockExecutor.sol";
import { Counter } from "../../../mocks/Counter.sol";

error InvalidModule(address module);

contract TestAccountExecution_ExecuteFromExecutor is Test, SmartAccountTestLab {
    MockExecutor public mockExecutor;
    Counter public counter;

    function setUp() public {
        init();
        mockExecutor = new MockExecutor();
        counter = new Counter();

        // Install MockExecutor as executor module on BOB_ACCOUNT
        bytes memory callDataInstall =
            abi.encodeWithSelector(IModuleManager.installModule.selector, uint256(2), address(mockExecutor), "");
        PackedUserOperation[] memory userOpsInstall = prepareExecutionUserOp(
            BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(BOB_ACCOUNT), 0, callDataInstall
        );
        ENTRYPOINT.handleOps(userOpsInstall, payable(address(BOB.addr)));
    }

    // Test single execution via MockExecutor
    function test_ExecSingleFromExecutor() public {
        bytes memory incrementCallData = abi.encodeWithSelector(Counter.incrementNumber.selector);
        bytes memory execCallData = abi.encodeWithSelector(
            MockExecutor.executeViaAccount.selector, BOB_ACCOUNT, address(counter), 0, incrementCallData
        );
        PackedUserOperation[] memory userOpsExec = prepareExecutionUserOp(
            BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, address(mockExecutor), 0, execCallData
        );
        ENTRYPOINT.handleOps(userOpsExec, payable(address(BOB.addr)));
        assertEq(counter.getNumber(), 1, "Counter should have incremented");
    }

    // Test batch execution via MockExecutor
    function test_ExecuteBatchFromExecutor() public {
        Execution[] memory executions = new Execution[](3);
        for (uint256 i = 0; i < executions.length; i++) {
            executions[i] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        }
        bytes[] memory results = mockExecutor.execBatch(BOB_ACCOUNT, executions);
        assertEq(counter.getNumber(), 3, "Counter should have incremented three times");
    }

    // Test execution from an unauthorized executor
    function test_ExecSingleFromExecutor_Unauthorized() public {
        MockExecutor unauthorizedExecutor = new MockExecutor();
        bytes memory callData = abi.encodeWithSelector(Counter.incrementNumber.selector);
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(counter), 0, callData);
        vm.expectRevert(abi.encodeWithSelector(InvalidModule.selector, address(unauthorizedExecutor)));
        unauthorizedExecutor.execBatch(BOB_ACCOUNT, executions);
    }

    // Test value transfer via executor
    function test_ExecSingleWithValueTransfer() public {
        address receiver = address(0x123);
        uint256 sendValue = 1 ether;
        payable(address(BOB_ACCOUNT)).call{ value: 2 ether }(""); // Fund BOB_ACCOUNT
        bytes[] memory results = mockExecutor.executeViaAccount(BOB_ACCOUNT, receiver, sendValue, "");
        assertEq(receiver.balance, sendValue, "Receiver should have received ETH");
    }

    // Test executing an empty batch via executor
    function test_ExecuteEmptyBatchFromExecutor() public {
        Execution[] memory executions = new Execution[](0);
        bytes[] memory results = mockExecutor.execBatch(BOB_ACCOUNT, executions);
        assertEq(results.length, 0, "Results array should be empty");
    }

    // Test batch execution with mixed outcomes (success and revert)
    function test_ExecuteBatchWithMixedOutcomes() public {
        Execution[] memory executions = new Execution[](3);
        executions[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        executions[1] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.revertOperation.selector));
        executions[2] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        vm.expectRevert("Counter: Revert operation");
        mockExecutor.execBatch(BOB_ACCOUNT, executions);
    }
}
