// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Imports.sol";
import "./CheatCodes.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { EntryPoint } from "account-abstraction/contracts/core/EntryPoint.sol";

import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { AccountFactory } from "../../../contracts/factory/AccountFactory.sol";
import { MockValidator } from "../../../contracts/mocks/MockValidator.sol";
import { MockExecutor } from "../../../contracts/mocks/MockExecutor.sol";
import { MockHook } from "../../../contracts/mocks/MockHook.sol";
import { MockHandler } from "../../../contracts/mocks/MockHandler.sol";
import { Nexus } from "../../../contracts/Nexus.sol";
import "../../../contracts/lib/ModeLib.sol";
import "../../../contracts/lib/ExecLib.sol";
import "../../../contracts/lib/ModuleTypeLib.sol";

import "solady/src/utils/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "./EventsAndErrors.sol";

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
    MockValidator internal VALIDATOR_MODULE;
    MockExecutor internal EXECUTOR_MODULE;
    MockHook internal HOOK_MODULE;
    MockHandler internal HANDLER_MODULE;
    Nexus internal ACCOUNT_IMPLEMENTATION;

    // -----------------------------------------
    // Setup Functions
    // -----------------------------------------
    function initializeTestingEnvironment() internal virtual {
        /// Initializes the testing environment
        initializeWallets();
        deployContracts();
        deployAccounts();
    }

    function createAndFundWallet(string memory name, uint256 amount) internal returns (Vm.Wallet memory) {
        Vm.Wallet memory wallet = newWallet(name);
        vm.deal(wallet.addr, amount);
        return wallet;
    }

    function initializeWallets() internal {
        DEPLOYER = createAndFundWallet("DEPLOYER", 1000 ether);
        ALICE = createAndFundWallet("ALICE", 1000 ether);
        BOB = createAndFundWallet("BOB", 1000 ether);
        CHARLIE = createAndFundWallet("CHARLIE", 1000 ether);
        BUNDLER = createAndFundWallet("BUNDLER", 1000 ether);
    }

    function deployContracts() internal {
        ENTRYPOINT = new EntryPoint();
        changeContractAddress(address(ENTRYPOINT), 0x0000000071727De22E5E9d8BAf0edAc6f37da032);
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
    function deployAccount(Vm.Wallet memory wallet, uint256 deposit) internal returns (Nexus) {
        address payable accountAddress = calculateAccountAddress(wallet.addr, address(VALIDATOR_MODULE));
        bytes memory initCode = prepareInitCode(wallet.addr);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = prepareUserOpWithInitAndCalldata(wallet, initCode, "");

        ENTRYPOINT.depositTo{ value: deposit }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(wallet.addr));
        assertTrue(VALIDATOR_MODULE.isOwner(accountAddress, wallet.addr));
        return Nexus(accountAddress);
    }

    function deployAccountWithCustomValidator(Vm.Wallet memory wallet, uint256 deposit, address validator) internal returns (Nexus) {
        address payable accountAddress = calculateAccountAddress(wallet.addr, validator);
        bytes memory initCode = prepareInitCodeWithCustomValidator(wallet.addr, validator);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = prepareUserOpWithInitAndCalldataWithCustomValidator(wallet, initCode, "", validator);

        ENTRYPOINT.depositTo{ value: deposit }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(wallet.addr));
        assertTrue(MockValidator(validator).isOwner(accountAddress, wallet.addr));
        return Nexus(accountAddress);
    }

    function deployAccounts() internal {
        BOB_ACCOUNT = deployAccount(BOB, 100 ether);
        labelAddress(address(BOB_ACCOUNT), "BOB_ACCOUNT");
        ALICE_ACCOUNT = deployAccount(ALICE, 100 ether);
        labelAddress(address(ALICE_ACCOUNT), "ALICE_ACCOUNT");
        CHARLIE_ACCOUNT = deployAccount(CHARLIE, 100 ether);
        labelAddress(address(CHARLIE_ACCOUNT), "CHARLIE_ACCOUNT");
    }

    function calculateAccountAddress(address owner, address validator) internal view returns (address payable account) {
        bytes memory initData = abi.encodePacked(owner);

        uint256 saDeploymentIndex = 0;

        account = FACTORY.getCounterFactualAddress(address(validator), initData, saDeploymentIndex);

        return account;
    }

    function prepareInitCode(address ownerAddress) internal view returns (bytes memory initCode) {
        address module = address(VALIDATOR_MODULE);
        uint256 saDeploymentIndex = 0;
        bytes memory moduleInitData = abi.encodePacked(ownerAddress);

        // Prepend the factory address to the encoded function call to form the initCode
        initCode = abi.encodePacked(
            address(FACTORY),
            abi.encodeWithSelector(FACTORY.createAccount.selector, module, moduleInitData, saDeploymentIndex)
        );
    }

    function prepareInitCodeWithCustomValidator(address ownerAddress, address validator) internal view returns (bytes memory initCode) {
        address module = address(validator);
        uint256 saDeploymentIndex = 0;
        bytes memory moduleInitData = abi.encodePacked(ownerAddress);

        // Prepend the factory address to the encoded function call to form the initCode
        initCode = abi.encodePacked(
            address(FACTORY),
            abi.encodeWithSelector(FACTORY.createAccount.selector, module, moduleInitData, saDeploymentIndex)
        );
    }

    function prepareUserOpWithInitAndCalldata(
        Vm.Wallet memory wallet,
        bytes memory initCode,
        bytes memory callData
    ) internal view returns (PackedUserOperation memory userOp) {
        userOp = prepareUserOpWithCalldata(wallet, callData);
        userOp.initCode = initCode;

        bytes memory signature = signUserOp(wallet, userOp);
        userOp.signature = signature;
    }

    function prepareUserOpWithInitAndCalldataWithCustomValidator(
        Vm.Wallet memory wallet,
        bytes memory initCode,
        bytes memory callData,
        address validator
    ) internal view returns (PackedUserOperation memory userOp) {
        userOp = prepareUserOpWithCalldataWithCustomValidator(wallet, callData, validator);
        userOp.initCode = initCode;

        bytes memory signature = signUserOp(wallet, userOp);
        userOp.signature = signature;
    }

    function prepareUserOpWithCalldata(Vm.Wallet memory wallet, bytes memory callData) internal view returns (PackedUserOperation memory userOp) {
        address payable account = calculateAccountAddress(wallet.addr, address(VALIDATOR_MODULE));
        uint256 nonce = getNonce(account, address(VALIDATOR_MODULE));
        userOp = buildPackedUserOp(account, nonce);
        userOp.callData = callData;

        bytes memory signature = signUserOp(wallet, userOp);
        userOp.signature = signature;
    }

    function prepareUserOpWithCalldataWithCustomValidator(
        Vm.Wallet memory wallet,
        bytes memory callData,
        address validator
    ) internal view returns (PackedUserOperation memory userOp) {
        address payable account = calculateAccountAddress(wallet.addr, address(validator));
        uint256 nonce = getNonce(account, address(validator));
        userOp = buildPackedUserOp(account, nonce);
        userOp.callData = callData;

        bytes memory signature = signUserOp(wallet, userOp);
        userOp.signature = signature;
    }

    function getNonce(address account, address validator) internal view returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(address(validator))));
        nonce = ENTRYPOINT.getNonce(address(account), key);
    }

    function signUserOp(Vm.Wallet memory wallet, PackedUserOperation memory userOp) internal view returns (bytes memory) {
        bytes32 opHash = ENTRYPOINT.getUserOpHash(userOp);
        return signMessage(wallet, opHash);
    }

    // -----------------------------------------
    // Utility Functions
    // -----------------------------------------

    // Helper to modify the address of a deployed contract in a test environment
    function changeContractAddress(address originalAddress, address newAddress) internal {
        setContractCode(originalAddress, originalAddress.code);
        setContractCode(newAddress, originalAddress.code);
    }

    // Helper to build a user operation struct for account abstraction tests
    function buildPackedUserOp(address sender, uint256 nonce) internal pure returns (PackedUserOperation memory) {
        return
            PackedUserOperation({
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

    // Utility method to encode and sign a message, then pack r, s, v into bytes
    function signMessage(Vm.Wallet memory wallet, bytes32 messageHash) internal pure returns (bytes memory signature) {
        bytes32 userOpHash = ECDSA.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet.privateKey, userOpHash);
        signature = abi.encodePacked(r, s, v);
    }

    function prepareUserOperation(
        Vm.Wallet memory signer,
        Nexus account,
        ExecType execType,
        Execution[] memory executions
    ) internal view returns (PackedUserOperation[] memory userOps) {
        // Validate execType
        require(execType == EXECTYPE_DEFAULT || execType == EXECTYPE_TRY, "Invalid ExecType");

        // Determine mode and calldata based on callType and executions length
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

        // Initialize the userOps array with one operation
        userOps = new PackedUserOperation[](1);

        // Build the UserOperation
        userOps[0] = buildPackedUserOp(address(account), getNonce(address(account), address(VALIDATOR_MODULE)));
        userOps[0].callData = executionCalldata;

        // Sign the operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(signer, userOpHash);

        return userOps;
    }

    function prepareUserOperationWithCustomValidator(
        Vm.Wallet memory signer,
        Nexus account,
        ExecType execType,
        Execution[] memory executions,
        address validator
    ) internal view returns (PackedUserOperation[] memory userOps) {
        // Validate execType
        require(execType == EXECTYPE_DEFAULT || execType == EXECTYPE_TRY, "Invalid ExecType");

        // Determine mode and calldata based on callType and executions length
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

        // Initialize the userOps array with one operation
        userOps = new PackedUserOperation[](1);

        // Build the UserOperation
        userOps[0] = buildPackedUserOp(address(account), getNonce(address(account), address(validator)));
        userOps[0].callData = executionCalldata;

        // Sign the operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(signer, userOpHash);

        return userOps;
    }

    function bytesEqual(bytes memory a, bytes memory b) internal pure returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;

        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function test() public pure {
        // This function is used to ignore file in coverage report
    }
}
