// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IValidator } from "../interfaces/modules/IValidator.sol";
import { VALIDATION_SUCCESS, VALIDATION_FAILED, MODULE_TYPE_VALIDATOR } from "../types/Constants.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { ECDSA } from "solady/utils/ECDSA.sol";

contract MockSimpleValidator is IValidator {
    using ECDSA for bytes32;

    mapping(address => address) public smartAccountOwners;

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external view returns (uint256) {
        address owner = smartAccountOwners[msg.sender];
        return verify(owner, userOpHash, userOp.signature) ? VALIDATION_SUCCESS : VALIDATION_FAILED;
    }

    function isValidSignatureWithSender(address, bytes32 hash, bytes calldata signature) external view returns (bytes4) {
        address owner = smartAccountOwners[msg.sender];
        return verify(owner, hash, signature) ? bytes4(0x1626ba7e) : bytes4(0xffffffff);
    }

    function verify(address signer, bytes32 hash, bytes calldata signature) internal view returns (bool) {
        if (signer == hash.recover(signature)) {
            return true;
        }
        if (signer == hash.toEthSignedMessageHash().recover(signature)) {
            return true;
        }
        return false;
    }

    function onInstall(bytes calldata data) external {
        smartAccountOwners[msg.sender] = address(bytes20(data));
    }

    function onUninstall(bytes calldata) external {
        delete smartAccountOwners[msg.sender];
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function isInitialized(address) external pure returns (bool) {
        return false;
    }
}
