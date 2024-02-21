// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;

import { SmartAccount } from "../../contracts/SmartAccount.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    function run() public broadcast returns (SmartAccount smartAccount) {
        smartAccount = new SmartAccount();
    }

    function test() public pure returns (uint256) {
        return 0;
    }
}
