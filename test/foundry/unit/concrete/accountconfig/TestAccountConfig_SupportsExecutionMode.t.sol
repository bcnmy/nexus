// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/BicoTestBase.t.sol";

contract TestAccountConfig_SupportsExecutionMode is Test, BicoTestBase {
    AccountConfig accountConfig;

    function setUp() public {
        init();
        accountConfig = SmartAccount(deploySmartAccount(BOB));
    }

    function test_SupportsBatchExecutionMode() public {
        ModeCode mode = ModeLib.encodeSimpleBatch();
        assertTrue(accountConfig.supportsExecutionMode(mode), "AccountConfig should support batch execution mode.");
    }

    function test_SupportsSingleExecutionMode() public {
        ModeCode mode = ModeLib.encodeSimpleSingle();
        assertTrue(accountConfig.supportsExecutionMode(mode), "AccountConfig should support single execution mode.");
    }

    // Optionally test for unsupported execution modes if any
    // For example, if delegate calls are not supported
    function test_UnsupportedExecutionMode() public {
        // Assuming delegate calls are not supported, and using an arbitrary ModeCode for demonstration
        ModeCode mode = ModeLib.encode(
            CALLTYPE_SINGLE, ExecType.wrap(0x10), ModeSelector.wrap(0x00000000), ModePayload.wrap(bytes22(0x00))
        );
        assertFalse(accountConfig.supportsExecutionMode(mode), "AccountConfig should not support this execution mode.");
    }
}
