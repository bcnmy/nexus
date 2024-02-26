pragma solidity 0.8.24;

import { SmartAccount } from "../SmartAccount.sol";
import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { IAccountFactory } from "../interfaces/factory/IAccountFactory.sol";
import { IModuleManager } from "../interfaces/base/IModuleManager.sol";
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
        IModuleManager(account).installModule(index, module, data);
    }

    /**
     * @dev Computes the expected address of a SmartAccount contract created via the factory.
     * @param module The address of the module to be used in the SmartAccount.
     * @param index The index or type of the module, for differentiation if needed.
     * @param data The initialization data for the module.
     * @return expectedAddress The address at which the new SmartAccount contract will be deployed.
     */
    function computeAccountAddress(
        address module,
        uint256 index,
        bytes calldata data
    )
        external
        view
        returns (address expectedAddress)
    {
        bytes32 salt = keccak256(abi.encodePacked(module, index, data));
        bytes memory bytecode = abi.encodePacked(type(SmartAccount).creationCode);
        expectedAddress = Create2.computeAddress(salt, keccak256(bytecode));
    }
}
