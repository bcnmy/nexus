// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";

/// @title TestERC4337Account_PayPrefund
/// @notice Tests for the validateUserOp function in the ERC4337 account related to paying prefunds.
contract TestERC4337Account_PayPrefund is NexusTest_Base {
    Vm.Wallet internal signer;
    Nexus internal account;

    /// @notice Sets up the testing environment.
    function setUp() public {
        init();
        signer = createAndFundWallet("Signer", 0.0001 ether);
        account = deployNexus(signer, 0.0001 ether, address(VALIDATOR_MODULE));
    }

    /// @notice Tests the prefund payment handling with sufficient funds.
    function testPayPrefund_WithSufficientFunds() public {
        // Fund the account with sufficient ether
        vm.deal(address(account), 1 ether);

        // Prepare a single execution with no value transfer
        Execution[] memory executions = prepareSingleExecution(address(account), 0, "");

        // Build a packed user operation
        PackedUserOperation[] memory userOps = buildPackedUserOperation(signer, account, EXECTYPE_TRY, executions, address(VALIDATOR_MODULE), 0);
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);
        userOps[0].signature = signPureHash(signer, userOpHash);

        startPrank(address(ENTRYPOINT));
        account.validateUserOp(userOps[0], userOpHash, 0.1 ether);
        stopPrank();
    }
}
