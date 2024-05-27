// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

/// @title TestNexusERC721NFTIntegration
/// @notice Tests Nexus smart account functionalities with ERC721NFT token transfers
contract TestNexusERC721NFTIntegration is NexusTest_Base {
    MockNFT ERC721NFT;
    MockPaymaster private paymaster;
    Vm.Wallet private user;
    address payable private preComputedAddress;
    address private constant recipient = address(0x123);
    uint256 private constant tokenId = 10;

    /// @notice Modifier to check ERC721NFT balance changes
    /// @param account The account to check the balance for
    modifier checkERC721NFTBalance(address account) {
        _;
        address finalOwner = ERC721NFT.ownerOf(tokenId);
        assertEq(finalOwner, account);
    }

    /// @notice Sets up the initial state for the tests
    function setUp() public {
        init();
        user = createAndFundWallet("user", 1 ether);
        ERC721NFT = new MockNFT("Mock NFT", "MNFT");
        paymaster = new MockPaymaster(address(ENTRYPOINT));
        ENTRYPOINT.depositTo{ value: 10 ether }(address(paymaster));
        vm.deal(address(paymaster), 100 ether);
        preComputedAddress = payable(calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));
        console.log(preComputedAddress);
    }

    /// @notice Helper function to transfer ERC721NFT tokens simply
    function transferERC721NFTSimple() external {
        ERC721NFT.transferFrom(address(this), recipient, tokenId);
    }

    /// @notice Helper function to handle operations for a deployed Nexus
    function handleOpsForDeployedNexus() external {
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));
        Execution[] memory executions = prepareSingleExecution(
            address(ERC721NFT),
            0,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", preComputedAddress, recipient, tokenId)
        );
        PackedUserOperation[] memory userOps = buildPackedUserOperation(user, deployedNexus, EXECTYPE_DEFAULT, executions, address(VALIDATOR_MODULE));
        ENTRYPOINT.handleOps(userOps, payable(BUNDLER.addr));
    }

    /// @notice Helper function to handle operations with paymaster
    function handleOpsForPaymaster() external {
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
            address(VALIDATOR_MODULE)
        );

        userOps[0].initCode = initCode;

        // Including paymaster address and additional data
        userOps[0].paymasterAndData = abi.encodePacked(
            address(paymaster),
            uint128(3e6), // verification gas limit
            uint128(3e6) // postOp gas limit
        );

        userOps[0].signature = signUserOp(user, userOps[0]);

        ENTRYPOINT.handleOps(userOps, BUNDLER_ADDRESS);
    }

    /// @notice Helper function to handle operations using deposit
    function handleOpsForDeposit() external {
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
            address(VALIDATOR_MODULE)
        );
        userOps[0].initCode = initCode;
        userOps[0].signature = signUserOp(user, userOps[0]);

        ENTRYPOINT.handleOps(userOps, BUNDLER_ADDRESS);
    }

    /// @notice Tests gas consumption for a simple ERC721NFT transfer
    function test_Gas_ERC721NFT_Simple_Transfer() public checkERC721NFTBalance(recipient) {
        ERC721NFT.mint(address(this), tokenId);
        measureGasAndEmitLog("ERC721NFT::SimpleTransfer::Gas used for simple ERC721NFT transfer", this.transferERC721NFTSimple);
    }

    /// @notice Tests sending ERC721NFT from an already deployed Nexus smart account
    function test_Gas_ERC721NFT_DeployedNexus_Transfer() public checkERC721NFTBalance(recipient) {
        ERC721NFT.mint(preComputedAddress, tokenId);
        measureGasAndEmitLog("ERC721NFT::DeployedNexusTransfer::Gas used for sending ERC721NFT from deployed Nexus", this.handleOpsForDeployedNexus);
    }

    /// @notice Tests deploying Nexus and transferring ERC721NFT tokens using a paymaster
    function test_Gas_ERC721NFT_DeployWithPaymaster_Transfer() public checkERC721NFTBalance(recipient) {
        ERC721NFT.mint(preComputedAddress, tokenId);
        measureGasAndEmitLog(
            "ERC721NFT::DeployWithPaymasterTransfer::Gas used for deploying Nexus and sending ERC721NFT with paymaster",
            this.handleOpsForPaymaster
        );
    }

    /// @notice Tests deploying Nexus and transferring ERC721NFT tokens using deposited funds without a paymaster
    function test_Gas_ERC721NFT_DeployUsingDeposit_Transfer() public checkERC721NFTBalance(recipient) {
        ERC721NFT.mint(preComputedAddress, tokenId);
        measureGasAndEmitLog(
            "ERC721NFT::DeployUsingDepositTransfer::Gas used for deploying Nexus and transferring ERC721NFT using deposit",
            this.handleOpsForDeposit
        );
    }
}
