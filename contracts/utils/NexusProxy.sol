// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { Proxy } from "@openzeppelin/contracts/proxy/Proxy.sol";
import { ERC1967Utils } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Utils.sol";
import { Initializable } from "../lib/Initializable.sol";

/// @title NexusProxy
/// @dev A proxy contract that uses the ERC1967 upgrade pattern and sets the initializable flag
///      in the constructor to prevent reinitialization
contract NexusProxy is Proxy {
    constructor(address implementation, bytes memory data) payable {
        Initializable.setInitializable();
        ERC1967Utils.upgradeToAndCall(implementation, data);
    }

    function _implementation() internal view virtual override returns (address) {
        return ERC1967Utils.getImplementation();
    }
}
