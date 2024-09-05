// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../utils/Imports.sol";

/// @title Test suite for checking account ID in AccountConfig
contract TestAccountConfig_AccountId is Test {
    Nexus internal accountConfig;
    address _ENTRYPOINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    modifier givenTheAccountConfiguration() {
        _;
    }

    /// @notice Initialize the testing environment
    function setUp() public {
        accountConfig = new Nexus(_ENTRYPOINT);
    }

    /// @notice Tests if the account ID returns the expected value
    function test_WhenCheckingTheAccountID() external givenTheAccountConfiguration {
        string memory expected = "biconomy.nexus.1.0.0-beta";
        assertEq(accountConfig.accountId(), expected, "AccountConfig should return the expected account ID.");
    }
}
