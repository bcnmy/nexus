// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";

contract TestERC1271Account_IsValidSignature is Test, SmartAccountTestLab {

    function setUp() public {
        init();
    }

    function test_isValidSignature_MockValidator_Success() public {
        string memory message = "Some Message";
        bytes32 hash = keccak256(abi.encodePacked(message));
        bytes32 toSign = ALICE_ACCOUNT.replaySafeHash(hash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ALICE.privateKey, toSign);
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes4 ret = ALICE_ACCOUNT.isValidSignature(hash, abi.encodePacked(address(VALIDATOR_MODULE), signature));
        assertEq(ret, bytes4(0x1626ba7e));
    }

    function test_isValidSignature_MockValidator_Wrong1271Signer_Fail() public {
        string memory message = "Some Message";
        bytes32 hash = keccak256(abi.encodePacked(message));
        bytes32 toSign = ALICE_ACCOUNT.replaySafeHash(hash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, toSign);
        bytes memory signature = abi.encodePacked(r, s, v);
        bytes4 ret = ALICE_ACCOUNT.isValidSignature(hash, abi.encodePacked(address(VALIDATOR_MODULE), signature));
        assertEq(ret, bytes4(0xFFFFFFFF));
    }

    // @ TODO
    // other test scenarios
}