// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../shared/TestAccountExecution_Base.t.sol";
import { Storage } from "composability/Storage.sol";
import {
    ComposableExecution,
    ComposableExecutionBase,
    InputParam,
    OutputParam,
    Constraint,
    ConstraintType,
    InputParamFetcherType,
    OutputParamFetcherType,
    InputParamType
} from "composability/ComposableExecutionBase.sol";
import { ComposableExecutionLib } from "composability/ComposableExecutionLib.sol";
import "node_modules/@biconomy/composability/test/mock/DummyContract.sol";

/// @title Regression tests for ComposableExecution multiple constraints validation
/// @dev Verifies that multiple constraints on single-word inputs validate the actual fetched value
contract TestComposableExecution_MultiConstraints is TestAccountExecution_Base {
    Storage public storageContract;
    DummyContract public dummyContract;

    function setUp() public {
        setUpTestAccountExecution_Base();
        storageContract = new Storage();
        dummyContract = new DummyContract();
        vm.deal(address(BOB_ACCOUNT), 100 ether);
    }

    /// @notice Validates that duplicate valid constraints succeed instead of falsely reverting on OOB heap memory
    function test_MultipleConstraints_DuplicateEQ_Succeeds() public {
        Constraint[] memory c = new Constraint[](2);
        c[0] = Constraint({ constraintType: ConstraintType.EQ, referenceData: abi.encode(bytes32(uint256(777))) });
        c[1] = Constraint({ constraintType: ConstraintType.EQ, referenceData: abi.encode(bytes32(uint256(777))) });

        InputParam[] memory inputParams = new InputParam[](2);
        inputParams[0] = InputParam({
            paramType: InputParamType.TARGET,
            fetcherType: InputParamFetcherType.RAW_BYTES,
            paramData: abi.encode(address(dummyContract)),
            constraints: new Constraint[](0)
        });
        inputParams[1] = InputParam({
            paramType: InputParamType.CALL_DATA,
            fetcherType: InputParamFetcherType.RAW_BYTES,
            paramData: abi.encode(uint256(777)),
            constraints: c
        });

        ComposableExecution[] memory executions = new ComposableExecution[](1);
        executions[0] = ComposableExecution({
            functionSig: DummyContract.setFoo.selector,
            inputParams: inputParams,
            outputParams: new OutputParam[](0)
        });

        bytes memory callData = abi.encodeWithSelector(ComposableExecutionBase.executeComposable.selector, executions);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithCalldata(BOB, callData, address(VALIDATOR_MODULE));

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(dummyContract.getFoo(), 777, "setFoo(777) should succeed when both constraints match the value");
    }

    /// @notice Validates that a realistic range check (GTE and LTE) passes when the value is within range
    function test_MultipleConstraints_RangeCheck_WithinBounds_Succeeds() public {
        Constraint[] memory c = new Constraint[](2);
        c[0] = Constraint({ constraintType: ConstraintType.GTE, referenceData: abi.encode(bytes32(uint256(700))) });
        c[1] = Constraint({ constraintType: ConstraintType.LTE, referenceData: abi.encode(bytes32(uint256(800))) });

        InputParam[] memory inputParams = new InputParam[](2);
        inputParams[0] = InputParam({
            paramType: InputParamType.TARGET,
            fetcherType: InputParamFetcherType.RAW_BYTES,
            paramData: abi.encode(address(dummyContract)),
            constraints: new Constraint[](0)
        });
        inputParams[1] = InputParam({
            paramType: InputParamType.CALL_DATA,
            fetcherType: InputParamFetcherType.RAW_BYTES,
            paramData: abi.encode(uint256(777)),
            constraints: c
        });

        ComposableExecution[] memory executions = new ComposableExecution[](1);
        executions[0] = ComposableExecution({
            functionSig: DummyContract.setFoo.selector,
            inputParams: inputParams,
            outputParams: new OutputParam[](0)
        });

        bytes memory callData = abi.encodeWithSelector(ComposableExecutionBase.executeComposable.selector, executions);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithCalldata(BOB, callData, address(VALIDATOR_MODULE));

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertEq(dummyContract.getFoo(), 777, "setFoo(777) should succeed when 700 <= 777 <= 800");
    }

    /// @notice Validates that an upper-bound constraint violation (LTE) reverts as expected and does not bypass
    function test_MultipleConstraints_SecurityBound_RAW_BYTES_RevertsOnViolation() public {
        uint256 REAL_VALUE = 999_999_999;
        uint256 POLICY_MAX = 1000;

        Constraint[] memory c = new Constraint[](2);
        c[0] = Constraint({ constraintType: ConstraintType.GTE, referenceData: abi.encode(bytes32(uint256(0))) });
        c[1] = Constraint({ constraintType: ConstraintType.LTE, referenceData: abi.encode(bytes32(POLICY_MAX)) });

        InputParam[] memory inputParams = new InputParam[](2);
        inputParams[0] = InputParam({
            paramType: InputParamType.TARGET,
            fetcherType: InputParamFetcherType.RAW_BYTES,
            paramData: abi.encode(address(dummyContract)),
            constraints: new Constraint[](0)
        });
        inputParams[1] = InputParam({
            paramType: InputParamType.CALL_DATA,
            fetcherType: InputParamFetcherType.RAW_BYTES,
            paramData: abi.encode(REAL_VALUE),
            constraints: c
        });

        ComposableExecution[] memory executions = new ComposableExecution[](1);
        executions[0] = ComposableExecution({
            functionSig: DummyContract.setFoo.selector,
            inputParams: inputParams,
            outputParams: new OutputParam[](0)
        });

        bytes memory callData = abi.encodeWithSelector(ComposableExecutionBase.executeComposable.selector, executions);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithCalldata(BOB, callData, address(VALIDATOR_MODULE));

        vm.recordLogs();
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        bytes memory revertReason;
        bytes32 userOpRevertTopic = keccak256("UserOperationRevertReason(bytes32,address,uint256,bytes)");
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics.length > 0 && logs[i].topics[0] == userOpRevertTopic) {
                (, revertReason) = abi.decode(logs[i].data, (uint256, bytes));
            }
        }

        assertEq(dummyContract.getFoo(), 0, "Execution must not mutate state when constraint is violated");
        assertTrue(revertReason.length >= 4, "Must revert with UserOperationRevertReason");

        bytes4 gotSelector;
        assembly {
            gotSelector := mload(add(revertReason, 0x20))
        }
        assertEq(gotSelector, ComposableExecutionLib.ConstraintNotMet.selector, "Revert selector must be ConstraintNotMet");
    }

    /// @notice Validates that an upper-bound constraint violation on BALANCE fetcher reverts as expected
    function test_MultipleConstraints_SecurityBound_BALANCE_RevertsOnViolation() public {
        uint256 POLICY_MAX = 10 ether;

        Constraint[] memory c = new Constraint[](2);
        c[0] = Constraint({ constraintType: ConstraintType.GTE, referenceData: abi.encode(bytes32(uint256(0))) });
        c[1] = Constraint({ constraintType: ConstraintType.LTE, referenceData: abi.encode(bytes32(POLICY_MAX)) });

        InputParam[] memory inputParams = new InputParam[](2);
        inputParams[0] = InputParam({
            paramType: InputParamType.TARGET,
            fetcherType: InputParamFetcherType.RAW_BYTES,
            paramData: abi.encode(address(dummyContract)),
            constraints: new Constraint[](0)
        });
        inputParams[1] = InputParam({
            paramType: InputParamType.CALL_DATA,
            fetcherType: InputParamFetcherType.BALANCE,
            paramData: abi.encodePacked(address(0), address(BOB_ACCOUNT)), // Native balance = 100 ether
            constraints: c
        });

        ComposableExecution[] memory executions = new ComposableExecution[](1);
        executions[0] = ComposableExecution({
            functionSig: DummyContract.setFoo.selector,
            inputParams: inputParams,
            outputParams: new OutputParam[](0)
        });

        bytes memory callData = abi.encodeWithSelector(ComposableExecutionBase.executeComposable.selector, executions);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithCalldata(BOB, callData, address(VALIDATOR_MODULE));

        vm.recordLogs();
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        Vm.Log[] memory logs = vm.getRecordedLogs();

        bytes memory revertReason;
        bytes32 userOpRevertTopic = keccak256("UserOperationRevertReason(bytes32,address,uint256,bytes)");
        for (uint256 i; i < logs.length; i++) {
            if (logs[i].topics.length > 0 && logs[i].topics[0] == userOpRevertTopic) {
                (, revertReason) = abi.decode(logs[i].data, (uint256, bytes));
            }
        }

        assertEq(dummyContract.getFoo(), 0, "Execution must not mutate state when balance exceeds LTE bound");
        assertTrue(revertReason.length >= 4, "Must revert with UserOperationRevertReason");

        bytes4 gotSelector;
        assembly {
            gotSelector := mload(add(revertReason, 0x20))
        }
        assertEq(gotSelector, ComposableExecutionLib.ConstraintNotMet.selector, "Revert selector must be ConstraintNotMet");
    }
}
