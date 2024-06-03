// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./BaseSettings.t.sol";
import "../../utils/Imports.sol";
import "../../shared/interfaces/IERC20.t.sol";
import "../../shared/interfaces/IUniswapV2Router02.t.sol";

/// @title TestNexusSwapETH_Integration
/// @notice Tests Nexus smart account functionalities with Uniswap V2 swaps
contract TestNexusSwapETH_Integration is BaseSettings {
    address payable private preComputedAddress;
    IUniswapV2Router02 public uniswapV2Router;
    MockPaymaster private paymaster;
    Vm.Wallet private user;
    address public swapper;
    IERC20 public usdc;

    uint256 public constant SWAP_AMOUNT = 1 ether; // 1 ETH for swap

    /// @notice Modifier to check ERC20 balance changes
    /// @param account The account to check the balance for
    /// @param expectedBalance The expected balance change
    modifier checkERC20Balance(address account, uint256 expectedBalance) {
        uint256 initialBalance = usdc.balanceOf(account);
        assertEq(initialBalance, 0, "Account balance is not zero");
        _;
        uint256 finalBalance = usdc.balanceOf(account);
        assertGe(finalBalance, 0, "Account balance is zero");
    }

    /// @notice Sets up the initial state for the tests
    function setUp() public {
        // Fork the Base network
        uint256 baseFork = vm.createFork(getBaseRpcUrl());
        vm.selectFork(baseFork);
        vm.rollFork(BLOCK_NUMBER);
        init();

        user = createAndFundWallet("user", 1 ether);
        swapper = vm.addr(2);

        usdc = IERC20(USDC_ADDRESS);
        uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER02);

        // Distribute ether to accounts
        vm.deal(swapper, 100 ether);

        // Initialize Nexus
        startPrank(swapper);
        paymaster = new MockPaymaster(address(ENTRYPOINT), BUNDLER_ADDRESS);
        ENTRYPOINT.depositTo{ value: 2 ether }(address(paymaster));
        paymaster.addStake{ value: 2 ether }(10 days);
        stopPrank();
        // vm.deal(address(paymaster), 100 ether);
        preComputedAddress = payable(calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));

        vm.deal(preComputedAddress, 100 ether);
    }

    /// @notice Tests gas consumption for swapping ETH for USDC using an EOA
    function test_Gas_Swap_EOA_SwapEthForTokens() public checkERC20Balance(swapper, SWAP_AMOUNT) {
        vm.startPrank(swapper);
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(usdc);

        measureAndLogGasEOA(
            "41::UniswapV2::swapExactETHForTokens::EOA::ETHtoUSDC::N/A",
            address(uniswapV2Router),
            SWAP_AMOUNT,
            abi.encodeWithSignature("swapExactETHForTokens(uint256,address[],address,uint256)", 0, path, swapper, block.timestamp)
        );

        vm.stopPrank();
    }

    /// @notice Tests gas consumption for swapping ETH for USDC using a deployed Nexus account
    function test_Gas_Swap_DeployedNexus_SwapEthForTokens() public checkERC20Balance(preComputedAddress, SWAP_AMOUNT) {
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));

        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router),
            SWAP_AMOUNT,
            abi.encodeWithSignature(
                "swapExactETHForTokens(uint256,address[],address,uint256)",
                0,
                getPathForETHtoUSDC(),
                address(deployedNexus),
                block.timestamp
            )
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        measureAndLogGas("42::UniswapV2::swapExactETHForTokens::Nexus::Deployed::N/A", userOps);
    }

    /// @notice Tests deploying Nexus and swapping ETH for USDC with Paymaster
    /// @dev Verifies that the paymaster has sufficient deposit, prepares and executes the swap, and logs gas usage.
    function test_Gas_Swap_DeployAndSwap_WithPaymaster()
        public
        checkERC20Balance(preComputedAddress, SWAP_AMOUNT)
        checkPaymasterBalance(address(paymaster))
    {
        // Prepare the swap execution details
        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router), // Uniswap V2 Router address
            SWAP_AMOUNT, // Amount of ETH to swap
            abi.encodeWithSignature(
                "swapExactETHForTokens(uint256,address[],address,uint256)", // Function signature
                0, // Minimum amount of tokens to receive (set to 0 for simplicity)
                getPathForETHtoUSDC(), // Path for the swap (ETH to USDC)
                preComputedAddress, // Recipient of the USDC
                block.timestamp // Deadline for the swap
            )
        );

        // Build the PackedUserOperation array
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user, // Wallet initiating the operation
            Nexus(preComputedAddress), // Nexus account precomputed address
            EXECTYPE_DEFAULT, // Execution type
            executions, // Execution details
            address(VALIDATOR_MODULE) // Validator module address
        );
        userOps[0].initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE)); // Set initCode for the operation

        // Generate and sign paymaster data
        userOps[0].paymasterAndData = generateAndSignPaymasterData(userOps[0], BUNDLER, paymaster);

        // Sign the entire user operation with the user's wallet
        userOps[0].signature = signUserOp(user, userOps[0]);

        // Measure and log gas usage for the operation
        measureAndLogGas("43::UniswapV2::swapExactETHForTokens::Setup And Call::WithPaymaster::N/A", userOps);
    }

    /// @notice Tests deploying Nexus and swapping ETH for USDC using deposit
    function test_Gas_Swap_DeployAndSwap_UsingDeposit() public checkERC20Balance(preComputedAddress, SWAP_AMOUNT) {
        uint256 depositAmount = 1 ether;
        ENTRYPOINT.depositTo{ value: depositAmount }(preComputedAddress);

        uint256 newBalance = ENTRYPOINT.balanceOf(preComputedAddress);
        assertEq(newBalance, depositAmount);

        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router),
            SWAP_AMOUNT,
            abi.encodeWithSignature(
                "swapExactETHForTokens(uint256,address[],address,uint256)",
                0,
                getPathForETHtoUSDC(),
                preComputedAddress,
                block.timestamp
            )
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            Nexus(preComputedAddress),
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );

        userOps[0].initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));
        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("44::UniswapV2::swapExactETHForTokens::Setup And Call::UsingDeposit::N/A", userOps);
    }

    /// @notice Tests sending ETH to the Nexus account before deployment and then deploy with Uniswap V2 swap
    function test_Gas_Swap_DeployNexusWithPreFundedETH() public checkERC20Balance(preComputedAddress, SWAP_AMOUNT) {
        // Send ETH directly to the precomputed address
        vm.deal(preComputedAddress, 10 ether);
        assertEq(address(preComputedAddress).balance, 10 ether, "ETH not sent to precomputed address");

        // Create initCode for deploying the Nexus account
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        // Prepare execution to swap ETH for USDC
        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router),
            SWAP_AMOUNT,
            abi.encodeWithSignature(
                "swapExactETHForTokens(uint256,address[],address,uint256)",
                0,
                getPathForETHtoUSDC(),
                preComputedAddress,
                block.timestamp
            )
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

        measureAndLogGas("45::UniswapV2::swapExactETHForTokens::Setup And Call::Using Pre-Funded Ether::N/A", userOps);
    }

    /// @notice Tests gas consumption for swapping ETH for USDC using a deployed Nexus account with Paymaster
    function test_Gas_Swap_DeployedNexus_SwapEthForTokens_WithPaymaster()
        public
        checkERC20Balance(preComputedAddress, SWAP_AMOUNT)
        checkPaymasterBalance(address(paymaster))
    {
        // Prepare the swap execution details
        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router), // Uniswap V2 Router address
            SWAP_AMOUNT, // Amount of ETH to swap
            abi.encodeWithSignature(
                "swapExactETHForTokens(uint256,address[],address,uint256)", // Function signature
                0, // Minimum amount of tokens to receive (set to 0 for simplicity)
                getPathForETHtoUSDC(), // Path for the swap (ETH to USDC)
                preComputedAddress, // Recipient of the USDC
                block.timestamp // Deadline for the swap
            )
        );

        // Deploy the Nexus account
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));

        // Build the PackedUserOperation array
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user, // Wallet initiating the operation
            deployedNexus, // Deployed Nexus account
            EXECTYPE_DEFAULT, // Execution type
            executions, // Execution details
            address(VALIDATOR_MODULE) // Validator module address
        );

        // Generate and sign paymaster data
        userOps[0].paymasterAndData = generateAndSignPaymasterData(userOps[0], BUNDLER, paymaster);

        // Sign the entire user operation with the user's wallet
        userOps[0].signature = signUserOp(user, userOps[0]);

        // Measure and log gas usage for the operation
        measureAndLogGas("46::UniswapV2::swapExactETHForTokens::Nexus::WithPaymaster::N/A", userOps);
    }

    /// @notice Helper function to get the path for ETH to USDC swap
    /// @return path The array containing the swap path
    function getPathForETHtoUSDC() internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(UNISWAP_V2_ROUTER02).WETH();
        path[1] = USDC_ADDRESS;
        return path;
    }
}
