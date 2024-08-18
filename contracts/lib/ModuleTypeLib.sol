// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

type EncodedModuleTypes is uint256;

type ModuleType is uint256;

/// @title ModuleTypeLib
/// @notice A library for handling module types and encoding them as bits
library ModuleTypeLib {
    /// @notice Checks if the given EncodedModuleTypes contains a specific module type
    /// @param self The encoded module types
    /// @param moduleTypeId The module type to check for
    /// @return True if the module type is present, false otherwise
    function isType(EncodedModuleTypes self, ModuleType moduleTypeId) internal pure returns (bool) {
          // Check if the specific bit for the moduleTypeId is set in the encoded value using bitwise shift
          return (EncodedModuleTypes.unwrap(self) & (uint256(1) << ModuleType.unwrap(moduleTypeId))) != 0;
    }


    /// @notice Encodes an array of ModuleType into a single EncodedModuleTypes bitmask
    /// @param moduleTypes An array of ModuleType to encode
    /// @return The encoded module types
    // example for bitEncode, similar adjustments should be done for isType, bitEncodeCalldata
    function bitEncode(ModuleType[] memory moduleTypes) internal pure returns (EncodedModuleTypes) {
        uint256 result;

        // Iterate through the moduleTypes array and set the corresponding bits in the result
        for (uint256 i; i < moduleTypes.length; i++) {
           result |= uint256(1) << ModuleType.unwrap(moduleTypes[i]);
        }

        return EncodedModuleTypes.wrap(result);
    }

    /// @notice Encodes a calldata array of ModuleType into a single EncodedModuleTypes bitmask
    /// @param moduleTypes A calldata array of ModuleType to encode
    /// @return The encoded module types
    function bitEncodeCalldata(ModuleType[] calldata moduleTypes) internal pure returns (EncodedModuleTypes) {
        uint256 result;

        // Iterate through the moduleTypes array and set the corresponding bits in the result
        for (uint256 i; i < moduleTypes.length; i++) {
            result |= uint256(1) << ModuleType.unwrap(moduleTypes[i]);
        }

        return EncodedModuleTypes.wrap(result);
    }
}
