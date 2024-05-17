// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24 <0.9.0;

import "./Helpers.sol";
import "./Imports.sol";
import "./EventsAndErrors.sol";

contract SmartAccountTestLab is Helpers {
    Nexus public smartAccount;
    Nexus public implementation;

    function init() internal {
        initializeTestingEnvironment();
    }

    function _prefundSmartAccountAndAssertSuccess(address sa, uint256 prefundAmount) internal {
        (bool res, ) = sa.call{ value: prefundAmount }(""); // Pre-funding the account contract
        assertTrue(res, "Pre-funding account should succeed");
    }

    function _prepareSingleExecution(address to, uint256 value, bytes memory data) internal pure returns (Execution[] memory execution) {
        execution = new Execution[](1);
        execution[0] = Execution(to, value, data);
    }

    function _prepareSeveralIdenticalExecutions(Execution memory execution, uint256 executionsNumber) internal pure returns (Execution[] memory) {
        Execution[] memory executions = new Execution[](executionsNumber);
        for (uint256 i = 0; i < executionsNumber; i++) {
            executions[i] = execution;
        }
        return executions;
    }

    function handleUserOpAndMeasureGas(PackedUserOperation[] memory userOps, address refundReceiver) internal returns (uint256 gasUsed) {
        uint256 gasStart = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(refundReceiver));
        gasUsed = gasStart - gasleft();
    }

    receive() external payable {}
}
