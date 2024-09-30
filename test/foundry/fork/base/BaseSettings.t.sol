// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../../utils/NexusTest_Base.t.sol";

/// @title BaseSettings
/// @notice This contract sets up the constants required for Base fork tests
contract BaseSettings is NexusTest_Base {
    address public constant UNISWAP_V2_ROUTER02 = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;
    address public constant USDC_ADDRESS = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    string public constant DEFAULT_BASE_RPC_URL = "https://mainnet.base.org";
    //string public constant DEFAULT_BASE_RPC_URL = "https://base.llamarpc.com";
    //string public constant DEFAULT_BASE_RPC_URL = "https://developer-access-mainnet.base.org";
    uint constant BLOCK_NUMBER = 15000000;

    /// @notice Retrieves the Base RPC URL from the environment variable or defaults to the hardcoded URL
    /// @return rpcUrl The Base RPC URL
    function getBaseRpcUrl() internal view returns (string memory) {
        string memory rpcUrl = vm.envOr("BASE_RPC_URL", DEFAULT_BASE_RPC_URL);
        return rpcUrl;
    }
}
