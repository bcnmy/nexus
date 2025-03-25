// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { NexusTest_Base } from "../../../utils/NexusTest_Base.t.sol";
import "../../../utils/Imports.sol";
import { MockTarget } from "contracts/mocks/MockTarget.sol";
import { LibRLP } from "solady/utils/LibRLP.sol";
import { EfficientHashLib } from "solady/utils/EfficientHashLib.sol";
import { LibPREP } from "lib-prep/LibPREP.sol";
import { IExecutionHelper } from "contracts/interfaces/base/IExecutionHelper.sol";

contract TestPREP is NexusTest_Base {

    event PREPInitialized(bytes32 r);
    
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
        BootstrapConfig[] memory validators = BootstrapLib.createArrayConfig(address(mockValidator), abi.encodePacked(BOB_ADDRESS)); // set BOB as signer in the validator
        BootstrapConfig[] memory executors = BootstrapLib.createArrayConfig(address(mockExecutor), "");
        BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(0), "");
        BootstrapConfig[] memory fallbacks = BootstrapLib.createArrayConfig(address(0), "");

        return BOOTSTRAPPER.getInitNexusCalldata(validators, executors, hook, fallbacks, REGISTRY, ATTESTERS, THRESHOLD);
    }

    function test_PREP_Initialization_Success(uint256 valueToSet) public {
        valueToSet = bound(valueToSet, 0, 77e18);
        bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, valueToSet);    

        bytes memory initData = _getInitData();
        bytes32 initDataHash = keccak256(abi.encodePacked(initData));

        (bytes32 saltAndDelegation, address prep) = _mine(initDataHash, valueToSet);

        bytes32 r = LibPREP.rPREP(prep, initDataHash, saltAndDelegation);

        // We can not use vm.attachDelegation by foundry because it
        // uses 31337 as chainId in the 7702 auth tuple and it can not be altered.
        // as signedDelegation struct doesn't have a chainId field.
        // vm.attachDelegation(signedDelegation);        
        _doEIP7702(prep);
        assertEq(LibPREP.isPREP(prep, r), true);
        vm.deal(prep, 100 ether);

        // Initialize PREP with the first userOp
        uint256 nonce = getNonce(prep, MODE_PREP, address(mockValidator), 0);

        // Create the userOp and add the data
        PackedUserOperation memory userOp = buildPackedUserOp(address(prep), nonce);
        userOp.callData = abi.encodeCall(IExecutionHelper.execute, (ModeLib.encodeSimpleSingle(), ExecLib.encodeSingle(address(target), uint256(0), setValueOnTarget)));
        userOp.signature = signUserOp(BOB, userOp);

        // add prep data to signature 
        userOp.signature = abi.encode(saltAndDelegation, initData, userOp.signature);

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        
        vm.expectEmit(address(prep));
        emit PREPInitialized(r);
        ENTRYPOINT.handleOps(userOps, payable(address(0x69)));

        // Assert that the value was set ie that execution was successful
        assertTrue(target.value() == valueToSet);        
    }

    function test_PREP_Initialization_Success_DefaultValidator(uint256 valueToSet) public {
        valueToSet = bound(valueToSet, 0, 77e18);
        bytes memory setValueOnTarget = abi.encodeCall(MockTarget.setValue, valueToSet); 

        bytes memory initData = abi.encodeWithSelector(NexusBootstrap.initNexusWithDefaultValidator.selector, abi.encodePacked(BOB_ADDRESS));
        initData = abi.encode(address(BOOTSTRAPPER), initData);
        bytes32 initDataHash = keccak256(abi.encodePacked(initData));

        (bytes32 saltAndDelegation, address prep) = _mine(initDataHash, 0);
        bytes32 r = LibPREP.rPREP(prep, initDataHash, saltAndDelegation);

        _doEIP7702(prep);
        assertEq(LibPREP.isPREP(prep, r), true);
        vm.deal(prep, 100 ether);

        // Initialize PREP with the first userOp
        uint256 nonce = getNonce(prep, MODE_PREP, address(0), 0);

        PackedUserOperation memory userOp = buildPackedUserOp(address(prep), nonce);
        userOp.callData = abi.encodeCall(IExecutionHelper.execute, (ModeLib.encodeSimpleSingle(), ExecLib.encodeSingle(address(target), uint256(0), setValueOnTarget)));
        userOp.signature = signUserOp(BOB, userOp);

        // add prep data to signature 
        userOp.signature = abi.encode(saltAndDelegation, initData, userOp.signature);

        // Create userOps array
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        vm.expectEmit(address(prep));
        emit PREPInitialized(r);
        ENTRYPOINT.handleOps(userOps, payable(address(0x69)));

        // Assert that the value was set ie that execution was successful
        assertTrue(target.value() == valueToSet);        
    }

    function _mine(bytes32 digest, uint256 randomnessSalt) internal returns (bytes32 saltAndDelegation, address prep) {
        bytes32 saltRandomnessSeed = EfficientHashLib.hash(uint256(0xa11cedecaf), randomnessSalt);
        bytes32 h = EfficientHashLib.hash(_rlpEncodeAuth(uint256(0), address(ACCOUNT_IMPLEMENTATION), 0));
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
