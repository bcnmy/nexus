// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

contract UpgradeSmartAccountTest is NexusTest_Base {

    function setUp() public {
        init();
    }
    /// @notice Tests the upgrade of the smart account implementation
    function test_upgradeSmartAccount() public {
        Nexus newSmartAccount = new Nexus();
        bytes32 slot = ACCOUNT_IMPLEMENTATION.proxiableUUID();
        
        // Check if the slot matches the expected UUID
        assertEq(slot, 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc, "Proxiable UUID mismatch");

        address currentImplementation = BOB_ACCOUNT.getImplementation();
        assertEq(currentImplementation, address(ACCOUNT_IMPLEMENTATION), "Current implementation address mismatch");

        bytes memory callData = abi.encodeWithSelector(Nexus.upgradeToAndCall.selector, address(newSmartAccount), "");

        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(BOB_ACCOUNT), 0, callData);

        PackedUserOperation[] memory userOps = buildPackedUserOperation(BOB, BOB_ACCOUNT, EXECTYPE_DEFAULT, execution, address(VALIDATOR_MODULE));

        ENTRYPOINT.handleOps(userOps, payable(address(BOB.addr)));

        address newImplementation = BOB_ACCOUNT.getImplementation();
        assertEq(newImplementation, address(newSmartAccount), "New implementation address mismatch");
    }
}
