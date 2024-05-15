// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/SmartAccountTestLab.t.sol";

contract TestFuzz_ValidateUserOp is SmartAccountTestLab {
    address public userAddress = address(BOB.addr);
    function setUp() public {
        init(); // Initializes all required contracts and wallets
    }

    function testFuzz_ValidateUserOp(uint256 randomNonce, uint256 missingAccountFunds, bytes calldata randomSignature) public {
        vm.assume(randomNonce < type(uint192).max); // Assuming practical nonce range
        vm.assume(missingAccountFunds < 100 ether); // Assume missing funds are less than 100 ether

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(userAddress, randomNonce);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = randomSignature; // Using fuzzed signature

        // Attempt to validate the user operation
        startPrank(address(ENTRYPOINT));
        uint256 res = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, missingAccountFunds);
        assertTrue(res == 1, "Operation should fail validation properly");
        stopPrank();
    }
}
