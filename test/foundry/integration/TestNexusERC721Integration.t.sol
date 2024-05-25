// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../utils/Imports.sol";
import "../utils/NexusTest_Base.t.sol";

/// @title TestNexusERC721Integration
/// @notice Tests Nexus smart account functionalities with ERC721 token transfers
contract TestNexusERC721Integration is NexusTest_Base {
    NFT private ERC721;
    MockPaymaster private paymaster;
    Vm.Wallet private user;
    address payable private preComputedAddress;
    address private constant recipient = address(0x123);
    uint256 private constant tokenId = 10;

    /// @notice Modifier to check ERC721 balance changes
    /// @param account The account to check the balance for
    /// @param tokenId The token ID to check the ownership of
    modifier checkERC721Balance(address account, uint256 tokenId) {
        _;
        address finalOwner = ERC721.ownerOf(tokenId);
        assertEq(finalOwner, account);
    }

    /// @notice Sets up the initial state for the tests
    function setUp() public {
        init();
        user = createAndFundWallet("user", 1 ether);
        ERC721 = new NFT("Mock NFT", "MNFT");
        paymaster = new MockPaymaster(address(ENTRYPOINT));
        ENTRYPOINT.depositTo{value: 10 ether}(address(paymaster));
        vm.deal(address(paymaster), 100 ether);
        preComputedAddress = payable(calculateAccountAddress(user.addr, address(VALIDATOR_MODULE)));
        console.log(preComputedAddress);
    }

    /// @notice Helper function to transfer ERC721 tokens simply
    function transferERC721Simple() external {
        ERC721.transferFrom(address(this), recipient, tokenId);
    }

    /// @notice Helper function to handle operations for a deployed Nexus
    function handleOpsForDeployedNexus() external {
        Nexus deployedNexus = deployNexus(user, 100 ether, address(VALIDATOR_MODULE));
        Execution[] memory executions = prepareSingleExecution(
            address(ERC721),
            0,
            abi.encodeWithSignature("transferFrom(address,address,uint256)", preComputedAddress, recipient, tokenId)
        );
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            user,
            deployedNexus,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(userOps, payable(BUNDLER.addr));
    }

    /// @notice Helper function to handle operations with paymaster
    function handleOpsForPaymaster() external {
        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        Execution[] memory executions = prepareSingleExecution(
            address(ERC721),
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
            uint128(3e6)  // postOp gas limit
        );

        userOps[0].signature = signUserOp(user, userOps[0]);

        ENTRYPOINT.handleOps(userOps, BUNDLER_ADDRESS);
    }

    /// @notice Helper function to handle operations using deposit
    function handleOpsForDeposit() external {
        uint256 depositAmount = 1 ether;
        ENTRYPOINT.depositTo{value: depositAmount}(preComputedAddress);

        uint256 newBalance = ENTRYPOINT.balanceOf(preComputedAddress);
        assertEq(newBalance, depositAmount);

        bytes memory initCode = buildInitCode(user.addr, address(VALIDATOR_MODULE));

        Execution[] memory executions = prepareSingleExecution(
            address(ERC721),
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

    /// @notice Tests gas consumption for a simple ERC721 transfer
    function test_Gas_ERC721_Simple_Transfer() public checkERC721Balance(recipient, tokenId) {
        ERC721.mint(address(this), tokenId);
        measureGasAndEmitLog("ERC721::SimpleTransfer::Gas used for simple ERC721 transfer", this.transferERC721Simple);
    }

    /// @notice Tests sending ERC721 from an already deployed Nexus smart account
    function test_Gas_ERC721_DeployedNexus_Transfer() public checkERC721Balance(recipient, tokenId) {
        ERC721.mint(preComputedAddress, tokenId);
        measureGasAndEmitLog("ERC721::DeployedNexusTransfer::Gas used for sending ERC721 from deployed Nexus", this.handleOpsForDeployedNexus);
    }

    /// @notice Tests deploying Nexus and transferring ERC721 tokens using a paymaster
    function test_Gas_ERC721_DeployWithPaymaster_Transfer() public checkERC721Balance(recipient, tokenId) {
        ERC721.mint(preComputedAddress, tokenId);
        measureGasAndEmitLog("ERC721::DeployWithPaymasterTransfer::Gas used for deploying Nexus and sending ERC721 with paymaster", this.handleOpsForPaymaster);
    }

    /// @notice Tests deploying Nexus and transferring ERC721 tokens using deposited funds without a paymaster
    function test_Gas_ERC721_DeployUsingDeposit_Transfer() public checkERC721Balance(recipient, tokenId) {
        ERC721.mint(preComputedAddress, tokenId);
        measureGasAndEmitLog("ERC721::DeployUsingDepositTransfer::Gas used for deploying Nexus and transferring ERC721 using deposit", this.handleOpsForDeposit);
    }
}
