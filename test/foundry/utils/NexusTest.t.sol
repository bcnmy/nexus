// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./Imports.sol";
import "./TestHelper.t.sol";
import "./EventsAndErrors.sol";

/// @title NexusTest - Contract for testing Nexus smart account functionalities
/// @notice This contract inherits from TestHelper to provide testing utilities
contract NexusTest is TestHelper {
    Nexus public smartAccount;
    Nexus public implementation;

    /// @notice Initializes the testing environment
    function setUp() internal {
        setupTestEnvironment();
    }

    receive() external payable {}
}
