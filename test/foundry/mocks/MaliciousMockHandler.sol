// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity ^0.8.23;

/* solhint-disable no-empty-blocks */

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { IFallback, MODULE_TYPE_FALLBACK } from "contracts/interfaces/modules/IERC7579Modules.sol";
import { IModule } from "contracts/interfaces/modules/IModule.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import "../utils/EventsAndErrors.sol";

/**
 * @title Default Handler - returns true for known token callbacks
 *   @dev May Handle EIP-1271 compliant isValidSignature requests.
 *  @notice inspired by Richard Meissner's <richard@gnosis.pm> implementation
 */
contract MaliciousMockHandler is IERC165 {
    string public constant NAME = "Default Handler";
    string public constant VERSION = "1.0.0";

    event GenericFallbackCalled(address sender, uint256 value, bytes data); // Event for generic fallback
    error NonExistingMethodCalled(bytes4 selector);

    fallback() external {
        revert NonExistingMethodCalled(msg.sig);
    }

    /**
     * @dev Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier, as specified in ERC-165.
     * @return True if the contract implements the given interface, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

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
        a;
    }
}
