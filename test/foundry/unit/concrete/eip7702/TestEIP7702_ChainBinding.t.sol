// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { NexusTest_Base } from "../../../utils/NexusTest_Base.t.sol";
import "../../../utils/Imports.sol";
import { INexus } from "contracts/interfaces/INexus.sol";
import { Nexus } from "contracts/Nexus.sol";
import { MockValidator } from "contracts/mocks/MockValidator.sol";
import { MockExecutor } from "contracts/mocks/MockExecutor.sol";
import { MockPreValidationHook } from "contracts/mocks/MockPreValidationHook.sol";

contract TestEIP7702_ChainBinding is NexusTest_Base {
    MockValidator public mockValidator;
    MockExecutor public mockExecutor;
    MockPreValidationHook public mockPreValidationHook;

    function setUp() public {
        setupTestEnvironment();
        mockValidator = new MockValidator();
        mockExecutor = new MockExecutor();
        mockPreValidationHook = new MockPreValidationHook();
    }

    function _getActualInitData() internal view returns (bytes memory) {
        BootstrapConfig[] memory validators = BootstrapLib.createArrayConfig(address(mockValidator), "");
        BootstrapConfig[] memory executors = BootstrapLib.createArrayConfig(address(mockExecutor), "");
        BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(0), "");
        BootstrapConfig[] memory fallbacks = BootstrapLib.createArrayConfig(address(0), "");
        BootstrapPreValidationHookConfig[] memory preValidationHooks =
            BootstrapLib.createArrayPreValidationHookConfig(MODULE_TYPE_PREVALIDATION_HOOK_ERC4337, address(mockPreValidationHook), "");

        return abi.encode(
            address(BOOTSTRAPPER),
            abi.encodeCall(
                BOOTSTRAPPER.initNexus,
                (validators, executors, hook, fallbacks, preValidationHooks, RegistryConfig({ registry: REGISTRY, attesters: ATTESTERS, threshold: THRESHOLD }))
            )
        );
    }

    /// @notice Proves that getERC7702InitDigest is chain-bound and differs between chains
    function test_getERC7702InitDigest_differsAcrossChains() public {
        uint256 eoaKey = 0xB0B;
        address account = vm.addr(eoaKey);
        bytes memory actualInitData = _getActualInitData();

        vm.chainId(1);
        _doEIP7702(account);
        bytes32 digestChain1 = INexus(account).getERC7702InitDigest(actualInitData);

        vm.chainId(8453);
        _doEIP7702(account);
        bytes32 digestChain8453 = INexus(account).getERC7702InitDigest(actualInitData);

        assertTrue(digestChain1 != digestChain8453, "EIP-712 init digest must be chain-bound");
    }

    /// @notice Proves that a signature created for Chain 1 reverts with InvalidSignature on Chain 8453
    function test_revertWhen_crossChainReplayOfRelayInitialization() public {
        uint256 eoaKey = 0xB0B;
        address account = vm.addr(eoaKey);
        address relayer = address(0x999);

        bytes memory actualInitData = _getActualInitData();

        // 1. Owner signs initData on Chain 1 (e.g. Ethereum Mainnet)
        vm.chainId(1);
        _doEIP7702(account);

        bytes32 initDataDigestChain1 = INexus(account).getERC7702InitDigest(actualInitData);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaKey, initDataDigestChain1);
        bytes memory sig = abi.encodePacked(r, s, v);
        bytes memory relayCalldata = abi.encodePacked(sig, actualInitData);

        // 2. Relayer attempts to replay the Chain 1 signature on Chain 8453 (e.g. Base)
        vm.chainId(8453);
        _doEIP7702(account);

        // On Chain 8453, the Chain 1 signature must be rejected with InvalidSignature
        vm.prank(relayer);
        vm.expectRevert(InvalidSignature.selector);
        INexus(account).initializeAccount(relayCalldata);

        assertFalse(Nexus(payable(account)).isInitialized());
    }

    /// @notice Demonstrates that valid chain-bound initialization succeeds on the intended chain
    function test_relayInitialization_succeeds_on_intended_chain() public {
        uint256 eoaKey = 0xB0B;
        address account = vm.addr(eoaKey);
        address relayer = address(0x999);

        bytes memory actualInitData = _getActualInitData();

        vm.chainId(8453);
        _doEIP7702(account);

        bytes32 initDataDigest = INexus(account).getERC7702InitDigest(actualInitData);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaKey, initDataDigest);
        bytes memory sig = abi.encodePacked(r, s, v);
        bytes memory relayCalldata = abi.encodePacked(sig, actualInitData);

        vm.prank(relayer);
        INexus(account).initializeAccount(relayCalldata);

        assertTrue(Nexus(payable(account)).isInitialized());
    }

    /// @notice Demonstrates that replaying the same initialization twice on the same chain reverts
    function test_revertWhen_replayingOnSameChain() public {
        uint256 eoaKey = 0xB0B;
        address account = vm.addr(eoaKey);
        address relayer = address(0x999);

        bytes memory actualInitData = _getActualInitData();

        vm.chainId(8453);
        _doEIP7702(account);

        bytes32 initDataDigest = INexus(account).getERC7702InitDigest(actualInitData);

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(eoaKey, initDataDigest);
        bytes memory sig = abi.encodePacked(r, s, v);
        bytes memory relayCalldata = abi.encodePacked(sig, actualInitData);

        // First initialization succeeds
        vm.prank(relayer);
        INexus(account).initializeAccount(relayCalldata);

        // Second initialization attempt reverts
        vm.prank(relayer);
        vm.expectRevert(AccountAlreadyInitialized.selector);
        INexus(account).initializeAccount(relayCalldata);
    }
}
