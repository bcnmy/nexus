// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";
import { TokenWithPermit } from "../../../../../contracts/mocks/TokenWithPermit.sol";

/// @title TestERC1271Account_MockProtocol
/// @notice This contract tests the ERC1271 signature validation with a mock protocol and mock validator.
contract TestERC1271Account_MockProtocol is NexusTest_Base {
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
    bytes32 internal domainSepB;
    TokenWithPermit public permitToken;

    /// @notice Sets up the testing environment and initializes the permit token.
    function setUp() public {
        init();
        permitToken = new TokenWithPermit("TestToken", "TST");
        domainSepB = permitToken.DOMAIN_SEPARATOR();
    }

    /// @notice Tests the validation of a signature using EIP-712 with the mock protocol and mock validator.
    function test_isValidSignature_EIP712Sign_Success() public {
        TestTemps memory t;
        t.contents = keccak256(
            abi.encode(
                permitToken.PERMIT_TYPEHASH_LOCAL(),
                address(ALICE_ACCOUNT),
                address(0x69),
                1e18,
                permitToken.nonces(address(ALICE_ACCOUNT)),
                block.timestamp
            )
        );
        (t.v, t.r, t.s) = vm.sign(ALICE.privateKey, toERC1271Hash(t.contents, payable(address(ALICE_ACCOUNT))));
        bytes memory contentsType = "Contents(bytes32 stuff)";
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v, domainSepB, t.contents, contentsType, uint16(contentsType.length));
        bytes memory completeSignature = abi.encodePacked(address(VALIDATOR_MODULE), signature);
        bytes4 ret = ALICE_ACCOUNT.isValidSignature(toContentsHash(t.contents), completeSignature);
        assertEq(ret, bytes4(0x1626ba7e));
        permitToken.permitWith1271(address(ALICE_ACCOUNT), address(0x69), 1e18, block.timestamp, completeSignature);
        assertEq(permitToken.allowance(address(ALICE_ACCOUNT), address(0x69)), 1e18);
    }

    /// @notice Tests the failure of signature validation due to an incorrect signer.
    function test_RevertWhen_SignatureIsInvalidDueToWrongSigner() public {
        TestTemps memory t;
        t.contents = keccak256(
            abi.encode(
                permitToken.PERMIT_TYPEHASH_LOCAL(),
                address(ALICE_ACCOUNT),
                address(0x69),
                1e18,
                permitToken.nonces(address(ALICE_ACCOUNT)),
                block.timestamp
            )
        );
        (t.v, t.r, t.s) = vm.sign(BOB.privateKey, toERC1271Hash(t.contents, payable(address(ALICE_ACCOUNT))));
        bytes memory contentsType = "Contents(bytes32 stuff)";
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v, domainSepB, t.contents, contentsType, uint16(contentsType.length));
        bytes memory completeSignature = abi.encodePacked(address(VALIDATOR_MODULE), signature);

        vm.expectRevert(abi.encodeWithSelector(ERC1271InvalidSigner.selector, address(ALICE_ACCOUNT)));
        permitToken.permitWith1271(address(ALICE_ACCOUNT), address(0x69), 1e18, block.timestamp, completeSignature);

        assertEq(permitToken.allowance(address(ALICE_ACCOUNT), address(0x69)), 0);
    }

    /// @notice Tests the failure of signature validation due to signing the wrong allowance.
    function test_RevertWhen_SignatureIsInvalidDueToWrongAllowance() public {
        TestTemps memory t;
        t.contents = keccak256(
            abi.encode(
                permitToken.PERMIT_TYPEHASH_LOCAL(),
                address(ALICE_ACCOUNT),
                address(0x69),
                1e6,
                permitToken.nonces(address(ALICE_ACCOUNT)),
                block.timestamp
            )
        );
        (t.v, t.r, t.s) = vm.sign(BOB.privateKey, toERC1271Hash(t.contents, payable(address(ALICE_ACCOUNT))));
        bytes memory contentsType = "Contents(bytes32 stuff)";
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v, domainSepB, t.contents, contentsType, uint16(contentsType.length));
        bytes memory completeSignature = abi.encodePacked(address(VALIDATOR_MODULE), signature);

        vm.expectRevert(abi.encodeWithSelector(ERC1271InvalidSigner.selector, address(ALICE_ACCOUNT)));
        permitToken.permitWith1271(address(ALICE_ACCOUNT), address(0x69), 1e18, block.timestamp, completeSignature);

        assertEq(permitToken.allowance(address(ALICE_ACCOUNT), address(0x69)), 0);
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

    /// @notice Converts the contents hash to an EIP-712 hash.
    /// @param contents The contents hash.
    /// @return digest The EIP-712 hash.
    function toContentsHash(bytes32 contents) internal view returns (bytes32 digest) {
        return keccak256(abi.encodePacked(hex"1901", domainSepB, contents));
    }

    /// @notice Converts the contents hash to an ERC-1271 hash.
    /// @param contents The contents hash.
    /// @param account The address of the account.
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
        return keccak256(abi.encodePacked("\x19\x01", domainSepB, parentStructHash));
    }

    /// @notice Retrieves the EIP-712 domain struct fields.
    /// @param account The address of the account.
    /// @return The EIP-712 domain struct fields encoded.
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
}
