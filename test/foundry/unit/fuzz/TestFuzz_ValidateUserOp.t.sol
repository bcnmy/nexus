// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/NexusTest_Base.t.sol";

/// @title TestFuzz_ValidateUserOp - Fuzz testing for the validateUserOp function of the Nexus smart account
/// @notice This contract inherits from NexusTest_Base to provide common setup and utilities for fuzz testing
contract TestFuzz_ValidateUserOp is NexusTest_Base {

    /// @notice Initializes the testing environment and sets the user address
    function setUp() public {
        init(); // Initializes all required contracts and wallets
    }

    /// @notice Fuzz test for validateUserOp with a valid signature and sufficient funds
    /// @param randomNonce The random nonce for the user operation
    function testFuzz_ValidateUserOp_Valid(uint256 randomNonce) public {
        vm.assume(randomNonce < type(uint192).max);

        // Prefund the smart account with sufficient funds
        prefundSmartAccountAndAssertSuccess(address(BOB_ACCOUNT), 1 ether);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithCalldata(BOB, "", address(VALIDATOR_MODULE));

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(BOB, userOpHash); // Using a valid signature

        // Attempt to validate the user operation
        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        assertTrue(res == 0, "Operation should pass validation with valid signature and sufficient funds");
        stopPrank();
    }

    /// @notice Fuzz test for validateUserOp with an invalid signature
    /// @param randomNonce The random nonce for the user operation
    /// @param missingAccountFunds The random missing funds for the account
    function testFuzz_ValidateUserOp_InvalidSignature(uint256 randomNonce, uint256 missingAccountFunds) public {
        vm.assume(randomNonce < type(uint192).max);
        vm.assume(missingAccountFunds < 100 ether);

        prank(BOB.addr);
        prefundSmartAccountAndAssertSuccess(address(BOB_ACCOUNT), missingAccountFunds + 0.1 ether);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithCalldata(BOB, "", address(VALIDATOR_MODULE));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signUserOp(ALICE, userOps[0]); // Using a signature from a different user

        // Attempt to validate the user operation
        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, missingAccountFunds);
        assertTrue(res == 1, "Operation should fail validation due to invalid signature");
        stopPrank();
    }

    /// @notice Fuzz test for validateUserOp with an invalid nonce
    /// @param randomNonce The random nonce for the user operation
    /// @param missingAccountFunds The random missing funds for the account
    function testFuzz_ValidateUserOp_InvalidNonce(uint256 randomNonce, uint256 missingAccountFunds) public {
        vm.assume(randomNonce < type(uint192).max);
        vm.assume(missingAccountFunds < 100 ether);

        prefundSmartAccountAndAssertSuccess(address(BOB_ACCOUNT), missingAccountFunds + 0.1 ether);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(BOB.addr, randomNonce);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(BOB, userOpHash); // Using a valid signature

        prank(BOB.addr);
        prefundSmartAccountAndAssertSuccess(address(BOB_ACCOUNT), missingAccountFunds + 0.1 ether);

        // Attempt to validate the user operation
        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        assertTrue(res == 1, "Operation should fail validation due to invalid nonce");
        stopPrank();
    }

    /// @notice Fuzz test for validateUserOp with an invalid nonce and valid signature
    /// @param randomNonce The random nonce for the user operation
    /// @param missingAccountFunds The random missing funds for the account
    function testFuzz_ValidateUserOp_InvalidNonceAndValidSignature(uint256 randomNonce, uint256 missingAccountFunds) public {
        vm.assume(randomNonce < type(uint192).max);
        vm.assume(missingAccountFunds < 100 ether);

        prank(BOB.addr);
        prefundSmartAccountAndAssertSuccess(address(BOB_ACCOUNT), missingAccountFunds + 0.1 ether);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(BOB.addr, randomNonce);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signUserOp(BOB, userOps[0]); // Using a valid signature

        // Attempt to validate the user operation
        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, missingAccountFunds);
        assertTrue(res == 1, "Operation should fail validation due to invalid nonce");
        stopPrank();
    }

    /// @notice Fuzz test for validateUserOp with an invalid user address
    /// @param randomNonce The random nonce for the user operation
    /// @param userAddress The invalid user address for the user operation
    function testFuzz_ValidateUserOp_InvalidUserAddress(uint256 randomNonce, address userAddress) public {
        vm.assume(randomNonce < type(uint192).max);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, randomNonce);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(BOB, userOpHash); // Using a valid signature

        // Attempt to validate the user operation
        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        assertTrue(res == 1, "Operation should fail validation with an invalid user address");
        stopPrank();
    }
}
