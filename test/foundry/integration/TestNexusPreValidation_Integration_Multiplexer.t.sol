// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../shared/TestModuleManagement_Base.t.sol";
import { MockPreValidationHookMultiplexer } from "../../../contracts/mocks/MockPreValidationHookMultiplexer.sol";
import { MockResourceLockPreValidationHook } from "../../../contracts/mocks/MockResourceLockPreValidationHook.sol";
import { Mock7739PreValidationHook } from "../../../contracts/mocks/Mock7739PreValidationHook.sol";
import { MockAccountLocker } from "../../../contracts/mocks/MockAccountLocker.sol";
import { MockSimpleValidator } from "../../../contracts/mocks/MockSimpleValidator.sol";

/// @title TestNexusPreValidation_Integration_HookMultiplexer
/// @notice This contract tests the integration of the PreValidation hook multiplexer with the PreValidation resource lock hooks
contract TestNexusPreValidation_Integration_HookMultiplexer is TestModuleManagement_Base {
    MockPreValidationHookMultiplexer private hookMultiplexer;
    MockResourceLockPreValidationHook private resourceLockHook;
    Mock7739PreValidationHook private erc7739Hook;
    MockAccountLocker private accountLocker;
    MockSimpleValidator private SIMPLE_VALIDATOR;

    struct TestTemps {
        bytes32 contents;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    bytes32 internal constant APP_DOMAIN_SEPARATOR = 0xa1a044077d7677adbbfa892ded5390979b33993e0e2a457e3f974bbcda53821b;

    function setUp() public {
        setUpModuleManagement_Base();

        // Deploy supporting contracts
        accountLocker = new MockAccountLocker();
        hookMultiplexer = new MockPreValidationHookMultiplexer();
        erc7739Hook = new Mock7739PreValidationHook(address(hookMultiplexer));
        resourceLockHook = new MockResourceLockPreValidationHook(address(accountLocker), address(hookMultiplexer));
        // Deploy the simple validator
        SIMPLE_VALIDATOR = new MockSimpleValidator();
        // Format install data with owner
        bytes memory validatorSetupData = abi.encodePacked(BOB_ADDRESS); // Set BOB as owner
        // Prepare the call data for installing the validator module
        bytes memory callData =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(SIMPLE_VALIDATOR), validatorSetupData);
        // Install validator module using execution
        installModule(callData, MODULE_TYPE_VALIDATOR, address(SIMPLE_VALIDATOR), EXECTYPE_DEFAULT);
        // Prepare calldata for installing the account locker
        bytes memory accountLockerInstallCallData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(accountLocker), "");
        // Install account locker
        installModule(accountLockerInstallCallData, MODULE_TYPE_HOOK, address(accountLocker), EXECTYPE_DEFAULT);
    }

    function test_installMultiplePreValidationHooks() public {
        // Install hooks for 4337
        address[] memory hooks4337 = new address[](1);
        hooks4337[0] = address(resourceLockHook);
        bytes[] memory hookData4337 = new bytes[](1);
        hookData4337[0] = "foo";

        // Install hooks for 1271
        address[] memory hooks1271 = new address[](2);
        hooks1271[0] = address(resourceLockHook);
        hooks1271[1] = address(erc7739Hook);
        bytes[] memory hookData1271 = new bytes[](2);
        hookData1271[0] = "foo";
        hookData1271[1] = "bar";

        // Install 4337 hooks
        bytes memory installData4337 = abi.encode(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, hooks4337, hookData4337);
        bytes memory installCallData4337 =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(hookMultiplexer), installData4337);
        installModule(installCallData4337, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(hookMultiplexer), EXECTYPE_DEFAULT);

        // Install 1271 hooks
        bytes memory installData1271 = abi.encode(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, hooks1271, hookData1271);
        bytes memory installCallData1271 =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(hookMultiplexer), installData1271);
        installModule(installCallData1271, MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(hookMultiplexer), EXECTYPE_DEFAULT);

        // Verify multiplexer is installed for both types
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(hookMultiplexer), ""), "4337 multiplexer should be installed");
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(hookMultiplexer), ""), "1271 multiplexer should be installed");
    }

    function test_1271_HookChaining_MockValidator_Success() public {
        // Install hooks and multiplexer
        test_installMultiplePreValidationHooks();

        // Prepare test data
        TestTemps memory t;
        t.contents = keccak256("test message");

        // Create signature data for personal sign
        bytes32 hashToSign = toERC1271HashPersonalSign(t.contents, address(BOB_ACCOUNT));
        (t.v, t.r, t.s) = vm.sign(BOB.privateKey, hashToSign);

        // Prepare signature with validator prefix and triggering both hooks
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v);
        bytes memory validatorSignature = abi.encodePacked(
            address(VALIDATOR_MODULE),
            bytes1(0x01), // Skip 7739 wrap
            signature
        );

        // Validate signature through hook chain
        bytes4 result = BOB_ACCOUNT.isValidSignature(t.contents, validatorSignature);
        assertEq(result, bytes4(0x1626ba7e), "Signature should be valid after hook chaining");
    }

    function test_1271_HookChaining_MockSimpleValidator_Success() public {
        // Install hooks and multiplexer
        test_installMultiplePreValidationHooks();

        // Prepare test data
        TestTemps memory t;
        t.contents = keccak256("test message");

        // Create signature data for personal sign
        bytes32 hashToSign = toERC1271HashPersonalSign(t.contents, address(BOB_ACCOUNT));
        (t.v, t.r, t.s) = vm.sign(BOB.privateKey, hashToSign);

        // Prepare signature with validator prefix and triggering both hooks
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v);
        bytes memory validatorSignature = abi.encodePacked(address(SIMPLE_VALIDATOR), bytes1(0x00), signature);

        // Validate signature through hook chain
        bytes4 result = BOB_ACCOUNT.isValidSignature(t.contents, validatorSignature);
        assertEq(result, bytes4(0x1626ba7e), "Signature should be valid after hook chaining");
    }

    function test_1271_HookChaining_Fails_WhenResourceLocked() public {
        // Install hooks and multiplexer
        test_installMultiplePreValidationHooks();

        // Lock resources

        MockAccountLocker(accountLocker).setLockedAmount(address(BOB_ACCOUNT), address(this), 1);

        // Prepare test data
        TestTemps memory t;
        t.contents = keccak256("test message");

        // Create signature data
        bytes32 hashToSign = toERC1271HashPersonalSign(t.contents, address(BOB_ACCOUNT));
        (t.v, t.r, t.s) = vm.sign(BOB.privateKey, hashToSign);

        // Prepare signature with validator prefix
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v);
        bytes memory validatorSignature = abi.encodePacked(
            address(VALIDATOR_MODULE),
            bytes1(0x00), // Trigger 7739 wrap
            signature
        );

        // Expect revert due to resource lock
        vm.expectRevert(abi.encodeWithSelector(MockResourceLockPreValidationHook.SenderIsResourceLocked.selector));
        BOB_ACCOUNT.isValidSignature(t.contents, validatorSignature);
    }

    // Helper function to generate ERC-1271 hash for personal sign
    function toERC1271HashPersonalSign(bytes32 childHash, address account) internal view returns (bytes32) {
        AccountDomainStruct memory t;
        (t.fields, t.name, t.version, t.chainId, t.verifyingContract, t.salt, t.extensions) = EIP712(account).eip712Domain();
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

    struct AccountDomainStruct {
        bytes1 fields;
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
        uint256[] extensions;
    }
}
