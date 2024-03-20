// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import "../../utils/SmartAccountTestLab.t.sol";
import "../../mocks/Counter.sol";

event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

abstract contract TestAccountExecution_Base is Test, SmartAccountTestLab {
    ModeCode public singleMode;
    ModeCode public batchMode;
    ModeCode public unsupportedMode;

    
    Counter public counter;
    // Define more shared state variables here

    function setUp() public virtual {
        // Shared setup logic for all derived test contracts
        init(); // Initialize the testing environment if necessary

        singleMode = ModeLib.encodeSimpleSingle();
        batchMode = ModeLib.encodeSimpleBatch();
        // Example of an unsupported mode for demonstration purposes
        unsupportedMode = ModeLib.encode(CallType.wrap(0x02), EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00));

        counter = new Counter();

    }

}

