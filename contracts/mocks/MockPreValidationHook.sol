// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPreValidationHookERC1271, IPreValidationHookERC4337, PackedUserOperation } from "../interfaces/modules/IPreValidationHook.sol";
import { EncodedModuleTypes } from "../lib/ModuleTypeLib.sol";
import "../types/Constants.sol";

contract MockPreValidationHook is IPreValidationHookERC1271, IPreValidationHookERC4337 {
    event PreCheckCalled();
    event HookOnInstallCalled(bytes32 dataFirstWord);

    function onInstall(bytes calldata data) external override {
        if (data.length >= 0x20) {
            emit HookOnInstallCalled(bytes32(data[0:32]));
        }
    }

    function onUninstall(bytes calldata) external override { }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337 || moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271;
    }

    function isInitialized(address) external pure returns (bool) {
        return true;
    }

    function preValidationHookERC1271(
        address,
        address,
        bytes32 hash,
        bytes calldata data
    )
        external
        pure
        returns (bytes32 hookHash, bytes memory hookSignature)
    {
        return (hash, data);
    }

    function preValidationHookERC4337(
        PackedUserOperation calldata userOp,
        uint256,
        bytes32 userOpHash
    )
        external
        pure
        returns (bytes32 hookHash, bytes memory hookSignature)
    {
        return (userOpHash, userOp.signature);
    }
}
