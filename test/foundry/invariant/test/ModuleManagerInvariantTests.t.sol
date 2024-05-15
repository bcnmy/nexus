// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import "../../unit/shared/TestModuleManagement_Base.t.sol";

contract ModuleManagerInvariantTests is TestModuleManagement_Base {
    function setUp() public {
        setUpModuleManagement_Base();
    }

    /// @notice Invariant to check the persistent installation of the Validator module
    function invariantTest_ValidatorModuleInstalled() public {
        // Validator module should always be installed on BOB_ACCOUNT
        assertTrue(BOB_ACCOUNT.isModuleInstalled(1, address(VALIDATOR_MODULE), ""), "Validator Module should be consistently installed.");
    }

    /// @notice Invariant to ensure that no duplicate installations occur
    function invariantTest_NoDuplicateValidatorInstallation() public {
        // Attempt to reinstall the Validator module should revert
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, 1, address(VALIDATOR_MODULE), "");
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "ModuleAlreadyInstalled(uint256,address)",
            MODULE_TYPE_VALIDATOR,
            address(VALIDATOR_MODULE)
        );

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);

        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    /// @notice Invariant to ensure that non-installed modules are not reported as installed
    function invariantTest_AbsenceOfNonInstalledModules() public {
        // Check that non-installed modules are not mistakenly installed
        assertFalse(BOB_ACCOUNT.isModuleInstalled(2, address(mockExecutor), ""), "Executor Module should not be installed initially.");
        assertFalse(BOB_ACCOUNT.isModuleInstalled(4, address(mockHook), ""), "Hook Module should not be installed initially.");
    }
}
