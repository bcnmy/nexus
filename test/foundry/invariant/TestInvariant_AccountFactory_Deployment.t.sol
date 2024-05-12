// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../utils/Imports.sol";
import "../utils/SmartAccountTestLab.t.sol";

contract TestInvariant_AccountFactory_Deployment is SmartAccountTestLab {
    address payable expectedAddress;
    bytes initData;

    function setUp() public {
        init();
        Vm.Wallet memory user = createAndFundWallet("user", 1 ether);
        initData = abi.encodePacked(user.addr);
        expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, 0);
    }

    function invariantTest_AccountDeploymentConsistency() public {
        address payable deployedAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
        assertEq(deployedAccountAddress, expectedAddress, "Deployed account address should consistently match the expected address");

        // Check re-initialization protection
        vm.prank(deployedAccountAddress);
        vm.expectRevert(LinkedList_AlreadyInitialized.selector);
        INexus(deployedAccountAddress).initialize(address(VALIDATOR_MODULE), initData);
    }
}
