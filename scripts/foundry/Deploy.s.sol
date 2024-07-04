// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
pragma solidity >=0.8.0 <0.9.0;

import { Nexus } from "../../contracts/Nexus.sol";

import { BaseScript } from "./Base.s.sol";

/// @dev See the Solidity Scripting tutorial: https://book.getfoundry.sh/tutorials/solidity-scripting
contract Deploy is BaseScript {
    address private constant _ENTRYPOINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    function run() public broadcast returns (Nexus smartAccount) {
        smartAccount = new Nexus(_ENTRYPOINT);
    }

    function test() public {
        // This is a test function to exclude this script from the coverage report.
    }
}
