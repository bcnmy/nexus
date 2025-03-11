// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IPreValidationHookERC1271 } from "../interfaces/modules/IPreValidationHook.sol";
import { MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337 } from "../types/Constants.sol";
import { EIP712 } from "solady/utils/EIP712.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";

contract Mock7739PreValidationHook is IPreValidationHookERC1271 {
    bytes32 internal constant _PERSONAL_SIGN_TYPEHASH = 0x983e65e5148e570cd828ead231ee759a8d7958721a768f93bc4483ba005c32de;
    bytes32 internal constant _DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    address public immutable prevalidationHookMultiplexer;

    constructor(address _prevalidationHookMultiplexer) {
        prevalidationHookMultiplexer = _prevalidationHookMultiplexer;
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

    function isTrustedForwarder(address forwarder) public view returns (bool) {
        return forwarder == prevalidationHookMultiplexer;
    }

    function preValidationHookERC1271(address, bytes32 hash, bytes calldata data) external view returns (bytes32 hookHash, bytes memory hookSignature) {
        address account = _msgSender();
        // Check flag in first byte
        if (data[0] == 0x00) {
            return wrapFor7739Validation(account, hash, _erc1271UnwrapSignature(data[1:]));
        }
        return (hash, data[1:]);
    }

    function wrapFor7739Validation(address account, bytes32 hash, bytes calldata signature) internal view virtual returns (bytes32, bytes calldata) {
        bytes32 t = _typedDataSignFieldsForAccount(account);
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Cache the free memory pointer.
            // `c` is `contentsType.length`, which is stored in the last 2 bytes of the signature.
            let c := shr(240, calldataload(add(signature.offset, sub(signature.length, 2))))
            for { } 1 { } {
                let l := add(0x42, c) // Total length of appended data (32 + 32 + c + 2).
                let o := add(signature.offset, sub(signature.length, l)) // Offset of appended data.
                mstore(0x00, 0x1901) // Store the "\x19\x01" prefix.
                calldatacopy(0x20, o, 0x40) // Copy the `APP_DOMAIN_SEPARATOR` and `contents` struct hash.
                // Use the `PersonalSign` workflow if the reconstructed hash doesn't match,
                // or if the appended data is invalid, i.e.
                // `appendedData.length > signature.length || contentsType.length == 0`.
                if or(xor(keccak256(0x1e, 0x42), hash), or(lt(signature.length, l), iszero(c))) {
                    t := 0 // Set `t` to 0, denoting that we need to `hash = _hashTypedData(hash)`.
                    mstore(t, _PERSONAL_SIGN_TYPEHASH)
                    mstore(0x20, hash) // Store the `prefixed`.
                    hash := keccak256(t, 0x40) // Compute the `PersonalSign` struct hash.
                    break
                }
                // Else, use the `TypedDataSign` workflow.
                // `TypedDataSign({ContentsName} contents,bytes1 fields,...){ContentsType}`.
                mstore(m, "TypedDataSign(") // Store the start of `TypedDataSign`'s type encoding.
                let p := add(m, 0x0e) // Advance 14 bytes to skip "TypedDataSign(".
                calldatacopy(p, add(o, 0x40), c) // Copy `contentsType` to extract `contentsName`.
                // `d & 1 == 1` means that `contentsName` is invalid.
                let d := shr(byte(0, mload(p)), 0x7fffffe000000000000010000000000) // Starts with `[a-z(]`.
                // Store the end sentinel '(', and advance `p` until we encounter a '(' byte.
                for { mstore(add(p, c), 40) } iszero(eq(byte(0, mload(p)), 40)) { p := add(p, 1) } { d := or(shr(byte(0, mload(p)), 0x120100000001), d) } // Has
                // a byte in ", )\x00".

                mstore(p, " contents,bytes1 fields,string n") // Store the rest of the encoding.
                mstore(add(p, 0x20), "ame,string version,uint256 chain")
                mstore(add(p, 0x40), "Id,address verifyingContract,byt")
                mstore(add(p, 0x60), "es32 salt,uint256[] extensions)")
                p := add(p, 0x7f)
                calldatacopy(p, add(o, 0x40), c) // Copy `contentsType`.
                // Fill in the missing fields of the `TypedDataSign`.
                calldatacopy(t, o, 0x40) // Copy the `contents` struct hash to `add(t, 0x20)`.
                mstore(t, keccak256(m, sub(add(p, c), m))) // Store `typedDataSignTypehash`.
                // The "\x19\x01" prefix is already at 0x00.
                // `APP_DOMAIN_SEPARATOR` is already at 0x20.
                mstore(0x40, keccak256(t, 0x120)) // `hashStruct(typedDataSign)`.
                // Compute the final hash, corrupted if `contentsName` is invalid.
                hash := keccak256(0x1e, add(0x42, and(1, d)))
                signature.length := sub(signature.length, l) // Truncate the signature.
                break
            }
            mstore(0x40, m) // Restore the free memory pointer.
        }
        if (t == bytes32(0)) hash = _hashTypedDataForAccount(account, hash); // `PersonalSign` workflow.
        return (hash, signature);
    }

    /// @dev Unwraps and returns the signature.
    function _erc1271UnwrapSignature(bytes calldata signature) internal view virtual returns (bytes calldata result) {
        result = signature;
        /// @solidity memory-safe-assembly
        assembly {
            // Unwraps the ERC6492 wrapper if it exists.
            // See: https://eips.ethereum.org/EIPS/eip-6492
            if eq(
                calldataload(add(result.offset, sub(result.length, 0x20))),
                mul(0x6492, div(not(mload(0x60)), 0xffff)) // `0x6492...6492`.
            ) {
                let o := add(result.offset, calldataload(add(result.offset, 0x40)))
                result.length := calldataload(o)
                result.offset := add(o, 0x20)
            }
        }
    }

    /// @dev For use in `_erc1271IsValidSignatureViaNestedEIP712`,
    function _typedDataSignFieldsForAccount(address account) private view returns (bytes32 m) {
        (bytes1 fields, string memory name, string memory version, uint256 chainId, address verifyingContract, bytes32 salt, uint256[] memory extensions) =
            EIP712(account).eip712Domain();
        /// @solidity memory-safe-assembly
        assembly {
            m := mload(0x40) // Grab the free memory pointer.
            mstore(0x40, add(m, 0x120)) // Allocate the memory.
            // Skip 2 words for the `typedDataSignTypehash` and `contents` struct hash.
            mstore(add(m, 0x40), shl(248, byte(0, fields)))
            mstore(add(m, 0x60), keccak256(add(name, 0x20), mload(name)))
            mstore(add(m, 0x80), keccak256(add(version, 0x20), mload(version)))
            mstore(add(m, 0xa0), chainId)
            mstore(add(m, 0xc0), shr(96, shl(96, verifyingContract)))
            mstore(add(m, 0xe0), salt)
            mstore(add(m, 0x100), keccak256(add(extensions, 0x20), shl(5, mload(extensions))))
        }
    }

    /// @notice Hashes typed data according to eip-712
    ///         Uses account's domain separator
    /// @param account the smart account, who's domain separator will be used
    /// @param structHash the typed data struct hash
    function _hashTypedDataForAccount(address account, bytes32 structHash) private view returns (bytes32 digest) {
        (
            ,
            /*bytes1 fields*/
            string memory name,
            string memory version,
            uint256 chainId,
            address verifyingContract, /*bytes32 salt*/ /*uint256[] memory extensions*/
            ,
        ) = EIP712(account).eip712Domain();

        /// @solidity memory-safe-assembly
        assembly {
            //Rebuild domain separator out of 712 domain
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), keccak256(add(name, 0x20), mload(name))) // Name hash.
            mstore(add(m, 0x40), keccak256(add(version, 0x20), mload(version))) // Version hash.
            mstore(add(m, 0x60), chainId)
            mstore(add(m, 0x80), verifyingContract)
            digest := keccak256(m, 0xa0) //domain separator

            // Hash typed data
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, digest) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }

    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC1271 || moduleTypeId == MODULE_TYPE_PREVALIDATION_HOOK_ERC4337;
    }

    function isInitialized(address) external pure returns (bool) {
        return true;
    }
}
