// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

interface IERC1271Unsafe {
    /// @notice Verifies a signature against a hash, using the sender's address as a contextual check.
    ///         Unsafe version, should be used in cases when Account is sure that the signed object contains all
    ///         data to protect from replay attacks and thus 7739 is escessive.
    ///         One example of that is Module Enable Mode Signatures.
    /// @dev Used to confirm the validity of a signature against the specific conditions set by the sender.
    /// @param sender The address from which the operation was initiated, adding an additional layer of validation against the signature.
    /// @param hash The hash of the data signed.
    /// @param data The signature data to validate.
    /// @return magicValue A bytes4 value that corresponds to the ERC-1271 standard, indicating the validity of the signature.
    function isValidSignatureWithSenderUnsafe(address sender, bytes32 hash, bytes calldata data) external view returns (bytes4);
}
