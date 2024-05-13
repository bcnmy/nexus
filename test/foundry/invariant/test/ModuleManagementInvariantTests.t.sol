// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import "../handlers/ModuleManagementHandler.t.sol";

contract ModuleManagementInvariantTests is BaseInvariantTest {
    ModuleManagementHandler public handler;
    Nexus public nexusAccount;
    Vm.Wallet public signer;

    function setUp() public override {
        super.setUp();
        signer = newWallet("Signer");
        vm.deal(signer.addr, 100 ether);
        nexusAccount = deployAccount(signer, 1 ether);

        handler = new ModuleManagementHandler(nexusAccount, signer);

        // Setting up the test environment
        vm.deal(address(handler), 100 ether);
        // targetContract(address(handler));

        bytes4[] memory selectors = new bytes4[](2);
        selectors[0] = ModuleManagementHandler.installModule.selector;
        selectors[1] = ModuleManagementHandler.uninstallModule.selector;

        // // Set the fuzzer to only call the specified methods
        targetSelector(FuzzSelector({ addr: address(handler), selectors: selectors }));
    }

    function invariant_moduleInstallation() public {
        // Ensuring a module remains installed after a test cycle
        assertTrue(handler.checkModuleInstalled(1, address(VALIDATOR_MODULE)), "Invariant failed: Module should be installed.");
    }

    function invariant_moduleUninstallation() public {
        // Ensuring a module remains uninstalled after a test cycle
        assertFalse(handler.checkModuleInstalled(1, address(EXECUTOR_MODULE)), "Invariant failed: Module should be uninstalled.");
    }
}
