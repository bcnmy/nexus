// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract EventsAndErrors {
    // Define all events
    event ModuleInstalled(uint256 moduleTypeId, address module);
    event ModuleUninstalled(uint256 moduleTypeId, address module);
    
    event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);


    // Define all errors
    error InvalidModule(address module);
}
