// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./Imports.sol";
import "./TestHelper.t.sol";
import "./EventsAndErrors.sol";

/// @title NexusTest_Base - Base contract for testing Nexus smart account functionalities
/// @notice This contract inherits from TestHelper to provide common setup and utilities for Nexus tests
abstract contract NexusTest_Base is TestHelper {
    /// @notice Initializes the testing environment
    function init() internal virtual {
        setupTestEnvironment();
    }

    receive() external payable {}
}
