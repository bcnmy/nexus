// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC7579ModuleBase } from "../../../contracts/interfaces/modules/IERC7579ModuleBase.sol";
import { IValidator } from "../../../contracts/interfaces/modules/IValidator.sol";
import { VALIDATION_SUCCESS, VALIDATION_FAILED, MODULE_TYPE_VALIDATOR } from "../../../contracts/types/Constants.sol";
import { EncodedModuleTypes } from "../../../contracts/lib/ModuleTypeLib.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MockValidator {
    mapping(address => address) public smartAccountOwners;

    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    )
        external
        view
        returns (uint256 validation)
    {
        return ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(userOpHash), userOp.signature)
            == smartAccountOwners[msg.sender] ? VALIDATION_SUCCESS : VALIDATION_FAILED;
    }

    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata signature
    )
        external
        pure
        returns (bytes4)
    {
        sender;
        hash;
        signature;
        return 0xffffffff;
    }

    function onInstall(bytes calldata data) external {
        smartAccountOwners[msg.sender] = address(bytes20(data));
    }

    function onUninstall(bytes calldata data) external {
        data;
        delete smartAccountOwners[msg.sender];
    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function isOwner(address account, address owner) external view returns (bool) {
        return smartAccountOwners[account] == owner;
    }

    function isInitialized(address smartAccount) external pure returns (bool) {
        return false;
    }

    function getOwner(address account) external view returns (address) {
        return smartAccountOwners[account];
    }

    // Review
    function test(uint256 a) public pure {
        a;
    }
}
