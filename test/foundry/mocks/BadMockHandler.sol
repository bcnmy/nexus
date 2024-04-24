// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.23;

/* solhint-disable no-empty-blocks */

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import "../utils/EventsAndErrors.sol";
import { MODULE_TYPE_FALLBACK } from "../../../contracts/types/Constants.sol";

/**
 * @title Bad Mock Handler - Impossible to Uninstall
 */
contract BadMockHandler {
    string public constant NAME = "Bad Handler";
    string public constant VERSION = "1.0.0";

    event GenericFallbackCalled(address sender, uint256 value, bytes data); // Event for generic fallback

    error NonExistingMethodCalled(bytes4 selector);
    // Example function to manually trigger the fallback mechanism

    function onGenericFallback(address sender, uint256 value, bytes calldata data) external returns (bytes4) {
        emit GenericFallbackCalled(sender, value, data);
        return this.onGenericFallback.selector;
    }

    function onInstall(bytes calldata data) external { }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return moduleTypeId == MODULE_TYPE_FALLBACK;
    }

    function getModuleTypes() external view returns (EncodedModuleTypes) { }

    // Review
    function test(uint256 a) public pure {
        // @todo To be removed: This function is used to ignore file in coverage report
    }
}
