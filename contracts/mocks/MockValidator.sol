// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IModule } from "../interfaces/modules/IModule.sol";
import { IModuleManager } from "../interfaces/base/IModuleManager.sol";
import { VALIDATION_SUCCESS, VALIDATION_FAILED, MODULE_TYPE_VALIDATOR, ERC1271_MAGICVALUE, ERC1271_INVALID } from "../types/Constants.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { ECDSA } from "solady/utils/ECDSA.sol";
import { SignatureCheckerLib } from "solady/utils/SignatureCheckerLib.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ERC7739Validator } from "../base/ERC7739Validator.sol";
import { IERC1271Unsafe } from "../interfaces/modules/IERC1271Unsafe.sol";

contract MockValidator is ERC7739Validator, IERC1271Unsafe {
    mapping(address => address) public smartAccountOwners;

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external view returns (uint256 validation) {
        address owner = smartAccountOwners[msg.sender];
        return _validateSignatureForOwner(owner, userOpHash, userOp.signature) ? VALIDATION_SUCCESS : VALIDATION_FAILED;
    }

    function isValidSignatureWithSender(address, bytes32 hash, bytes calldata signature) external view returns (bytes4) {
        address owner = smartAccountOwners[msg.sender];

        (bytes32 computeHash, bytes calldata truncatedSignature) = _erc1271HashForIsValidSignatureViaNestedEIP712(hash, signature);

        return _validateSignatureForOwner(owner, computeHash, truncatedSignature) ? ERC1271_MAGICVALUE : ERC1271_INVALID;
    }

    function isValidSignatureWithSenderUnsafe(address, bytes32 hash, bytes calldata signature) external view returns (bytes4) {
        address owner = smartAccountOwners[msg.sender];
        return _validateSignatureForOwner(owner, hash, signature) ? ERC1271_MAGICVALUE : ERC1271_INVALID;
    }

    // ISessionValidator interface for smart session
    function validateSignatureWithData(bytes32 hash, bytes calldata sig, bytes calldata data) external view returns (bool validSig) {
        address owner = address(bytes20(data[0:20]));
        return _validateSignatureForOwner(owner, hash, sig);
    }

    function _validateSignatureForOwner(address owner, bytes32 hash, bytes calldata signature) internal view returns (bool) {
        if (SignatureCheckerLib.isValidSignatureNowCalldata(owner, hash, signature)) {
            return true;
        }
        if (SignatureCheckerLib.isValidSignatureNowCalldata(owner, MessageHashUtils.toEthSignedMessageHash(hash), signature)) {
            return true;
        }
        return false;
    }

    function onInstall(bytes calldata data) external {
        require(IModuleManager(msg.sender).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(this), ""), "Validator is still installed");
        smartAccountOwners[msg.sender] = address(bytes20(data));
    }

    function onUninstall(bytes calldata data) external {
        data;
        require(!IModuleManager(msg.sender).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(this), ""), "Validator is still installed");
        delete smartAccountOwners[msg.sender];
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function isOwner(address account, address owner) external view returns (bool) {
        return smartAccountOwners[account] == owner;
    }

    function isInitialized(address) external pure returns (bool) {
        return false;
    }

    function getOwner(address account) external view returns (address) {
        return smartAccountOwners[account];
    }
}
