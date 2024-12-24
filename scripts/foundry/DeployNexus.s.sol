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
    bytes32 constant NEXUS_SALT = 0x0000000000000000000000000000000000000000f2bd6e8e0a8d8b01a83be4c5;
    bytes32 constant K1VALIDATOR_SALT = 0x000000000000000000000000000000000000000014fedeb9e1c61d030943b78e;
    bytes32 constant NEXUSBOOTSTRAP_SALT = 0x0000000000000000000000000000000000000000685bdf10d2a63f043e248cc0;
    bytes32 constant K1VALIDATORFACTORY_SALT = 0x0000000000000000000000000000000000000000d07e828a05cf8c02ef869155;
    bytes32 constant NEXUS_ACCOUNT_FACTORY_SALT = 0x0000000000000000000000000000000000000000a00deaddeb69f9031a251b40;

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

        salt = K1VALIDATOR_SALT;
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/K1Validator/K1Validator.json");
        address k1validator = DeterministicDeployerLib.computeAddress(bytecode, salt);
        assembly {
            codeSize := extcodesize(k1validator)
        }
        checkDeployed(codeSize);
        console2.log("Nexus K1 Validator Addr: ", k1validator, " || >> Code Size: ", codeSize);
        console2.logBytes32(keccak256(abi.encodePacked(bytecode)));

        salt = NEXUSBOOTSTRAP_SALT;
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/NexusBootstrap/NexusBootstrap.json");
        address bootstrap = DeterministicDeployerLib.computeAddress(bytecode, salt);
        assembly {
            codeSize := extcodesize(bootstrap)
        }
        checkDeployed(codeSize);
        console2.log("Nexus Bootstrap Addr: ", bootstrap, " || >> Code Size: ", codeSize);
        console2.logBytes32(keccak256(abi.encodePacked(bytecode)));

        salt = K1VALIDATORFACTORY_SALT;
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/K1ValidatorFactory/K1ValidatorFactory.json");
        args = abi.encode(
                         nexus, 
                         address(0x129443cA2a9Dec2020808a2868b38dDA457eaCC7), // factory owner
                         k1validator, 
                         bootstrap,
                         REGISTRY_ADDRESS // registry
                        );
        address k1ValidatorFactory = DeterministicDeployerLib.computeAddress(bytecode, args, salt);
        assembly {
            codeSize := extcodesize(k1ValidatorFactory)
        }
        checkDeployed(codeSize);
        console2.log("K1ValidatorFactory Addr: ", k1ValidatorFactory, " || >> Code Size: ", codeSize);
        console2.logBytes(args);
        console2.logBytes32(keccak256(abi.encodePacked(bytecode, args)));

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

        // ======== K1Validator ========

        salt = K1VALIDATOR_SALT;
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/K1Validator/K1Validator.json");
        address k1validator = DeterministicDeployerLib.computeAddress(bytecode, salt);
        assembly {
            codeSize := extcodesize(k1validator)
        }
        if (codeSize > 0) {
            console2.log("Nexus K1 Validator already deployed at: ", k1validator, " skipping deployment");
        } else {
            k1validator = DeterministicDeployerLib.broadcastDeploy(bytecode, salt);
            console2.log("Nexus K1 Validator deployed at: ", k1validator);
        }

        // Register K1Validator on registry
        _registerModule(k1validator);

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

        // ======== K1ValidatorFactory ========
        salt = K1VALIDATORFACTORY_SALT;
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/K1ValidatorFactory/K1ValidatorFactory.json");
        args = abi.encode(
                         nexus, 
                         address(0x129443cA2a9Dec2020808a2868b38dDA457eaCC7), // factory owner
                         k1validator, 
                         bootstrap, 
                         address(0x000000000069E2a187AEFFb852bF3cCdC95151B2) // registry
                        );
        address k1ValidatorFactory = DeterministicDeployerLib.computeAddress(bytecode, args, salt);
        assembly {
            codeSize := extcodesize(k1ValidatorFactory)
        }
        if (codeSize > 0) {
            console2.log("Nexus K1 Validator Factory already deployed at: ", k1ValidatorFactory, " skipping deployment");
        } else {
            k1ValidatorFactory = DeterministicDeployerLib.broadcastDeploy(bytecode, args, salt);
            console2.log("Nexus K1 Validator Factory deployed at: ", k1ValidatorFactory);
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