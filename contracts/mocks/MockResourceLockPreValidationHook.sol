// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPreValidationHookERC1271, IPreValidationHookERC4337, PackedUserOperation } from "../interfaces/modules/IPreValidationHook.sol";
import { MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, MODULE_TYPE_HOOK, MODULE_TYPE_PREVALIDATION_HOOK_ERC1271 } from "../types/Constants.sol";
import { EIP712 } from "solady/utils/EIP712.sol";

interface IAccountLocker {
    function getLockedAmount(address account, address token) external view returns (uint256);
}

interface IAccount {
    function isModuleInstalled(uint256 moduleTypeId, address module, bytes calldata additionalContext) external view returns (bool installed);
}

contract MockResourceLockPreValidationHook is IPreValidationHookERC4337, IPreValidationHookERC1271 {
    address constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    /// @dev `keccak256("PersonalSign(bytes prefixed)")`.
    bytes32 internal constant _PERSONAL_SIGN_TYPEHASH = 0x983e65e5148e570cd828ead231ee759a8d7958721a768f93bc4483ba005c32de;
    bytes32 internal constant _DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    IAccountLocker public immutable resourceLocker;
    address public immutable prevalidationHookMultiplexer;

    error InsufficientUnlockedETH(uint256 required);
    error ResourceLockerNotInstalled();
    error ResourceLockerInstalled();
    error SenderIsResourceLocked();

    constructor(address _resourceLocker, address _prevalidationHookMultiplexer) {
        resourceLocker = IAccountLocker(_resourceLocker);
        prevalidationHookMultiplexer = _prevalidationHookMultiplexer;
    }

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == prevalidationHookMultiplexer;
    }

    function _msgSender() internal view returns (address sender) {
        if (isTrustedForwarder(msg.sender) && msg.data.length >= 20) {
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function onInstall(bytes calldata) external view override {
        address sender = _msgSender();
        require(IAccount(sender).isModuleInstalled(MODULE_TYPE_HOOK, address(resourceLocker), ""), ResourceLockerNotInstalled());
    }

    function onUninstall(bytes calldata) external view override {
        address sender = _msgSender();
        require(!IAccount(sender).isModuleInstalled(MODULE_TYPE_HOOK, address(resourceLocker), ""), ResourceLockerInstalled());
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337 || moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271;
    }

    function isInitialized(address) external pure returns (bool) {
        return true;
    }

    function preValidationHookERC4337(
        address account,
        PackedUserOperation calldata userOp,
        uint256 missingAccountFunds,
        bytes32 userOpHash
    )
        external
        view
        returns (bytes32 hookHash, bytes memory hookSignature)
    {
        require(enoughETHAvailable(account, missingAccountFunds), InsufficientUnlockedETH(missingAccountFunds));
        return (userOpHash, userOp.signature);
    }

    function enoughETHAvailable(address account, uint256 requiredAmount) internal view returns (bool) {
        if (requiredAmount == 0) {
            return true;
        }

        uint256 lockedAmount = resourceLocker.getLockedAmount(account, NATIVE_TOKEN);
        uint256 unlockedAmount = address(account).balance - lockedAmount;

        return unlockedAmount >= requiredAmount;
    }

    function preValidationHookERC1271(
        address account,
        address sender,
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        override
        returns (bytes32 hookHash, bytes memory hookSignature)
    {
        require(notResourceLocked(account, sender), SenderIsResourceLocked());
        return (hash, data);
    }

    function notResourceLocked(address account, address sender) internal view returns (bool) {
        uint256 lockedAmount = resourceLocker.getLockedAmount(account, sender);
        return lockedAmount == 0;
    }
}
