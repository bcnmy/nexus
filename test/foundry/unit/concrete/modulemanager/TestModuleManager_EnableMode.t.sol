// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import "../../shared/TestModuleManagement_Base.t.sol";
import "contracts/mocks/Counter.sol";
import { Solarray } from "solarray/Solarray.sol";
import { MODE_VALIDATION, MODE_MODULE_ENABLE, MULTITYPE_MODULE, MODULE_TYPE_VALIDATOR, MODULE_TYPE_EXECUTOR, MODULE_ENABLE_MODE_TYPE_HASH } from "contracts/types/Constants.sol";
import "solady/src/utils/EIP712.sol";

contract TestModuleManager_EnableMode is Test, TestModuleManagement_Base {

    MockMultiModule mockMultiModule;
    Counter public counter;
    bytes32 internal constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    function setUp() public {
        setUpModuleManagement_Base();
        mockMultiModule = new MockMultiModule();
        counter = new Counter();
    }

    function test_EnableMode_Success() public {
        address moduleToEnable = address(mockMultiModule);

        uint256 nonce = getNonce(BOB_ADDRESS, MODE_MODULE_ENABLE, moduleToEnable);
        PackedUserOperation memory op = buildPackedUserOp(address(BOB_ACCOUNT), nonce);

        op.callData = prepareERC7579SingleExecuteCallData(
            EXECTYPE_DEFAULT, 
            address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector)
        );
        
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(op);
        op.signature = signMessage(ALICE, userOpHash);  // SIGN THE ACCOUNT WITH SIGNER THAT IS ABOUT TO BE USED

        // prepare Enable Mode Data
        bytes32 validatorConfig = bytes32(bytes20(ALICE_ADDRESS)); //set Alice as owner via MultiTypeModule
        bytes32 executorConfig = bytes32(uint256(0x2222));

        bytes memory validatorInstallData = abi.encodePacked(
            bytes1(uint8(MODULE_TYPE_VALIDATOR)),
            validatorConfig
        );

        bytes memory executorInstallData = abi.encodePacked(
            bytes1(uint8(MODULE_TYPE_EXECUTOR)),
            executorConfig
        );

        uint256[] memory types = Solarray.uint256s(MODULE_TYPE_VALIDATOR, MODULE_TYPE_EXECUTOR);
        bytes[] memory initDatas = Solarray.bytess(validatorInstallData, executorInstallData);

        bytes memory multiInstallData = abi.encode(
            types,
            initDatas
        );

        // prepare Enable Mode Signature
        bytes32 structHash = keccak256(abi.encode(
            MODULE_ENABLE_MODE_TYPE_HASH, 
            address(mockMultiModule), 
            keccak256(multiInstallData)
        ));
        (,string memory name,string memory version,,,,) = EIP712(address(BOB_ACCOUNT)).eip712Domain();
        bytes32 hashToSign = _hashTypedData(structHash, name, version, address(BOB_ACCOUNT));

        bytes memory enableModeSig = signMessage(BOB, hashToSign); //should be signed by current owner
        enableModeSig = abi.encodePacked(address(VALIDATOR_MODULE), enableModeSig); //append validator address

        // Enable Mode Sig Prefix
        // uint256 moduleTypeId
        // bytes4 initDataLength
        // initData
        // bytes4 enableModeSig length
        // enableModeSig
        bytes memory enableModeSigPrefix = abi.encodePacked(
            MULTITYPE_MODULE,
            bytes4(uint32(multiInstallData.length)),
            multiInstallData,
            bytes4(uint32(enableModeSig.length)),
            enableModeSig
        );

        op.signature = abi.encodePacked(enableModeSigPrefix, op.signature);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = op;

        uint256 counterBefore = counter.getNumber();
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        assertEq(counter.getNumber(), counterBefore+1, "Counter should have been incremented after single execution");
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockMultiModule), ""),
            "Module should be installed as validator"
        );
        assertTrue(
            BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockMultiModule), ""),
            "Module should be installed as executor"
        );
    }


    // ==========

    function _hashTypedData(
        bytes32 structHash,
        string memory name,
        string memory version,
        address verifyingContract
    ) internal view virtual returns (bytes32 digest) {
        digest = _buildDomainSeparator(name, version, verifyingContract);
        /// @solidity memory-safe-assembly
        assembly {
            // Compute the digest.
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, digest) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }
    }

    /// @dev Returns the EIP-712 domain separator.
    function _buildDomainSeparator(string memory name, string memory version, address verifyingContract) private view returns (bytes32 separator) {
        bytes32 nameHash = keccak256(bytes(name));
        bytes32 versionHash = keccak256(bytes(version));
        /// @solidity memory-safe-assembly
        assembly {
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), nameHash) // Name hash.
            mstore(add(m, 0x40), versionHash)
            mstore(add(m, 0x60), chainid())
            mstore(add(m, 0x80), verifyingContract)
            separator := keccak256(m, 0xa0)
        }
    }

    
}
