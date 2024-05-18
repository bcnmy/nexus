// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/TestHelper.t.sol";
import "../../../utils/NexusTest_Base.t.sol";
import { MockValidator } from "../../../../../contracts/mocks/MockValidator.sol";

contract TestAccountFactory_Operations is NexusTest_Base {
    // Initialize the testing environment and deploy necessary contracts
    Vm.Wallet public user;
    bytes initData;

    function setUp() public {
        super.setupTestEnvironment();
        user = newWallet("user");
        vm.deal(user.addr, 1 ether);
        initData = abi.encodePacked(user.addr);
    }

    function test_DeployAccount_WithCreateAccount() public {
        // Deploy an account using the factory directly
        address payable expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, 0);
        vm.expectEmit(true, true, true, true);
        emit AccountCreated(expectedAddress, address(VALIDATOR_MODULE), initData);
        address payable deployedAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        // Validate that the account was deployed correctly
        assertEq(deployedAccountAddress, expectedAddress, "Deployed account address mismatch");
    }

    function test_DeployAccount_WithCreateAccount_ReturnsSameAddressWithSameArgs() public {
        address payable expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, 0);

        vm.expectEmit(true, true, true, true);
        emit AccountCreated(expectedAddress, address(VALIDATOR_MODULE), initData);
        address payable deployedAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);

        address payable deployedAccountAddress2 = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        assertEq(deployedAccountAddress, deployedAccountAddress2, "Deployed account address mismatch");
    }

    function test_DeployAccount_WithHandleOps() public {
        address payable accountAddress = calculateAccountAddress(user.addr, address(VALIDATOR_MODULE));
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithInitAndCalldata(user, initCode, "", address(VALIDATOR_MODULE));

        ENTRYPOINT.depositTo{ value: 1 ether }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(user.addr));
        assertEq(IAccountConfig(accountAddress).accountId(), "biconomy.nexus.0.0.1", "Not deployed properly");
    }

    function test_DeployAccount_WithHandleOps_FailsIfAccountAlreadyExists() public {
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
        address payable firstAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        vm.prank(user.addr); // Even owner can not reinit
        vm.expectRevert(LinkedList_AlreadyInitialized.selector);
        INexus(firstAccountAddress).initialize(address(VALIDATOR_MODULE), initData);
    }

    function test_CreateAccountWithDifferentIndexes() public {
        uint256 indexBase = 0;
        address payable accountAddress1 = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, indexBase);
        address payable accountAddress2 = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, indexBase + 1);
        // Validate that the deployed addresses are different
        assertTrue(accountAddress1 != accountAddress2, "Accounts with different indexes should have different addresses");
    }

    function test_DeployAccountWithInvalidValidatorModule() public {
        address payable expectedAddress = FACTORY.getCounterFactualAddress(address(0), initData, 0);
        // Should revert if the validator module is invalid
        vm.expectRevert();
        address payable accountAddress = FACTORY.createAccount(address(0), initData, 0);
        assertTrue(expectedAddress != accountAddress, "Account address should be the same");
    }

    function test_DeployAccountWithoutEnoughGas() public {
        vm.expectRevert();
        // Adjust the gas amount based on your contract's requirements
        FACTORY.createAccount{ gas: 1000 }(address(VALIDATOR_MODULE), initData, 0);
    }
}
