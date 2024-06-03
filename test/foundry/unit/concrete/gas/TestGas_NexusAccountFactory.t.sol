// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../../../shared/TestModuleManagement_Base.t.sol";

/// @title Gas benchmark tests for NexusAccountFactory
contract TestGas_NexusAccountFactory is TestModuleManagement_Base {
    function setUp() public {
        init();
    }

    /// @notice Tests gas usage for deploying a new account
    function test_Gas_DeployAccount() public {
        uint256 initialGas = gasleft();
        address newAccount = FACTORY.createAccount(getInitData(address(VALIDATOR_MODULE), address(this)), keccak256("deploy_account_test"));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for deploying a new account: ", gasUsed);

        // Verifying the account was deployed correctly
        assertTrue(newAccount != address(0), "New account address should not be zero");
    }

    /// @notice Tests gas usage for deploying a new account with different parameters
    function test_Gas_DeployAccountWithDifferentParams() public {
        uint256 initialGas = gasleft();
        address newAccount = FACTORY.createAccount(
            getInitData(address(VALIDATOR_MODULE), address(mockExecutor)),
            keccak256("deploy_account_with_diff_params_test")
        );
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for deploying a new account with different parameters: ", gasUsed);

        // Verifying the account was deployed correctly
        assertTrue(newAccount != address(0), "New account address should not be zero");
    }

    /// @notice Tests gas usage for deploying multiple accounts
    function test_Gas_DeployMultipleAccounts() public {
        uint256 initialGas = gasleft();
        for (uint i = 0; i < 5; i++) {
            FACTORY.createAccount(getInitData(address(VALIDATOR_MODULE), address(this)), keccak256(abi.encodePacked("deploy_multiple_accounts", i)));
        }
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for deploying multiple accounts: ", gasUsed);
    }

    /// @notice Tests gas usage for deploying an account and verifying module installation
    function test_Gas_DeployAccountAndVerifyModuleInstallation() public {
        uint256 initialGas = gasleft();
        address newAccount = FACTORY.createAccount(getInitData(address(VALIDATOR_MODULE), address(this)), keccak256("deploy_account_verify_module"));
        uint256 gasUsed = initialGas - gasleft();
        console.log("Gas used for deploying a new account and verifying module installation: ", gasUsed);

        // Verifying the module was installed correctly
        bool moduleInstalled = Nexus(payable(newAccount)).isModuleInstalled(MODULE_TYPE_VALIDATOR, address(VALIDATOR_MODULE), "");
        assertTrue(moduleInstalled, "Validator module should be installed");
    }

    /// @notice Helper function to get the initialization data for account creation
    function getInitData(address validator, address owner) internal view returns (bytes memory) {
        BootstrapConfig[] memory validators = BootstrapLib.createArrayConfig(validator, abi.encodePacked(owner));
        BootstrapConfig memory hook = BootstrapLib.createSingleConfig(address(0), "");
        return BOOTSTRAPPER.getInitNexusScopedCalldata(validators, hook);
    }
}
