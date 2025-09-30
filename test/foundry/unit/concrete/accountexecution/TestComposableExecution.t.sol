// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../shared/TestAccountExecution_Base.t.sol";
import {Storage} from "composability/Storage.sol";
import {ComposableExecution, ComposableExecutionBase, InputParam, OutputParam, Constraint, ConstraintType, InputParamFetcherType, OutputParamFetcherType} from "composability/ComposableExecutionBase.sol";

import "node_modules/@biconomy/composability/test/mock/DummyContract.sol";

contract ComposableExecutionTest is TestAccountExecution_Base {

    event MockAccountReceive(uint256 amount);
    Storage public storageContract;
    DummyContract public dummyContract;

    address public eoa = address(0x11ce);
    bytes32 public constant SLOT_A = keccak256("SLOT_A");
    bytes32 public constant SLOT_B = keccak256("SLOT_B");

    Constraint[] internal emptyConstraints;

    uint256 input1 = 2517;
    uint256 input2 = 7579;

    function setUp() public {
        setUpTestAccountExecution_Base();
        storageContract = new Storage();
        dummyContract = new DummyContract();
        vm.deal(eoa, 100 ether);
        vm.deal(address(BOB_ACCOUNT), 100 ether);
    }

    /// @notice Tests successful composable execution
    function test_ExecuteComposable_Success() public {
        dummyContract.setFoo(input1);

        // Constraints
        Constraint[] memory constraints_input1_1 = new Constraint[](1);
        constraints_input1_1[0] = Constraint({
            constraintType: ConstraintType.EQ,
            referenceData: abi.encode(bytes32(input1))
        });
        Constraint[] memory constraints_input1_2 = new Constraint[](1);
        constraints_input1_2[0] = Constraint({
            constraintType: ConstraintType.IN,
            referenceData: abi.encode(bytes32(uint256(input2-1)), bytes32(uint256(input2+1)))
        });

        // first execution => call swap and store the result in the composability storage
        InputParam[] memory inputParams_execution1 = new InputParam[](2);
        inputParams_execution1[0] = InputParam({
            fetcherType: InputParamFetcherType.RAW_BYTES,
            paramData: abi.encode(input1),
            constraints: constraints_input1_1
        });
        inputParams_execution1[1] = InputParam({
            fetcherType: InputParamFetcherType.RAW_BYTES,
            paramData: abi.encode(input2),
            constraints: constraints_input1_2
        });

        OutputParam[] memory outputParams_execution1 = new OutputParam[](2);
        outputParams_execution1[0] = OutputParam({
            fetcherType: OutputParamFetcherType.EXEC_RESULT,
            paramData: abi.encode(1, address(storageContract), SLOT_A)
        });
        outputParams_execution1[1] = OutputParam({
            fetcherType: OutputParamFetcherType.STATIC_CALL,
            paramData: abi.encode(
                1,
                address(dummyContract),
                abi.encodeWithSelector(DummyContract.getFoo.selector),
                address(storageContract),
                SLOT_B
            )
        });

        bytes32 namespace = storageContract.getNamespace(address(BOB_ACCOUNT), address(BOB_ACCOUNT));
        bytes32 SLOT_A_0 = keccak256(abi.encodePacked(SLOT_A, uint256(0)));
        bytes32 SLOT_B_0 = keccak256(abi.encodePacked(SLOT_B, uint256(0)));

        // second execution => call stake with the result of the first execution
        Constraint[] memory constraints_input2_1 = new Constraint[](1);
        constraints_input2_1[0] = Constraint({
            constraintType: ConstraintType.EQ,
            referenceData: abi.encode(bytes32(input1+1))
        });
        
        InputParam[] memory inputParams_execution2 = new InputParam[](2);
        inputParams_execution2[0] = InputParam({
            fetcherType: InputParamFetcherType.STATIC_CALL,
            paramData: abi.encode(storageContract, abi.encodeCall(Storage.readStorage, (namespace, SLOT_A_0))),
            constraints: constraints_input2_1
        });
        inputParams_execution2[1] = InputParam({
            fetcherType: InputParamFetcherType.STATIC_CALL,
            paramData: abi.encode(storageContract, abi.encodeCall(Storage.readStorage, (namespace, SLOT_B_0))),
            constraints: emptyConstraints
        });
        OutputParam[] memory outputParams_execution2 = new OutputParam[](0);

        uint256 valueToSend = 1e15;

        ComposableExecution[] memory executions = new ComposableExecution[](2);
        executions[0] = ComposableExecution({
            to: address(dummyContract),
            value: valueToSend,
            functionSig: DummyContract.swap.selector,
            inputParams: inputParams_execution1,
            outputParams: outputParams_execution1
        });
        executions[1] = ComposableExecution({
            to: address(dummyContract),
            value: valueToSend,
            functionSig: DummyContract.stake.selector,
            inputParams: inputParams_execution2,
            outputParams: outputParams_execution2
        });

        // Build user operation
        bytes memory callData = abi.encodeWithSelector(ComposableExecutionBase.executeComposable.selector, executions);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithCalldata(BOB, callData, address(VALIDATOR_MODULE));

        uint256 expectedToStake = input1 + 1;
        vm.expectEmit(address(dummyContract));
        // swap emits input params
        emit Uint256Emitted2(input1, input2);
        // swap emits output param
        emit Uint256Emitted(expectedToStake);
        // stake emits input params: first param is from swap, second param is from getFoo which is just input1
        emit Uint256Emitted2(expectedToStake, input1);
        emit Received(valueToSend);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        

        //check storage slots
        bytes32 storedValueA = storageContract.readStorage(namespace, SLOT_A_0);
        assertEq(uint256(storedValueA), expectedToStake, "Value not stored correctly in the composability storage");
        bytes32 storedValueB = storageContract.readStorage(namespace, SLOT_B_0);
        assertEq(uint256(storedValueB), input1, "Value not stored correctly in the composability storage");
    }


}
