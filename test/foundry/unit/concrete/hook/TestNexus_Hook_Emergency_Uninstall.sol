// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../shared/TestModuleManagement_Base.t.sol";
import "../../../../../contracts/mocks/MockHook.sol";
import { MockSimpleValidator } from "../../../../../contracts/mocks/MockSimpleValidator.sol";
import { MockPreValidationHook } from "../../../../../contracts/mocks/MockPreValidationHook.sol";
import { EMERGENCY_UNINSTALL_TYPE_HASH } from "../../../../../contracts/types/Constants.sol";
import { EmergencyUninstall } from "../../../../../contracts/types/DataTypes.sol";

/// @title TestNexus_Hook_Uninstall
/// @notice Tests for handling hooks emergency uninstall
contract TestNexus_Hook_Emergency_Uninstall is TestModuleManagement_Base {
    MockSimpleValidator SIMPLE_VALIDATOR_MODULE;

    /// @notice Sets up the base module management environment.
    function setUp() public {
        setUpModuleManagement_Base();
        // Deploy  simple validator
        SIMPLE_VALIDATOR_MODULE = new MockSimpleValidator();

        // Format install data with owner
        bytes memory validatorSetupData = abi.encodePacked(BOB_ADDRESS); // Set BOB as owner

        // Prepare the call data for installing the validator module
        bytes memory callData =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_VALIDATOR, address(SIMPLE_VALIDATOR_MODULE), validatorSetupData);

        // Install validator module using execution
        installModule(callData, MODULE_TYPE_VALIDATOR, address(SIMPLE_VALIDATOR_MODULE), EXECTYPE_DEFAULT);

        // Assert that bob is the owner
        assertTrue(SIMPLE_VALIDATOR_MODULE.smartAccountOwners(address(BOB_ACCOUNT)) == BOB_ADDRESS, "Bob should be the owner");
    }

    /// @notice Tests the successful installation of the hook module, then tests initiate emergency uninstall.
    function test_EmergencyUninstallHook_Initiate_Success() public {
        // 1. Install the hook
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");
        installModule(callData, MODULE_TYPE_HOOK, address(HOOK_MODULE), EXECTYPE_DEFAULT);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));

        // 2. Sign and request emergency uninstall
        EmergencyUninstall memory emergencyUninstall = EmergencyUninstall(address(HOOK_MODULE), MODULE_TYPE_HOOK, "", 0);
        // Get the hash of the emergency uninstall data
        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        // Format signature with validator address prefix
        bytes memory signature = abi.encodePacked(
            address(SIMPLE_VALIDATOR_MODULE), // First 20 bytes is validator
            sign(BOB, hash) // Rest is signature
        );

        bytes memory emergencyUninstallCalldata = abi.encodeWithSelector(
            Nexus.emergencyUninstallHook.selector,
            emergencyUninstall, // EmergencyUninstall struct
            signature
        );

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(SIMPLE_VALIDATOR_MODULE), bytes3(0)));
        userOps[0].callData = emergencyUninstallCalldata;
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = sign(BOB, userOpHash);

        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(HOOK_MODULE), block.timestamp);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
    }

    function test_EmergencyUninstallHook_Fail_AfterInitiated() public {
        // 1. Install the hook
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");
        installModule(callData, MODULE_TYPE_HOOK, address(HOOK_MODULE), EXECTYPE_DEFAULT);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));

        // 2. Sign and request emergency uninstall
        EmergencyUninstall memory emergencyUninstall = EmergencyUninstall({ hook: address(HOOK_MODULE), hookType: MODULE_TYPE_HOOK, deInitData: "", nonce: 0 });

        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        bytes memory signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));

        bytes memory emergencyUninstallCalldata = abi.encodeWithSelector(Nexus.emergencyUninstallHook.selector, emergencyUninstall, signature);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(SIMPLE_VALIDATOR_MODULE), bytes3(0)));
        userOps[0].callData = emergencyUninstallCalldata;
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = sign(BOB, userOpHash);

        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(HOOK_MODULE), block.timestamp);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // 3. Try without waiting for time to pass

        // Rebuild the user operation
        emergencyUninstall.nonce = 1;
        hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );
        signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));
        emergencyUninstallCalldata = abi.encodeWithSelector(Nexus.emergencyUninstallHook.selector, emergencyUninstall, signature);

        PackedUserOperation[] memory newUserOps = new PackedUserOperation[](1);
        newUserOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(SIMPLE_VALIDATOR_MODULE), bytes3(0)));
        newUserOps[0].callData = emergencyUninstallCalldata;
        bytes32 newUserOpHash = ENTRYPOINT.getUserOpHash(newUserOps[0]);
        newUserOps[0].signature = sign(BOB, newUserOpHash);

        bytes memory expectedRevertReason = abi.encodeWithSelector(EmergencyTimeLockNotExpired.selector);
        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(newUserOpHash, address(BOB_ACCOUNT), newUserOps[0].nonce, expectedRevertReason);
        ENTRYPOINT.handleOps(newUserOps, payable(BOB.addr));

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
    }

    function test_EmergencyUninstallHook_Success_LongAfterInitiated() public {
        // 1. Install the hook
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");
        installModule(callData, MODULE_TYPE_HOOK, address(HOOK_MODULE), EXECTYPE_DEFAULT);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));

        uint256 prevTimeStamp = block.timestamp;

        // 2. Sign and request emergency uninstall
        EmergencyUninstall memory emergencyUninstall = EmergencyUninstall({ hook: address(HOOK_MODULE), hookType: MODULE_TYPE_HOOK, deInitData: "", nonce: 0 });

        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        bytes memory signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));

        bytes memory emergencyUninstallCalldata = abi.encodeWithSelector(Nexus.emergencyUninstallHook.selector, emergencyUninstall, signature);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(SIMPLE_VALIDATOR_MODULE), bytes3(0)));
        userOps[0].callData = emergencyUninstallCalldata;
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = sign(BOB, userOpHash);

        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(HOOK_MODULE), block.timestamp);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // 3. Wait for time to pass

        // not more than 3 days
        vm.warp(prevTimeStamp + 2 days);

        // Rebuild the user operation
        emergencyUninstall.nonce = 1;
        hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );
        signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));
        emergencyUninstallCalldata = abi.encodeWithSelector(Nexus.emergencyUninstallHook.selector, emergencyUninstall, signature);

        PackedUserOperation[] memory newUserOps = new PackedUserOperation[](1);
        newUserOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(SIMPLE_VALIDATOR_MODULE), bytes3(0)));
        newUserOps[0].callData = emergencyUninstallCalldata;
        bytes32 newUserOpHash = ENTRYPOINT.getUserOpHash(newUserOps[0]);
        newUserOps[0].signature = sign(BOB, newUserOpHash);

        vm.expectEmit(true, true, true, true);
        emit ModuleUninstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE));
        ENTRYPOINT.handleOps(newUserOps, payable(BOB.addr));

        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
    }

    function test_EmergencyUninstallHook_Success_Reset_SuperLongAfterInitiated() public {
        // 1. Install the hook
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");
        installModule(callData, MODULE_TYPE_HOOK, address(HOOK_MODULE), EXECTYPE_DEFAULT);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));

        uint256 prevTimeStamp = block.timestamp;

        // 2. Sign and request emergency uninstall
        EmergencyUninstall memory emergencyUninstall = EmergencyUninstall({ hook: address(HOOK_MODULE), hookType: MODULE_TYPE_HOOK, deInitData: "", nonce: 0 });

        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        bytes memory signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));

        bytes memory emergencyUninstallCalldata = abi.encodeWithSelector(Nexus.emergencyUninstallHook.selector, emergencyUninstall, signature);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(SIMPLE_VALIDATOR_MODULE), bytes3(0)));
        userOps[0].callData = emergencyUninstallCalldata;
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = sign(BOB, userOpHash);

        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(HOOK_MODULE), block.timestamp);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // 3. Wait for time to pass

        // more than 3 days
        vm.warp(prevTimeStamp + 4 days);

        // Rebuild the user operation
        emergencyUninstall.nonce = 1;
        hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );
        signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));
        emergencyUninstallCalldata = abi.encodeWithSelector(Nexus.emergencyUninstallHook.selector, emergencyUninstall, signature);

        PackedUserOperation[] memory newUserOps = new PackedUserOperation[](1);
        newUserOps[0] = buildPackedUserOp(address(BOB_ACCOUNT), getNonce(address(BOB_ACCOUNT), MODE_VALIDATION, address(SIMPLE_VALIDATOR_MODULE), bytes3(0)));
        newUserOps[0].callData = emergencyUninstallCalldata;
        bytes32 newUserOpHash = ENTRYPOINT.getUserOpHash(newUserOps[0]);
        newUserOps[0].signature = sign(BOB, newUserOpHash);

        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequestReset(address(HOOK_MODULE), block.timestamp);
        ENTRYPOINT.handleOps(newUserOps, payable(BOB.addr));

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
    }

    function test_EmergencyUninstallHook_DirectCall_Success() public {
        // 1. Install the hook
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");
        installModule(callData, MODULE_TYPE_HOOK, address(HOOK_MODULE), EXECTYPE_DEFAULT);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));

        // 2. Sign and request emergency uninstall
        EmergencyUninstall memory emergencyUninstall = EmergencyUninstall({ hook: address(HOOK_MODULE), hookType: MODULE_TYPE_HOOK, deInitData: "", nonce: 0 });

        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        bytes memory signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));

        vm.prank(address(BOB_ACCOUNT));
        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(HOOK_MODULE), block.timestamp);

        BOB_ACCOUNT.emergencyUninstallHook(emergencyUninstall, signature);

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
    }

    function test_EmergencyUninstallHook_DirectCall_Fail_WrongSigner() public {
        // 1. Install the hook
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_HOOK, address(HOOK_MODULE), "");
        installModule(callData, MODULE_TYPE_HOOK, address(HOOK_MODULE), EXECTYPE_DEFAULT);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));

        // 2. Sign with wrong signer (ALICE instead of BOB)
        EmergencyUninstall memory emergencyUninstall = EmergencyUninstall({ hook: address(HOOK_MODULE), hookType: MODULE_TYPE_HOOK, deInitData: "", nonce: 0 });

        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        bytes memory signature = abi.encodePacked(
            address(SIMPLE_VALIDATOR_MODULE),
            sign(ALICE, hash) // ALICE signs instead of BOB
        );

        vm.prank(address(BOB_ACCOUNT));
        vm.expectRevert(EmergencyUninstallSigError.selector);
        BOB_ACCOUNT.emergencyUninstallHook(emergencyUninstall, signature);

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_HOOK, address(HOOK_MODULE), ""));
    }

    function test_EmergencyUninstallHook_1271_DirectCall_Success() public {
        // 1. Install the 1271 hook
        MockPreValidationHook preValidationHook = new MockPreValidationHook();
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), ""));

        bytes memory callData =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), "");
        installModule(callData, MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), EXECTYPE_DEFAULT);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), ""));

        // 2. Sign and request emergency uninstall
        EmergencyUninstall memory emergencyUninstall =
            EmergencyUninstall({ hook: address(preValidationHook), hookType: MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, deInitData: "", nonce: 0 });

        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        bytes memory signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));

        vm.prank(address(BOB_ACCOUNT));
        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(preValidationHook), block.timestamp);
        BOB_ACCOUNT.emergencyUninstallHook(emergencyUninstall, signature);

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), ""));
    }

    function test_EmergencyUninstallHook_4337_DirectCall_Success() public {
        // 1. Install the 4337 hook
        MockPreValidationHook preValidationHook = new MockPreValidationHook();
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), ""));

        bytes memory callData =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), "");
        installModule(callData, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), EXECTYPE_DEFAULT);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), ""));

        // 2. Sign and request emergency uninstall
        EmergencyUninstall memory emergencyUninstall =
            EmergencyUninstall({ hook: address(preValidationHook), hookType: MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, deInitData: "", nonce: 0 });

        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        bytes memory signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));

        vm.prank(address(BOB_ACCOUNT));
        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(preValidationHook), block.timestamp);
        BOB_ACCOUNT.emergencyUninstallHook(emergencyUninstall, signature);

        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), ""));
    }

    function test_EmergencyUninstallHook_1271_DirectCall_Fail_WrongSigner() public {
        // 1. Install the 1271 hook
        MockPreValidationHook preValidationHook = new MockPreValidationHook();
        bytes memory callData =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), "");
        installModule(callData, MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), EXECTYPE_DEFAULT);

        // 2. Sign with wrong signer (ALICE instead of BOB)
        EmergencyUninstall memory emergencyUninstall =
            EmergencyUninstall({ hook: address(preValidationHook), hookType: MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, deInitData: "", nonce: 0 });

        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        bytes memory signature = abi.encodePacked(
            address(SIMPLE_VALIDATOR_MODULE),
            sign(ALICE, hash) // ALICE signs instead of BOB
        );

        vm.prank(address(BOB_ACCOUNT));
        vm.expectRevert(EmergencyUninstallSigError.selector);
        BOB_ACCOUNT.emergencyUninstallHook(emergencyUninstall, signature);
    }

    function test_EmergencyUninstallHook_4337_DirectCall_Fail_WrongSigner() public {
        // 1. Install the 4337 hook
        MockPreValidationHook preValidationHook = new MockPreValidationHook();
        bytes memory callData =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), "");
        installModule(callData, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), EXECTYPE_DEFAULT);

        // 2. Sign with wrong signer (ALICE instead of BOB)
        EmergencyUninstall memory emergencyUninstall =
            EmergencyUninstall({ hook: address(preValidationHook), hookType: MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, deInitData: "", nonce: 0 });

        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        bytes memory signature = abi.encodePacked(
            address(SIMPLE_VALIDATOR_MODULE),
            sign(ALICE, hash) // ALICE signs instead of BOB
        );

        vm.prank(address(BOB_ACCOUNT));
        vm.expectRevert(EmergencyUninstallSigError.selector);
        BOB_ACCOUNT.emergencyUninstallHook(emergencyUninstall, signature);
    }

    function test_EmergencyUninstallHook_PreValidation1271_Uninstall() public {
        // 1. Install the 1271 hook
        MockPreValidationHook preValidationHook = new MockPreValidationHook();
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), ""));

        bytes memory callData =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), "");
        installModule(callData, MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), EXECTYPE_DEFAULT);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), ""));

        // 2. Sign and request emergency uninstall
        EmergencyUninstall memory emergencyUninstall =
            EmergencyUninstall({ hook: address(preValidationHook), hookType: MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, deInitData: "", nonce: 0 });

        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        bytes memory signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));

        uint256 prevTimeStamp = block.timestamp;

        // Direct call to emergency uninstall
        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(preValidationHook), block.timestamp);
        BOB_ACCOUNT.emergencyUninstallHook(emergencyUninstall, signature);

        // Wait for time to pass
        vm.warp(prevTimeStamp + 2 days);

        // Rebuild the request
        emergencyUninstall.nonce = 1;
        hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );
        signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));

        vm.expectEmit(true, true, true, true);
        emit ModuleUninstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook));
        BOB_ACCOUNT.emergencyUninstallHook(emergencyUninstall, signature);

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC1271, address(preValidationHook), ""),
            "PreValidation 1271 hook should be uninstalled"
        );
    }

    function test_EmergencyUninstallHook_PreValidation4337_Uninstall() public {
        // 1. Install the 4337 hook
        MockPreValidationHook preValidationHook = new MockPreValidationHook();
        assertFalse(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), ""));

        bytes memory callData =
            abi.encodeWithSelector(IModuleManager.installModule.selector, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), "");
        installModule(callData, MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), EXECTYPE_DEFAULT);
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), ""));

        // 2. Sign and request emergency uninstall
        EmergencyUninstall memory emergencyUninstall =
            EmergencyUninstall({ hook: address(preValidationHook), hookType: MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, deInitData: "", nonce: 0 });

        bytes32 hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );

        bytes memory signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));

        uint256 prevTimeStamp = block.timestamp;

        // Initiate uninstall request
        vm.expectEmit(true, true, true, true);
        emit EmergencyHookUninstallRequest(address(preValidationHook), block.timestamp);
        BOB_ACCOUNT.emergencyUninstallHook(emergencyUninstall, signature);

        // Wait for time to pass
        vm.warp(prevTimeStamp + 2 days);

        // Perform uninstall

        // Rebuild the request
        emergencyUninstall.nonce = 1;
        hash = _hashTypedData(
            keccak256(
                abi.encode(
                    EMERGENCY_UNINSTALL_TYPE_HASH,
                    emergencyUninstall.hook,
                    emergencyUninstall.hookType,
                    keccak256(emergencyUninstall.deInitData),
                    emergencyUninstall.nonce
                )
            ),
            address(BOB_ACCOUNT)
        );
        signature = abi.encodePacked(address(SIMPLE_VALIDATOR_MODULE), sign(BOB, hash));

        vm.expectEmit(true, true, true, true);
        emit ModuleUninstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook));
        BOB_ACCOUNT.emergencyUninstallHook(emergencyUninstall, signature);

        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(preValidationHook), ""),
            "PreValidation 4337 hook should be uninstalled"
        );
    }

    function sign(Vm.Wallet memory wallet, bytes32 hash) internal pure returns (bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet.privateKey, hash);
        return abi.encodePacked(r, s, v);
    }
}
