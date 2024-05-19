// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Account compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. For security issues, contact: security@biconomy.io

import { LibClone } from "solady/src/utils/LibClone.sol";
import { Stakeable } from "../common/Stakeable.sol";
import { INexus } from "../interfaces/INexus.sol";
import { BootstrapUtil } from "../utils/BootstrapUtil.sol";
import { Bootstrap, BootstrapConfig } from "../utils/Bootstrap.sol";

/// @title Nexus - AccountFactory
/// @notice Manages the creation of Modular Smart Accounts compliant with ERC-7579 and ERC-4337 using a factory pattern.
/// @dev Utilizes the `StakeManager` for staking requirements and `LibClone` for creating deterministic proxy accounts.
///       This contract serves as a factory to generate new Nexus instances with specific modules and initialization data.
///       It combines functionality from Biconomy's implementation and external libraries to manage account deployments and initializations.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract ModuleWhitelistFactory is Stakeable, BootstrapUtil {
    /// @notice Emitted when a new Smart Account is created, capturing the account details and associated module configurations.
    event AccountCreated(address indexed account, bytes indexed initData, bytes32 indexed salt);
    
    /// @notice Stores the implementation contract address used to create new Nexus instances.
    /// @dev This address is set once upon deployment and cannot be changed afterwards.
    address public immutable ACCOUNT_IMPLEMENTATION;

    error ModuleNotWhitelisted();

    mapping(address => bool) public moduleWhitelist;

    // Review instead of Stakeable can just make Ownable. (Staeable gives Ownable but with Meta factory stake methods are not required)

    /// @notice Constructor to set the smart account implementation address.
    /// @param implementation The address of the Nexus implementation to be used for all deployments.
    constructor(address implementation, address owner) Stakeable(owner) {
        ACCOUNT_IMPLEMENTATION = implementation;
    }

    /// @notice Adds an address to the module whitelist.
    /// @param module The address to be whitelisted.
    function addModuleToWhitelist(address module) external onlyOwner {
        moduleWhitelist[module] = true;
    }

    /// @notice Removes an address from the module whitelist.
    /// @param module The address to be removed from the whitelist.
    function removeModuleFromWhitelist(address module) external onlyOwner {
        moduleWhitelist[module] = false;
    }

    /// @notice Checks if an address is whitelisted.
    /// @param module The address to check.
    function isWhitelisted(address module) public view returns (bool) {
        return moduleWhitelist[module];
    }

    /// @notice Creates a new Nexus with a specific validator and initialization data.

    // Review : or (BootstrapConfig[] validators, BootstrapConfig hook)
    function createAccount(address[] calldata validators, bytes[] calldata validatorData, address hook, bytes calldata hookData, bytes32 salt) external payable returns (address payable) {
        // Check if all validator addresses are whitelisted
        for (uint256 i = 0; i < validators.length; i++) {
            if (!isWhitelisted(validators[i])) {
                revert ModuleNotWhitelisted();
            }
        }
        // Check if hook address is whitelisted
        if (!isWhitelisted(hook)) {
            revert ModuleNotWhitelisted();
        }
        (salt);
        bytes32 actualSalt;
        assembly {
            let ptr := mload(0x40)
            let calldataLength := sub(calldatasize(), 0x04)
            mstore(0x40, add(ptr, calldataLength))
            calldatacopy(ptr, 0x04, calldataLength)
            actualSalt := keccak256(ptr, calldataLength)
        }

        (bool alreadyDeployed, address account) = LibClone.createDeterministicERC1967(msg.value, ACCOUNT_IMPLEMENTATION, actualSalt);

        // we could also just pass address eoaOwner above, if IAccountFactory consistency is not important
        BootstrapConfig[] memory _validators = makeBootstrapConfig(validators, validatorData);
        BootstrapConfig memory _hook = _makeBootstrapConfig(hook, hookData);

        bytes memory _initData = bootstrapSingleton._getInitNexusScopedCalldata(_validators, _hook);

        if (!alreadyDeployed) {
            INexus(account).initializeAccount(_initData);
            emit AccountCreated(account, _initData, actualSalt);
        }
        return payable(account);
    }

    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @dev This function allows for address calculation without deploying the Nexus.
    function computeAccountAddress(
        address[] calldata validators, bytes[] calldata validatorData, address hook, bytes calldata hookData, bytes32 salt
    ) external view returns (address payable expectedAddress) {
        (validators, validatorData, hook, hookData, salt);
        bytes32 actualSalt;

        assembly {
            let ptr := mload(0x40)
            let calldataLength := sub(calldatasize(), 0x04)
            mstore(0x40, add(ptr, calldataLength))
            calldatacopy(ptr, 0x04, calldataLength)
            actualSalt := keccak256(ptr, calldataLength)
        }
        expectedAddress = payable(LibClone.predictDeterministicAddressERC1967(ACCOUNT_IMPLEMENTATION, actualSalt, address(this)));
    }
}