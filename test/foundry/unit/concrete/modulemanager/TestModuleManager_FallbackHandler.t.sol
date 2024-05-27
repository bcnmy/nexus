// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../shared/TestModuleManagement_Base.t.sol";

/// @title TestModuleManager_FallbackHandler
/// @notice Tests for installing and uninstalling the fallback handler in a smart account.
contract TestModuleManager_FallbackHandler is TestModuleManagement_Base {
    /// @notice Sets up the base module management environment and installs the fallback handler.
    function setUp() public {
        init();

        // Custom data for installing the MockHandler with call type STATIC
        bytes memory customData = abi.encode(bytes5(abi.encodePacked(GENERIC_FALLBACK_SELECTOR, CALLTYPE_SINGLE)));

        // Install MockHandler as the fallback handler for BOB_ACCOUNT
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_FALLBACK,
            address(HANDLER_MODULE),
            customData
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the fallback handler was installed
        assertEq(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData), true, "Fallback handler not installed");
    }

    /// @notice Tests triggering the onGenericFallback function of the fallback handler.
    function test_GenericFallbackHandlerTriggered() public {
        // Example sender, value, and data for the fallback call
        address exampleSender = address(this);
        uint256 exampleValue = 12_345;
        bytes memory exampleData = "Example data";

        // Expect the GenericFallbackCalled event to be emitted
        vm.expectEmit(true, true, true, true);
        emit GenericFallbackCalled(exampleSender, exampleValue, exampleData);

        // Trigger the onGenericFallback directly
        MockHandler(HANDLER_MODULE).onGenericFallback(exampleSender, exampleValue, exampleData);

        // Additional assertions could go here if needed
    }

    /// @notice Tests that handleOps triggers the generic fallback handler.
    function test_HandleOpsTriggersGenericFallback() public {
        // Prepare the operation that triggers the fallback handler
        bytes memory dataToTriggerFallback = abi.encodeWithSelector(
            MockHandler(address(0)).onGenericFallback.selector,
            address(this),
            123,
            "Example data"
        );
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, dataToTriggerFallback);

        // Prepare UserOperation
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        // Expect the GenericFallbackCalled event from the MockHandler contract
        vm.expectEmit(true, true, false, true, address(HANDLER_MODULE));
        emit GenericFallbackCalled(address(this), 123, "Example data");

        // Call handleOps, which should trigger the fallback handler and emit the event
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Tests installing a fallback handler.
    /// @param selector The function selector for the fallback handler.
    function test_InstallFallbackHandler(bytes4 selector) internal {
        bytes memory customData = abi.encode(selector);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_FALLBACK,
            address(HANDLER_MODULE),
            customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the fallback handler was installed for the given selector
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData), "Fallback handler not installed");
    }

    /// @notice Tests reversion when the function selector is already used by another handler.
    function test_RevertIf_FunctionSelectorAlreadyUsed() public {
        MockHandler otherHandler = new MockHandler();

        bytes memory customData = abi.encode(GENERIC_FALLBACK_SELECTOR);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_FALLBACK,
            address(otherHandler),
            customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        // Expected UserOperationRevertReason event due to function selector already used
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        bytes memory expectedRevertReason = abi.encodeWithSignature("FallbackAlreadyInstalledForSelector(bytes4)", GENERIC_FALLBACK_SELECTOR);

        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Tests reversion when uninstalling a fallback handler with a function selector not used.
    function test_RevertIf_FunctionSelectorNotUsed() public {
        MockHandler otherHandler = new MockHandler();

        bytes memory customData = abi.encode(UNUSED_SELECTOR);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_FALLBACK,
            address(otherHandler),
            customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        // Expected UserOperationRevertReason event due to function selector not used
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "ModuleNotInstalled(uint256,address)",
            MODULE_TYPE_FALLBACK,
            address(otherHandler)
        );

        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Tests reversion when uninstalling a fallback handler with a function selector not used by this handler.
    function test_RevertIf_FunctionSelectorNotUsedByThisHandler() public {
        bytes memory customData = abi.encode(UNUSED_SELECTOR);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_FALLBACK,
            address(HANDLER_MODULE),
            customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        // Expected UserOperationRevertReason event due to function selector not used by this handler
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "ModuleNotInstalled(uint256,address)",
            MODULE_TYPE_FALLBACK,
            address(HANDLER_MODULE)
        );

        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Tests the successful uninstallation of the fallback handler.
    function test_UninstallFallbackHandler_Success() public {
        // Correctly uninstall the fallback handler
        bytes memory customData = abi.encode(GENERIC_FALLBACK_SELECTOR);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_FALLBACK,
            address(HANDLER_MODULE),
            customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the fallback handler was uninstalled
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData), "Fallback handler was not uninstalled");
    }

    /// @notice Tests the successful uninstallation of the fallback handler.
    function test_RevertIf_UninstallNonInstalledFallbackHandler() public {
        // Correctly uninstall the fallback handler
        bytes memory customData = abi.encode(UNUSED_SELECTOR);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_FALLBACK,
            address(HANDLER_MODULE),
            customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the fallback handler was uninstalled
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData), "Fallback handler was not uninstalled");
    }

    /// @notice Tests getting the fallback handler by its function selector.
    /// @dev This test ensures that the correct fallback handler is returned for the given selector.
    function test_GetFallbackHandlerBySelector() public view {
        // Fetch the handler address for the provided selector
        (, address handlerAddress) = BOB_ACCOUNT.getFallbackHandlerBySelector(GENERIC_FALLBACK_SELECTOR);

        // Assert that the fetched handler address matches the expected handler module address
        assertEq(handlerAddress, address(HANDLER_MODULE), "getActiveHookHandlerBySelector returned incorrect handler address");
    }
}
