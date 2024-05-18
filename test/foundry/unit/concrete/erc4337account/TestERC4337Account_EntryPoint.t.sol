// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";

contract TestERC4337Account_EntryPoint is Test, NexusTest_Base {
    function setUp() public {
        init();
    }

    function test_CorrectEntryPointAddress() public {
        assertEq(BOB_ACCOUNT.entryPoint(), address(ENTRYPOINT), "Should return the correct EntryPoint address");
        assertEq(ALICE_ACCOUNT.entryPoint(), address(ENTRYPOINT), "Should return the correct EntryPoint address");
        assertEq(CHARLIE_ACCOUNT.entryPoint(), address(ENTRYPOINT), "Should return the correct EntryPoint address");
    }
}
