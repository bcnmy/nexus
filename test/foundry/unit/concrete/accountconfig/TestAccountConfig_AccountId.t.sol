// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { NexusTest_Base } from "../../../utils/NexusTest_Base.t.sol";

/// @title Test suite for checking account ID in AccountConfig
contract TestAccountConfig_AccountId is NexusTest_Base {
    /// @notice Initialize the testing environment
    /// @notice Initialize the testing environment
    function setUp() public {
        setupPredefinedWallets();
        deployTestContracts();
    }

    /// @notice Tests if the account ID returns the expected value
    function test_WhenCheckingTheAccountID() external {
        string memory expected = "biconomy.nexus.1.2.0";
        assertEq(ACCOUNT_IMPLEMENTATION.accountId(), expected, "AccountConfig should return the expected account ID.");
    }
}
