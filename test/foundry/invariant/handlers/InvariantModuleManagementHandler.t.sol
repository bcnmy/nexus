// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../base/BaseInvariantTest.t.sol";

// Manages module installation and removal operations to ensure the integrity of modules across the Nexus system.
contract InvariantModuleManagementHandler is BaseInvariantTest {
    Nexus internal nexusAccount;
    Vm.Wallet internal signer;

    // Constructor initializes the handler with a Nexus account and wallet for transaction signing
    constructor(Nexus _nexusAccount, Vm.Wallet memory _signer) {
        nexusAccount = _nexusAccount;
        signer = _signer;
    }

    // Ensures the persistent installation of a specified module
    function invariant_handleModuleInstallation(uint256 moduleType, address moduleAddress) external {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            moduleType,
            moduleAddress,
            ""
        );
        
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({target: address(nexusAccount), value: 0, callData: callData});

        // Execute module installation through ENTRYPOINT
        PackedUserOperation[] memory userOps = prepareUserOperation(signer, nexusAccount, executions);
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Verify that the module remains installed
        assertTrue(
            nexusAccount.isModuleInstalled(moduleType, moduleAddress, ""),
            "Invariant failed: Module should be persistently installed."
        );
    }

    // Ensures that uninstalled modules are not mistakenly recognized as installed
    function invariant_handleModuleUninstallation(uint256 moduleType, address moduleAddress) external {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            moduleType,
            moduleAddress,
            ""
        );
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({target: address(nexusAccount), value: 0, callData: callData});


        // Execute module uninstallation through ENTRYPOINT
        PackedUserOperation[] memory userOps = prepareUserOperation(signer, nexusAccount, executions);
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Verify that the module is no longer installed
        assertFalse(
            nexusAccount.isModuleInstalled(moduleType, moduleAddress, ""),
            "Invariant failed: Module should not be mistakenly recognized as installed."
        );
    }

    // Utility function to add if specific state checks are needed post-operation
    function checkModuleState(uint256 moduleType, address moduleAddress, bool expectedState) internal {
        bool isInstalled = nexusAccount.isModuleInstalled(moduleType, moduleAddress, "");
        assertEq(isInstalled, expectedState, "Module state does not match expected state.");
    }

        // Ensures that the validator module is installed and remains persistent
    function ensureValidatorModuleInstalled() external view returns (bool) {
        uint256 moduleType = MODULE_TYPE_VALIDATOR; // Define the module type identifier
        address moduleAddress = address(VALIDATOR_MODULE); // Define the module address

        return nexusAccount.isModuleInstalled(moduleType, moduleAddress, "");
    }

    // Function to check if a particular module is installed
    function isValidatorModuleInstalled(uint256 moduleType, address moduleAddress) external view returns (bool) {
        return nexusAccount.isModuleInstalled(moduleType, moduleAddress, "");
    }
}
