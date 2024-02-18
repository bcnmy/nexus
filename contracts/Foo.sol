// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24;

/**
 * @title Foo
 * @dev A simple contract demonstrating a pure function in Solidity.
 */
contract Foo {
    /**
     * @notice Returns the input value unchanged.
     * @dev A pure function that does not alter or interact with contract state.
     * @param value The uint256 value to be returned.
     * @return uint256 The same value that was input.
     */
    function id(uint256 value) external pure returns (uint256) {
        return value;
    }
}
