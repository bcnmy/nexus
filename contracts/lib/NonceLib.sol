// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { MODE_MODULE_ENABLE } from "contracts/types/Constants.sol";

library NonceLib {
    function getValidator(uint256 nonce) internal pure returns (address validator) {
        assembly {
            validator := shr(96, shl(32, nonce))
        }
    }

    function isModuleEnableMode(uint256 nonce) internal pure returns (bool res) {
        bytes32 v;
        assembly {
            let vmode := shr(248, shl(24, nonce))
            res := eq(shl(248, vmode), MODE_MODULE_ENABLE)
            v := vmode
        }
    }
}
