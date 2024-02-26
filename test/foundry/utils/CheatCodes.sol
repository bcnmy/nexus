// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Imports.sol";
import "forge-std/src/Test.sol";

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

    function signMessage(address signer, bytes32 hash) internal returns (uint8 v, bytes32 r, bytes32 s) {
        uint256 privateKey = uint256(keccak256(abi.encodePacked(signer)));
        (v, r, s) = vm.sign(privateKey, hash);
    }

    function assume(bool condition) internal {
        vm.assume(condition);
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
    function loadStorageAtSlot(address contractAddress, bytes32 slot) internal returns (bytes32) {
        return vm.load(contractAddress, slot);
    }

    // Set contract code for an address
    function setContractCode(address contractAddress, bytes memory code) internal {
        vm.etch(contractAddress, code);
    }

    function test(uint256 a) public {
        a;
    }
}
