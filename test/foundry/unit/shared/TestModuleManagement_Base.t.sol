// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import "../../utils/SmartAccountTestLab.t.sol";
import { Nexus } from "../../../../contracts/Nexus.sol";
import { MockHook } from "../../../../contracts/mocks/MockHook.sol";
import { MockHandler } from "../../../../contracts/mocks/MockHandler.sol";
import { MockExecutor } from "../../../../contracts/mocks/MockExecutor.sol";
import { MockValidator } from "../../../../contracts/mocks/MockValidator.sol";

event ModuleInstalled(uint256 moduleTypeId, address module);

event ModuleUninstalled(uint256 moduleTypeId, address module);

event UserOperationRevertReason(bytes32 indexed userOpHash, address indexed sender, uint256 nonce, bytes revertReason);

abstract contract TestModuleManagement_Base is Test, SmartAccountTestLab {
    MockHook public mockHook;
    MockHandler public mockHandler;
    MockExecutor public mockExecutor;
    MockRegistry public mockRegistry;
    MockValidator public mockValidator;
    address public constant INVALID_MODULE_ADDRESS = address(0);
    uint256 public constant INVALID_MODULE_TYPE = 999;

    bytes4 public constant GENERIC_FALLBACK_SELECTOR = 0xcb5baf0f;
    bytes4 public constant UNUSED_SELECTOR = 0xdeadbeef;
    // More shared state variables if needed

    function setUpModuleManagement_Base() internal {
        init(); // Initialize the testing environment if necessary

        // Setup mock validator and executor, different from those possibly already used
        mockHook = new MockHook();
        mockHandler = new MockHandler();
        mockExecutor = new MockExecutor();
        mockRegistry = new MockRegistry();
        mockValidator = new MockValidator();

        // Additional shared setup can go here
    }

    // Shared utility and helper functions to install/uninstall modules
    function installModule(
        bytes memory callData,
        uint256 moduleTypeId,
        address moduleAddress,
        ExecType execType
    )
        internal
    {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, execType, execution);

        vm.expectEmit(true, true, true, true);
        emit ModuleInstalled(moduleTypeId, moduleAddress);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function uninstallModule(bytes memory callData, ExecType execType) internal {
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        // Similar to installModule but for uninstallation
        PackedUserOperation[] memory userOps = preparePackedUserOperation(BOB, BOB_ACCOUNT, execType, execution);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }

    function setRegistry(address _registry) internal {
        bytes memory callData = abi.encodeWithSelector(
            Nexus.setModuleRegistry.selector,
            _registry
        );

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution);
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));
    }
}
