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
import {EIP712} from "solady/src/utils/EIP712.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MockValidator is EIP712, IValidator {
    // keccak256(EIP712Domain(string name,string version,uint256 chainId,address verifyingContract))
    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    string constant NAME = "Mock ECDSA Validator";
    string constant VERSION = "0.0.1";

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
        bytes32 domainSeparator = _domainSeparator();
        bytes32 signedMessageHash = keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, hash)
        );
        bytes32 ethHash = ECDSA.toEthSignedMessageHash(signedMessageHash);
        address owner = ECDSA.recover(ethHash, signature);
        if(ownerOfSender == owner) {
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

    function _domainSeparator() internal view override returns (bytes32) {
        (string memory _name, string memory _version) = _domainNameAndVersion();
        bytes32 nameHash = keccak256(bytes(_name));
        bytes32 versionHash = keccak256(bytes(_version));
        // Should Use the proxy address for the EIP-712 domain separator?
        // Review: this uses the validator address as the verifying contract
        address verifyingContract = address(this);

        // Construct the domain separator with name, version, chainId, and proxy address.
        bytes32 typeHash = EIP712_DOMAIN_TYPEHASH;
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, verifyingContract));
    }

    function _domainNameAndVersion() internal pure override returns (string memory, string memory) {
        return (NAME, VERSION);
    }

    // Review
    function test(uint256 a) public pure {
        a;
    }
}
