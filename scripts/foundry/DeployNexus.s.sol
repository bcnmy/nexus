// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {DeterministicDeployerLib} from "./utils/DeterministicDeployerLib.sol";
import { ResolverUID, IRegistryModuleManager } from "./utils/RegisterModule.s.sol";
import { NexusAccountFactory } from "contracts/factory/NexusAccountFactory.sol";
import { NexusBootstrap } from "contracts/utils/NexusBootstrap.sol";
contract DeployNexus is Script {

    uint256 deployed;
    uint256 total;

    address public constant REGISTRY_ADDRESS = 0x000000000069E2a187AEFFb852bF3cCdC95151B2;
    address public constant EP_V07_ADDRESS = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
    address public constant eEeEeAddress = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    // NEXUS CONTRACTS DEPLOYMENT SALTS
    bytes32 constant NEXUS_SALT = 0x000000000000000000000000000000000000000063c625f7f03af60349ec78e4; // => 0x0000004c02A3FFb0E95C259661871b27e7D02e32;
    
    bytes32 constant NEXUSBOOTSTRAP_SALT = 0x0000000000000000000000000000000000000000f3a86c770fe78703ac6fea73; // => 0x000000B7502F5a0F821b7d4648d45bD28f470d9b
    
    bytes32 constant NEXUS_ACCOUNT_FACTORY_SALT = 0x00000000000000000000000000000000000000007b4b9662c0bee002c7f260d3;//  => 0x000000369502a78b26a219cfe21c36e910288EDD;

    address internal defaultValidator = address(0x00000002987de8E966e1202534f018B028384eaC); // MEE K1 Validator v1.0.5

    function setUp() public {}

    function run(bool check) public {
        if (check) {
            checkNexusAddress();
        } else {
            deployNexus();
        }
    }   

    function checkNexusAddress() internal {

        // ======== Nexus ========

        bytes32 salt = NEXUS_SALT;
        bytes memory bytecode = vm.getCode("scripts/bash-deploy/artifacts/Nexus/Nexus.json");
        bytes memory args = abi.encode(EP_V07_ADDRESS, defaultValidator, abi.encodePacked(eEeEeAddress));
        address nexus = DeterministicDeployerLib.computeAddress(bytecode, args, salt);
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(nexus)
        }
        checkDeployed(codeSize);
        console2.log("Nexus Addr: ", nexus, " || >> Code Size: ", codeSize);
        console2.logBytes(args);
        console2.logBytes32(keccak256(abi.encodePacked(bytecode, args)));

        // ======== NexusBootstrap ========

        salt = NEXUSBOOTSTRAP_SALT;
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/NexusBootstrap/NexusBootstrap.json");
        args = abi.encode(defaultValidator, abi.encodePacked(eEeEeAddress));
        address bootstrap = DeterministicDeployerLib.computeAddress(bytecode, args, salt);
        assembly {
            codeSize := extcodesize(bootstrap)
        }
        checkDeployed(codeSize);
        console2.log("Nexus Bootstrap Addr: ", bootstrap, " || >> Code Size: ", codeSize);
        console2.logBytes(args);
        console2.logBytes32(keccak256(abi.encodePacked(bytecode, args)));

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

        // ASSIGN DEFAULT VALIDATOR if needed to override the default one
        // defaultValidator = k1validator;

        bytes32 salt = NEXUS_SALT;
        bytes memory bytecode = vm.getCode("scripts/bash-deploy/artifacts/Nexus/Nexus.json");
        bytes memory args = abi.encode(EP_V07_ADDRESS, defaultValidator, abi.encodePacked(eEeEeAddress));
        address nexus = DeterministicDeployerLib.computeAddress(bytecode, args, salt);
        
        uint256 codeSize;
        assembly {
            codeSize := extcodesize(nexus)
        }
        if (codeSize > 0) {
            console2.log("Nexus already deployed at: ", nexus, " skipping deployment");
        } else {
            nexus = DeterministicDeployerLib.broadcastDeploy(bytecode, args, salt);
            console2.log("Nexus deployed at: %s. Default validator: %s", nexus, defaultValidator);
        }

        // ======== NexusBootstrap ========

        salt = NEXUSBOOTSTRAP_SALT;
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/NexusBootstrap/NexusBootstrap.json");
        args = abi.encode(defaultValidator, abi.encodePacked(eEeEeAddress));    
        address bootstrap = DeterministicDeployerLib.computeAddress(bytecode, args, salt);
        assembly {
            codeSize := extcodesize(bootstrap)
        }
        if (codeSize > 0) {
            console2.log("Nexus Bootstrap already deployed at: ", bootstrap, " skipping deployment");
        } else {
            bootstrap = DeterministicDeployerLib.broadcastDeploy(bytecode, args, salt);
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

        // ======== NexusProxy ========

        salt = 0x0000000000000000000000000000000000000000000000000000000000000001;
        bytes memory initData = abi.encode(
            bootstrap,
            abi.encodeWithSelector(
                NexusBootstrap.initNexusWithDefaultValidator.selector,
                abi.encodePacked(eEeEeAddress)
            ) 
        );
        vm.startBroadcast();
        address nexusProxy = NexusAccountFactory(nexusAccountFactory).createAccount(initData, salt);
        vm.stopBroadcast();
        console2.log("Nexus Proxy deployed at: ", nexusProxy);
    }

    function checkDeployed(uint256 codeSize) internal {
        if (codeSize > 0) {
            deployed++;
        }
        total++;
    }
}