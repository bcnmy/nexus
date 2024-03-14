// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../utils/Imports.sol";
import "../../../utils/BicoTestBase.t.sol";
import { MockExecutor } from "../../../mocks/MockExecutor.sol";
import { Counter } from "../../../mocks/Counter.sol";

error InvalidModule(address module);

contract TestAccountExecution_ExecuteFromExecutor is Test, BicoTestBase {
    SmartAccount public BOB_ACCOUNT;
    MockExecutor public mockExecutor;
    Counter public counter;

    function setUp() public {
        init();
        BOB_ACCOUNT = SmartAccount(deploySmartAccount(BOB));
        mockExecutor = new MockExecutor();
        counter = new Counter();

        // Install MockExecutor as executor module on BOB_ACCOUNT
        bytes memory callDataInstall = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            uint256(2),
            address(mockExecutor),
            ""
        );
        PackedUserOperation[] memory userOpsInstall = prepareExecutionUserOp(
            BOB,
            BOB_ACCOUNT,
            ModeLib.encodeSimpleSingle(),
            address(BOB_ACCOUNT),
            0,
            callDataInstall
        );
        ENTRYPOINT.handleOps(userOpsInstall, payable(address(BOB.addr)));
    }

