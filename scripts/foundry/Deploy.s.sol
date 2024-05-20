// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { Nexus } from "../../contracts/Nexus.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    function run() public broadcast returns (Nexus smartAccount) {
        smartAccount = new Nexus();
    }

    function test() public pure returns (uint256) {
        return 0;
    }
}
