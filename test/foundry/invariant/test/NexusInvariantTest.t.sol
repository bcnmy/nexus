// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../../utils/NexusTest_Base.t.sol";

/// @title NexusInvariantTest
/// @notice This contract tests invariants related to Nexus, ensuring execution consistency and proper nonce handling.
contract NexusInvariantTest is NexusTest_Base {
    /// @notice Initializes the testing environment
    function setUp() public {
        init(); // Initialize environment which includes deploying Nexus as BOB_ACCOUNT

        excludeContract(address(VALIDATOR_MODULE));
        excludeContract(address(EXECUTOR_MODULE));
        excludeContract(address(HANDLER_MODULE));
        excludeContract(address(HOOK_MODULE));
        excludeContract(address(FACTORY));
    }

    /// @notice Invariant to ensure execution consistency and access control
    function invariant_executionConsistency() public {
        bytes memory execCallData = abi.encodeWithSelector(MockExecutor.executeViaAccount.selector, BOB_ACCOUNT, address(0), 0, "");
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(EXECUTOR_MODULE), 0, execCallData);

        // Try executing without the correct permissions, expecting failure
        try EXECUTOR_MODULE.executeBatchViaAccount(BOB_ACCOUNT, executions) {
            fail("Execution should fail without proper permissions or setup");
        } catch {}

        // Install the EXECUTOR_MODULE correctly
        bytes memory callDataInstall = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(EXECUTOR_MODULE),
            ""
        );
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callDataInstall);
        PackedUserOperation[] memory userOpsInstall = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(userOpsInstall, payable(address(BOB.addr)));

        // Now execute should work with the correct setup
        executions[0] = Execution(address(EXECUTOR_MODULE), 0, execCallData);
        PackedUserOperation[] memory userOpsExec = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(userOpsExec, payable(address(BOB.addr)));
    }

    /// @notice Invariant to ensure nonce handling is consistent across operations
    function invariant_nonceConsistency() public {
        uint256 initialNonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));

        // Perform a state-changing operation
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), "");
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        uint256 finalNonce = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));
        assertEq(finalNonce, initialNonce + 1, "Nonce should increment by one after a state-changing operation.");
    }
}
