// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";
import "../../../shared/TestAccountExecution_Base.t.sol";

contract TestAccountExecution_ExecuteFromExecutor is TestAccountExecution_Base {
    MockExecutor public mockExecutor;

    /// @notice Sets up the testing environment and installs the MockExecutor module
    function setUp() public {
        setUpTestAccountExecution_Base();

        mockExecutor = new MockExecutor();
        counter = new Counter();

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

    /// @notice Tests single execution via MockExecutor
    function test_ExecSingleFromExecutor_Success() public {
        bytes memory incrementCallData = abi.encodeWithSelector(Counter.incrementNumber.selector);
        bytes memory execCallData = abi.encodeWithSelector(
            MockExecutor.executeViaAccount.selector,
            BOB_ACCOUNT,
            address(counter),
            0,
            incrementCallData
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(mockExecutor), 0, execCallData);

        PackedUserOperation[] memory userOpsExec = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOpsExec, payable(address(BOB.addr)));
        assertEq(counter.getNumber(), 1, "Counter should have incremented");
    }

    /// @notice Tests batch execution via MockExecutor
    function test_ExecBatchFromExecutor_Success() public {
        Execution[] memory executions = new Execution[](3);
        for (uint256 i = 0; i < executions.length; i++) {
            executions[i] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        }
        mockExecutor.executeBatchViaAccount(BOB_ACCOUNT, executions);
        assertEq(counter.getNumber(), 3, "Counter should have incremented three times");
    }

    /// @notice Tests execution from an unauthorized executor
    function test_RevertIf_UnauthorizedExecutor() public {
        MockExecutor unauthorizedExecutor = new MockExecutor();
        bytes memory callData = abi.encodeWithSelector(Counter.incrementNumber.selector);
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(counter), 0, callData);
        vm.expectRevert(abi.encodeWithSelector(InvalidModule.selector, address(unauthorizedExecutor)));
        unauthorizedExecutor.executeBatchViaAccount(BOB_ACCOUNT, executions);
    }

    /// @notice Tests value transfer via executor
    function test_ExecSingleWithValueTransfer() public {
        address receiver = address(0x123);
        uint256 sendValue = 1 ether;
        (bool res, ) = payable(address(BOB_ACCOUNT)).call{ value: 2 ether }(""); // Fund BOB_ACCOUNT
        assertEq(res, true, "Funding should succeed");
        mockExecutor.executeViaAccount(BOB_ACCOUNT, receiver, sendValue, "");
        assertEq(receiver.balance, sendValue, "Receiver should have received ETH");
    }

    /// @notice Tests executing an empty batch via executor
    function test_ExecBatch_Empty() public {
        Execution[] memory executions = new Execution[](0);
        bytes[] memory results = mockExecutor.executeBatchViaAccount(BOB_ACCOUNT, executions);
        assertEq(results.length, 0, "Results array should be empty");
    }

    /// @notice Tests batch execution with mixed outcomes (success and revert)
    function test_ExecBatchWithMixedOutcomes() public {
        Execution[] memory executions = new Execution[](3);
        executions[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        executions[1] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.revertOperation.selector));
        executions[2] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        vm.expectRevert("Counter: Revert operation");
        mockExecutor.executeBatchViaAccount(BOB_ACCOUNT, executions);
    }

    /// @notice Tests ERC20 token transfer via executor
    function test_ExecERC20TransferFromExecutor() public {
        uint256 amount = 100 * 10 ** 18;
        bytes memory transferCallData = abi.encodeWithSelector(token.transfer.selector, address(0x123), amount);

        mockExecutor.executeViaAccount(BOB_ACCOUNT, address(token), 0, transferCallData);

        uint256 balanceCharlie = token.balanceOf(address(0x123));
        assertEq(balanceCharlie, amount, "Charlie should have received the tokens");
    }

    /// @notice Tests ERC20 token transfer via executor
    function test_ExecERC20TransferViaExecutor() public {
        uint256 amount = 100 * 10 ** 18;
        address recipient = address(0x123);
        bytes memory transferCallData = abi.encodeWithSelector(token.transfer.selector, recipient, amount);

        mockExecutor.executeViaAccount(BOB_ACCOUNT, address(token), 0, transferCallData);

        uint256 balanceRecipient = token.balanceOf(recipient);
        assertEq(balanceRecipient, amount, "Recipient should have received the tokens");
    }

    /// @notice Tests ERC20 approve and transferFrom via batch execution
    function test_ExecERC20ApproveAndTransferFromViaBatch() public {
        uint256 approvalAmount = 200 * 10 ** 18;
        uint256 transferAmount = 150 * 10 ** 18;
        address recipient = address(0x123);

        Execution[] memory execs = new Execution[](2);
        execs[0] = Execution(address(token), 0, abi.encodeWithSelector(token.approve.selector, address(BOB_ACCOUNT), approvalAmount));
        execs[1] = Execution(address(token), 0, abi.encodeWithSelector(token.transferFrom.selector, address(BOB_ACCOUNT), recipient, transferAmount));

        bytes[] memory returnData = mockExecutor.executeBatchViaAccount(BOB_ACCOUNT, execs);
        assertEq(returnData.length, 2, "Return data should have two elements");

        uint256 balanceRecipient = token.balanceOf(recipient);
        assertEq(balanceRecipient, transferAmount, "Recipient should have received the tokens via transferFrom");
    }

    /// @notice Tests zero value transfer in batch
    function test_ZeroValueTransferInBatch() public {
        uint256 amount = 0;
        address recipient = address(0x123);

        Execution[] memory execs = new Execution[](1);
        execs[0] = Execution(address(token), 0, abi.encodeWithSelector(token.transfer.selector, recipient, amount));

        mockExecutor.executeBatchViaAccount(BOB_ACCOUNT, execs);

        uint256 balanceRecipient = token.balanceOf(recipient);
        assertEq(balanceRecipient, amount, "Recipient should have received 0 tokens");
    }
}
