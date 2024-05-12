// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../unit/shared/TestAccountExecution_Base.t.sol";

contract TestInvariantExecutionHelper is TestAccountExecution_Base {
    function setUp() public {
        init(); // Initialize environment which includes deploying Nexus as BOB_ACCOUNT
    }

    // Invariant test to ensure that only an authorized executor can invoke executeFromExecutor
    function invariant_AuthorizedExecutorOnly() public {
        // Attempt to execute from a non-installed executor should fail
        MockExecutor unauthorizedExecutor = new MockExecutor();
        bytes memory execData = abi.encodeWithSelector(Counter.incrementNumber.selector);

        try unauthorizedExecutor.executeViaAccount(BOB_ACCOUNT, address(counter), 0, execData) {
            fail("Should revert: unauthorized executor should not be able to call executeFromExecutor");
        } catch {}

        // Properly installed executor should succeed
        MockExecutor authorizedExecutor = new MockExecutor();
        bytes memory installData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(authorizedExecutor),
            ""
        );
        Execution[] memory installExec = new Execution[](1);
        installExec[0] = Execution(address(BOB_ACCOUNT), 0, installData);
        PackedUserOperation[] memory installOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, installExec);
        ENTRYPOINT.handleOps(installOps, payable(address(BOB.addr)));

        // Now attempt a valid execution from the installed executor
        try authorizedExecutor.executeViaAccount(BOB_ACCOUNT, address(counter), 0, execData) {
            // This should succeed without any exceptions
        } catch {
            fail("Should not revert: authorized executor should be able to call executeFromExecutor");
        }
    }
}
