// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IModule } from "../interfaces/modules/IModule.sol";
import { IModuleManager } from "../interfaces/base/IModuleManager.sol";
import { VALIDATION_SUCCESS, VALIDATION_FAILED, MODULE_TYPE_VALIDATOR, ERC1271_MAGICVALUE, ERC1271_INVALID } from "../types/Constants.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { ECDSA } from "solady/utils/ECDSA.sol";
import { SignatureCheckerLib } from "solady/utils/SignatureCheckerLib.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import { ERC7739Validator } from "erc7739Validator/ERC7739Validator.sol";

contract MockValidator is ERC7739Validator {
    mapping(address => address) public smartAccountOwners;

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external view returns (uint256 validation) {
        address owner = smartAccountOwners[msg.sender];
        return _validateSignatureForOwner(owner, userOpHash, userOp.signature) ? VALIDATION_SUCCESS : VALIDATION_FAILED;
    }

    function isValidSignatureWithSender(address sender, bytes32 hash, bytes calldata signature) external view virtual returns (bytes4 sigValidationResult) {
        // can put additional checks based on sender here
        return _erc1271IsValidSignatureWithSender(sender, hash, _erc1271UnwrapSignature(signature));
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

    /// @dev Returns whether the `hash` and `signature` are valid.
    ///      Obtains the authorized signer's credentials and calls some
    ///      module's specific internal function to validate the signature
    ///      against credentials.
    function _erc1271IsValidSignatureNowCalldata(bytes32 hash, bytes calldata signature) internal view override returns (bool) {
        // obtain credentials
        address owner = smartAccountOwners[msg.sender];

        // call custom internal function to validate the signature against credentials
        return _validateSignatureForOwner(owner, hash, signature);
    }

    /// @dev Returns whether the `sender` is considered safe, such
    /// that we don't need to use the nested EIP-712 workflow.
    /// See: https://mirror.xyz/curiousapple.eth/pFqAdW2LiJ-6S4sg_u1z08k4vK6BCJ33LcyXpnNb8yU
    // The canonical `MulticallerWithSigner` at 0x000000000000D9ECebf3C23529de49815Dac1c4c
    // is known to include the account in the hash to be signed.
    // msg.sender = Smart Account
    // sender = 1271 og request sender
    function _erc1271CallerIsSafe(address sender) internal view virtual override returns (bool) {
        return (
            sender == 0x000000000000D9ECebf3C23529de49815Dac1c4c // MulticallerWithSigner
                || sender == msg.sender
        );
    }

    function onInstall(bytes calldata data) external {
        smartAccountOwners[msg.sender] = address(bytes20(data));
    }

    function onUninstall(bytes calldata data) external {
        require(!IModuleManager(msg.sender).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(this), ""), "Validator is still installed");
        data;
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
