// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./base/BaseInvariantTest.t.sol";
import "./handlers/InvariantAccountCreationHandler.t.sol";
import "./handlers/InvariantExecutionHandler.t.sol";
import "./handlers/InvariantDepositManagementHandler.t.sol";
import "./handlers/InvariantModuleManagementHandler.t.sol";

// ActorManager is responsible for coordinating test actions across different actors using handlers.
contract ActorManager is BaseInvariantTest {
    struct ActorHandlers {
        InvariantExecutionHandler executionHandler;
        InvariantDepositManagementHandler depositHandler;
        InvariantModuleManagementHandler moduleHandler;
        InvariantAccountCreationHandler accountCreationHandler;
    }

    ActorHandlers[] public actorHandlers;
    address public validationModule;

    // Initializes handlers for each actor
    function setUpActors() public {
        // Example actor wallets and corresponding accounts; customize as per your environment setup
        Vm.Wallet[3] memory actors = [ALICE, BOB, CHARLIE];
        Nexus[3] memory actorAccounts = [ALICE_ACCOUNT, BOB_ACCOUNT, CHARLIE_ACCOUNT];
        validationModule = address(new MockValidator());

        // Initialize the handlers for each actor
        for (uint i = 0; i < actors.length; i++) {
            InvariantExecutionHandler executionHandler = new InvariantExecutionHandler(actorAccounts[i], actors[i]);
            InvariantDepositManagementHandler depositHandler = new InvariantDepositManagementHandler(actorAccounts[i], actors[i]);
            InvariantModuleManagementHandler moduleHandler = new InvariantModuleManagementHandler(actorAccounts[i], actors[i]);
            InvariantAccountCreationHandler accountCreationHandler = new InvariantAccountCreationHandler(FACTORY, validationModule, actors[i].addr);

            // Store all handlers in an array for each actor
            actorHandlers.push(
                ActorHandlers({
                    executionHandler: executionHandler,
                    depositHandler: depositHandler,
                    moduleHandler: moduleHandler,
                    accountCreationHandler: accountCreationHandler
                })
            );
        }
    }

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

    // Test account creation across all actors
    function invariant_CreateAccount() public {
        uint256 index = 0;
        for (uint i = 0; i < actorHandlers.length; i++) {
            actorHandlers[i].accountCreationHandler.invariant_createAccount(index++, 0);
        }
    }

    // Add more test scenarios involving execution or module management
}
