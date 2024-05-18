// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../utils/Imports.sol";
import { ArbitrumSettings } from "./ArbitrumSettings.t.sol";
import { NexusTest_Base } from "../../utils/NexusTest_Base.t.sol";
import { UserOperation } from "../../shared/interfaces/UserOperation.t.sol";
import { IEntryPointV_0_6 } from "../../shared/interfaces/IEntryPointV_0_6.t.sol";
import { IBiconomySmartAccountV2 } from "../../shared/interfaces/IBiconomySmartAccountV2.t.sol";

contract ArbitrumSmartAccountUpgradeTest is NexusTest_Base, ArbitrumSettings {
    Vm.Wallet internal signer;
    Nexus public newImplementation;
    uint256 internal signerPrivateKey;
    IEntryPoint public ENTRYPOINT_V_0_7;
    IEntryPointV_0_6 public ENTRYPOINT_V_0_6;
    IBiconomySmartAccountV2 public smartAccountV2;

    function setUp() public {
        uint mainnetFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(mainnetFork);
        vm.rollFork(209480000);
        init();
        // Load an existing smart account on the fork
        smartAccountV2 = IBiconomySmartAccountV2(SMART_ACCOUNT_V2_ADDRESS);

        // Load the existing entrypoint v0.6
        ENTRYPOINT_V_0_6 = IEntryPointV_0_6(ENTRYPOINT_ADDRESS);
        // Load the existing entrypoint v0.7
        ENTRYPOINT_V_0_7 = ENTRYPOINT;

        // Deploy the new implementation of Modular Smart Account (Nexus)
        newImplementation = new Nexus();

        // /!\ This PrivateKey is for testing purposes only and should not be used in production
        signerPrivateKey = 0x2924d554c046e633f658427df4d0e7726487b1322bd16caaf24a53099f1cda85;

        signer = vm.createWallet(signerPrivateKey);
    }

    function test_UpgradeV2ToV3AndInitialize() public {
        // Check initial state before upgrade
        address initialEntryPoint = Nexus(payable(address(smartAccountV2))).entryPoint();
        assertEq(address(initialEntryPoint), ENTRYPOINT_ADDRESS, "Initial entry point mismatch.");
        vm.deal(SMART_ACCOUNT_V2_ADDRESS, 1 ether);
        vm.deal(OWNER_ADDRESS, 1 ether);

        ENTRYPOINT_V_0_6.depositTo{ value: 1 ether }(SMART_ACCOUNT_V2_ADDRESS);

        // Addresses and call data for batch operations
        address[] memory dest = new address[](2);
        uint256[] memory values = new uint256[](2);
        bytes[] memory calldatas = new bytes[](2);

        // Prepare call data for upgrade and initialization
        dest[0] = address(smartAccountV2);
        values[0] = 0;
        calldatas[0] = abi.encodeWithSelector(IBiconomySmartAccountV2.updateImplementation.selector, newImplementation);

        dest[1] = address(smartAccountV2);
        values[1] = 0;
        calldatas[1] = abi.encodeWithSelector(Nexus.initialize.selector, VALIDATOR_MODULE, abi.encodePacked(BOB.addr));

        // Prepare the batch execute call data
        bytes memory batchCallData = abi.encodeWithSelector(IBiconomySmartAccountV2.executeBatch.selector, dest, values, calldatas);

        // Prepare the user operation
        UserOperation[] memory userOps = new UserOperation[](1);
        userOps[0] = buildUserOperation(address(smartAccountV2), batchCallData, 0, address(smartAccountV2));

        bytes32 userOpHash = ENTRYPOINT_V_0_6.getUserOpHash(userOps[0]);

        userOps[0].signature = abi.encode(signMessage(signer, userOpHash), MODULE_ADDRESS);

        ENTRYPOINT_V_0_6.handleOps(userOps, address(this));

        // Check state after upgrade
        address newEntryPoint = Nexus(payable(address(smartAccountV2))).entryPoint();
        assertEq(newEntryPoint, address(ENTRYPOINT_V_0_7), "Entry point should change after upgrade.");

        // Check if the Validator module is installed after upgrade and initialization is complete
        assertTrue(
            Nexus(payable(address(smartAccountV2))).isModuleInstalled(1, address(VALIDATOR_MODULE), ""),
            "Validator module should be installed after upgrade."
        );
    }

    function test_AccountIdValidationAfterUpgrade() public {
        test_UpgradeV2ToV3AndInitialize(); // Ensure the smartAccountV2 is upgraded and initialized

        string memory expectedAccountId = "biconomy.nexus.0.0.1";
        string memory actualAccountId = IAccountConfig(payable(address(smartAccountV2))).accountId();
        assertEq(actualAccountId, expectedAccountId, "Account ID does not match after upgrade.");
    }

    function test_USDCTransferPostUpgrade() public {
        test_UpgradeV2ToV3AndInitialize(); // Ensure the setup and upgrade are complete

        MockToken usdc = MockToken(USDC_ADDRESS);
        address recipient = address(0x123); // Random recipient address
        uint256 amount = usdc.balanceOf(address(smartAccountV2)); // Full balance for transfer

        // Encode the call to USDC's transfer function
        bytes memory callData = abi.encodeWithSelector(usdc.transfer.selector, recipient, amount);

        // Create execution array
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(usdc), 0, callData);

        // Pack user operation
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            BOB,
            Nexus(payable(address(SMART_ACCOUNT_V2_ADDRESS))),
            EXECTYPE_DEFAULT,
            execution,
            address(VALIDATOR_MODULE)
        );

        // Execute the operation via the EntryPoint
        ENTRYPOINT_V_0_7.handleOps(userOps, payable(OWNER_ADDRESS));

        // Check the recipient received the USDC
        assertEq(usdc.balanceOf(recipient), amount, "USDC transfer failed");
    }

    function test_NativeEthTransferPostUpgrade() public {
        test_UpgradeV2ToV3AndInitialize(); // Ensure the setup and upgrade are complete

        address recipient = address(0x123); // Random recipient address
        uint256 amount = 1 ether; // Amount of ETH to transfer

        vm.deal(address(smartAccountV2), amount + 1 ether); // Ensure the smart account has ETH to send

        // Create execution array
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(recipient, amount, "");

        // Pack user operation
        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            BOB,
            Nexus(payable(address(smartAccountV2))),
            EXECTYPE_DEFAULT,
            execution,
            address(VALIDATOR_MODULE)
        );

        // Execute the operation via the EntryPoint
        ENTRYPOINT_V_0_7.handleOps(userOps, payable(OWNER_ADDRESS));

        // Check the recipient received the ETH
        assertEq(address(recipient).balance, amount, "ETH transfer failed");
    }

    function buildUserOperation(address from, bytes memory callData, uint256 value, address target) internal view returns (UserOperation memory op) {
        op.sender = from;
        op.nonce = ENTRYPOINT_V_0_6.getNonce(op.sender, 0);
        op.callData = callData;
        op.callGasLimit = 3e6;
        op.verificationGasLimit = 3e6;
        op.preVerificationGas = 3e6;
        op.maxFeePerGas = 3e6;
        op.maxPriorityFeePerGas = 3e6;
        op.paymasterAndData = "";
    }
}
