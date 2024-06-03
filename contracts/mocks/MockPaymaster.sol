// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import { IEntryPoint } from "account-abstraction/contracts/interfaces/IEntryPoint.sol";
import { VerifyingPaymaster } from "account-abstraction/contracts/samples/VerifyingPaymaster.sol";

contract MockPaymaster is VerifyingPaymaster {
    constructor(address _entryPoint, address _signer) VerifyingPaymaster(IEntryPoint(_entryPoint), _signer) {}
}
