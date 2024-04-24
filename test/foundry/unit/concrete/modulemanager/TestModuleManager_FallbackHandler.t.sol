// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../unit/shared/TestModuleManagement_Base.t.sol";

contract TestModuleManager_FallbackHandler is TestModuleManagement_Base {
    function setUp() public {
        init();

        // Custom data for installing the MockHandler
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));

        // Install MockHandler as the fallback handler for BOB_ACCOUNT
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the fallback handler was installed
        assertEq(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData),
            true,
            "Fallback handler not installed"
        );
    }

    // Test triggering the onGenericFallback function
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

    function test_HandleOpsTriggersGenericFallback() public {
        // Prepare the operation that triggers the fallback handler
        bytes memory dataToTriggerFallback = abi.encodeWithSelector(
            MockHandler(address(0)).onGenericFallback.selector, address(this), 123, "Example data"
        );
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, dataToTriggerFallback);

        // Prepare UserOperation
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);

        // Expect the GenericFallbackCalled event from the MockHandler contract
        vm.expectEmit(true, true, false, true, address(HANDLER_MODULE));
        emit GenericFallbackCalled(address(this), 123, "Example data");

        // Call handleOps, which should trigger the fallback handler and emit the event
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    function test_InstallFallbackHandler(bytes4 selector) internal {
        bytes memory customData = abi.encode(selector);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the fallback handler was installed for the given selector
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData),
            "Fallback handler not installed"
        );
    }

    function test_InstallFallbackHandler_FunctionSelectorAlreadyUsed() public {
        MockHandler otherHandler = new MockHandler();

        bytes memory customData = abi.encode(GENERIC_FALLBACK_SELECTOR);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(otherHandler), customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        // Expected UserOperationRevertReason event due to function selector already used
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        bytes memory expectedRevertReason =
            abi.encodeWithSignature("FallbackAlreadyInstalledForSelector(bytes4)", GENERIC_FALLBACK_SELECTOR);

        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    function test_UninstallFallbackHandler_FunctionSelectorNotUsed() public {
        MockHandler otherHandler = new MockHandler();

        bytes memory customData = abi.encode(UNUSED_SELECTOR);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector, MODULE_TYPE_FALLBACK, address(otherHandler), customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        // Expected UserOperationRevertReason event due to function selector not used
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        bytes memory expectedRevertReason =
            abi.encodeWithSignature("ModuleNotInstalled(uint256,address)", MODULE_TYPE_FALLBACK, address(otherHandler));

        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    function test_UninstallFallbackHandler_FunctionSelectorNotUsedByThisHandler() public {
        MockHandler otherHandler = new MockHandler();

        bytes memory customData = abi.encode(UNUSED_SELECTOR); // Assuming GENERIC_FALLBACK_SELECTOR is set
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector, MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        // Expected UserOperationRevertReason event due to function selector not used by this handler
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        bytes memory expectedRevertReason = abi.encodeWithSignature(
            "ModuleNotInstalled(uint256,address)", MODULE_TYPE_FALLBACK, address(HANDLER_MODULE)
        );

        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    function test_UninstallFallbackHandler_Success() public {
        // Correctly uninstall the fallback handler
        bytes memory customData = abi.encode(GENERIC_FALLBACK_SELECTOR);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector, MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        // Verify the fallback handler was uninstalled
        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData),
            "Fallback handler was not uninstalled"
        );
    }

    function test_UninstallFallbackHandler_Failed() public {
        BadMockHandler badHandleModule = new BadMockHandler();
        bytes memory customData = abi.encode(bytes4(UNUSED_SELECTOR));

        // Install MockHandler as the fallback handler for BOB_ACCOUNT
        bytes memory installCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(badHandleModule), customData
        );
        Execution[] memory executionInstall = new Execution[](1);
        executionInstall[0] = Execution(address(BOB_ACCOUNT), 0, installCallData);
        PackedUserOperation[] memory userOpsInstall =
            prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executionInstall);
        ENTRYPOINT.handleOps(userOpsInstall, payable(address(BOB.addr)));

        bytes memory uninstallCallData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector, MODULE_TYPE_FALLBACK, address(badHandleModule), customData
        );
        Execution[] memory executionUninstall = new Execution[](1);
        executionUninstall[0] = Execution(address(BOB_ACCOUNT), 0, uninstallCallData);
        PackedUserOperation[] memory userOpsUninstall =
            prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executionUninstall);

        ENTRYPOINT.handleOps(userOpsUninstall, payable(address(BOB.addr)));

        // Verify the fallback handler was uninstalled
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(badHandleModule), customData),
            "Fallback handler was uninstalled"
        );
    }

    function test_GetFallbackHandlerBySelector() public {
        (, address handlerAddress) = BOB_ACCOUNT.getFallbackHandlerBySelector(GENERIC_FALLBACK_SELECTOR);
        assertEq(
            handlerAddress, address(HANDLER_MODULE), "getActiveHookHandlerBySelector returned incorrect handler address"
        );
    }
}
