// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.26;

import { IFallback } from "contracts/interfaces/modules/IFallback.sol";
import { MODULE_TYPE_FALLBACK } from "../../contracts/types/Constants.sol";

contract MockHandler is IFallback {
    uint256 public count;
    string public constant NAME = "Default Handler";
    string public constant VERSION = "1.0.0";

    event GenericFallbackCalled(address sender, uint256 value, bytes data); // Event for generic fallback

    error NonExistingMethodCalled(bytes4 selector);

    fallback() external {
        revert NonExistingMethodCalled(msg.sig);
    }

    // Example function to manually trigger the fallback mechanism
    function onGenericFallback(address sender, uint256 value, bytes calldata data) external returns (bytes4) {
        emit GenericFallbackCalled(sender, value, data);
        return this.onGenericFallback.selector;
    }

    function onInstall(bytes calldata data) external override {}

    function onUninstall(bytes calldata data) external override {}

    function isModuleType(uint256 moduleTypeId) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_FALLBACK;
    }

    function isInitialized(address) external pure override returns (bool) {
        return false;
    }

    function staticFunction() external pure returns (bytes32) {
        return keccak256("STATIC_CALL");
    }

    function stateChangingFunction() external {
        count++;
    }

    function singleFunction() external pure returns (bytes32) {
        return keccak256("SINGLE_CALL");
    }

    function batchFunction() external pure returns (bytes32) {
        return keccak256("BATCH_CALL");
    }

    function revertingStaticFunction() external pure {
        require(false, "Static call revert reason");
    }

    function revertingSingleFunction() external pure {
        require(false, "Single call revert reason");
    }

    function gasIntensiveFunction() external {
        while (true) {
            count++;
        }
    }

    function dynamicFunction() external pure returns (bytes32) {
        return keccak256("DYNAMIC_CALL");
    }

    function getState() external view returns (uint256) {
        return count;
    }
}
