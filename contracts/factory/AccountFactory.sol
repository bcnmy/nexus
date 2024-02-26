pragma solidity 0.8.24;

import { SmartAccount } from "../SmartAccount.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { IAccountFactory } from "../interfaces/factory/IAccountFactory.sol";
import { IModuleConfig } from "../interfaces/IModuleConfig.sol";
import { StakeManager } from "account-abstraction/contracts/core/StakeManager.sol";

contract AccountFactory is IAccountFactory, StakeManager {
    function createAccount(address module, uint256 index, bytes calldata data) external returns (address account) {
        bytes32 salt = keccak256(abi.encodePacked(module, index, data));

        bytes memory bytecode = abi.encodePacked(type(SmartAccount).creationCode);
        account = Create2.computeAddress(salt, keccak256(bytecode));
        if (account.code.length > 0) {
            return account;
        }

        account = Create2.deploy(0, salt, bytecode);
        IModuleConfig(account).installModule(index, module, data);
    }
}
