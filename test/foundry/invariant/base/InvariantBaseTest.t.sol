// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;


import "../../utils/NexusTest_Base.t.sol";
import "../../../../contracts/mocks/Counter.sol";
import "../../../../contracts/mocks/MockToken.sol";

/// @title InvariantBaseTest
/// @dev This contract serves as the foundational test setup for all invariant testing related to the Nexus contract suite.
abstract contract InvariantBaseTest is NexusTest_Base {
    Counter public counter;
    MockToken public token;

    /// @notice Initializes the NexusTest_Base environment and sets up the specific test environments.
    function setUp() public virtual {
        init(); // Initialize wallets, accounts, ENTRYPOINT, and ACCOUNT_IMPLEMENTATION.
        counter = new Counter();
        token = new MockToken("MockToken", "MTK");

        // Fund the Nexus accounts with tokens.
        uint256 amountToEach = 10_000 * 10 ** token.decimals();
        token.transfer(address(BOB_ACCOUNT), amountToEach);
        token.transfer(address(ALICE_ACCOUNT), amountToEach);
        token.transfer(address(CHARLIE_ACCOUNT), amountToEach);
    }
}
