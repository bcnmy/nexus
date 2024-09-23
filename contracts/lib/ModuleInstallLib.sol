// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "../types/Constants.sol";

library ModuleInstallLib {
    
    /// @dev Detects if module is being used as validator based on data provided
    function asValidator(bytes calldata data) internal pure returns (bool) {
        return uint256(uint8(bytes1(data[0:1]))) == MODULE_TYPE_VALIDATOR;
    }

    function encodeAsValidatorData(bytes memory data) internal pure returns (bytes memory) {
        return abi.encodePacked(uint8(MODULE_TYPE_VALIDATOR), data);
    }
}

