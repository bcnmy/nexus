// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

interface IDomainSeparator {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

/// @title Base Contract for Account Execution Tests
/// @notice Provides shared setup and utility functions for account execution tests
abstract contract TestAccountExecution_Base is NexusTest_Base {
    ExecutionMode public singleMode;
    ExecutionMode public batchMode;
    ExecutionMode public unsupportedMode;

    Counter public counter;
    MockToken public token;

    /// @notice Sets up the base environment for account execution tests
    function setUpTestAccountExecution_Base() internal virtual {
        init(); // Initialize the testing environment

        singleMode = ModeLib.encodeSimpleSingle();
        batchMode = ModeLib.encodeSimpleBatch();
        // Example of an unsupported mode for demonstration purposes
        unsupportedMode = ModeLib.encode(CallType.wrap(0xee), EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00));

        counter = new Counter();
        token = new MockToken("Test Token", "TST");
        // Mint tokens to the owner `(this)` and transfer to other accounts

        // transfer tokens to BOB_ACCOUNT, ALICE_ACCOUNT, and CHARLIE_ACCOUNT
        uint256 amountToEach = 10_000 * 10 ** token.decimals();
        token.transfer(address(BOB_ACCOUNT), amountToEach);
        token.transfer(address(ALICE_ACCOUNT), amountToEach);
        token.transfer(address(CHARLIE_ACCOUNT), amountToEach);
    }

    function _hashTypedData(bytes32 structHash, address account) internal view virtual returns (bytes32 digest) {
        // We will use `digest` to store the domain separator to save a bit of gas.
        digest = IDomainSeparator(account).DOMAIN_SEPARATOR();
        
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the digest.
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, digest) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }
}
