// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./base/BaseInvariantTest.t.sol";
import "./handlers/AccountCreationHandler.t.sol";
import "./handlers/DepositManagementHandler.t.sol";

import "./handlers/ExecutionHandler.t.sol";
import "./handlers/ModuleManagementHandler.t.sol";

// ActorManager is responsible for coordinating test actions across different actors using handlers.
contract ActorManager is BaseInvariantTest {
    struct ActorHandlers {
        DepositManagementHandler depositHandler;
        ModuleManagementHandler moduleHandler;
        ExecutionHandler executionHandler;
        AccountCreationHandler accountCreationHandler;
    }

    ActorHandlers[] public actorHandlers;
    address public validationModule;
    uint256 public testModuleType;
    address public testModuleAddress;

    // Initializes handlers for each actor
    function setUpActors() public {
        // Example actor wallets and corresponding accounts; customize as per your environment setup
        Vm.Wallet[3] memory actors = [ALICE, BOB, CHARLIE];
        Nexus[3] memory actorAccounts = [ALICE_ACCOUNT, BOB_ACCOUNT, CHARLIE_ACCOUNT];
        validationModule = address(new MockValidator());
        testModuleType = 1; // Example module type for testing
        testModuleAddress = address(0x123); // Example module address for testing

        // Initialize the handlers for each actor
        for (uint i = 0; i < actors.length; i++) {
            // ExecutionHandler executionHandler = new ExecutionHandler(actorAccounts[i], actors[i]);
            DepositManagementHandler depositHandler = new DepositManagementHandler(actorAccounts[i], actors[i]);
            ModuleManagementHandler moduleHandler = new ModuleManagementHandler(actorAccounts[i], actors[i]);
            AccountCreationHandler accountCreationHandler = new AccountCreationHandler(FACTORY, validationModule, actors[i].addr);
            ExecutionHandler executionHandler = new ExecutionHandler(actorAccounts[i], actors[i]);

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
        }

        bytes4[] memory selectors = new bytes4[](5);
        selectors[0] = ModuleManagementHandler.installModule.selector;
        selectors[1] = ModuleManagementHandler.uninstallModule.selector;
        // selectors[2] = ModuleManagementHandler.invariant_ensureValidatorAlwaysInstalled.selector;
        // selectors[3] = ModuleManagementHandler.invariant_preventInvalidModuleTypeInstallation.selector;
        // selectors[4] = ModuleManagementHandler.invariant_preventUninstallingLastValidator.selector;

        for (uint i = 0; i < actorHandlers.length; i++) {
            targetSelector(FuzzSelector({ addr: address(actorHandlers[i].moduleHandler), selectors: selectors }));
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
        uint256 amount = 500 ether; // Assumes bounds set in the handler
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].executionHandler.invariant_handleBoundedDeposit(amount);
        }
    }
}
