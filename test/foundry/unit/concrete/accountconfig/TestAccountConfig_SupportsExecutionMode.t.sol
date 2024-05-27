// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";

/// @title Test suite for checking execution modes supported by AccountConfig
contract TestAccountConfig_SupportsExecutionMode is NexusTest_Base {
    Nexus public accountConfig;

    /// @notice Initialize the testing environment
    function setUp() public {
        init();
        accountConfig = Nexus(BOB_ACCOUNT);
    }

    /// @notice Tests if batch execution mode is supported
    function test_SupportsBatchExecutionMode_Success() public view {
        ExecutionMode mode = ModeLib.encodeSimpleBatch();
        assertTrue(accountConfig.supportsExecutionMode(mode), "AccountConfig should support batch execution mode.");
    }

    /// @notice Tests if single execution mode is supported
    function test_SupportsSingleExecutionMode_Success() public view {
        ExecutionMode mode = ModeLib.encodeSimpleSingle();
        assertTrue(accountConfig.supportsExecutionMode(mode), "AccountConfig should support single execution mode.");
    }

    /// @notice Tests an unsupported execution mode
    function test_RevertIf_UnsupportedExecutionMode() public view {
        ExecutionMode unsupportedMode = ModeLib.encode(
            CALLTYPE_SINGLE,
            ExecType.wrap(0x10),
            ModeSelector.wrap(0x00000000),
            ModePayload.wrap(bytes22(0x00))
        );
        assertFalse(accountConfig.supportsExecutionMode(unsupportedMode), "AccountConfig should not support this execution mode.");
    }
}
