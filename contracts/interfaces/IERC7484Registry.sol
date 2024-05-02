// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title IERC7484Registry Interface
/// @dev Interface for a registry that provides module security checks.
interface IERC7484Registry {
    /// @notice Allows setting trust levels for attesters
    /// @param threshold The minimum number of valid attestations required
    /// @param attesters An array of attester addresses to trust
    function trustAttesters(uint8 threshold, address[] calldata attesters) external;

    /// @notice Checks a module's security attestation
    /// @param module The address of the module to check
    function check(address module) external view;

    /// @notice Checks a module's security attestation for a specific smart account
    /// @param smartAccount The address of the smart account
    /// @param module The address of the module to check
    function checkForAccount(address smartAccount, address module) external view;

    /// @notice Checks a module's security attestation with a specific module type
    /// @param module The address of the module to check
    /// @param moduleType The type ID of the module
    function check(address module, uint256 moduleType) external view;

    /// @notice Checks a module's security attestation for a specific smart account and module type
    /// @param smartAccount The address of the smart account
    /// @param module The address of the module to check
    /// @param moduleType The type ID of the module
    function checkForAccount(address smartAccount, address module, uint256 moduleType) external view;

    /// @notice Checks a module's attestation by a specific attester
    /// @param module The address of the module to check
    /// @param attester The address of the attester verifying the module
    function check(address module, address attester) external view;

    /// @notice Checks a module's attestation by a specific attester for a specific module type
    /// @param module The address of the module to check
    /// @param moduleType The type ID of the module
    /// @param attester The address of the attester verifying the module
    function check(address module, uint256 moduleType, address attester) external view;

    /// @notice Checks a module's attestation by multiple attesters with a threshold
    /// @param module The address of the module to check
    /// @param attesters An array of attester addresses
    /// @param threshold The minimum number of valid attestations required
    function checkN(address module, address[] calldata attesters, uint256 threshold) external view;

    /// @notice Checks a module's attestation by multiple attesters with a threshold for a specific module type
    /// @param module The address of the module to check
    /// @param moduleType The type ID of the module
    /// @param attesters An array of attester addresses
    /// @param threshold The minimum number of valid attestations required
    function checkN(address module, uint256 moduleType, address[] calldata attesters, uint256 threshold) external view;
}
