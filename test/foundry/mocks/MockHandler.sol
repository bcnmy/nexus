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
contract MockHandler is IERC165, IERC721Receiver, IFallback {
    string public constant NAME = "Default Handler";
    string public constant VERSION = "1.0.0";

    event FallbackHandlerTriggered();
    error NonExistingMethodCalled(bytes4 selector);

    fallback() external {
        revert NonExistingMethodCalled(msg.sig);
    }

    /**
     * @dev Checks if the contract supports a given interface.
     * @param interfaceId The interface identifier, as specified in ERC-165.
     * @return True if the contract implements the given interface, false otherwise.
     */
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return interfaceId == type(IERC721Receiver).interfaceId
            || interfaceId == type(IERC165).interfaceId;
    }

    /**
     * @dev Handles the receipt of an ERC721 token.
     * @return The interface selector for the called function.
     */
    function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
        emit FallbackHandlerTriggered();
        return IERC721Receiver.onERC721Received.selector;
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
    function test(uint256 a) public pure {
        a;
    }
}
