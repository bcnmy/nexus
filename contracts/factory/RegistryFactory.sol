// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Accounts compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io. To report security issues, please contact us at: security@biconomy.io

import { LibClone } from "solady/utils/LibClone.sol";
import { LibSort } from "solady/utils/LibSort.sol";
import { BytesLib } from "../lib/BytesLib.sol";
import { INexus } from "../interfaces/INexus.sol";
import { BootstrapConfig } from "../utils/RegistryBootstrap.sol";
import { Stakeable } from "../common/Stakeable.sol";
import { IERC7484 } from "../interfaces/IERC7484.sol";
import { INexusFactory } from "../interfaces/factory/INexusFactory.sol";
import { MODULE_TYPE_VALIDATOR, MODULE_TYPE_EXECUTOR, MODULE_TYPE_FALLBACK, MODULE_TYPE_HOOK } from "../types/Constants.sol";

/// @title RegistryFactory
/// @notice Factory for creating Nexus accounts with whitelisted modules. Ensures compliance with ERC-7579 and ERC-4337 standards.
/// @author @livingrockrises | Biconomy | chirag@biconomy.io
/// @author @aboudjem | Biconomy | adam.boudjemaa@biconomy.io
/// @author @filmakarov | Biconomy | filipp.makarov@biconomy.io
/// @author @zeroknots | Rhinestone.wtf | zeroknots.eth
/// Special thanks to the Solady team for foundational contributions: https://github.com/Vectorized/solady
contract RegistryFactory is Stakeable, INexusFactory {
    /// @notice Address of the implementation contract used to create new Nexus instances.
    /// @dev This address is immutable and set upon deployment, ensuring the implementation cannot be changed.
    address public immutable ACCOUNT_IMPLEMENTATION;

    IERC7484 public immutable REGISTRY;
    address[] public attesters;
    uint8 public threshold;

    /// @notice Error thrown when a non-whitelisted module is used.
    /// @param module The module address that is not whitelisted.
    error ModuleNotWhitelisted(address module);

    /// @notice Error thrown when the threshold exceeds the number of attesters.
    /// @param threshold The provided threshold value.
    /// @param attestersLength The number of attesters provided.
    error InvalidThreshold(uint8 threshold, uint256 attestersLength);

    /// @notice Constructor to set the smart account implementation address and owner.
    /// @param implementation_ The address of the Nexus implementation to be used for all deployments.
    /// @param owner_ The address of the owner of the factory.
    constructor(address implementation_, address owner_, IERC7484 registry_, address[] memory attesters_, uint8 threshold_) Stakeable(owner_) {
        require(implementation_ != address(0), ImplementationAddressCanNotBeZero());
        require(owner_ != address(0), ZeroAddressNotAllowed());
        require(threshold_ <= attesters_.length, InvalidThreshold(threshold_, attesters_.length));
        REGISTRY = registry_;
        attesters = attesters_;
        threshold = threshold_;
        ACCOUNT_IMPLEMENTATION = implementation_;
    }

    function addAttester(address attester) external onlyOwner {
        // Add the new attester to the storage array
        attesters.push(attester);

        // Copy the storage array into memory for sorting
        address[] memory attestersMemory = attesters;

        // Sort the memory array
        LibSort.sort(attestersMemory);

        // Copy the sorted memory array back to the storage array
        for (uint256 i = 0; i < attestersMemory.length; i++) {
            attesters[i] = attestersMemory[i];
        }
    }

    function removeAttester(address attester) external onlyOwner {
        // Find and remove the attester by swapping it with the last element and popping the array
        for (uint256 i = 0; i < attesters.length; i++) {
            if (attesters[i] == attester) {
                attesters[i] = attesters[attesters.length - 1];
                attesters.pop();
                break;
            }
        }

        // Copy the storage array into memory for sorting
        address[] memory attestersMemory = attesters;

        // Sort the memory array
        LibSort.sort(attestersMemory);

        // Copy the sorted memory array back to the storage array
        for (uint256 i = 0; i < attestersMemory.length; i++) {
            attesters[i] = attestersMemory[i];
        }
    }

    function setThreshold(uint8 newThreshold) external onlyOwner {
        threshold = newThreshold;
    }

    /// @notice Creates a new Nexus account with the provided initialization data.
    /// @param initData Initialization data that is expected to be compatible with a `Bootstrap` contract's initialization method.
    /// @param salt Unique salt used for deterministic deployment of the Nexus smart account.
    /// @return The address of the newly created Nexus account.
    function createAccount(bytes calldata initData, bytes32 salt) external payable override returns (address payable) {
        // Decode the initialization data to extract the target bootstrap contract and the data to be used for initialization.
        (, bytes memory callData) = abi.decode(initData, (address, bytes));

        // Ensure that the initData is structured for the expected Bootstrap.initNexus or similar method.
        // This step is crucial for ensuring the proper initialization of the Nexus smart account.
        bytes memory innerData = BytesLib.slice(callData, 4, callData.length - 4);
        (
            BootstrapConfig[] memory validators,
            BootstrapConfig[] memory executors,
            BootstrapConfig memory hook,
            BootstrapConfig[] memory fallbacks,
            ,
            ,

        ) = abi.decode(innerData, (BootstrapConfig[], BootstrapConfig[], BootstrapConfig, BootstrapConfig[], address, address[], uint8));

        // Ensure that all specified modules are whitelisted and allowed for the account.
        for (uint256 i = 0; i < validators.length; i++) {
            require(_isModuleAllowed(validators[i].module, MODULE_TYPE_VALIDATOR), ModuleNotWhitelisted(validators[i].module));
        }

        for (uint256 i = 0; i < executors.length; i++) {
            require(_isModuleAllowed(executors[i].module, MODULE_TYPE_EXECUTOR), ModuleNotWhitelisted(executors[i].module));
        }

        require(_isModuleAllowed(hook.module, MODULE_TYPE_HOOK), ModuleNotWhitelisted(hook.module));

        for (uint256 i = 0; i < fallbacks.length; i++) {
            require(_isModuleAllowed(fallbacks[i].module, MODULE_TYPE_FALLBACK), ModuleNotWhitelisted(fallbacks[i].module));
        }

        // Compute the actual salt for deterministic deployment
        bytes32 actualSalt = keccak256(abi.encodePacked(initData, salt));

        // Deploy the account using the deterministic address
        (bool alreadyDeployed, address account) = LibClone.createDeterministicERC1967(msg.value, ACCOUNT_IMPLEMENTATION, actualSalt);

        if (!alreadyDeployed) {
            // Initialize the Nexus account using the provided initialization data
            INexus(account).initializeAccount(initData);
            emit AccountCreated(account, initData, salt);
        }

        return payable(account);
    }

    /// @notice Computes the expected address of a Nexus contract using the factory's deterministic deployment algorithm.
    /// @param initData - Initialization data to be called on the new Smart Account.
    /// @param salt - Unique salt for the Smart Account creation.
    /// @return expectedAddress The expected address at which the Nexus contract will be deployed if the provided parameters are used.
    function computeAccountAddress(bytes calldata initData, bytes32 salt) external view override returns (address payable expectedAddress) {
        // Compute the actual salt for deterministic deployment
        bytes32 actualSalt = keccak256(abi.encodePacked(initData, salt));
        expectedAddress = payable(LibClone.predictDeterministicAddressERC1967(ACCOUNT_IMPLEMENTATION, actualSalt, address(this)));
    }

    /// @notice Checks if a module is whitelisted.
    /// @param module The address of the module to check.
    /// @param moduleType The type of the module to check.
    /// @return True if the module is whitelisted, reverts otherwise.
    function _isModuleAllowed(address module, uint256 moduleType) private view returns (bool) {
        REGISTRY.check(module, moduleType, attesters, threshold);
        return true;
    }
}
