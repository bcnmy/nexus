// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {DeterministicDeployerLib} from "./utils/DeterministicDeployerLib.sol";

contract DeployNexus is Script {

    uint256 deployed;
    uint256 total;

    function setUp() public {}

    function run(bool check) public {
        if (check) {
            checkNexusAddress();
        } else {
            deployNexus();
        }
    }   

    function checkNexusAddress() internal {
        bytes32 salt = vm.envBytes32("NEXUS_SALT");
        bytes memory bytecode = vm.getCode("scripts/bash-deploy/artifacts/Nexus/Nexus.json");
        bytes memory args = abi.encode(address(0x0000000071727De22E5E9d8BAf0edAc6f37da032));
        address nexus = DeterministicDeployerLib.computeAddress(bytecode, args, salt);
        uint256 codeSize;

        assembly {
            codeSize := extcodesize(nexus)
        }
        checkDeployed(codeSize);
        console2.log("Nexus Addr: ", nexus, " || >> Code Size: ", codeSize);

        salt = vm.envBytes32("K1VALIDATOR_SALT");
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/K1Validator/K1Validator.json");
        address k1validator = DeterministicDeployerLib.computeAddress(bytecode, salt);
        assembly {
            codeSize := extcodesize(k1validator)
        }
        checkDeployed(codeSize);
        console2.log("Nexus K1 Validator Addr: ", k1validator, " || >> Code Size: ", codeSize);

        salt = vm.envBytes32("NEXUSBOOTSTRAP_SALT");
        bytecode = vm.getCode("scripts/bash-deploy/artifacts/NexusBootstrap/NexusBootstrap.json");
        address bootstrap = DeterministicDeployerLib.computeAddress(bytecode, salt);
        assembly {
            codeSize := extcodesize(bootstrap)
        }
        checkDeployed(codeSize);
        console2.log("Nexus Bootstrap Addr: ", bootstrap, " || >> Code Size: ", codeSize);

        salt = vm.envBytes32("K1VALIDATORFACTORY_SALT");
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
        checkDeployed(codeSize);
        console2.log("K1ValidatorFactory Addr: ", k1ValidatorFactory, " || >> Code Size: ", codeSize);

        salt = vm.envBytes32("NEXUS_ACCOUNT_FACTORY_SALT");
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
        console2.logBytes32(keccak256(abi.encodePacked(bytecode, args)));
        console2.log("=====> On this chain we have", deployed, " contracts already deployed out of ", total);
    }


// #########################################################################################
// ################## DEPLOYMENT ##################
// #########################################################################################

    function deployNexus() internal {

        // ======== Nexus ========

        bytes32 salt = vm.envBytes32("NEXUS_SALT");
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

        salt = vm.envBytes32("K1VALIDATOR_SALT");
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

        // ======== NexusBootstrap ========

        salt = vm.envBytes32("NEXUSBOOTSTRAP_SALT");
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
        salt = vm.envBytes32("K1VALIDATORFACTORY_SALT");
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

        salt = vm.envBytes32("NEXUS_ACCOUNT_FACTORY_SALT");
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
}
