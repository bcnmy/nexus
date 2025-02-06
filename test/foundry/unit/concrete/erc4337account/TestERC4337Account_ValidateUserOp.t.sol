// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";

/// @title TestERC4337Account_ValidateUserOp
/// @notice Tests for the validateUserOp function in the ERC4337 account.
contract TestERC4337Account_ValidateUserOp is Test, NexusTest_Base {
    Vm.Wallet internal signer;
    Nexus internal account;

    /// @notice Sets up the testing environment.
    function setUp() public {
        init();
        signer = createAndFundWallet("Signer", 0.0001 ether);
        account = deployNexus(signer, 0.0001 ether, address(VALIDATOR_MODULE));
    }

    /// @notice Tests that the prefund payment is handled with sufficient funds.
    function testPayPrefund_WithSufficientFunds() public {
        vm.deal(address(account), 1 ether);

        Execution[] memory executions = prepareSingleExecution(address(account), 0, "");
        PackedUserOperation[] memory userOps = buildPackedUserOperation(signer, account, EXECTYPE_TRY, executions, address(VALIDATOR_MODULE), 0);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signPureHash(signer, userOpHash);

        startPrank(address(ENTRYPOINT));
        account.validateUserOp(userOps[0], userOpHash, 0.1 ether);
        stopPrank();
    }

    /// @notice Tests a valid user operation.
    function test_ValidateUserOp_ValidOperation() public {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(signer.addr, getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), bytes3(0)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signPureHash(BOB, userOpHash);

        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        assertTrue(res == 0, "Valid operation should pass validation");
        stopPrank();
    }

    /// @notice Tests an invalid signature for the user operation.
    function test_ValidateUserOp_InvalidSignature() public {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(signer.addr, getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), bytes3(0)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signPureHash(ALICE, userOpHash);

        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        assertTrue(res == 1, "Operation with invalid signature should fail validation");
        stopPrank();
    }

    /// @notice Tests an invalid signature format for the user operation.
    function test_ValidateUserOp_InvalidSignatureFormat() public {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(signer.addr, getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), bytes3(0)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = "0x1234"; // Incorrect format, too short

        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        assertTrue(res == 1, "Operation with invalid signature format should fail validation");
        stopPrank();
    }

    /// @notice Tests user operation validation with insufficient funds.
    function test_ValidateUserOp_InsufficientFunds() public {
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(signer.addr, getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), bytes3(0)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signPureHash(BOB, userOpHash);

        startPrank(address(ENTRYPOINT));
        BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0.5 ether);
        stopPrank();
    }

    /// @notice Tests user operation validation with an invalid nonce.
    function test_RevertWhen_InvalidNonce() public {
        uint256 correctNonce = getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(VALIDATOR_MODULE), 0x123456);
        uint256 incorrectNonce = correctNonce + 1; // deliberately incorrect to simulate invalid nonce

        vm.deal(address(account), 1 ether);

        Execution[] memory executions = prepareSingleExecution(address(account), 0, "");
        PackedUserOperation[] memory userOps = buildPackedUserOperation(signer, account, EXECTYPE_TRY, executions, address(VALIDATOR_MODULE), incorrectNonce);
        
        bytes memory expectedRevertReason = abi.encodeWithSelector(
            FailedOp.selector, 
            0, 
            "AA25 invalid account nonce"
        );
        
        vm.expectRevert(expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(signer.addr)));
    }
}
