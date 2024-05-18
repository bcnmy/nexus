// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";

contract TestAccountConfig_SupportsExecutionMode is Test, NexusTest_Base {
    Nexus public accountConfig;

    function setUp() public {
        init();
        accountConfig = Nexus(BOB_ACCOUNT);
    }

    function test_SupportsBatchExecutionMode() public {
        ExecutionMode mode = ModeLib.encodeSimpleBatch();
        assertTrue(accountConfig.supportsExecutionMode(mode), "AccountConfig should support batch execution mode.");
    }

    function test_SupportsSingleExecutionMode() public {
        ExecutionMode mode = ModeLib.encodeSimpleSingle();
        assertTrue(accountConfig.supportsExecutionMode(mode), "AccountConfig should support single execution mode.");
    }

    // Optionally test for unsupported execution modes if any
    // For example, if delegate calls are not supported
    function test_UnsupportedExecutionMode() public {
        // Delegate calls are not supported, and using an arbitrary ExecutionMode for demonstration
        ExecutionMode unsupportedMode = ModeLib.encode(
            CALLTYPE_SINGLE,
            ExecType.wrap(0x10),
            ModeSelector.wrap(0x00000000),
            ModePayload.wrap(bytes22(0x00))
        );
        assertFalse(accountConfig.supportsExecutionMode(unsupportedMode), "AccountConfig should not support this execution mode.");
    }
}
