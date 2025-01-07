// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../shared/TestModuleManagement_Base.t.sol";
import { MockResourceLockPreValidationHook } from "../../../contracts/mocks/MockResourceLockPreValidationHook.sol";
import { MockAccountLocker } from "../../../contracts/mocks/MockAccountLocker.sol";

/// @title TestNexusPreValidation_Integration_ResourceLockHooks
/// @notice This contract tests the integration of ResourceLock hook with the PreValidation resource lock hooks
contract TestNexusPreValidation_Integration_ResourceLockHooks is TestModuleManagement_Base {
    MockResourceLockPreValidationHook private resourceLockHook;
    MockAccountLocker private accountLocker;

    address internal constant NATIVE_TOKEN = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    bytes32 internal constant APP_DOMAIN_SEPARATOR = 0xa1a044077d7677adbbfa892ded5390979b33993e0e2a457e3f974bbcda53821b;

    struct TestTemps {
        bytes32 contents;
        address signer;
        uint256 privateKey;
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    function setUp() public {
        setUpModuleManagement_Base();
        accountLocker = new MockAccountLocker();
        resourceLockHook = new MockResourceLockPreValidationHook(address(accountLocker), address(0));
    }

    /// @notice Tests installing the account locker and resource lock hook
    function test_InstallResourceLockHooks() public {
        installResourceLockHooks();
        // Verify hooks are installed
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(resourceLockHook), ""), "Resource lock 4337 hook should be installed"
        );
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(resourceLockHook), ""), "Resource lock 1271 hook should be installed"
        );
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(accountLocker), ""), "Account locker should be installed");
    }

    /// @notice Fuzz test for pre-validation hook when ETH is locked
    /// @param lockedAmount Amount of ETH to lock
    /// @param missingAccountFunds Funds missing from the account
    function testFuzz_4337_PreValidationHook_RevertsWhen_InsufficientUnlockedETH(uint256 lockedAmount, uint256 missingAccountFunds) public {
        // Constrain inputs to reasonable ranges
        vm.assume(lockedAmount > 0);
        vm.assume(missingAccountFunds > 0);

        // Install resource lock hooks
        installResourceLockHooks();

        // Prepare user operation
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithCalldata(BOB, "", address(VALIDATOR_MODULE));

        // Set locked amount to block ETH transactions
        vm.prank(address(accountLocker));
        MockAccountLocker(accountLocker).setLockedAmount(address(BOB_ACCOUNT), NATIVE_TOKEN, lockedAmount);

        // Ensure account has enough total balance
        vm.deal(address(BOB_ACCOUNT), lockedAmount);
        assertTrue(address(BOB_ACCOUNT).balance == lockedAmount, "Account should have correct balance");

        // Calculate user op hash
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Sign the user operation
        userOps[0].signature = signMessage(BOB, userOpHash);

        // Expect revert due to insufficient unlocked ETH
        vm.expectRevert(abi.encodeWithSelector(MockResourceLockPreValidationHook.InsufficientUnlockedETH.selector, missingAccountFunds));

        // Attempt to validate the user operation
        startPrank(address(ENTRYPOINT));
        BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, missingAccountFunds);
        stopPrank();
    }

    /// @notice Fuzz test for pre-validation hook when sufficient ETH is unlocked
    /// @param lockedAmount Amount of ETH to lock
    /// @param totalBalance Total balance of the account
    function testFuzz_4337_PreValidationHook_Success(uint256 lockedAmount, uint256 totalBalance) public {
        // Constrain inputs to reasonable ranges
        vm.assume(lockedAmount > 0);
        vm.assume(totalBalance > lockedAmount);

        // Install resource lock hooks
        installResourceLockHooks();

        // Prepare user operation
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildUserOpWithCalldata(BOB, "", address(VALIDATOR_MODULE));

        // Set locked amount
        vm.prank(address(accountLocker));
        MockAccountLocker(accountLocker).setLockedAmount(address(BOB_ACCOUNT), NATIVE_TOKEN, lockedAmount);

        // Ensure account has enough total balance
        vm.deal(address(BOB_ACCOUNT), totalBalance);
        assertTrue(address(BOB_ACCOUNT).balance == totalBalance, "Account should have correct balance");

        // Calculate user op hash
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        // Sign the user operation
        userOps[0].signature = signMessage(BOB, userOpHash);

        // Attempt to validate the user operation when unlocked balance is sufficient
        vm.assume(totalBalance - lockedAmount >= 0);
        startPrank(address(ENTRYPOINT));
        uint256 result = BOB_ACCOUNT.validateUserOp(userOps[0], userOpHash, 0);
        assertTrue(result == 0, "Validation should succeed");
        stopPrank();
    }

    /// @notice Tests signature validation succeeds when resource is not locked
    function test_1271_PreValidationHook_Success() public {
        // Install resource lock hooks
        installResourceLockHooks();

        // Prepare signature
        TestTemps memory t;
        t.contents = keccak256("123");
        bytes32 hashToSign = toERC1271HashPersonalSign(t.contents, address(BOB_ACCOUNT));
        (t.v, t.r, t.s) = vm.sign(BOB.privateKey, hashToSign);

        // Prepare signature with validator prefix
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v);
        bytes memory validatorSignature = abi.encodePacked(address(VALIDATOR_MODULE), signature);

        // Validate signature
        bytes4 result = BOB_ACCOUNT.isValidSignature(t.contents, validatorSignature);
        assertEq(result, bytes4(0x1626ba7e), "Signature should be valid");
    }

    /// @notice Tests signature validation fails when resource is locked
    function test_1271_PreValidationHook_RevertsWhen_ResourceLocked() public {
        // Install resource lock hooks
        installResourceLockHooks();

        // Prepare signature
        TestTemps memory t;
        t.contents = keccak256("123");
        bytes32 hashToSign = toERC1271HashPersonalSign(t.contents, address(BOB_ACCOUNT));
        (t.v, t.r, t.s) = vm.sign(BOB.privateKey, hashToSign);

        // Prepare signature with validator prefix
        bytes memory signature = abi.encodePacked(t.r, t.s, t.v);
        bytes memory validatorSignature = abi.encodePacked(address(VALIDATOR_MODULE), signature);

        // Set locked amount to block signature validation
        vm.prank(address(accountLocker));
        MockAccountLocker(accountLocker).setLockedAmount(address(BOB_ACCOUNT), address(this), 1);

        // Expect revert due to resource lock
        vm.expectRevert(abi.encodeWithSelector(MockResourceLockPreValidationHook.SenderIsResourceLocked.selector));
        BOB_ACCOUNT.isValidSignature(t.contents, validatorSignature);
    }

    function installResourceLockHooks() internal {
        // Install account locker first
        bytes memory accountLockerInstallCallData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(accountLocker), "");
        installModule(accountLockerInstallCallData, MODULE_TYPE_HOOK, address(accountLocker), EXECTYPE_DEFAULT);

        // Install resource lock pre-validation 4337 hook
        bytes memory resourceLockHook4337InstallCallData =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(resourceLockHook), "");
        installModule(resourceLockHook4337InstallCallData, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(resourceLockHook), EXECTYPE_DEFAULT);

        // Install resource lock pre-validation 1271 hook
        bytes memory resourceLockHook1271InstallCallData =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(resourceLockHook), "");
        installModule(resourceLockHook1271InstallCallData, MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(resourceLockHook), EXECTYPE_DEFAULT);
    }

    /// @notice Generates an ERC-1271 hash for personal sign.
    /// @param childHash The child hash.
    /// @return The ERC-1271 hash for personal sign.
    function toERC1271HashPersonalSign(bytes32 childHash, address account) internal view returns (bytes32) {
        AccountDomainStruct memory t;
        (t.fields, t.name, t.version, t.chainId, t.verifyingContract, t.salt, t.extensions) = EIP712(account).eip712Domain();
        bytes32 domainSeparator = keccak256(
            abi.encode(
                keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                keccak256(bytes(t.name)),
                keccak256(bytes(t.version)),
                t.chainId,
                t.verifyingContract // veryfingContract should be the account address.
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
