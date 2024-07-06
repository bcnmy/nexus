// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../../utils/Imports.sol";
import { MODE_VALIDATION } from "contracts/types/Constants.sol";
import "../../../utils/NexusTest_Base.t.sol";

/// @title TestERC4337Account_OnlyEntryPoint
/// @notice Tests the onlyEntryPoint modifier in Nexus contracts under ERC4337 standards.
contract TestERC4337Account_OnlyEntryPoint is NexusTest_Base {
    Nexus public account;
    MockValidator public validator;
    address public userAddress;

    /// @notice Sets up the environment for each test case.
    function setUp() public {
        init();
        BOB_ACCOUNT.addDeposit{ value: 1 ether }(); // Fund the account to cover potential transaction fees
    }

    /// @notice Verifies that a valid operation passes validation when invoked from the EntryPoint.
    function test_ValidUserOpFromEntryPoint() public {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(BOB, userOpHash); // Sign operation with valid signer

        startPrank(address(ENTRYPOINT));
        // Attempt to validate the user operation, expecting success
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 10);
        assertTrue(res == 0, "Valid operation should pass validation");
        stopPrank();
    }

    function test_ValidateUserOp_InvalidSignature() public {
        startPrank(address(ENTRYPOINT));
        // Initialize a user operation with a valid nonce but signed by an incorrect signer
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(ALICE, userOpHash); // Incorrect signer simulated

        startPrank(address(ENTRYPOINT));
        // Attempt to validate the user operation, expecting failure due to invalid signature
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        stopPrank();

        assertTrue(res == 1, "Invalid operation should not pass validation");
    }

    /// @notice Ensures that operations fail validation when invoked from an unauthorized sender.
    function test_RevertIf_UserOpFromNonEntryPoint() public {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(BOB, userOpHash); // Still correctly signed

        startPrank(address(BOB_ACCOUNT));
        vm.expectRevert(abi.encodeWithSelector(AccountAccessUnauthorized.selector));
        BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        stopPrank();
    }

    /// @notice Tests that the operation fails validation when the signature is invalid.
    function test_RevertIf_InvalidUserOpSignature() public {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(ALICE, userOpHash); // Incorrect signer

        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        stopPrank();

        assertTrue(res == 1, "Operation with invalid signature should fail validation");
    }
}
