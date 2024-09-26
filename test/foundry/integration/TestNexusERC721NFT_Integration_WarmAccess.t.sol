// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

/// @title TestNexusERC721NFT_Integration_WarmAccess
/// @notice Tests Nexus smart account functionalities with ERC721 token transfers (Warm Access)
contract TestNexusERC721NFT_Integration_WarmAccess is NexusTest_Base {
    MockNFT ERC721NFT;
    MockPaymaster private paymaster;
    Vm.Wallet private user;
    address payable private preComputedAddress;
    address private constant recipient = address(0x123);
    uint256 private constant tokenId = 10;

    /// @notice Modifier to check ERC721 token balance changes with warm access
    /// @param account The account to check the balance for
    modifier checkERC721NFTBalanceWarm(address account) {
        ERC721NFT.mint(account, 1); // Ensure the account has at least one NFT
        assertGt(ERC721NFT.balanceOf(account), 0, "Account balance is zero (warm access)");
        _;
        address finalOwner = ERC721NFT.ownerOf(tokenId);
        assertEq(finalOwner, account);
    }

    /// @notice Sets up the initial state for the tests
    function setUp() public {
        init();
        user = createAndFundWallet("user", 1 ether);
        ERC721NFT = new MockNFT("Mock NFT", "MNFT");
        paymaster = new MockPaymaster(address(ENTRYPOINT), BUNDLER_ADDRESS);
        ENTRYPOINT.depositTo{ value: 10 ether }(address(paymaster));
        vm.deal(address(paymaster), 100 ether);
        preComputedAddress = payable(calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));
    }

    /// @notice Tests gas consumption for a simple ERC721 token transfer with warm access
    function test_Gas_ERC721NFT_Simple_Transfer_Warm() public checkERC721NFTBalanceWarm(recipient) {
        ERC721NFT.mint(address(this), tokenId);
        measureAndLogGasEOA(
            "14::ERC721::transferFrom::EOA::Simple::WarmAccess",
            address(ERC721NFT),
            0,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), recipient, tokenId)
        );
    }

    /// @notice Tests sending ERC721 tokens from an already deployed Nexus smart account with warm access
    function test_Gas_ERC721NFT_DeployedNexus_Transfer_Warm() public checkERC721NFTBalanceWarm(recipient) {
        ERC721NFT.mint(preComputedAddress, tokenId);
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));
        Execution[] memory executions = prepareSingleExecution(
            address(ERC721NFT),
            0,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", preComputedAddress, recipient, tokenId)
        );
        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);
        measureAndLogGas("16::ERC721::transferFrom::Nexus::Deployed::WarmAccess", userOps);
    }

    /// @notice Tests deploying Nexus and transferring ERC721 tokens using a paymaster with warm access
    function test_Gas_ERC721NFT_DeployWithPaymaster_Transfer_Warm()
        public
        checkERC721NFTBalanceWarm(recipient)
        checkPaymasterBalance(address(paymaster))
    {
        ERC721NFT.mint(preComputedAddress, tokenId);

        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));
        Execution[] memory executions = prepareSingleExecution(
            address(ERC721NFT),
            0,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", preComputedAddress, recipient, tokenId)
        );
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            Nexus(preComputedAddress),
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE),
            0
        );
        userOps[0].initCode = initCode;
        userOps[0].paymasterAndData = generateAndSignPaymasterData(userOps[0], BUNDLER, paymaster);
        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("18::ERC721::transferFrom::Setup And Call::WithPaymaster::WarmAccess", userOps);
    }

    /// @notice Tests deploying Nexus and transferring ERC721 tokens using deposited funds without a paymaster with warm access
    function test_Gas_ERC721NFT_DeployUsingDeposit_Transfer_Warm() public checkERC721NFTBalanceWarm(recipient) {
        ERC721NFT.mint(preComputedAddress, tokenId);

        uint256 depositAmount = 1 ether;
        ENTRYPOINT.depositTo{ value: depositAmount }(preComputedAddress);

        uint256 newBalance = ENTRYPOINT.balanceOf(preComputedAddress);
        assertEq(newBalance, depositAmount);

        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        Execution[] memory executions = prepareSingleExecution(
            address(ERC721NFT),
            0,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", preComputedAddress, recipient, tokenId)
        );

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            Nexus(preComputedAddress),
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE),
            0
        );
        userOps[0].initCode = initCode;
        userOps[0].signature = signUserOp(user, userOps[0]);

        measureAndLogGas("20::ERC721::transferFrom::Setup And Call::UsingDeposit::WarmAccess", userOps);
    }

    /// @notice Tests sending ETH to the Nexus account before deployment and then deploy with warm access
    function test_Gas_ERC721NFT_DeployNexusWithPreFundedETH_Warm() public checkERC721NFTBalanceWarm(recipient) {
        ERC721NFT.mint(preComputedAddress, tokenId);

        // Send ETH directly to the precomputed address
        vm.deal(preComputedAddress, 1 ether);
        assertEq(address(preComputedAddress).balance, 1 ether, "ETH not sent to precomputed address");

        // Create initCode for deploying the Nexus account
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        // Prepare execution to transfer ERC721 tokens
        Execution[] memory executions = prepareSingleExecution(
            address(ERC721NFT),
            0,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", preComputedAddress, recipient, tokenId)
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

        measureAndLogGas("22::ERC721::transferFrom::Setup And Call::Using Pre-Funded Ether::WarmAccess", userOps);
    }

    /// @notice Tests gas consumption for transferring ERC721 tokens from an already deployed Nexus smart account using a paymaster
    function test_Gas_ERC721NFT_DeployedNexus_Transfer_WithPaymaster_Warm()
        public
        checkERC721NFTBalanceWarm(recipient)
        checkPaymasterBalance(address(paymaster))
    {
        // Mint the NFT to the precomputed address
        ERC721NFT.mint(preComputedAddress, tokenId);

        // Deploy the Nexus account
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));

        // Prepare the execution for ERC721 token transfer
        Execution[] memory executions = prepareSingleExecution(
            address(ERC721NFT),
            0,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", preComputedAddress, recipient, tokenId)
        );

        // Build the PackedUserOperation array
        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE), 0);

        // Generate and sign paymaster data
        userOps[0].paymasterAndData = generateAndSignPaymasterData(userOps[0], BUNDLER, paymaster);

        // Sign the user operation
        userOps[0].signature = signUserOp(user, userOps[0]);

        // Measure and log gas usage
        measureAndLogGas("24::ERC721::transferFrom::Nexus::WithPaymaster::WarmAccess", userOps);
    }
}
