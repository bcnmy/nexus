// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/Helpers.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import {MockValidator} from "../../../mocks/MockValidator.sol";

contract TestAccountFactory_Operations is SmartAccountTestLab {
    // Initialize the testing environment and deploy necessary contracts
    Vm.Wallet public user;
    function setUp() public {
        super.initializeTestingEnvironment();
        user = newWallet("user");
        setBalance(user.addr, 1 ether);
    }

    function test_DeployAccount_WithCreateAccount() public {
        // Prepare initialization data for the account
        bytes memory initData = abi.encodeWithSelector(SmartAccount.initialize.selector, address(VALIDATOR_MODULE), abi.encode(user.addr));
        // Deploy an account using the factory directly
        address payable expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, 0);
        vm.expectEmit(true, true, true, true);
            emit AccountCreated(
                expectedAddress,
                address(VALIDATOR_MODULE),
                initData
            );
        address payable deployedAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        // Validate that the account was deployed correctly
        assertEq(deployedAccountAddress, expectedAddress, "Deployed account address mismatch");
    }

        function test_DeployAccount_WithCreateAccount_FailsIfAccountAlreadyExists() public {
        // Prepare initialization data for the account
        bytes memory initData = abi.encodeWithSelector(SmartAccount.initialize.selector, address(VALIDATOR_MODULE), abi.encode(user.addr));
        address payable expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, 0);

        vm.expectEmit(true, true, true, true);
            emit AccountCreated(
                expectedAddress,
                address(VALIDATOR_MODULE),
                initData
            );
        address payable deployedAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        
        address payable deployedAccountAddress2 = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);

        assertEq(deployedAccountAddress, deployedAccountAddress2, "Deployed account address mismatch");
    }


    function test_DeployAccount_WithHandleOps() public {

        address payable accountAddress = calculateAccountAddress(user.addr);
        bytes memory initCode = prepareInitCode(user.addr);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = prepareUserOpWithInit(user, initCode, "");

        ENTRYPOINT.depositTo{ value: 1 ether }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(user.addr));
    }

    function test_DeployAccount_WithHandleOps_FailsIfAccountAlreadyExists() public {

        address payable accountAddress = calculateAccountAddress(user.addr);
        bytes memory initCode = prepareInitCode(user.addr);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = prepareUserOpWithInit(user, initCode, "");

        ENTRYPOINT.depositTo{ value: 1 ether }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(user.addr));

        vm.expectRevert(abi.encodeWithSelector(FailedOp.selector, 0, "AA10 sender already constructed"));

        ENTRYPOINT.handleOps(userOps, payable(user.addr));
    }

    function test_AccountReInitializationPrevented() public {
    // Deploy the account for the first time
    bytes memory initData = abi.encodeWithSelector(SmartAccount.initialize.selector, address(VALIDATOR_MODULE), abi.encode(user.addr));
    address payable firstAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
    
    // Attempt to re-initialize the same account

    bytes memory expectedRevertReason = abi.encodeWithSignature(
            "AlreadyInitialized(address)", address(firstAccountAddress)
        );
    vm.prank(user.addr); // Ensure msg.sender is the user for authorization if needed
    vm.expectRevert(LinkedList_AlreadyInitialized.selector); // Assuming your contract reverts with this error on re-initialization attempts
    
    IModularSmartAccount(firstAccountAddress).initialize(address(VALIDATOR_MODULE), initData);
}

    function test_CreateAccountWithDifferentIndexes() public {
        bytes memory initData = abi.encodeWithSelector(SmartAccount.initialize.selector, address(VALIDATOR_MODULE), abi.encode(user.addr));
        
        // Deploy accounts with different indexes
        address payable accountAddress1 = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        address payable accountAddress2 = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 1);
        
        // Validate that the deployed addresses are different
        assertTrue(accountAddress1 != accountAddress2, "Accounts with different indexes should have different addresses");
    }

    function test_DeployAccountWithZeroInitializationData() public {

        bytes memory initData = abi.encodeWithSelector(SmartAccount.initialize.selector, address(VALIDATOR_MODULE), abi.encode(address(0)));
        address payable expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, 0);
            vm.expectEmit(true, true, true, true);
            emit AccountCreated(
                expectedAddress,
                address(VALIDATOR_MODULE),
                initData
            );
        address accountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        assertEq(accountAddress, expectedAddress, "Deployed account address mismatch");
    }

    function test_DeployAccountWithInvalidValidatorModule() public {
        bytes memory initData = abi.encodeWithSelector(SmartAccount.initialize.selector, address(0), abi.encode(user.addr));
        address payable expectedAddress = FACTORY.getCounterFactualAddress(address(0), initData, 0);
        
        // Should revert if the validator module is invalid without data
        vm.expectRevert();
        FACTORY.createAccount(address(0), initData, 0);
    }

    function test_DeployAccountWithoutEnoughGas() public {
        bytes memory initData = abi.encodeWithSelector(SmartAccount.initialize.selector, address(VALIDATOR_MODULE), abi.encode(user.addr));

        vm.expectRevert();
        FACTORY.createAccount{gas: 1000}(address(VALIDATOR_MODULE), initData, 0); // Adjust the gas amount based on your contract's requirements
    }

}
