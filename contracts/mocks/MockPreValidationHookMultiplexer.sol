// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPreValidationHookERC1271, IPreValidationHookERC4337, PackedUserOperation, IModule } from "../interfaces/modules/IPreValidationHook.sol";
import { MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337 } from "../types/Constants.sol";

contract MockPreValidationHookMultiplexer is IPreValidationHookERC1271, IPreValidationHookERC4337 {
    struct HookConfig {
        address[] hooks;
        bool initialized;
    }

    // Separate configurations for each hook type
    mapping(uint256 hookType => mapping(address account => HookConfig)) internal accountConfig;

    error AlreadyInitialized(uint256 hookType);
    error NotInitialized(uint256 hookType);
    error InvalidHookType(uint256 hookType);
    error OnInstallFailed(address hook);
    error OnUninstallFailed(address hook);
    error SubHookFailed(address hook);

    function onInstall(bytes calldata data) external {
        (uint256 moduleType, address[] memory hooks, bytes[] memory hookData) = abi.decode(data, (uint256, address[], bytes[]));

        if (!isValidModuleType(moduleType)) {
            revert InvalidHookType(moduleType);
        }

        if (accountConfig[moduleType][msg.sender].initialized) {
            revert AlreadyInitialized(moduleType);
        }

        accountConfig[moduleType][msg.sender].hooks = hooks;
        accountConfig[moduleType][msg.sender].initialized = true;

        for (uint256 i = 0; i < hooks.length; i++) {
            bytes memory subHookOnInstallCalldata = abi.encodeCall(IModule.onInstall, hookData[i]);
            (bool success,) = hooks[i].call(abi.encodePacked(subHookOnInstallCalldata, msg.sender));
            require(success, OnInstallFailed(hooks[i]));
        }
    }

    function onUninstall(bytes calldata data) external {
        (uint256 moduleType, bytes[] memory hookData) = abi.decode(data, (uint256, bytes[]));

        if (!isValidModuleType(moduleType)) {
            revert InvalidHookType(moduleType);
        }

        address[] memory hooks = accountConfig[moduleType][msg.sender].hooks;

        delete accountConfig[moduleType][msg.sender];

        for (uint256 i = 0; i < hooks.length; i++) {
            bytes memory subHookOnUninstallCalldata = abi.encodeCall(IModule.onUninstall, hookData[i]);
            (bool success,) = hooks[i].call(abi.encodePacked(subHookOnUninstallCalldata, msg.sender));
            require(success, OnUninstallFailed(hooks[i]));
        }
    }

    function preValidationHookERC4337(
        PackedUserOperation calldata userOp,
        uint256 missingAccountFunds,
        bytes32 userOpHash
    )
        external
        returns (bytes32 hookHash, bytes memory hookSignature)
    {
        HookConfig storage config = accountConfig[MODULE_TYPE_PREVALIDATION_HOOK_ERC4337][msg.sender];

        if (!config.initialized) {
            revert NotInitialized(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337);
        }

        hookHash = userOpHash;
        hookSignature = userOp.signature;
        PackedUserOperation memory op = userOp;

        for (uint256 i = 0; i < config.hooks.length; i++) {
            bytes memory subHookData = abi.encodeWithSelector(IPreValidationHookERC4337.preValidationHookERC4337.selector, op, missingAccountFunds, hookHash);
            (bool success, bytes memory result) = config.hooks[i].call(abi.encodePacked(subHookData, msg.sender));
            require(success, SubHookFailed(config.hooks[i]));
            (hookHash, hookSignature) = abi.decode(result, (bytes32, bytes));
            op.signature = hookSignature;
        }

        return (hookHash, hookSignature);
    }

    function preValidationHookERC1271(
        address account,
        address sender,
        bytes32 hash,
        bytes calldata signature
    )
        external
        view
        returns (bytes32 hookHash, bytes memory hookSignature)
    {
        HookConfig storage config = accountConfig[MODULE_TYPE_PREVALIDATION_HOOK_ERC1271][msg.sender];

        if (!config.initialized) {
            revert NotInitialized(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271);
        }

        hookHash = hash;
        hookSignature = signature;

        for (uint256 i = 0; i < config.hooks.length; i++) {
            (hookHash, hookSignature) = IPreValidationHookERC1271(config.hooks[i]).preValidationHookERC1271(account, sender, hookHash, hookSignature);
        }

        return (hookHash, hookSignature);
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return isValidModuleType(moduleTypeId);
    }

    function isInitialized(address smartAccount) external view returns (bool) {
        // Account is initialized if either hook type is initialized
        return accountConfig[MODULE_TYPE_PREVALIDATION_HOOK_ERC4337][smartAccount].initialized
            || accountConfig[MODULE_TYPE_PREVALIDATION_HOOK_ERC1271][smartAccount].initialized;
    }

    function isHookTypeInitialized(address smartAccount, uint256 hookType) external view returns (bool) {
        return accountConfig[hookType][smartAccount].initialized;
    }

    function isValidModuleType(uint256 moduleTypeId) internal pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337 || moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271;
    }
}
