// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";

/// @title TestERC1271Account_IsValidSignature
/// @notice This contract tests the ERC1271 signature validation functionality.
/// @dev Uses MockValidator for testing signature validation.
contract TestERC1271Account_IsValidSignature is NexusTest_Base {
    struct TestTemps {
        bytes32 userOpHash;
        bytes32 contents;
        address signer;
        uint256 privateKey;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 missingAccountFunds;
    }

    bytes32 internal constant PARENT_TYPEHASH = 0xd61db970ec8a2edc5f9fd31d876abe01b785909acb16dcd4baaf3b434b4c439b;
    bytes32 internal constant DOMAIN_SEP_B = 0xa1a044077d7677adbbfa892ded5390979b33993e0e2a457e3f974bbcda53821b;

    /// @notice Initializes the testing environment.
    function setUp() public {
        init();
    }

    /// @notice Tests the validation of a personal signature using the mock validator.
    function test_isValidSignature_PersonalSign_MockValidator_Success() public {
        TestTemps memory t;
        t.contents = keccak256("123");
        (t.v, t.r, t.s) = vm.sign(ALICE.privateKey, toERC1271HashPersonalSign(t.contents));
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v);
        assertEq(ALICE_ACCOUNT.isValidSignature(t.contents, abi.encodePacked(address(VALIDATOR_MODULE), signature)), bytes4(0x1626ba7e));

        unchecked {
            uint256 vs = uint256(t.s) | (uint256(t.v - 27) << 255);
            signature = abi.encodePacked(t.r, vs);
            assertEq(ALICE_ACCOUNT.isValidSignature(t.contents, abi.encodePacked(address(VALIDATOR_MODULE), signature)), bytes4(0x1626ba7e));
        }
    }

    /// @notice Tests the validation of an EIP-712 signature using the mock validator.
    function test_isValidSignature_EIP712Sign_MockValidator_Success() public {
        TestTemps memory t;
        t.contents = keccak256("123");
        (t.v, t.r, t.s) = vm.sign(ALICE.privateKey, toERC1271Hash(t.contents, payable(address(ALICE_ACCOUNT))));
        bytes memory contentsType = "Contents(bytes32 stuff)";
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v, DOMAIN_SEP_B, t.contents, contentsType, uint16(contentsType.length));
        if (random() % 4 == 0) signature = erc6492Wrap(signature);
        bytes4 ret = ALICE_ACCOUNT.isValidSignature(toContentsHash(t.contents), abi.encodePacked(address(VALIDATOR_MODULE), signature));
        assertEq(ret, bytes4(0x1626ba7e));

        unchecked {
            uint256 vs = uint256(t.s) | (uint256(t.v - 27) << 255);
            signature = abi.encodePacked(t.r, vs, DOMAIN_SEP_B, t.contents, contentsType, uint16(contentsType.length));
            assertEq(
                ALICE_ACCOUNT.isValidSignature(toContentsHash(t.contents), abi.encodePacked(address(VALIDATOR_MODULE), signature)),
                bytes4(0x1626ba7e)
            );
        }
    }

    /// @notice Tests the failure of an EIP-712 signature validation due to a wrong signer.
    function test_isValidSignature_EIP712Sign_MockValidator_Wrong1271Signer_Fail() public {
        TestTemps memory t;
        t.contents = keccak256("123");
        (t.v, t.r, t.s) = vm.sign(BOB.privateKey, toERC1271Hash(t.contents, payable(address(ALICE_ACCOUNT))));
        bytes memory contentsType = "Contents(bytes32 stuff)";
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v, DOMAIN_SEP_B, t.contents, contentsType, uint16(contentsType.length));
        bytes4 ret = ALICE_ACCOUNT.isValidSignature(toContentsHash(t.contents), abi.encodePacked(address(VALIDATOR_MODULE), signature));
        assertEq(ret, bytes4(0xFFFFFFFF));
    }

    /// @notice Generates an ERC-1271 hash for the given contents and account.
    /// @param contents The contents hash.
    /// @param account The account address.
    /// @return The ERC-1271 hash.
    function toERC1271Hash(bytes32 contents, address payable account) internal view returns (bytes32) {
        bytes32 parentStructHash = keccak256(
            abi.encodePacked(
                abi.encode(
                    keccak256(
                        "TypedDataSign(Contents contents,bytes1 fields,string name,string version,uint256 chainId,address verifyingContract,bytes32 salt,uint256[] extensions)Contents(bytes32 stuff)"
                    ),
                    contents
                ),
                accountDomainStructFields(account)
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEP_B, parentStructHash));
    }

    /// @notice Generates a contents hash.
    /// @param contents The contents hash.
    /// @return The EIP-712 hash.
    function toContentsHash(bytes32 contents) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(hex"1901", DOMAIN_SEP_B, contents));
    }

    /// @notice Generates an ERC-1271 hash for personal sign.
    /// @param childHash The child hash.
    /// @return The ERC-1271 hash for personal sign.
    function toERC1271HashPersonalSign(bytes32 childHash) internal view returns (bytes32) {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256("Nexus"),
                keccak256("0.0.1"),
                block.chainid,
                address(ALICE_ACCOUNT)
            )
        );
        bytes32 parentStructHash = keccak256(abi.encode(keccak256("PersonalSign(bytes prefixed)"), childHash));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, parentStructHash));
    }

    struct AccountDomainStruct {
        bytes1 fields;
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
        uint256[] extensions;
    }

    /// @notice Retrieves the EIP-712 domain struct fields.
    /// @param account The account address.
    /// @return The encoded EIP-712 domain struct fields.
    function accountDomainStructFields(address payable account) internal view returns (bytes memory) {
        AccountDomainStruct memory t;
        (t.fields, t.name, t.version, t.chainId, t.verifyingContract, t.salt, t.extensions) = Nexus(account).eip712Domain();

        return
            abi.encode(
                t.fields,
                keccak256(bytes(t.name)),
                keccak256(bytes(t.version)),
                t.chainId,
                t.verifyingContract,
                t.salt,
                keccak256(abi.encodePacked(t.extensions))
            );
    }

    /// @notice Generates a random string from given byte choices.
    /// @param byteChoices The bytes to choose from.
    /// @param nonEmpty Whether the result should be non-empty.
    /// @return result The random string.
    function randomString(string memory byteChoices, bool nonEmpty) internal returns (string memory result) {
        uint256 randomness = random();
        uint256 resultLength = _bound(random(), nonEmpty ? 1 : 0, random() % 32 != 0 ? 4 : 128);
        assembly {
            if mload(byteChoices) {
                result := mload(0x40)
                mstore(0x00, randomness)
                mstore(0x40, and(add(add(result, 0x40), resultLength), not(31)))
                mstore(result, resultLength)

                for {
                    let i := 0
                } lt(i, resultLength) {
                    i := add(i, 1)
                } {
                    mstore(0x20, gas())
                    mstore8(add(add(result, 0x20), i), mload(add(add(byteChoices, 1), mod(keccak256(0x00, 0x40), mload(byteChoices)))))
                }
            }
        }
    }

    /// @notice Wraps a signature using ERC-6492 format.
    /// @param signature The original signature.
    /// @return The ERC-6492 wrapped signature.
    function erc6492Wrap(bytes memory signature) internal returns (bytes memory) {
        return
            abi.encodePacked(
                abi.encode(randomNonZeroAddress(), bytes(randomString("12345", false)), signature),
                bytes32(0x6492649264926492649264926492649264926492649264926492649264926492)
            );
    }
}
