// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { NexusProxy } from "../utils/NexusProxy.sol";
import { INexus } from "../interfaces/INexus.sol";

/// @title ProxyLib
/// @notice A library for deploying NexusProxy contracts
library ProxyLib {
    /// @notice Error thrown when ETH transfer fails.
    error EthTransferFailed();

    /// @notice Deploys a new NexusProxy contract, returning the address of the new contract, if the contract is already deployed,
    ///         the msg.value will be forwarded to the existing contract.
    /// @param implementation The address of the implementation contract.
    /// @param salt The salt used for the contract creation.
    /// @param initData The initialization data for the implementation contract.
    /// @return alreadyDeployed A boolean indicating if the contract was already deployed.
    /// @return account The address of the new contract or the existing contract.
    function deployProxy(address implementation, bytes32 salt, bytes memory initData) internal returns (bool alreadyDeployed, address payable account) {
        // Check if the contract is already deployed
        account = predictProxyAddress(implementation, salt, initData);
        alreadyDeployed = account.code.length > 0;
        // Deploy a new contract if it is not already deployed
        if (!alreadyDeployed) {
            // Deploy the contract
            new NexusProxy{ salt: salt, value: msg.value }(implementation, abi.encodeCall(INexus.initializeAccount, initData));
        } else {
            // Forward the value to the existing contract
            (bool success,) = account.call{ value: msg.value }("");
            require(success, EthTransferFailed());
        }
    }

    /// @notice Predicts the address of a NexusProxy contract.
    /// @param implementation The address of the implementation contract.
    /// @param salt The salt used for the contract creation.
    /// @param initData The initialization data for the implementation contract.
    /// @return predictedAddress The predicted address of the new contract.
    function predictProxyAddress(address implementation, bytes32 salt, bytes memory initData) internal view returns (address payable predictedAddress) {
        // Get the init code hash
        bytes32 initCodeHash =
            keccak256(abi.encodePacked(type(NexusProxy).creationCode, abi.encode(implementation, abi.encodeCall(INexus.initializeAccount, initData))));

        // Compute the predicted address
        predictedAddress = payable(address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, initCodeHash))))));
    }
}
