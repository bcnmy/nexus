// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

contract Counter {
    uint256 private _number;

    function incrementNumber() public {
        _number++;
    }

    function decrementNumber() public {
        _number--;
    }

    function getNumber() public view returns (uint256) {
        return _number;
    }

    function revertOperation() public pure {
        revert("Counter: Revert operation");
    }

    function test_() public pure {
        // This function is used to ignore file in coverage report
    }
}
