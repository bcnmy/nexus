// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.27;

import { IFallback } from "../interfaces/modules/IFallback.sol";
import { MODULE_TYPE_FALLBACK } from "..//types/Constants.sol";

contract MockHandler is IFallback {
    uint256 public count;
    string constant NAME = "Default Handler";
    string constant VERSION = "1.0.0";

    event GenericFallbackCalled(address sender, uint256 value, bytes data); // Event for generic fallback
    event HandlerOnInstallCalled(bytes32 dataFirstWord);

    error NonExistingMethodCalled(bytes4 selector);

    fallback() external {
        revert NonExistingMethodCalled(msg.sig);
    }

    // Example function to manually trigger the fallback mechanism
    function onGenericFallback(address sender, uint256 value, bytes calldata data) external returns (bytes4) {
        emit GenericFallbackCalled(sender, value, data);
        return this.onGenericFallback.selector;
    }

    function complexReturnData(string memory input, bytes4 selector) external view returns (uint256, bytes memory, address, uint64, address) {
        return (
            uint256(block.timestamp),
            abi.encode(input, NAME, VERSION, selector),
            address(this),
            uint64(block.chainid),
            _msgSender()
        );
    }

    function onInstall(bytes calldata data) external override {
        if (data.length >= 0x20) {
            emit HandlerOnInstallCalled(bytes32(data[0:32]));
        }
    }

    function onUninstall(bytes calldata data) external override {}

    function isModuleType(uint256 moduleTypeId) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_FALLBACK;
    }

    function isInitialized(address) external pure override returns (bool) {
        return false;
    }

    function stateChangingFunction() external {
        count++;
    }

    function successFunction() external pure returns (bytes32) {
        return keccak256("SUCCESS");
    }

    function revertingFunction() external pure {
        revert("REVERT");
    }

    function getState() external view returns (uint256) {
        return count;
    }

    function getName() external pure returns (string memory) {
        return NAME;
    }

    function getVersion() external pure returns (string memory) {
        return VERSION;
    }

    function _msgSender() internal pure returns (address sender) {
        // The assembly code is more direct than the Solidity version using `abi.decode`.
        /* solhint-disable no-inline-assembly */
        /// @solidity memory-safe-assembly
        assembly {
            sender := shr(96, calldataload(sub(calldatasize(), 20)))
        }
        /* solhint-enable no-inline-assembly */
    }
}
