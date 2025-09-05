// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {EfficientHashLib} from "solady/utils/EfficientHashLib.sol";
import {LibBit} from "solady/utils/LibBit.sol";
import {ECDSA} from "solady/utils/ECDSA.sol";
import {LibBytes} from "solady/utils/LibBytes.sol";
import {LibEIP7702} from "solady/accounts/LibEIP7702.sol";

/// @title LibPREP
/// @notice A library to encapsulate the PREP (Provably Rootless EIP-7702 Proxy) workflow.
/// See: https://blog.biconomy.io/prep-deep-dive/
library LibPREP {
    /// @dev Validates if `digest` and `saltAndDelegation` results in `target`.
    /// `saltAndDelegation` is `bytes32((uint256(salt) << 160) | uint160(delegation))`.
    /// Returns a non-zero `r` for the PREP signature, if valid.
    /// Otherwise returns 0.
    /// `r` will be less than `2**160`, allowing for optional storage packing.
    function rPREP(address target, bytes32 digest, bytes32 saltAndDelegation)
        internal
        view
        returns (bytes32 r)
    {
        r = (EfficientHashLib.hash(digest, saltAndDelegation >> 160) << 96) >> 96;
        if (!isValid(target, r, address(uint160(uint256(saltAndDelegation))))) r = 0;
    }

    /// @dev Returns if `r` and `delegation` results in `target`.
    function isValid(address target, bytes32 r, address delegation) internal view returns (bool) {
        bytes32 s = EfficientHashLib.hash(r);
        bytes32 h; // `keccak256(abi.encodePacked(hex"05", LibRLP.p(0).p(delegation).p(0).encode()))`.
        assembly ("memory-safe") {
            mstore(0x20, 0x80)
            mstore(0x1f, delegation)
            mstore(0x0b, 0x05d78094)
            h := keccak256(0x27, 0x19)
        }
        return LibBit.and(target != address(0), ECDSA.tryRecover(h, 27, r, s) == target);
    }

    /// @dev Returns if `target` is a PREP.
    function isPREP(address target, bytes32 r) internal view returns (bool) {
        address delegation = LibEIP7702.delegation(target);
        return !LibBit.or(delegation == address(0), r == 0) && isValid(target, r, delegation);
    }
}
