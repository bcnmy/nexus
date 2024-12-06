// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

import {VmSafe} from "forge-std/Vm.sol";

/// @notice Library for deploying contracts using Deterministic Deployer
/// @dev forked from Wilson Cusack's https://github.com/wilsoncusack/safe-singleton-deployer-sol 
library DeterministicDeployerLib {
    error DeployFailed();

    address constant DETERMINISTIC_DEPLOYER = 0x4e59b44847b379578588920cA78FbF26c0B4956C;
    VmSafe private constant VM = VmSafe(address(uint160(uint256(keccak256("hevm cheat code")))));

    function computeAddress(bytes memory creationCode, bytes32 salt) internal pure returns (address) {
        return computeAddress(creationCode, "", salt);
    }

    function computeAddress(bytes memory creationCode, bytes memory args, bytes32 salt) internal pure returns (address) {
        return VM.computeCreate2Address({
            salt: salt,
            initCodeHash: _hashInitCode(creationCode, args),
            deployer: DETERMINISTIC_DEPLOYER
        });
    }

    function broadcastDeploy(bytes memory creationCode, bytes memory args, bytes32 salt) internal returns (address) {
        VM.broadcast();
        return _deploy(creationCode, args, salt);
    }

    function broadcastDeploy(bytes memory creationCode, bytes32 salt) internal returns (address) {
        VM.broadcast();
        return _deploy(creationCode, "", salt);
    }

    function broadcastDeploy(address deployer, bytes memory creationCode, bytes memory args, bytes32 salt)
        internal
        returns (address)
    {
        VM.broadcast(deployer);
        return _deploy(creationCode, args, salt);
    }

    function broadcastDeploy(address deployer, bytes memory creationCode, bytes32 salt) internal returns (address) {
        VM.broadcast(deployer);
        return _deploy(creationCode, "", salt);
    }

    function broadcastDeploy(uint256 deployerPrivateKey, bytes memory creationCode, bytes memory args, bytes32 salt)
        internal
        returns (address)
    {
        VM.broadcast(deployerPrivateKey);
        return _deploy(creationCode, args, salt);
    }

    function broadcastDeploy(uint256 deployerPrivateKey, bytes memory creationCode, bytes32 salt)
        internal
        returns (address)
    {
        VM.broadcast(deployerPrivateKey);
        return _deploy(creationCode, "", salt);
    }

    /// @dev Allows calling without Forge broadcast
    function deploy(bytes memory creationCode, bytes memory args, bytes32 salt) internal returns (address) {
        return _deploy(creationCode, args, salt);
    }

    /// @dev Allows calling without Forge broadcast
    function deploy(bytes memory creationCode, bytes32 salt) internal returns (address) {
        return _deploy(creationCode, "", salt);
    }

    function _deploy(bytes memory creationCode, bytes memory args, bytes32 salt) private returns (address) {
        bytes memory callData = abi.encodePacked(salt, creationCode, args);

        (bool success, bytes memory result) = DETERMINISTIC_DEPLOYER.call(callData);

        if (!success) {
            // contract does not pass on revert reason
            // https://github.com/Arachnid/deterministic-deployment-proxy/blob/master/source/deterministic-deployment-proxy.yul#L13
            revert DeployFailed();
        }

        return address(bytes20(result));
    }

    function _hashInitCode(bytes memory creationCode, bytes memory args) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(creationCode, args));
    }
}