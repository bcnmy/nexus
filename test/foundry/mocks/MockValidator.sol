// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IModule } from "../../../contracts/interfaces/modules/IERC7579Modules.sol";
import {
    IValidator,
    VALIDATION_SUCCESS,
    VALIDATION_FAILED,
    MODULE_TYPE_VALIDATOR
} from "../../../contracts/interfaces/modules/IERC7579Modules.sol";
import { ERC1271_MAGICVALUE, ERC1271_INVALID } from "../../../contracts/types/Constants.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { SignatureCheckerLib } from "solady/src/utils/SignatureCheckerLib.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MockValidator is IValidator {
    mapping(address => address) public smartAccountOwners;

    /// @inheritdoc IValidator
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

    /// @inheritdoc IValidator
    function isValidSignatureWithSender(
        address,
        bytes32 hash,
        bytes calldata signature
    )
        external
        view
        returns (bytes4)
    {
        address owner = smartAccountOwners[msg.sender];
        // SHOULD PREPARE REPLAY RESISTANT HASH BY APPENDING MSG.SENDER
        // SEE: https://github.com/bcnmy/scw-contracts/blob/3362262dab34fa0f57e2fbe0e57a4bdbd5318165/contracts/smart-account/modules/EcdsaOwnershipRegistryModule.sol#L122-L132
        // OR USE EIP-712
        return
            SignatureCheckerLib.isValidSignatureNowCalldata(owner, hash, signature) ? ERC1271_MAGICVALUE : ERC1271_INVALID;
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