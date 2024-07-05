// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import { MODE_MODULE_ENABLE } from "contracts/types/Constants.sol";

library LocalCallDataParserLib {
    function parseEnableModeData(bytes calldata packedData) 
        internal 
        pure 
        returns (
            uint256 moduleType,
            bytes calldata moduleInitData,
            bytes calldata enableModeSignature,
            bytes calldata userOpSignature
        ) 
    {
        uint256 p;
        assembly {
            p := packedData.offset
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

    function parseMultiTypeInitData(bytes calldata initData) 
        internal
        pure
        returns (
            uint256[] calldata types,
            bytes[] calldata initDatas
        )
    {
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
