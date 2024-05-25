// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./BaseSettings.t.sol";
import "../../utils/Imports.sol";
import "../../utils/NexusTest_Base.t.sol";
import "../../shared/interfaces/IUniswapV2Router02.t.sol";
import "../../shared/interfaces/IERC20.t.sol";

/// @title TestNexusSwapETHIntegration
/// @notice Tests Nexus smart account functionalities with Uniswap V2 swaps
contract TestNexusSwapETHIntegration is NexusTest_Base, BaseSettings {
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
        _;
        uint256 finalBalance = usdc.balanceOf(account);
        assert(finalBalance >= initialBalance + expectedBalance);
    }

    /// @notice Sets up the initial state for the tests
    function setUp() public {
        // Fork the Base network
        uint256 baseFork = vm.createFork(getBaseRpcUrl());
        vm.selectFork(baseFork);
        init();

        user = createAndFundWallet("user", 1 ether);
        swapper = vm.addr(2);

        usdc = IERC20(USDC_ADDRESS);
        uniswapV2Router = IUniswapV2Router02(UNISWAP_V2_ROUTER02);

        // Distribute ether to accounts
        vm.deal(swapper, 100 ether);

        // Initialize Nexus
        paymaster = new MockPaymaster();
        ENTRYPOINT.depositTo{value: 10 ether}(address(paymaster));

        vm.deal(address(paymaster), 100 ether);
        preComputedAddress = payable(calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));

        vm.deal(preComputedAddress, 100 ether);
    }

    /// @notice Tests gas consumption for swapping ETH for USDC using an EOA
    function test_Gas_Swap_EOA_SwapEthForTokens() public {
        vm.startPrank(swapper);
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(usdc);

        uint256 initialTokenBalance = usdc.balanceOf(swapper);
        
        uint256 initialGas = gasleft();
        uniswapV2Router.swapExactETHForTokens{value: SWAP_AMOUNT}(
            0,
            path,
            swapper,
            block.timestamp
        );
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("UniswapV2::swapExactETHForTokens::Gas used for swapping ETH for USDC (EOA)", gasUsed);

        assertGt(usdc.balanceOf(swapper), initialTokenBalance);
        vm.stopPrank();
    }

    /// @notice Tests gas consumption for swapping ETH for USDC using a deployed Nexus account
    function test_Gas_Swap_DeployedNexus_SwapEthForTokens() public {
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));
        uint256 initialGas = gasleft();
        
        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router),
            SWAP_AMOUNT,
            abi.encodeWithSignature("swapExactETHForTokens(uint256,address[],address,uint256)", 0, getPathForETHtoUSDC(), address(deployedNexus), block.timestamp)
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            deployedNexus,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );

        ENTRYPOINT.handleOps(userOps, payable(BUNDLER.addr));
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("UniswapV2::swapExactETHForTokens::Gas used for swapping ETH for USDC (Deployed Nexus)", gasUsed);

        assertGt(usdc.balanceOf(address(deployedNexus)), 0);
    }

    /// @notice Tests deploying Nexus and swapping ETH for USDC with Paymaster
    function test_Gas_Swap_DeployAndSwap_WithPaymaster() public {
        uint256 initialGas = gasleft();
        
        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router),
            SWAP_AMOUNT,
            abi.encodeWithSignature("swapExactETHForTokens(uint256,address[],address,uint256)", 0, getPathForETHtoUSDC(), preComputedAddress, block.timestamp)
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
            uint128(3e6)  // postOp gas limit
        );

        userOps[0].signature = signUserOp(user, userOps[0]);

        ENTRYPOINT.handleOps(userOps, BUNDLER_ADDRESS);
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("UniswapV2::swapExactETHForTokens::Gas used for deploying Nexus and swapping ETH for USDC with Paymaster", gasUsed);

        assertGt(usdc.balanceOf(preComputedAddress), 0);
    }

    /// @notice Tests deploying Nexus and swapping ETH for USDC using deposit
    function test_Gas_Swap_DeployAndSwap_UsingDeposit() public {
        uint256 depositAmount = 1 ether;
        ENTRYPOINT.depositTo{value: depositAmount}(preComputedAddress);

        uint256 newBalance = ENTRYPOINT.balanceOf(preComputedAddress);
        assertEq(newBalance, depositAmount);

        uint256 initialGas = gasleft();
        
        Execution[] memory executions = prepareSingleExecution(
            address(uniswapV2Router),
            SWAP_AMOUNT,
            abi.encodeWithSignature("swapExactETHForTokens(uint256,address[],address,uint256)", 0, getPathForETHtoUSDC(), preComputedAddress, block.timestamp)
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

        ENTRYPOINT.handleOps(userOps, BUNDLER_ADDRESS);
        uint256 gasUsed = initialGas - gasleft();
        emit log_named_uint("UniswapV2::swapExactETHForTokens::Gas used for deploying Nexus and swapping ETH for USDC using deposit", gasUsed);

        assertGt(usdc.balanceOf(preComputedAddress), 0);
    }

    /// @notice Helper function to get the path for ETH to USDC swap
    /// @return path The array containing the swap path
    function getPathForETHtoUSDC() internal pure returns (address[] memory) {
        address[] memory path = new address[](2);
        path[0] = IUniswapV2Router02(UNISWAP_V2_ROUTER02).WETH();
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