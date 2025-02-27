// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/NexusTest_Base.t.sol";
import "../../../shared/TestModuleManagement_Base.t.sol";
import "contracts/mocks/Counter.sol";
import { Solarray } from "solarray/Solarray.sol";
import { MODE_VALIDATION, MODE_MODULE_ENABLE, MODULE_TYPE_MULTI, MODULE_TYPE_VALIDATOR, MODULE_TYPE_EXECUTOR, MODULE_ENABLE_MODE_TYPE_HASH } from "contracts/types/Constants.sol";

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

    string constant MODULE_ENABLE_MODE_NOTATION = "ModuleEnableMode(address module,uint256 moduleType,bytes32 userOpHash,bytes32 initDataHash)";

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
        op.signature = signMessage(ALICE, userOpHash);  // SIGN THE USEROP WITH SIGNER THAT IS ABOUT TO BE USED

        (bytes memory multiInstallData, bytes32 hashToSign, ) = makeInstallDataAndHash(address(BOB_ACCOUNT), MODULE_TYPE_MULTI, userOpHash);

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

    function test_EnableMode_Uninitialized_7702_Account() public {
        address moduleToEnable = address(mockMultiModule);
        address opValidator = address(mockMultiModule);

        // make the account out of BOB itself
        uint256 nonce = getNonce(BOB_ADDRESS, MODE_MODULE_ENABLE, moduleToEnable, bytes3(0));

        PackedUserOperation memory op = buildPackedUserOp(BOB_ADDRESS, nonce);

        op.callData = prepareERC7579SingleExecuteCallData(
            EXECTYPE_DEFAULT, 
            address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector)
        );
        
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(op);
        op.signature = signMessage(ALICE, userOpHash);  // SIGN THE USEROP WITH SIGNER THAT IS ABOUT TO BE USED

        // simulate uninitialized 7702 account
        vm.etch(BOB_ADDRESS, address(ACCOUNT_IMPLEMENTATION).code);

        (bytes memory multiInstallData, bytes32 hashToSign, ) = makeInstallDataAndHash(BOB_ADDRESS, MODULE_TYPE_MULTI, userOpHash);

        bytes memory enableModeSig = signMessage(BOB, hashToSign); //should be signed by current owner
        enableModeSig = abi.encodePacked(DEFAULT_VALIDATOR_FLAG, enableModeSig); //append validator address

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
            INexus(BOB_ADDRESS).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockMultiModule), ""),
            "Module should be installed as validator"
        );
        assertTrue(
            INexus(BOB_ADDRESS).isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockMultiModule), ""),
            "Module should be installed as executor"
        );
    }

    // we do not test 7739 personal sign, as with personal sign makes enable data hash is unreadable
    function test_EnableMode_Success_7739_Nested_712() public {
        address moduleToEnable = address(mockMultiModule);
        address opValidator = address(mockMultiModule);

        PackedUserOperation memory op = makeDraftOp(opValidator);
        
        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(op);
        op.signature = signMessage(ALICE, userOpHash);  // SIGN THE USEROP WITH SIGNER THAT IS ABOUT TO BE USED

        (bytes memory multiInstallData, /*bytes32 eip712ChildHash*/, bytes32 structHash) = makeInstallDataAndHash(address(BOB_ACCOUNT), MODULE_TYPE_MULTI, userOpHash);

        // app is just account itself in this case
        bytes32 appDomainSeparator = _getDomainSeparator(address(BOB_ACCOUNT));
        
        bytes32 hashToSign = toERC1271Hash(structHash, address(BOB_ACCOUNT), appDomainSeparator);

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

    function test_EnableMode_Success_DeployAccount() public {
        address moduleToEnable = address(mockMultiModule);
        address opValidator = address(mockMultiModule);

        //prepare owner
        Vm.Wallet memory EVE = createAndFundWallet("EVE", 1000 ether);
        address EVE_ADDRESS = EVE.addr;

        //prepare deployment userOp
        PackedUserOperation memory userOp;
        address payable accountAddress = calculateAccountAddress(EVE_ADDRESS, address(VALIDATOR_MODULE));
        ENTRYPOINT.depositTo{ value: 100 ether }(address(accountAddress));
        {
            bytes memory initCode = buildInitCode(EVE_ADDRESS, address(VALIDATOR_MODULE));
            userOp = buildUserOpWithInitAndCalldata(EVE, initCode, "", address(VALIDATOR_MODULE));
        }

        // make nonce
        {
            uint256 nonce = getNonce(accountAddress, MODE_MODULE_ENABLE, moduleToEnable, bytes3(0));
            assertEq(nonce<<196, 0); // nonce_sequence should be 0 for non-deployed acc
            userOp.nonce = nonce;
        }

        //make calldata
        userOp.callData = prepareERC7579SingleExecuteCallData(
            EXECTYPE_DEFAULT, 
            address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector)
        );

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOp);
        userOp.signature = signMessage(ALICE, userOpHash);  // SIGN THE USEROP WITH SIGNER THAT IS ABOUT TO BE USED VIA NEWLY INSTALLED (VIA ENABLE MODE) MODULE

        // since the account is not deployed yet, we can't get eip712 domain from it
        // so we take the structHash and manually convert it to proper 712 typed data hash
        (bytes memory multiInstallData, /*bytes32 hashToSign*/, bytes32 structHash) = makeInstallDataAndHash(address(BOB_ACCOUNT), MODULE_TYPE_MULTI, userOpHash);

        bytes32 eip712digest;
        //everything will be same except address(this)
        (
            /*bytes1 fields*/,
            string memory name,
            string memory version,
            uint256 chainId,
            /*address verifyingContract*/,
            /*bytes32 salt*/,
            /*uint256[] memory extensions*/
        ) = EIP712(address(BOB_ACCOUNT)).eip712Domain();
        
        /// @solidity memory-safe-assembly
        assembly {
            //Rebuild domain separator out of 712 domain
            let m := mload(0x40) // Load the free memory pointer.
            mstore(m, _DOMAIN_TYPEHASH)
            mstore(add(m, 0x20), keccak256(add(name, 0x20), mload(name))) // Name hash.
            mstore(add(m, 0x40), keccak256(add(version, 0x20), mload(version))) // Version hash.
            mstore(add(m, 0x60), chainId)
            mstore(add(m, 0x80), accountAddress) //use expected EVE account address
            eip712digest := keccak256(m, 0xa0) //domain separator

            // Hash typed data
            mstore(0x00, 0x1901000000000000) // Store "\x19\x01".
            mstore(0x1a, eip712digest) // Store the domain separator.
            mstore(0x3a, structHash) // Store the struct hash.
            eip712digest := keccak256(0x18, 0x42)
            // Restore the part of the free memory slot that was overwritten.
            mstore(0x3a, 0)
        }

        bytes memory enableModeSig = signMessage(EVE, eip712digest); //should be signed by current owner
        enableModeSig = abi.encodePacked(address(VALIDATOR_MODULE), enableModeSig); //append validator address
        bytes memory enableModeSigPrefix = abi.encodePacked(
            moduleToEnable,
            MODULE_TYPE_MULTI,
            bytes4(uint32(multiInstallData.length)),
            multiInstallData,
            bytes4(uint32(enableModeSig.length)),
            enableModeSig
        );

        userOp.signature = abi.encodePacked(enableModeSigPrefix, userOp.signature);
        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = userOp;

        uint256 counterBefore = counter.getNumber();
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
        assertEq(counter.getNumber(), counterBefore+1, "Counter should have been incremented after single execution");

        //Should be deployed at this point
        Nexus EVE_ACCOUNT = Nexus(accountAddress);

        assertTrue(
            EVE_ACCOUNT.isModuleInstalled(MODULE_TYPE_VALIDATOR, address(mockMultiModule), ""),
            "Module should be installed as validator"
        );
        assertTrue(
            EVE_ACCOUNT.isModuleInstalled(MODULE_TYPE_EXECUTOR, address(mockMultiModule), ""),
            "Module should be installed as executor"
        );
    }

    function test_EnableMode_FailsWithWrongValidationModuleInEnableModeSig() public {
        address moduleToEnable = address(mockMultiModule);
        address opValidator = address(mockMultiModule);

        PackedUserOperation memory op = makeDraftOp(opValidator);

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(op);
        op.signature = signMessage(ALICE, userOpHash);  // SIGN THE USEROP WITH SIGNER THAT IS ABOUT TO BE USED
        (bytes memory multiInstallData, bytes32 hashToSign, ) = makeInstallDataAndHash(address(BOB_ACCOUNT), MODULE_TYPE_MULTI, userOpHash);
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
        (bytes memory multiInstallData, bytes32 hashToSign, ) = makeInstallDataAndHash(address(BOB_ACCOUNT), MODULE_TYPE_MULTI, userOpHash);
        
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

        (bytes memory multiInstallData, bytes32 hashToSign, ) = makeInstallDataAndHash(address(BOB_ACCOUNT), MODULE_TYPE_MULTI, userOpHash);

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

        (bytes memory multiInstallData, bytes32 hashToSign, ) = makeInstallDataAndHash(address(BOB_ACCOUNT), MODULE_TYPE_EXECUTOR, userOpHash);  // Use EXECUTOR type instead of MULTI

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
            abi.encodeWithSelector(ValidatorNotInstalled.selector, address(moduleToEnable))
        );

        vm.expectRevert(expectedRevertReason);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    // ==========

    function makeDraftOp(address moduleToEnable) internal view returns (PackedUserOperation memory op) {
        uint256 nonce = getNonce(address(BOB_ACCOUNT), MODE_MODULE_ENABLE, moduleToEnable, bytes3(0));
        op = buildPackedUserOp(address(BOB_ACCOUNT), nonce);

        op.callData = prepareERC7579SingleExecuteCallData(
            EXECTYPE_DEFAULT, 
            address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector)
        );
    }

    function makeInstallDataAndHash(address account, uint256 moduleType, bytes32 userOpHash) internal view returns (bytes memory multiInstallData, bytes32 eip712Hash, bytes32 structHash) {
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
        eip712Hash = _hashTypedData(structHash, account);
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
                            "TypedDataSign(ModuleEnableMode contents,string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)",
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
        string name;
        string version;
        uint256 chainId;
        address verifyingContract;
        bytes32 salt;
    }

    /// @notice Retrieves the EIP-712 domain struct fields.
    /// @param account The account address.
    /// @return The encoded EIP-712 domain struct fields.
    function accountDomainStructFields(address account) internal view returns (bytes memory) {
        AccountDomainStruct memory t;
        (/*t.fields*/, t.name, t.version, t.chainId, t.verifyingContract, t.salt, /*t.extensions*/) = EIP712(account).eip712Domain();

        return
            abi.encode(
                keccak256(bytes(t.name)),
                keccak256(bytes(t.version)),
                t.chainId,
                t.verifyingContract, // Use the account address as the verifying contract.
                t.salt
            );
    }

    
}