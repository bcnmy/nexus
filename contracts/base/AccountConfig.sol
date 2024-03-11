// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IAccountConfig } from "../interfaces/base/IAccountConfig.sol";
import { ModeCode } from "../lib/ModeLib.sol";

// Review: may not need interface at all if child account uses full holistic interface
abstract contract AccountConfig is IAccountConfig {
    string internal constant _ACCOUNT_IMPLEMENTATION_ID = "biconomy.modular-smart-account.1.0.0-alpha";

    /// @inheritdoc IAccountConfig
    function supportsExecutionMode(ModeCode encodedMode) external view virtual returns (bool);

    /// @inheritdoc IAccountConfig
    function supportsModule(uint256 moduleTypeId) external view virtual returns (bool);

    /// @inheritdoc IAccountConfig
    function accountId() external pure virtual returns (string memory) {
        return _ACCOUNT_IMPLEMENTATION_ID;
    }
}
