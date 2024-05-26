// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.26;

// import "../../utils/Imports.sol";
// import "../../utils/NexusTest_Base.t.sol";

// contract TestFuzz_AccountFactory_Deployment is NexusTest_Base {
//     function setUp() public {
//         init();
//     }

//     function testFuzz_CreateAccountWithRandomData(uint256 randomSeed) public {
//         Vm.Wallet memory randomUser = createAndFundWallet("RandomUser", 1 ether);
//         bytes memory initData = abi.encodePacked(randomUser.addr, randomSeed);

//         address payable expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, 0);
//         address payable deployedAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);

//         assertEq(deployedAccountAddress, expectedAddress, "Deployed account address should match expected address");
//     }

//     function testFuzz_CreateAccountWithLargeIndex(uint256 largeIndex) public {
//         Vm.Wallet memory randomUser = createAndFundWallet("RandomUser", 1 ether);
//         bytes memory initData = abi.encodePacked(randomUser.addr, largeIndex);

//         address payable expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, largeIndex);
//         address payable deployedAccountAddress = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, largeIndex);

//         assertEq(deployedAccountAddress, expectedAddress, "Deployed account address should match expected address for large index");
//     }

//     function testFuzz_RepeatedAccountCreation(uint256 randomSeed) public {
//         Vm.Wallet memory randomUser = createAndFundWallet("RandomUser", 1 ether);
//         bytes memory initData = abi.encodePacked(randomUser.addr, randomSeed);

//         address payable expectedAddress = FACTORY.getCounterFactualAddress(address(VALIDATOR_MODULE), initData, 0);

//         // First deployment
//         address payable deployedAccountAddress1 = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
//         assertEq(deployedAccountAddress1, expectedAddress, "First deployment address should match expected address");

//         // Attempt to deploy the same account again
//         address payable deployedAccountAddress2 = FACTORY.createAccount(address(VALIDATOR_MODULE), initData, 0);
//         assertEq(deployedAccountAddress2, expectedAddress, "Repeated deployment address should match expected address");
//     }
// }
