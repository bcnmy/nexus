// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

event ModuleInstalled(uint256 moduleTypeId, address module);

event ModuleUninstalled(uint256 moduleTypeId, address module);

event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

abstract contract TestModuleManagement_Base is Test, NexusTest_Base {
    MockValidator public mockValidator;
    MockExecutor public mockExecutor;
    MockHandler public mockHandler;
    MockHook public mockHook;

    address public constant INVALID_MODULE_ADDRESS = address(0);
    uint256 public constant INVALID_MODULE_TYPE = 999;

    bytes4 public constant GENERIC_FALLBACK_SELECTOR = 0xcb5baf0f;
    bytes4 public constant UNUSED_SELECTOR = 0xdeadbeef;
    // More shared state variables if needed

    function setUpModuleManagement_Base() internal {
        init(); // Initialize the testing environment if necessary

        // Setup mock validator and executor, different from those possibly already used
        mockValidator = new MockValidator();
        mockExecutor = new MockExecutor();
        mockHandler = new MockHandler();
        mockHook = new MockHook();

        // Additional shared setup can go here
    }

    // Shared utility and helper functions to install/uninstall modules
    function installModule(bytes memory callData, uint256 moduleTypeId, address moduleAddress, ExecType execType) internal {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, execType, execution, address(VALIDATOR_MODULE));

        vm.expectEmit(true, true, true, true);
        emit ModuleInstalled(moduleTypeId, moduleAddress);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function uninstallModule(bytes memory callData, ExecType execType) internal {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Similar to installModule but for uninstallation
        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, execType, execution, address(VALIDATOR_MODULE));

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }
}
