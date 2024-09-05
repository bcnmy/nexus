// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";
import "../../../shared/TestModuleManagement_Base.t.sol";
import "contracts/mocks/Counter.sol";
import { Solarray } from "solarray/Solarray.sol";
import { MODE_VALIDATION, MODE_MODULE_ENABLE, MODULE_TYPE_MULTI, MODULE_TYPE_VALIDATOR, MODULE_TYPE_EXECUTOR, MODULE_ENABLE_MODE_TYPE_HASH, MODULE_ENABLE_MODE_NOTATION } from "contracts/types/Constants.sol";
import "solady/src/utils/EIP712.sol";

contract TestModuleManager_EnableMode is Test, TestModuleManagement_Base {

    struct TestTemps {
        bytes32 userOpHash;
        bytes32 contents;
        address signer;
        uint256 privateKey;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 missingAccountFunds;
    }

    MockMultiModule mockMultiModule;
    Counter public counter;
    bytes32 internal constant _DOMAIN_TYPEHASH =
        0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

    function setUp() public {
        setUpModuleManagement_Base();
        mockMultiModule = new MockMultiModule();
        counter = new Counter();
    }

    function test_EnableMode_Success_No7739() public {
        address moduleToEnable = address(mockMultiModule);
        address opValidator = address(mockMultiModule);

        PackedUserOperation memory op = makeDraftOp(opValidator);
        
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(op);
        op.signature = signMessage(ALICE, userOpHash);  // SIGN THE ACCOUNT WITH SIGNER THAT IS ABOUT TO BE USED

        (bytes memory multiInstallData, bytes32 hashToSign, ) = makeInstallDataAndHash(MODULE_TYPE_MULTI, userOpHash);

        bytes memory enableModeSig = signMessage(BOB, hashToSign); //should be signed by current owner
        enableModeSig = abi.encodePacked(address(VALIDATOR_MODULE), enableModeSig); //append validator address
        // Enable Mode Sig Prefix
        // address moduleToEnable
        // uint256 moduleTypeId
        // bytes4 initDataLength
        // initData
        // bytes4 enableModeSig length
        // enableModeSig
        bytes memory enableModeSigPrefix = abi.encodePacked(
            moduleToEnable,
            MODULE_TYPE_MULTI,
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

    // we do not test 7739 personal sign, as with personal sign makes enable data hash is unreadable
    function test_EnableMode_Success_7739_Nested_712() public {
        address moduleToEnable = address(mockMultiModule);
        address opValidator = address(mockMultiModule);

        PackedUserOperation memory op = makeDraftOp(opValidator);
        
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(op);
        op.signature = signMessage(ALICE, userOpHash);  // SIGN THE ACCOUNT WITH SIGNER THAT IS ABOUT TO BE USED

        (bytes memory multiInstallData, /*bytes32 eip712ChildHash*/, bytes32 structHash) = makeInstallDataAndHash(MODULE_TYPE_MULTI, userOpHash);

        // app is just account itself in this case
        bytes32 appDomainSeparator = _buildDomainSeparator(address(BOB_ACCOUNT));
        
        bytes32 hashToSign = toERC1271Hash(structHash, address(BOB_ACCOUNT), appDomainSeparator);
        console2.log("nested 712 flow hash to sign");
        console2.logBytes32(hashToSign);

        TestTemps memory t;
        (t.v, t.r, t.s) = vm.sign(BOB.privateKey, hashToSign); //should be signed by current owner
        
        bytes memory contentsType = bytes(MODULE_ENABLE_MODE_NOTATION);
        bytes memory enableModeSig = abi.encodePacked(t.r, t.s, t.v, appDomainSeparator, structHash, contentsType, uint16(contentsType.length)); //prepare 7739 sig

        enableModeSig = abi.encodePacked(address(VALIDATOR_MODULE), enableModeSig); //append validator address
        bytes memory enableModeSigPrefix = abi.encodePacked(
            moduleToEnable,
            MODULE_TYPE_MULTI,
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

    function test_EnableMode_FailsWithWrongValidationModuleInEnableModeSig() public {
        address moduleToEnable = address(mockMultiModule);
        address opValidator = address(mockMultiModule);

        PackedUserOperation memory op = makeDraftOp(opValidator);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(op);
        op.signature = signMessage(ALICE, userOpHash);  // SIGN THE ACCOUNT WITH SIGNER THAT IS ABOUT TO BE USED
        (bytes memory multiInstallData, bytes32 hashToSign, ) = makeInstallDataAndHash(MODULE_TYPE_MULTI, userOpHash);
        bytes memory enableModeSig = signMessage(BOB, hashToSign); //should be signed by current owner
        address invalidValidator = address(0xdeaf);
        enableModeSig = abi.encodePacked(invalidValidator, enableModeSig);

        bytes memory enableModeSigPrefix = abi.encodePacked(
            moduleToEnable,
            MODULE_TYPE_MULTI,
            bytes4(uint32(multiInstallData.length)),
            multiInstallData,
            bytes4(uint32(enableModeSig.length)),
            enableModeSig
        );

        op.signature = abi.encodePacked(enableModeSigPrefix, op.signature);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = op;
        
        bytes memory expectedRevertReason = abi.encodeWithSelector(
            FailedOpWithRevert.selector, 
            0, 
            "AA23 reverted",
            abi.encodeWithSelector(ValidatorNotInstalled.selector, invalidValidator)
        );
        
        vm.expectRevert(expectedRevertReason);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function test_EnableMode_FailsWithWrongSig() public {
        address moduleToEnable = address(mockMultiModule);
        address opValidator = address(mockMultiModule);

        PackedUserOperation memory op = makeDraftOp(opValidator);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(op);
        op.signature = signMessage(ALICE, userOpHash); 
        (bytes memory multiInstallData, bytes32 hashToSign, ) = makeInstallDataAndHash(MODULE_TYPE_MULTI, userOpHash);
        
        bytes memory enableModeSig = signMessage(CHARLIE, hashToSign); // SIGN WITH NOT OWNER
        enableModeSig = abi.encodePacked(address(VALIDATOR_MODULE), enableModeSig);

        bytes memory enableModeSigPrefix = abi.encodePacked(
            moduleToEnable,
            MODULE_TYPE_MULTI,
            bytes4(uint32(multiInstallData.length)),
            multiInstallData,
            bytes4(uint32(enableModeSig.length)),
            enableModeSig
        );

        op.signature = abi.encodePacked(enableModeSigPrefix, op.signature);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = op;
        
        bytes memory expectedRevertReason = abi.encodeWithSelector(
            FailedOpWithRevert.selector, 
            0, 
            "AA23 reverted",
            abi.encodeWithSelector(EnableModeSigError.selector)
        );
        
        vm.expectRevert(expectedRevertReason);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function test_EnableMode_FailsWhenModuleAlreadyInstalled() public {
        address moduleToEnable = address(mockMultiModule);

        // Prepare valid data for installation
        bytes memory validInstallData = abi.encodePacked(
            uint8(MODULE_TYPE_VALIDATOR), // Module Type ID
            bytes32(0x0) // Example 32-byte config value
        );

        prank(address(BOB_ACCOUNT));
        BOB_ACCOUNT.installModule(MODULE_TYPE_VALIDATOR, moduleToEnable, validInstallData);

        PackedUserOperation memory op = makeDraftOp(moduleToEnable);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(op);
        op.signature = signMessage(ALICE, userOpHash); 

        (bytes memory multiInstallData, bytes32 hashToSign, ) = makeInstallDataAndHash(MODULE_TYPE_MULTI, userOpHash);

        bytes memory enableModeSig = signMessage(BOB, hashToSign); 
        enableModeSig = abi.encodePacked(address(VALIDATOR_MODULE), enableModeSig);

        bytes memory enableModeSigPrefix = abi.encodePacked(
            moduleToEnable,
            MODULE_TYPE_MULTI,
            bytes4(uint32(multiInstallData.length)),
            multiInstallData,
            bytes4(uint32(enableModeSig.length)),
            enableModeSig
        );

        bytes memory revertReason = abi.encodeWithSignature(
                "LinkedList_EntryAlreadyInList(address)", address(mockMultiModule)
            );

        op.signature = abi.encodePacked(enableModeSigPrefix, op.signature);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = op;

        bytes memory expectedRevertReason = abi.encodeWithSelector(
            FailedOpWithRevert.selector, 
            0, 
            "AA23 reverted",
            revertReason
        );

        vm.expectRevert(expectedRevertReason);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }


    function test_EnableMode_FailsWithWrongModuleType() public {
        address moduleToEnable = address(mockMultiModule);

        PackedUserOperation memory op = makeDraftOp(moduleToEnable);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(op);
        op.signature = signMessage(ALICE, userOpHash); 

        (bytes memory multiInstallData, bytes32 hashToSign, ) = makeInstallDataAndHash(MODULE_TYPE_EXECUTOR, userOpHash);  // Use EXECUTOR type instead of MULTI

        bytes memory enableModeSig = signMessage(BOB, hashToSign); 
        enableModeSig = abi.encodePacked(address(VALIDATOR_MODULE), enableModeSig);

        bytes memory enableModeSigPrefix = abi.encodePacked(
            moduleToEnable,
            MODULE_TYPE_EXECUTOR,  // Incorrect module type
            bytes4(uint32(multiInstallData.length)),
            multiInstallData,
            bytes4(uint32(enableModeSig.length)),
            enableModeSig
        );

        op.signature = abi.encodePacked(enableModeSigPrefix, op.signature);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = op;

        bytes memory expectedRevertReason = abi.encodeWithSelector(
            FailedOpWithRevert.selector, 
            0, 
            "AA23 reverted",
            abi.encodeWithSelector(InvalidModuleTypeId.selector, MODULE_TYPE_EXECUTOR)
        );

        vm.expectRevert(expectedRevertReason);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    // ==========

    function makeDraftOp(address moduleToEnable) internal view returns (PackedUserOperation memory op) {
        uint256 nonce = getNonce(BOB_ADDRESS, MODE_MODULE_ENABLE, moduleToEnable);
        op = buildPackedUserOp(address(BOB_ACCOUNT), nonce);

        op.callData = prepareERC7579SingleExecuteCallData(
            EXECTYPE_DEFAULT, 
            address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector)
        );
    }

    function makeInstallDataAndHash(uint256 moduleType, bytes32 userOpHash) internal view returns (bytes memory multiInstallData, bytes32 eip712Hash, bytes32 structHash) {
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

        multiInstallData = abi.encode(
            types,
            initDatas
        );

        // prepare Enable Mode Signature
        structHash = keccak256(abi.encode(
            MODULE_ENABLE_MODE_TYPE_HASH, 
            address(mockMultiModule),
            moduleType,
            userOpHash,
            keccak256(multiInstallData)
        ));
        eip712Hash = _hashTypedData(structHash, address(BOB_ACCOUNT));

        console2.log("Struct hash in test");
        console2.logBytes32(structHash);
        //console2.logBytes32(eip712Hash);
        //return (multiInstallData, eip712Hash, structHash);
    }

    function _hashTypedData(
        bytes32 structHash,
        address account
    ) internal view virtual returns (bytes32 digest) {
        digest = _buildDomainSeparator(account);
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
    function _buildDomainSeparator(address account) private view returns (bytes32 separator) {
        (,string memory name,string memory version,,address verifyingContract,,) = EIP712(address(account)).eip712Domain();
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

    /// @notice Generates an ERC-1271 hash for the given contents and account.
    /// @param contents The contents hash.
    /// @param account The account address.
    /// @return The ERC-1271 hash.
    function toERC1271Hash(bytes32 contents, address account, bytes32 appDomainSeparator) internal view returns (bytes32) {
        bytes32 parentStructHash = keccak256(
            abi.encodePacked(
                abi.encode(
                    keccak256(
                        abi.encodePacked(
                            "TypedDataSign(ModuleEnableMode contents,bytes1 fields,string name,string version,uint256 chainId,address verifyingContract,bytes32 salt,uint256[] extensions)",
                            MODULE_ENABLE_MODE_NOTATION
                        )
                    ),
                    contents
                ),
                accountDomainStructFields(account)
            )
        );
        return keccak256(abi.encodePacked("\x19\x01", appDomainSeparator, parentStructHash));
    }

    struct AccountDomainStruct {
        bytes1 fields;
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
        uint256[] extensions;
    }

    /// @notice Retrieves the EIP-712 domain struct fields.
    /// @param account The account address.
    /// @return The encoded EIP-712 domain struct fields.
    function accountDomainStructFields(address account) internal view returns (bytes memory) {
        AccountDomainStruct memory t;
        (t.fields, t.name, t.version, t.chainId, t.verifyingContract, t.salt, t.extensions) = EIP712(account).eip712Domain();

        return
            abi.encode(
                t.fields,
                keccak256(bytes(t.name)),
                keccak256(bytes(t.version)),
                t.chainId,
                t.verifyingContract, // Use the account address as the verifying contract.
                t.salt,
                keccak256(abi.encodePacked(t.extensions))
            );
    }

    
}