// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import "../../../shared/TestModuleManagement_Base.t.sol";

/// @title TestModuleManager_SupportsModule
/// @notice Tests for module management, verifying support for various module types in BOB_ACCOUNT.
contract TestModuleManager_SupportsModule is TestModuleManagement_Base {
    /// @notice Sets up the base environment for the module management tests.
    function setUp() public {
        setUpModuleManagement_Base();
    }

    /// @notice Tests the successful support of the Validator module.
    function test_SupportsModuleValidator_Success() public view {
        assertTrue(BOB_ACCOUNT.supportsModule(MODULE_TYPE_VALIDATOR), "Validator module not supported");
    }

    /// @notice Tests the successful support of the Executor module.
    function test_SupportsModuleExecutor_Success() public view {
        assertTrue(BOB_ACCOUNT.supportsModule(MODULE_TYPE_EXECUTOR), "Executor module not supported");
    }

    /// @notice Tests the successful support of the Fallback module.
    function test_SupportsModuleFallback_Success() public view {
        assertTrue(BOB_ACCOUNT.supportsModule(MODULE_TYPE_FALLBACK), "Fallback module not supported");
    }

    /// @notice Tests the successful support of the Hook module.
    function test_SupportsModuleHook_Success() public view {
        assertTrue(BOB_ACCOUNT.supportsModule(MODULE_TYPE_HOOK), "Hook module not supported");
    }

    /// @notice Tests that an unsupported module type returns false.
    function test_SupportsModule_FailsForUnsupportedModule() public view {
        assertFalse(BOB_ACCOUNT.supportsModule(INVALID_MODULE_TYPE), "Invalid module type should not be supported");
    }

    /// @notice Tests that zero as a module type returns false.
    function test_SupportsModule_FailsForZeroModuleType() public view {
        assertFalse(BOB_ACCOUNT.supportsModule(0), "Zero module type should not be supported");
    }
}
