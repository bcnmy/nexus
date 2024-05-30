// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/NexusTest_Base.t.sol";
import { IEntryPoint, IStakeManager } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";

/// @title TestStakeable
/// @notice Unit tests for the Stakeable contract
contract TestStakeable is NexusTest_Base {
    Stakeable public stakeable;
    address public owner;
    IEntryPoint public entryPoint;

    /// @notice Sets up the testing environment by deploying the contract and initializing variables
    function setUp() public {
        init();
        owner = FACTORY_OWNER.addr;
        stakeable = new Stakeable(owner);
        entryPoint = IEntryPoint(address(ENTRYPOINT)); // Use the ENTRYPOINT from NexusTest_Base
    }

    /// @notice Tests the addStake function
    function test_AddStake_Success() public {
        vm.deal(owner, 10 ether); // Fund the owner with 10 ether
        vm.startPrank(owner);

        // Get initial stake info
        IStakeManager.DepositInfo memory initialInfo = ENTRYPOINT.getDepositInfo(address(stakeable));
        uint256 initialStake = initialInfo.stake;
        uint256 amount = 1 ether;

        // Add stake
        stakeable.addStake{value: amount}(address(entryPoint), 1000);

        // Get updated stake info
        IStakeManager.DepositInfo memory updatedInfo = entryPoint.getDepositInfo(address(stakeable));
        assertEq(updatedInfo.stake, initialStake + amount, "Stake amount should increase");
        assertEq(updatedInfo.unstakeDelaySec, 1000, "Unstake delay should be set");

        vm.stopPrank();
    }

    /// @notice Tests that addStake fails when called by a non-owner
    function test_AddStake_RevertIf_NotOwner() public {
        vm.expectRevert(Unauthorized.selector);
        stakeable.addStake{value: 1 ether}(address(entryPoint), 100);
    }

    /// @notice Tests that addStake fails with an invalid EntryPoint address
    function test_AddStake_RevertIf_InvalidEPAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid EP address");
        stakeable.addStake{value: 1 ether}(address(0), 100);
        vm.stopPrank();
    }

    /// @notice Tests the unlockStake function
    function test_UnlockStake_Success() public {
        vm.startPrank(owner);

        // Add stake first to unlock it later
        stakeable.addStake{value: 1 ether}(address(entryPoint), 100);

        // Unlock the stake
        stakeable.unlockStake(address(entryPoint));
        IStakeManager.DepositInfo memory info = entryPoint.getDepositInfo(address(stakeable));
        assertTrue(info.withdrawTime > block.timestamp, "Stake should be unlocked");

        vm.stopPrank();
    }

    /// @notice Tests that unlockStake fails when called by a non-owner
    function test_UnlockStake_RevertIf_NotOwner() public {
        vm.expectRevert(Unauthorized.selector);
        stakeable.unlockStake(address(entryPoint));
    }

    /// @notice Tests that unlockStake fails with an invalid EntryPoint address
    function test_UnlockStake_RevertIf_InvalidEPAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid EP address");
        stakeable.unlockStake(address(0));
        vm.stopPrank();
    }

    /// @notice Tests the withdrawStake function
    function test_WithdrawStake_Success() public {
        vm.startPrank(owner);

        address payable withdrawAddress = payable(address(0x456));

        // Add stake first to withdraw it later
        stakeable.addStake{value: 1 ether}(address(entryPoint), 100);

        // Unlock and wait for the unstake delay
        stakeable.unlockStake(address(entryPoint));
        vm.warp(block.timestamp + 100); // Simulate passing of time

        // Withdraw the stake
        stakeable.withdrawStake(address(entryPoint), withdrawAddress);
        IStakeManager.DepositInfo memory info = entryPoint.getDepositInfo(address(stakeable));
        assertEq(info.stake, 0, "Stake should be withdrawn");

        vm.stopPrank();
    }

    /// @notice Tests the deployment of the Stakeable contract
    function test_DeployStakeable() public {
        Stakeable stakeable = new Stakeable(owner);
        assertEq(stakeable.owner(), owner, "Owner should be set correctly");
    }

    /// @notice Tests that withdrawStake fails when called by a non-owner
    function test_WithdrawStake_RevertIf_NotOwner() public {
        vm.expectRevert(Unauthorized.selector);
        stakeable.withdrawStake(address(entryPoint), payable(address(0x456)));
    }

    /// @notice Tests that withdrawStake fails with an invalid EntryPoint address
    function test_WithdrawStake_RevertIf_InvalidEPAddress() public {
        vm.startPrank(owner);
        vm.expectRevert("Invalid EP address");
        stakeable.withdrawStake(address(0), payable(address(0x456)));
        vm.stopPrank();
    }
}
