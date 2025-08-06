// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {DeterministicDeployerLib} from "./utils/DeterministicDeployerLib.sol";
import { ResolverUID, IRegistryModuleManager } from "./utils/RegisterModule.s.sol";

contract DeployNexus is Script {

    uint256 deployed;
    uint256 total;

    address public constant REGISTRY_ADDRESS = 0x000000000069E2a187AEFFb852bF3cCdC95151B2;

    // NEXUS CONTRACTS DEPLOYMENT SALTS
    bytes32 constant NEXUS_SALT = 0x00000000000000000000000000000000000000003c718f28e3d21701ecb6f357; // => 0x000000001964d23C59962Fc7A912872EE8fB3b6A
    bytes32 constant NEXUSBOOTSTRAP_SALT = 0x00000000000000000000000000000000000000005c3a61e0798aee010bada5a5; // => 0x000000c4781Be3349F81d341027fd7A4EdFa4Dd2
    bytes32 constant NEXUS_ACCOUNT_FACTORY_SALT = 0x0000000000000000000000000000000000000000a1448768dca0f901627b559d; // => 0x0000000C8B6b3329cEa5d15C9d8C15F1f254ec3C

    function setUp() public {}

    function run(bool check) public {
        if (check) {
            checkNexusAddress();
        } else {
            deployNexus();
        }
    }   

    function checkNexusAddress() internal {
        bytes32 salt = NEXUS_SALT;
        bytes memory bytecode = vm.getCode("scripts/bash-deploy/artifacts/Nexus/Nexus.json");
        bytes memory args = abi.encode(address(0x0000000071727De22E5E9d8BAf0edAc6f37da032));
        address nexus = DeterministicDeployerLib.computeAddress(bytecode, args, salt);
        uint256 codeSize;

        assembly {
            codeSize := extcodesize(nexus)
        }
        checkDeployed(codeSize);
        console2.log("Nexus Addr: ", nexus, " || >> Code Size: ", codeSize);
        console2.logBytes(args);
        console2.logBytes32(keccak256(abi.encodePacked(bytecode, args)));

        salt = NEXUSBOOTSTRAP_SALT;
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/NexusBootstrap/NexusBootstrap.json");
        address bootstrap = DeterministicDeployerLib.computeAddress(bytecode, salt);
        assembly {
            codeSize := extcodesize(bootstrap)
        }
        checkDeployed(codeSize);
        console2.log("Nexus Bootstrap Addr: ", bootstrap, " || >> Code Size: ", codeSize);
        console2.logBytes32(keccak256(abi.encodePacked(bytecode)));

        salt = NEXUS_ACCOUNT_FACTORY_SALT;
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/NexusAccountFactory/NexusAccountFactory.json");
        args = abi.encode(
                         nexus, // implementation
                         address(0x129443cA2a9Dec2020808a2868b38dDA457eaCC7) // factory owner 
                        );
        address nexusAccountFactory = DeterministicDeployerLib.computeAddress(bytecode, args, salt);
        assembly {
            codeSize := extcodesize(nexusAccountFactory)
        }
        checkDeployed(codeSize);
        console2.log("Nexus Account Factory Addr: ", nexusAccountFactory, " || >> Code Size: ", codeSize);
        console2.logBytes(args);
        console2.logBytes32(keccak256(abi.encodePacked(bytecode, args)));
        console2.log("=====> On this chain we have", deployed, " contracts already deployed out of ", total);
    }


// #########################################################################################
// ################## DEPLOYMENT ##################
// #########################################################################################

    function deployNexus() internal {

        // ======== Nexus ========

        bytes32 salt = NEXUS_SALT;
        bytes memory bytecode = vm.getCode("scripts/bash-deploy/artifacts/Nexus/Nexus.json");
        bytes memory args = abi.encode(address(0x0000000071727De22E5E9d8BAf0edAc6f37da032));
        address nexus = DeterministicDeployerLib.computeAddress(bytecode, args, salt);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(nexus)
        }
        if (codeSize > 0) {
            console2.log("Nexus already deployed at: ", nexus, " skipping deployment");
        } else {
            nexus = DeterministicDeployerLib.broadcastDeploy(bytecode, args, salt);
            console2.log("Nexus deployed at: ", nexus);
        }


        // ======== NexusBootstrap ========

        salt = NEXUSBOOTSTRAP_SALT;
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/NexusBootstrap/NexusBootstrap.json");
        address bootstrap = DeterministicDeployerLib.computeAddress(bytecode, salt);
        assembly {
            codeSize := extcodesize(bootstrap)
        }
        if (codeSize > 0) {
            console2.log("Nexus Bootstrap already deployed at: ", bootstrap, " skipping deployment");
        } else {
            bootstrap = DeterministicDeployerLib.broadcastDeploy(bytecode, salt);
            console2.log("Nexus Bootstrap deployed at: ", bootstrap);
        }


        // ======== NexusAccountFactory ========

        salt = NEXUS_ACCOUNT_FACTORY_SALT;
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/NexusAccountFactory/NexusAccountFactory.json");
        args = abi.encode(
                         nexus, // implementation
                         address(0x129443cA2a9Dec2020808a2868b38dDA457eaCC7) // factory owner 
                        );
        address nexusAccountFactory = DeterministicDeployerLib.computeAddress(bytecode, args, salt);
        assembly {
            codeSize := extcodesize(nexusAccountFactory)
        }
        if (codeSize > 0) {
            console2.log("Nexus Account Factory already deployed at: ", nexusAccountFactory, " skipping deployment");
        } else {
            nexusAccountFactory = DeterministicDeployerLib.broadcastDeploy(bytecode, args, salt);
            console2.log("Nexus Account Factory deployed at: ", nexusAccountFactory);
        }
    }

    function checkDeployed(uint256 codeSize) internal {
        if (codeSize > 0) {
            deployed++;
        }
        total++;
    }

    function _registerModule(address module) internal {
        bool registryDeployed;
        assembly {
            registryDeployed := iszero(iszero(extcodesize(REGISTRY_ADDRESS)))
        }
        if (registryDeployed) {
            vm.startBroadcast();
            IRegistryModuleManager registry = IRegistryModuleManager(REGISTRY_ADDRESS);
            try registry.registerModule(
                ResolverUID.wrap(0xdbca873b13c783c0c9c6ddfc4280e505580bf6cc3dac83f8a0f7b44acaafca4f),
                module,
                hex"",
                hex""
            ) {
                console2.log("Module registered on registry");
            } catch (bytes memory reason) {
                console2.log("Module registration failed");
                console2.logBytes(reason);
            }
            vm.stopBroadcast();
        } else {
            console2.log("Registry not deployed, skipping Module registration => module not registered on registry");
        }
    }
}