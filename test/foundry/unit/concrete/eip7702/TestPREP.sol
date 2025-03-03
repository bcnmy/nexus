// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { NexusTest_Base } from "../../../utils/NexusTest_Base.t.sol";
import "../../../utils/Imports.sol";
import { MockTarget } from "contracts/mocks/MockTarget.sol";
import { LibRLP } from "solady/utils/LibRLP.sol";
import { EfficientHashLib } from "solady/utils/EfficientHashLib.sol";

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

    function _doEIP7702(address account) internal {
//        vm.etch(account, abi.encodePacked(bytes3(0xef0100), bytes20(address(ACCOUNT_IMPLEMENTATION))));
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

        /*
        struct SignedDelegation {
    // The y-parity of the recovered secp256k1 signature (0 or 1).
    uint8 v;
    // First 32 bytes of the signature.
    bytes32 r;
    // Second 32 bytes of the signature.
    bytes32 s;
    // The current nonce of the authority account at signing time.
    // Used to ensure signature can't be replayed after account nonce changes.
    uint64 nonce;
    // Address of the contract implementation that will be delegated to.
    // Gets encoded into delegation code: 0xef0100 || implementation.
    address implementation;
}
*/  
        bytes memory initData = _getInitData();
        bytes32 initDataHash = keccak256(abi.encodePacked(initData));

        uint256 eoaKey = uint256(1010101010101);
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(ACCOUNT_IMPLEMENTATION), eoaKey);

        // ================================

        bytes memory rlpAuth = abi.encodePacked(hex"05", LibRLP.p(uint256(0x7a69)).p(signedDelegation.implementation).p(signedDelegation.nonce).encode());
        bytes32 authHash = keccak256(rlpAuth);

        
        //signedDelegation.s = bytes32(uint256(0x0000000000000000000000000000000000000000ffffffffffffffffffffffff)) & keccak256(abi.encodePacked(block.timestamp));

        uint256 i=2**12;
        address prep;
        console2.log(signedDelegation.v);

        while (prep == address(0)) {
            signedDelegation.r = EfficientHashLib.hash(uint256(initDataHash), i) & bytes32(uint256(2 ** 160 - 1));
            //signedDelegation.s = keccak256(abi.encodePacked(initDataHash, i));
            signedDelegation.s = keccak256(abi.encodePacked(signedDelegation.r));
            prep = authHash.tryRecover(signedDelegation.v+27, signedDelegation.r, signedDelegation.s);
            i++;
            console2.log(i);
            console2.log(prep);
        }

        console2.log(prep);        

        vm.attachDelegation(signedDelegation);        


        bytes32 prepCode;
        assembly {
            extcodecopy(prep, prepCode, 0, 23)
        }
        console2.logBytes32(prepCode);        
    }

    function test_Auth_Hash_generation() public {
        uint256 eoaKey = uint256(1010101010101);
    
        Vm.SignedDelegation memory signedDelegation = vm.signDelegation(address(ACCOUNT_IMPLEMENTATION), eoaKey);

        bytes memory auth = abi.encodePacked(
            MAGIC,
            abi.encode(
                uint256(0x7a69),
                signedDelegation.implementation,
                signedDelegation.nonce   
            )
        );

        console2.logBytes(auth);

        bytes memory rlpAuth = abi.encodePacked(hex"05", LibRLP.p(uint256(0x7a69)).p(signedDelegation.implementation).p(signedDelegation.nonce).encode());

        console2.logBytes(rlpAuth);

        bytes32 authHash = keccak256(rlpAuth);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaKey, authHash);

        console2.log("v");
        console2.log(v);

        assertEq(r, signedDelegation.r);
        assertEq(s, signedDelegation.s);
        
        // assertEq(v, signedDelegation.v);
    }
}
