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
    function singleInitNexus(IModule validator, bytes calldata data) external {
        // init validator
        _installValidator(address(validator), data);
    }

    /**
     * This function is intended to be called by the Nexus with a delegatecall.
     * Make sure that the Nexus already initilazed the linked lists in the ModuleManager prior to
     * calling this function
     */
    /// Review: Full bootstrap config vs limited bootstrap config (say n validators and hook only is frequently needed when setting up account) 
    function initNexus(
        BootstrapConfig[] calldata $valdiators,
        BootstrapConfig[] calldata $executors,
        BootstrapConfig calldata _hook,
        BootstrapConfig[] calldata _fallbacks
    )
        external
    {
        // init validators
        for (uint256 i; i < $valdiators.length; i++) {
            _installValidator($valdiators[i].module, $valdiators[i].data);
        }

        // init executors
        for (uint256 i; i < $executors.length; i++) {
            if ($executors[i].module == address(0)) continue;
            _installExecutor($executors[i].module, $executors[i].data);
        }

        // init hook
        if (_hook.module != address(0)) {
            _installHook(_hook.module, _hook.data);
        }

        // init fallback
        for (uint256 i; i < _fallbacks.length; i++) {
            if (_fallbacks[i].module == address(0)) continue;
            _installFallbackHandler(_fallbacks[i].module, _fallbacks[i].data);
        }
    }

    function _getInitNexusCalldata(
        BootstrapConfig[] calldata $valdiators,
        BootstrapConfig[] calldata $executors,
        BootstrapConfig calldata _hook,
        BootstrapConfig[] calldata _fallbacks
    )
        external
        view
        returns (bytes memory init)
    {
        init = abi.encode(
            address(this),
            abi.encodeCall(this.initNexus, ($valdiators, $executors, _hook, _fallbacks))
        );
    }

    function initNexusScoped(
        BootstrapConfig[] calldata $valdiators,
        BootstrapConfig calldata _hook
    )
        external
    {
        // init validators
        for (uint256 i; i < $valdiators.length; i++) {
            _installValidator($valdiators[i].module, $valdiators[i].data);
        }

        // init hook
        if (_hook.module != address(0)) {
            _installHook(_hook.module, _hook.data);
        }
    }

    function _getInitNexusScopedCalldata(
        BootstrapConfig[] calldata $valdiators,
        BootstrapConfig calldata _hook
    )
        external
        view
        returns (bytes memory init)
    {
        init = abi.encode(
            address(this),
            abi.encodeCall(this.initNexusScoped, ($valdiators, _hook))
        );
    }

    function _getInitNexusWithSingleValidatorCalldata(
        BootstrapConfig calldata $valdiator
    )
        external
        view
        returns (bytes memory init)
    {
        init = abi.encode(
            address(this),
            abi.encodeCall(this.singleInitNexus, (IModule($valdiator.module), $valdiator.data))
        );
    }
}