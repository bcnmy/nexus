// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import { Test } from "forge-std/Test.sol";
import "forge-std/console2.sol";
import { NexusSentinelListLib, SENTINEL, ZERO_ADDRESS, NICKS_SENTINEL, NICK_METHOD_FLAG_STORAGE_SLOT } from "contracts/lib/NexusSentinelList.sol";

contract NexusSentinelListLibTest is Test {

    using NexusSentinelListLib for NexusSentinelListLib.SentinelList;
    
    struct TestStorage {    
        NexusSentinelListLib.SentinelList nicksSentinelList;
        NexusSentinelListLib.SentinelList regularSentinelList;
    }

    bytes32 internal constant _STORAGE_LOCATION = 0x0bb70095b32b9671358306b0339b4c06e7cbd8cb82505941fba30d1eb5b82f00;

    function _getAccountStorage() internal pure returns (TestStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
    
    function setUp() public {
        assembly {
            sstore(NICK_METHOD_FLAG_STORAGE_SLOT, 0x01)
        }
        assertTrue(NexusSentinelListLib._isNicksMethodInit());
        _getAccountStorage().nicksSentinelList.init();
        assembly {
            sstore(NICK_METHOD_FLAG_STORAGE_SLOT, 0x00)
        }
        assertFalse(NexusSentinelListLib._isNicksMethodInit());
        _getAccountStorage().regularSentinelList.init();
        
    }

    function test_init() public {
        TestStorage storage $ = _getAccountStorage();
        assertTrue($.nicksSentinelList.alreadyInitialized());
        assertTrue(NexusSentinelListLib._isNicksMethodNexus($.nicksSentinelList));
        assertTrue($.regularSentinelList.alreadyInitialized());
        assertFalse(NexusSentinelListLib._isNicksMethodNexus($.regularSentinelList));
    }

    function _assert_push(address newEntry) public {
        TestStorage storage $ = _getAccountStorage();
        $.nicksSentinelList.push(newEntry);
        assertTrue($.nicksSentinelList._isNicksMethodNexus());
        assertTrue($.nicksSentinelList.contains(newEntry));
        $.regularSentinelList.push(newEntry);
        assertFalse($.regularSentinelList._isNicksMethodNexus());
        assertTrue($.regularSentinelList.contains(newEntry));
    }

    function test_push() public {
        address newEntry = address(0xA11cea11CEA11CEA11cEa11CeA11ceA11CEA11Ce);
        _assert_push(newEntry);
    }

    function _assert_pop(address prevEntry, address popEntry) public {
        TestStorage storage $ = _getAccountStorage();
        // === nicksSentinelList ===
        $.nicksSentinelList.pop(prevEntry, popEntry);
        assertTrue($.nicksSentinelList._isNicksMethodNexus());
        assertFalse($.nicksSentinelList.contains(popEntry));
        if (prevEntry != SENTINEL) {
            assertTrue($.nicksSentinelList.contains(prevEntry));
        }
        assertTrue($.nicksSentinelList.alreadyInitialized());
        // === regularSentinelList ===
        $.regularSentinelList.pop(prevEntry, popEntry);
        assertFalse($.regularSentinelList._isNicksMethodNexus());
        assertFalse($.regularSentinelList.contains(popEntry));
        if (prevEntry != SENTINEL) {
            assertTrue($.regularSentinelList.contains(prevEntry));
        }
        assertTrue($.regularSentinelList.alreadyInitialized());
    }

    function test_pop() public {
        address alice = address(0xA11cea11CEA11CEA11cEa11CeA11ceA11CEA11Ce);
        address bob = address(0xB0B0b0B0B0B0B0b0B0B0B0b0b0b0b0B0b0b0B0B0);
        _assert_push(alice);
        _assert_push(bob);
        
        _assert_pop(bob, alice); // pop alice
        _assert_pop(SENTINEL, bob); // pop bob
    }

    function test_popAll() public {
        address alice = address(0xA11cea11CEA11CEA11cEa11CeA11ceA11CEA11Ce);
        address bob = address(0xB0B0b0B0B0B0B0b0B0B0B0b0b0b0b0B0b0b0B0B0);
        address charlie = address(0xC0C0c0c0C0C0c0c0c0C0c0C0C0C0C0C0C0C0c0c0);
        address dan = address(0xD0D0d0d0d0D0D0d0D0D0D0D0d0D0d0d0d0d0D0D0);
        _assert_push(alice);
        _assert_push(bob);
        _assert_push(charlie);
        _assert_push(dan);
        TestStorage storage $ = _getAccountStorage();
        $.nicksSentinelList.popAll();
        assertTrue($.nicksSentinelList._isNicksMethodNexus());
        assertFalse($.nicksSentinelList.alreadyInitialized()); // popAll de-inits the list
        assertFalse($.nicksSentinelList.contains(alice));
        assertFalse($.nicksSentinelList.contains(bob));
        assertFalse($.nicksSentinelList.contains(charlie));
        assertFalse($.nicksSentinelList.contains(dan));
        bool s_flag;
        assembly {
            s_flag := sload(NICK_METHOD_FLAG_STORAGE_SLOT)
        }
        assertTrue(s_flag); // expect popAll to set the flag to true in storage
        assembly {
            sstore(NICK_METHOD_FLAG_STORAGE_SLOT, 0x00)
        }
        $.regularSentinelList.popAll();
        assertFalse($.regularSentinelList._isNicksMethodNexus());
        assertFalse($.regularSentinelList.alreadyInitialized()); // popAll de-inits the list
        assertFalse($.regularSentinelList.contains(alice));
        assertFalse($.regularSentinelList.contains(bob));
        assertFalse($.regularSentinelList.contains(charlie));
        assertFalse($.regularSentinelList.contains(dan));
    }
        

        
    
    
}