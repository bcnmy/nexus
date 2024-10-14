// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0 <0.9.0;
pragma solidity >=0.8.0 <0.9.0;

import { Nexus } from "../../contracts/Nexus.sol";

import { BaseScript } from "./Base.s.sol";
import { K1ValidatorFactory } from "../../contracts/factory/K1ValidatorFactory.sol";
import { K1Validator } from "../../contracts/modules/validators/K1Validator.sol";
import { BootstrapLib } from "../../contracts/lib/BootstrapLib.sol";
import { NexusBootstrap } from "../../contracts/utils/NexusBootstrap.sol";
import { MockRegistry } from "../../contracts/mocks/MockRegistry.sol";
import { HelperConfig } from "./HelperConfig.s.sol";

contract Deploy is BaseScript {
    K1ValidatorFactory private k1ValidatorFactory;
    K1Validator private k1Validator;
    NexusBootstrap private bootstrapper;
    MockRegistry private registry;
    HelperConfig private helperConfig;

    function run() public broadcast returns (Nexus smartAccount) {
        helperConfig = new HelperConfig();
        require(address(helperConfig.ENTRYPOINT()) != address(0), "ENTRYPOINT is not set");
        smartAccount = new Nexus(address(helperConfig.ENTRYPOINT()));
        k1Validator = new K1Validator();
        bootstrapper = new NexusBootstrap();
        registry = new MockRegistry();
        k1ValidatorFactory = new K1ValidatorFactory(
            address(smartAccount),
            msg.sender,
            address(k1Validator),
            bootstrapper,
            registry
        );
    }
}
