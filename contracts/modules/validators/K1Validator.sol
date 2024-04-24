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
// Nexus: A suite of contracts for Modular Smart Accounts compliant with ERC-7579 and ERC-4337,
// using Entrypoint version 0.7.0, developed by Biconomy. Learn more at https://biconomy.io/

import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { SignatureCheckerLib } from "solady/src/utils/SignatureCheckerLib.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

import { ERC1271_MAGICVALUE, ERC1271_INVALID } from "contracts/types/Constants.sol";
import { MODULE_TYPE_VALIDATOR, VALIDATION_SUCCESS, VALIDATION_FAILED } from "contracts/types/Constants.sol";

/// @title Nexus - K1Validator
/// @notice This contract is a simple validator for testing purposes, verifying user operation signatures against registered owners.
/// @dev It validates signatures using the SignatureCheckerLib, and should not be used in production environments.
/// This contract exemplifies a module that checks if the user operation signature is valid according to ERC-1271 standards.
/// For production-ready modules, please refer to the Biconomy Modules repository.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract K1Validator {
    using SignatureCheckerLib for address;

    mapping(address sa => address owner) public smartAccountOwners;

    error NoOwnerProvided();

    // TODO // Review comments
    function onInstall(bytes calldata data) external {
        if (data.length == 0) revert NoOwnerProvided();
        address owner = address(bytes20(data)); // encodePacked
        // OR // abi.decode(data, (address));
        smartAccountOwners[msg.sender] = owner;
    }

    function onUninstall(bytes calldata) external {
        delete smartAccountOwners[msg.sender];
    }

    function isInitialized(address smartAccount) external view returns (bool) {
        return smartAccountOwners[smartAccount] != address(0);
    }

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external view returns (uint256) {
        bool validSig = smartAccountOwners[userOp.sender].isValidSignatureNow(ECDSA.toEthSignedMessageHash(userOpHash), userOp.signature);
        if (!validSig) {
            validSig = smartAccountOwners[userOp.sender].isValidSignatureNow(userOpHash, userOp.signature);
        }
        if (!validSig) return VALIDATION_FAILED;
        return VALIDATION_SUCCESS;
    }

    function isValidSignatureWithSender(address, bytes32 hash, bytes calldata data) external view returns (bytes4) {
        address owner = smartAccountOwners[msg.sender];
        // SHOULD PREPARE REPLAY RESISTANT HASH BY APPENDING MSG.SENDER
        // SEE:
        // https://github.com/bcnmy/scw-contracts/blob/develop/contracts/smart-account/modules/EcdsaOwnershipRegistryModule.sol#L122
        // OR USE EIP-712
        return SignatureCheckerLib.isValidSignatureNowCalldata(owner, hash, data) ? ERC1271_MAGICVALUE : ERC1271_INVALID;
    }

    function name() external pure returns (string memory) {
        return "K1Validator";
    }

    function version() external pure returns (string memory) {
        return "0.0.1";
    }

    function isModuleType(uint256 typeID) external pure returns (bool) {
        return typeID == MODULE_TYPE_VALIDATOR;
    }

    function test() public pure {
        // solhint-disable-previous-line no-empty-blocks
        // @todo To be removed: This function is used to ignore file in coverage report
    }
}
