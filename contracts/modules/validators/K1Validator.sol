// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { SignatureCheckerLib } from "solady/src/utils/SignatureCheckerLib.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { MODULE_TYPE_VALIDATOR, VALIDATION_SUCCESS, VALIDATION_FAILED } from "contracts/interfaces/modules/IERC7579Modules.sol";
import { IValidator } from "contracts/interfaces/modules/IValidator.sol";
import { ERC1271_MAGICVALUE, ERC1271_INVALID } from "contracts/types/Constants.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";

/*
 * @title K1Validator
 * @dev A simple validator that checks if the user operation signature is valid
 * THIS VALIDATOR IS NOT FOR PRODUCTION, BUT FOR TESTING PURPOSES ONLY
 * For production use, check Biconomy Modules repo at https://github.com/bcnmy/...
 */

contract K1Validator is IValidator {
    error NoOwnerProvided();

    using SignatureCheckerLib for address;

    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANTS & STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    mapping(address sa => address owner) public smartAccountOwners;

    /*//////////////////////////////////////////////////////////////////////////
                                     CONFIG
    //////////////////////////////////////////////////////////////////////////*/

    // TODO // Review comments
    function onInstall(bytes calldata data) external override {
        if (data.length == 0) revert NoOwnerProvided();
        address owner = address(bytes20(data)); // encodePacked
        // OR // abi.decode(data, (address));
        smartAccountOwners[msg.sender] = owner;
    }

    function onUninstall(bytes calldata) external override {
        delete smartAccountOwners[msg.sender];
    }

    function isInitialized(address smartAccount) external view returns (bool) {
        return smartAccountOwners[smartAccount] != address(0);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODULE LOGIC
    //////////////////////////////////////////////////////////////////////////*/

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    ) external view override returns (uint256) {
        bool validSig = smartAccountOwners[userOp.sender].isValidSignatureNow(
            ECDSA.toEthSignedMessageHash(userOpHash),
            userOp.signature
        );
        if (!validSig) {
            validSig = smartAccountOwners[userOp.sender].isValidSignatureNow(userOpHash, userOp.signature);
        }
        if (!validSig) return VALIDATION_FAILED;
        return VALIDATION_SUCCESS;
    }

    function isValidSignatureWithSender(
        address,
        bytes32 hash,
        bytes calldata data
    ) external view override returns (bytes4) {
        address owner = smartAccountOwners[msg.sender];
        // SHOULD PREPARE REPLAY RESISTANT HASH BY APPENDING MSG.SENDER
        // SEE: https://github.com/bcnmy/scw-contracts/blob/3362262dab34fa0f57e2fbe0e57a4bdbd5318165/contracts/smart-account/modules/EcdsaOwnershipRegistryModule.sol#L122-L132
        // OR USE EIP-712
        return
            SignatureCheckerLib.isValidSignatureNowCalldata(owner, hash, data) ? ERC1271_MAGICVALUE : ERC1271_INVALID;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     METADATA
    //////////////////////////////////////////////////////////////////////////*/

    function getModuleTypes() external view override returns (EncodedModuleTypes) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function name() external pure returns (string memory) {
        return "K1Validator";
    }

    function version() external pure returns (string memory) {
        return "0.0.1";
    }

    function isModuleType(uint256 typeID) external pure override returns (bool) {
        return typeID == MODULE_TYPE_VALIDATOR;
    }

    function test() public pure {
        // solhint-disable-previous-line no-empty-blocks
        // @todo To be removed: This function is used to ignore file in coverage report
    }
}
