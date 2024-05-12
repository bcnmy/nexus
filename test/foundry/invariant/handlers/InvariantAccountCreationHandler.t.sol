// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../base/BaseInvariantTest.t.sol";

// InvariantAccountCreationHandler is designed to handle invariant testing for the creation
// of accounts using the AccountFactory.
contract InvariantAccountCreationHandler is BaseInvariantTest {
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

    // Utility function to check if an address is a contract
    function isContract(address _addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_addr) }
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
