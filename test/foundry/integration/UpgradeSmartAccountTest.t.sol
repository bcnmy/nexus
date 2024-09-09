// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

contract UpgradeSmartAccountTest is NexusTest_Base {
    function setUp() public {
        init();
    }

    /// @notice Tests that the proxiable UUID slot is correct
    function test_proxiableUUIDSlot() public {
        bytes32 slot = ACCOUNT_IMPLEMENTATION.proxiableUUID();
        assertEq(slot, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, "Proxiable UUID mismatch");
    }

    /// @notice Tests that the current implementation address is correct
    function test_currentImplementationAddress() public {
        address currentImplementation = BOB_ACCOUNT.getImplementation();
        assertEq(currentImplementation, address(ACCOUNT_IMPLEMENTATION), "Current implementation address mismatch");
    }

    /// @notice Tests the upgrade of the smart account implementation
    function test_upgradeImplementation() public {
        address _ENTRYPOINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
        Nexus newSmartAccount = new Nexus(_ENTRYPOINT);
        bytes memory callData = abi.encodeWithSelector(Nexus.upgradeToAndCall.selector, address(newSmartAccount), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
        address newImplementation = BOB_ACCOUNT.getImplementation();
        assertEq(newImplementation, address(newSmartAccount), "New implementation address mismatch");
    }

    /// @notice Tests the upgrade of the smart account implementation with invalid call data
    function test_upgradeImplementation_invalidCallData() public {
        address _ENTRYPOINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
        Nexus newSmartAccount = new Nexus(_ENTRYPOINT);
        bytes memory callData = abi.encodeWithSelector(Nexus.upgradeToAndCall.selector, address(newSmartAccount), bytes(hex"1234"));
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        bytes memory expectedRevertReason = abi.encodeWithSelector(MissingFallbackHandler.selector, bytes4(hex"1234"));
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Tests the upgrade of the smart account implementation with an invalid address
    function test_upgradeImplementation_InvalidAddress() public {
        /// @note "" means empty calldata. this will just update the implementation but not setup the account.
        bytes memory callData = abi.encodeWithSelector(Nexus.upgradeToAndCall.selector, address(0), "");
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        bytes memory expectedRevertReason = abi.encodeWithSignature("InvalidImplementationAddress()");
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// @notice Tests the upgrade of the smart account implementation with an invalid address
    function test_upgradeImplementation_InvalidAddress_NotAContract() public {
        /// @note "" means empty calldata. this will just update the implementation but not setup the account.
        bytes memory callData = abi.encodeWithSelector(Nexus.upgradeToAndCall.selector, BOB.addr, "");
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));
        bytes memory expectedRevertReason = abi.encodeWithSignature("InvalidImplementationAddress()");
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        // Expect the UserOperationRevertReason event
        vm.expectEmit(true, true, true, true);
        emit UserOperationRevertReason(
            userOpHash, // userOpHash
            address(BOB_ACCOUNT), // sender
            userOps[0].nonce, // nonce
            expectedRevertReason
        );
        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));
    }

    /// Could add...
    /// Access control on upgrades
    /// send setup data instead of empty data

    /// @notice Tests the entire upgrade process
    function test_upgradeSmartAccount() public {
        test_proxiableUUIDSlot();
        test_currentImplementationAddress();
        test_upgradeImplementation();
    }

    /// @notice Tests the entire upgrade process
    function test_RevertIf_AccessUnauthorized_upgradeSmartAccount() public {
        test_proxiableUUIDSlot();
        test_currentImplementationAddress();
        address _ENTRYPOINT = 0x0000000071727De22E5E9d8BAf0edAc6f37da032;
        Nexus newSmartAccount = new Nexus(_ENTRYPOINT);
        vm.expectRevert(abi.encodeWithSelector(AccountAccessUnauthorized.selector));
        BOB_ACCOUNT.upgradeToAndCall(address(newSmartAccount), "");
    }
}
