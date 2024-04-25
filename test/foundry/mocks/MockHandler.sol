// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.23;

/* solhint-disable no-empty-blocks */

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IERC7579ModuleBase } from "contracts/interfaces/modules/IERC7579ModuleBase.sol";
import { IFallback } from "contracts/interfaces/modules/IFallback.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import "../utils/EventsAndErrors.sol";
import { MODULE_TYPE_FALLBACK } from "../../../contracts/types/Constants.sol";

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

    function onInstall(bytes calldata data) external override { }

    function onUninstall(bytes calldata data) external override { }

    function isModuleType(uint256 moduleTypeId) external pure override returns (bool) {
        return moduleTypeId == MODULE_TYPE_FALLBACK;
    }

    function isInitialized(address) external pure override returns (bool) {
        return false;
    }

    // Review
    function test() public pure {
        // @todo To be removed
    }
}
