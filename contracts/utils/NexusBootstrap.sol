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
import { IERC7484 } from "../interfaces/IERC7484.sol";
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

    struct RegistryConfig {
        IERC7484 registry;
        address[] attesters;
        uint8 threshold;
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
    /// No registry is needed for the default validator.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @dev For gas savings purposes this method does not initialize the registry.
    /// @dev The registry should be initialized via the `setRegistry` function on the Nexus contract later if needed.
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

    /// @notice Initializes the Nexus account with the default validator and other modules and no registry.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param defaultValidatorInitData The initialization data for the default validator module.
    /// @param executors The configuration array for executor modules.
    /// @param hook The configuration for the hook module.
    /// @param fallbacks The configuration array for fallback handler modules.
    function initNexusWithDefaultValidatorAndOtherModulesNoRegistry(
        bytes calldata defaultValidatorInitData,
        BootstrapConfig[] calldata executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks,
        BootstrapPreValidationHookConfig[] calldata preValidationHooks
    )
        external
        payable
    {
        RegistryConfig memory registryConfig = RegistryConfig({
            registry: IERC7484(address(0)),
            attesters: new address[](0),
            threshold: 0
        });

        _initNexusWithDefaultValidatorAndOtherModules(
            defaultValidatorInitData, 
            executors, 
            hook, 
            fallbacks, 
            preValidationHooks, 
            registryConfig
        );
    }

    /// @notice Initializes the Nexus account with the default validator and other modules.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param defaultValidatorInitData The initialization data for the default validator module.
    /// @param executors The configuration array for executor modules.
    /// @param hook The configuration for the hook module.
    /// @param fallbacks The configuration array for fallback handler modules.
    /// @param registryConfig The registry configuration.
    function initNexusWithDefaultValidatorAndOtherModules(
        bytes calldata defaultValidatorInitData,
        BootstrapConfig[] calldata executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks,
        BootstrapPreValidationHookConfig[] calldata preValidationHooks,
        RegistryConfig memory registryConfig
    )
        external
        payable
    {
        _initNexusWithDefaultValidatorAndOtherModules(
            defaultValidatorInitData, 
            executors, 
            hook, 
            fallbacks, 
            preValidationHooks,
            registryConfig
        );
    }

    function _initNexusWithDefaultValidatorAndOtherModules(
        bytes calldata defaultValidatorInitData,
        BootstrapConfig[] calldata executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks,
        BootstrapPreValidationHookConfig[] calldata preValidationHooks, 
        RegistryConfig memory registryConfig
    )
        internal
        _withInitSentinelLists
    {
        _configureRegistry(registryConfig.registry, registryConfig.attesters, registryConfig.threshold);

        IModule(_DEFAULT_VALIDATOR).onInstall(defaultValidatorInitData);

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

    // ================================================
    // ===== SINGLE VALIDATOR =====
    // ================================================

    /// @notice Initializes the Nexus account with a single validator and no registry.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validator The address of the validator module.
    /// @param data The initialization data for the validator module.
    function initNexusWithSingleValidatorNoRegistry(
        address validator,
        bytes calldata data
    )
        external
        payable
    {
        RegistryConfig memory registryConfig = RegistryConfig({  
            registry: IERC7484(address(0)),
            attesters: new address[](0),
            threshold: 0
        });
        _initNexusWithSingleValidator(validator, data, registryConfig);
    }

    /// @notice Initializes the Nexus account with a single validator.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validator The address of the validator module.
    /// @param data The initialization data for the validator module.
    /// @param registryConfig The registry configuration.
    function initNexusWithSingleValidator(
        address validator,
        bytes calldata data,
        RegistryConfig memory registryConfig
    )
        external
        payable
    {
        _initNexusWithSingleValidator(validator, data, registryConfig);
    }

    function _initNexusWithSingleValidator(
        address validator,
        bytes calldata data,
        RegistryConfig memory registryConfig
    )
        internal
        _withInitSentinelLists
    {
        _configureRegistry(registryConfig.registry, registryConfig.attesters, registryConfig.threshold);
        _installValidator(validator, data);
        emit ModuleInstalled(MODULE_TYPE_VALIDATOR, validator);
    }

    // ================================================
    // ===== GENERALIZED FLOW =====
    // ================================================

    /// @notice Initializes the Nexus account with multiple modules and no registry.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validators The configuration array for validator modules.
    /// @param executors The configuration array for executor modules.
    /// @param hook The configuration for the hook module.
    /// @param fallbacks The configuration array for fallback handler modules.
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
        RegistryConfig memory registryConfig = RegistryConfig({
            registry: IERC7484(address(0)),
            attesters: new address[](0),
            threshold: 0
        });

        _initNexus(validators, executors, hook, fallbacks, preValidationHooks, registryConfig);
    }

    /// @notice Initializes the Nexus account with multiple modules.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validators The configuration array for validator modules.
    /// @param executors The configuration array for executor modules.
    /// @param hook The configuration for the hook module.
    /// @param fallbacks The configuration array for fallback handler modules.
    /// @param registryConfig The registry configuration.
    function initNexus(
        BootstrapConfig[] calldata validators,
        BootstrapConfig[] calldata executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks,
        BootstrapPreValidationHookConfig[] calldata preValidationHooks,
        RegistryConfig memory registryConfig
    )
        external
        payable
    {
        _initNexus({
            validators: validators,
            executors: executors,
            hook: hook,
            fallbacks: fallbacks,
            preValidationHooks: preValidationHooks,
            registryConfig: registryConfig
        });
    }

    function _initNexus(
        BootstrapConfig[] calldata validators,
        BootstrapConfig[] calldata executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks,
        BootstrapPreValidationHookConfig[] calldata preValidationHooks,
        RegistryConfig memory registryConfig
    )
        internal
        _withInitSentinelLists
    {
        _configureRegistry(registryConfig.registry, registryConfig.attesters, registryConfig.threshold);

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

    // ================================================
    // ===== SCOPED FLOW =====
    // ================================================

    /// @notice Initializes the Nexus account with a scoped set of modules and no registry.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validators The configuration array for validator modules.
    /// @param hook The configuration for the hook module.
    function initNexusScopedNoRegistry(
        BootstrapConfig[] calldata validators,
        BootstrapConfig calldata hook
    )
        external
        payable
    {
        RegistryConfig memory registryConfig = RegistryConfig({
            registry: IERC7484(address(0)),
            attesters: new address[](0),
            threshold: 0
        });
        _initNexusScoped(validators, hook, registryConfig);
    }

    /// @notice Initializes the Nexus account with a scoped set of modules.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validators The configuration array for validator modules.
    /// @param hook The configuration for the hook module.
    /// @param registryConfig The registry configuration.
    function initNexusScoped(
        BootstrapConfig[] calldata validators,
        BootstrapConfig calldata hook,
        RegistryConfig memory registryConfig
    )
        external
        payable
    {
        _initNexusScoped(validators, hook, registryConfig);
    }

    /// @notice Initializes the Nexus account with a scoped set of modules.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validators The configuration array for validator modules.
    /// @param hook The configuration for the hook module.
    function _initNexusScoped(
        BootstrapConfig[] calldata validators,
        BootstrapConfig calldata hook,
        RegistryConfig memory registryConfig
    )
        internal
        _withInitSentinelLists
    {
        _configureRegistry(registryConfig.registry, registryConfig.attesters, registryConfig.threshold);

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

    /// @dev EIP712 domain name and version.
    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "NexusBootstrap";
        version = "1.2.0";
    }
}
