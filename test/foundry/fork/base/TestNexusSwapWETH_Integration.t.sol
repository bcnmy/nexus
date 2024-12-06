// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "./BaseSettings.t.sol";
import "../../utils/Imports.sol";
import "../../shared/interfaces/IERC20.t.sol";
import "../../shared/interfaces/IUniswapV2Router02.t.sol";

/// @title TestNexusSwapWETH_Integration
/// @notice Tests Nexus smart account functionalities with Uniswap V2 swaps using WETH
contract TestNexusSwapWETH_Integration is BaseSettings {
    address payable private preComputedAddress;
    IUniswapV2Router02 public uniswapV2Router;
    MockPaymaster private paymaster;
    address private WETH_ADDRESS;
    Vm.Wallet private user;
    address public swapper;
    IERC20 public weth;
    IERC20 public usdc;

    uint256 public constant SWAP_AMOUNT = 1 ether; // 1 WETH for swap

    /// @notice Modifier to check ERC20 balance changes
    /// @param account The account to check the balance for
    modifier checkERC20Balance(address account) {
        uint256 initialBalance = usdc.balanceOf(account);
        assertEq(initialBalance, 0, "Account balance is not zero");
        _;
        uint256 finalBalance = usdc.balanceOf(account);
        assertGt(finalBalance, 0, "Account balance is zero");
    }

    /// @notice Sets up the initial state for the tests
    function setUp() public {
        // Fork the Base network
        uint256 baseFork = vm.createFork(getBaseRpcUrl());
        vm.selectFork(baseFork);
        vm.rollFork(BLOCK_NUMBER);
        init();

        user = createAndFundWallet("user", 50 ether);
        swapper = vm.addr(2);
        startPrank(swapper);
        vm.deal(swapper, 50 ether);
        usdc = IERC20(USDC_ADDRESS);
        uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER02);
        weth = IERC20(uniswapV2Router.WETH());
        WETH_ADDRESS = address(weth);

        // Convert ETH to WETH for swapper
        (bool success, ) = WETH_ADDRESS.call{ value: 10 ether }(abi.encodeWithSignature("deposit()"));
        require(success, "WETH deposit failed");

        // Initialize Nexus
        paymaster = new MockPaymaster(address(ENTRYPOINT), BUNDLER_ADDRESS);
        ENTRYPOINT.depositTo{ value: 10 ether }(address(paymaster));
        paymaster.addStake{ value: 2 ether }(10 days);

        vm.deal(address(paymaster), 100 ether);
        preComputedAddress = payable(calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));

        // Transfer WETH to swapper and preComputedAddress
        weth.transfer(swapper, SWAP_AMOUNT * 2);
        weth.transfer(preComputedAddress, SWAP_AMOUNT * 2);
    }

    /// @notice Tests gas consumption for swapping WETH for USDC using an EOA
    function test_Gas_Swap_EOA_SwapWethForTokens() public checkERC20Balance(swapper) {
        vm.startPrank(swapper);
        weth.approve(address(uniswapV2Router), SWAP_AMOUNT);

        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(usdc);

        measureAndLogGasEOA(
            "47::UniswapV2::swapExactTokensForTokens::EOA::WETHtoUSDC::N/A",
            address(uniswapV2Router),
            0,
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                SWAP_AMOUNT,
                0,
                path,
                swapper,
                block.timestamp
            )
        );
        vm.stopPrank();
    }

    /// @notice Tests gas consumption for swapping WETH for USDC using a deployed Nexus account
    function test_Gas_Swap_DeployedNexus_SwapWethForTokens() public checkERC20Balance(preComputedAddress) {
        Nexus deployedNexus = deployNexus(user, 10 ether, address(VALIDATOR_MODULE));

        // Approve WETH transfer for deployed Nexus
        vm.startPrank(preComputedAddress);
        weth.approve(address(uniswapV2Router), SWAP_AMOUNT);
        vm.stopPrank();

        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router),
            0,
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                SWAP_AMOUNT,
                0,
                getPathForWETHtoUSDC(),
                address(deployedNexus),
                block.timestamp
            )
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);
        measureAndLogGas("48::UniswapV2::swapExactTokensForTokens::Nexus::Deployed::N/A", userOps);
    }

    /// @notice Tests deploying Nexus and swapping WETH for USDC with Paymaster
    function test_Gas_Swap_DeployAndSwap_WithPaymaster() public checkERC20Balance(preComputedAddress) checkPaymasterBalance(address(paymaster)) {
        // Approve WETH transfer for precomputed address
        vm.startPrank(preComputedAddress);
        weth.approve(address(uniswapV2Router), SWAP_AMOUNT);
        vm.stopPrank();

        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router),
            0,
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                SWAP_AMOUNT,
                0,
                getPathForWETHtoUSDC(),
                preComputedAddress,
                block.timestamp
            )
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            Nexus(preComputedAddress),
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE),
            0
        );

        userOps[0].initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        // Including paymaster address and additional data
        userOps[0].paymasterAndData = generateAndSignPaymasterData(userOps[0], BUNDLER, paymaster);

        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("49::UniswapV2::swapExactTokensForTokens::Setup And Call::WithPaymaster::N/A", userOps);
    }

    /// @notice Tests deploying Nexus and swapping WETH for USDC using deposit
    function test_Gas_Swap_DeployAndSwap_UsingDeposit() public checkERC20Balance(preComputedAddress) {
        uint256 depositAmount = 1 ether;
        ENTRYPOINT.depositTo{ value: depositAmount }(preComputedAddress);

        uint256 newBalance = ENTRYPOINT.balanceOf(preComputedAddress);
        assertEq(newBalance, depositAmount);

        // Approve WETH transfer for precomputed address
        vm.startPrank(preComputedAddress);
        weth.approve(address(uniswapV2Router), SWAP_AMOUNT);
        vm.stopPrank();

        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router),
            0,
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                SWAP_AMOUNT,
                0,
                getPathForWETHtoUSDC(),
                preComputedAddress,
                block.timestamp
            )
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            Nexus(preComputedAddress),
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE),
            0
        );

        userOps[0].initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));
        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("50::UniswapV2::swapExactTokensForTokens::Setup And Call::UsingDeposit::N/A", userOps);
    }

    /// @notice Tests gas consumption for batch approval and swapping WETH for USDC using deployed Nexus account
    function test_Gas_BatchApproveAndSwap_DeployedNexus() public checkERC20Balance(preComputedAddress) {
        Nexus deployedNexus = deployNexus(user, 10 ether, address(VALIDATOR_MODULE));

        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution(address(weth), 0, abi.encodeWithSignature("approve(address,uint256)", address(uniswapV2Router), SWAP_AMOUNT));
        executions[1] = Execution(
            address(uniswapV2Router),
            0,
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                SWAP_AMOUNT,
                0,
                getPathForWETHtoUSDC(),
                address(deployedNexus),
                block.timestamp
            )
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);
        measureAndLogGas("51::UniswapV2::approve+swapExactTokensForTokens::Nexus::Deployed::N/A", userOps);
    }

    /// @notice Tests deploying Nexus and batch approval and swapping WETH for USDC with Paymaster
    function test_Gas_BatchApproveAndSwap_DeployAndSwap_WithPaymaster()
        public
        checkERC20Balance(preComputedAddress)
        checkPaymasterBalance(address(paymaster))
    {
        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution(address(weth), 0, abi.encodeWithSignature("approve(address,uint256)", address(uniswapV2Router), SWAP_AMOUNT));
        executions[1] = Execution(
            address(uniswapV2Router),
            0,
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                SWAP_AMOUNT,
                0,
                getPathForWETHtoUSDC(),
                preComputedAddress,
                block.timestamp
            )
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            Nexus(preComputedAddress),
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE),
            0
        );

        userOps[0].initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        // Including paymaster address and additional data
        userOps[0].paymasterAndData = generateAndSignPaymasterData(userOps[0], BUNDLER, paymaster);

        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("52::UniswapV2::approve+swapExactTokensForTokens::Setup And Call::WithPaymaster::N/A", userOps);
    }

    /// @notice Tests deploying Nexus and batch approval and swapping WETH for USDC using deposit
    function test_Gas_BatchApproveAndSwap_DeployAndSwap_UsingDeposit() public checkERC20Balance(preComputedAddress) {
        uint256 depositAmount = 1 ether;
        ENTRYPOINT.depositTo{ value: depositAmount }(preComputedAddress);

        uint256 newBalance = ENTRYPOINT.balanceOf(preComputedAddress);
        assertEq(newBalance, depositAmount);

        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution(address(weth), 0, abi.encodeWithSignature("approve(address,uint256)", address(uniswapV2Router), SWAP_AMOUNT));
        executions[1] = Execution(
            address(uniswapV2Router),
            0,
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                SWAP_AMOUNT,
                0,
                getPathForWETHtoUSDC(),
                preComputedAddress,
                block.timestamp
            )
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            Nexus(preComputedAddress),
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE),
            0
        );

        userOps[0].initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));
        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("53::UniswapV2::approve+swapExactTokensForTokens::Setup And Call::UsingDeposit::N/A", userOps);
    }

    /// @notice Tests sending ETH to the Nexus account before deployment and then deploy with Uniswap V2 swap using WETH
    function test_Gas_Swap_DeployNexusWithPreFundedETH_WETH() public checkERC20Balance(preComputedAddress) {
        // Send ETH directly to the precomputed address
        vm.deal(preComputedAddress, 1 ether);
        assertEq(address(preComputedAddress).balance, 1 ether, "ETH not sent to precomputed address");

        // Create initCode for deploying the Nexus account
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        Execution[] memory executions = new Execution[](2);
        executions[0] = Execution(address(weth), 0, abi.encodeWithSignature("approve(address,uint256)", address(uniswapV2Router), SWAP_AMOUNT));
        executions[1] = Execution(
            address(uniswapV2Router),
            0,
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                SWAP_AMOUNT,
                0,
                getPathForWETHtoUSDC(),
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
            address(VALIDATOR_MODULE),
            0
        );
        userOps[0].initCode = initCode;
        // Sign the user operation
        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("54::UniswapV2::approve+swapExactTokensForTokens::Setup And Call::Using Pre-Funded Ether::N/A", userOps);
    }

    /// @notice Tests gas consumption for swapping WETH for USDC using a deployed Nexus account with Paymaster
    function test_Gas_Swap_DeployedNexus_SwapWethForTokens_WithPaymaster()
        public
        checkERC20Balance(preComputedAddress)
        checkPaymasterBalance(address(paymaster))
    {
        // Approve WETH transfer for precomputed address
        vm.startPrank(preComputedAddress);
        weth.approve(address(uniswapV2Router), SWAP_AMOUNT);
        vm.stopPrank();

        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router),
            0,
            abi.encodeWithSignature(
                "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)",
                SWAP_AMOUNT,
                0,
                getPathForWETHtoUSDC(),
                preComputedAddress,
                block.timestamp
            )
        );

        // Deploy the Nexus account
        Nexus deployedNexus = deployNexus(user, 10 ether, address(VALIDATOR_MODULE));

        // Build the PackedUserOperation array
        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);

        // Generate and sign paymaster data
        userOps[0].paymasterAndData = generateAndSignPaymasterData(userOps[0], BUNDLER, paymaster);

        // Sign the user operation
        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("55::UniswapV2::swapExactTokensForTokens::Nexus::WithPaymaster::N/A", userOps);
    }

    /// @notice Helper function to get the path for WETH to USDC swap
    /// @return path The array containing the swap path
    function getPathForWETHtoUSDC() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(WETH_ADDRESS);
        path[1] = USDC_ADDRESS;
        return path;
    }
}
