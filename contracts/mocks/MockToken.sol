// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

// ──────────────────────────────────────────────────────────────────────────────
//     _   __    _  __
//    / | / /__ | |/ /_  _______
//   /  |/ / _ \|   / / / / ___/
//  / /|  /  __/   / /_/ (__  )
// /_/ |_/\___/_/|_\__,_/____/
//
// ──────────────────────────────────────────────────────────────────────────────
// Nexus: A suite of contracts for Modular Smart Account compliant with ERC-7579 and ERC-4337, developed by Biconomy.
// Learn more at https://biconomy.io/

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Note: could be imported from foundry mocks
contract MockToken is ERC20 {
    constructor() ERC20("TST", "MockToken") {}

    function mint(address sender, uint256 amount) external {
        _mint(sender, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function test() public pure {
        // @todo To be removed: This function is used to ignore file in coverage report
    }
}
