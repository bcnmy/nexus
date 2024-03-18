// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24 <0.9.0;

import "./Helpers.sol";

contract SmartAccountTestLab is Helpers {
    SmartAccount public implementation;
    SmartAccount public smartAccount;

    function init() public {
        initializeTestingEnvironment();
    }

    function testIgnore_() public pure {
        // This is a dummy test to avoid "No tests found" error
    }
}
