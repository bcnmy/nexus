// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { NexusTest_Base } from "../../../utils/NexusTest_Base.t.sol";
import "../../../utils/Imports.sol";
import { MockTarget } from "contracts/mocks/MockTarget.sol";
import { LibRLP } from "solady/utils/LibRLP.sol";
import { EfficientHashLib } from "solady/utils/EfficientHashLib.sol";
import { LibPREP } from "lib-prep/LibPREP.sol";

contract TestPREP is NexusTest_Base {

    uint8 constant MAGIC = 0x05;

    using ECDSA for bytes32;
    using LibRLP for *;

    MockTarget target;
    MockValidator public mockValidator;
    MockExecutor public mockExecutor;

    function setUp() public {
        setupTestEnvironment();
        target = new MockTarget();
        mockValidator = new MockValidator();
        mockExecutor = new MockExecutor();
    }

    function _getInitData() internal view returns (bytes memory) {
        // Create config for initial modules
        BootstrapConfig[] memory validators = BootstrapLib.createArrayConfig(address(mockValidator), "");
        BootstrapConfig[] memory executors = BootstrapLib.createArrayConfig(address(mockExecutor), "");
        BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(0), "");
        BootstrapConfig[] memory fallbacks = BootstrapLib.createArrayConfig(address(0), "");

        return BOOTSTRAPPER.getInitNexusCalldata(validators, executors, hook, fallbacks, REGISTRY, ATTESTERS, THRESHOLD);
    }

    function _getUserOpSignature(uint256 eoaKey, PackedUserOperation memory userOp) internal view returns (bytes memory) {
        bytes32 hash = ENTRYPOINT.getUserOpHash(userOp);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaKey, hash.toEthSignedMessageHash());
        return abi.encodePacked(r, s, v);
    }

    function test_PREP_Initialization_Success() public {

        bytes memory initData = _getInitData();
        bytes32 initDataHash = keccak256(abi.encodePacked(initData));

        (bytes32 saltAndDelegation, address prep) = _mine(initDataHash);

        bytes32 r = LibPREP.rPREP(prep, initDataHash, saltAndDelegation);

        // We can not use vm.attachDelegation by foundry because it
        // uses 31337 as chainId in the 7702 auth tuple and it can not be altered.
        // as signedDelegation struct doesn't have a chainId field.
        // vm.attachDelegation(signedDelegation);        
        _doEIP7702(prep);
        assertEq(LibPREP.isPREP(prep, r), true);

        // Initialize PREP with the first userOp



        
    }

    function _mine(bytes32 digest) internal returns (bytes32 saltAndDelegation, address prep) {
        bytes32 saltRandomnessSeed = bytes32(uint256(0xa11cedecaf));
        
        bytes32 h = keccak256(abi.encodePacked(hex"05", LibRLP.p(uint256(0)).p(address(ACCOUNT_IMPLEMENTATION)).p(uint64(0)).encode()));
        uint96 salt;
        while (true) {
            salt = uint96(uint256(saltRandomnessSeed));
            bytes32 r =
                EfficientHashLib.hash(uint256(digest), salt) & bytes32(uint256(2 ** 160 - 1));
            bytes32 s = EfficientHashLib.hash(r);
            prep = ecrecover(h, 27, r, s);
            if (prep != address(0)) break;
            saltRandomnessSeed = EfficientHashLib.hash(saltRandomnessSeed);
        }
        saltAndDelegation = bytes32((uint256(salt) << 160) | uint160(address(ACCOUNT_IMPLEMENTATION)));
    }

    function test_Auth_RLP_encoding() public {
        uint256 eoaKey = uint256(1010101010101);
    
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(ACCOUNT_IMPLEMENTATION), eoaKey);

        bytes memory rlpAuth = _rlpEncodeAuth(uint256(0x7a69), signedDelegation.implementation, signedDelegation.nonce);

        bytes32 authHash = keccak256(rlpAuth);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaKey, authHash);

        assertEq(r, signedDelegation.r);
        assertEq(s, signedDelegation.s);
    }

    function _rlpEncodeAuth(uint256 chainId, address implementation, uint64 nonce) internal view returns (bytes memory) {
        return abi.encodePacked(hex"05", LibRLP.p(chainId).p(implementation).p(nonce).encode());
    }
}
