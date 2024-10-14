// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
pragma solidity >=0.8.0 <0.9.0;

import { EntryPoint } from "account-abstraction/core/EntryPoint.sol";
import { IEntryPoint } from "account-abstraction/interfaces/IEntryPoint.sol";

import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    IEntryPoint public ENTRYPOINT;
    address private  constant MAINNET_ENTRYPOINT_ADDRESS = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;

    constructor() {
        if (block.chainid == 31337) {
            setupAnvilConfig();
        } else {
            ENTRYPOINT = IEntryPoint(MAINNET_ENTRYPOINT_ADDRESS);
        }
    }

    function setupAnvilConfig() public {
        if(address(ENTRYPOINT) != address(0)){
            return;
        }
        ENTRYPOINT = new EntryPoint();
        vm.etch(address(MAINNET_ENTRYPOINT_ADDRESS), address(ENTRYPOINT).code);
        ENTRYPOINT = IEntryPoint(MAINNET_ENTRYPOINT_ADDRESS);
    }

}