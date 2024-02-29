pragma solidity ^0.8.24;

interface IAccountFactory {
    event AccountCreated(address account, address owner);

    function createAccount(address module, uint256 index, bytes calldata data) external returns (address account);
}
