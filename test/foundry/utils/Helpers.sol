// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CheatCodes.sol";
import "./Imports.sol";
import { PackedUserOperation } from "account-abstraction/contracts/interfaces/PackedUserOperation.sol";

contract Helpers is CheatCodes {
    // Pre-defined roles
    Vm.Wallet public DEPLOYER;
    Vm.Wallet public ALICE;
    Vm.Wallet public BOB;
    Vm.Wallet public CHARLIE;
    Vm.Wallet public BUNDLER;

    address public DEPLOYER_ADDRESS;
    address public ALICE_ADDRESS;
    address public BOB_ADDRESS;
    address public CHARLIE_ADDRESS;
    address public BUNDLER_ADDRESS;
    IEntryPointPatch public ENTRYPOINT;
    AccountFactory public FACTORY;
    MockValidator public VALIDATOR_MODULE;

    function setAddress() public virtual {
        DEPLOYER = newWallet("DEPLOYER");
        DEPLOYER_ADDRESS = DEPLOYER.addr;
        vm.deal(DEPLOYER_ADDRESS, 1000 ether);

        ALICE = newWallet("ALICE");
        ALICE_ADDRESS = ALICE.addr;
        vm.deal(ALICE_ADDRESS, 1000 ether);

        BOB = newWallet("BOB");
        BOB_ADDRESS = BOB.addr;
        vm.deal(BOB_ADDRESS, 1000 ether);

        CHARLIE = newWallet("CHARLIE");
        CHARLIE_ADDRESS = CHARLIE.addr;
        vm.deal(CHARLIE_ADDRESS, 1000 ether);

        BUNDLER = newWallet("BUNDLER");
        BUNDLER_ADDRESS = BUNDLER.addr;
        vm.deal(BUNDLER_ADDRESS, 1000 ether);

        /* ENTRYPOINT = new EntryPoint();
        changeContractAddress(address(ENTRYPOINT), 0x0000000071727De22E5E9d8BAf0edAc6f37da032);
        ENTRYPOINT = IEntryPoint(0x0000000071727De22E5E9d8BAf0edAc6f37da032); */

        ENTRYPOINT = new EntryPointPatch();
        changeContractAddress(address(ENTRYPOINT), 0x0000000071727De22E5E9d8BAf0edAc6f37da032);
        ENTRYPOINT = IEntryPointPatch(0x0000000071727De22E5E9d8BAf0edAc6f37da032);

        FACTORY = new AccountFactory();

        VALIDATOR_MODULE = new MockValidator();
    }

    function sendEther(address to, uint256 amount) internal {
        payable(to).transfer(amount);
    }

    function setupContractAs(
        address sender,
        uint256 value,
        bytes memory constructorArgs,
        bytes memory bytecode
    )
        internal
        returns (address)
    {
        startPrank(sender);
        address deployedAddress; // Deploy the contract
        stopPrank();
        return deployedAddress;
    }

    function assertBalance(address addr, uint256 expectedBalance, string memory message) internal {
        require(addr.balance == expectedBalance, message);
    }

    function simulateTimePassing(uint256 nbDays) internal {
        warpTo(block.timestamp + nbDays * 1 days);
    }

    // Helper to modify the address of a deployed contract in a test environment
    function changeContractAddress(address originalAddress, address newAddress) internal {
        setContractCode(originalAddress, address(originalAddress).code);
        setContractCode(newAddress, originalAddress.code);
    }

    // Helper to build a user operation struct for account abstraction tests
    function buildPackedUserOp(address sender, uint256 nonce) internal pure returns (PackedUserOperation memory) {
        return PackedUserOperation({
            sender: sender,
            nonce: nonce,
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(abi.encodePacked(uint128(3e6), uint128(3e6))),
            preVerificationGas: 3e6,
            gasFees: bytes32(abi.encodePacked(uint128(3e6), uint128(3e6))),
            paymasterAndData: "",
            signature: ""
        });
    }

    // Utility method to encode and sign a message, then pack r, s, v into bytes
    function signMessageAndGetSignatureBytes(
        Vm.Wallet memory wallet,
        bytes32 messageHash
    )
        internal
        returns (bytes memory signature)
    {
        bytes32 userOpHash = ECDSA.toEthSignedMessageHash(messageHash);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(wallet.privateKey, userOpHash);
        signature = abi.encodePacked(r, s, v);
    }

    function getAccountAddress(address signer) internal view returns (address account) {
        bytes memory initData = abi.encodePacked(signer);

        uint256 moduleTypeId = uint256(ModuleType.Validation);

        account = FACTORY.computeAccountAddress(address(VALIDATOR_MODULE), moduleTypeId, initData);

        return account;
    }
    // Method to create a UserOperation

    function createUserOperation(
        Vm.Wallet memory wallet,
        address module
    )
        internal
        returns (PackedUserOperation memory userOp)
    {
        address accountAddress = getAccountAddress(wallet.addr);

        // Constructing the UserOperation with the signed hash
        userOp = PackedUserOperation({
            sender: accountAddress,
            nonce: _getNonce(accountAddress, module),
            initCode: "",
            callData: "",
            accountGasLimits: bytes32(abi.encodePacked(uint128(3e6), uint128(3e6))),
            preVerificationGas: 3e6,
            gasFees: bytes32(abi.encodePacked(uint128(3e6), uint128(3e6))),
            paymasterAndData: "",
            signature: ""
        });
    }

    function createInitCode(
        address ownerAddress,
        bytes4 createAccountSelector
    )
        internal
        view
        returns (bytes memory initCode)
    {
        address module = address(VALIDATOR_MODULE);
        uint256 moduleTypeId = uint256(ModuleType.Validation);
        bytes memory moduleInitData = abi.encodePacked(ownerAddress);

        // Prepend the factory address to the encoded function call to form the initCode
        initCode = abi.encodePacked(
            address(FACTORY),
            abi.encodeWithSelector(FACTORY.createAccount.selector, module, moduleTypeId, moduleInitData)
        );
    }

    function _getNonce(address account, address validator) internal returns (uint256 nonce) {
        uint192 key = uint192(bytes24(bytes20(address(validator))));
        nonce = ENTRYPOINT.getNonce(address(account), key);
    }

    /**
     * @dev Helper to log gas usage for an external call
     * USAGE example:
     * W/o logging: ENTRYPOINT.handleOpsLogGas(userOps, payable(ALICE.addr));
     * With logging: _gasLog(address(ENTRYPOINT), 0, abi.encodeCall(IEntryPoint.handleOps, (userOps,
     * payable(wallet.addr))));
     */
    function _gasLog(address dest, uint256 value, bytes memory data) internal {
        _gasLogExecutionGas(dest, value, data);
        _gasLogCalldataGas(data);
    }

    /**
     * @dev Console logs the execution gas
     */
    function _gasLogExecutionGas(address dest, uint256 value, bytes memory data) internal {
        console2.log("Execution gas cost (external call): ", _estimateExecutionGas(dest, value, data));
    }

    /**
     * @dev Logs calldata gas
     */
    function _gasLogCalldataGas(bytes memory data) internal {
        uint256 calldataGas = _estimateCallDataGas(data);
        console2.log("Calldata gas cost: ", calldataGas);
    }

    /**
     * @dev Executes the external call
     * And returns the gasleft() difference
     */
    function _estimateExecutionGas(address dest, uint256 value, bytes memory data) internal returns (uint256) {
        uint256 gasStart = gasleft();
        (bool success, bytes memory returnData) = dest.call{ value: value }(data);
        require(success, "Call failed");
        return gasStart - gasleft();
    }

    /**
     * @dev Estimates the gas cost of the calldata
     * 0x00 costs 4 gas, 0x01-0xff costs 16 gas
     * https://ethereum.org/en/developers/tutorials/short-abi/#cost-of-l2-transactions
     */
    function _estimateCallDataGas(bytes memory data) internal view returns (uint256) {
        uint256 cost = 0;
        for (uint256 i = 0; i < data.length; i++) {
            if (data[i] == 0x00) {
                cost += 4;
            } else {
                cost += 16;
            }
        }
        return cost;
    }

    function testHelpers(uint256 a) public {
        a;
    }
}
