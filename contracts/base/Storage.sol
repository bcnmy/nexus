// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IStorage } from "../interfaces/base/IStorage.sol";

contract Storage is IStorage {
    /// @custom:storage-location erc7201:biconomy.storage.SmartAccount
    /// ERC-7201 namespaced via `keccak256(encode(uint256(keccak256("biconomy.storage.SmartAccount")) - 1)) & ~0xff`
    bytes32 private constant _STORAGE_LOCATION = 0x34e06d8d82e2a2cc69c6a8a18181d71c19765c764b52180b715db4be61b27a00;

    /**
     * @dev Utilizes ERC-7201's namespaced storage pattern for isolated storage access. This method computes
     * the storage slot based on a predetermined location, ensuring collision-resistant storage for contract states.
     * @custom:storage-location ERC-7201 formula applied to "biconomy.storage.SmartAccount", facilitating unique
     * namespace identification and storage segregation, as detailed in the specification.
     * @return $ The proxy to the `AccountStorage` struct, providing a reference to the namespaced storage slot.
     */
    function _getAccountStorage() internal pure returns (AccountStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
}
