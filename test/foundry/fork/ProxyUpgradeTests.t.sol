// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "./ArbitrumForkSettings.t.sol";
import "../../../contracts/Nexus.sol";
import "../../../contracts/mocks/MockToken.sol";
import "../utils/SmartAccountTestLab.t.sol";
import "../../../contracts/interfaces/base/IAccountConfig.sol";
import "./TestInterfacesAndStructs.t.sol";

contract ProxyUpgradeProcessTests is SmartAccountTestLab, ArbitrumForkSettings {
    IProxyV2 public proxy;
    IEntryPointV_0_6 public entryPoint;
    Nexus public newImplementation;

    function setUp() public {
        uint mainnetFork = vm.createFork(ARBITRUM_RPC_URL);
        vm.selectFork(mainnetFork);
        vm.rollFork(200000000);
        init();
        proxy = IProxyV2(PROXY_ADDRESS);
        entryPoint = IEntryPointV_0_6(ENTRYPOINT_ADDRESS);
        newImplementation = new Nexus();
    }

    function test_UpgradeAndInitialize() public {
        // Check initial state before upgrade
        address initialEntryPoint = Nexus(payable(address(proxy))).entryPoint();
        assertEq(initialEntryPoint, ENTRYPOINT_ADDRESS, "Initial entry point mismatch.");

        vm.startPrank(PROXY_ADDRESS);
        proxy.updateImplementation(address(newImplementation));

        // Initialize the new implementation with the required validator module
        bytes memory initData = abi.encodePacked(BOB.addr);
        Nexus(payable(address(proxy))).initialize(address(VALIDATOR_MODULE), initData);

        vm.stopPrank();

        // Check state after upgrade
        address newEntryPoint = Nexus(payable(address(proxy))).entryPoint();
        assertEq(newEntryPoint, address(ENTRYPOINT), "Entry point should not change after upgrade.");
    }

function test_AccountIdValidationAfterUpgrade() public {
    test_UpgradeAndInitialize();  // Ensure the proxy is upgraded and initialized

    string memory expectedAccountId = "biconomy.nexus.0.0.1";
    string memory actualAccountId = IAccountConfig(payable(address(proxy))).accountId();
    assertEq(actualAccountId, expectedAccountId, "Account ID does not match after upgrade.");
}

    function test_USDCTransferPostUpgrade() public {
        test_UpgradeAndInitialize();  // Ensure the setup and upgrade are complete

        MockToken usdc = MockToken(USDC_ADDRESS);
        address recipient = address(0x123);  // Random recipient address
        uint256 amount = usdc.balanceOf(address(proxy));  // Full balance for transfer

        // Encode the call to USDC's transfer function
        bytes memory callData = abi.encodeWithSelector(usdc.transfer.selector, recipient, amount);

        // Create execution array
        Execution[] memory execution = new Execution[](1);
        execution[0] = Execution(address(usdc), 0, callData);

        // Pack user operation
        PackedUserOperation[] memory userOps = prepareUserOperation(BOB, Nexus(payable(address(PROXY_ADDRESS))), EXECTYPE_DEFAULT, execution);

        // Execute the operation via the EntryPoint
        ENTRYPOINT.handleOps(userOps, payable(OWNER_ADDRESS));

        // Check the recipient received the USDC
        assertEq(usdc.balanceOf(recipient), amount, "USDC transfer failed");
    }
}
