// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import { Nexus } from "contracts/Nexus.sol";
import { INexus } from "contracts/interfaces/INexus.sol";
interface IExposedNexus is INexus {
    function amIERC7702() external view returns (bool);
}

contract ExposedNexus is Nexus, IExposedNexus {

    constructor(address anEntryPoint) Nexus(anEntryPoint) {}

    function amIERC7702() external view returns (bool) {
        return _amIERC7702();
    }
}


