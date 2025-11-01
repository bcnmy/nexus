// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Accounts compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. For security issues, contact: security@biconomy.io

import { ModuleManager } from "../base/ModuleManager.sol";
import { IModule } from "../interfaces/modules/IModule.sol";
import {
    MODULE_TYPE_VALIDATOR,
    MODULE_TYPE_EXECUTOR,
    MODULE_TYPE_FALLBACK,
    MODULE_TYPE_HOOK
} from "../types/Constants.sol";

/// @title NexusBootstrap Configuration for Nexus
/// @notice Provides configuration and initialization for Nexus smart accounts.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
struct BootstrapConfig {
    address module;
    bytes data;
}

struct BootstrapPreValidationHookConfig {
    uint256 hookType;
    address module;
    bytes data;
}

/// @title NexusBootstrap
/// @notice Manages the installation of modules into Nexus smart accounts using delegatecalls.
contract NexusBootstrap is ModuleManager {

    constructor(address defaultValidator, bytes memory initData) ModuleManager(defaultValidator, initData) {}

    modifier _withInitSentinelLists() {
        _initSentinelLists();
        _;
    }

    /// @notice Initializes the Nexus account with the default validator.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param data The initialization data for the default validator module.
    function initNexusWithDefaultValidator(
        bytes calldata data
    )
        external
        payable
    {
        IModule(_DEFAULT_VALIDATOR).onInstall(data);
    }

    // ================================================
    // ===== DEFAULT VALIDATOR + OTHER MODULES =====
    // ================================================

    /// @notice Initializes the Nexus account with the default validator and other modules.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param defaultValidatorInitData The initialization data for the default validator module.
    /// @param validators The configuration array for validator modules. Should not contain the default validator.
    /// @param executors The configuration array for executor modules.
    /// @param hook The configuration for the hook module.
    /// @param fallbacks The configuration array for fallback handler modules.
    /// @param preValidationHooks The configuration array for pre-validation hooks.
    function initNexusWithDefaultValidatorAndOtherModules(
        bytes calldata defaultValidatorInitData,
        BootstrapConfig[] calldata validators,
        BootstrapConfig[] calldata executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks,
        BootstrapPreValidationHookConfig[] calldata preValidationHooks
    )
        public
        payable
        _withInitSentinelLists
    {
        IModule(_DEFAULT_VALIDATOR).onInstall(defaultValidatorInitData);

        for (uint256 i; i < validators.length; i++) {
            if (validators[i].module == address(0)) continue;
            _installValidator(validators[i].module, validators[i].data);
            emit ModuleInstalled(MODULE_TYPE_VALIDATOR, validators[i].module);
        }

        for (uint256 i; i < executors.length; i++) {
            if (executors[i].module == address(0)) continue;
            _installExecutor(executors[i].module, executors[i].data);
            emit ModuleInstalled(MODULE_TYPE_EXECUTOR, executors[i].module);
        }

        // Initialize hook
        if (hook.module != address(0)) {
            _installHook(hook.module, hook.data);
            emit ModuleInstalled(MODULE_TYPE_HOOK, hook.module);
        }

        // Initialize fallback handlers
        for (uint256 i; i < fallbacks.length; i++) {
            if (fallbacks[i].module == address(0)) continue;
            _installFallbackHandler(fallbacks[i].module, fallbacks[i].data);
            emit ModuleInstalled(MODULE_TYPE_FALLBACK, fallbacks[i].module);
        } 

        // Initialize pre-validation hooks
        for (uint256 i; i < preValidationHooks.length; i++) {
            if (preValidationHooks[i].module == address(0)) continue;
            _installPreValidationHook(
                preValidationHooks[i].hookType,
                preValidationHooks[i].module,
                preValidationHooks[i].data
            );
            emit ModuleInstalled(preValidationHooks[i].hookType, preValidationHooks[i].module);
        }
    }

    /// @notice expose this function for backwards compatibility
    function initNexusWithDefaultValidatorAndOtherModulesNoRegistry(
        bytes calldata defaultValidatorInitData,
        BootstrapConfig[] calldata validators,
        BootstrapConfig[] calldata executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks,
        BootstrapPreValidationHookConfig[] calldata preValidationHooks
    )
        external
        payable
    {
        initNexusWithDefaultValidatorAndOtherModules(
            defaultValidatorInitData, 
            validators,
            executors, 
            hook, 
            fallbacks, 
            preValidationHooks
        );
    }

    // ================================================
    // ===== SINGLE VALIDATOR =====
    // ================================================

    /// @notice Initializes the Nexus account with a single validator.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validator The address of the validator module. Should not be the default validator.
    /// @param data The initialization data for the validator module.
    function initNexusWithSingleValidator(
        address validator,
        bytes calldata data
    )
        public
        payable
        _withInitSentinelLists
    {
        _installValidator(validator, data);
        emit ModuleInstalled(MODULE_TYPE_VALIDATOR, validator);
    }

    /// @notice expose this function for backwards compatibility
    function initNexusWithSingleValidatorNoRegistry(
        address validator,
        bytes calldata data
    )
        external
        payable
    {   
        initNexusWithSingleValidator(validator, data);
    }


    // ================================================
    // ===== GENERALIZED FLOW =====
    // ================================================

    /// @notice Initializes the Nexus account with multiple modules.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validators The configuration array for validator modules. Should not contain the default validator.
    /// @param executors The configuration array for executor modules.
    /// @param hook The configuration for the hook module.
    /// @param fallbacks The configuration array for fallback handler modules.
    /// @param preValidationHooks The configuration array for pre-validation hooks.
    function initNexus(
        BootstrapConfig[] calldata validators,
        BootstrapConfig[] calldata executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks,
        BootstrapPreValidationHookConfig[] calldata preValidationHooks
    )
        public
        _withInitSentinelLists
    {
        // Initialize validators
        for (uint256 i = 0; i < validators.length; i++) {
            _installValidator(validators[i].module, validators[i].data);
            emit ModuleInstalled(MODULE_TYPE_VALIDATOR, validators[i].module);
        }

        // Initialize executors
        for (uint256 i = 0; i < executors.length; i++) {
            if (executors[i].module == address(0)) continue;
            _installExecutor(executors[i].module, executors[i].data);
            emit ModuleInstalled(MODULE_TYPE_EXECUTOR, executors[i].module);
        }

        // Initialize fallback handlers
        for (uint256 i = 0; i < fallbacks.length; i++) {
            if (fallbacks[i].module == address(0)) continue;
            _installFallbackHandler(fallbacks[i].module, fallbacks[i].data);
            emit ModuleInstalled(MODULE_TYPE_FALLBACK, fallbacks[i].module);
        }

        // Initialize hook
        if (hook.module != address(0)) {
            _installHook(hook.module, hook.data);
            emit ModuleInstalled(MODULE_TYPE_HOOK, hook.module);
        }

        // Initialize pre-validation hooks
        for (uint256 i = 0; i < preValidationHooks.length; i++) {
            if (preValidationHooks[i].module == address(0)) continue;
            _installPreValidationHook(
                preValidationHooks[i].hookType,
                preValidationHooks[i].module,
                preValidationHooks[i].data
            );
            emit ModuleInstalled(preValidationHooks[i].hookType, preValidationHooks[i].module);
        }
    }

    /// @notice expose this function for backwards compatibility
    function initNexusNoRegistry(
        BootstrapConfig[] calldata validators,
        BootstrapConfig[] calldata executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks,
        BootstrapPreValidationHookConfig[] calldata preValidationHooks
    )
        external
        payable
    {
        initNexus(validators, executors, hook, fallbacks, preValidationHooks);
    }

    // ================================================
    // ===== SCOPED FLOW =====
    // ================================================

    /// @notice Initializes the Nexus account with a scoped set of modules.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validators The configuration array for validator modules. Should not contain the default validator.
    /// @param hook The configuration for the hook module.
    function initNexusScoped(
        BootstrapConfig[] calldata validators,
        BootstrapConfig calldata hook
    )
        public
        _withInitSentinelLists
    {
        // Initialize validators
        for (uint256 i = 0; i < validators.length; i++) {
            _installValidator(validators[i].module, validators[i].data);
            emit ModuleInstalled(MODULE_TYPE_VALIDATOR, validators[i].module);
        }

        // Initialize hook
        if (hook.module != address(0)) {
            _installHook(hook.module, hook.data);
            emit ModuleInstalled(MODULE_TYPE_HOOK, hook.module);
        }
    }

    /// @notice expose this function for backwards compatibility
    function initNexusScopedNoRegistry(
        BootstrapConfig[] calldata validators,
        BootstrapConfig calldata hook
    )
        external
        payable
    {
        initNexusScoped(validators, hook);
    }

    /// @dev EIP712 domain name and version.
    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "NexusBootstrap";
        version = "1.3.0";
    }

    
    // required implementations. Are not used.
    function installModule(uint256 moduleTypeId, address module, bytes calldata initData) external payable override {
        // do nothing
    }

    function uninstallModule(uint256 moduleTypeId, address module, bytes calldata deInitData) external payable override {
        // do nothing
    }

    function isModuleInstalled(uint256 moduleTypeId, address module, bytes calldata additionalContext) external view override returns (bool installed) {
        return false;
    }
}
