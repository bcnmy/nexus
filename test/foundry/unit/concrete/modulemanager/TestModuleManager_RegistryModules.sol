// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import "../../shared/TestModuleManagement_Base.t.sol";


contract TestModuleManager_RegistryModules is TestModuleManagement_Base {
    MockValidator public validatorModule;
    MockExecutor public executorModule;

    function setUp() public {
        super.setUpModuleManagement_Base(); // Set up base configuration

        mockRegistry = new MockRegistry();  // Instantiate the mock registry
        validatorModule = new MockValidator();  // Different validator module for specific tests
        executorModule = new MockExecutor();  // Executor module for type-specific testing

        // Attaching the modules with attestations
        mockRegistry.addAttestation(address(validatorModule), 1, address(this), true);  // Add self as attestor for validator
        mockRegistry.setThreshold(1, 1);  // Simple threshold of 1 for validator module type

        // This module will have a threshold not met, thus fail registry checks
        mockRegistry.addAttestation(address(executorModule), 2, address(this), true);  // Adding one attestor, but threshold needs two
        mockRegistry.setThreshold(2, 2);  // Threshold set to 2 for executor module type

        setRegistry(address(mockRegistry));  // Setting the registry via ENTRYPOINT.handleOps
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

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Expecting failure due to insufficient attestations
        bytes memory expectedRevertReason = abi.encodeWithSignature("Error(string)", "Not enough valid attestations.");
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function test_InvalidModuleInstallation_WrongType() public {
        MockExecutor wrongTypeModule = new MockExecutor();

        mockRegistry.addAttestation(address(wrongTypeModule), 1, address(this), true);  // Adding one attestor, but threshold needs two
        mockRegistry.addAttestation(address(wrongTypeModule), 1, address(0x123), true);  // Adding one attestor, but threshold needs two

        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector, 
            2,  // Expected to be type 2, but attested as type 1
            address(wrongTypeModule),
            ""
        );
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        
        bytes memory expectedRevertReason = abi.encodeWithSignature("Error(string)", "Module type mismatch.");
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(userOpHash, address(BOB_ACCOUNT), userOps[0].nonce, expectedRevertReason);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }
}
