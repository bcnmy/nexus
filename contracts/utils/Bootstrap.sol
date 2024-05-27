// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Account compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. For security issues, contact: security@biconomy.io

import { ModuleManager } from "../base/ModuleManager.sol";
import { IModule } from "../interfaces/modules/IModule.sol";

struct BootstrapConfig {
    address module;
    bytes data;
}

contract Bootstrap is ModuleManager {
    /// @dev This function is intended to be called by the Nexus with a delegatecall.
    /// Make sure that the Nexus already initilazed the linked lists in the ModuleManager prior to
    /// calling this function
    function initNexusWithSingleValidator(IModule validator, bytes calldata data) external {
        // init validator
        _installValidator(address(validator), data);
    }

    /// @dev This function is intended to be called by the Nexus with a delegatecall.
    /// Make sure that the Nexus already initilazed the linked lists in the ModuleManager prior to
    /// calling this function
    function initNexus(
        BootstrapConfig[] calldata $validators,
        BootstrapConfig[] calldata $executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks
    ) external {
        // init validators
        for (uint256 i; i < $validators.length; i++) {
            _installValidator($validators[i].module, $validators[i].data);
        }

        // init executors
        for (uint256 i; i < $executors.length; i++) {
            if ($executors[i].module == address(0)) continue;
            _installExecutor($executors[i].module, $executors[i].data);
        }

        // init hook
        if (hook.module != address(0)) {
            _installHook(hook.module, hook.data);
        }

        // init fallback
        for (uint256 i; i < fallbacks.length; i++) {
            if (fallbacks[i].module == address(0)) continue;
            _installFallbackHandler(fallbacks[i].module, fallbacks[i].data);
        }
    }

    /// @dev This function is intended to be called by the Nexus with a delegatecall.
    /// Make sure that the Nexus already initilazed the linked lists in the ModuleManager prior to
    /// calling this function
    function initNexusScoped(BootstrapConfig[] calldata $validators, BootstrapConfig calldata hook) external {
        // init validators
        for (uint256 i; i < $validators.length; i++) {
            _installValidator($validators[i].module, $validators[i].data);
        }

        // init hook
        if (hook.module != address(0)) {
            _installHook(hook.module, hook.data);
        }
    }

    /// @dev This function is used to prepare calldata for initNexus function which can install any amount of modules.
    /// n validators, n executors, 1 hook and n fallbacks can be installed
    function getInitNexusCalldata(
        BootstrapConfig[] calldata $validators,
        BootstrapConfig[] calldata $executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks
    ) external view returns (bytes memory init) {
        init = abi.encode(address(this), abi.encodeCall(this.initNexus, ($validators, $executors, hook, fallbacks)));
    }

    /// @dev This function is used to prepare calldata for initNexusScoped function which can install limited amount of modules.
    /// n validators and 1 hook can be installed
    function getInitNexusScopedCalldata(
        BootstrapConfig[] calldata $validators,
        BootstrapConfig calldata hook
    ) external view returns (bytes memory init) {
        init = abi.encode(address(this), abi.encodeCall(this.initNexusScoped, ($validators, hook)));
    }

    /// @dev This function is used to prepare calldata for initNexusWithSingleValidator function which can install only 1 validator.
    function getInitNexusWithSingleValidatorCalldata(BootstrapConfig calldata $validator) external view returns (bytes memory init) {
        init = abi.encode(address(this), abi.encodeCall(this.initNexusWithSingleValidator, (IModule($validator.module), $validator.data)));
    }
}
