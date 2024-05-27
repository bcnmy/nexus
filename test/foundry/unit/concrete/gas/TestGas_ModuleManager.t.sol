// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../shared/TestModuleManagement_Base.t.sol";

contract TestGas_ModuleManager is TestModuleManagement_Base {
    function setUp() public {
        setUpModuleManagement_Base();
    }

    // Install Modules

    function test_Gas_InstallValidatorModule() public {
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(mockValidator), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for installValidatorModule: ", gasUsed);
    }

    function test_Gas_InstallExecutorModule() public {
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(mockExecutor), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for installExecutorModule: ", gasUsed);
    }

    function test_Gas_InstallHookModule() public {
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(mockHook), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for installHookModule: ", gasUsed);
    }

    function test_Gas_InstallFallbackHandler() public {
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_FALLBACK, address(mockHandler), customData);

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for installFallbackHandler: ", gasUsed);
    }

    // Uninstall Modules

    function test_Gas_UninstallValidatorModule() public {
        // Install module first
        bytes memory installCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(mockValidator),
            ""
        );
        Execution[] memory installExecution = new Execution[](1);
        installExecution[0] = Execution(address(BOB_ACCOUNT), 0, installCallData);
        PackedUserOperation[] memory installUserOps = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            installExecution,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(installUserOps, payable(address(BOB.addr)));

        // Uninstall module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_VALIDATOR,
            address(mockValidator),
            abi.encode(address(VALIDATOR_MODULE), "")
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for uninstallValidatorModule: ", gasUsed);
    }

    function test_Gas_UninstallExecutorModule() public {
        // Install module first
        bytes memory installCallData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_EXECUTOR, address(mockExecutor), "");
        Execution[] memory installExecution = new Execution[](1);
        installExecution[0] = Execution(address(BOB_ACCOUNT), 0, installCallData);
        PackedUserOperation[] memory installUserOps = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            installExecution,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(installUserOps, payable(address(BOB.addr)));

        // Uninstall module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_EXECUTOR,
            address(mockExecutor),
            abi.encode(address(VALIDATOR_MODULE), "")
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for uninstallExecutorModule: ", gasUsed);
    }

    function test_Gas_UninstallHookModule() public {
        // Install module first
        bytes memory installCallData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(mockHook), "");
        Execution[] memory installExecution = new Execution[](1);
        installExecution[0] = Execution(address(BOB_ACCOUNT), 0, installCallData);
        PackedUserOperation[] memory installUserOps = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            installExecution,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(installUserOps, payable(address(BOB.addr)));

        // Uninstall module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_HOOK,
            address(mockHook),
            abi.encode(address(VALIDATOR_MODULE), "")
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for uninstallHookModule: ", gasUsed);
    }

    function test_Gas_UninstallFallbackHandler() public {
        // Install module first
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));
        bytes memory installCallData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_FALLBACK,
            address(mockHandler),
            customData
        );
        Execution[] memory installExecution = new Execution[](1);
        installExecution[0] = Execution(address(BOB_ACCOUNT), 0, installCallData);
        PackedUserOperation[] memory installUserOps = buildPackedUserOperation(
            BOB,
            BOB_ACCOUNT,
            EXECTYPE_DEFAULT,
            installExecution,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(installUserOps, payable(address(BOB.addr)));

        // Uninstall module
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.uninstallModule.selector,
            MODULE_TYPE_FALLBACK,
            address(mockHandler),
            customData
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for uninstallFallbackHandler: ", gasUsed);
    }

    function test_Gas_InstallValidatorModule_CheckIsInstalled() public {
        test_Gas_InstallValidatorModule();
        uint256 initialGas = gasleft();
        bool isInstalled = BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), "");
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for isModuleInstalled after installing Validator Module: ", gasUsed);
        assertTrue(isInstalled, "Validator Module should be installed");
    }

    function test_Gas_InstallExecutorModule_CheckIsInstalled() public {
        test_Gas_InstallExecutorModule();
        uint256 initialGas = gasleft();
        bool isInstalled = BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockExecutor), "");
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for isModuleInstalled after installing Executor Module: ", gasUsed);
        assertTrue(isInstalled, "Executor Module should be installed");
    }

    function test_Gas_InstallHookModule_CheckIsInstalled() public {
        test_Gas_InstallHookModule();
        uint256 initialGas = gasleft();
        bool isInstalled = BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(mockHook), "");
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for isModuleInstalled after installing Hook Module: ", gasUsed);
        assertTrue(isInstalled, "Hook Module should be installed");
    }

    function test_Gas_InstallFallbackHandler_CheckIsInstalled() public {
        test_Gas_InstallFallbackHandler();
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));
        uint256 initialGas = gasleft();
        bool isInstalled = BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData);
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for isModuleInstalled after installing Fallback Handler: ", gasUsed);
        assertTrue(isInstalled, "Fallback Handler should be installed");
    }

    function test_Gas_UninstallValidatorModule_CheckIsUninstalled() public view {
        uint256 initialGas = gasleft();
        bool isInstalled = BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockValidator), "");
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for isModuleInstalled after uninstalling Validator Module: ", gasUsed);
        assertFalse(isInstalled, "Validator Module should be uninstalled");
    }

    function test_Gas_UninstallExecutorModule_CheckIsUninstalled() public view {
        uint256 initialGas = gasleft();
        bool isInstalled = BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockExecutor), "");
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for isModuleInstalled after uninstalling Executor Module: ", gasUsed);
        assertFalse(isInstalled, "Executor Module should be uninstalled");
    }

    function test_Gas_UninstallHookModule_CheckIsUninstalled() public {
        test_Gas_UninstallHookModule();
        uint256 initialGas = gasleft();
        bool isInstalled = BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(mockHook), "");
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for isModuleInstalled after uninstalling Hook Module: ", gasUsed);
        assertFalse(isInstalled, "Hook Module should be uninstalled");
    }

    function test_Gas_UninstallFallbackHandler_CheckIsUninstalled() public {
        test_Gas_UninstallFallbackHandler();
        bytes memory customData = abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR));
        uint256 initialGas = gasleft();
        bool isInstalled = BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), customData);
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for isModuleInstalled after uninstalling Fallback Handler: ", gasUsed);
        assertFalse(isInstalled, "Fallback Handler should be uninstalled");
    }

    function test_Gas_isModuleInstalled_InvalidModuleType() public view {
        uint256 initialGas = gasleft();
        bool isInstalled = BOB_ACCOUNT.isModuleInstalled(99, address(mockValidator), "");
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for isModuleInstalled with invalid Module Type: ", gasUsed);
        assertFalse(isInstalled, "Invalid Module Type should not be installed");
    }

    function test_Gas_isModuleInstalled_InvalidModuleAddress() public view {
        uint256 initialGas = gasleft();
        bool isInstalled = BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(0), "");
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for isModuleInstalled with invalid Module Address: ", gasUsed);
        assertFalse(isInstalled, "Invalid Module Address should not be installed");
    }

    function test_Gas_isModuleInstalled_GenericFallback_NoCustomData() public {
        test_Gas_InstallFallbackHandler();

        uint256 initialGas = gasleft();
        bool isInstalled = BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(mockHandler), "");
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for isModuleInstalled with Generic Fallback and no custom data: ", gasUsed);
        assertFalse(isInstalled, "Generic Fallback with no custom data should not be installed");
    }
}
