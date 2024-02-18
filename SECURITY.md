# Security Policy

## Reporting a Vulnerability

The safety and security of our smart contract platform is our top priority. If you have discovered a security vulnerability, we appreciate your help in disclosing it to us responsibly.

### Contact Us Directly for Critical or High-Risk Findings

For critical or high-impact vulnerabilities that could affect our users, **please contact us directly** at:

- Email: security@biconomy.io

We'll work with you to assess and understand the scope of the issue.

### For Other Issues

For vulnerabilities that are less critical and do not immediately affect our users:

1. Open an issue in our GitHub repository (`https://github.com/bcnmy/sc-template/issues`).

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
