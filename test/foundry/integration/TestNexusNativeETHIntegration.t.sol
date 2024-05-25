// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

/// @title TestNexusNativeETHIntegration
/// @notice Tests Nexus smart account functionalities with native ETH transfers
contract TestNexusNativeETHIntegration is NexusTest_Base {
    Vm.Wallet private user;
    MockPaymaster private paymaster;
    address payable private preComputedAddress;
    address private constant recipient = payable(address(0x123));
    uint256 private constant transferAmount = 1 ether;

    /// @notice Modifier to check ETH balance changes
    /// @param account The account to check the balance for
    /// @param expectedBalance The expected balance change
    modifier checkETHBalance(address account, uint256 expectedBalance) {
        uint256 initialBalance = account.balance;
        _;
        uint256 finalBalance = account.balance;
        assertEq(finalBalance, initialBalance + expectedBalance);
    }

    /// @notice Sets up the initial state for the tests
    function setUp() public {
        init();
        user = createAndFundWallet("user", 1 ether);
        paymaster = new MockPaymaster(address(ENTRYPOINT));
        ENTRYPOINT.depositTo{ value: 10 ether }(address(paymaster));

        vm.deal(address(paymaster), 100 ether);
        preComputedAddress = payable(calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));
        payable(address(preComputedAddress)).transfer(10 ether);
    }

    /// @notice Tests gas consumption for a simple ETH transfer
    function test_Gas_NativeETH_SimpleTransfer_UsingTransfer() public checkETHBalance(recipient, transferAmount) {
        prank(BOB.addr);
        uint256 initialGas = gasleft();
        payable(recipient).transfer(transferAmount);
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("NativeETH::SimpleTransfer::Gas used for simple ETH transfer using transfer", gasUsed);
    }

    /// @notice Tests gas consumption for a simple ETH transfer
    function test_Gas_NativeETH_SimpleTransfer_UsingCall() public checkETHBalance(recipient, transferAmount) {
        prank(BOB.addr);
        bool res;
        uint256 initialGas = gasleft();
        (res, ) = payable(recipient).call{ value: transferAmount }("");
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("NativeETH::SimpleTransfer::Gas used for simple ETH transfer using Call", gasUsed);
    }

    /// @notice Tests gas consumption for a simple ETH transfer
    function test_Gas_NativeETH_SimpleTransfer_UsingSend() public checkETHBalance(recipient, transferAmount) {
        prank(BOB.addr);
        bool res;
        uint256 initialGas = gasleft();
        res = payable(recipient).send(transferAmount);
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("NativeETH::SimpleTransfer::Gas used for simple ETH transfer using Call", gasUsed);
    }

    /// @notice Tests sending ETH from an already deployed Nexus smart account
    function test_Gas_NativeETH_DeployedNexusTransfer() public checkETHBalance(recipient, transferAmount) {
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));

        assertEq(address(deployedNexus), calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));
        Execution[] memory executions = prepareSingleExecution(recipient, transferAmount, "");

        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(BUNDLER.addr));
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("NativeETH::DeployedNexusTransfer::Gas used for sending ETH from deployed Nexus", gasUsed);
    }

    /// @notice Tests deploying Nexus and transferring ETH using a paymaster
    function test_Gas_NativeETH_DeployAndTransferWithPaymaster() public checkETHBalance(recipient, transferAmount) {
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        Execution[] memory executions = prepareSingleExecution(recipient, transferAmount, "");

        PackedUserOperation[] memory userOps = new PackedUserOperation[](1);

        userOps = buildPackedUserOperation(user, Nexus(preComputedAddress), EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        userOps[0].initCode = initCode;

        // Including paymaster address and additional data
        userOps[0].paymasterAndData = abi.encodePacked(
            address(paymaster),
            uint128(3e6), // verification gas limit
            uint128(3e6) // postOp gas limit
        );

        uint256 initialGas = gasleft();

        userOps[0].signature = signUserOp(user, userOps[0]);
        ENTRYPOINT.handleOps(userOps, BUNDLER_ADDRESS);
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("NativeETH::DeployAndTransferWithPaymaster::Gas used for deploying Nexus and sending ETH with paymaster", gasUsed);
    }

    /// @notice Tests deploying Nexus and transferring ETH using deposited funds without a paymaster
    function test_Gas_NativeETH_DeployAndTransferUsingDeposit() public checkETHBalance(recipient, transferAmount) {
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

        uint256 initialGas = gasleft();

        // Sign the user operation
        userOps[0].signature = signUserOp(user, userOps[0]);
        ENTRYPOINT.handleOps(userOps, BUNDLER_ADDRESS);

        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("NativeETH::DeployAndTransferUsingDeposit::Gas used for deploying Nexus and transferring ETH using deposit", gasUsed);
    }
}
