// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script, console2} from "forge-std/Script.sol";

type ResolverUID is bytes32;

interface IRegistryModuleManager {
    function registerModule(
        ResolverUID resolverUID,
        address moduleAddress,
        bytes calldata metadata,
        bytes calldata resolverContext
    ) external;
}

contract RegisterModule is Script {

    function setUp() public {}

    function run() public {
        IRegistryModuleManager registry = IRegistryModuleManager(0x000000000069E2a187AEFFb852bF3cCdC95151B2);
        registry.registerModule(
            ResolverUID.wrap(0xdbca873b13c783c0c9c6ddfc4280e505580bf6cc3dac83f8a0f7b44acaafca4f),
            address(0x0000002D6DB27c52E3C11c1Cf24072004AC75cBa),  // K1Validator
            hex"",
            hex""
        );    
    }
}
