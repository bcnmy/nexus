// SPDX-License-Identifier: MIT
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
// Learn more at https://biconomy.io. For security issues, contact: security@biconomy.io

/**
 * @title Stakeable Entity
 * @author Fil Makarov - <filipp.makarov@biconomy.io>
 */
interface IStakeable {
    function addStake(
        address epAddress,
        uint32 unstakeDelaySec
    ) external payable;

    function unlockStake(address epAddress) external;

    function withdrawStake(
        address epAddress,
        address payable withdrawAddress
    ) external;
}
