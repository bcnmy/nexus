// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

/// @title TestNexusNativeETH_Integration_ColdAccess
/// @notice Tests Nexus smart account functionalities with native ETH transfers (Cold Access)
contract TestNexusNativeETH_Integration_ColdAccess is NexusTest_Base {
    Vm.Wallet private user;
    MockPaymaster private paymaster;
    address payable private preComputedAddress;
    address private constant recipient = payable(address(0x123));
    uint256 private constant transferAmount = 1 ether;

    /// @notice Modifier to check ETH balance changes with cold access
    /// @param account The account to check the balance for
    /// @param expectedBalance The expected balance change
    modifier checkETHBalanceCold(address account, uint256 expectedBalance) {
        uint256 initialBalance = account.balance;
        assertEq(initialBalance, 0, "Account balance is not zero (cold access)");
        _;
        uint256 finalBalance = account.balance;
        assertEq(finalBalance, initialBalance + expectedBalance);
    }

    /// @notice Sets up the initial state for the tests
    function setUp() public {
        init();
        user = createAndFundWallet("user", 1 ether);
        paymaster = new MockPaymaster(address(ENTRYPOINT), BUNDLER_ADDRESS);
        ENTRYPOINT.depositTo{ value: 10 ether }(address(paymaster));

        vm.deal(address(paymaster), 100 ether);
        preComputedAddress = payable(calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));
        payable(address(preComputedAddress)).transfer(10 ether);
    }

    /// @notice Tests gas consumption for a simple ETH transfer
    function test_Gas_NativeETH_SimpleTransfer_UsingTransfer() public checkETHBalanceCold(recipient, transferAmount) {
        prank(BOB.addr);
        measureAndLogGasEOA("25::ETH::transfer::EOA::Simple::ColdAccess", recipient, transferAmount, "");
    }

    /// @notice Tests gas consumption for a simple ETH transfer using call
    function test_Gas_NativeETH_SimpleTransfer_UsingCall() public checkETHBalanceCold(recipient, transferAmount) {
        prank(BOB.addr);
        measureAndLogGasEOA(
            "27::ETH::call::EOA::Simple::ColdAccess",
            recipient,
            transferAmount,
            abi.encodeWithSignature("call{ value: transferAmount }('')")
        );
    }

    /// @notice Tests gas consumption for a simple ETH transfer using send
    function test_Gas_NativeETH_SimpleTransfer_UsingSend() public checkETHBalanceCold(recipient, transferAmount) {
        prank(BOB.addr);
        measureAndLogGasEOA("29::ETH::send::EOA::Simple::ColdAccess", recipient, transferAmount, abi.encodeWithSignature("send(transferAmount)"));
    }

    /// @notice Tests sending ETH from an already deployed Nexus smart account
    function test_Gas_NativeETH_DeployedNexusTransfer() public checkETHBalanceCold(recipient, transferAmount) {
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));

        assertEq(address(deployedNexus), calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));
        Execution[] memory executions = prepareSingleExecution(recipient, transferAmount, "");

        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        measureAndLogGas("31::ETH::transfer::Nexus::Deployed::ColdAccess", userOps);
    }

    /// @notice Tests deploying Nexus and transferring ETH using a paymaster
    function test_Gas_NativeETH_DeployAndTransferWithPaymaster()
        public
        checkETHBalanceCold(recipient, transferAmount)
        checkPaymasterBalance(address(paymaster))
    {
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        Execution[] memory executions = prepareSingleExecution(recipient, transferAmount, "");

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            Nexus(preComputedAddress),
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );

        userOps[0].initCode = initCode;

        // Including paymaster address and additional data
        userOps[0].paymasterAndData = generateAndSignPaymasterData(userOps[0], BUNDLER, paymaster);

        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("33::ETH::transfer::Setup And Call::WithPaymaster::ColdAccess", userOps);
    }

    /// @notice Tests deploying Nexus and transferring ETH using deposited funds without a paymaster
    function test_Gas_NativeETH_DeployAndTransferUsingDeposit() public checkETHBalanceCold(recipient, transferAmount) {
        uint256 depositAmount = 1 ether;

        // Add deposit to the precomputed address
        ENTRYPOINT.depositTo{ value: depositAmount }(preComputedAddress);

        uint256 newBalance = ENTRYPOINT.balanceOf(preComputedAddress);
        assertEq(newBalance, depositAmount);

        // Create initCode for deploying the Nexus account
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        // Prepare execution to transfer ETH
        Execution[] memory executions = prepareSingleExecution(recipient, transferAmount, "");

        // Build user operation with initCode and callData
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            Nexus(preComputedAddress),
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        userOps[0].initCode = initCode;

        // Sign the user operation
        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("35::ETH::transfer::Setup And Call::UsingDeposit::ColdAccess", userOps);
    }

    /// @notice Tests sending ETH to the Nexus account before deployment and then deploy with cold access
    function test_Gas_DeployNexusWithPreFundedETH_Cold() public checkETHBalanceCold(recipient, transferAmount) {
        // Send ETH directly to the precomputed address
        vm.deal(preComputedAddress, 10 ether);
        assertEq(address(preComputedAddress).balance, 10 ether, "ETH not sent to precomputed address");

        // Create initCode for deploying the Nexus account
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        // Prepare execution to transfer ETH
        Execution[] memory executions = prepareSingleExecution(recipient, transferAmount, "");

        // Build user operation with initCode and callData
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            Nexus(preComputedAddress),
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        userOps[0].initCode = initCode;
        // Sign the user operation
        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("37::ETH::transfer::Setup And Call::Using Pre-Funded Ether::ColdAccess", userOps);
    }

    /// @notice Tests gas consumption for transferring ETH from an already deployed Nexus smart account using a paymaster
    function test_Gas_NativeETH_DeployedNexus_Transfer_WithPaymaster_Cold()
        public
        checkETHBalanceCold(recipient, transferAmount)
        checkPaymasterBalance(address(paymaster))
    {
        // Deploy the Nexus account
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));

        // Prepare the execution for ETH transfer
        Execution[] memory executions = prepareSingleExecution(recipient, transferAmount, "");

        // Build the PackedUserOperation array
        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        // Generate and sign paymaster data
        userOps[0].paymasterAndData = generateAndSignPaymasterData(userOps[0], BUNDLER, paymaster);

        // Sign the user operation
        userOps[0].signature = signUserOp(user, userOps[0]);

        // Measure and log gas usage
        measureAndLogGas("39::ETH::transfer::Nexus::WithPaymaster::ColdAccess", userOps);
    }
}
