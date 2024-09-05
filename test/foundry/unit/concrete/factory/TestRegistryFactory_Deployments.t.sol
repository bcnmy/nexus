// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../utils/NexusTest_Base.t.sol";

/// @title TestRegistryFactory_Deployments
/// @notice Tests for deploying accounts using the RegistryFactory and various methods.
contract TestRegistryFactory_Deployments is NexusTest_Base {
    Vm.Wallet public user;
    bytes initData;
    RegistryFactory public registryFactory;
    bytes4 public constant GENERIC_FALLBACK_SELECTOR = 0xcb5baf0f;
    MockRegistry public registry;
    address[] public attesters;
    uint8 public threshold;

    /// @notice Sets up the testing environment.
    function setUp() public {
        init();
        user = newWallet("user");
        vm.deal(user.addr, 1 ether);
        initData = abi.encodePacked(user.addr);
        registryFactory = new RegistryFactory(address(ACCOUNT_IMPLEMENTATION), address(FACTORY_OWNER.addr), REGISTRY, ATTESTERS, THRESHOLD);
    }

    /// @notice Tests the constructor sets the implementation address correctly.
    function test_Constructor_SetsImplementation() public {
        address implementation = address(0x123);
        address[] memory attestersArray = new address[](1);
        attestersArray[0] = address(0x789);
        RegistryFactory factory = new RegistryFactory(implementation, address(this), registry, attestersArray, 1);
        assertEq(factory.ACCOUNT_IMPLEMENTATION(), implementation, "Implementation address mismatch");
    }

    /// @notice Tests that the constructor reverts if the owner address is zero.
    function test_Constructor_RevertIf_OwnerIsZero() public {
        address implementation = address(0x123);
        address[] memory attestersArray = new address[](1);
        attestersArray[0] = address(0x789);
        vm.expectRevert(ZeroAddressNotAllowed.selector);
        new RegistryFactory(implementation, address(0), registry, attestersArray, 1);
    }

    /// @notice Tests that the constructor reverts if the implementation address is zero.
    function test_Constructor_RevertIf_ImplementationIsZero() public {
        address[] memory attestersArray = new address[](1);
        attestersArray[0] = address(0x789);
        vm.expectRevert(ImplementationAddressCanNotBeZero.selector);
        new RegistryFactory(address(0), address(this), registry, attestersArray, 1);
    }

        /// @notice Tests that the constructor reverts if the threshold is greater than the length of the attesters array.
    function test_Constructor_RevertIf_ThresholdExceedsAttestersLength() public {
        address implementation = address(0x123);
        address[] memory attestersArray = new address[](1);
        attestersArray[0] = address(0x789);

        // Expect the constructor to revert because the threshold (2) is greater than the number of attesters (1)
        vm.expectRevert(abi.encodeWithSelector(InvalidThreshold.selector, 2, attestersArray.length));
        new RegistryFactory(implementation, address(this), registry, attestersArray, 2);
    }

    /// @notice Tests adding and removing attesters from the registry.
    function test_AddRemoveAttester() public {
        address attester = address(0x456);
        address attester2 = address(0x654);
        vm.startPrank(FACTORY_OWNER.addr);
        
        registryFactory.addAttester(attester);
        registryFactory.addAttester(attester2);
        assertTrue(registryFactory.attesters(0) == attester, "Attester should be added");
        assertTrue(registryFactory.attesters(1) == attester2, "Attester should be added");
        
        registryFactory.removeAttester(attester);
        assertFalse(registryFactory.attesters(0) == attester, "Attester should be removed");
        vm.stopPrank();
    }

    /// @notice Tests deploying an account using the registry factory directly.
    function test_DeployAccount_RegistryFactory_CreateAccount() public payable {
        // Prepare bootstrap configuration for validators
        BootstrapConfig[] memory validators = BootstrapLib.createArrayConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig[] memory executors = BootstrapLib.createArrayConfig(address(EXECUTOR_MODULE), "");
        BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(HOOK_MODULE), "");
        BootstrapConfig[] memory fallbacks = BootstrapLib.createArrayConfig(address(HANDLER_MODULE), abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR)));
        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        // Create initcode and salt to be sent to Factory
        bytes memory _initData = BOOTSTRAPPER.getInitNexusCalldata(validators, executors, hook, fallbacks, REGISTRY, ATTESTERS, THRESHOLD);

        address payable expectedAddress = registryFactory.computeAccountAddress(_initData, salt);

        address payable deployedAccountAddress = registryFactory.createAccount(_initData, salt);

        // Validate that the account was deployed correctly
        assertEq(deployedAccountAddress, expectedAddress, "Deployed account address mismatch");

        assertEq(
            Nexus(deployedAccountAddress).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), ""),
            true,
            "Validator should be installed"
        );
        assertEq(
            Nexus(deployedAccountAddress).isModuleInstalled(MODULE_TYPE_EXECUTOR, address(EXECUTOR_MODULE), ""),
            true,
            "Executor should be installed"
        );
        assertEq(Nexus(deployedAccountAddress).isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""), true, "Hook should be installed");
        assertEq(
            Nexus(deployedAccountAddress).isModuleInstalled(MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), abi.encode(GENERIC_FALLBACK_SELECTOR)),
            true,
            "Fallback should be installed for selector"
        );
    }

    /// @notice Tests that creating an account fails if a module is not whitelisted.
    function test_DeployAccount_FailsIfModuleNotWhitelisted() public payable {
        // Prepare bootstrap configuration with a non-whitelisted module
        address nonWhitelistedModule = address(0x789);
        BootstrapConfig[] memory validators = BootstrapLib.createArrayConfig(nonWhitelistedModule, initData);
        BootstrapConfig[] memory executors;
        BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(0), "");
        BootstrapConfig[] memory fallbacks;

        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        // Create initcode and salt to be sent to Factory
        bytes memory _initData = BOOTSTRAPPER.getInitNexusCalldata(validators, executors, hook, fallbacks, registry, attesters, threshold);

        // Expect the account creation to revert
        vm.expectRevert(abi.encodeWithSelector(NexusInitializationFailed.selector));
        registryFactory.createAccount{ value: 1 ether }(_initData, salt);
    }

    /// @notice Tests creating accounts with different indexes.
    function test_DeployAccount_DifferentIndexes() public payable {
        BootstrapConfig[] memory validators = BootstrapLib.createArrayConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig[] memory executors = BootstrapLib.createArrayConfig(address(EXECUTOR_MODULE), "");
        BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(HOOK_MODULE), "");
        BootstrapConfig[] memory fallbacks = BootstrapLib.createArrayConfig(address(HANDLER_MODULE), abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR)));
        bytes memory saDeploymentIndex0 = "0";
        bytes memory saDeploymentIndex1 = "1";
        bytes32 salt0 = keccak256(saDeploymentIndex0);
        bytes32 salt1 = keccak256(saDeploymentIndex1);

        bytes memory _initData = BOOTSTRAPPER.getInitNexusCalldata(validators, executors, hook, fallbacks, registry, attesters, threshold);

        address payable accountAddress0 = registryFactory.createAccount{ value: 1 ether }(_initData, salt0);
        address payable accountAddress1 = registryFactory.createAccount{ value: 1 ether }(_initData, salt1);

        // Validate that the deployed addresses are different
        assertTrue(accountAddress0 != accountAddress1, "Accounts with different indexes should have different addresses");
    }

    /// @notice Tests that creating an account fails if an executor module is not whitelisted.
    function test_DeployAccount_FailsIfExecutorNotWhitelisted() public payable {
        // Prepare bootstrap configuration with a non-whitelisted executor module
        address nonWhitelistedExecutor = address(0x789);
        BootstrapConfig[] memory validators = BootstrapLib.createArrayConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig[] memory executors = BootstrapLib.createArrayConfig(nonWhitelistedExecutor, "");
        BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(0), "");
        BootstrapConfig[] memory fallbacks;

        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        // Create initcode and salt to be sent to Factory
        bytes memory _initData = BOOTSTRAPPER.getInitNexusCalldata(validators, executors, hook, fallbacks, REGISTRY, ATTESTERS, THRESHOLD);

        // Expect the account creation to revert with ModuleNotWhitelisted error
        vm.expectRevert(abi.encodeWithSelector(NexusInitializationFailed.selector));
        registryFactory.createAccount{ value: 1 ether }(_initData, salt);
    }

    /// @notice Tests that creating an account fails if the threshold is zero.
    function test_DeployAccount_WithThresholdZero() public payable {
        // Set threshold to zero
        prank(FACTORY_OWNER.addr);
        registryFactory.setThreshold(0);

        // Prepare bootstrap configuration for validators
        BootstrapConfig[] memory validators = BootstrapLib.createArrayConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig[] memory executors = BootstrapLib.createArrayConfig(address(EXECUTOR_MODULE), "");
        BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(HOOK_MODULE), "");
        BootstrapConfig[] memory fallbacks = BootstrapLib.createArrayConfig(address(HANDLER_MODULE), abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR)));
        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        // Create initcode and salt to be sent to Factory
        bytes memory _initData = BOOTSTRAPPER.getInitNexusCalldata(validators, executors, hook, fallbacks, REGISTRY, attesters, 0);

        // Expect the account creation to revert due to zero threshold
        registryFactory.createAccount{ value: 1 ether }(_initData, salt);
    }

    /// @notice Tests that creating an account fails if there are no attesters.
    function test_DeployAccount_FailsIfNoAttesters() public payable {
        // Set attesters to an empty array
        address[] memory noAttesters;

        // Prepare bootstrap configuration for validators
        BootstrapConfig[] memory validators = BootstrapLib.createArrayConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig[] memory executors = BootstrapLib.createArrayConfig(address(EXECUTOR_MODULE), "");
        BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(HOOK_MODULE), "");
        BootstrapConfig[] memory fallbacks = BootstrapLib.createArrayConfig(address(HANDLER_MODULE), abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR)));
        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        // Create initcode and salt to be sent to Factory
        bytes memory _initData = BOOTSTRAPPER.getInitNexusCalldata(validators, executors, hook, fallbacks, REGISTRY, noAttesters, THRESHOLD);

        // Expect the account creation to revert due to no attesters
        registryFactory.createAccount{ value: 1 ether }(_initData, salt);
    }
}
