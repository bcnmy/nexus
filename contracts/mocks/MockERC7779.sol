// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { ERC7779Adaptor } from "../base/ERC7779Adaptor.sol";

contract MockERC7779 is ERC7779Adaptor {
    
    function addStorageBase(bytes32 storageBase) external {
        _addStorageBase(storageBase);
    }

    function _onRedelegation() internal override {
        // do nothing
    }

}
