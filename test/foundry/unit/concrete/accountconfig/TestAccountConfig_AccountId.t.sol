// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";

contract TestAccountConfig_AccountId is Test {
    Nexus public accountConfig;

    function setUp() public {
        accountConfig = new Nexus();
    }

    function test_AccountId_ReturnsExpectedValue() public {
        string memory expected = "biconomy.nexus.1.0.0";
        assertEq(accountConfig.accountId(), expected, "AccountConfig should return the expected account ID.");
    }
}
