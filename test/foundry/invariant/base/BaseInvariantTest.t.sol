// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../utils/SmartAccountTestLab.t.sol";
import "../../../../contracts/mocks/Counter.sol";
import "../../../../contracts/mocks/MockToken.sol";

// BaseInvariantTest serves as the foundational test setup for all invariant testing related to the Nexus contract suite.
contract BaseInvariantTest is SmartAccountTestLab {
    Counter public counter;
    MockToken public token;

    // Initializes the SmartAccountTestLab environment along with specific test setups
    function setUp() public virtual {
        init(); // Initializes wallets, accounts, and contracts including ENTRYPOINT and ACCOUNT_IMPLEMENTATION
        counter = new Counter();
        token = new MockToken("MockToken", "MTK");
    }

    // Utility to prepare user operations for invariant tests.
    function prepareUserOperation(
        Vm.Wallet memory signer,
        Nexus account,
        Execution[] memory executions
    ) internal view returns (PackedUserOperation[] memory userOps) {
        bytes memory executionCalldata = (executions.length > 1)
            ? ExecLib.encodeBatch(executions)
            : ExecLib.encodeSingle(executions[0].target, executions[0].value, executions[0].callData);

        userOps = new PackedUserOperation[](1);
        userOps[0] = PackedUserOperation({
            sender: address(account),
            nonce: getNonce(address(account), address(VALIDATOR_MODULE)),
            initCode: "",
            callData: executionCalldata,
            accountGasLimits: bytes32(abi.encodePacked(uint128(3e6), uint128(3e6))),
            preVerificationGas: 3e6,
            gasFees: bytes32(abi.encodePacked(uint128(3e6), uint128(3e6))),
            paymasterAndData: "",
            signature: ""
        });

        userOps[0].signature = signUserOp(signer, userOps[0]);

        return userOps;
    }

    // You can add additional setup functions or utility functions here to be used across various invariant tests.
}
