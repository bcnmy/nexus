// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import "../../shared/TestModuleManagement_Base.t.sol";


contract TestModuleManager_RegistryModules is TestModuleManagement_Base {
    MockValidator public validatorModule;
    MockExecutor public executorModule;

    function setUp() public {
        setUpModuleManagement_Base();

        mockRegistry = new MockRegistry();  // Instantiate the mock registry
        executorModule = new MockExecutor();  // Executor module for type-specific testing
        validatorModule = new MockValidator();  // Different validator module for specific tests

        // Attaching the modules with attestations
        mockRegistry.addAttestation(address(validatorModule), 1, address(this), true);  // Add self as attestor for validator
        mockRegistry.setThreshold(1, 1);  // Simple threshold of 1 for validator module type

        // This module will have a threshold not met, thus fail registry checks
        mockRegistry.addAttestation(address(executorModule), 2, address(this), true);  // Adding one attestor, but threshold needs two
        mockRegistry.setThreshold(2, 2);  // Threshold set to 2 for executor module type

        setRegistry(address(mockRegistry));  // Setting the registry via ENTRYPOINT.handleOps
    }

    function test_GetRegistry() public {
        IERC7484Registry registryAddress = ModuleManager(BOB_ACCOUNT).getModuleRegistry();
        assertEq(address(registryAddress), address(mockRegistry), "The registry address should match the one set.");
    }

    function test_ValidModuleInstallation() public {
                assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(validatorModule), ""),
            "Module should not be installed initially"
        );
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, 
            1,  // Module type for validator
            address(validatorModule),
            ""
        );

        installModule(callData, 1, address(validatorModule), EXECTYPE_DEFAULT);
        
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(validatorModule), ""),
            "Module should be installed"
        );
    }

    function test_InvalidModuleInstallation_ThresholdNotMet() public {
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, 
            2,  // Module type for executor, where threshold is not met
            address(executorModule),
            ""
        );

        expectRevertWithReason(callData, "Not enough valid attestations.");
    }

    function test_InvalidModuleInstallation_WrongType() public {
        MockExecutor wrongTypeModule = new MockExecutor();

        mockRegistry.addAttestation(address(wrongTypeModule), 1, address(this), true);  // Adding one attestor, but threshold needs two
        mockRegistry.addAttestation(address(wrongTypeModule), 1, address(0x123), true);  // Adding one attestor threshold should be met

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, 
            2,  // Expected to be type 2, but attested as type 1
            address(wrongTypeModule),
            ""
        );
        
        expectRevertWithReason(callData, "Module type mismatch.");

    }
}
