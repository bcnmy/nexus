pragma solidity ^0.8.24;

interface IAccountFactory {
    event AccountCreated(address indexed account, address indexed validationModule, bytes moduleInstallData);

    function createAccount(
        address validationModule,
        bytes calldata moduleInstallData,
        uint256 index
    )
        external
        payable
        returns (address payable account);
}
