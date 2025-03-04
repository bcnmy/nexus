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
// Learn more at https://biconomy.io. To report security issues, please contact us at: security@biconomy.io

import { ECDSA } from "solady/utils/ECDSA.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { ERC7739Validator } from "erc7739Validator/ERC7739Validator.sol";
import { IValidator } from "../../interfaces/modules/IValidator.sol";
import { EnumerableSet } from "../../lib/EnumerableSet4337.sol";
import { MODULE_TYPE_VALIDATOR, VALIDATION_SUCCESS, VALIDATION_FAILED } from "../../types/Constants.sol";

/// @title Nexus - K1Validator (ECDSA)
/// @notice Validator module for smart accounts, verifying user operation signatures
///         based on the K1 curve (secp256k1), a widely used ECDSA algorithm.
/// @dev Implements secure ownership validation by checking signatures against registered
///      owners. This module supports ERC-7579 and ERC-4337 standards, ensuring only the
///      legitimate owner of a smart account can authorize transactions.
///      Implements ERC-7739
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract K1Validator is IValidator, ERC7739Validator {
    using ECDSA for bytes32;
    using EnumerableSet for EnumerableSet.AddressSet;

    /*//////////////////////////////////////////////////////////////////////////
                            CONSTANTS & STORAGE
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Mapping of smart account addresses to their respective owner addresses
    mapping(address => address) public smartAccountOwners;

    EnumerableSet.AddressSet private _safeSenders;

    /// @notice Error to indicate that no owner was provided during installation
    error NoOwnerProvided();

    /// @notice Error to indicate that the new owner cannot be the zero address
    error ZeroAddressNotAllowed();

    /// @notice Error to indicate the module is already initialized
    error ModuleAlreadyInitialized();

    /// @notice Error to indicate that the new owner cannot be a contract address
    error NewOwnerIsContract();

    /// @notice Error to indicate that the owner cannot be the zero address
    error OwnerCannotBeZeroAddress();

    /// @notice Error to indicate that the data length is invalid
    error InvalidDataLength();

    /*//////////////////////////////////////////////////////////////////////////
                                     CONFIG
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * Initialize the module with the given data
     *
     * @param data The data to initialize the module with
     */
    function onInstall(bytes calldata data) external override {
        require(data.length != 0, NoOwnerProvided());
        require(!_isInitialized(msg.sender), ModuleAlreadyInitialized());
        address newOwner = address(bytes20(data[:20]));
        require(newOwner != address(0), OwnerCannotBeZeroAddress());
        require(!_isContract(newOwner), NewOwnerIsContract());
        smartAccountOwners[msg.sender] = newOwner;
        if (data.length > 20) {
            _fillSafeSenders(data[20:]);
        }
    }

    /**
     * De-initialize the module with the given data
     */
    function onUninstall(bytes calldata) external override {
        delete smartAccountOwners[msg.sender];
        _safeSenders.removeAll(msg.sender);
    }

    /// @notice Transfers ownership of the validator to a new owner
    /// @param newOwner The address of the new owner
    function transferOwnership(address newOwner) external {
        require(newOwner != address(0), ZeroAddressNotAllowed());
        require(!_isContract(newOwner), NewOwnerIsContract());
        smartAccountOwners[msg.sender] = newOwner;
    }

    /// @notice Adds a safe sender to the _safeSenders list for the smart account
    function addSafeSender(address sender) external {
        _safeSenders.add(msg.sender, sender);
    }

    /// @notice Removes a safe sender from the _safeSenders list for the smart account
    function removeSafeSender(address sender) external {
        _safeSenders.remove(msg.sender, sender);
    }

    /// @notice Checks if a sender is in the _safeSenders list for the smart account
    function isSafeSender(address sender, address smartAccount) external view returns (bool) {
        return _safeSenders.contains(smartAccount, sender);
    }

    /**
     * Check if the module is initialized
     * @param smartAccount The smart account to check
     *
     * @return true if the module is initialized, false otherwise
     */
    function isInitialized(address smartAccount) external view returns (bool) {
        return _isInitialized(smartAccount);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     MODULE LOGIC
    //////////////////////////////////////////////////////////////////////////*/

    /**
     * Validates PackedUserOperation
     *
     * @param userOp UserOperation to be validated
     * @param userOpHash Hash of the UserOperation to be validated
     *
     * @return uint256 the result of the signature validation, which can be:
     *  - 0 if the signature is valid
     *  - 1 if the signature is invalid
     *  - <20-byte> aggregatorOrSigFail, <6-byte> validUntil and <6-byte> validAfter (see ERC-4337
     * for more details)
     */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external view override returns (uint256) {
        return _validateSignatureForOwner(smartAccountOwners[userOp.sender], userOpHash, userOp.signature) ? VALIDATION_SUCCESS : VALIDATION_FAILED;
    }

    /**
     * Validates an ERC-1271 signature
     * @dev implements signature malleability prevention
     *      see: https://eips.ethereum.org/EIPS/eip-1271#reference-implementation
     * Please note, that this prevention does not protect against replay attacks in general
     * So the protocol using ERC-1271 should make sure hash is replay-safe.
     *
     * @param sender The sender of the ERC-1271 call to the account
     * @param hash The hash of the message
     * @param signature The signature of the message
     *
     * @return sigValidationResult the result of the signature validation, which can be:
     *  - EIP1271_SUCCESS if the signature is valid
     *  - EIP1271_FAILED if the signature is invalid
     *  - 0x7739000X if this is the ERC-7739 support detection request.
     *  Where X is the version of the ERC-7739 support.
     */
    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata signature
    ) external view virtual override returns (bytes4) {
        return _erc1271IsValidSignatureWithSender(sender, hash, _erc1271UnwrapSignature(signature));
    }

    /// @notice ISessionValidator interface for smart session
    /// @param hash The hash of the data to validate
    /// @param sig The signature data
    /// @param data The data to validate against (owner address in this case)
    function validateSignatureWithData(bytes32 hash, bytes calldata sig, bytes calldata data) external view returns (bool validSig) {
        require(data.length == 20, InvalidDataLength());
        address owner = address(bytes20(data[0:20]));
        return _validateSignatureForOwner(owner, hash, sig);
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     METADATA
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Returns the name of the module
    /// @return The name of the module
    function name() external pure returns (string memory) {
        return "K1Validator";
    }

    /// @notice Returns the version of the module
    /// @return The version of the module
    function version() external pure returns (string memory) {
        return "1.0.1";
    }

    /// @notice Checks if the module is of the specified type
    /// @param typeId The type ID to check
    /// @return True if the module is of the specified type, false otherwise
    function isModuleType(uint256 typeId) external pure returns (bool) {
        return typeId == MODULE_TYPE_VALIDATOR;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     INTERNAL
    //////////////////////////////////////////////////////////////////////////*/

    /// @notice Recovers the signer from a signature
    /// @param hash The hash of the data to validate
    /// @param signature The signature data
    /// @return The recovered signer address
    /// @notice tryRecover returns address(0) on invalid signature
    function _recoverSigner(bytes32 hash, bytes calldata signature) internal view returns (address) {
        return hash.tryRecover(signature);
    }

    /// @dev Returns whether the `hash` and `signature` are valid.
    ///      Obtains the authorized signer's credentials and calls some
    ///      module's specific internal function to validate the signature
    ///      against credentials.
    function _erc1271IsValidSignatureNowCalldata(bytes32 hash, bytes calldata signature) internal view override returns (bool) {
        // call custom internal function to validate the signature against credentials
        return _validateSignatureForOwner(smartAccountOwners[msg.sender], hash, signature);
    }

    /// @dev Returns whether the `sender` is considered safe, such
    /// that we don't need to use the nested EIP-712 workflow.
    /// See: https://mirror.xyz/curiousapple.eth/pFqAdW2LiJ-6S4sg_u1z08k4vK6BCJ33LcyXpnNb8yU
    // The canonical `MulticallerWithSigner` at 0x000000000000D9ECebf3C23529de49815Dac1c4c
    // is known to include the account in the hash to be signed.
    // msg.sender = Smart Account
    // sender = 1271 og request sender
    function _erc1271CallerIsSafe(address sender) internal view virtual override returns (bool) {
        return (sender == 0x000000000000D9ECebf3C23529de49815Dac1c4c || // MulticallerWithSigner
            sender == msg.sender || // Smart Account. Assume smart account never sends non safe eip-712 struct
            _safeSenders.contains(msg.sender, sender)); // check if sender is in _safeSenders for the Smart Account
    }

    /// @notice Internal method that does the job of validating the signature via ECDSA (secp256k1)
    /// @param owner The address of the owner
    /// @param hash The hash of the data to validate
    /// @param signature The signature data
    function _validateSignatureForOwner(address owner, bytes32 hash, bytes calldata signature) internal view returns (bool) {
        // verify signer
        // owner can not be zero address in this contract
        if (_recoverSigner(hash, signature) == owner) return true;
        if (_recoverSigner(hash.toEthSignedMessageHash(), signature) == owner) return true;
        return false;
    }

    // @notice Fills the _safeSenders list from the given data
    function _fillSafeSenders(bytes calldata data) private {
        for (uint256 i; i < data.length / 20; i++) {
            _safeSenders.add(msg.sender, address(bytes20(data[20 * i:20 * (i + 1)])));
        }
    }

    /// @notice Checks if the smart account is initialized with an owner
    /// @param smartAccount The address of the smart account
    /// @return True if the smart account has an owner, false otherwise
    function _isInitialized(address smartAccount) private view returns (bool) {
        return smartAccountOwners[smartAccount] != address(0);
    }

    /// @notice Checks if the address is a contract
    /// @param account The address to check
    /// @return True if the address is a contract, false otherwise
    function _isContract(address account) private view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
