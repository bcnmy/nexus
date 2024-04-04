// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "./MockHandler.sol";

contract TriggerFallback {
    function triggerGenericFallback(MockHandler fallbackHandler, address sender, uint256 value, bytes memory data) public returns (bytes4) {
        return fallbackHandler.onGenericFallback(sender, value, data);
    }

    function test() public pure {
        // This function is used to ignore file in coverage report
    }
}