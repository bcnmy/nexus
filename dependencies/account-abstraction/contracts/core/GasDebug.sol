// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

contract GasDebug {
    // Phase 0: account creation
    // Phase 1: validation
    // Phase 2: execution
    mapping(address account => mapping(uint256 phase => uint256 gas)) gasConsumed;

    function setGasConsumed(address account, uint256 phase, uint256 gas) internal {
        gasConsumed[account][phase] = gas;
    }

    function getGasConsumed(address account, uint256 phase) public view returns (uint256) {
        return gasConsumed[account][phase];
    }
}
