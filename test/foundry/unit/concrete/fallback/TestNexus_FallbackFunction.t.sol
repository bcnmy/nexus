// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../../shared/TestModuleManagement_Base.t.sol";
import "../../../../../contracts/mocks/MockHandler.sol";

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

        // Make a call to the fallback function
        (bool success, bytes memory returnData) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
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
        (bool success, ) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
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
        (bool success, ) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        assertFalse(success, "State change through fallback static call should fail");
    }

    /// @notice Tests fallback handler with an invalid call type.
    function test_FallbackHandlerInvalidCallType() public {
        bytes4 selector = mockFallbackHandler.stateChangingFunction.selector;
        // Use an invalid call type (0xFF is not defined)
        bytes memory customData = abi.encodePacked(selector, bytes1(0xFF));
        installFallbackHandler(customData);

        // Make a call to the fallback function with an invalid call type
        (bool success, ) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        assertTrue(success, "Call with invalid call type should fail");
    }

    /// @notice Tests fallback handler when the handler is missing.
    function test_FallbackHandlerMissingHandler() public {
        bytes4 selector = bytes4(keccak256("nonexistentFunction()"));
        (bool success, ) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        // Review: since now we are not reverting this does not fail anymore. 
        assertFalse(success, "Call to missing fallback handler should fail");
    }

    /// @notice Tests fallback handler with an invalid function selector.
    function test_FallbackHandlerInvalidFunctionSelector() public {
        bytes4 selector = bytes4(keccak256("invalidFunction()"));
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Make a call to the fallback function with an invalid selector
        (bool success, ) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        assertFalse(success, "Call with invalid function selector should fail");
    }

    /// @notice Tests fallback handler with insufficient gas.
    function test_FallbackHandlerInsufficientGas() public {
        bytes4 selector = mockFallbackHandler.stateChangingFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Make a call to the fallback function with insufficient gas
        (bool success, ) = address(BOB_ACCOUNT).call{ gas: 1000 }(abi.encodeWithSelector(selector));
        assertFalse(success, "Call with insufficient gas should fail");
    }

    /// @notice Tests single call through the fallback handler that reverts.
    function test_FallbackHandlerSingleCall_Revert() public {
        bytes4 selector = mockFallbackHandler.revertingFunction.selector;
        bytes memory customData = abi.encodePacked(selector, CALLTYPE_SINGLE);
        installFallbackHandler(customData);

        // Make a call to the fallback function that reverts
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
        (bool success, bytes memory returnData) = address(BOB_ACCOUNT).call(abi.encodeWithSelector(selector));
        assertFalse(success, "Static call through fallback that reverts should fail");

        // Decode and verify the revert reason
        bytes memory revertReason = abi.encodeWithSignature("Error(string)", "REVERT");
        assertEq(revertReason, returnData, "Incorrect revert reason");
    }

    /// @notice Installs the fallback handler with the given selector and custom data.
    /// @param customData The custom data for the handler.
    function installFallbackHandler(bytes memory customData) internal {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_FALLBACK,
            address(mockFallbackHandler),
            customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the fallback handler was installed
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockFallbackHandler), customData), "Fallback handler not installed");
    }
}
