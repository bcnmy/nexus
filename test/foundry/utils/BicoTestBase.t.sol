// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24 <0.9.0;

import "./Helpers.sol";

contract BicoTestBase is Helpers {
    // Review: current below variable is of no use
    SmartAccount public implementation;
    SmartAccount public smartAccount;

    function init() public {
        setAddress();
        // Review: currently this is of no use
        implementation = new SmartAccount();
    }

    // Note: could be renamed to getDeployedSmartAccount
    // Note: should have method to get counterfactual account and initcode
    // Refer to the reference implementatino repo for this

    function deploySmartAccount(Vm.Wallet memory wallet) public returns (address payable) {
        address payable account = getAccountAddress(wallet.addr);
        address signer = wallet.addr;

        bytes memory initCode = createInitCode(wallet.addr, FACTORY.createAccount.selector);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(account, getNonce(account, address(VALIDATOR_MODULE)));

        userOps[0].initCode = initCode;

        bytes32 userOpHash = ENTRYPOINT.getUserOpHash(userOps[0]);

        userOps[0].signature = signMessageAndGetSignatureBytes(wallet, userOpHash);
        ENTRYPOINT.depositTo{ value: 100 ether }(account);
        ENTRYPOINT.handleOps(userOps, payable(wallet.addr));
        return account;
    }

    function testBico(uint256 a) public {
        a;
    }
}
