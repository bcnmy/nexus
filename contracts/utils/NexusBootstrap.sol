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


    /// @notice Initializes the Nexus account with a single validator.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validator The address of the validator module.
    /// @param data The initialization data for the validator module.
    function initNexusWithSingleValidator(
        IModule validator,
        bytes calldata data,
        IERC7484 registry,
        address[] calldata attesters,
        uint8 threshold
    )
        external
        payable
        _withInitSentinelLists
    {
        _configureRegistry(registry, attesters, threshold);
        _installValidator(address(validator), data);
        emit ModuleInstalled(MODULE_TYPE_VALIDATOR, address(validator));
    }

    /// @notice Initializes the Nexus account with multiple modules.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validators The configuration array for validator modules.
    /// @param executors The configuration array for executor modules.
    /// @param hook The configuration for the hook module.
    /// @param fallbacks The configuration array for fallback handler modules.
    function initNexus(
        BootstrapConfig[] calldata validators,
        BootstrapConfig[] calldata executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks,
        IERC7484 registry,
        address[] calldata attesters,
        uint8 threshold
    )
        external
        payable
        _withInitSentinelLists
    {
        _configureRegistry(registry, attesters, threshold);

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

        // Initialize hook
        if (hook.module != address(0)) {
            _installHook(hook.module, hook.data);
            emit ModuleInstalled(MODULE_TYPE_HOOK, hook.module);
        }

        // Initialize fallback handlers
        for (uint256 i = 0; i < fallbacks.length; i++) {
            if (fallbacks[i].module == address(0)) continue;
            _installFallbackHandler(fallbacks[i].module, fallbacks[i].data);
            emit ModuleInstalled(MODULE_TYPE_FALLBACK, fallbacks[i].module);
        }
    }

    /// @notice Initializes the Nexus account with a scoped set of modules.
    /// @dev Intended to be called by the Nexus with a delegatecall.
    /// @param validators The configuration array for validator modules.
    /// @param hook The configuration for the hook module.
    function initNexusScoped(
        BootstrapConfig[] calldata validators,
        BootstrapConfig calldata hook,
        IERC7484 registry,
        address[] calldata attesters,
        uint8 threshold
    )
        external
        payable
        _withInitSentinelLists
    {
        _configureRegistry(registry, attesters, threshold);

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

    /// @notice Prepares calldata for the initNexus function.
    /// @param validators The configuration array for validator modules.
    /// @param executors The configuration array for executor modules.
    /// @param hook The configuration for the hook module.
    /// @param fallbacks The configuration array for fallback handler modules.
    /// @return init The prepared calldata for initNexus.
    function getInitNexusCalldata(
        BootstrapConfig[] calldata validators,
        BootstrapConfig[] calldata executors,
        BootstrapConfig calldata hook,
        BootstrapConfig[] calldata fallbacks,
        IERC7484 registry,
        address[] calldata attesters,
        uint8 threshold
    )
        external
        view
        returns (bytes memory init)
    {
        init = abi.encode(address(this), abi.encodeCall(this.initNexus, (validators, executors, hook, fallbacks, registry, attesters, threshold)));
    }

    /// @notice Prepares calldata for the initNexusScoped function.
    /// @param validators The configuration array for validator modules.
    /// @param hook The configuration for the hook module.
    /// @return init The prepared calldata for initNexusScoped.
    function getInitNexusScopedCalldata(
        BootstrapConfig[] calldata validators,
        BootstrapConfig calldata hook,
        IERC7484 registry,
        address[] calldata attesters,
        uint8 threshold
    )
        external
        view
        returns (bytes memory init)
    {
        init = abi.encode(address(this), abi.encodeCall(this.initNexusScoped, (validators, hook, registry, attesters, threshold)));
    }

    /// @notice Prepares calldata for the initNexusWithSingleValidator function.
    /// @param validator The configuration for the validator module.
    /// @return init The prepared calldata for initNexusWithSingleValidator.
    function getInitNexusWithSingleValidatorCalldata(
        BootstrapConfig calldata validator,
        IERC7484 registry,
        address[] calldata attesters,
        uint8 threshold
    )
        external
        view
        returns (bytes memory init)
    {
        init = abi.encode(
            address(this), abi.encodeCall(this.initNexusWithSingleValidator, (IModule(validator.module), validator.data, registry, attesters, threshold))
        );
    }

    /// @dev EIP712 domain name and version.
    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "NexusBootstrap";
        version = "1.2.0";
    }
}
