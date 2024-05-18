// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";
// import {UserOperation} from "path/to/UserOperation.sol"; // Update this path

contract TestERC4337Account_Nonce is Test, NexusTest_Base {
    Counter public counter;

    function setUp() public {
        init();
        counter = new Counter();
    }

    function test_InitialNonce() public {
        uint256 nonce = ENTRYPOINT.getNonce(address(BOB_ACCOUNT), makeNonceKeyFromAddress(address(VALIDATOR_MODULE)));
        assertEq(BOB_ACCOUNT.nonce(makeNonceKeyFromAddress(address(VALIDATOR_MODULE))), nonce, "Nonce in the account and EP should be same");
    }

    function test_NonceIncrementAfterOperation() public {
        uint256 initialNonce = BOB_ACCOUNT.nonce(makeNonceKeyFromAddress(address(VALIDATOR_MODULE)));
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory executions = prepareSingleExecution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(counter.getNumber(), 1, "Counter should have been incremented");
        uint256 newNonce = BOB_ACCOUNT.nonce(makeNonceKeyFromAddress(address(VALIDATOR_MODULE)));
        assertEq(newNonce, initialNonce + 1, "Nonce should increment after operation");
    }

    function test_NonceIncrementedEvenOnFailedOperation() public {
        uint256 initialNonce = BOB_ACCOUNT.nonce(makeNonceKeyFromAddress(address(VALIDATOR_MODULE)));
        assertEq(counter.getNumber(), 0, "Counter should start at 0");

        Execution[] memory executions = prepareSingleExecution(address(counter), 0, abi.encodeWithSelector(Counter.revertOperation.selector));

        // Assuming the method should fail
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        bytes memory expectedRevertReason = abi.encodeWithSignature("Error(string)", "Counter: Revert operation");

        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(counter.getNumber(), 0, "Counter should not have been incremented after revert");
        uint256 newNonce = BOB_ACCOUNT.nonce(makeNonceKeyFromAddress(address(VALIDATOR_MODULE)));
        assertEq(newNonce, initialNonce + 1, "Nonce should change even on failed operation");
    }

    function makeNonceKeyFromAddress(address addr) internal pure returns (uint192) {
        return uint192(bytes24(bytes20(address(addr))));
    }
}
