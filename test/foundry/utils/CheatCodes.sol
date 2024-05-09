// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Imports.sol";
import "forge-std/Test.sol";

contract CheatCodes is Test {
    // Assign a readable name to an address to improve test output readability
    function labelAddress(address addr, string memory name) internal {
        vm.label(addr, name);
    }

    // Create a new wallet from a given name, generating a private key, and label the address
    function newWallet(string memory name) internal returns (Vm.Wallet memory) {
        Vm.Wallet memory wallet = vm.createWallet(name);
        vm.label(wallet.addr, name);
        return wallet;
    }

    function warpTo(uint256 timestamp) internal {
        vm.warp(timestamp);
    }

    function setBalance(address addr, uint256 balance) internal {
        vm.deal(addr, balance);
    }

    function signMessage(address signer, bytes32 hash) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        uint256 privateKey = uint256(keccak256(abi.encodePacked(signer)));
        (v, r, s) = vm.sign(privateKey, hash);
    }

    function assume(bool condition) internal pure {
        vm.assume(condition);
    }

    function prank(address addr) internal {
        vm.prank(addr);
    }

    function startPrank(address addr) internal {
        vm.startPrank(addr);
    }

    function stopPrank() internal {
        vm.stopPrank();
    }

    function createSnapshot() internal returns (uint256) {
        return vm.snapshot();
    }

    function revertToSnapshot(uint256 snapshotId) internal {
        vm.revertTo(snapshotId);
    }

    function skipTest(bool condition) internal {
        if (condition) {
            vm.skip(true);
        }
    }

    // Set the block base fee
    function setBaseFee(uint256 baseFee) internal {
        vm.fee(baseFee);
    }

    // Load storage slot directly from a contract
    function loadStorageAtSlot(address contractAddress, bytes32 slot) internal view returns (bytes32) {
        return vm.load(contractAddress, slot);
    }

    // Set contract code for an address
    function setContractCode(address contractAddress, bytes memory code) internal {
        vm.etch(contractAddress, code);
    }

    function test(uint256 a) public pure {
        a;
    }

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
