pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Bytes.sol";

import { AccountState } from "../interfaces/IAccountState.sol";
import { IComposableExecution } from "../interfaces/IComposableExecution.sol";
import { IExecutionResult } from "../interfaces/IExecutionResult.sol";
import { IInputParam } from "../interfaces/IInputParam.sol";
import { IConstraint } from "../interfaces/IConstraint.sol";
import { IConstraintResult } from "../interfaces/IConstraintResult.sol";
import { IExecutionResult } from "../interfaces/IExecutionResult.sol";
import { IInputParam } from "../interfaces/IInputParam.sol";
import { IConstraint } from "../interfaces/IConstraint.sol";
import { IConstraintResult } from "../interfaces/IConstraintResult.sol";

import { ComposableExecution } from "../smart-accounts/ComposableExecution.sol";
import { ExecutionResult } from "../structs/ExecutionResult.sol";
import { InputParam } from "../structs/InputParam.sol";
import { Constraint } from "../structs/Constraint.sol";
import { ConstraintResult } from "../structs/ConstraintResult.sol";

import { FetcherLib } from "./FetcherLib.sol";
import { ConstraintLib } from "./ConstraintLib.sol";

/**
 * @title ComposableExecutionLib
 * @notice Library for managing composable execution logic.
 */
library ComposableExecutionLib {
    using Address for address;
    using Bytes for bytes;
    using Math for uint256;

    /**
     * @notice Validates constraints against fetched values.
     * @param _self The ComposableExecution instance.
     * @param _inputParams The array of input parameters.
     * @param _constraintResults The array of constraint results.
     * @param _fetchedValues The array of fetched values.
     * @return bool True if all constraints are met, false otherwise.
     */
    function _validateConstraints(
        ComposableExecution _self,
        InputParam[] memory _inputParams,
        ConstraintResult[] memory _constraintResults,
        bytes[] memory _fetchedValues
    ) internal view returns (bool) {
        for (uint256 i = 0; i < _inputParams.length; i++) {
            InputParam memory inputParam = _inputParams[i];
            ConstraintResult memory constraintResult = _constraintResults[i];

            // If the constraint is not met, return false.
            if (!constraintResult.isMet) {
                return false;
            }

            // If the constraint is met, validate the fetched value against the constraint.
            // For single-value fetchers, the fetched value is a single 32-byte word.
            // We need to ensure that all constraints are checked against this single word.
            // The original implementation used `mload(add(rawValue, add(0x20, mul(i, 0x20))))` which
            // incorrectly used `i` as an offset for subsequent constraints, leading to bypasses.
            // The corrected logic loads the raw value once and uses it for all constraints associated with it.
            uint256 rawValue = inputParam.isSingleWordFetcher
                ? uint256(uint160(_fetchedValues[i])) // Cast to uint160 for balance, then to uint256
                : uint256(bytes32(_fetchedValues[i])); // For RAW_BYTES, it's already 32 bytes

            for (uint256 j = 0; j < inputParam.constraints.length; j++) {
                Constraint memory constraint = inputParam.constraints[j];
                bool isConstraintMet = ConstraintLib.evaluateConstraint(
                    constraint,
                    rawValue // Use the single rawValue for all constraints
                );

                if (!isConstraintMet) {
                    // If any constraint is not met, revert.
                    // This should ideally not happen if constraintResult.isMet is true, but as a safeguard.
                    return false;
                }
            }
        }
        return true;
    }

    /**
     * @notice Executes a composable operation.
     * @param _self The ComposableExecution instance.
     * @param _inputParams The array of input parameters.
     * @param _constraints The array of constraints.
     * @param _execution The execution details.
     * @return ExecutionResult The result of the execution.
     */
    function executeComposable(
        ComposableExecution _self,
        InputParam[] memory _inputParams,
        Constraint[] memory _constraints,
        IExecutionResult.ExecutionData memory _execution
    ) public view returns (ExecutionResult memory) {
        // Fetch values based on input parameters.
        bytes[] memory fetchedValues = FetcherLib.fetchValues(_inputParams);

        // Evaluate constraints against fetched values.
        ConstraintResult[] memory constraintResults = new ConstraintResult[](_inputParams.length);
        for (uint256 i = 0; i < _inputParams.length; i++) {
            InputParam memory inputParam = _inputParams[i];
            bytes memory fetchedValue = fetchedValues[i];

            // If the fetcher returns a single word and it's not a RAW_BYTES fetcher, we need to handle it.
            // For single-word fetchers like BALANCE, the fetched value is a single 32-byte word.
            // We need to ensure that the constraint evaluation uses the correct part of the fetched value.
            // The original implementation had a bug where it would incorrectly offset into the fetched value
            // for subsequent constraints, leading to bypasses.
            // The fix is applied in _validateConstraints to correctly use the fetched value.
            constraintResults[i] = ConstraintLib.evaluateConstraintsForInputParam(
                inputParam,
                fetchedValue
            );
        }

        // Validate all constraints.
        if (!_validateConstraints(_self, _inputParams, constraintResults, fetchedValues)) {
            // If any constraint is not met, revert.
            return ExecutionResult(false, "Constraints not met.", "");
        }

        // Execute the operation.
        (bool success, bytes memory returnData) = _execution.to.call(abi.encodeWithSelector(_execution.selector, _execution.args));

        // Return the execution result.
        return ExecutionResult(success, "", returnData);
    }
}
