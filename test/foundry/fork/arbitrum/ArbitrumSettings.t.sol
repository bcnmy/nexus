// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { NexusTest_Base } from "../../utils/NexusTest_Base.t.sol";

/// @title ArbitrumSettings
/// @notice This contract sets up the constants required for Arbitrum fork tests
contract ArbitrumSettings is NexusTest_Base {
    address public constant SMART_ACCOUNT_V2_ADDRESS = 0x920F12FD41B77030EA4e913b71ce1C072a576c48;
    address public constant OWNER_ADDRESS = 0xBF18f4f70d4Be6E6B0bfC9e185a2eE48d15C6cD8;
    address public constant ENTRYPOINT_ADDRESS = 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789;
    address public constant MODULE_ADDRESS = 0x0000001c5b32F37F5beA87BDD5374eB2aC54eA8e;
    address public constant USDC_ADDRESS = 0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8;
    string public constant DEFAULT_ARBITRUM_RPC_URL = "https://arbitrum.meowrpc.com";
    // Backup URLs
    // string public constant DEFAULT_ARBITRUM_RPC_URL = "https://arbitrum.blockpi.network/v1/rpc/public";
    //string public constant DEFAULT_ARBITRUM_RPC_URL = "https://public.stackup.sh/api/v1/node/arbitrum-one";
    //string public constant DEFAULT_ARBITRUM_RPC_URL = "https://arb-pokt.nodies.app";
    //string public constant DEFAULT_ARBITRUM_RPC_URL = "https://rpc.ankr.com/arbitrum";
    //string public constant DEFAULT_ARBITRUM_RPC_URL = "https://arbitrum-one-rpc.publicnode.com";
    uint constant BLOCK_NUMBER = 209480000;

    /// @notice Retrieves the Arbitrum RPC URL from the environment variable or defaults to the hardcoded URL
    function getArbitrumRpcUrl() internal view returns (string memory) {
        string memory rpcUrl = vm.envOr("ARBITRUM_RPC_URL", DEFAULT_ARBITRUM_RPC_URL);
        return rpcUrl;
    }
}
