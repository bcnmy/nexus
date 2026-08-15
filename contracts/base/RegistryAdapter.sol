// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { IERC7484 } from "../interfaces/IERC7484.sol";
import { Storage } from "./Storage.sol";

/// @title RegistryAdapter
/// @notice This contract provides an interface for interacting with an ERC-7484 compliant registry.
/// @dev The registry feature is opt-in, allowing the smart account owner to select and trust specific attesters.
abstract contract RegistryAdapter is Storage {
    /// @notice Emitted when a new ERC-7484 registry is configured for the account.
    /// @param registry The configured registry contract.
    event ERC7484RegistryConfigured(IERC7484 indexed registry);

    /// @notice Modifier to check if a module meets the required attestations in the registry.
    /// @param module The module to check.
    /// @param moduleType The type of the module to verify in the registry.
    modifier withRegistry(address module, uint256 moduleType) {
        _checkRegistry(module, moduleType);
        _;
    }

    /// @notice Returns the configured ERC-7484 registry.
    /// @return The configured registry contract.
    function getRegistry() external view returns (IERC7484) {
        return IERC7484(_getAccountStorage().registry);
    }

    /// @notice Configures the ERC-7484 registry and sets trusted attesters.
    /// @param newRegistry The new registry contract to use.
    /// @param attesters The list of attesters to trust.
    /// @param threshold The number of attestations required.
    function _configureRegistry(IERC7484 newRegistry, address[] memory attesters, uint8 threshold) internal {
        _getAccountStorage().registry = address(newRegistry);
        if (address(newRegistry) != address(0)) {
            newRegistry.trustAttesters(threshold, attesters);
        }
        emit ERC7484RegistryConfigured(newRegistry);
    }

    /// @notice Checks the registry to ensure sufficient valid attestations for a module.
    /// @param module The module to check.
    /// @param moduleType The type of the module to verify in the registry.
    /// @dev Reverts if the required attestations are not met.
    function _checkRegistry(address module, uint256 moduleType) internal view {
        IERC7484 moduleRegistry = IERC7484(_getAccountStorage().registry);
        if (address(moduleRegistry) != address(0)) {
            // This will revert if attestations or the threshold are not met.
            moduleRegistry.check(module, moduleType);
        }
    }
}
