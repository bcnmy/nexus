// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { SignatureCheckerLib } from "solady/src/utils/SignatureCheckerLib.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { MODULE_TYPE_VALIDATOR, VALIDATION_SUCCESS, VALIDATION_FAILED } from "contracts/interfaces/modules/IERC7579Modules.sol";
import { IValidator } from "contracts/interfaces/modules/IValidator.sol";
import { ERC1271_MAGICVALUE, ERC1271_INVALID } from "contracts/types/Constants.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";

contract R1Validator is IValidator {
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
        if (data.length == 0) return;
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
        if (!validSig) return VALIDATION_FAILED;
        return VALIDATION_SUCCESS;
    }

    function isValidSignatureWithSender(
        address,
        bytes32 hash,
        bytes calldata data
    ) external view override returns (bytes4) {
        address owner = smartAccountOwners[msg.sender];
        return
            SignatureCheckerLib.isValidSignatureNowCalldata(owner, hash, data) ? ERC1271_MAGICVALUE : ERC1271_INVALID;
    }

    /*//////////////////////////////////////////////////////////////////////////
                                     METADATA
    //////////////////////////////////////////////////////////////////////////*/

    function name() external pure returns (string memory) {
        return "R1Validator";
    }

    function version() external pure returns (string memory) {
        return "0.0.1";
    }

    function isModuleType(uint256 typeID) external pure override returns (bool) {
        return typeID == MODULE_TYPE_VALIDATOR;
    }

    function getModuleTypes() external view override returns (EncodedModuleTypes) {}
}