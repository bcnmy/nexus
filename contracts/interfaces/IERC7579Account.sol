// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IAccountConfig } from "./base/IAccountConfig.sol";
import { IExecutionManager } from "./base/IExecutionManager.sol";
import { IModuleManager } from "./base/IModuleManager.sol";

// MinimalMSA
interface IERC7579Account is IAccountConfig, IExecutionManager, IModuleManager {
    /**
     * @dev ERC-1271 isValidSignature
     *         This function is intended to be used to validate a smart account signature
     * and may forward the call to a validator module
     *
     * @param hash The hash of the data that is signed
     * @param data The data that is signed
     */
    function isValidSignature(bytes32 hash, bytes calldata data) external view returns (bytes4);
}
