// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.24;

contract Counter {
    uint256 private _number;

    function incrementNumber() public {
        _number++;
    }

    function decrementNumber() public {
        _number--;
    }

    /**
     * @dev Return value
     * @return value of 'number'
     */
    function getNumber() public view returns (uint256) {
        return _number;
    }
}
