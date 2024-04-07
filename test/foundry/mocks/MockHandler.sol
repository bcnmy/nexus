// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.23;

/* solhint-disable no-empty-blocks */

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IFallback, MODULE_TYPE_FALLBACK } from "contracts/interfaces/modules/IERC7579Modules.sol";
import { IModule } from "contracts/interfaces/modules/IModule.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import "../utils/EventsAndErrors.sol";

contract MockHandler is IFallback {
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

    /// @inheritdoc IModule
    function onInstall(bytes calldata data) external override { }

    /// @inheritdoc IModule
    function onUninstall(bytes calldata data) external override { }

    /// @inheritdoc IModule
    function isModuleType(uint256 moduleTypeId) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_FALLBACK;
    }

    function getModuleTypes() external view override returns (EncodedModuleTypes) { }

    // Review
    function test() public pure {
        // @todo To be removed
    }
}
