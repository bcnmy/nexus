// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../shared/TestAccountExecution_Base.t.sol";

/// @title TestAccountExecution_TryExecuteSingle
/// @notice This contract tests single execution attempts using the try method in the account execution system.
contract TestAccountExecution_TryExecuteSingle is TestAccountExecution_Base {
    MockDelegateTarget delegateTarget;
    /// @notice Sets up the testing environment.
    function setUp() public {
        setUpTestAccountExecution_Base();
        delegateTarget = new MockDelegateTarget();
    }

    /// @notice Tests successful execution of a single operation.
    function test_ExecuteDelegateCall_Success() public {

        (bool res, ) = payable(address(BOB_ACCOUNT)).call{ value: 2 ether}(""); // Fund BOB_ACCOUNT
        assertEq(res, true, "Funding BOB_ACCOUNT should succeed");

        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");
        // Create calldata for the account to execute
        address valueTarget = makeAddr("valueTarget");
        uint256 value = 1 ether;

        bytes memory sendValue =
            abi.encodeWithSelector(MockDelegateTarget.sendValue.selector, valueTarget, value);

        // placeholder
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));


        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);

         bytes memory userOpCalldata = abi.encodeCall(
            Nexus.execute,
            (
                ModeLib.encode(
                    CALLTYPE_DELEGATECALL, EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00)
                ),
                abi.encodePacked(address(delegateTarget), sendValue)
            )
        );

        userOps[0].callData = userOpCalldata;

        // Sign the operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signPureHash(BOB, userOpHash);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
         // Assert that the value was set ie that execution was successful
        assertTrue(valueTarget.balance == value);
    }

    /// @notice Tests successful execution of a single operation.
    function test_TryExecuteDelegateCall_Success() public {

        (bool res, ) = payable(address(BOB_ACCOUNT)).call{ value: 2 ether}(""); // Fund BOB_ACCOUNT
        assertEq(res, true, "Funding BOB_ACCOUNT should succeed");

        // Initial state assertion
        assertEq(counter.getNumber(), 0, "Counter should start at 0");
        // Create calldata for the account to execute
        address valueTarget = makeAddr("valueTarget");
        uint256 value = 1 ether;

        bytes memory sendValue =
            abi.encodeWithSelector(MockDelegateTarget.sendValue.selector, valueTarget, value);

        // placeholder
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));


        // Build UserOperation for single execution
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_TRY, execution, address(VALIDATOR_MODULE), 0);

         bytes memory userOpCalldata = abi.encodeCall(
            Nexus.execute,
            (
                ModeLib.encode(
                    CALLTYPE_DELEGATECALL, EXECTYPE_TRY, MODE_DEFAULT, ModePayload.wrap(0x00)
                ),
                abi.encodePacked(address(delegateTarget), sendValue)
            )
        );

        userOps[0].callData = userOpCalldata;

        // Sign the operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signPureHash(BOB, userOpHash);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
         // Assert that the value was set ie that execution was successful
        assertTrue(valueTarget.balance == (value));
    }
}
