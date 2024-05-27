// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

/// @title TestNexusERC20TokenIntegration
/// @notice Tests Nexus smart account functionalities with ERC20Token token transfers
contract TestNexusERC20TokenIntegration is NexusTest_Base {
    Vm.Wallet private user;
    MockToken private ERC20Token;
    MockPaymaster private paymaster;
    uint256 private amount = 1_000_000 * 1e18;
    address payable private preComputedAddress;
    address private constant recipient = address(0x123);

    /// @notice Modifier to check ERC20Token balance changes
    /// @param account The account to check the balance for
    /// @param expectedBalance The expected balance after the operation
    modifier checkERC20TokenBalance(address account, uint256 expectedBalance) {
        uint256 initialBalance = ERC20Token.balanceOf(account);
        _;
        uint256 finalBalance = ERC20Token.balanceOf(account);
        assertEq(finalBalance, initialBalance + expectedBalance);
    }

    /// @notice Sets up the initial state for the tests
    function setUp() public {
        init();
        user = createAndFundWallet("user", 1 ether);
        ERC20Token = new MockToken("Mock ERC20Token", "MOCK");
        paymaster = new MockPaymaster(address(ENTRYPOINT));
        ENTRYPOINT.depositTo{ value: 10 ether }(address(paymaster));

        vm.deal(address(paymaster), 100 ether);
        preComputedAddress = payable(calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));
        ERC20Token.transfer(preComputedAddress, amount);
    }

    /// @notice Tests gas consumption for a simple ERC20Token transfer
    function test_Gas_ERC20Token_Simple_Transfer() public checkERC20TokenBalance(recipient, amount) {
        uint256 initialGas = gasleft();
        ERC20Token.transfer(recipient, amount);
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("ERC20Token::transfer::SimpleTransfer::Gas used for ERC20Token transfer", gasUsed);
    }

    /// @notice Tests sending ERC20Token from an already deployed Nexus smart account
    function test_Gas_ERC20Token_DeployedNexus_Transfer() public checkERC20TokenBalance(recipient, amount) {
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));
        ERC20Token.transfer(address(deployedNexus), amount);

        assertEq(address(deployedNexus), calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));
        Execution[] memory executions = prepareSingleExecution(
            address(ERC20Token),
            0,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(BUNDLER.addr));
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("ERC20Token::transfer::DeployedNexusTransfer::Gas used for sending ERC20Token from deployed Nexus", gasUsed);
    }

    /// @notice Tests deploying Nexus and transferring ERC20Token tokens using a paymaster
    function test_Gas_ERC20Token_DeployWithPaymaster_Transfer() public checkERC20TokenBalance(recipient, amount) {
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        Execution[] memory executions = prepareSingleExecution(
            address(ERC20Token),
            0,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
        );

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
        emit log_named_uint(
            "ERC20Token::transfer::DeployWithPaymasterTransfer::Gas used for deploying Nexus and sending ERC20Token with paymaster",
            gasUsed
        );
    }

    /// @notice Test deploying Nexus and transferring ERC20Token tokens using deposited funds without a paymaster
    function test_Gas_ERC20Token_DeployUsingDeposit_Transfer() public checkERC20TokenBalance(recipient, amount) {
        uint256 depositAmount = 1 ether;

        // Add deposit to the precomputed address
        ENTRYPOINT.depositTo{ value: depositAmount }(preComputedAddress);

        uint256 newBalance = ENTRYPOINT.balanceOf(preComputedAddress);
        assertEq(newBalance, depositAmount);

        // Create initCode for deploying the Nexus account
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        // Prepare execution to transfer ERC20Token tokens
        Execution[] memory executions = prepareSingleExecution(
            address(ERC20Token),
            0,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
        );

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
        emit log_named_uint(
            "ERC20Token::transfer::DeployUsingDepositTransfer::Gas used for deploying Nexus and transferring ERC20Token using deposit",
            gasUsed
        );
    }
}
