// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/TestHelper.t.sol";
import "../../../utils/NexusTest_Base.t.sol";
import { MockValidator } from "../../../../../contracts/mocks/MockValidator.sol";

/// @title TestAccountFactory_Deployments
/// @dev Tests for deploying accounts using the AccountFactory and various methods.
contract TestAccountFactory_Deployments is NexusTest_Base {
    Vm.Wallet public user;
    bytes initData;

    /// @notice Sets up the testing environment.
    function setUp() public {
        super.setupTestEnvironment();
        user = newWallet("user");
        vm.deal(user.addr, 1 ether);
        initData = abi.encodePacked(user.addr);
    }

    /// @notice Tests deploying an account using the factory directly.
    function test_DeployAccount_CreateAccount() public {
        // Prepare bootstrap configuration for validators
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        // Create initcode and salt to be sent to Factory
        bytes memory _initData =
            BOOTSTRAPPER._getInitNexusScopedCalldata(validators, hook);

        address payable expectedAddress = FACTORY.computeAccountAddress(_initData, salt);

        vm.expectEmit(true, true, true, true);
        emit AccountCreated(expectedAddress, _initData, salt);   

        bytes memory factoryData = abi.encodeWithSelector(FACTORY.createAccount.selector, _initData, salt);    

        uint256 gasBefore = gasleft();
        address payable deployedAccountAddress = META_FACTORY.deployWithFactory(address(FACTORY), factoryData);
        console2.logUint(gasBefore - gasleft());
        console2.log("Gas used to deploy account using meta factory + generic factory printed above");
        // Validate that the account was deployed correctly
        assertEq(deployedAccountAddress, expectedAddress, "Deployed account address mismatch");
    }

    function test_DeployAccount_WithCreateAccount_ReturnsSameAddressWithSameArgs() public {
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        // Create initcode and salt to be sent to Factory
        bytes memory _initData =
            BOOTSTRAPPER._getInitNexusScopedCalldata(validators, hook);

        address payable expectedAddress = FACTORY.computeAccountAddress(_initData, salt);

        vm.expectEmit(true, true, true, true);
        emit AccountCreated(expectedAddress, _initData, salt);   
        
        bytes memory factoryData = abi.encodeWithSelector(FACTORY.createAccount.selector, _initData, salt);    

        address payable deployedAccountAddress = META_FACTORY.deployWithFactory(address(FACTORY), factoryData);

        address payable deployedAccountAddress2 = META_FACTORY.deployWithFactory(address(FACTORY), factoryData);
        assertEq(deployedAccountAddress, deployedAccountAddress2, "Deployed account address mismatch");
    }

    /// @notice Tests deploying an account using handleOps method.
    function test_DeployAccountUsingHandleOps_Success() public {
        address payable accountAddress = calculateAccountAddress(user.addr, address(VALIDATOR_MODULE));
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithInitAndCalldata(user, initCode, "", address(VALIDATOR_MODULE));
        ENTRYPOINT.depositTo{ value: 1 ether }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(user.addr));
        assertEq(IAccountConfig(accountAddress).accountId(), "biconomy.nexus.0.0.1", "Not deployed properly");
    }

    /// @notice Tests that deploying an account fails if it already exists.
    function test_RevertIf_HandleOpsDeployAccountExists() public {
        address payable accountAddress = calculateAccountAddress(user.addr, address(VALIDATOR_MODULE));
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithInitAndCalldata(user, initCode, "", address(VALIDATOR_MODULE));
        ENTRYPOINT.depositTo{ value: 1 ether }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(user.addr));
        vm.expectRevert(abi.encodeWithSelector(FailedOp.selector, 0, "AA10 sender already constructed"));
        ENTRYPOINT.handleOps(userOps, payable(user.addr));
    }

    function test_DeployAccount_DeployedAccountIsInitializedAndCannotBeReInitialized() public {
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        // Create initcode and salt to be sent to Factory
        bytes memory _initData =
            BOOTSTRAPPER._getInitNexusScopedCalldata(validators, hook);

        bytes memory factoryData = abi.encodeWithSelector(FACTORY.createAccount.selector, _initData, salt);

        uint256 gasBefore = gasleft();
        address payable firstAccountAddress = FACTORY.createAccount(_initData, salt);
        console2.logUint(gasBefore - gasleft());
        console2.log("Gas used to deploy account directly using generic factory printed above");

        vm.prank(user.addr); // Even owner can not reinit
        vm.expectRevert(LinkedList_AlreadyInitialized.selector);
        INexus(firstAccountAddress).initializeAccount(_initData);
    }

    /// @notice Tests creating accounts with different indexes.
    function test_CreateAccountWithDifferentIndexes() public {
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        bytes memory _initData =
            BOOTSTRAPPER._getInitNexusScopedCalldata(validators, hook);

        bytes memory factoryData1 = abi.encodeWithSelector(FACTORY.createAccount.selector, _initData, salt);
        bytes memory factoryData2 = abi.encodeWithSelector(FACTORY.createAccount.selector, _initData, keccak256("1"));


        address payable accountAddress1 = META_FACTORY.deployWithFactory(address(FACTORY), factoryData1);
        address payable accountAddress2 = META_FACTORY.deployWithFactory(address(FACTORY), factoryData2);
        // Validate that the deployed addresses are different
        assertTrue(
            accountAddress1 != accountAddress2, "Accounts with different indexes should have different addresses"
        );
    }

    function test_DeployAccountWithInvalidValidatorModule() public {
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        bytes memory _initData =
            BOOTSTRAPPER._getInitNexusScopedCalldata(validators, hook);

        address payable expectedAddress = FACTORY.computeAccountAddress(_initData, salt);
        // Should revert if the validator module is invalid
        BootstrapConfig[] memory validatorsInvalid = makeBootstrapConfig(address(0), initData);
        bytes memory _initDataInvalidModule =
            BOOTSTRAPPER._getInitNexusScopedCalldata(validatorsInvalid, hook);

        vm.expectRevert();
        address payable accountAddress = FACTORY.createAccount(_initDataInvalidModule, salt);
                assertTrue(
            expectedAddress != accountAddress, "Account address should be the same"
        );
    }

    function test_DeployAccountWithoutEnoughGas() public {
        BootstrapConfig[] memory validators = makeBootstrapConfig(address(VALIDATOR_MODULE), initData);
        BootstrapConfig memory hook = _makeBootstrapConfig(address(0), "");
        bytes memory saDeploymentIndex = "0";
        bytes32 salt = keccak256(saDeploymentIndex);

        bytes memory _initData =
            BOOTSTRAPPER._getInitNexusScopedCalldata(validators, hook);
        vm.expectRevert();
        // Adjust the gas amount based on your contract's requirements
        FACTORY.createAccount{ gas: 1000 }(_initData, salt);
    }
}
