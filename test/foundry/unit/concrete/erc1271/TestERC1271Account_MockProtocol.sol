// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import { TokenWithPermit } from "../../../../../contracts/mocks/TokenWithPermit.sol";

// some refs
// https://pastebin.com/m6tqJBKh
// https://pastebin.com/EVQxRH3n (just use typedData)
// https://pastebin.com/XjgWxSuG
// https://pastebin.com/y0hncv31

contract TestERC1271Account_MockProtocol is Test, SmartAccountTestLab {

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

    // todo
    bytes32 internal constant _PARENT_TYPEHASH =
        0xd61db970ec8a2edc5f9fd31d876abe01b785909acb16dcd4baaf3b434b4c439b;

    // todo // permit domain separator
    bytes32 internal _DOMAIN_SEP_B;


    TokenWithPermit public permitToken;    

    function setUp() public {
        init();
        permitToken = new TokenWithPermit("TestToken", "TST");
        _DOMAIN_SEP_B = permitToken.DOMAIN_SEPARATOR();
    }

    function test_isValidSignature_EIP712Sign_MockProtocol_MockValidator_Success() public {
        _TestTemps memory t;
        t.contents = keccak256(abi.encode(permitToken.PERMIT_TYPEHASH_LOCAL(), address(ALICE_ACCOUNT), address(0x69), 1e18, permitToken.nonces(address(ALICE_ACCOUNT)), block.timestamp));
        (t.v, t.r, t.s) = vm.sign(ALICE.privateKey, _toERC1271Hash(t.contents, payable(address(ALICE_ACCOUNT))));
        bytes memory contentsType = "Contents(bytes32 stuff)";
        bytes memory signature = abi.encodePacked(
            t.r, t.s, t.v, _DOMAIN_SEP_B, t.contents, contentsType, uint16(contentsType.length)
        );
        bytes memory completeSignature = abi.encodePacked(address(VALIDATOR_MODULE), signature);
        bytes4 ret = ALICE_ACCOUNT.isValidSignature(_toContentsHash(t.contents), completeSignature);
        assertEq(ret, bytes4(0x1626ba7e));
        permitToken.permitWith1271(address(ALICE_ACCOUNT), address(0x69), 1e18, block.timestamp, completeSignature);
        assertEq(permitToken.allowance(address(ALICE_ACCOUNT), address(0x69)), 1e18);
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

    function _toContentsHash(bytes32 contents) internal view returns (bytes32 digest) {
        return keccak256(abi.encodePacked(hex"1901", _DOMAIN_SEP_B, contents));
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