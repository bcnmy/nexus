// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.27;

import { ECDSA } from "solady/utils/ECDSA.sol";

contract MockSigVerifier {
    using ECDSA for bytes32;

    constructor() {
    }

    function verify(bytes32 hash, bytes calldata signature, address signer) external view returns (bool) {
        if (_recoverSigner(hash, signature) == signer) return true;
        if (_recoverSigner(hash.toEthSignedMessageHash(), signature) == signer) return true;
        return false;
    }

    function _recoverSigner(bytes32 hash, bytes calldata signature) internal view returns (address) {
        return hash.tryRecover(signature);
    }
}
