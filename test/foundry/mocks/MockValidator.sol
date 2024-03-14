// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IModule } from "contracts/interfaces/modules/IModule.sol";
import { IValidator, VALIDATION_SUCCESS, VALIDATION_FAILED } from "contracts/interfaces/modules/IERC7579Modules.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract MockValidator is IValidator {
    mapping(address => address) public smartAccountOwners;

    /// @inheritdoc IValidator
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash
    )
        external
        returns (uint256 validation)
    {
        return ECDSA.recover(MessageHashUtils.toEthSignedMessageHash(userOpHash), userOp.signature)
            == smartAccountOwners[msg.sender] ? VALIDATION_SUCCESS : VALIDATION_FAILED;
    }

    /// @inheritdoc IValidator
    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        returns (bytes4)
    {
        sender;
        hash;
        data;
        return 0xffffffff;
    }

    /// @inheritdoc IModule
    function onInstall(bytes calldata data) external {
        smartAccountOwners[msg.sender] = address(bytes20(data));
    }

    /// @inheritdoc IModule
    function onUninstall(bytes calldata data) external {
        delete smartAccountOwners[msg.sender];
    }

    /// @inheritdoc IModule
    function isModuleType(uint256 moduleTypeId) external view returns (bool) {
        moduleTypeId;
        return true;
    }

    function isOwner(address account, address owner) external view returns (bool) {
        return smartAccountOwners[account] == owner;
    }

    /// @inheritdoc IModule
    function getModuleTypes() external view returns (EncodedModuleTypes) {
        // solhint-disable-previous-line no-empty-blocks
    }

    function test_() public pure {
        // This function is used to ignore file in coverage report
    }
}
