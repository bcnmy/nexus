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
    // Pre-defined roles
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
    IEntryPoint public ENTRYPOINT;
    AccountFactory public FACTORY;
    MockValidator public VALIDATOR_MODULE;
    SmartAccount public ACCOUNT_IMPLEMENTATION;

    function setAddress() public virtual {
        DEPLOYER = newWallet("DEPLOYER");
        DEPLOYER_ADDRESS = DEPLOYER.addr;
        vm.deal(DEPLOYER_ADDRESS, 1000 ether);

        ALICE = newWallet("ALICE");
        ALICE_ADDRESS = ALICE.addr;
        vm.deal(ALICE_ADDRESS, 1000 ether);

        BOB = newWallet("BOB");
        BOB_ADDRESS = BOB.addr;
        vm.deal(BOB_ADDRESS, 1000 ether);

        CHARLIE = newWallet("CHARLIE");
        CHARLIE_ADDRESS = CHARLIE.addr;
        vm.deal(CHARLIE_ADDRESS, 1000 ether);

        BUNDLER = newWallet("BUNDLER");
        BUNDLER_ADDRESS = BUNDLER.addr;
        vm.deal(BUNDLER_ADDRESS, 1000 ether);

        ENTRYPOINT = new EntryPoint();
        changeContractAddress(address(ENTRYPOINT), 0x0000000071727De22E5E9d8BAf0edAc6f37da032);
        ENTRYPOINT = IEntryPoint(0x0000000071727De22E5E9d8BAf0edAc6f37da032);

        ACCOUNT_IMPLEMENTATION = new SmartAccount();

        FACTORY = new AccountFactory(address(ACCOUNT_IMPLEMENTATION));

        VALIDATOR_MODULE = new MockValidator();
    }

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

    function getAccountAddress(address signer) internal view returns (address payable account) {
        bytes memory initData = abi.encodePacked(signer);

        uint256 moduleTypeId = uint256(0);

        uint256 saDeploymentIndex = 0;

        account = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, saDeploymentIndex);

        return account;
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
    function signMessageAndGetSignatureBytes(
        Vm.Wallet memory wallet,
        bytes32 messageHash
    )
        internal
        returns (bytes memory signature)
    {
        bytes32 userOpHash = ECDSA.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet.privateKey, userOpHash);
        signature = abi.encodePacked(r, s, v);
    }

    function createInitCode(
        address ownerAddress,
        bytes4 createAccountSelector
    )
        internal
        view
        returns (bytes memory initCode)
    {
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

    function getNonce(address account, address validator) internal returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(address(validator))));
        nonce = ENTRYPOINT.getNonce(address(account), key);
    }

    function prepareExecutionUserOp(
        Vm.Wallet memory signer,
        SmartAccount account,
        ModeCode mode,
        address target,
        uint256 value,
        bytes memory functionCall
    )
        internal
        returns (PackedUserOperation[] memory userOps)
    {
        bytes memory executionCalldata =
            abi.encodeCall(AccountExecution.execute, (mode, ExecLib.encodeSingle(target, value, functionCall)));

        userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(address(account), getNonce(address(account), address(VALIDATOR_MODULE)));
        userOps[0].callData = executionCalldata;

        // Generating and signing the hash of the user operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessageAndGetSignatureBytes(signer, userOpHash);

        return userOps;
    }

    function prepareBatchExecutionUserOp(
        Vm.Wallet memory signer,
        SmartAccount account,
        ModeCode mode,
        Execution[] memory executions
    )
        internal
        returns (PackedUserOperation[] memory userOps)
    {
        // Encode the call into the calldata for the userOp
        bytes memory executionCalldata =
            abi.encodeCall(AccountExecution.execute, (ModeLib.encodeSimpleBatch(), ExecLib.encodeBatch(executions)));
        // Initializing the userOps array with the same size as the targets array
        userOps = new PackedUserOperation[](1);

        // Building the UserOperation for each execution
        userOps[0] = buildPackedUserOp(address(account), getNonce(address(account), address(VALIDATOR_MODULE)));
        userOps[0].callData = executionCalldata;

        // Generating and attaching the signature for each operation
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signMessageAndGetSignatureBytes(signer, userOpHash);

        return userOps;
    }

    function testHelpers(uint256 a) public {
        a;
    }
}
