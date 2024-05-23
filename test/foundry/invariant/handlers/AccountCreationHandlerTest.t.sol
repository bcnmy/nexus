// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { InvariantBaseTest } from "../base/InvariantBaseTest.t.sol";
import "../../utils/Imports.sol";

/// @title AccountCreationHandlerTest
/// @notice Handles invariant testing for the creation of accounts using the AccountFactory.
/// @dev This handler is responsible for simulating the creation of accounts, ensuring the process adheres to defined invariants.
contract AccountCreationHandlerTest is InvariantBaseTest {
    NexusAccountFactory private accountFactory;
    address private validationModule;
    address private owner;
    address private lastCreatedAccount; // Stores the last created account address

    /// @notice Initializes the handler with dependencies.
    /// @param _accountFactory The account factory contract.
    /// @param _validationModule The validation module address.
    /// @param _owner The owner address.
    constructor(NexusAccountFactory _accountFactory, address _validationModule, address _owner) {
        accountFactory = _accountFactory;
        validationModule = _validationModule;
        owner = _owner;
    }

    /// @notice Tests account creation and asserts key invariants.
    /// @param salt The salt used for creating the account address.
    function invariant_createAccount(bytes32 salt) external {
        bytes memory initData = abi.encodePacked(owner);
        address payable newAccount = deployAccount(initData, salt);
        require(newAccount != address(0), "Account creation failed");
        lastCreatedAccount = newAccount; // Update the last created account

        // Validate if the account is a contract and correctly set up
        require(isContract(newAccount), "Created account is not a valid contract");

        // Initial balance should be zero
        assertAccountBalance(newAccount, 0 ether);

        // Initial nonce should be zero
        assertNonce(newAccount, 0);

        // Validate account creation
        assertValidCreation(Nexus(newAccount));
    }

    /// @notice Ensures nonce consistency before and after account creation.
    /// @param salt The salt used for creating the account address.
    function invariant_nonceConsistency(bytes32 salt) external {
        bytes memory initData = abi.encodePacked(owner);
        address payable newAccount = deployAccount(initData, salt);
        require(newAccount != address(0), "Account creation failed");

        // Calculate the expected nonce based on the newly created account and the validation module
        uint256 expectedNonce = getNonce(newAccount);
        uint256 actualNonce = ENTRYPOINT.getNonce(newAccount, uint192(bytes24(bytes20(address(validationModule)))));

        // Assert that the calculated nonce matches the actual nonce
        assertEq(actualNonce, expectedNonce, "Nonce consistency invariant violated after account creation");
        assertValidCreation(Nexus(newAccount));
    }

    /// @notice Verifies that the nonce is reset to zero upon account creation.
    /// @param salt The salt used for creating the account address.
    function invariant_nonceResetOnCreation(bytes32 salt) external {
        bytes memory initData = abi.encodePacked(owner);
        address payable newAccount = deployAccount(initData, salt);
        require(newAccount != address(0), "Account creation failed");

        // Retrieve the nonce for the newly created account
        uint256 nonceAfterCreation = getNonce(newAccount);

        // Assert that the nonce is zero for a new account
        assertEq(nonceAfterCreation, 0, "Nonce should be reset to zero upon account creation");
        assertValidCreation(Nexus(newAccount));
    }

    /// @notice Tests the creation of multiple accounts with different indices and validates nonce initialization.
    function invariant_multipleAccountCreationWithUniqueIndices() external {
        bytes memory initData = abi.encodePacked(owner);
        address payable account1 = deployAccountWithSalt(initData, keccak256(abi.encodePacked("1")));
        address payable account2 = deployAccountWithSalt(initData, keccak256(abi.encodePacked("2")));

        require(account1 != address(0) && account2 != address(0) && account1 != account2, "Account creation failed");

        // Check nonces are initialized correctly
        uint256 nonce1 = getNonce(account1);
        uint256 nonce2 = getNonce(account2);

        assertEq(nonce1, 0, "Nonce for the first account is not initialized correctly");
        assertEq(nonce2, 0, "Nonce for the second account is not initialized correctly");

        assertValidCreation(Nexus(account1));
        assertValidCreation(Nexus(account2));
    }

    /// @notice Asserts that the account's balance matches the expected balance.
    /// @param _account The account address.
    /// @param _expectedBalance The expected balance.
    function assertAccountBalance(address _account, uint256 _expectedBalance) internal {
        assertEq(address(_account).balance, _expectedBalance, "Balance invariant violated");
    }

    /// @notice Asserts that the nonce of the account matches the expected nonce.
    /// @param _account The account address.
    /// @param _expectedNonce The expected nonce.
    function assertNonce(address _account, uint256 _expectedNonce) internal {
        uint256 actualNonce = ENTRYPOINT.getNonce(_account, uint192(bytes24(bytes20(address(validationModule)))));
        assertEq(actualNonce, _expectedNonce, "Nonce invariant violated");
    }

    /// @notice Getter for the last created account.
    /// @return The address of the last created account.
    function getLastCreatedAccount() external view returns (address) {
        return lastCreatedAccount;
    }

    /// @notice Validates the creation of a new account.
    /// @param _account The new account address.
    function assertValidCreation(Nexus _account) internal {
        string memory expected = "biconomy.nexus.0.0.1";
        assertEq(_account.accountId(), expected, "AccountConfig should return the expected account ID.");
        assertTrue(_account.isModuleInstalled(MODULE_TYPE_VALIDATOR, validationModule, ""), "Account should have the validation module installed");
    }

    /// @notice Deploys a new account with given initialization data.
    /// @param initData Initialization data for the account.
    /// @param salt The salt used for creating the account address.
    /// @return The address of the deployed account.
    function deployAccount(bytes memory initData, bytes32 salt) internal returns (address payable) {
        bytes memory factoryData = abi.encodeWithSelector(accountFactory.createAccount.selector, initData, salt);
        return META_FACTORY.deployWithFactory(address(accountFactory), factoryData);
    }

    /// @notice Deploys a new account with given initialization data and a specific salt.
    /// @param initData Initialization data for the account.
    /// @param salt The salt used for creating the account address.
    /// @return The address of the deployed account.
    function deployAccountWithSalt(bytes memory initData, bytes32 salt) internal returns (address payable) {
        bytes memory factoryData = abi.encodeWithSelector(accountFactory.createAccount.selector, initData, salt);
        return META_FACTORY.deployWithFactory(address(accountFactory), factoryData);
    }

    /// @notice Retrieves the nonce for a given account.
    /// @param account The account address.
    /// @return The current nonce of the account.
    function getNonce(address account) internal view returns (uint256) {
        return ENTRYPOINT.getNonce(account, uint192(bytes24(bytes20(address(validationModule)))));
    }
}
