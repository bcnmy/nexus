// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24 <0.9.0;

import "./Imports.sol";
import "forge-std/console2.sol";

import { Vm } from "forge-std/Vm.sol";

contract BicoTestBase is PRBTest, Imports {
    enum ModuleType {
        Validation,
        Execution,
        Fallback,
        Hooks
    }

    IEntryPoint entrypoint;

    SmartAccount public implementation;
    SmartAccount public smartAccount;
    AccountFactory public factory;

    MockValidator public mockValidator;

    address target;
    address payable alice;
    address owner;

    function setUp() public virtual {
        implementation = new SmartAccount();
        entrypoint = new EntryPoint();

        factory = new AccountFactory();

        //@TODO: deploy account via Factory and EP
        // smartAccount = new SmartAccount();

        mockValidator = new MockValidator();

        target = address(0x69);
        alice = payable(address(0xa11ce));
        owner = address(0xff);
        vm.deal(address(0xff), 1000 ether);
        vm.deal(address(owner), 1000 ether);
        vm.deal(address(smartAccount), 1000 ether);
    }

    // HELPERS
    function _getNonce(address account, address validator) internal returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(address(validator))));
        nonce = entrypoint.getNonce(address(account), key);
    }

    function testBuildPackedUserOp() public {
        vm.startPrank(owner);
        address signer = owner;
        // IAccountFactory;
        bytes memory tx = abi.encodeWithSignature(
            "createAccount(address,uint256,bytes)", address(mockValidator), uint256(ModuleType.Validation), signer
        );

        bytes memory initCode = abi.encode(address(factory), tx);
        initCode = abi.encodeCall(
            factory.createAccount, (address(mockValidator), uint256(ModuleType.Validation), abi.encodePacked(signer))
        );
        address account = _getAccountAddress(signer);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = PackedUserOperation({
            sender: address(0),
            nonce: _getNonce(account, address(mockValidator)),
            initCode: initCode,
            callData: "",
            accountGasLimits: bytes32(abi.encodePacked(uint128(1e6), uint128(1e6))),
            preVerificationGas: 1e6,
            gasFees: bytes32(abi.encodePacked(uint128(1e6), uint128(1e6))),
            paymasterAndData: "",
            signature: ""
        });

        // bytes32 userOpHash = entrypoint.getUserOpHash(userOps[0]);

        // (uint8 v, bytes32 r, bytes32 s) = vm.sign(signer.privateKey, userOpHash);
        // userOps[0].signature = abi.encodePacked(r, s, v);

        // // bytes memory signedHash = abi.encode(ECDSA.toEthSignedMessageHash(hash));

        // // userOps[0].signature = signedHash;

        // entrypoint.depositTo{ value: 100 ether }(account);
        // // entrypoint.depositTo{value: 1000 ether}(owner);
        // entrypoint.handleOps(userOps, payable(owner));
    }

    function _getAccountAddress(address signer) internal view returns (address account) {
        address factoryAddress = address(factory);
        address mockValidatorAddress = address(mockValidator);
        uint256 moduleType = uint256(ModuleType.Validation);

        (,, account) = _computeAddress(signer, mockValidatorAddress, factoryAddress, moduleType);
    }

    function _computeAddress(
        address signer,
        address mockValidatorAddress,
        address factoryAddress,
        uint256 moduleType
    )
        internal
        view
        returns (bytes memory, bytes32, address)
    {
        bytes memory initData = abi.encodePacked(signer);
        bytes32 salt = keccak256(abi.encodePacked(mockValidatorAddress, moduleType, initData));
        bytes memory bytecode = type(SmartAccount).creationCode;
        address account = Create2.computeAddress(salt, keccak256(bytecode));
        return (bytecode, salt, account);
    }
}

// struct PackedUserOperation {
//     address sender;
//     uint256 nonce;
//     bytes initCode;
//     bytes callData;
//     bytes32 accountGasLimits;
//     uint256 preVerificationGas;
//     bytes32 gasFees;    //maxPriorityFee and maxFeePerGas;
//     bytes paymasterAndData;
//     bytes signature;
// }
