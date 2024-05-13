// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import "../../utils/SmartAccountTestLab.t.sol";

contract ERC4337AccountValidateUserOpInvariantTests is Test, SmartAccountTestLab {
    Nexus public account;
    address public userAddress = address(BOB.addr);

    function setUp() public {
        init();
    }

    /// @notice Invariant to check nonce consistency
    function invariantTest_NonceConsistency() public {
        // Fetch the nonce for BOB_ACCOUNT from ENTRYPOINT
        uint256 nonceBefore = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));

        // Prepare a simple operation
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(BOB_ACCOUNT), value: 0, callData: abi.encodeWithSignature("someExistingMethod()") });

        // Use helpers to prepare user operation
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);

        // Execute the operation
        ENTRYPOINT.handleOps(userOps, payable(BOB_ACCOUNT));

        // Fetch the nonce after operation execution
        uint256 nonceAfter = getNonce(address(BOB_ACCOUNT), address(VALIDATOR_MODULE));

        // Assert nonce consistency
        assertTrue(nonceAfter == nonceBefore + 1, "Nonce should be correctly incremented after operation");
    }
}
