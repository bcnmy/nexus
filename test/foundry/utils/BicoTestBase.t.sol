// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24 <0.9.0;


import "./Helpers.sol";
import "forge-std/src/console2.sol";

contract BicoTestBase is Helpers {
    SmartAccount public implementation;
    SmartAccount public smartAccount;

    function init() public {
        setAddress();
        implementation = new SmartAccount();
    }

    function deploySmartAccount(Vm.Wallet memory wallet) public returns (address) {
        address account = getAccountAddress(wallet.addr);
        address signer = wallet.addr;

        bytes memory initCode = createInitCode(wallet.addr, FACTORY.createAccount.selector);

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);
        userOps[0] = buildPackedUserOp(account, _getNonce(account, address(VALIDATOR_MODULE)));

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
