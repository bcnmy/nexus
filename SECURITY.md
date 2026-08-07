# Security Policy

## Published Advisories

### Stale transient initialization flag (GHSA-q47q-h6x2-f5qg)

`NexusProxy` set the `Initializable` transient flag in its constructor and never cleared it. EIP-1153 transient storage persists for the whole transaction, so the classic (non-7702) `initializeAccount` guard still passed on a second call within the deploying transaction. An account that held funds at its counterfactual address before being deployed could be deployed and then re-initialized in the same transaction with attacker-supplied bootstrap data.

**Affected**

- Classic (non-7702) Nexus accounts, version 1.2.0 and above, **only while they hold a balance and have not yet been deployed**

**Not affected**

- Accounts already deployed on chain. Deployment is the point at which an account stops being exposed, and it is permanent for that account
- EIP-7702 accounts and Fusion flows, which do not hold funds at an undeployed account address
- Biconomy Smart Account V2

**Fixed in**

| Where | Fixed at |
| ----- | -------- |
| This repository | `contracts/lib/Initializable.sol`, commit `272c408` on `main` |
| Deployed contracts | Nexus 1.3.3, shipped as MEE contract suite 2.2.3 |

`requireInitializable()` now consumes the flag by clearing the transient slot, making it single-use within the deploying transaction.

The deployed fix was built from [bcnmy/stx-contracts](https://github.com/bcnmy/stx-contracts), which carries the Nexus 1.3.3 lineage, and reviewed by Pashov Audit Group in July 2026. This repository is on the 1.2.1 lineage and receives the same change so that forks and self-deployments are built from fixed code.

**If you fork or deploy this repository yourself**

Build from `main` at or after commit `272c408`. Earlier commits and tags contain the issue. If you have already deployed contracts from an earlier commit and hold balances at account addresses that have not been deployed yet, deploy those accounts. Any operation deploys an account, including one with empty calldata, and the funds do not need to be moved.

See [Account Migration](https://docs.biconomy.io/upgrade-migrate) for the version-by-version picture and [Contracts & Audits](https://docs.biconomy.io/contracts-and-audits) for deployed addresses.

## Reporting a Vulnerability

The safety and security of our smart contract platform is our top priority. If you have discovered a security vulnerability, we appreciate your help in disclosing it to us responsibly.

### Contact Us Directly for Critical or High-Risk Findings

For critical or high-impact vulnerabilities that could affect our users, **please contact us directly** at:

- Email: security@biconomy.io

We'll work with you to assess and understand the scope of the issue.

### For Other Issues

For vulnerabilities that are less critical and do not immediately affect our users:

1. Open an issue in our GitHub repository (`https://github.com/bcnmy/nexus/issues`).

2. Provide detailed information about the issue and steps to reproduce.

If your findings are eligible for a bounty, we will follow up with you on the payment process.

## Bug Bounty Program

We run a bug bounty program to encourage and reward those who help us improve the security of our smart contracts. The rewards are distributed according to the impact of the vulnerability based on the severity levels outlined below.

### Rewards by Threat Level

- **Critical:** Up to $50,000

- **High:** Up to $10,000

- **Medium and Low:** Case by case

In addition to security improvements, we actively support initiatives aimed at optimizing our smart contracts for better gas efficiency as outlined in our [GAS_OPTIMIZATION.md](./GAS_OPTIMIZATION.md). Contributors who make significant strides in either area will be recognized for their efforts. To learn more about making contributions across various areas, including potential rewards and our appreciation program, refer to our [CONTRIBUTING.md](./CONTRIBUTING.md).

### Scope

The bounty program covers code in the `main` branch of our repository, focusing on Solidity smart contracts. The vulnerability must not have already been addressed or fixed in the `develop` branch.

### Eligibility

To be eligible for a bounty, researchers must:

- Report a security bug that has not been previously reported.

- Not violate our testing policies (detailed below).

- Follow responsible disclosure guidelines.

### Testing Policies

- Do not conduct testing on the mainnet or public testnets. Local forks should be used for testing.

- Avoid testing that generates significant traffic or could lead to denial of service.

- Do not disclose the vulnerability publicly until we have had the chance to address it.

### Out of Scope

- Known issues listed in the issue tracker or already fixed in the `develop` branch.

- Issues in third-party components unless they directly affect our smart contracts.

- Basic economic and governance attacks, e.g., 51% attacks.

## Legal Notice

By submitting a vulnerability report, you agree to comply with our responsible disclosure process. Public disclosure of the vulnerability without consent from us will render the vulnerability ineligible for a bounty.

Thank you for helping to keep Biconomy 🍊 and the blockchain community safe!
