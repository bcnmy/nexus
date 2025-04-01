// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../shared/TestModuleManagement_Base.t.sol";
import "../../../../../contracts/mocks/MockHandler.sol";
import "../../../../../contracts/mocks/MockTransferer.sol";

/// @title TestNexus_FallbackFunction
/// @notice Tests for handling fallback functions in the Nexus system.
contract TestNexus_FallbackFunction is TestModuleManagement_Base {
    MockHandler private mockFallbackHandler;

    /// @notice Sets up the base environment for fallback function tests.
    function setUp() public {
        init();
        mockFallbackHandler = new MockHandler();
        vm.label(address(mockFallbackHandler), "MockFallbackHandler");
    }

    /// @notice Tests setting the fallback handler.
    function test_SetFallbackHandler_Success() public {
        bytes4 selector = GENERIC_FALLBACK_SELECTOR;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);

        installFallbackHandler(customData);

        // Verify the fallback handler was installed
        (CallType callType, address handler) = BOB_ACCOUNT.getFallbackHandlerBySelector(selector);
        assertEq(handler, address(mockFallbackHandler), "Fallback handler not installed");
        assertEq(CallType.unwrap(callType), CallType.unwrap(CALLTYPE_SINGLE));
    }

    /// @notice Tests successful static call through the fallback handler.
    function test_FallbackHandlerStaticCall_Success() public {
        bytes4 selector = mockFallbackHandler.successFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_STATIC);
        installFallbackHandler(customData);

        prank(address(BOB_ACCOUNT));
        // Make a call to the fallback function
        (bool success, bytes memory returnData) = address(BOB_ACCOUNT).staticcall(abi.encodeWithSelector(selector));
        assertTrue(success, "Static call through fallback failed");

        // Decode and verify the return data
        bytes32 result = abi.decode(returnData, (bytes32));
        assertEq(result, keccak256("SUCCESS"));
    }

    /// @notice Tests successful single call through the fallback handler.
    function test_FallbackHandlerSingleCall_Success() public {
        bytes4 selector = mockFallbackHandler.successFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Make a call to the fallback function
        prank(address(BOB_ACCOUNT));
        (bool success, bytes memory returnData) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        assertTrue(success, "Single call through fallback failed");

        // Decode and verify the return data
        bytes32 result = abi.decode(returnData, (bytes32));
        assertEq(result, keccak256("SUCCESS"));
    }

    /// @notice Tests state change through the fallback handler using a single call.
    function test_FallbackHandlerStateChange_SingleCall() public {
        bytes4 selector = mockFallbackHandler.stateChangingFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Make a call to the fallback function that changes state
        prank(address(BOB_ACCOUNT));
        (bool success,) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        assertTrue(success, "State change through fallback single call failed");

        // Verify the state change
        uint256 newState = mockFallbackHandler.getState();
        assertEq(newState, 1, "State was not changed correctly");
    }

    /// @notice Tests state change through the fallback handler using a static call.
    function test_FallbackHandlerStateChange_StaticCall() public {
        bytes4 selector = mockFallbackHandler.stateChangingFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_STATIC);
        installFallbackHandler(customData);

        // Make a call to the fallback function that changes state (should fail)
        prank(address(BOB_ACCOUNT));
        (bool success,) = address(BOB_ACCOUNT).staticcall(abi.encodeWithSelector(selector));
        assertFalse(success, "State change through fallback static call should fail");
    }

    /// @notice Tests installing fallback handler with an invalid call type.
    function test_FallbackHandlerInvalidCallType() public {
        bytes4 selector = mockFallbackHandler.stateChangingFunction.selector;
        // Use an invalid call type (0xFF is not defined)
        bytes memory customData = abi.encodePacked(selector, bytes1(0xFF));

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_FALLBACK,
            address(mockFallbackHandler),
            customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);

        bytes memory expectedRevertReason = abi.encodeWithSelector(FallbackCallTypeInvalid.selector);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );
        
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Tests fallback handler when the handler is missing.
    function test_FallbackHandlerMissingHandler() public {
        bytes4 selector = bytes4(keccak256("nonexistentFunction()"));
        prank(address(BOB_ACCOUNT));
        (bool success,) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        assertFalse(success, "Call to missing fallback handler should fail");
    }

    /// @notice Tests fallback handler with an invalid function selector.
    function test_FallbackHandlerInvalidFunctionSelector() public {
        bytes4 selector = bytes4(keccak256("invalidFunction()"));
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Make a call to the fallback function with an invalid selector
        prank(address(BOB_ACCOUNT));
        (bool success,) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        assertFalse(success, "Call with invalid function selector should fail");
    }

    /// @notice Tests fallback handler with insufficient gas.
    function test_FallbackHandlerInsufficientGas() public {
        bytes4 selector = mockFallbackHandler.stateChangingFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Make a call to the fallback function with insufficient gas
        prank(address(BOB_ACCOUNT));
        (bool success,) = address(BOB_ACCOUNT).call{ gas: 1000 }(abi.encodeWithSelector(selector));
        assertFalse(success, "Call with insufficient gas should fail");
    }

    /// @notice Tests single call through the fallback handler that reverts.
    function test_FallbackHandlerSingleCall_Revert() public {
        bytes4 selector = mockFallbackHandler.revertingFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Make a call to the fallback function that reverts
        prank(address(BOB_ACCOUNT));
        (bool success, bytes memory returnData) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        assertFalse(success, "Single call through fallback that reverts should fail");

        // Decode and verify the revert reason
        bytes memory revertReason = abi.encodeWithSignature("Error(string)", "REVERT");
        assertEq(revertReason, returnData, "Incorrect revert reason");
    }

    /// @notice Tests static call through the fallback handler that reverts.
    function test_FallbackHandlerStaticCall_Revert() public {
        bytes4 selector = mockFallbackHandler.revertingFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_STATIC);
        installFallbackHandler(customData);

        // Make a call to the fallback function that reverts
        prank(address(BOB_ACCOUNT));
        (bool success, bytes memory returnData) = address(BOB_ACCOUNT).staticcall(abi.encodeWithSelector(selector));
        assertFalse(success, "Static call through fallback that reverts should fail");

        // Decode and verify the revert reason
        bytes memory revertReason = abi.encodeWithSignature("Error(string)", "REVERT");
        assertEq(revertReason, returnData, "Incorrect revert reason");
    }

    /// @notice Installs the fallback handler with the given selector and custom data.
    /// @param customData The custom data for the handler.
    function installFallbackHandler(bytes memory customData) internal {
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(mockFallbackHandler), customData);
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the fallback handler was installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockFallbackHandler), customData), "Fallback handler not installed");
    }

    /// @notice Tests fallback function call from the authorized entry point.
    function test_FallbackFunction_AuthorizedEntryPoint() public {
        bytes4 selector = mockFallbackHandler.successFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Simulate the call from the entry point
        prank(address(ENTRYPOINT));
        (bool success, bytes memory returnData) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        assertTrue(success, "Call from authorized entry point should succeed");

        // Decode and verify the return data
        bytes32 result = abi.decode(returnData, (bytes32));
        assertEq(result, keccak256("SUCCESS"));
    }

    /// @notice Tests fallback function call from the contract itself.
    function test_FallbackFunction_AuthorizedSelf() public {
        bytes4 selector = mockFallbackHandler.successFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Simulate the call from the contract itself
        prank(address(BOB_ACCOUNT));
        (bool success, bytes memory returnData) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        assertTrue(success, "Call from the contract itself should succeed");

        // Decode and verify the return data
        bytes32 result = abi.decode(returnData, (bytes32));
        assertEq(result, keccak256("SUCCESS"));
    }

    /// @notice Tests fallback function call from the authorized executor module.
    function test_FallbackFunction_AuthorizedExecutorModule() public {
        // Setting up the fallback handler
        bytes4 selector = mockFallbackHandler.successFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Install the executor module
        bytes memory executorInstallData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), "");
        installModule(executorInstallData, MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), EXECTYPE_DEFAULT);

        // Simulate the call from the executor module
        vm.prank(address(EXECUTOR_MODULE)); // Set the sender to the executor module
        (bool success, bytes memory returnData) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));

        // Verify that the call was successful
        assertTrue(success, "Call from authorized executor module should succeed");

        // Decode and verify the return data
        bytes32 result = abi.decode(returnData, (bytes32));
        assertEq(result, keccak256("SUCCESS"));
    }

    /// @notice Tests fallback function call from an unauthorized entity.
    function test_FallbackFunction_UnauthorizedEntity() public {
        bytes4 selector = mockFallbackHandler.successFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Simulate the call from an unauthorized entity
        address unauthorizedCaller = address(0x123);
        prank(unauthorizedCaller);
        vm.expectRevert(abi.encodeWithSelector(UnauthorizedOperation.selector, unauthorizedCaller));
        (bool success,) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
    }

    function test_receive_transfer() public {
        MockTransferer transferer = new MockTransferer();
        vm.deal(address(transferer), 10 ether);
        transferer.transfer(address(BOB_ACCOUNT), 1 ether);
        assertEq(address(transferer).balance, 9 ether);
        assertEq(address(BOB_ACCOUNT).balance, 1 ether);
    }

    /// @notice Installs a module to the smart account.
    function installModule(bytes memory callData, uint256 moduleTypeId, address module) internal {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE), 0);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the module was installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(moduleTypeId, module, ""), "Module should be installed");
    }

}
