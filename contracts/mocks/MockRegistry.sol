// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC7484Registry } from "../../../contracts/interfaces/IERC7484Registry.sol";
contract MockRegistry {
    struct Attestation {
        uint256 moduleType;               // The type of the module attested.
        mapping(address => bool) attestors; // Tracks whether an address has attested
        uint256 validCount;               // Count of valid attestations for this module.
    }

    mapping(address => Attestation) public moduleAttestations; // Maps modules to their attestation records.
    mapping(uint256 => uint256) public typeThresholds; // Required thresholds for each module type.

    /// @notice Adds or updates an attestation for a specific module.
    /// @param module The address of the module.
    /// @param moduleType The type identifier of the module.
    /// @param attestor The address of the attestor.
    /// @param attested Boolean indicating the attestation status.
    function addAttestation(address module, uint256 moduleType, address attestor, bool attested) external {
        Attestation storage att = moduleAttestations[module];
        if (attested && !att.attestors[attestor]) {
            att.validCount++;
            att.attestors[attestor] = true;
        } else if (!attested && att.attestors[attestor]) {
            att.validCount--;
            att.attestors[attestor] = false;
        }
        att.moduleType = moduleType;
    }

    /// @notice Sets the attestation threshold required for a module type.
    /// @param moduleType The module type identifier.
    /// @param threshold The number of valid attestations required for approval.
    function setThreshold(uint256 moduleType, uint256 threshold) external {
        typeThresholds[moduleType] = threshold;
    }

    /// @notice Checks if a module meets the attestation requirements for a specified module type.
    /// @param module The address of the module to check.
    /// @param moduleType The module type that needs validation.
    /// @dev Reverts if the attestation conditions are not met.
    function check(address module, uint256 moduleType) external view {
        Attestation storage att = moduleAttestations[module];
        require(att.validCount >= typeThresholds[moduleType], "Not enough valid attestations.");
        require(att.moduleType == moduleType, "Module type mismatch.");
    }
}