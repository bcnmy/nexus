// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

/// @title Base Test Contract for Module Management
/// @notice Contains setup and shared functions for testing module management
abstract contract TestModuleManagement_Base is NexusTest_Base {
    MockValidator public mockValidator;
    MockExecutor public mockExecutor;
    MockHandler public mockHandler;
    MockHook public mockHook;
    MockMultiModule public mockMulti;

    address public constant INVALID_MODULE_ADDRESS = address(0);
    uint256 public constant INVALID_MODULE_TYPE = 999;

    bytes4 public constant GENERIC_FALLBACK_SELECTOR = 0xcb5baf0f;
    bytes4 public constant UNUSED_SELECTOR = 0xdeadbeef;

    /// @notice Sets up the base environment for module management tests
    function setUpModuleManagement_Base() internal {
        init(); // Initialize the testing environment

        mockValidator = new MockValidator();
        mockExecutor = new MockExecutor();
        mockHandler = new MockHandler();
        mockHook = new MockHook();
        mockMulti = new MockMultiModule();
    }

    /// @notice Installs a module on the given account
    /// @param callData The call data for the installation
    /// @param moduleTypeId The type ID of the module
    /// @param moduleAddress The address of the module
    /// @param execType The execution type for the operation
    function installModule(bytes memory callData, uint256 moduleTypeId, address moduleAddress, ExecType execType) internal {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, execType, execution, address(VALIDATOR_MODULE), 0);

        vm.expectEmit(true, true, true, true);
        emit ModuleInstalled(moduleTypeId, moduleAddress);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    /// @notice Uninstalls a module from the given account
    /// @param callData The call data for the uninstallation
    /// @param execType The execution type for the operation
    function uninstallModule(bytes memory callData, ExecType execType) internal {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, execType, execution, address(VALIDATOR_MODULE), 0);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }
}
