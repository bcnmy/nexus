// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "solady/src/utils/ECDSA.sol";
import { EntryPoint } from "account-abstraction/contracts/core/EntryPoint.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

import "./Imports.sol";
import "./CheatCodes.sol";
import "./EventsAndErrors.sol";
import "../../../contracts/lib/ModeLib.sol";
import "../../../contracts/lib/ExecLib.sol";
import { Nexus } from "../../../contracts/Nexus.sol";
import { MockHook } from "../../../contracts/mocks/MockHook.sol";
import { MockHandler } from "../../../contracts/mocks/MockHandler.sol";
import { MockExecutor } from "../../../contracts/mocks/MockExecutor.sol";
import { MockValidator } from "../../../contracts/mocks/MockValidator.sol";
import { AccountFactory } from "../../../contracts/factory/AccountFactory.sol";

/// @title Helpers - Utility contract for testing with cheat codes and shared setup
/// @notice Provides various helper functions for setting up and testing contracts
contract Helpers is CheatCodes, EventsAndErrors {
    // -----------------------------------------
    // State Variables
    // -----------------------------------------
    
    Vm.Wallet internal DEPLOYER;
    Vm.Wallet internal ALICE;
    Vm.Wallet internal BOB;
    Vm.Wallet internal CHARLIE;
    Vm.Wallet internal BUNDLER;

    address internal DEPLOYER_ADDRESS;
    address internal ALICE_ADDRESS;
    address internal BOB_ADDRESS;
    address internal CHARLIE_ADDRESS;
    address internal BUNDLER_ADDRESS;

    Nexus internal BOB_ACCOUNT;
    Nexus internal ALICE_ACCOUNT;
    Nexus internal CHARLIE_ACCOUNT;

    IEntryPoint internal ENTRYPOINT;
    AccountFactory internal FACTORY;
    MockHook internal HOOK_MODULE;
    MockHandler internal HANDLER_MODULE;
    MockExecutor internal EXECUTOR_MODULE;
    MockValidator internal VALIDATOR_MODULE;
    Nexus internal ACCOUNT_IMPLEMENTATION;

    // -----------------------------------------
    // Setup Functions
    // -----------------------------------------
    
    /// @notice Initializes the testing environment with wallets, contracts, and accounts
    function setupTestEnvironment() internal virtual {
        setupPredefinedWallets();
        deployTestContracts();
        deployNexusForPredefinedWallets();
    }

    /// @notice Creates and funds a new wallet
    /// @param name The name to label the wallet
    /// @param amount The amount of ether to fund the wallet with
    /// @return wallet The created and funded wallet
    function createAndFundWallet(string memory name, uint256 amount) internal returns (Vm.Wallet memory) {
        Vm.Wallet memory wallet = newWallet(name);
        vm.deal(wallet.addr, amount);
        return wallet;
    }

    /// @notice Initializes the predefined wallets
    function setupPredefinedWallets() internal {
        DEPLOYER = createAndFundWallet("DEPLOYER", 1000 ether);
        ALICE = createAndFundWallet("ALICE", 1000 ether);
        BOB = createAndFundWallet("BOB", 1000 ether);
        CHARLIE = createAndFundWallet("CHARLIE", 1000 ether);
        BUNDLER = createAndFundWallet("BUNDLER", 1000 ether);
    }

    /// @notice Deploys the necessary contracts for testing
    function deployTestContracts() internal {
        ENTRYPOINT = new EntryPoint();
        vm.etch(address(0x0000000071727De22E5E9d8BAf0edAc6f37da032), address(ENTRYPOINT).code);
        ENTRYPOINT = IEntryPoint(0x0000000071727De22E5E9d8BAf0edAc6f37da032);
        ACCOUNT_IMPLEMENTATION = new Nexus();
        FACTORY = new AccountFactory(address(ACCOUNT_IMPLEMENTATION));
        VALIDATOR_MODULE = new MockValidator();
        EXECUTOR_MODULE = new MockExecutor();
        HOOK_MODULE = new MockHook();
        HANDLER_MODULE = new MockHandler();
    }

    // -----------------------------------------
    // Account Deployment Functions
    // -----------------------------------------
    
    /// @notice Deploys an account with a specified wallet, deposit amount, and optional custom validator
    /// @param wallet The wallet to deploy the account for
    /// @param deposit The deposit amount
    /// @param validator The custom validator address, if not provided uses default
    /// @return The deployed Nexus account
    function deployNexus(Vm.Wallet memory wallet, uint256 deposit, address validator) internal returns (Nexus) {
        if (validator == address(0)) {
            validator = address(VALIDATOR_MODULE);
        }
        address payable accountAddress = calculateAccountAddress(wallet.addr, validator);
        bytes memory initCode = buildInitCode(wallet.addr, validator);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithInitAndCalldata(wallet, initCode, "", validator);

        ENTRYPOINT.depositTo{ value: deposit }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(wallet.addr));
        assertTrue(MockValidator(validator).isOwner(accountAddress, wallet.addr));
        return Nexus(accountAddress);
    }

    /// @notice Deploys Nexus accounts for predefined wallets
    function deployNexusForPredefinedWallets() internal {
        BOB_ACCOUNT = deployNexus(BOB, 100 ether, address(VALIDATOR_MODULE));
        vm.label(address(BOB_ACCOUNT), "BOB_ACCOUNT");
        ALICE_ACCOUNT = deployNexus(ALICE, 100 ether, address(VALIDATOR_MODULE));
        vm.label(address(ALICE_ACCOUNT), "ALICE_ACCOUNT");
        CHARLIE_ACCOUNT = deployNexus(CHARLIE, 100 ether, address(VALIDATOR_MODULE));
        vm.label(address(CHARLIE_ACCOUNT), "CHARLIE_ACCOUNT");
    }

    // -----------------------------------------
    // Utility Functions
    // -----------------------------------------

    /// @notice Calculates the address of a new account
    /// @param owner The address of the owner
    /// @param validator The address of the validator
    /// @return account The calculated account address
    function calculateAccountAddress(address owner, address validator) internal view returns (address payable account) {
        bytes memory initData = abi.encodePacked(owner);
        uint256 saDeploymentIndex = 0;
        account = FACTORY.getCounterFactualAddress(address(validator), initData, saDeploymentIndex);
        return account;
    }

    /// @notice Prepares the init code for account creation with a validator
    /// @param ownerAddress The address of the owner
    /// @param validator The address of the validator
    /// @return initCode The prepared init code
    function buildInitCode(address ownerAddress, address validator) internal view returns (bytes memory initCode) {
        uint256 saDeploymentIndex = 0;
        bytes memory moduleInitData = abi.encodePacked(ownerAddress);

        initCode = abi.encodePacked(
            address(FACTORY),
            abi.encodeWithSelector(FACTORY.createAccount.selector, validator, moduleInitData, saDeploymentIndex)
        );
    }

    /// @notice Prepares a user operation with init code and call data
    /// @param wallet The wallet for which the user operation is prepared
    /// @param initCode The init code
    /// @param callData The call data
    /// @param validator The validator address
    /// @return userOp The prepared user operation
    function buildUserOpWithInitAndCalldata(
        Vm.Wallet memory wallet,
        bytes memory initCode,
        bytes memory callData,
        address validator
    ) internal view returns (PackedUserOperation memory userOp) {
        userOp = buildUserOpWithCalldata(wallet, callData, validator);
        userOp.initCode = initCode;

        bytes memory signature = signUserOp(wallet, userOp);
        userOp.signature = signature;
    }

    /// @notice Prepares a user operation with call data and a validator
    /// @param wallet The wallet for which the user operation is prepared
    /// @param callData The call data
    /// @param validator The validator address
    /// @return userOp The prepared user operation
    function buildUserOpWithCalldata(
        Vm.Wallet memory wallet,
        bytes memory callData,
        address validator
    ) internal view returns (PackedUserOperation memory userOp) {
        address payable account = calculateAccountAddress(wallet.addr, validator);
        uint256 nonce = getNonce(account, validator);
        userOp = buildPackedUserOp(account, nonce);
        userOp.callData = callData;

        bytes memory signature = signUserOp(wallet, userOp);
        userOp.signature = signature;
    }

    /// @notice Retrieves the nonce for a given account and validator
    /// @param account The account address
    /// @param validator The validator address
    /// @return nonce The retrieved nonce
    function getNonce(address account, address validator) internal view returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(address(validator))));
        nonce = ENTRYPOINT.getNonce(address(account), key);
    }

    /// @notice Signs a user operation
    /// @param wallet The wallet to sign the operation
    /// @param userOp The user operation to sign
    /// @return The signed user operation
    function signUserOp(Vm.Wallet memory wallet, PackedUserOperation memory userOp) internal view returns (bytes memory) {
        bytes32 opHash = ENTRYPOINT.getUserOpHash(userOp);
        return signMessage(wallet, opHash);
    }

    /// @notice Modifies the address of a deployed contract in a test environment
    /// @param originalAddress The original address of the contract
    /// @param newAddress The new address to replace the original
    function changeContractAddress(address originalAddress, address newAddress) internal {
        vm.etch(newAddress, originalAddress.code);
    }

    /// @notice Builds a user operation struct for account abstraction tests
    /// @param sender The sender address
    /// @param nonce The nonce
    /// @return userOp The built user operation
    function buildPackedUserOp(address sender, uint256 nonce) internal pure returns (PackedUserOperation memory) {
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(abi.encodePacked(uint128(3e6), uint128(3e6))),
            preVerificationGas: 3e6,
            gasFees: bytes32(abi.encodePacked(uint128(3e6), uint128(3e6))),
            paymasterAndData: "",
            signature: ""
        });
    }

    /// @notice Signs a message and packs r, s, v into bytes
    /// @param wallet The wallet to sign the message
    /// @param messageHash The hash of the message to sign
    /// @return signature The packed signature
    function signMessage(Vm.Wallet memory wallet, bytes32 messageHash) internal pure returns (bytes memory signature) {
        bytes32 userOpHash = ECDSA.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet.privateKey, userOpHash);
        signature = abi.encodePacked(r, s, v);
    }

    /// @notice Prepares a packed user operation with specified parameters
    /// @param signer The wallet to sign the operation
    /// @param account The Nexus account
    /// @param execType The execution type
    /// @param executions The executions to include
    /// @param validator The validator address
    /// @return userOps The prepared packed user operations
    function buildPackedUserOperation(
        Vm.Wallet memory signer,
        Nexus account,
        ExecType execType,
        Execution[] memory executions,
        address validator
    ) internal view returns (PackedUserOperation[] memory userOps) {
        require(execType == EXECTYPE_DEFAULT || execType == EXECTYPE_TRY, "Invalid ExecType");

        ExecutionMode mode;
        bytes memory executionCalldata;
        uint256 length = executions.length;

        if (length == 1) {
            mode = (execType == EXECTYPE_DEFAULT) ? ModeLib.encodeSimpleSingle() : ModeLib.encodeTrySingle();
            executionCalldata = abi.encodeCall(
                Nexus.execute,
                (mode, ExecLib.encodeSingle(executions[0].target, executions[0].value, executions[0].callData))
            );
        } else if (length > 1) {
            mode = (execType == EXECTYPE_DEFAULT) ? ModeLib.encodeSimpleBatch() : ModeLib.encodeTryBatch();
            executionCalldata = abi.encodeCall(Nexus.execute, (mode, ExecLib.encodeBatch(executions)));
        } else {
            revert("Executions array cannot be empty");
        }

        userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(address(account), getNonce(address(account), validator));
        userOps[0].callData = executionCalldata;

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(signer, userOpHash);

        return userOps;
    }

    /// @notice Checks if an address is a contract
    /// @param account The address to check
    /// @return True if the address is a contract, false otherwise
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /// @notice Returns a random non-zero address
    /// @return result A random non-zero address
    function randomNonZeroAddress() internal returns (address result) {
        do {
            result = address(uint160(random()));
        } while (result == address(0));
    }

    /// @dev credits: vectorized || solady
    /// @notice Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive)
    /// @return r A pseudorandom random number
    function random() internal returns (uint256 r) {
        assembly {
            let sSlot := 0xd715531fe383f818c5f158c342925dcf01b954d24678ada4d07c36af0f20e1ee
            let sValue := sload(sSlot)

            mstore(0x20, sValue)
            r := keccak256(0x20, 0x40)

            if iszero(sValue) {
                sValue := sSlot
                let m := mload(0x40)
                calldatacopy(m, 0, calldatasize())
                r := keccak256(m, calldatasize())
            }
            sstore(sSlot, add(r, 1))

            for {} 1 {} {
                let d := byte(0, r)
                if iszero(d) {
                    r := and(r, 3)
                    break
                }
                if iszero(and(2, d)) {
                    let t := xor(not(0), mul(iszero(and(4, d)), not(xor(sValue, r))))
                    switch and(8, d)
                    case 0 {
                        if iszero(and(16, d)) { t := 1 }
                        r := add(shl(shl(3, and(byte(3, r), 0x1f)), t), sub(and(r, 7), 3))
                    }
                    default {
                        if iszero(and(16, d)) { t := shl(255, 1) }
                        r := add(shr(shl(3, and(byte(3, r), 0x1f)), t), sub(and(r, 7), 3))
                    }
                    if iszero(and(0x20, d)) { r := not(r) }
                    break
                }
                r := xor(sValue, r)
                break
            }
        }
    }

    /// @notice Pre-funds a smart account and asserts success
    /// @param sa The smart account address
    /// @param prefundAmount The amount to pre-fund
    function prefundSmartAccountAndAssertSuccess(address sa, uint256 prefundAmount) internal {
        (bool res, ) = sa.call{ value: prefundAmount }(""); // Pre-funding the account contract
        assertTrue(res, "Pre-funding account should succeed");
    }

    /// @notice Prepares a single execution
    /// @param to The target address
    /// @param value The value to send
    /// @param data The call data
    /// @return execution The prepared execution array
    function prepareSingleExecution(address to, uint256 value, bytes memory data) internal pure returns (Execution[] memory execution) {
        execution = new Execution[](1);
        execution[0] = Execution(to, value, data);
    }

    /// @notice Prepares several identical executions
    /// @param execution The execution to duplicate
    /// @param executionsNumber The number of executions to prepare
    /// @return executions The prepared executions array
    function prepareSeveralIdenticalExecutions(Execution memory execution, uint256 executionsNumber) internal pure returns (Execution[] memory) {
        Execution[] memory executions = new Execution[](executionsNumber);
        for (uint256 i = 0; i < executionsNumber; i++) {
            executions[i] = execution;
        }
        return executions;
    }

    /// @notice Handles a user operation and measures gas usage
    /// @param userOps The user operations to handle
    /// @param refundReceiver The address to receive the gas refund
    /// @return gasUsed The amount of gas used
    function handleUserOpAndMeasureGas(PackedUserOperation[] memory userOps, address refundReceiver) internal returns (uint256 gasUsed) {
        uint256 gasStart = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(refundReceiver));
        gasUsed = gasStart - gasleft();
    }
}
