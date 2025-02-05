// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

/// @title ModeLib
/// @author zeroknots.eth | rhinestone.wtf
/// To allow smart accounts to be very simple, but allow for more complex execution, A custom mode
/// encoding is used.
///    Function Signature of execute function:
///           function execute(ExecutionMode mode, bytes calldata executionCalldata) external payable;
/// This allows for a single bytes32 to be used to encode the execution mode, calltype, execType and
/// context.
/// NOTE: Simple Account implementations only have to scope for the most significant byte. Account  that
/// implement
/// more complex execution modes may use the entire bytes32.
///
/// |--------------------------------------------------------------------|
/// | CALLTYPE  | EXECTYPE  |   UNUSED   | ModeSelector  |  ModePayload  |
/// |--------------------------------------------------------------------|
/// | 1 byte    | 1 byte    |   4 bytes  | 4 bytes       |   22 bytes    |
/// |--------------------------------------------------------------------|
///
/// CALLTYPE: 1 byte
/// CallType is used to determine how the executeCalldata paramter of the execute function has to be
/// decoded.
/// It can be either single, batch or delegatecall. In the future different calls could be added.
/// CALLTYPE can be used by a validation module to determine how to decode <userOp.callData[36:]>.
///
/// EXECTYPE: 1 byte
/// ExecType is used to determine how the account should handle the execution.
/// It can indicate if the execution should revert on failure or continue execution.
/// In the future more execution modes may be added.
/// Default Behavior (EXECTYPE = 0x00) is to revert on a single failed execution. If one execution in
/// a batch fails, the entire batch is reverted
///
/// UNUSED: 4 bytes
/// Unused bytes are reserved for future use.
///
/// ModeSelector: bytes4
/// The "optional" mode selector can be used by account vendors, to implement custom behavior in
/// their accounts.
/// the way a ModeSelector is to be calculated is bytes4(keccak256("vendorname.featurename"))
/// this is to prevent collisions between different vendors, while allowing innovation and the
/// development of new features without coordination between ERC-7579 implementing accounts
///
/// ModePayload: 22 bytes
/// Mode payload is used to pass additional data to the smart account execution, this may be
/// interpreted depending on the ModeSelector
///
/// ExecutionCallData: n bytes
/// single, delegatecall or batch exec abi.encoded as bytes

// Custom type for improved developer experience
type ExecutionMode is bytes32;

type CallType is bytes1;

type ExecType is bytes1;

type ModeSelector is bytes4;

type ModePayload is bytes22;

// Default CallType
CallType constant CALLTYPE_SINGLE = CallType.wrap(0x00);
// Batched CallType
CallType constant CALLTYPE_BATCH = CallType.wrap(0x01);

CallType constant CALLTYPE_STATIC = CallType.wrap(0xFE);

// @dev Implementing delegatecall is OPTIONAL!
// implement delegatecall with extreme care.
CallType constant CALLTYPE_DELEGATECALL = CallType.wrap(0xFF);

// @dev default behavior is to revert on failure
// To allow very simple accounts to use mode encoding, the default behavior is to revert on failure
// Since this is value 0x00, no additional encoding is required for simple accounts
ExecType constant EXECTYPE_DEFAULT = ExecType.wrap(0x00);
// @dev account may elect to change execution behavior. For example "try exec" / "allow fail"
ExecType constant EXECTYPE_TRY = ExecType.wrap(0x01);

ModeSelector constant MODE_DEFAULT = ModeSelector.wrap(bytes4(0x00000000));
// Example declaration of a custom mode selector
ModeSelector constant MODE_OFFSET = ModeSelector.wrap(bytes4(keccak256("default.mode.offset")));
// ERC-7821 Batch with opData
ModeSelector constant MODE_BATCH_OPDATA = ModeSelector.wrap(bytes4(0x78210001));
// ERC-7821 Batch of Batches with opData
ModeSelector constant MODE_BATCH_OF_BATCHES_OPDATA = ModeSelector.wrap(bytes4(0x78210002));

/// @dev ModeLib is a helper library to encode/decode ModeCodes
library ModeLib {
    function decode(
        ExecutionMode mode
    ) internal pure returns (CallType _calltype, ExecType _execType, ModeSelector _modeSelector, ModePayload _modePayload) {
        assembly {
            _calltype := mode
            _execType := shl(8, mode)
            _modeSelector := shl(48, mode)
            _modePayload := shl(80, mode)
        }
    }

    function decodeBasic(ExecutionMode mode) internal pure returns (CallType _calltype, ExecType _execType) {
        assembly {
            _calltype := mode
            _execType := shl(8, mode)
        }
    }

    function encode(CallType callType, ExecType execType, ModeSelector mode, ModePayload payload) internal pure returns (ExecutionMode) {
        return ExecutionMode.wrap(bytes32(abi.encodePacked(callType, execType, bytes4(0), ModeSelector.unwrap(mode), payload)));
    }

    function encodeSimpleBatch() internal pure returns (ExecutionMode mode) {
        mode = encode(CALLTYPE_BATCH, EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00));
    }

    function encodeSimpleSingle() internal pure returns (ExecutionMode mode) {
        mode = encode(CALLTYPE_SINGLE, EXECTYPE_DEFAULT, MODE_DEFAULT, ModePayload.wrap(0x00));
    }

    function encodeTrySingle() internal pure returns (ExecutionMode mode) {
        mode = encode(CALLTYPE_SINGLE, EXECTYPE_TRY, MODE_DEFAULT, ModePayload.wrap(0x00));
    }

    function encodeTryBatch() internal pure returns (ExecutionMode mode) {
        mode = encode(CALLTYPE_BATCH, EXECTYPE_TRY, MODE_DEFAULT, ModePayload.wrap(0x00));
    }

    function encodeCustom(CallType callType, ExecType execType) internal pure returns (ExecutionMode mode) {
        mode = encode(callType, execType, MODE_DEFAULT, ModePayload.wrap(0x00));
    }

    function getCallType(ExecutionMode mode) internal pure returns (CallType calltype) {
        assembly {
            calltype := mode
        }
    }
}

using { _eqModeSelector as == } for ModeSelector global;
using { _eqCallType as == } for CallType global;
using { _uneqCallType as != } for CallType global;
using { _eqExecType as == } for ExecType global;

function _eqCallType(CallType a, CallType b) pure returns (bool) {
    return CallType.unwrap(a) == CallType.unwrap(b);
}

function _uneqCallType(CallType a, CallType b) pure returns (bool) {
    return CallType.unwrap(a) != CallType.unwrap(b);
}

function _eqExecType(ExecType a, ExecType b) pure returns (bool) {
    return ExecType.unwrap(a) == ExecType.unwrap(b);
}

//slither-disable-next-line dead-code
function _eqModeSelector(ModeSelector a, ModeSelector b) pure returns (bool) {
    return ModeSelector.unwrap(a) == ModeSelector.unwrap(b);
}
