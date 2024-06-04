// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

/// @title TestNexusERC20Token_Integration_WarmAccess
/// @notice Tests Nexus smart account functionalities with ERC20 token transfers (Warm Access)
contract TestNexusERC20Token_Integration_WarmAccess is NexusTest_Base {
    Vm.Wallet private user;
    MockToken private ERC20Token;
    MockPaymaster private paymaster;
    uint256 private amount = 1_000_000 * 1e18;
    address payable private preComputedAddress;
    address private constant recipient = address(0x123);

    /// @notice Modifier to check ERC20 token balance changes with warm access
    /// @param account The account to check the balance for
    /// @param expectedBalance The expected balance after the operation
    modifier checkERC20TokenBalanceWarm(address account, uint256 expectedBalance) {
        ERC20Token.transfer(account, 1);
        assertGt(ERC20Token.balanceOf(account), 0, "Account balance is zero (warm access)");
        _;
        uint256 finalBalance = ERC20Token.balanceOf(account);
        assertEq(finalBalance, expectedBalance + 1);
    }

    /// @notice Sets up the initial state for the tests
    function setUp() public {
        init();
        user = createAndFundWallet("user", 1 ether);
        ERC20Token = new MockToken("Mock ERC20Token", "MOCK");
        paymaster = new MockPaymaster(address(ENTRYPOINT), BUNDLER_ADDRESS);
        ENTRYPOINT.depositTo{ value: 10 ether }(address(paymaster));

        vm.deal(address(paymaster), 100 ether);
        preComputedAddress = payable(calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));
        ERC20Token.transfer(preComputedAddress, amount);
    }

    /// @notice Tests gas consumption for a simple ERC20 token transfer with warm access
    function test_Gas_ERC20Token_Simple_Transfer_Warm() public checkERC20TokenBalanceWarm(recipient, amount) {
        measureAndLogGasEOA(
            "2::ERC20::transfer::EOA::Simple::WarmAccess",
            address(ERC20Token),
            0,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
        );
    }

    /// @notice Tests sending ERC20 tokens from an already deployed Nexus smart account with warm access
    function test_Gas_ERC20Token_DeployedNexus_Transfer_Warm() public checkERC20TokenBalanceWarm(recipient, amount) {
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));
        ERC20Token.transfer(address(deployedNexus), amount);

        assertEq(address(deployedNexus), calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));
        Execution[] memory executions = prepareSingleExecution(
            address(ERC20Token),
            0,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        measureAndLogGas("4::ERC20::transfer::Nexus::Deployed::WarmAccess", userOps);
    }

    /// @notice Tests deploying Nexus and transferring ERC20 tokens using a paymaster with warm access
    function test_Gas_ERC20Token_DeployWithPaymaster_Transfer_Warm()
        public
        checkERC20TokenBalanceWarm(recipient, amount)
        checkPaymasterBalance(address(paymaster))
    {
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
        userOps[0].paymasterAndData = generateAndSignPaymasterData(userOps[0], BUNDLER, paymaster);

        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("6::ERC20::transfer::Setup And Call::WithPaymaster::WarmAccess", userOps);
    }

    /// @notice Test deploying Nexus and transferring ERC20 tokens using deposited funds without a paymaster with warm access
    function test_Gas_ERC20Token_DeployUsingDeposit_Transfer_Warm() public checkERC20TokenBalanceWarm(recipient, amount) {
        uint256 depositAmount = 1 ether;

        // Add deposit to the precomputed address
        ENTRYPOINT.depositTo{ value: depositAmount }(preComputedAddress);

        uint256 newBalance = ENTRYPOINT.balanceOf(preComputedAddress);
        assertEq(newBalance, depositAmount);

        // Create initCode for deploying the Nexus account
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        // Prepare execution to transfer ERC20 tokens
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
        // Sign the user operation
        userOps[0].signature = signUserOp(user, userOps[0]);
        measureAndLogGas("8::ERC20::transfer::Setup And Call::UsingDeposit::WarmAccess", userOps);
    }

    /// @notice Test sending ETH to the Nexus account before deployment and then deploy with warm access
    function test_Gas_DeployNexusWithPreFundedETH_Warm() public checkERC20TokenBalanceWarm(recipient, amount) {
        // Send ETH directly to the precomputed address
        vm.deal(preComputedAddress, 1 ether);
        assertEq(address(preComputedAddress).balance, 1 ether, "ETH not sent to precomputed address");

        // Create initCode for deploying the Nexus account
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        // Prepare execution to transfer ERC20 tokens
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
        // Sign the user operation
        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("10::ERC20::transfer::Setup And Call::Using Pre-Funded Ether::WarmAccess", userOps);
    }

    /// @notice Tests gas consumption for transferring ERC20 tokens from an already deployed Nexus smart account using a paymaster
    function test_Gas_ERC20Token_DeployedNexus_Transfer_WithPaymaster_Warm()
        public
        checkERC20TokenBalanceWarm(recipient, amount)
        checkPaymasterBalance(address(paymaster))
    {
        // Ensure the paymaster has a sufficient deposit
        assertGe(ENTRYPOINT.balanceOf(address(paymaster)), 1 ether, "Insufficient paymaster deposit");

        // Deploy Nexus account
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));
        ERC20Token.transfer(address(deployedNexus), amount);

        // Prepare the execution for ERC20 token transfer
        Execution[] memory executions = prepareSingleExecution(
            address(ERC20Token),
            0,
            abi.encodeWithSignature("transfer(address,uint256)", recipient, amount)
        );

        // Build the PackedUserOperation array
        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        // Generate and sign paymaster data
        userOps[0].paymasterAndData = generateAndSignPaymasterData(userOps[0], BUNDLER, paymaster);

        // Sign the user operation
        userOps[0].signature = signUserOp(user, userOps[0]);

        // Measure and log gas usage
        measureAndLogGas("12::ERC20::transfer::Nexus::WithPaymaster::WarmAccess", userOps);
    }
}
