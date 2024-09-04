// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { Test, Vm, stdMath } from "forge-std/src/Test.sol";

/// @title CheatCodes - A utility contract for testing with cheat codes
/// @notice Provides various helper functions for testing
contract CheatCodes is Test {
    /// @notice Creates a new wallet from a given name
    /// @param name The name to generate a wallet from
    /// @return wallet A struct containing the new wallet's address and private key
    function newWallet(string memory name) internal returns (Vm.Wallet memory) {
        Vm.Wallet memory wallet = vm.createWallet(name);
        vm.label(wallet.addr, name);
        return wallet;
    }

    /// @notice Signs a message with the given address
    /// @param signer The address to sign the message with
    /// @param hash The hash of the message to sign
    /// @return v The recovery id (v)
    /// @return r Output of ECDSA signature (r)
    /// @return s Output of ECDSA signature (s)
    function signMessage(address signer, bytes32 hash) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        uint256 privateKey = uint256(keccak256(abi.encodePacked(signer)));
        (v, r, s) = vm.sign(privateKey, hash);
    }

    /// @notice Mocks the next call to be made from a specific address
    /// @param addr The address to make the next call from
    function prank(address addr) internal {
        vm.prank(addr);
    }

    /// @notice Starts mocking calls to be made from a specific address
    /// @param addr The address to make the calls from
    function startPrank(address addr) internal {
        vm.startPrank(addr);
    }

    /// @notice Stops mocking calls to be made from a specific address
    function stopPrank() internal {
        vm.stopPrank();
    }

    /// @notice Creates a snapshot of the current state
    /// @return The ID of the created snapshot
    function createSnapshot() internal returns (uint256) {
        return vm.snapshot();
    }

    /// @notice Reverts the state to a specific snapshot
    /// @param snapshotId The ID of the snapshot to revert to
    function revertToSnapshot(uint256 snapshotId) internal {
        vm.revertTo(snapshotId);
    }

    /// @notice Skips the test if a specific condition is met
    /// @param condition The condition to check
    function skipTest(bool condition) internal {
        if (condition) {
            vm.skip(true);
        }
    }

    /// @notice Asserts that two uint256 values are approximately equal
    /// @param a The first value to compare
    /// @param b The second value to compare
    /// @param maxPercentDelta The maximum allowed percentage difference
    function almostEq(uint256 a, uint256 b, uint256 maxPercentDelta) internal {
        if (b == 0) return assertEq(a, b); // If the left is 0, right must be too.

        uint256 percentDelta = stdMath.percentDelta(a, b);

        if (percentDelta > maxPercentDelta) {
            emit log("Error: a ~= b not satisfied [uint]");
            emit log_named_uint("        Left", a);
            emit log_named_uint("       Right", b);
            emit log_named_decimal_uint(" Max % Delta", maxPercentDelta * 100, 18);
            emit log_named_decimal_uint("     % Delta", percentDelta * 100, 18);
            fail();
        }
    }
}
