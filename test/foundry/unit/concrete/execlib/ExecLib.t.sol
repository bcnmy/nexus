// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import "forge-std/src/Test.sol";
import "../../../../../contracts/lib/ExecLib.sol";

contract ExecLibTest is Test {
    function setUp() public { }

    function test_encode_decode(address target, uint256 value, bytes memory callData) public {
        bytes memory encoded = ExecLib.encodeSingle(target, value, callData);
        (address target_, uint256 value_, bytes memory callData_) = this.decode(encoded);

        assertTrue(target_ == target);
        assertTrue(value_ == value);
        assertTrue(keccak256(callData_) == keccak256(callData));
    }

    function decode(bytes calldata encoded)
        public
        pure
        returns (address target, uint256 value, bytes calldata callData)
    {
        (target, value, callData) = ExecLib.decodeSingle(encoded);
    }
}
