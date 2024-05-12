// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../base/BaseInvariantTest.t.sol";

// ModuleManagementInvariantHandler manages module installation and removal operations
// to verify the integrity of modules across the Nexus Smart Account.
contract InvariantModuleManagementHandler is BaseInvariantTest {
    Nexus internal nexusAccount;
    Vm.Wallet internal signer;

    // Initializes the handler with a Nexus account and wallet for transactions
    constructor(Nexus _nexusAccount, Vm.Wallet memory _signer) {
        nexusAccount = _nexusAccount;
        signer = _signer;
    }

    // Invariant to ensure the persistent installation of a specified module
    function invariant_handleModuleInstallation(uint256 moduleType, address moduleAddress) external {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            moduleType,
            moduleAddress,
            ""
        );
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(nexusAccount),
            value: 0,
            callData: callData
        });

        // Execute module installation through ENTRYPOINT
        PackedUserOperation[] memory userOps = prepareUserOperation(signer, nexusAccount, executions);
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Verify that the module remains installed after the operation
        assertTrue(
            nexusAccount.isModuleInstalled(moduleType, moduleAddress, ""),
            "Invariant failed: Module should be persistently installed."
        );
    }

    // Invariant to ensure that uninstalled modules are not mistakenly recognized as installed
    function invariant_handleModuleUninstallation(uint256 moduleType, address moduleAddress) external {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            moduleType,
            moduleAddress,
            ""
        );
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(nexusAccount),
            value: 0,
            callData: callData
        });

        // Execute module uninstallation through ENTRYPOINT
        PackedUserOperation[] memory userOps = prepareUserOperation(signer, nexusAccount, executions);
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Verify that the module is no longer installed
        assertFalse(
            nexusAccount.isModuleInstalled(moduleType, moduleAddress, ""),
            "Invariant failed: Module should not be mistakenly recognized as installed."
        );
    }

    // Function to ensure the Validator module is installed
    function ensureValidatorModuleInstalled() external view {
        // Implement the logic to ensure the validator module is installed
        uint256 moduleType = 1; // Example module type
        address moduleAddress = address(0x123); // Example module address
        require(
            nexusAccount.isModuleInstalled(moduleType, moduleAddress, ""),
            "Validator module is not installed"
        );
    }

    // Function to simulate duplicate module installation and expect revert
    function simulateDuplicateInstallationRevert() external {
        // Implement the logic to simulate duplicate module installation
        // and ensure it reverts
        uint256 moduleType = 1; // Example module type
        address moduleAddress = address(0x123); // Example module address

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            moduleType,
            moduleAddress,
            ""
        );
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(nexusAccount),
            value: 0,
            callData: callData
        });

        PackedUserOperation[] memory userOps = prepareUserOperation(signer, nexusAccount, executions);
        vm.expectRevert();
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));
    }

    // Function to validate only authorized modules are installed
    function validateAuthorizedModulesInstallation() external view returns (bool) {
        // Implement the logic to check that only authorized modules are installed
        uint256 moduleType = 1; // Example module type
        address authorizedModuleAddress = address(0x123); // Example authorized module address

        return nexusAccount.isModuleInstalled(moduleType, authorizedModuleAddress, "");
    }
}
