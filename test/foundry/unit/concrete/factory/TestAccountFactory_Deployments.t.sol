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

    /// @notice Tests deploying an account using the factory's createAccount method.
    function test_DeployAccount_WithCreateAccount() public {
        address payable expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, 0);
        vm.expectEmit(true, true, true, true);
        emit AccountCreated(expectedAddress, address(VALIDATOR_MODULE), initData);
        address payable deployedAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        assertEq(deployedAccountAddress, expectedAddress, "Deployed account address mismatch");
    }

    /// @notice Tests deploying an account with createAccount ensuring same address with same arguments.
    function test_DeployAccount_WithCreateAccount_ReturnsSameAddressWithSameArgs() public {
        address payable expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, 0);
        vm.expectEmit(true, true, true, true);
        emit AccountCreated(expectedAddress, address(VALIDATOR_MODULE), initData);
        address payable deployedAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        address payable deployedAccountAddress2 = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        assertEq(deployedAccountAddress, deployedAccountAddress2, "Deployed account address mismatch");
    }

    /// @notice Tests deploying an account using handleOps method.
    function test_DeployAccount_WithHandleOps() public {
        address payable accountAddress = calculateAccountAddress(user.addr, address(VALIDATOR_MODULE));
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithInitAndCalldata(user, initCode, "", address(VALIDATOR_MODULE));
        ENTRYPOINT.depositTo{ value: 1 ether }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(user.addr));
        assertEq(IAccountConfig(accountAddress).accountId(), "biconomy.nexus.0.0.1", "Not deployed properly");
    }

    /// @notice Tests that deploying an account fails if it already exists.
    function test_RevertIf_DeployAccount_WithHandleOps_AccountAlreadyExists() public {
        address payable accountAddress = calculateAccountAddress(user.addr, address(VALIDATOR_MODULE));
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithInitAndCalldata(user, initCode, "", address(VALIDATOR_MODULE));
        ENTRYPOINT.depositTo{ value: 1 ether }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(user.addr));
        vm.expectRevert(abi.encodeWithSelector(FailedOp.selector, 0, "AA10 sender already constructed"));
        ENTRYPOINT.handleOps(userOps, payable(user.addr));
    }

    /// @notice Tests that a deployed account is initialized and cannot be reinitialized.
    function test_RevertIf_DeployAccount_InitializedAndCannotBeReinitialized() public {
        address payable firstAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        vm.prank(user.addr);
        vm.expectRevert(LinkedList_AlreadyInitialized.selector);
        INexus(firstAccountAddress).initialize(address(VALIDATOR_MODULE), initData);
    }

    /// @notice Tests creating accounts with different indexes.
    function test_CreateAccountWithDifferentIndexes() public {
        uint256 indexBase = 0;
        address payable accountAddress1 = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, indexBase);
        address payable accountAddress2 = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, indexBase + 1);
        assertTrue(accountAddress1 != accountAddress2, "Accounts with different indexes should have different addresses");
    }

    /// @notice Tests that deploying an account with an invalid validator module reverts.
    function test_RevertIf_DeployAccountWithInvalidValidatorModule() public {
        address payable expectedAddress = FACTORY.getCounterFactualAddress(address(0), initData, 0);
        vm.expectRevert();
        address payable accountAddress = FACTORY.createAccount(address(0), initData, 0);
        assertTrue(expectedAddress != accountAddress, "Account address should be the same");
    }

    /// @notice Tests that deploying an account without enough gas reverts.
    function test_RevertIf_DeployAccountWithoutEnoughGas() public {
        vm.expectRevert();
        FACTORY.createAccount{ gas: 1000 }(address(VALIDATOR_MODULE), initData, 0);
    }
}
