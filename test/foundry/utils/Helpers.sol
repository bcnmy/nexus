// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Imports.sol";
import "./CheatCodes.sol";
import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { EntryPoint } from "account-abstraction/contracts/core/EntryPoint.sol";

import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { AccountFactory } from "../../../contracts/factory/AccountFactory.sol";
import { MockValidator } from "../mocks/MockValidator.sol";
import { SmartAccount } from "../../../contracts/SmartAccount.sol";
import "../../../contracts/lib/ModeLib.sol";
import "../../../contracts/lib/ExecLib.sol";
import "../../../contracts/lib/ModuleTypeLib.sol";

import { AccountExecution } from "../../../contracts/base/AccountExecution.sol";

import "solady/src/utils/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract Helpers is CheatCodes {
    // -----------------------------------------
    // State Variables
    // -----------------------------------------

    Vm.Wallet public DEPLOYER;
    Vm.Wallet public ALICE;
    Vm.Wallet public BOB;
    Vm.Wallet public CHARLIE;
    Vm.Wallet public BUNDLER;

    address public DEPLOYER_ADDRESS;
    address public ALICE_ADDRESS;
    address public BOB_ADDRESS;
    address public CHARLIE_ADDRESS;
    address public BUNDLER_ADDRESS;

    SmartAccount public BOB_ACCOUNT;
    SmartAccount public ALICE_ACCOUNT;
    SmartAccount public CHARLIE_ACCOUNT;

    IEntryPoint public ENTRYPOINT;
    AccountFactory public FACTORY;
    MockValidator public VALIDATOR_MODULE;
    SmartAccount public ACCOUNT_IMPLEMENTATION;

    // -----------------------------------------
    // Setup Functions
    // -----------------------------------------
    function initializeTestingEnvironment() public virtual {
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
        ACCOUNT_IMPLEMENTATION = new SmartAccount();
        FACTORY = new AccountFactory(address(ACCOUNT_IMPLEMENTATION));
        VALIDATOR_MODULE = new MockValidator();
    }

    // -----------------------------------------
    // Account Deployment Functions
    // -----------------------------------------
    function deployAccount(Vm.Wallet memory wallet) public returns (SmartAccount) {
        address payable accountAddress = calculateAccountAddress(wallet.addr);
        bytes memory initCode = prepareInitCode(wallet.addr);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = prepareUserOpWithInit(wallet, initCode, "");

        ENTRYPOINT.depositTo{ value: 100 ether }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(wallet.addr));

        return SmartAccount(accountAddress);
    }

    function deployAccounts() public {
        BOB_ACCOUNT = deployAccount(BOB);
        ALICE_ACCOUNT = deployAccount(ALICE);
        CHARLIE_ACCOUNT = deployAccount(CHARLIE);
    }

    function calculateAccountAddress(address owner) internal view returns (address payable account) {
        bytes memory initData = abi.encodePacked(owner);

        uint256 moduleTypeId = uint256(0);

        uint256 saDeploymentIndex = 0;

        account = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, saDeploymentIndex);

        return account;
    }

    function prepareInitCode(address ownerAddress) internal view returns (bytes memory initCode) {
        address module = address(VALIDATOR_MODULE);
        uint256 moduleTypeId = uint256(0);
        uint256 saDeploymentIndex = 0;
        bytes memory moduleInitData = abi.encodePacked(ownerAddress);

        // Prepend the factory address to the encoded function call to form the initCode
        initCode = abi.encodePacked(
            address(FACTORY),
            abi.encodeWithSelector(FACTORY.createAccount.selector, module, moduleInitData, saDeploymentIndex)
        );
    }

    function prepareUserOp(
        Vm.Wallet memory wallet,
        bytes memory callData
    )
        internal
        returns (PackedUserOperation memory userOp)
    {
        address payable account = calculateAccountAddress(wallet.addr);
        uint256 nonce = getNonce(account, address(VALIDATOR_MODULE));
        userOp = buildPackedUserOp(account, nonce);
        userOp.callData = callData;

        bytes memory signature = signUserOp(wallet, userOp);
        userOp.signature = signature;
    }

    function prepareUserOpWithInit(
        Vm.Wallet memory wallet,
        bytes memory initCode,
        bytes memory callData
    )
        internal
        returns (PackedUserOperation memory userOp)
    {
        userOp = prepareUserOp(wallet, callData);
        userOp.initCode = initCode;

        bytes memory signature = signUserOp(wallet, userOp);
        userOp.signature = signature;
    }

    function getNonce(address account, address validator) internal returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(address(validator))));
        nonce = ENTRYPOINT.getNonce(address(account), key);
    }

    function signUserOp(Vm.Wallet memory wallet, PackedUserOperation memory userOp) internal returns (bytes memory) {
        bytes32 opHash = ENTRYPOINT.getUserOpHash(userOp);
        return signMessage(wallet, opHash);
    }

    // -----------------------------------------
    // Utility Functions
    // -----------------------------------------

    function sendEther(address to, uint256 amount) internal {
        payable(to).transfer(amount);
    }

    function setupContractAs(
        address sender,
        uint256 value,
        bytes memory constructorArgs,
        bytes memory bytecode
    )
        internal
        returns (address)
    {
        startPrank(sender);
        address deployedAddress; // Deploy the contract
        stopPrank();
        return deployedAddress;
    }

    function assertBalance(address addr, uint256 expectedBalance, string memory message) internal {
        require(addr.balance == expectedBalance, message);
    }

    function simulateTimePassing(uint256 nbDays) internal {
        warpTo(block.timestamp + nbDays * 1 days);
    }

    // Helper to modify the address of a deployed contract in a test environment
    function changeContractAddress(address originalAddress, address newAddress) internal {
        setContractCode(originalAddress, address(originalAddress).code);
        setContractCode(newAddress, originalAddress.code);
    }

    // Helper to build a user operation struct for account abstraction tests
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

    // Utility method to encode and sign a message, then pack r, s, v into bytes
    function signMessage(Vm.Wallet memory wallet, bytes32 messageHash) internal returns (bytes memory signature) {
        bytes32 userOpHash = ECDSA.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet.privateKey, userOpHash);
        signature = abi.encodePacked(r, s, v);
    }

    function prepareExecutionUserOp(
        Vm.Wallet memory signer,
        SmartAccount account,
        ExecType execType,
        address target,
        uint256 value,
        bytes memory functionCall
    )
        internal
        returns (PackedUserOperation[] memory userOps)
    {
        ModeCode mode = (execType == ExecType.wrap(0x00)) ? ModeLib.encodeSimpleSingle() : ModeLib.encodeTrySingle();

        bytes memory executionCalldata =
            abi.encodeCall(AccountExecution.execute, (mode, ExecLib.encodeSingle(target, value, functionCall)));

        userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(address(account), getNonce(address(account), address(VALIDATOR_MODULE)));
        userOps[0].callData = executionCalldata;

        // Generating and signing the hash of the user operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(signer, userOpHash);

        return userOps;
    }

    function prepareBatchExecutionUserOp(
        Vm.Wallet memory signer,
        SmartAccount account,
        ExecType execType,
        Execution[] memory executions
    )
        internal
        returns (PackedUserOperation[] memory userOps)
    {
        // Determine the mode based on execType
        ModeCode mode = (execType == ExecType.wrap(0x00)) ? ModeLib.encodeSimpleBatch() : ModeLib.encodeTryBatch();

        // Encode the call into the calldata for the userOp
        bytes memory executionCalldata = abi.encodeCall(AccountExecution.execute, (mode, ExecLib.encodeBatch(executions)));

        // Initializing the userOps array with the same size as the targets array
        userOps = new PackedUserOperation[](1);

        // Building the UserOperation for each execution
        userOps[0] = buildPackedUserOp(address(account), getNonce(address(account), address(VALIDATOR_MODULE)));
        userOps[0].callData = executionCalldata;

        // Generating and attaching the signature for each operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessage(signer, userOpHash);

        return userOps;
    }

    function testHelpers(uint256 a) public {
        a;
    }
}
