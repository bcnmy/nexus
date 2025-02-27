// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import { MODE_MODULE_ENABLE } from "../types/Constants.sol";

/**
    Nonce structure
    [3 bytes empty][1 bytes validation mode][20 bytes validator][8 bytes nonce]
*/

library NonceLib {
    /// @dev Parses validator address out of nonce
    /// @param nonce The nonce
    /// @return validator
    function getValidator(uint256 nonce) internal pure returns (address validator) {
        assembly {
            validator := shr(96, shl(32, nonce))
        }
    }

    /// @dev Detects if Validaton Mode is Module Enable Mode
    /// @param nonce The nonce
    /// @return res boolean result, true if it is the Module Enable Mode
    function isModuleEnableMode(uint256 nonce) internal pure returns (bool res) {
        assembly {
            let vmode := byte(3, nonce)
            res := eq(shl(248, vmode), MODE_MODULE_ENABLE)
        }
    }

    /// @dev Detects if Validaton Mode is Default Validator Mode
    /// @param nonce The nonce
    /// @return res boolean result, true if it is the Default Validator Mode
    function isDefaultValidatorMode(uint256 nonce) internal pure returns (bool res) {
        assembly {
            let vmode := byte(3, nonce)
            res := eq(shl(248, vmode), MODE_DEFAULT_VALIDATOR)
        }
    }
}
