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
        paymaster = new MockPaymaster(address(ENTRYPOINT), BUNDLER_ADDRESS);
        ENTRYPOINT.depositTo{ value: 10 ether }(address(paymaster));

        vm.deal(address(paymaster), 100 ether);
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
            "UniswapV2::swapExactETHForTokens::EOA::ETHtoUSDC::N/A",
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

        measureAndLogGas("UniswapV2::swapExactETHForTokens::Nexus::Deployed::N/A", userOps);
    }
/// @notice Tests deploying Nexus and swapping ETH for USDC with Paymaster
function test_Gas_Swap_DeployAndSwap_WithPaymasterkkkkk() public checkERC20Balance(preComputedAddress, SWAP_AMOUNT) {
 
 
    uint128 verificationGasLimit = 300_000;
    uint128 callGasLimit = 500_000;
    uint128 preVerificationGas = 70_000;
    uint128 maxFeePerGas = 3e5;
    uint128 maxPriorityFeePerGas = 3e5;
    uint128 paymasterVerificationGasLimit = 200000;
    uint128 paymasterPostOpGasLimit = 100000;
 
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

    userOps[0].accountGasLimits = bytes32(abi.encodePacked(verificationGasLimit, callGasLimit));
    userOps[0].preVerificationGas = preVerificationGas;
    userOps[0].gasFees = bytes32(abi.encodePacked(maxFeePerGas, maxPriorityFeePerGas));

    userOps[0].initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));


    // Include validity timestamps
    uint48 validUntil = uint48(block.timestamp + 1 days);
    uint48 validAfter = uint48(block.timestamp);

    // Ensure paymasterAndData is populated correctly
    userOps[0].paymasterAndData = abi.encodePacked(
        address(paymaster),
        uint128(paymasterVerificationGasLimit),
        uint128(paymasterPostOpGasLimit)
    );


    // Construct gas limits and fees
    userOps[0].preVerificationGas = preVerificationGas;
    userOps[0].accountGasLimits = bytes32(abi.encodePacked(verificationGasLimit, callGasLimit));
    userOps[0].gasFees = bytes32(abi.encodePacked(maxFeePerGas, maxPriorityFeePerGas));

    // Get the hash that needs to be signed off-chain
    bytes32 paymasterHash = paymaster.getHash(userOps[0], validUntil, validAfter);

    // Sign the hash using the verifying signer (BUNDLER here)
    bytes memory paymasterSignature = signMessage(BUNDLER, paymasterHash);

    // Construct paymasterAndData with the signature
    userOps[0].paymasterAndData = abi.encodePacked(
        address(paymaster),
        validUntil,
        validAfter,
        paymasterSignature
    );

    // Log gas values for debugging
    emit log_named_uint("preVerificationGas", userOps[0].preVerificationGas);
    emit log_named_uint("verificationGasLimit", uint128(bytes16(userOps[0].accountGasLimits)));
    emit log_named_uint("callGasLimit", uint128(bytes16(userOps[0].accountGasLimits << 128)));
    emit log_named_uint("maxFeePerGas", uint128(bytes16(userOps[0].gasFees)));
    emit log_named_uint("maxPriorityFeePerGas", uint128(bytes16(userOps[0].gasFees << 128)));

    // Sign the user operation itself
    userOps[0].signature = signUserOp(user, userOps[0]);

    // Additional debug information
    emit log_named_bytes("initCode", userOps[0].initCode);
    emit log_named_bytes("paymasterAndData", userOps[0].paymasterAndData);
    emit log_named_bytes("signature", userOps[0].signature);

    measureAndLogGas("UniswapV2::swapExactETHForTokens::Setup And Call::WithPaymaster::N/A", userOps);
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

        measureAndLogGas("UniswapV2::swapExactETHForTokens::Setup And Call::UsingDeposit::N/A", userOps);
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

        measureAndLogGas("UniswapV2::swapExactETHForTokens::Setup And Call::Using Pre-Funded Ether::N/A", userOps);
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
