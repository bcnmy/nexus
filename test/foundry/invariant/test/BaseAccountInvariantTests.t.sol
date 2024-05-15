// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import "../../utils/SmartAccountTestLab.t.sol";

contract BaseAccountInvariantTests is SmartAccountTestLab {
    MockValidator internal validator;
    Vm.Wallet internal signer;
    Nexus internal nexusAccount;

    function setUp() public {
        init();

        // Initialize the MockValidator and associate it with nexusAccount
        validator = new MockValidator();

        signer = newWallet("Signer");
        vm.deal(signer.addr, 100 ether);
        vm.deal(address(nexusAccount), 100 ether);
        nexusAccount = deployAccountWithCustomValidator(signer, 10 ether, address(validator));

        bytes memory installData = abi.encodePacked(signer.addr);

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({
            target: address(validator),
            value: 0,
            callData: abi.encodeWithSelector(MockValidator.onInstall.selector, installData)
        });

        PackedUserOperation[] memory userOps = prepareUserOperationWithCustomValidator(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(validator)
        );
        ENTRYPOINT.handleOps(userOps, payable(address(signer.addr)));

        // Ensure validator is correctly set up for nexusAccount
        assertEq(validator.getOwner(address(nexusAccount)), signer.addr, "Validator setup failed");

        excludeContract(address(validator));
        excludeContract(address(VALIDATOR_MODULE));
        excludeContract(address(EXECUTOR_MODULE));
        excludeContract(address(HANDLER_MODULE));
        excludeContract(address(HOOK_MODULE));
    }

    // Invariant to ensure deposit balance integrity with tolerance for gas costs
    function invariant_depositBalanceConsistency() public {
        uint256 initialBalance = nexusAccount.getDeposit();
        uint256 depositAmount = 1 ether;
        uint256 tolerance = 0.01 ether;

        // Adjust balance with vm.deal to simulate deposit.
        vm.deal(address(nexusAccount), initialBalance + depositAmount + 1 ether);

        // Deposit 1 ether to nexusAccount from signer.
        vm.prank(signer.addr);
        nexusAccount.addDeposit{ value: 1 ether }();

        // Check if the deposit reflects correctly within the tolerance
        uint256 postDepositBalance = nexusAccount.getDeposit();
        assertApproxEqRel(postDepositBalance, initialBalance + depositAmount, tolerance, "Deposit balance invariant failed after deposit.");

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(
            address(nexusAccount),
            0,
            abi.encodeWithSelector(nexusAccount.withdrawDepositTo.selector, address(signer.addr), depositAmount)
        );

        PackedUserOperation[] memory userOps = prepareUserOperationWithCustomValidator(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(validator)
        );
        ENTRYPOINT.handleOps(userOps, payable(address(signer.addr)));

        // Verify the post-withdrawal balance within the tolerance
        uint256 finalBalance = nexusAccount.getDeposit();
        assertApproxEqRel(finalBalance, initialBalance, tolerance, "Deposit balance invariant failed after withdrawal.");
    }

    // Invariant to test access control for withdrawal
    function invariant_accessControl() public {
        try nexusAccount.withdrawDepositTo(address(this), 1 ether) {
            fail("withdrawDepositTo should fail when not called through ENTRYPOINT");
        } catch {}
    }

    // Invariant to ensure consistent nonce handling
    function invariant_nonceConsistency() public {
        uint256 initialNonce = getNonce(address(nexusAccount), address(validator));

        // Create a transaction that affects nonce
        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution(address(nexusAccount), 0.4 ether, abi.encodeWithSelector(nexusAccount.addDeposit.selector));

        PackedUserOperation[] memory userOps = prepareUserOperationWithCustomValidator(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(validator)
        );
        ENTRYPOINT.handleOps(userOps, payable(address(signer.addr)));

        uint256 updatedNonce = getNonce(address(nexusAccount), address(validator));
        assertGe(updatedNonce, initialNonce + 1, "Nonce should increment correctly.");
    }

    // Invariant to ensure consistent nonce handling with multiple operations
    function invariant_multiOperationNonceConsistency() public {
        uint256 initialNonce = getNonce(address(nexusAccount), address(validator));

        // Simulate multiple operations
        for (uint i = 0; i < 3; i++) {
            Execution[] memory executions = _prepareSingleExecution(
                address(nexusAccount),
                0.4 ether,
                abi.encodeWithSelector(nexusAccount.addDeposit.selector)
            );
            PackedUserOperation[] memory userOps = prepareUserOperationWithCustomValidator(
                signer,
                nexusAccount,
                EXECTYPE_DEFAULT,
                executions,
                address(validator)
            );
            ENTRYPOINT.handleOps(userOps, payable(address(signer.addr)));
        }

        uint256 finalNonce = getNonce(address(nexusAccount), address(validator));
        assertGe(finalNonce, initialNonce + 3, "Nonce should increment by 3 after three operations.");
    }

    // Invariant to ensure consistent nonce handling with multiple operations in a single handleOps call
    function invariant_multiOperationNonceConsistency_SingleCall() public {
        // Prepare multiple executions to be processed together
        Execution[] memory execution = _prepareSingleExecution(
            address(nexusAccount),
            0.4 ether,
            abi.encodeWithSelector(nexusAccount.addDeposit.selector)
        );

        // Create an array of PackedUserOperations
        PackedUserOperation[] memory userOps = new PackedUserOperation[](3);
        userOps[0] = prepareUserOperationWithCustomValidator(signer, nexusAccount, EXECTYPE_DEFAULT, execution, address(validator))[0];
        userOps[1] = prepareUserOperationWithCustomValidator(signer, nexusAccount, EXECTYPE_DEFAULT, execution, address(validator))[0];
        userOps[2] = prepareUserOperationWithCustomValidator(signer, nexusAccount, EXECTYPE_DEFAULT, execution, address(validator))[0];

        uint256 initialNonce = getNonce(address(nexusAccount), address(validator));
        // Set proper nonce values for each user operation
        for (uint i = 0; i < userOps.length; i++) {
            userOps[i].nonce = initialNonce + i;
            userOps[i].signature = signUserOp(signer, userOps[i]);
        }

        // Process all operations in a single call
        ENTRYPOINT.handleOps(userOps, payable(address(signer.addr)));

        uint256 finalNonce = getNonce(address(nexusAccount), address(validator));
        assertGe(finalNonce, initialNonce + 3, "Nonce should increment by 3 after three operations.");
    }
}
