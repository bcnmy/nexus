// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IModule } from "../interfaces/modules/IModule.sol";
import { VALIDATION_SUCCESS, VALIDATION_FAILED, MODULE_TYPE_VALIDATOR } from "../types/Constants.sol";
import { PackedUserOperation } from "account-abstraction/interfaces/PackedUserOperation.sol";
import { IValidator } from "../interfaces/modules/IValidator.sol";

/// @title MockRevertingValidator
/// @notice A mock validator whose isInitialized() always reverts.
/// Used to test that a reverting validator cannot block uninstallation of other validators.
contract MockRevertingValidator is IValidator {
    function validateUserOp(PackedUserOperation calldata, bytes32) external pure returns (uint256) {
        return VALIDATION_SUCCESS;
    }

    function isValidSignatureWithSender(address, bytes32, bytes calldata) external pure returns (bytes4) {
        return bytes4(0xffffffff);
    }

    function onInstall(bytes calldata) external { }

    function onUninstall(bytes calldata) external { }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    /// @notice Always reverts to simulate a broken or malicious validator.
    function isInitialized(address) external pure returns (bool) {
        revert("MockRevertingValidator: isInitialized reverts");
    }
}
