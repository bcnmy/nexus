// Sources flattened with hardhat v2.20.1 https://hardhat.org

// SPDX-License-Identifier: GPL-3.0 AND MIT

// File contracts/interfaces/base/IAccountConfig.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ERC-7579 Account Configuration Interface
 * @dev Interface for smart account configurations.
 */
interface IAccountConfig {
    /**
     * @notice Returns the account id of the smart account.
     * @return accountImplementationId The account id of the smart account.
     */
    function accountId() external view returns (string memory);

    /**
     * @notice Checks if the account supports a certain execution mode.
     * @param encodedMode The encoded mode.
     * @return True if the account supports the mode, false otherwise.
     */
    function supportsAccountMode(bytes32 encodedMode) external view returns (bool);

    /**
     * @notice Checks if the account supports a certain module typeId.
     * @param moduleTypeId The module type ID.
     * @return True if the account supports the module type, false otherwise.
     */
    function supportsModule(uint256 moduleTypeId) external view returns (bool);
}


// File contracts/base/AccountConfig.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.24;

contract AccountConfig is IAccountConfig {
    string internal constant _ACCOUNT_IMPLEMENTATION_ID = "biconomy.modular-smart-account.1.0.0-alpha";

    /// @inheritdoc IAccountConfig
    function supportsAccountMode(bytes32 encodedMode) external view returns (bool) {
        encodedMode;
        return true;
    }

    /// @inheritdoc IAccountConfig
    function supportsModule(uint256 moduleTypeId) external view returns (bool) {
        moduleTypeId;
        return true;
    }

    /// @inheritdoc IAccountConfig
    function accountId() external pure returns (string memory) {
        return _ACCOUNT_IMPLEMENTATION_ID;
    }
}


// File account-abstraction/contracts/interfaces/PackedUserOperation.sol@v0.6.0

// Original license: SPDX_License_Identifier: GPL-3.0
pragma solidity >=0.7.5;

/**
 * User Operation struct
 * @param sender                - The sender account of this request.
 * @param nonce                 - Unique value the sender uses to verify it is not a replay.
 * @param initCode              - If set, the account contract will be created by this constructor/
 * @param callData              - The method call to execute on this account.
 * @param accountGasLimits      - Packed gas limits for validateUserOp and gas limit passed to the callData method call.
 * @param preVerificationGas    - Gas not calculated by the handleOps method, but added to the gas paid.
 *                                Covers batch overhead.
 * @param gasFees                - packed gas fields maxFeePerGas and maxPriorityFeePerGas - Same as EIP-1559 gas parameter.
 * @param paymasterAndData      - If set, this field holds the paymaster address, verification gas limit, postOp gas limit and paymaster-specific extra data
 *                                The paymaster will pay for the transaction instead of the sender.
 * @param signature             - Sender-verified signature over the entire request, the EntryPoint address and the chain ID.
 */
struct PackedUserOperation {
    address sender;
    uint256 nonce;
    bytes initCode;
    bytes callData;
    bytes32 accountGasLimits;
    uint256 preVerificationGas;
    bytes32 gasFees;    //maxPriorityFee and maxFeePerGas;
    bytes paymasterAndData;
    bytes signature;
}


// File contracts/interfaces/base/IAccountExecution.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title Execution Interface for Biconomy Smart Accounts
 * @dev Interface for executing transactions on behalf of the smart account,
 * including ERC7579 executions and ERC-4337 user operations as per ERC-4337-v-0.7
 */
interface IAccountExecution {
    /**
     * @notice ERC7579 Main Execution flow.
     * Executes a transaction on behalf of the account.
     * @dev Must ensure adequate authorization control.
     * @param mode The encoded execution mode of the transaction.
     * @param executionCalldata The encoded execution call data.
     */
    function execute(bytes32 mode, bytes calldata executionCalldata) external payable;

    /**
     * @notice ERC7579 Execution from Executor flow.
     * Executes a transaction from an Executor Module.
     * @dev Must ensure adequate authorization control.
     * @param mode The encoded execution mode of the transaction.
     * @param executionCalldata The encoded execution call data.
     * @return returnData The return data from the executed call.
     */
    function executeFromExecutor(
        bytes32 mode,
        bytes calldata executionCalldata
    )
        external
        payable
        returns (bytes[] memory returnData);

    /**
     * @notice Executes a user operation as per ERC-4337.
     * @dev This function is intended to be called by the ERC-4337 EntryPoint contract.
     * @param userOp The packed user operation data.
     * @param userOpHash The hash of the packed user operation.
     */
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external payable;
}


// File contracts/base/AccountExecution.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.24;


contract AccountExecution is IAccountExecution {
    /// @inheritdoc IAccountExecution
    function execute(bytes32 mode, bytes calldata executionCalldata) external payable {
        mode;
        (address target, uint256 value, bytes memory callData) =
            abi.decode(executionCalldata, (address, uint256, bytes));
        target.call{ value: value }(callData);
    }

    /// @inheritdoc IAccountExecution
    function executeFromExecutor(
        bytes32 mode,
        bytes calldata executionCalldata
    )
        external
        payable
        returns (bytes[] memory returnData)
    {
        mode;
        (address target, uint256 value, bytes memory callData) =
            abi.decode(executionCalldata, (address, uint256, bytes));
        target.call{ value: value }(callData);
    }

    /// @inheritdoc IAccountExecution
    function executeUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external payable {
        userOp;
        userOpHash;
    }
}


// File contracts/interfaces/IStorage.sol

// Original license: SPDX_License_Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity 0.8.24;

interface IStorage {
    /// @custom:storage-location erc7201:biconomy.storage.SmartAccount
    struct AccountStorage {
        mapping(address => address) modules;
    }
}


// File contracts/base/Storage.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.24;

contract Storage is IStorage {
    /// @custom:storage-location erc7201:biconomy.storage.SmartAccount
    /// ERC-7201 namespaced via `keccak256(encode(uint256(keccak256("biconomy.storage.SmartAccount")) - 1)) & ~0xff`
    bytes32 private constant _STORAGE_LOCATION = 0x34e06d8d82e2a2cc69c6a8a18181d71c19765c764b52180b715db4be61b27a00;

    /**
     * @dev Utilizes ERC-7201's namespaced storage pattern for isolated storage access. This method computes
     * the storage slot based on a predetermined location, ensuring collision-resistant storage for contract states.
     * @custom:storage-location ERC-7201 formula applied to "biconomy.storage.SmartAccount", facilitating unique
     * namespace identification and storage segregation, as detailed in the specification.
     * @return $ The proxy to the `AccountStorage` struct, providing a reference to the namespaced storage slot.
     */
    function _getAccountStorage() internal pure returns (AccountStorage storage $) {
        assembly {
            $.slot := _STORAGE_LOCATION
        }
    }
}


// File contracts/interfaces/base/IModuleManager.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ERC-7579 Module Configuration Interface
 * @dev Interface for configuring modules in a smart account.
 */
interface IModuleManager {
    /**
     * @notice Installs a Module of a certain type on the smart account.
     * @param moduleType The module type ID.
     * @param module The module address.
     * @param initData Initialization data for the module.
     */
    function installModule(uint256 moduleType, address module, bytes calldata initData) external payable;

    /**
     * @notice Uninstalls a Module of a certain type from the smart account.
     * @param moduleType The module type ID.
     * @param module The module address.
     * @param deInitData De-initialization data for the module.
     */
    function uninstallModule(uint256 moduleType, address module, bytes calldata deInitData) external payable;

    /**
     * @notice Checks if a module is installed on the smart account.
     * @param moduleType The module type ID.
     * @param module The module address.
     * @param additionalContext Additional context for checking installation.
     * @return True if the module is installed, false otherwise.
     */
    function isModuleInstalled(
        uint256 moduleType,
        address module,
        bytes calldata additionalContext
    )
        external
        view
        returns (bool);
}


// File contracts/lib/ModuleTypeLib.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;

type EncodedModuleTypes is uint256;

type ModuleType is uint256;

library ModuleTypeLib {
    function isType(EncodedModuleTypes self, ModuleType moduleType) internal pure returns (bool) {
        return (EncodedModuleTypes.unwrap(self) & (2 ** ModuleType.unwrap(moduleType))) != 0;
    }

    function bitEncode(ModuleType[] memory moduleTypes) internal pure returns (EncodedModuleTypes) {
        uint256 result;
        for (uint256 i; i < moduleTypes.length; i++) {
            result = result + uint256(2 ** ModuleType.unwrap(moduleTypes[i]));
        }
        return EncodedModuleTypes.wrap(result);
    }

    function bitEncodeCalldata(ModuleType[] calldata moduleTypes) internal pure returns (EncodedModuleTypes) {
        uint256 result;
        for (uint256 i; i < moduleTypes.length; i++) {
            result = result + uint256(2 ** ModuleType.unwrap(moduleTypes[i]));
        }
        return EncodedModuleTypes.wrap(result);
    }
}


// File contracts/interfaces/IModule.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.24;

/**
 * @title ERC-7579 Module Interface
 * @dev Basic interface for all types of modules.
 */
interface IModule {
    error AlreadyInitialized(address smartAccount);
    error NotInitialized(address smartAccount);

    /**
     * @dev This function is called by the smart account during installation of the module
     * @param data arbitrary data that may be required on the module during `onInstall`
     * initialization
     *
     * MUST revert on error (i.e. if module is already enabled)
     */
    function onInstall(bytes calldata data) external;

    /**
     * @dev This function is called by the smart account during uninstallation of the module
     * @param data arbitrary data that may be required on the module during `onUninstall`
     * de-initialization
     *
     * MUST revert on error
     */
    function onUninstall(bytes calldata data) external;

    /**
     * @dev Returns boolean value if module is a certain type
     * @param typeID the module type ID according the ERC-7579 spec
     *
     * MUST return true if the module is of the given type and false otherwise
     */
    function isModuleType(uint256 typeID) external view returns (bool);

    /**
     * @dev Returns bit-encoded integer of the different typeIds of the module
     *
     * MUST return all the bit-encoded typeIds of the module
     */
    function getModuleTypes() external view returns (EncodedModuleTypes);

    /**
     * @dev Returns if the module was already initialized for a provided smartaccount
     */
    // function isInitialized(address smartAccount) external view returns (bool);
}


// File contracts/base/ModuleManager.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.24;



contract ModuleManager is Storage, IModuleManager {
    /**
     * @notice Installs a Module of a certain type on the smart account.
     * @param moduleType The module type ID.
     * @param module The module address.
     * @param initData Initialization data for the module.
     */
    function installModule(uint256 moduleType, address module, bytes calldata initData) external payable {
        AccountStorage storage $ = _getAccountStorage();
        $.modules[module] = module;

        IModule(module).onInstall(initData);
        moduleType;
        initData;
    }

    /**
     * @notice Uninstalls a Module of a certain type from the smart account.
     * @param moduleType The module type ID.
     * @param module The module address.
     * @param deInitData De-initialization data for the module.
     */
    function uninstallModule(uint256 moduleType, address module, bytes calldata deInitData) external payable {
        AccountStorage storage $ = _getAccountStorage();
        moduleType;
        deInitData;
        delete $.modules[module];
    }

    /**
     * @notice Checks if a module is installed on the smart account.
     * @param moduleType The module type ID.
     * @param module The module address.
     * @param additionalContext Additional context for checking installation.
     * @return True if the module is installed, false otherwise.
     */
    function isModuleInstalled(
        uint256 moduleType,
        address module,
        bytes calldata additionalContext
    )
        external
        view
        returns (bool)
    {
        AccountStorage storage $ = _getAccountStorage();
        additionalContext;
        moduleType;
        return $.modules[module] != address(0);
    }
}


// File contracts/interfaces/IAccount.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.24;

interface IAccount {
    /**
     * Validate user's signature and nonce
     * the entryPoint will make the call to the recipient only if this validation call returns successfully.
     * signature failure should be reported by returning SIG_VALIDATION_FAILED (1).
     * This allows making a "simulation call" without a valid signature
     * Other failures (e.g. nonce mismatch, or invalid signature format) should still revert to signal failure.
     *
     * @dev Must validate caller is the entryPoint.
     *      Must validate the signature and nonce
     * @param userOp              - The user operation that is about to be executed.
     * @param userOpHash          - Hash of the user's request data. can be used as the basis for signature.
     * @param missingAccountFunds - Missing funds on the account's deposit in the entrypoint.
     *                              This is the minimum amount to transfer to the sender(entryPoint) to be
     *                              able to make the call. The excess is left as a deposit in the entrypoint
     *                              for future calls. Can be withdrawn anytime using "entryPoint.withdrawTo()".
     *                              In case there is a paymaster in the request (or the current deposit is high
     *                              enough), this value will be zero.
     * @return validationData       - Packaged ValidationData structure. use `_packValidationData` and
     *                              `_unpackValidationData` to encode and decode.
     *                              <20-byte> sigAuthorizer - 0 for valid signature, 1 to mark signature failure,
     *                                 otherwise, an address of an "authorizer" contract.
     *                              <6-byte> validUntil - Last timestamp this operation is valid. 0 for "indefinite"
     *                              <6-byte> validAfter - First timestamp this operation is valid
     *                                                    If an account doesn't use time-range, it is enough to
     *                                                    return SIG_VALIDATION_FAILED value (1) for signature failure.
     *                              Note that the validation code cannot use block.timestamp (or block.number) directly.
     */
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        returns (uint256 validationData);
}


// File contracts/interfaces/IERC7579Modules.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity ^0.8.24;


uint256 constant VALIDATION_SUCCESS = 0;
uint256 constant VALIDATION_FAILED = 1;

uint256 constant MODULE_TYPE_VALIDATOR = 1;
uint256 constant MODULE_TYPE_EXECUTOR = 2;
uint256 constant MODULE_TYPE_FALLBACK = 3;
uint256 constant MODULE_TYPE_HOOK = 4;

interface IValidator is IModule {
    error InvalidTargetAddress(address target);

    /**
     * @dev Validates a transaction on behalf of the account.
     *         This function is intended to be called by the MSA during the ERC-4337 validaton phase
     *         Note: solely relying on bytes32 hash and signature is not suffcient for some
     * validation implementations (i.e. SessionKeys often need access to userOp.calldata)
     * @param userOp The user operation to be validated. The userOp MUST NOT contain any metadata.
     * The MSA MUST clean up the userOp before sending it to the validator.
     * @param userOpHash The hash of the user operation to be validated
     * @return return value according to ERC-4337
     */
    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external returns (uint256);

    /**
     * Validator can be used for ERC-1271 validation
     */
    function isValidSignatureWithSender(
        address sender,
        bytes32 hash,
        bytes calldata data
    )
        external
        view
        returns (bytes4);
}

interface IExecutor is IModule {
// solhint-disable-previous-line no-empty-blocks
}

interface IHook is IModule {
    function preCheck(address msgSender, bytes calldata msgData) external returns (bytes memory hookData);
    function postCheck(bytes calldata hookData) external returns (bool success);
}

interface IFallback is IModule {
// solhint-disable-previous-line no-empty-blocks
}


// File contracts/SmartAccount.sol

// Original license: SPDX_License_Identifier: MIT
pragma solidity 0.8.24;





contract SmartAccount is AccountConfig, AccountExecution, ModuleManager, IAccount {
    /// @dev Sends to the EntryPoint (i.e. `msg.sender`) the missing funds for this transaction.
    /// Subclass MAY override this modifier for better funds management.
    /// (e.g. send to the EntryPoint more than the minimum required, so that in future transactions
    /// it will not be required to send again)
    ///
    /// `missingAccountFunds` is the minimum value this modifier should send the EntryPoint,
    /// which MAY be zero, in case there is enough deposit, or the userOp has a paymaster.
    modifier payPrefund(uint256 missingAccountFunds) virtual {
        _;
        /// @solidity memory-safe-assembly
        assembly {
            if missingAccountFunds {
                // Ignore failure (it's EntryPoint's job to verify, not the account's).
                pop(call(gas(), caller(), missingAccountFunds, codesize(), 0x00, codesize(), 0x00))
            }
        }
    }

    constructor() {
        // solhint-disable-previous-line no-empty-blocks
    }

    /// @inheritdoc IAccount
    /// @dev expects IValidator module address to be encoded in the nonce
    function validateUserOp(
        PackedUserOperation calldata userOp,
        bytes32 userOpHash,
        uint256 missingAccountFunds
    )
        external
        virtual
        payPrefund(missingAccountFunds)
        returns (uint256)
    {
        address validator;
        uint256 nonce = userOp.nonce;
        assembly {
            validator := shr(96, nonce)
        }
        // check if validator is enabled. If terminate the validation phase.
        //if (!_isValidatorInstalled(validator)) return VALIDATION_FAILED;

        // bubble up the return value of the validator module
        uint256 validationData = IValidator(validator).validateUserOp(userOp, userOpHash);
        return validationData;
    }
}
