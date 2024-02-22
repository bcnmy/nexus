// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IValidator, IModule, VALIDATION_SUCCESS } from "../../interfaces/IERC7579Modules.sol";
import { EncodedModuleTypes } from "../../lib/ModuleTypeLib.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract MockValidator is IValidator {
    /// @inheritdoc IValidator
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external returns (uint256) {
        userOp;
        userOpHash;
        return VALIDATION_SUCCESS;
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
        data;
    }

    /// @inheritdoc IModule
    function onUninstall(bytes calldata data) external {
        data;
    }

    /// @inheritdoc IModule
    function isModuleType(uint256 typeID) external view returns (bool) {
        typeID;
        return true;
    }

    /// @inheritdoc IModule
    function getModuleTypes() external view returns (EncodedModuleTypes) {
        // solhint-disable-previous-line no-empty-blocks
    }
}
