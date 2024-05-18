// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24 <0.9.0;

import "./Helpers.sol";
import "./Imports.sol";
import "./EventsAndErrors.sol";

contract SmartAccountTestLab is Helpers {
    Nexus public smartAccount;
    Nexus public implementation;

    function init() internal {
        setupTestEnvironment();
    }

    receive() external payable {}
}
