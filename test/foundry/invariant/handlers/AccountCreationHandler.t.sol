// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/BaseInvariantTest.t.sol";

// InvariantAccountCreationHandler is designed to handle invariant testing for the creation
// of accounts using the AccountFactory.
contract AccountCreationHandler is BaseInvariantTest {
    IAccountFactory private accountFactory;
    address private validationModule;
    address private owner;
    address private lastCreatedAccount; // Store the last created account address

    // Constructor initializes the handler with dependencies
    constructor(IAccountFactory _accountFactory, address _validationModule, address _owner) {
        accountFactory = _accountFactory;
        validationModule = _validationModule;
        owner = _owner;
    }

    // Tests account creation and asserts key invariants
    function invariant_createAccount(uint256 index, uint192 nonceKey) external {
        bytes memory initData = abi.encodePacked(owner);
        address payable newAccount = accountFactory.createAccount(validationModule, initData, index);
        require(newAccount != address(0), "Account creation failed");
        lastCreatedAccount = newAccount; // Update the last created account

        // Validate if the account is a contract and correctly set up
        require(isContract(newAccount), "Created account is not a valid contract");

        // Initial balance should be zero
        assertAccountBalance(newAccount, 0 ether);

        // Initial nonce should be zero
        assertNonce(newAccount, nonceKey, 0);
    }

    // Ensures nonce consistency before and after account creation
    function invariant_nonceConsistency(uint256 index) external {
        address payable newAccount = accountFactory.createAccount(validationModule, abi.encodePacked(owner), index);
        assertTrue(newAccount != address(0), "Account creation failed");

        // Calculate the expected nonce based on the newly created account and the validation module
        uint256 expectedNonce = getNonce(newAccount, validationModule);
        uint256 actualNonce = ENTRYPOINT.getNonce(newAccount, uint192(bytes24(bytes20(address(validationModule)))));

        // Assert that the calculated nonce matches the actual nonce
        assertEq(actualNonce, expectedNonce, "Nonce consistency invariant violated after account creation");
    }

    // Verifies that the nonce is reset to zero upon account creation
    function invariant_nonceResetOnCreation(uint256 index) external {
        address payable newAccount = accountFactory.createAccount(validationModule, abi.encodePacked(owner), index);
        assertTrue(newAccount != address(0), "Account creation failed");

        // Retrieve the nonce for the newly created account
        uint256 nonceAfterCreation = getNonce(newAccount, validationModule);

        // Assert that the nonce is zero for a new account
        assertEq(nonceAfterCreation, 0, "Nonce should be reset to zero upon account creation");
    }

    // Tests the creation of multiple accounts with different indices and validates nonce initialization
    function invariant_multipleAccountCreationWithUniqueIndices() external {
        uint256 index1 = 1;
        uint256 index2 = 2;

        address payable account1 = accountFactory.createAccount(validationModule, abi.encodePacked(owner), index1);
        address payable account2 = accountFactory.createAccount(validationModule, abi.encodePacked(owner), index2);

        assertTrue(account1 != address(0) && account2 != address(0) && account1 != account2, "Account creation failed");

        // Check nonces are initialized correctly
        uint256 nonce1 = getNonce(account1, validationModule);
        uint256 nonce2 = getNonce(account2, validationModule);

        assertEq(nonce1, 0, "Nonce for the first account is not initialized correctly");
        assertEq(nonce2, 0, "Nonce for the second account is not initialized correctly");
    }

    // Utility function to check if an address is a contract
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return size > 0;
    }

    // Asserts that the account's balance matches the expected balance
    function assertAccountBalance(address _account, uint256 _expectedBalance) internal {
        assertEq(address(_account).balance, _expectedBalance, "Balance invariant violated");
    }

    // Asserts that the nonce of the account matches the expected nonce
    function assertNonce(address _account, uint192 _key, uint256 _expectedNonce) internal {
        uint256 actualNonce = IEntryPoint(_account).getNonce(_account, _key);
        assertEq(actualNonce, _expectedNonce, "Nonce invariant violated");
    }

    // Getter for the last created account
    function getLastCreatedAccount() external view returns (address) {
        return lastCreatedAccount;
    }
}
