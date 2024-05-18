// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import "../../utils/NexusTest_Base.t.sol";

contract TestFuzz_AccountFactory_Deployment is NexusTest_Base {
    function setUp() public {
        init();
    }

    function testFuzz_CreateAccountWithRandomData(uint256 randomSeed) public {
        Vm.Wallet memory randomUser = createAndFundWallet("RandomUser", 1 ether);
        bytes memory initData = abi.encodePacked(randomUser.addr, randomSeed);

        address payable expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, 0);
        address payable deployedAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);

        assertEq(deployedAccountAddress, expectedAddress, "Deployed account address should match expected address");
    }
}
