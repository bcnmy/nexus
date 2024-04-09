// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import "../../utils/SmartAccountTestLab.t.sol";
import "../../mocks/Counter.sol";
import "../../mocks/Token.sol";

event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

abstract contract TestAccountExecution_Base is Test, SmartAccountTestLab {
    ModeCode public singleMode;
    ModeCode public batchMode;
    ModeCode public unsupportedMode;

    Counter public counter;
    Token public token;

    // Define more shared state variables here

    function setUpTestAccountExecution_Base() internal virtual {
        // Shared setup logic for all derived test contracts
        init(); // Initialize the testing environment if necessary

        singleMode = ModeLib.encodeSimpleSingle();
        batchMode = ModeLib.encodeSimpleBatch();
        // Example of an unsupported mode for demonstration purposes
        unsupportedMode = ModeLib.encode(CallType.wrap(0xee), EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00));

        counter = new Counter();
        // Deploy the Token contract
        token = new Token("Test Token", "TST");

        // Assuming msg.sender is the owner and receives the initial supply,
        // transfer tokens to BOB_ACCOUNT, ALICE_ACCOUNT, and CHARLIE_ACCOUNT
        uint256 amountToEach = 10_000 * 10 ** token.decimals();

        token.transfer(address(BOB_ACCOUNT), amountToEach);
        token.transfer(address(ALICE_ACCOUNT), amountToEach);
        token.transfer(address(CHARLIE_ACCOUNT), amountToEach);
    }
}
