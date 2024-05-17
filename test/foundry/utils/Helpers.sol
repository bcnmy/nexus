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
    function setupTestEnvironment() internal virtual {
        /// Initializes the testing environment
        setupPredefinedWallets();
        deployTestContracts();
        deployNexusForPredefinedWallets();
    }

    function createAndFundWallet(string memory name, uint256 amount) internal returns (Vm.Wallet memory) {
        Vm.Wallet memory wallet = newWallet(name);
        vm.deal(wallet.addr, amount);
        return wallet;
    }

    function setupPredefinedWallets() internal {
        DEPLOYER = createAndFundWallet("DEPLOYER", 1000 ether);
        ALICE = createAndFundWallet("ALICE", 1000 ether);
        BOB = createAndFundWallet("BOB", 1000 ether);
        CHARLIE = createAndFundWallet("CHARLIE", 1000 ether);
        BUNDLER = createAndFundWallet("BUNDLER", 1000 ether);
    }

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

    function deployNexus(Vm.Wallet memory wallet, uint256 deposit, address validator) internal returns (Nexus) {
        address payable accountAddress = calculateAccountAddress(wallet.addr, validator);
        bytes memory initCode = buildInitCode(wallet.addr, validator);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithInitAndCalldata(wallet, initCode, "", validator);

        ENTRYPOINT.depositTo{ value: deposit }(address(accountAddress));
        ENTRYPOINT.handleOps(userOps, payable(wallet.addr));
        assertTrue(MockValidator(validator).isOwner(accountAddress, wallet.addr));
        return Nexus(accountAddress);
    }

    function deployNexusForPredefinedWallets() internal {
        BOB_ACCOUNT = deployNexus(BOB, 100 ether, address(VALIDATOR_MODULE));
        vm.label(address(BOB_ACCOUNT), "BOB_ACCOUNT");
        ALICE_ACCOUNT = deployNexus(ALICE, 100 ether, address(VALIDATOR_MODULE));
        vm.label(address(ALICE_ACCOUNT), "ALICE_ACCOUNT");
        CHARLIE_ACCOUNT = deployNexus(CHARLIE, 100 ether, address(VALIDATOR_MODULE));
        vm.label(address(CHARLIE_ACCOUNT), "CHARLIE_ACCOUNT");
    }

    function calculateAccountAddress(address owner, address validator) internal view returns (address payable account) {
        bytes memory initData = abi.encodePacked(owner);

        uint256 saDeploymentIndex = 0;

        account = FACTORY.getCounterFactualAddress(address(validator), initData, saDeploymentIndex);

        return account;
    }

    function buildInitCode(address ownerAddress, address validator) internal view returns (bytes memory initCode) {
        address module = address(validator);
        uint256 saDeploymentIndex = 0;
        bytes memory moduleInitData = abi.encodePacked(ownerAddress);

        // Prepend the factory address to the encoded function call to form the initCode
        initCode = abi.encodePacked(
            address(FACTORY),
            abi.encodeWithSelector(FACTORY.createAccount.selector, module, moduleInitData, saDeploymentIndex)
        );
    }

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


    function buildUserOpWithCalldata(
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

    function buildPackedUserOperation(
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

    /// @dev Returns a random non-zero address.
    function _randomNonZeroAddress() internal returns (address result) {
        do {
            result = address(uint160(_random()));
        } while (result == address(0));
    }

    /// @dev credits: vectorized || solady
    /// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive).
    /// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument.
    /// e.g. `testSomething(uint256) public`.
    function _random() internal returns (uint256 r) {
        /// @solidity memory-safe-assembly
        assembly {
            // This is the keccak256 of a very long string I randomly mashed on my keyboard.
            let sSlot := 0xd715531fe383f818c5f158c342925dcf01b954d24678ada4d07c36af0f20e1ee
            let sValue := sload(sSlot)

            mstore(0x20, sValue)
            r := keccak256(0x20, 0x40)

            // If the storage is uninitialized, initialize it to the keccak256 of the calldata.
            if iszero(sValue) {
                sValue := sSlot
                let m := mload(0x40)
                calldatacopy(m, 0, calldatasize())
                r := keccak256(m, calldatasize())
            }
            sstore(sSlot, add(r, 1))

            // Do some biased sampling for more robust tests.
            // prettier-ignore
            for {} 1 {} {
                let d := byte(0, r)
                // With a 1/256 chance, randomly set `r` to any of 0,1,2.
                if iszero(d) {
                    r := and(r, 3)
                    break
                }
                // With a 1/2 chance, set `r` to near a random power of 2.
                if iszero(and(2, d)) {
                    // Set `t` either `not(0)` or `xor(sValue, r)`.
                    let t := xor(not(0), mul(iszero(and(4, d)), not(xor(sValue, r))))
                    // Set `r` to `t` shifted left or right by a random multiple of 8.
                    switch and(8, d)
                    case 0 {
                        if iszero(and(16, d)) { t := 1 }
                        r := add(shl(shl(3, and(byte(3, r), 0x1f)), t), sub(and(r, 7), 3))
                    }
                    default {
                        if iszero(and(16, d)) { t := shl(255, 1) }
                        r := add(shr(shl(3, and(byte(3, r), 0x1f)), t), sub(and(r, 7), 3))
                    }
                    // With a 1/2 chance, negate `r`.
                    if iszero(and(0x20, d)) { r := not(r) }
                    break
                }
                // Otherwise, just set `r` to `xor(sValue, r)`.
                r := xor(sValue, r)
                break
            }
        }
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
