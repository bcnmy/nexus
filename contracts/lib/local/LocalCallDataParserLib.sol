// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

library LocalCallDataParserLib {
    /// @dev Parses the `userOp.signature` to extract the module type, module initialization data,
    ///      enable mode signature, and user operation signature. The `userOp.signature` must be
    ///      encoded in a specific way to be parsed correctly.
    /// @param packedData The packed signature data, typically coming from `userOp.signature`.
    /// @return module The address of the module.
    /// @return moduleType The type of module as a `uint256`.
    /// @return moduleInitData Initialization data specific to the module.
    /// @return enableModeSignature Signature used to enable the module mode.
    /// @return userOpSignature The remaining user operation signature data.
    function parseEnableModeData(
        bytes calldata packedData
    )
        internal
        pure
        returns (
            address module,
            uint256 moduleType,
            bytes calldata moduleInitData,
            bytes calldata enableModeSignature,
            bytes calldata userOpSignature
        )
    {
        uint256 p;
        assembly ("memory-safe") {
            p := packedData.offset
            module := shr(96, calldataload(p))

            p := add(p, 0x14)
            moduleType := calldataload(p)

            moduleInitData.length := shr(224, calldataload(add(p, 0x20)))
            moduleInitData.offset := add(p, 0x24)
            p := add(moduleInitData.offset, moduleInitData.length)

            enableModeSignature.length := shr(224, calldataload(p))
            enableModeSignature.offset := add(p, 0x04)
            p := sub(add(enableModeSignature.offset, enableModeSignature.length), packedData.offset)
        }
        userOpSignature = packedData[p:];
    }

    /// @dev Parses the data to obtain types and initdata's for Multi Type module install mode
    /// @param initData Multi Type module init data, abi.encoded
    function parseMultiTypeInitData(bytes calldata initData) internal pure returns (uint256[] calldata types, bytes[] calldata initDatas) {
        // equivalent of:
        // (types, initDatas) = abi.decode(initData,(uint[],bytes[]))
        assembly ("memory-safe") {
            let offset := initData.offset
            let baseOffset := offset
            let dataPointer := add(baseOffset, calldataload(offset))

            types.offset := add(dataPointer, 32)
            types.length := calldataload(dataPointer)
            offset := add(offset, 32)

            dataPointer := add(baseOffset, calldataload(offset))
            initDatas.offset := add(dataPointer, 32)
            initDatas.length := calldataload(dataPointer)
        }
    }
}
