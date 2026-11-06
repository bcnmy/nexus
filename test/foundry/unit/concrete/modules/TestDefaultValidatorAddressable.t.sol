// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { NexusTest_Base } from "../../../utils/NexusTest_Base.t.sol";
import "../../../utils/Imports.sol";
import { Nexus } from "contracts/Nexus.sol";
import { BootstrapConfig, BootstrapPreValidationHookConfig } from "contracts/utils/NexusBootstrap.sol";
import { IModuleManagerEventsAndErrors } from "contracts/interfaces/base/IModuleManagerEventsAndErrors.sol";

contract TestDefaultValidatorAddressable is NexusTest_Base {
    Nexus internal k1Account;

    struct AccountDomainStruct {
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
    }

    function toERC1271HashPersonalSign(bytes32 childHash, address account) internal view returns (bytes32) {
        AccountDomainStruct memory t;
        (, t.name, t.version, t.chainId, t.verifyingContract, t.salt,) = EIP712(account).eip712Domain();
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(t.name)),
                keccak256(bytes(t.version)),
                t.chainId,
                t.verifyingContract
            )
        );
        bytes32 parentStructHash = keccak256(abi.encode(keccak256("PersonalSign(bytes prefixed)"), childHash));
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, parentStructHash));
    }

    function setUp() public {
        setupTestEnvironment();

        BootstrapConfig[] memory noConfigs = new BootstrapConfig[](0);
        BootstrapPreValidationHookConfig[] memory noHooks = new BootstrapPreValidationHookConfig[](0);
        BootstrapConfig memory noHook = BootstrapLib.createSingleConfig(address(0), "");

        bytes memory initData = abi.encode(
            address(BOOTSTRAPPER),
            abi.encodeCall(
                BOOTSTRAPPER.initNexusWithDefaultValidatorAndOtherModulesNoRegistry,
                (abi.encodePacked(BOB_ADDRESS), noConfigs, noConfigs, noHook, noConfigs, noHooks)
            )
        );

        k1Account = Nexus(FACTORY.createAccount(initData, bytes32(uint256(0xC1A55))));
        vm.deal(address(k1Account), 10 ether);
    }

    /// @notice Confirms setup: default validator is initialized for k1Account
    function test_DefaultValidator_IsInitialized() public view {
        assertTrue(DEFAULT_VALIDATOR_MODULE.isInitialized(address(k1Account)), "Default validator must be initialized");
    }

    /// @notice ERC-7579 isModuleInstalled returns true for the default validator address
    function test_DefaultValidator_IsModuleInstalled_ReturnsTrue() public view {
        assertTrue(
            k1Account.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(DEFAULT_VALIDATOR_MODULE), ""),
            "Default validator address should report installed via isModuleInstalled"
        );
    }

    /// @notice ERC-1271 isValidSignature validates when prefixed with address(0)
    function test_IsValidSignature_PrefixZero_Success() public view {
        bytes32 originalHash = keccak256(abi.encodePacked("sample message"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, toERC1271HashPersonalSign(originalHash, address(k1Account)));
        bytes memory signedMessage = abi.encodePacked(r, s, v);
        bytes memory completeSignature = abi.encodePacked(address(0), signedMessage);

        bytes4 result = k1Account.isValidSignature(originalHash, completeSignature);
        assertEq(result, ERC1271_MAGICVALUE, "Prefix address(0) should return ERC1271_MAGICVALUE");
    }

    /// @notice ERC-1271 isValidSignature validates when prefixed with DEFAULT_VALIDATOR_MODULE address
    function test_IsValidSignature_PrefixDefaultValidator_Success() public view {
        bytes32 originalHash = keccak256(abi.encodePacked("sample message"));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, toERC1271HashPersonalSign(originalHash, address(k1Account)));
        bytes memory signedMessage = abi.encodePacked(r, s, v);
        bytes memory completeSignature = abi.encodePacked(address(DEFAULT_VALIDATOR_MODULE), signedMessage);

        bytes4 result = k1Account.isValidSignature(originalHash, completeSignature);
        assertEq(result, ERC1271_MAGICVALUE, "Prefix default validator should return ERC1271_MAGICVALUE");
    }

    /// @notice validateUserOp succeeds when nonce key carries DEFAULT_VALIDATOR_MODULE address
    function test_ValidateUserOp_WithDefaultValidatorInNonce_Success() public {
        uint256 nonce = getNonce(address(k1Account), MODE_VALIDATION, address(DEFAULT_VALIDATOR_MODULE), bytes3(0));
        PackedUserOperation memory op = buildPackedUserOp(address(k1Account), nonce);
        bytes32 opHash = ENTRYPOINT.getUserOpHash(op);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(BOB.privateKey, opHash);
        op.signature = abi.encodePacked(r, s, v);

        vm.prank(address(ENTRYPOINT));
        uint256 validationData = k1Account.validateUserOp(op, opHash, 0);
        assertEq(validationData, VALIDATION_SUCCESS, "Validation should succeed with default validator in nonce");
    }

    /// @notice uninstallModule rejects removing the default validator
    function test_UninstallDefaultValidator_RevertsCanNotRemoveLastValidator() public {
        bytes memory deInitData = abi.encode(address(1), "");
        vm.prank(address(ENTRYPOINT));
        vm.expectRevert(IModuleManagerEventsAndErrors.CanNotRemoveLastValidator.selector);
        k1Account.uninstallModule(MODULE_TYPE_VALIDATOR, address(DEFAULT_VALIDATOR_MODULE), deInitData);
    }
}
