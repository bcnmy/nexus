// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// ─────────────────────────────────────────────────────────────────────────────
///     _   __    _  __
///    / | / /__ | |/ /_  _______
///   /  |/ / _ \|   / / / / ___/
///  / /|  /  __/   / /_/ (__  )
/// /_/ |_/\___/_/|_\__,_/____/
///
/// ─────────────────────────────────────────────────────────────────────────────
/// Nexus: A suite of contracts for Modular Smart Account compliant with ERC-7579
/// and ERC-4337, developed by Biconomy. Learn more at https://biconomy.io.
/// To report security issues, please contact us at: security@biconomy.io

import { EIP712 } from "solady/src/utils/EIP712.sol";

import { Storage } from "./Storage.sol";

/// @title SignatureHandler
/// @notice Handles EIP-712 signature validation for the Nexus suite.
/// @dev Implements nested EIP-712 signature validation to prevent replays.
contract SignatureHandler is EIP712, Storage {
    /// @notice Returns the EIP-712 typed hash of the `BiconomyNexusMessage(bytes32 hash)` data structure.
    ///
    /// @dev Implements encode(domainSeparator : 𝔹²⁵⁶, message : 𝕊) = "\x19\x01" || domainSeparator ||
    ///      hashStruct(message).
    /// @dev See https://eips.ethereum.org/EIPS/eip-712#specification.
    ///
    /// @param hash The `BiconomyNexusMessage.hash` field to hash.
    ////
    /// @return The resulting EIP-712 hash.
    function _eip712Hash(bytes32 hash) internal view virtual returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator(), keccak256(abi.encode(_MESSAGE_TYPEHASH, hash))));
    }

    /// @dev ERC1271 signature validation (Nested EIP-712 workflow).
    ///
    /// This implementation uses a nested EIP-712 approach to
    /// prevent signature replays when a single signer owns multiple smart contract accounts,
    /// while still enabling wallet UIs (e.g. Metamask) to show the EIP-712 values.
    ///
    /// Crafted for phishing resistance, efficiency, flexibility.
    /// __________________________________________________________________________________________
    ///
    /// Glossary:
    ///
    /// - `APP_DOMAIN_SEPARATOR`: The domain separator of the `hash`.
    ///   Provided by the front end. Intended to be the domain separator of the contract
    ///   that will call `isValidSignature` on this account.
    ///
    /// - `ACCOUNT_DOMAIN_SEPARATOR`: The domain separator of this account.
    ///   See: `EIP712._domainSeparator()`.
    /// __________________________________________________________________________________________
    ///
    /// For the `TypedDataSign` workflow, the final hash will be:
    /// ```
    ///     keccak256(\x19\x01 ‖ APP_DOMAIN_SEPARATOR ‖
    ///         hashStruct(TypedDataSign({
    ///             contents: hashStruct(originalStruct),
    ///             name: keccak256(bytes(eip712Domain().name)),
    ///             version: keccak256(bytes(eip712Domain().version)),
    ///             chainId: eip712Domain().chainId,
    ///             verifyingContract: eip712Domain().verifyingContract,
    ///             salt: eip712Domain().salt
    ///             extensions: keccak256(abi.encodePacked(eip712Domain().extensions))
    ///         }))
    ///     )
    /// ```
    /// where `‖` denotes the concatenation operator for bytes.
    /// The order of the fields is important: `contents` comes before `name`.
    ///
    /// The signature will be `r ‖ s ‖ v ‖
    ///     APP_DOMAIN_SEPARATOR ‖ contents ‖ contentsType ‖ uint16(contentsType.length)`,
    /// where `contents` is the bytes32 struct hash of the original struct.
    ///
    /// The `APP_DOMAIN_SEPARATOR` and `contents` will be used to verify if `hash` is indeed correct.
    /// __________________________________________________________________________________________
    ///
    /// For the `PersonalSign` workflow, the final hash will be:
    /// ```
    ///     keccak256(\x19\x01 ‖ ACCOUNT_DOMAIN_SEPARATOR ‖
    ///         hashStruct(PersonalSign({
    ///             prefixed: keccak256(bytes(\x19Ethereum Signed Message:\n ‖
    ///                 base10(bytes(someString).length) ‖ someString))
    ///         }))
    ///     )
    /// ```
    /// where `‖` denotes the concatenation operator for bytes.
    ///
    /// The `PersonalSign` type hash will be `keccak256("PersonalSign(bytes prefixed)")`.
    /// The signature will be `r ‖ s ‖ v`.
    /// __________________________________________________________________________________________
    ///
    /// For demo and typescript code, see:
    /// - https://github.com/junomonster/nested-eip-712
    /// - https://github.com/frangio/eip712-wrapper-for-eip1271
    ///
    /// Their nomenclature may differ from ours, although the high-level idea is similar.
    ///
    /// Of course, if you have control over the codebase of the wallet client(s) too,
    /// you can choose a more minimalistic signature scheme like
    /// `keccak256(abi.encode(address(this), hash))` instead of all these acrobatics.
    /// All these are just for widespread out-of-the-box compatibility with other wallet clients.
    function _erc1271HashForIsValidSignatureViaNestedEIP712(
        bytes32 hash,
        bytes calldata signature
    ) internal view virtual returns (bytes32, bytes calldata) {
        assembly {
            // Unwraps the ERC6492 wrapper if it exists.
            // See: https://eips.ethereum.org/EIPS/eip-6492
            if eq(
                calldataload(add(signature.offset, sub(signature.length, 0x20))),
                mul(0x6492, div(not(mload(0x60)), 0xffff)) // `0x6492...6492`.
            ) {
                let o := add(signature.offset, calldataload(add(signature.offset, 0x40)))
                signature.length := calldataload(o)
                signature.offset := add(o, 0x20)
            }
        }

        bool result;
        bytes32 t = _typedDataSignFields();
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            // Length of the contents type.
            let c := and(0xffff, calldataload(add(signature.offset, sub(signature.length, 0x20))))
            for {

            } 1 {

            } {
                let l := add(0x42, c) // Total length of appended data (32 + 32 + c + 2).
                let o := add(signature.offset, sub(signature.length, l))
                calldatacopy(0x20, o, 0x40) // Copy the `APP_DOMAIN_SEPARATOR` and contents struct hash.
                mstore(0x00, 0x1901) // Store the "\x19\x01" prefix.
                // Use the `PersonalSign` workflow if the reconstructed contents hash doesn't match,
                // or if the appended data is invalid (length too long, or empty contents type).
                if or(xor(keccak256(0x1e, 0x42), hash), or(lt(signature.length, l), iszero(c))) {
                    mstore(0x00, _PERSONAL_SIGN_TYPEHASH)
                    mstore(0x20, hash) // Store the `prefixed`.
                    hash := keccak256(0x00, 0x40) // Compute the `PersonalSign` struct hash.
                    break
                }
                // Else, use the `TypedDataSign` workflow.
                mstore(m, "TypedDataSign(") // To construct `TYPED_DATA_SIGN_TYPEHASH` on-the-fly.
                let p := add(m, 0x0e) // Advance 14 bytes.
                calldatacopy(p, add(o, 0x40), c) // Copy the contents type.
                let d := byte(0, mload(p)) // For denoting if the contents name is invalid.
                d := or(gt(26, sub(d, 97)), eq(40, d)) // Starts with lowercase or '('.
                // Store the end sentinel '(', and advance `p` until we encounter a '(' byte.
                for {
                    mstore(add(p, c), 40)
                } 1 {
                    p := add(p, 1)
                } {
                    let b := byte(0, mload(p))
                    if eq(40, b) {
                        break
                    }
                    d := or(d, shr(b, 0x120100000001)) // Has a byte in ", )\x00".
                }
                mstore(p, " contents,bytes1 fields,string n")
                mstore(add(p, 0x20), "ame,string version,uint256 chain")
                mstore(add(p, 0x40), "Id,address verifyingContract,byt")
                mstore(add(p, 0x60), "es32 salt,uint256[] extensions)")
                calldatacopy(add(p, 0x7f), add(o, 0x40), c) // Copy the contents type.
                // Fill in the missing fields of the `TypedDataSign`.
                calldatacopy(t, o, 0x40) // Copy `contents` to `add(t, 0x20)`.
                mstore(t, keccak256(m, sub(add(add(p, 0x7f), c), m))) // `TYPED_DATA_SIGN_TYPEHASH`.
                // The "\x19\x01" prefix is already at 0x00.
                // `APP_DOMAIN_SEPARATOR` is already at 0x20.
                mstore(0x40, keccak256(t, 0x120)) // `hashStruct(typedDataSign)`.
                // Compute the final hash, corrupted if the contents name is invalid.
                hash := keccak256(0x1e, add(0x42, and(1, d)))
                result := 1 // Use `result` to temporarily denote if we will use `APP_DOMAIN_SEPARATOR`.
                signature.length := sub(signature.length, l) // Truncate the signature.
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
        }
        if (!result) hash = _hashTypedData(hash);
        return (hash, signature);
    }

    /// @dev EIP712 domain name and version.
    /// @return name The domain name.
    /// @return version The domain version.
    function _domainNameAndVersion() internal pure override returns (string memory name, string memory version) {
        name = "Nexus";
        version = "0.0.1";
    }

    /// @dev For use in `_erc1271HashForIsValidSignatureViaNestedEIP712`,
    ///      Constructs the typed data sign fields.
    /// @return m The constructed fields.
    function _typedDataSignFields() private view returns (bytes32 m) {
        (
            bytes1 fields,
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract,
            bytes32 salt,
            uint256[] memory extensions
        ) = eip712Domain();
        /// @solidity memory-safe-assembly
        assembly {
            m := mload(0x40) // Grab the free memory pointer.
            mstore(0x40, add(m, 0x120)) // Allocate the memory.
            // Skip 2 words: `TYPED_DATA_SIGN_TYPEHASH, contents`.
            mstore(add(m, 0x40), shl(248, byte(0, fields)))
            mstore(add(m, 0x60), keccak256(add(name, 0x20), mload(name)))
            mstore(add(m, 0x80), keccak256(add(version, 0x20), mload(version)))
            mstore(add(m, 0xa0), chainId)
            mstore(add(m, 0xc0), shr(96, shl(96, verifyingContract)))
            mstore(add(m, 0xe0), salt)
            mstore(add(m, 0x100), keccak256(add(extensions, 0x20), shl(5, mload(extensions))))
        }
    }
}
