// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";

contract TestERC1271Account_IsValidSignature is Test, SmartAccountTestLab {

    struct _TestTemps {
        bytes32 userOpHash;
        bytes32 contents;
        address signer;
        uint256 privateKey;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 missingAccountFunds;
    }


    bytes32 internal constant _PARENT_TYPEHASH =
        0xd61db970ec8a2edc5f9fd31d876abe01b785909acb16dcd4baaf3b434b4c439b;

    bytes32 internal constant _DOMAIN_SEP_B =
        0xa1a044077d7677adbbfa892ded5390979b33993e0e2a457e3f974bbcda53821b;

    bytes32 internal constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;    

    function setUp() public {
        init();
    }

    function test_isValidSignature_PersonalSign_MockValidator_Success() public {
        _TestTemps memory t;
        t.contents = keccak256("123");
        (t.v, t.r, t.s) = vm.sign(ALICE.privateKey, _toERC1271HashPersonalSign(t.contents));
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v);
        assertEq(ALICE_ACCOUNT.isValidSignature(t.contents, abi.encodePacked(address(VALIDATOR_MODULE), signature)), bytes4(0x1626ba7e));

        unchecked {
            uint256 vs = uint256(t.s) | uint256(t.v - 27) << 255;
            signature = abi.encodePacked(t.r, vs);
            assertEq(ALICE_ACCOUNT.isValidSignature(t.contents, abi.encodePacked(address(VALIDATOR_MODULE), signature)), bytes4(0x1626ba7e));
        }
    }

    function test_isValidSignature_EIP712Sign_MockValidator_Success() public {
        _TestTemps memory t;
        t.contents = keccak256("123");
        (t.v, t.r, t.s) = vm.sign(ALICE.privateKey, _toERC1271Hash(t.contents, payable(address(ALICE_ACCOUNT))));
        bytes memory contentsType = "Contents(bytes32 stuff)";
         bytes memory signature = abi.encodePacked(
            t.r, t.s, t.v, _DOMAIN_SEP_B, t.contents, contentsType, uint16(contentsType.length)
        );
        bytes4 ret = ALICE_ACCOUNT.isValidSignature(_toContentsHash(t.contents), abi.encodePacked(address(VALIDATOR_MODULE), signature));
        assertEq(ret, bytes4(0x1626ba7e));

        unchecked {
            uint256 vs = uint256(t.s) | uint256(t.v - 27) << 255;
            signature = abi.encodePacked(
                t.r, vs, _DOMAIN_SEP_B, t.contents, contentsType, uint16(contentsType.length)
            );
            assertEq(
                ALICE_ACCOUNT.isValidSignature(_toContentsHash(t.contents), abi.encodePacked(address(VALIDATOR_MODULE), signature)), bytes4(0x1626ba7e)
            );
        }
    }

    function test_isValidSignature_EIP712Sign_MockValidator_Wrong1271Signer_Fail() public {
         _TestTemps memory t;
        t.contents = keccak256("123");
        (t.v, t.r, t.s) = vm.sign(BOB.privateKey, _toERC1271Hash(t.contents, payable(address(ALICE_ACCOUNT))));
        bytes memory contentsType = "Contents(bytes32 stuff)";
         bytes memory signature = abi.encodePacked(
            t.r, t.s, t.v, _DOMAIN_SEP_B, t.contents, contentsType, uint16(contentsType.length)
        );
        bytes4 ret = ALICE_ACCOUNT.isValidSignature(_toContentsHash(t.contents), abi.encodePacked(address(VALIDATOR_MODULE), signature));
        assertEq(ret, bytes4(0xFFFFFFFF));
    }

    function _toERC1271Hash(bytes32 contents, address payable account) internal view returns (bytes32) {
        bytes32 parentStructHash = keccak256(
            abi.encodePacked(
                abi.encode(
                    keccak256(
                        "TypedDataSign(Contents contents,bytes1 fields,string name,string version,uint256 chainId,address verifyingContract,bytes32 salt,uint256[] extensions)Contents(bytes32 stuff)"
                    ),
                    contents
                ),
                _accountDomainStructFields(account)
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", _DOMAIN_SEP_B, parentStructHash));
    }

    function _toContentsHash(bytes32 contents) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"1901", _DOMAIN_SEP_B, contents));
    }

    function _toERC1271HashPersonalSign(bytes32 childHash) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256(
                    "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                ),
                keccak256("Nexus"),
                keccak256("0.0.1"),
                block.chainid,
                address(ALICE_ACCOUNT)
            )
        );
        bytes32 parentStructHash =
            keccak256(abi.encode(keccak256("PersonalSign(bytes prefixed)"), childHash));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, parentStructHash));
    }

    struct _AccountDomainStruct {
        bytes1 fields;
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
        uint256[] extensions;
    }

    function _accountDomainStructFields(address payable account) internal view returns (bytes memory) {
        _AccountDomainStruct memory t;
        (t.fields, t.name, t.version, t.chainId, t.verifyingContract, t.salt, t.extensions) =
            Nexus(account).eip712Domain();

        return abi.encode(
            t.fields,
            keccak256(bytes(t.name)),
            keccak256(bytes(t.version)),
            t.chainId,
            t.verifyingContract,
            t.salt,
            keccak256(abi.encodePacked(t.extensions))
        );
    }

    // @ TODO
    // other test scenarios
}