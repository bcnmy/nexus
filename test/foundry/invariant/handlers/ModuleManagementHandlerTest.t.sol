// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { InvariantBaseTest } from "../base/InvariantBaseTest.t.sol";
import "../../utils/Imports.sol";

/// @title ModuleManagementHandlerTest
/// @notice Handles invariant testing for module management in Nexus accounts.
/// @dev This handler manages the installation and uninstallation of modules, ensuring that modules are handled correctly and adhere to defined invariants.
contract ModuleManagementHandlerTest is InvariantBaseTest {
    Nexus public nexusAccount;
    Vm.Wallet public signer;

    /// @notice Initializes the handler with a Nexus account and signer
    /// @param _nexusAccount The Nexus account to manage modules
    /// @param _signer The wallet used for signing transactions
    constructor(Nexus _nexusAccount, Vm.Wallet memory _signer) {
        nexusAccount = _nexusAccount;
        signer = _signer;
    }

    /// @notice Installs a module and verifies the module is installed
    /// @param moduleType The type of the module to install
    /// @param moduleAddress The address of the module to install
    function invariant_installModule(uint256 moduleType, address moduleAddress) public {
        bytes memory callData = abi.encodeWithSelector(Nexus.installModule.selector, moduleType, moduleAddress, "");

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: 0, callData: callData });

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Verify module installation
        assertTrue(nexusAccount.isModuleInstalled(moduleType, moduleAddress, ""), "Module should be installed");
    }

    /// @notice Uninstalls a module and verifies the module is uninstalled
    /// @param moduleType The type of the module to uninstall
    /// @param moduleAddress The address of the module to uninstall
    function invariant_uninstallModule(uint256 moduleType, address moduleAddress) public {
        bytes memory callData = abi.encodeWithSelector(Nexus.uninstallModule.selector, moduleType, moduleAddress, "");

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: 0, callData: callData });

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));

        // Verify module uninstallation
        assertFalse(nexusAccount.isModuleInstalled(moduleType, moduleAddress, ""), "Module should be uninstalled");
    }

    /// @notice Checks if a module is installed in the Nexus account
    /// @param moduleType The type of the module
    /// @param moduleAddress The address of the module
    /// @return bool indicating if the module is installed
    function invariant_checkModuleInstalled(uint256 moduleType, address moduleAddress) public view returns (bool) {
        return nexusAccount.isModuleInstalled(moduleType, moduleAddress, "");
    }

    /// @notice Tests installation of an invalid module and expects revert
    function invariant_installInvalidModule() public {
        uint256 invalidModuleType = 999;
        address invalidModuleAddress = address(0);

        bytes memory callData = abi.encodeWithSelector(Nexus.installModule.selector, invalidModuleType, invalidModuleAddress, "");

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: 0, callData: callData });

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );

        vm.expectRevert("Invalid module type or address");
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));
    }

    /// @notice Tests uninstallation of a module that isn't installed and expects revert
    function invariant_uninstallNonExistentModule() public {
        uint256 moduleType = MODULE_TYPE_VALIDATOR;
        address moduleAddress = address(0x123);

        bytes memory callData = abi.encodeWithSelector(Nexus.uninstallModule.selector, moduleType, moduleAddress, "");

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: 0, callData: callData });

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );

        vm.expectRevert("Module not installed");
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));
    }
}
