// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/console2.sol";

// Sentinel address
address constant SENTINEL = address(0x1);
bytes32 constant NICKS_SENTINEL = bytes32(0x0100000000000000000000000000000000000000000000000000000000000001);
// Zero address
address constant ZERO_ADDRESS = address(0x0);

// Nick's method flag storage slot
// keccak256(abi.encode(uint256(keccak256("nick.method.flag.Nexus")) - 1)) & ~bytes32(uint256(0xff));
bytes32 constant NICK_METHOD_FLAG_STORAGE_SLOT = 0x3fa30d51722ce05d6eb76e47d8dd946b070ad3c25ac37b9f70694605b18ab200;

/**
 * @title Fork of the Rhinestone/SentinelListLib
 * @dev Library for managing a linked list of addresses
 * @dev Has a flag for Nick's method Nexuses
 */
library NexusSentinelListLib {
    // Struct to hold the linked list
    struct SentinelList {
        // TODO: make it bytes32 => bytes32 instead of address => address
        mapping(address => address) entries;
    }

    error LinkedList_AlreadyInitialized();
    error LinkedList_InvalidPage();
    error LinkedList_InvalidEntry(address entry);
    error LinkedList_EntryAlreadyInList(address entry);

    /**
     * Initialize the linked list
     *
     * @param self The linked list
     */
    function init(SentinelList storage self) internal {
        if (alreadyInitialized(self)) revert LinkedList_AlreadyInitialized();
        if (_isNicksMethodInit()) {
            _writeToMapping(self, SENTINEL, NICKS_SENTINEL);
        } else {
            self.entries[SENTINEL] = SENTINEL;
        }
    }

    /**
     * Check if the linked list is already initialized
     *
     * @param self The linked list
     *
     * @return bool True if the linked list is already initialized
     */
    function alreadyInitialized(SentinelList storage self) internal view returns (bool) {
        return self.entries[SENTINEL] != ZERO_ADDRESS;
    }

    /**
     * Get the next entry in the linked list
     *
     * @param self The linked list
     * @param entry The current entry
     *
     * @return address The next entry
     */
    function getNext(SentinelList storage self, address entry) internal view returns (address) {
        if (entry == ZERO_ADDRESS) {
            revert LinkedList_InvalidEntry(entry);
        }
        return self.entries[entry];
    }

    /**
     * Push a new entry to the linked list
     *
     * @param self The linked list
     * @param newEntry The new entry
     */
    function push(SentinelList storage self, address newEntry) internal {
        if (newEntry == ZERO_ADDRESS || newEntry == SENTINEL) {
            revert LinkedList_InvalidEntry(newEntry);
        }
        if (self.entries[newEntry] != ZERO_ADDRESS) revert LinkedList_EntryAlreadyInList(newEntry);
        // use assembly to get self.entries[SENTINEL] as bytes32
        bytes32 sentinelValue = _readFromMapping(self, SENTINEL);
        self.entries[newEntry] = self.entries[SENTINEL];
        // if there is a nicks method flag at msb , use assembly to append it to new entry and store it
        if (_isNicksMSB(sentinelValue)) {
            _writeToMapping(self, SENTINEL, _appendNicksMSB(bytes32(uint256(uint160(newEntry)))));
        } else {
            self.entries[SENTINEL] = newEntry;
        }   
    }

    /**
     * Safe push a new entry to the linked list
     * @dev This ensures that the linked list is initialized and initializes it if it is not
     *
     * @param self The linked list
     * @param newEntry The new entry
     */
    function safePush(SentinelList storage self, address newEntry) internal {
        if (!alreadyInitialized({ self: self })) {
            init({ self: self });
        }
        push({ self: self, newEntry: newEntry });
    }

    /**
     * Pop an entry from the linked list
     *
     * @param self The linked list
     * @param prevEntry The entry before the entry to pop
     * @param popEntry The entry to pop
     */
    function pop(SentinelList storage self, address prevEntry, address popEntry) internal {
        if (popEntry == ZERO_ADDRESS || popEntry == SENTINEL) {
            revert LinkedList_InvalidEntry(prevEntry);
        }
        if (self.entries[prevEntry] != popEntry) revert LinkedList_InvalidEntry(popEntry);
        // if prevEntry is the sentinel and there is a nicks method flag at msb
        // use assembly to append it to the self.entries[popEntry]
        if (prevEntry == SENTINEL && _isNicksMSB(_readFromMapping(self, SENTINEL))) {
            _writeToMapping(self, SENTINEL, _appendNicksMSB(_readFromMapping(self, popEntry)));
        } else {
            self.entries[prevEntry] = self.entries[popEntry];
        }
        self.entries[popEntry] = ZERO_ADDRESS;
    }

    /**
     * Pop all entries from the linked list
     *
     * @param self The linked list
     */
    function popAll(SentinelList storage self) internal {
        // use assembly to get self.entries[SENTINEL] aas bytes32
        bytes32 nextBytes32 = _readFromMapping(self, SENTINEL);
        // if there is a nicks method flag at msb, use assembly to set it to storage 
        // for the next reinitialization
        if (_isNicksMSB(nextBytes32)) {
            assembly {
                sstore(NICK_METHOD_FLAG_STORAGE_SLOT, 0x01)
            }
        }
        address next;
        assembly {
            next := nextBytes32
        }
        while (next != ZERO_ADDRESS) {
            address current = next;
            next = self.entries[next];
            self.entries[current] = ZERO_ADDRESS;
        }
    }

    /**
     * Check if the linked list contains an entry
     *
     * @param self The linked list
     * @param entry The entry to check
     *
     * @return bool True if the linked list contains the entry
     */
    function contains(SentinelList storage self, address entry) internal view returns (bool) {
        return SENTINEL != entry && self.entries[entry] != ZERO_ADDRESS;
    }

    /**
     * Get all entries in the linked list
     *
     * @param self The linked list
     * @param start The start entry
     * @param pageSize The page size
     *
     * @return array All entries in the linked list
     * @return next The next entry
     */
    function getEntriesPaginated(
        SentinelList storage self,
        address start,
        uint256 pageSize
    )
        internal
        view
        returns (address[] memory array, address next)
    {
        if (start != SENTINEL && !contains(self, start)) revert LinkedList_InvalidEntry(start);
        if (pageSize == 0) revert LinkedList_InvalidPage();
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 entryCount = 0;
        next = self.entries[start];
        while (next != ZERO_ADDRESS && next != SENTINEL && entryCount < pageSize) {
            array[entryCount] = next;
            next = self.entries[next];
            entryCount++;
        }

        /**
         * Because of the argument validation, we can assume that the loop will always iterate over
         * the valid entry list values
         *       and the `next` variable will either be an enabled entry or a sentinel address
         * (signalling the end).
         *
         *       If we haven't reached the end inside the loop, we need to set the next pointer to
         * the last element of the entry array
         *       because the `next` variable (which is a entry by itself) acting as a pointer to the
         * start of the next page is neither
         *       incSENTINELrent page, nor will it be included in the next one if you pass it as a
         * start.
         */
        if (next != SENTINEL && entryCount > 0) {
            next = array[entryCount - 1];
        }
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        /// @solidity memory-safe-assembly
        assembly {
            mstore(array, entryCount)
        }
    }

    // To be exposed as external at the using contract
    function _isNicksMethodNexus(SentinelList storage self) internal view returns (bool res) {
        if (_isNicksMSB(_readFromMapping(self, SENTINEL))) {
            res = true; // return early if nicks method flag is at msb
        } else {
            assembly {
                res := sload(NICK_METHOD_FLAG_STORAGE_SLOT)
            }
        }
    }

    function _slot(SentinelList storage self, address key) private pure returns (bytes32 __slot) {
        bytes32 keyStored;
        assembly {
            mstore(0x00, key)
            mstore(0x20, self.slot)
            __slot := keccak256(0x00, 0x40)
            keyStored := mload(0x00)
        }
    }

    function _readFromMapping(SentinelList storage self, address key) internal view returns (bytes32 value) {
        bytes32 slot = _slot(self, key);
        assembly {
            value := sload(slot)
        }
    }

    function _writeToMapping(SentinelList storage self, address key, bytes32 value) internal {
        bytes32 slot = _slot(self, key);
        assembly {
            sstore(slot, value)
        }
    }

    function _isNicksMSB(bytes32 value) internal pure returns (bool) {
        return value & bytes32(0xff00000000000000000000000000000000000000000000000000000000000000) != 0;
    }

    function _appendNicksMSB(bytes32 value) internal pure returns (bytes32) {
        return value | bytes32(0x0100000000000000000000000000000000000000000000000000000000000000);
    }

    function _isNicksMethodInit() internal view returns (bool) {
        bool flag;
        assembly {
            flag := tload(NICK_METHOD_FLAG_STORAGE_SLOT)
        }
        // return early if flag is true in transient storage so
        // no extra sload is done
        if (flag) return true;
        // check if flag is true in persistent storage
        assembly {
            flag := sload(NICK_METHOD_FLAG_STORAGE_SLOT)
        }
        return flag;
    }
}
