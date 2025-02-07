// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

// keccak256(abi.encode(uint256(keccak256("initializable.transient.Nexus")) - 1)) & ~bytes32(uint256(0xff));
bytes32 constant INIT_SLOT = 0x90b772c2cb8a51aa7a8a65fc23543c6d022d5b3f8e2b92eed79fba7eef829300;

/// @title Initializable
/// @dev This library provides a way to set a transient flag on a contract to ensure that it is only initialized during the
/// constructor execution. This is useful to prevent a contract from being initialized multiple times.
library Initializable {
    /// @dev Thrown when an attempt to initialize an already initialized contract is made
    error NotInitializable();

    /// @dev Sets the initializable flag in the transient storage slot to true
    function setInitializable() internal {
        bytes32 slot = INIT_SLOT;
        assembly {
            tstore(slot, 0x01)
        }
    }

    /// @dev returns true if the initializable flag is set in the transient storage slot,
    ///      otherwise returns false
    function isInitializable() internal view returns (bool isInitializable) {
        bytes32 slot = INIT_SLOT;
        // Load the current value from the slot
        assembly {
            isInitializable := tload(slot)
        }
    }
}
