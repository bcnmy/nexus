// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../utils/Imports.sol";

import { InvariantBaseTest } from "./base/InvariantBaseTest.t.sol";
import { ExecutionHandlerTest } from "./handlers/ExecutionHandlerTest.t.sol";
import { AccountCreationHandlerTest } from "./handlers/AccountCreationHandlerTest.t.sol";
import { ModuleManagementHandlerTest } from "./handlers/ModuleManagementHandlerTest.t.sol";
import { DepositManagementHandlerTest } from "./handlers/DepositManagementHandlerTest.t.sol";

// ActorManager is responsible for coordinating test actions across different actors using handlers.
contract ActorManagerInvariantTest is InvariantBaseTest {
    struct ActorHandlers {
        DepositManagementHandlerTest depositHandler;
        ModuleManagementHandlerTest moduleHandler;
        ExecutionHandlerTest executionHandler;
        AccountCreationHandlerTest accountCreationHandler;
    }

    ActorHandlers[] public actorHandlers;
    address public validationModule;
    uint256 public testModuleType;
    address public testModuleAddress;

    // Initializes handlers for each actor
    function setUpActors() public {
        Vm.Wallet[3] memory actors = [ALICE, BOB, CHARLIE];
        Nexus[3] memory actorAccounts = [ALICE_ACCOUNT, BOB_ACCOUNT, CHARLIE_ACCOUNT];
        validationModule = address(new MockValidator());
        testModuleType = 1;
        testModuleAddress = address(0x123);

        // Initialize the handlers for each actor
        for (uint i = 0; i < actors.length; i++) {
            // ExecutionHandler executionHandler = new ExecutionHandler(actorAccounts[i], actors[i]);
            DepositManagementHandlerTest depositHandler = new DepositManagementHandlerTest(actorAccounts[i], actors[i]);
            ModuleManagementHandlerTest moduleHandler = new ModuleManagementHandlerTest(actorAccounts[i], actors[i]);
            AccountCreationHandlerTest accountCreationHandler = new AccountCreationHandlerTest(FACTORY, validationModule, actors[i].addr);
            ExecutionHandlerTest executionHandler = new ExecutionHandlerTest(actorAccounts[i], actors[i]);

            // Store all handlers in an array for each actor
            actorHandlers.push(
                ActorHandlers({
                    depositHandler: depositHandler,
                    executionHandler: executionHandler,
                    moduleHandler: moduleHandler,
                    accountCreationHandler: accountCreationHandler
                })
            );
        }

        // Set targeted contracts and selectors for fuzzing
        for (uint i = 0; i < actorHandlers.length; i++) {
            targetContract(address(actorHandlers[i].moduleHandler));
            targetContract(address(actorHandlers[i].executionHandler));
            targetContract(address(actorHandlers[i].depositHandler));
            targetContract(address(actorHandlers[i].accountCreationHandler));
        }
    }

    //--------------------------------------------------------------
    // Account Creation Tests
    //--------------------------------------------------------------

    // Test account creation across all actors
    function invariant_CreateAccount() public {
        uint256 index = 0;
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].accountCreationHandler.invariant_createAccount(index++, 0);
        }
    }

    // Test nonce consistency across all actors
    function invariant_testNonceConsistency() public {
        uint256 index = 1;
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].accountCreationHandler.invariant_nonceConsistency(index++);
        }
    }

    // Test nonce reset on account creation across all actors
    function invariant_testNonceResetOnCreation() public {
        uint256 index = 1;
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].accountCreationHandler.invariant_nonceResetOnCreation(index++);
        }
    }

    // Test multiple account creation with unique indices across all actors
    function invariant_testMultipleAccountCreationWithUniqueIndices() public {
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].accountCreationHandler.invariant_multipleAccountCreationWithUniqueIndices();
        }
    }

    //--------------------------------------------------------------
    // Deposit Management Tests
    //--------------------------------------------------------------

    // Test deposits across all actors
    function invariant_Deposits() public {
        uint256 depositAmount = 1 ether;
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].depositHandler.invariant_handleDeposit(depositAmount);
        }
    }

    // Test withdrawals across all actors
    function invariant_Withdrawals() public {
        uint256 withdrawalAmount = 0.5 ether;
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].depositHandler.invariant_handleWithdrawal(withdrawalAmount);
        }
    }

    // Test zero value deposits across all actors
    function invariant_testAllZeroValueDeposits() public {
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].depositHandler.invariant_testZeroValueDeposit();
        }
    }

    // Test overdraft withdrawals across all actors
    function invariant_testAllOverdraftWithdrawals() public {
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].depositHandler.invariant_testOverdraftWithdrawal();
        }
    }

    // Check balance consistency after revert across all actors
    function invariant_checkAllBalancePostRevert() public {
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].depositHandler.invariant_checkBalancePostRevert();
        }
    }

    //--------------------------------------------------------------
    // Module Management Tests
    //--------------------------------------------------------------

    // Ensure each actor can handle module installation correctly
    function invariant_testAllModuleInstallations() public {
        uint256 moduleType = MODULE_TYPE_VALIDATOR;
        address moduleAddress = address(validationModule);

        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].moduleHandler.installModule(moduleType, moduleAddress);
        }
    }

    // Ensure each actor can handle module uninstallation correctly
    function invariant_testAllModuleUninstallations() public {
        uint256 moduleType = MODULE_TYPE_VALIDATOR;
        address moduleAddress = address(validationModule);

        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].moduleHandler.uninstallModule(moduleType, moduleAddress);
        }
    }

    //--------------------------------------------------------------
    // Execution Tests
    //--------------------------------------------------------------

    // Adds testing methods for increment operations across all actors
    function invariant_testAllIncrementOperations() public {
        uint256 amount = 1 ether;
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].executionHandler.invariant_handleIncrement(amount);
        }
    }

    // Tests failure handling for decrement operations across all actors
    function invariant_testAllDecrementFailures() public {
        uint256 amount = 1 ether;
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].executionHandler.invariant_handleShouldFail(amount);
        }
    }

    // Tests bounded deposit operations across all actors
    function invariant_testAllBoundedDeposits() public {
        uint256 amount = 500 ether;
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].executionHandler.invariant_handleBoundedDeposit(amount);
        }
    }
}
