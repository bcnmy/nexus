// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.24 <0.9.0;

import "./Imports.sol";

contract BicoTestBase is PRBTest, StdCheats {
    IEntryPoint entrypoint;

    SmartAccount public implementation;
    SmartAccount public smartAccount;

    MockValidator mockValidator;

    address target;
    address payable alice;

    function setUp() public virtual {
        implementation = new SmartAccount();
        entrypoint = new EntryPoint();

        //@TODO: deploy account via Factory and EP
        smartAccount = new SmartAccount();
        vm.deal(address(smartAccount), 1000 ether);

        mockValidator = new MockValidator();

        target = address(0x69);
        alice = payable(address(0xa11ce));
    }

    // HELPERS
    function getNonce(address account, address validator) internal returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(address(validator))));
        nonce = entrypoint.getNonce(address(account), key);
    }
}
