// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../utils/Imports.sol";
import "../../utils/NexusTest_Base.t.sol";

/// PoC for the disclosed "stale transient init flag" report.
///
/// NexusProxy's constructor sets the Initializable transient flag and never
/// clears it. EIP-1153 transient storage persists for the whole transaction,
/// so a second initializeAccount() call in the SAME transaction that deployed
/// the account still passes requireInitializable() and re-runs an
/// attacker-controlled bootstrap in the victim account context.
contract StaleInitFlagPoC is NexusTest_Base {
    function setUp() public {
        init();
    }

    function _victimInitData(address owner) internal view returns (bytes memory initData, bytes32 salt) {
        BootstrapConfig[] memory validators =
            BootstrapLib.createArrayConfig(address(VALIDATOR_MODULE), abi.encodePacked(owner));
        BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(0), "");
        initData = abi.encode(
            address(BOOTSTRAPPER),
            abi.encodeCall(
                BOOTSTRAPPER.initNexusScoped,
                (validators, hook, RegistryConfig({ registry: REGISTRY, attesters: ATTESTERS, threshold: THRESHOLD }))
            )
        );
        salt = keccak256("poc-counterfactual");
    }

    // Reproduces the reported attack and asserts the fix blocks it. On the
    // vulnerable contract the attacker's second initializeAccount passed (stale
    // transient flag) and drained the prefunded ETH. With requireInitializable()
    // consuming the flag, that second call reverts with NotInitializable, the
    // whole attacker transaction reverts, and the funds stay untouched.
    function test_reinit_in_same_tx_is_blocked_by_fix() public {
        address victimOwner = address(0x1111111111111111111111111111111111111111);
        address attacker = address(0xa77ac6000000000000000000000000000000A77a);

        (bytes memory victimInit, bytes32 salt) = _victimInitData(victimOwner);
        address payable account = FACTORY.computeAccountAddress(victimInit, salt);

        // Victim prefunds the counterfactual address before deployment.
        vm.deal(account, 10 ether);

        // Attacker's second init points at a malicious bootstrap that, run via
        // delegatecall in the victim account context, would sweep the ETH.
        MaliciousBootstrap evil = new MaliciousBootstrap();
        bytes memory attackerInit =
            abi.encode(address(evil), abi.encodeCall(MaliciousBootstrap.sweep, (attacker)));

        // Deploy the victim account and re-init it in ONE attacker transaction.
        // The re-init must revert, reverting the whole attacker transaction.
        Attacker a = new Attacker();
        vm.expectRevert(); // NotInitializable() from the consumed flag
        a.run(address(FACTORY), victimInit, salt, account, attackerInit);

        // Funds remain at the (still undeployed) victim address; attacker got nothing.
        assertEq(account.balance, 10 ether, "victim funds must be untouched");
        assertEq(attacker.balance, 0, "attacker must not receive funds");
    }

    function test_control_reinit_in_separate_tx_reverts() public {
        address victimOwner = address(0x1111111111111111111111111111111111111111);
        (bytes memory victimInit, bytes32 salt) = _victimInitData(victimOwner);
        address payable account = FACTORY.computeAccountAddress(victimInit, salt);

        // Deploy in one transaction.
        FACTORY.createAccount(victimInit, salt);

        // A re-init in a SEPARATE transaction must revert: the transient flag
        // was cleared at the end of the deploying tx.
        vm.expectRevert();
        INexus(account).initializeAccount(victimInit);
    }
}

contract Attacker {
    function run(
        address factory,
        bytes calldata victimInit,
        bytes32 salt,
        address account,
        bytes calldata attackerInit
    ) external {
        NexusAccountFactory(factory).createAccount(victimInit, salt);
        INexus(account).initializeAccount(attackerInit);
    }
}

/// Runs via delegatecall in the victim account's context from _initializeAccount.
/// isInitialized() stays true (the victim's validator from the first init is
/// still installed), so the final require(isInitialized()) passes.
contract MaliciousBootstrap {
    function sweep(address to) external {
        (bool ok,) = to.call{ value: address(this).balance }("");
        require(ok, "sweep failed");
    }
}
