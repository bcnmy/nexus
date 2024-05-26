// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./BaseSettings.t.sol";
import "../../utils/Imports.sol";
import "../../utils/NexusTest_Base.t.sol";
import "../../shared/interfaces/IUniswapV2Router02.t.sol";
import "../../shared/interfaces/IERC20.t.sol";

/// @title TestNexusSwapWETHIntegration
/// @notice Tests Nexus smart account functionalities with Uniswap V2 swaps using WETH
contract TestNexusSwapWETHIntegration is NexusTest_Base, BaseSettings {
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
        _;
        uint256 finalBalance = usdc.balanceOf(account);
        assert(finalBalance > 0);
    }

    /// @notice Sets up the initial state for the tests
    function setUp() public {
        // Fork the Base network
        uint256 baseFork = vm.createFork(getBaseRpcUrl());
        vm.selectFork(baseFork);
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
        paymaster = new MockPaymaster(address(ENTRYPOINT));
        ENTRYPOINT.depositTo{ value: 10 ether }(address(paymaster));

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

        uint256 initialGas = gasleft();
        uniswapV2Router.swapExactTokensForTokens(SWAP_AMOUNT, 0, path, swapper, block.timestamp);
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("UniswapV2::swapExactTokensForTokens::Gas used for swapping WETH for USDC (EOA)", gasUsed);
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

        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(BUNDLER.addr));
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("UniswapV2::swapExactTokensForTokens::Gas used for swapping WETH for USDC (Deployed Nexus)", gasUsed);
    }

    /// @notice Tests deploying Nexus and swapping WETH for USDC with Paymaster
    function test_Gas_Swap_DeployAndSwap_WithPaymaster() public checkERC20Balance(preComputedAddress) {
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
            address(VALIDATOR_MODULE)
        );

        userOps[0].initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        // Including paymaster address and additional data
        userOps[0].paymasterAndData = abi.encodePacked(
            address(paymaster),
            uint128(3e6), // verification gas limit
            uint128(3e6) // postOp gas limit
        );

        userOps[0].signature = signUserOp(user, userOps[0]);

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, BUNDLER_ADDRESS);
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("UniswapV2::swapExactTokensForTokens::Gas used for deploying Nexus and swapping WETH for USDC with Paymaster", gasUsed);
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
            address(VALIDATOR_MODULE)
        );

        userOps[0].initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));
        userOps[0].signature = signUserOp(user, userOps[0]);

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, BUNDLER_ADDRESS);
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("UniswapV2::swapExactTokensForTokens::Gas used for deploying Nexus and swapping WETH for USDC using deposit", gasUsed);
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

        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, payable(BUNDLER.addr));
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("UniswapV2::batchApproveAndSwap::Gas used for batch approval and swapping WETH for USDC (Deployed Nexus)", gasUsed);
    }

    /// @notice Tests deploying Nexus and batch approval and swapping WETH for USDC with Paymaster
    function test_Gas_BatchApproveAndSwap_DeployAndSwap_WithPaymaster() public checkERC20Balance(preComputedAddress) {
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
            address(VALIDATOR_MODULE)
        );

        userOps[0].initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        // Including paymaster address and additional data
        userOps[0].paymasterAndData = abi.encodePacked(
            address(paymaster),
            uint128(3e6), // verification gas limit
            uint128(3e6) // postOp gas limit
        );

        userOps[0].signature = signUserOp(user, userOps[0]);

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, BUNDLER_ADDRESS);
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("UniswapV2::batchApproveAndSwap::Gas used for batch approval and swapping WETH for USDC with Paymaster", gasUsed);
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
            address(VALIDATOR_MODULE)
        );

        userOps[0].initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));
        userOps[0].signature = signUserOp(user, userOps[0]);

        uint256 initialGas = gasleft();
        ENTRYPOINT.handleOps(userOps, BUNDLER_ADDRESS);
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("UniswapV2::batchApproveAndSwap::Gas used for batch approval and swapping WETH for USDC using deposit", gasUsed);
    }

    /// @notice Helper function to get the path for WETH to USDC swap
    /// @return path The array containing the swap path
    function getPathForWETHtoUSDC() internal view returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = address(WETH_ADDRESS);
        path[1] = USDC_ADDRESS;
        return path;
    }

    /// @notice Retrieves the Base RPC URL from the environment variable or defaults to the hardcoded URL
    /// @return rpcUrl The Base RPC URL
    function getBaseRpcUrl() internal view returns (string memory) {
        string memory rpcUrl = vm.envOr("BASE_RPC_URL", DEFAULT_BASE_RPC_URL);
        return rpcUrl;
    }
}
