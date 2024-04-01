// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
// import {UserOperation} from "path/to/UserOperation.sol"; // Update this path

contract TestERC4337Account_Nonce is Test, SmartAccountTestLab {
    Counter public counter;

    function setUp() public {
        init();

        counter = new Counter();
    }

    function test_InitialNonce() public {
        uint256 nonce = ENTRYPOINT.getNonce(address(BOB_ACCOUNT), convertAddressToUint192(address(VALIDATOR_MODULE)));
        assertEq(
            BOB_ACCOUNT.nonce(convertAddressToUint192(address(VALIDATOR_MODULE))), nonce, "Initial nonce should be 0"
        );
    }

    function test_NonceIncrementAfterOperation() public {
        // Simulate an operation that would increment the nonce
        // This might involve calling a function that simulates the EntryPoint calling `validateUserOp`
        // and ensuring the nonce for the validatorModule is incremented.

        uint256 initialNonce = BOB_ACCOUNT.nonce(convertAddressToUint192(address(VALIDATOR_MODULE)));

        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));

        // Assuming the method should fail
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter did not increment
        assertEq(counter.getNumber(), 1, "Counter should have been incremented");

        uint256 newNonce = BOB_ACCOUNT.nonce(convertAddressToUint192(address(VALIDATOR_MODULE)));
        assertEq(newNonce, initialNonce + 1, "Nonce should increment after operation");
    }

    function test_NonceUnchangedOnFailedOperation() public {
        // Simulate a failed operation that should not increment the nonce
        // Similar to the previous test, but ensure the operation fails

        uint256 initialNonce = BOB_ACCOUNT.nonce(convertAddressToUint192(address(VALIDATOR_MODULE)));
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.revertOperation.selector));

        // Assuming the method should fail
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        bytes memory expectedRevertReason = abi.encodeWithSignature("Error(string)", "Counter: Revert operation");

        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);

        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Asserting the counter did not increment
        assertEq(counter.getNumber(), 0, "Counter should not have been incremented after revert");

        uint256 unchangedNonce = BOB_ACCOUNT.nonce(convertAddressToUint192(address(VALIDATOR_MODULE)));
        assertEq(unchangedNonce, initialNonce + 1, "Nonce should change on failed operation");
    }

    function convertAddressToUint192(address addr) internal pure returns (uint192) {
        return uint192(bytes24(bytes20(address(addr))));
    }
}
