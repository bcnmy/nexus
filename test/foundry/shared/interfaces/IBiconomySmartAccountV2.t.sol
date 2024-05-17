// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBiconomySmartAccountV2 {
    function updateImplementation(address _implementation) external;
    function executeBatch(address[] calldata dest, uint256[] calldata value, bytes[] calldata func) external;
    function entryPoint() external view returns (address);
}