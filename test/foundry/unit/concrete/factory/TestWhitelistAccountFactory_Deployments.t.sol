// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/NexusTest_Base.t.sol";
import "../../../../../contracts/factory/ModuleWhitelistFactory.sol";

/// @title TestAccountFactory_Deployments
/// @notice Tests for deploying accounts using the AccountFactory and various methods.
contract TestAccountFactory_Deployments is NexusTest_Base {
    Vm.Wallet public user;
    bytes initData;
    ModuleWhitelistFactory public whitelistFactory;
    bytes4 public constant GENERIC_FALLBACK_SELECTOR = 0xcb5baf0f;

    /// @notice Sets up the testing environment.
    function setUp() public {
        super.setupTestEnvironment();
        user = newWallet("user");
        vm.deal(user.addr, 1 ether);
        initData = abi.encodePacked(user.addr);
        whitelistFactory = new ModuleWhitelistFactory(address(FACTORY_OWNER.addr), address(ACCOUNT_IMPLEMENTATION));
        vm.startPrank(FACTORY_OWNER.addr);
        whitelistFactory.addModuleToWhitelist(address(VALIDATOR_MODULE));
        whitelistFactory.addModuleToWhitelist(address(EXECUTOR_MODULE));
        whitelistFactory.addModuleToWhitelist(address(HANDLER_MODULE));
        whitelistFactory.addModuleToWhitelist(address(HOOK_MODULE));
        vm.stopPrank();
    }

    /// @notice Tests deploying an account using the factory directly.
    function test_DeployAccount_WhitelistFactory_CreateAccount() public {
        // Prepare bootstrap configuration for validators
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig[] memory executors = makeBootstrapConfig(address(EXECUTOR_MODULE), "");
        BootstrapConfig memory hook = _makeBootstrapConfig(address(HOOK_MODULE), "");
        BootstrapConfig[] memory fallbacks = makeBootstrapConfig(address(HANDLER_MODULE), abi.encode(bytes4(GENERIC_FALLBACK_SELECTOR)));
        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        // Create initcode and salt to be sent to Factory
        bytes memory _initData = BOOTSTRAPPER.getInitNexusCalldata(validators, executors, hook, fallbacks);

        address payable expectedAddress = whitelistFactory.computeAccountAddress(_initData, salt);

        bytes memory factoryData = abi.encodeWithSelector(whitelistFactory.createAccount.selector, _initData, salt);

        uint256 gasBefore = gasleft();
        address payable deployedAccountAddress = whitelistFactory.createAccount(_initData, salt);
        console2.logUint(gasBefore - gasleft());
        console2.log("Gas used to deploy account using module whitelist factory printed above");

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
}
