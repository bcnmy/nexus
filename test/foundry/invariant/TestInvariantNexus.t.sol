// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../utils/SmartAccountTestLab.t.sol";

contract TestInvariantNexus is SmartAccountTestLab {
    function setUp() public {
        init(); // Initialize environment which includes deploying Nexus as BOB_ACCOUNT
    }

    // Invariant to ensure consistent state of module installation
    function invariant_moduleInstallationConsistency() public {
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), "");

        // Simulating module installation
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify module is installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), ""), "Module should be installed after operation");

        // Attempt to uninstall module
        bytes memory callDataUninstall = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(EXECUTOR_MODULE),
            ""
        );
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callDataUninstall);
        userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Check module is uninstalled
        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), ""),
            "Module should be uninstalled after operation"
        );
    }

    // Invariant to ensure execution consistency and access control
    function invariant_executionConsistency() public {
        bytes memory execCallData = abi.encodeWithSelector(MockExecutor.executeViaAccount.selector, BOB_ACCOUNT, address(0), 0, "");
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(EXECUTOR_MODULE), 0, execCallData);

        // Try executing without the correct permissions
        try EXECUTOR_MODULE.executeBatchViaAccount(BOB_ACCOUNT, executions) {
            fail("Should fail without proper permissions or setup");
        } catch {}

        // Now install and use the proper executor to perform the same execution
        bytes memory callDataInstall = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(EXECUTOR_MODULE),
            ""
        );
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callDataInstall);
        PackedUserOperation[] memory userOpsInstall = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOpsInstall, payable(address(BOB.addr)));

        // Now execute should work
        executions[0] = Execution(address(EXECUTOR_MODULE), 0, execCallData);
        PackedUserOperation[] memory userOpsExec = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOpsExec, payable(address(BOB.addr)));
    }

    // Invariant to ensure nonce handling is consistent across operations
    function invariant_nonceConsistency() public {
        uint256 initialNonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));

        // Perform a state-changing operation
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), "");
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        uint256 finalNonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));
        assertEq(finalNonce, initialNonce + 1, "Nonce should increment by one after a state-changing operation.");
    }
}
