// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import "../shared/TestModuleManagement_Base.t.sol";

contract TestFuzz_ModuleManager is TestModuleManagement_Base {
    function setUp() public {
        setUpModuleManagement_Base();
    }

    // Fuzz testing module installation with random data
    function testFuzz_InstallModule_TypeRandom(uint256 randomTypeId, address randomAddress) public {
        // Ensure the fuzzed type is within the expected range and not the correct type for the given address
        vm.assume(randomTypeId < 1000 && randomTypeId > 4);
        vm.assume(randomAddress != address(0) && randomAddress != address(mockValidator)); // Exclude zero and correct validator address

        // Encode call data for attempting to install a module incorrectly
        bytes memory callData = abi.encodeWithSelector(IModuleManager.installModule.selector, randomTypeId, randomAddress, "");

        // Preparing operations
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);

        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Verify that the module was not installed incorrectly
        assertFalse(
            BOB_ACCOUNT.isModuleInstalled(randomTypeId, randomAddress, ""),
            "Module should not be installed with incorrect type or unauthorized address"
        );
    }

    // Fuzz testing for fallback handler installation
    function testFuzz_InstallFallbackHandler_RandomSelector(bytes4 selector) public {
        bytes memory customData = abi.encode(selector);
        bytes memory callData = abi.encodeWithSelector(
            IModuleManager.installModule.selector,
            MODULE_TYPE_FALLBACK,
            address(HANDLER_MODULE),
            customData
        );

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, executions);

        // Use ENTRYPOINT.handleOps to simulate actual transaction processing
        ENTRYPOINT.handleOps(userOps, payable(BOB.addr));

        // Verify the fallback handler was installed for the given selector
        assertTrue(BOB_ACCOUNT.isModuleInstalled(MODULE_TYPE_FALLBACK, address(HANDLER_MODULE), customData), "Fallback handler not installed");
    }
}
