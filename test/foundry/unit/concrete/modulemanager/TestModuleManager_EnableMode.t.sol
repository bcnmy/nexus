// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/SmartAccountTestLab.t.sol";
import "../../shared/TestModuleManagement_Base.t.sol";
import "contracts/mocks/Counter.sol";
import { Solarray } from "solarray/Solarray.sol";
import { MODE_VALIDATION, MODE_MODULE_ENABLE } from "contracts/types/Constants.sol";

contract TestModuleManager_EnableMode is Test, TestModuleManagement_Base {

    MockMultiModule mockMultiModule;
    Counter public counter;

    function setUp() public {
        setUpModuleManagement_Base();
        mockMultiModule = new MockMultiModule();
        counter = new Counter();
    }

    function test_EnableMode_Success() public {
        address moduleToEnable = address(mockMultiModule);
        address bobAccountAddress = address(BOB_ACCOUNT);

        uint256 nonce = getNonce(bobAccountAddress, MODE_MODULE_ENABLE, moduleToEnable);
        PackedUserOperation memory op = buildPackedUserOp(bobAccountAddress, nonce);

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(counter), 0, abi.encodeWithSelector(Counter.incrementNumber.selector));
        bytes memory executionCalldata = prepareERC7579ExecuteCallData(EXECTYPE_DEFAULT, executions);
        

        // Enable Mode Sig Prefix
        // uint256 moduleTypeId
        // bytes4 initDataLength
        // initData
        // bytes4 enableModeSig length
        // enableModeSig


    }

    
}
