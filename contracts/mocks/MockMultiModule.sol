// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IModule } from "../interfaces/modules/IModule.sol";
import { EncodedModuleTypes } from "../lib/ModuleTypeLib.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { ECDSA } from "solady/utils/ECDSA.sol";
import { SignatureCheckerLib } from "solady/utils/SignatureCheckerLib.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "../types/Constants.sol";

contract MockMultiModule is IModule {
    mapping(uint256 moduleTypeId => mapping(address smartAccount => bytes32 initData)) configs;

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external view returns (uint256 validation) {
        address owner = address(bytes20(configs[MODULE_TYPE_VALIDATOR][msg.sender]));
        return _checkSignature(owner, userOpHash, userOp.signature) ? VALIDATION_SUCCESS : VALIDATION_FAILED;
    }

    function _checkSignature(address owner, bytes32 userOpHash, bytes calldata signature) internal view returns (bool) {
        if (ECDSA.recover(userOpHash, signature) == owner) {
            return true;
        }
        if (ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(userOpHash), signature) == owner) {
            return true;
        } 
        return false;
    }

    function getConfig(address smartAccount, uint256 moduleTypeId) external view returns (bytes32) {
        return configs[moduleTypeId][smartAccount];
    }

    function onInstall(bytes calldata data) external override {
        if (data.length >= 0x21) {
            uint256 moduleTypeId = uint256(uint8(bytes1(data[:1])));
            configs[moduleTypeId][msg.sender] = bytes32(data[1:33]);
        } else {
            revert("MultiModule: Wrong install Data");
        }
    }

    function onUninstall(bytes calldata data) external override {
        if (data.length >= 0x1) {
            uint256 moduleTypeId = uint256(uint8(bytes1(data[:1])));
            configs[moduleTypeId][msg.sender] = bytes32(0x00);
        } else {
            revert("MultiModule: Wrong uninstall Data");
        }
    }

    function preCheck(address, uint256, bytes calldata) external returns (bytes memory) {}

    function postCheck(bytes calldata hookData) external {}

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return (moduleTypeId == MODULE_TYPE_HOOK ||
            moduleTypeId == MODULE_TYPE_EXECUTOR ||
            moduleTypeId == MODULE_TYPE_VALIDATOR ||
            moduleTypeId == MODULE_TYPE_FALLBACK);
    }

    function isInitialized(address smartAccount) external view returns (bool) {
        return (configs[MODULE_TYPE_VALIDATOR][smartAccount] != bytes32(0x00) ||
            configs[MODULE_TYPE_EXECUTOR][smartAccount] != bytes32(0x00) ||
            configs[MODULE_TYPE_HOOK][smartAccount] != bytes32(0x00) ||
            configs[MODULE_TYPE_FALLBACK][smartAccount] != bytes32(0x00));
    }
}
