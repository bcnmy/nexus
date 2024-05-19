// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";

/// @title Test suite for checking account ID in AccountConfig
contract TestAccountConfig_AccountId is Test {
    Nexus public accountConfig;

    /// @notice Initialize the testing environment
    function setUp() public {
        accountConfig = new Nexus();
    }

    /// @notice Tests if the account ID returns the expected value
    function test_AccountId_ReturnsExpectedValue() public {
        string memory expected = "biconomy.nexus.0.0.1";
        assertEq(accountConfig.accountId(), expected, "AccountConfig should return the expected account ID.");
    }
}
