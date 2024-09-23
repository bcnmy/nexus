// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import { IModule } from "contracts/interfaces/modules/IModule.sol";
import { EncodedModuleTypes } from "contracts/lib/ModuleTypeLib.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";
import { ECDSA } from "solady/src/utils/ECDSA.sol";
import { SignatureCheckerLib } from "solady/src/utils/SignatureCheckerLib.sol";
import { MessageHashUtils } from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";
import "contracts/types/Constants.sol";
import { IERC7579Account } from "contracts/interfaces/IERC7579Account.sol";

contract MockSafe1271Caller is IModule {
    mapping(address smartAccount => uint256) balances;

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash) external returns (uint256) {

        address account = userOp.sender;

        // do something based on additional erc1271 sig
        (bytes memory data, bytes memory erc1271sig, bytes memory userOpSig) = abi.decode(userOp.signature, (bytes, bytes, bytes));
        bytes32 secureHash = keccak256(
            abi.encode(
                address(account),
                block.chainid,
                keccak256(data)
            )
        );
        if(IERC7579Account(account).isValidSignature(secureHash, erc1271sig) == ERC1271_MAGICVALUE) {
            balances[account]++;
        }
        return VALIDATION_SUCCESS;
    }

    function balanceOf(address smartAccount) external view returns (uint256) {
        return balances[smartAccount];
    }

    function onInstall(bytes calldata data) external override {

    }

    function onUninstall(bytes calldata data) external override {

    }

    function isModuleType(uint256 moduleTypeId) external pure returns (bool) {
        return
            moduleTypeId == MODULE_TYPE_VALIDATOR;
    }

    function isInitialized(address smartAccount) external view returns (bool) {
        return true;
    }
}
