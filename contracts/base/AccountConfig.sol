// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IAccountConfig } from "../interfaces/base/IAccountConfig.sol";

contract AccountConfig is IAccountConfig {
    string internal constant _ACCOUNT_IMPLEMENTATION_ID = "biconomy.modular-smart-account.1.0.0-alpha";

    /// @inheritdoc IAccountConfig
    function supportsExecutionMode(bytes32 encodedMode) external view returns (bool) {
        encodedMode;
        return true;
    }

    /// @inheritdoc IAccountConfig
    function supportsModule(uint256 moduleTypeId) external view returns (bool) {
        moduleTypeId;
        return true;
    }

    /// @inheritdoc IAccountConfig
    function accountId() external pure returns (string memory) {
        return _ACCOUNT_IMPLEMENTATION_ID;
    }
}
