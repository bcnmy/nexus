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
import { EncodedModuleTypes } from "../../../contracts/lib/ModuleTypeLib.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { SignatureCheckerLib } from "solady/src/utils/SignatureCheckerLib.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MockValidator1271 is IValidator {

    string internal constant NAME = "Mock Validator 1271";
    string internal constant VERSION = "0.0.1";

    // d87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472
    bytes32 private constant _TYPE_HASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
    );
    bytes32 private constant _HASHED_NAME = keccak256(bytes(NAME));

    bytes32 private constant _HASHED_VERSION = keccak256(bytes(VERSION));

    bytes32 private immutable _SALT = bytes32(bytes20(address(this)));

    bytes32 private constant ACCOUNT_TYPEHASH = keccak256("BiconomyNexusMessage(bytes message)");

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
        address sender,
        bytes32 hash,
        bytes calldata signature
    )
        external
        view
        returns (bytes4)
    {
        address ownerOfSender = smartAccountOwners[sender];
        bytes32 messageHash = getMessageHash(sender, abi.encode(hash));
        if(SignatureCheckerLib.isValidERC1271SignatureNow(ownerOfSender, messageHash, signature)) {
          return ERC1271_MAGICVALUE;
        } else {
          return ERC1271_INVALID;
        }
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

     function encodeMessageData(address account, bytes memory message)
        public
        view
        returns (bytes memory)
    {
        bytes32 messageHash = keccak256(abi.encode(ACCOUNT_TYPEHASH, keccak256(message)));
        return abi.encodePacked("\x19\x01", _domainSeparator(account), messageHash);
    }

    function getMessageHash(address account, bytes memory message) public view returns (bytes32) {
        return keccak256(encodeMessageData(account, message));
    }

    function _domainSeparator(address account) internal view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION, block.chainid, account, _SALT));
    }

    // Review
    function test(uint256 a) public pure {
        a;
    }
}
