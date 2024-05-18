// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { InvariantBaseTest } from "../base/InvariantBaseTest.t.sol";
import "../../utils/Imports.sol";

contract ModuleManagementHandlerTest is InvariantBaseTest {
    Nexus public nexusAccount;
    Vm.Wallet public signer;

    constructor(Nexus _nexusAccount, Vm.Wallet memory _signer) {
        nexusAccount = _nexusAccount;
        signer = _signer;
    }

    function installModule(uint256 moduleType, address moduleAddress) public {
        bytes memory callData = abi.encodeWithSelector(Nexus.installModule.selector, moduleType, moduleAddress, "");

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: 0, callData: callData });

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));
    }

    function uninstallModule(uint256 moduleType, address moduleAddress) public {
        bytes memory callData = abi.encodeWithSelector(Nexus.uninstallModule.selector, moduleType, moduleAddress, "");

        Execution[] memory executions = new Execution[](1);
        executions[0] = Execution({ target: address(nexusAccount), value: 0, callData: callData });

        PackedUserOperation[] memory userOps = buildPackedUserOperation(
            signer,
            nexusAccount,
            EXECTYPE_DEFAULT,
            executions,
            address(VALIDATOR_MODULE)
        );
        ENTRYPOINT.handleOps(userOps, payable(signer.addr));
    }

    function checkModuleInstalled(uint256 moduleType, address moduleAddress) public view returns (bool) {
        return nexusAccount.isModuleInstalled(moduleType, moduleAddress, "");
    }
}
