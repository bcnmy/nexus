// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/BicoTestBase.t.sol";
// import {UserOperation} from "path/to/UserOperation.sol"; // Update this path

contract TestERC4337Account_ValidateUserOp is Test, BicoTestBase {
    ERC4337Account public account;
    MockValidator public validator;
    address public userAddress;
    SmartAccount public BOB_ACCOUNT;

    function setUp() public {
        init();
        userAddress = address(BOB.addr);
        BOB_ACCOUNT = SmartAccount(deploySmartAccount(BOB));
        validator = new MockValidator();
    }

    function test_ValidateUserOp_ValidOperation() public {
        // Initialize a user operation with a valid setup
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessageAndGetSignatureBytes(BOB, userOpHash);

        // Attempt to validate the user operation, expecting success
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 10);
        assertTrue(res == 0, "Valid operation should pass validation");
    }

    function test_ValidateUserOp_InvalidSignature() public {
        // Initialize a user operation with a valid nonce but signed by an incorrect signer
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE)));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessageAndGetSignatureBytes(ALICE, userOpHash); // Incorrect signer simulated

        // Attempt to validate the user operation, expecting failure due to invalid signature
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        assertTrue(res == 1, "Operation with invalid signature should fail validation");
    }
}
