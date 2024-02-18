// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

/**
 * @title Lock
 * @dev Implements a time-locked wallet that only allows withdrawals after a certain date.
 */
contract Lock {
    uint256 public unlockTime;
    address payable public owner;

    /**
     * @dev Emitted when funds are withdrawn from the contract.
     * @param amount The amount of Ether withdrawn.
     * @param when The timestamp of the withdrawal.
     */
    event Withdrawal(uint256 amount, uint256 when);

    /**
     * @notice Creates a locked wallet.
     * @param unlockTime_ The timestamp after which withdrawals can be made.
     */
    constructor(uint256 unlockTime_) payable {
        require(block.timestamp < unlockTime_, "Wrong Unlock time");

        unlockTime = unlockTime_;
        owner = payable(msg.sender);
    }

    /**
     * @notice Allows funds to be received via direct transfers.
     */
    receive() external payable { }

    /**
     * @notice Withdraws all funds if the unlock time has passed and the caller is the owner.
     */
    function withdraw() public {
        require(block.timestamp > unlockTime, "You can't withdraw yet");
        require(msg.sender == owner, "You aren't the owner");

        emit Withdrawal(address(this).balance, block.timestamp);

        owner.transfer(address(this).balance);
    }
}
