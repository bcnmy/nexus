// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";

/// @title Test suite for testing onlyEntryPoint modifier in Nexus contracts under ERC4337 standards.
contract TestERC4337Account_OnlyEntryPoint is Test, NexusTest_Base {
    Nexus public account;
    MockValidator public validator;
    address public userAddress;

    /// Setup environment for each test case
    function setUp() public {
        init();
        BOB_ACCOUNT.addDeposit{ value: 1 ether }(); // Fund the account to cover potential transaction fees
    }

    /// Verifies that a valid operation passes validation when invoked from the EntryPoint.
    function test_ValidUserOpValidation_FromEntryPoint() public {
        // Arrange a valid user operation
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(BOB.addr, getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(BOB, userOpHash); // Sign operation with valid signer

        // Act: Validate the operation from the entry point, expecting it to succeed
        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        stopPrank();

        // Assert that the operation is validated successfully
        assertTrue(res == 0, "Valid operation should pass validation");
    }

    /// Ensures that operations fail validation when invoked from an unauthorized sender.
    function test_UserOpValidation_FailsFromNonEntryPoint() public {
        // Setup a valid user operation, but simulate calling from a non-entry point address
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(BOB, userOpHash); // Still correctly signed

        // Act: Attempt to validate the operation from a non-entry point address
        startPrank(address(BOB_ACCOUNT));
        vm.expectRevert(abi.encodeWithSelector(AccountAccessUnauthorized.selector));
        BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        stopPrank();
    }

    /// Tests that the operation fails validation when the signature is invalid.
    function test_UserOpValidation_FailsWithInvalidSignature() public {
        // Arrange a user operation with incorrect signature
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(ALICE, userOpHash); // Incorrect signer

        // Act: Validate the operation from the entry point
        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        stopPrank();

        // Assert that the operation fails validation due to invalid signature
        assertTrue(res == 1, "Operation with invalid signature should fail validation");
    }
}
