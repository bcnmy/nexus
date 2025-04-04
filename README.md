[![Biconomy](https://img.shields.io/badge/Made_with_%F0%9F%8D%8A_by-Biconomy-ff4e17?style=flat)](https://biconomy.io) [![License MIT](https://img.shields.io/badge/License-MIT-blue?&style=flat)](./LICENSE) [![Hardhat](https://img.shields.io/badge/Built%20with-Hardhat-FFDB1C.svg)](https://hardhat.org/) [![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFBD10.svg)](https://getfoundry.sh/)

![Codecov Hardhat Coverage](https://img.shields.io/badge/90%25-green?style=flat&logo=codecov&label=Hardhat%20Coverage) ![Codecov Foundry Coverage](https://img.shields.io/badge/100%25-brightgreen?style=flat&logo=codecov&label=Foundry%20Coverage)

# Nexus - ERC-7579 Modular Smart Account Base 🚀

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/bcnmy/nexus)

This repository serves as a comprehensive foundation for smart contract projects, streamlining the development process with a focus on best practices, security, and efficiency.

Documentation: (https://github.com/bcnmy/nexus/wiki)

## 📚 Table of Contents

- [Nexus - ERC-7579 Modular Smart Account Base 🚀](#nexus---erc-7579-modular-smart-account-base-)
  - [📚 Table of Contents](#-table-of-contents)
  - [Getting Started](#getting-started)
    - [Prerequisites](#prerequisites)
    - [Installation](#installation)
  - [🛠️ Essential Scripts](#️-essential-scripts)
    - [🏗️ Build Contracts](#️-build-contracts)
    - [🧪 Run Tests](#-run-tests)
    - [⛽ Gas Report](#-gas-report)
    - [📊 Coverage Report](#-coverage-report)
    - [📄 Documentation](#-documentation)
    - [🚀 Deploy Contracts](#-deploy-contracts)
    - [🎨 Lint Code](#-lint-code)
    - [🖌️ Auto-fix Linting Issues](#️-auto-fix-linting-issues)
    - [🚀 Generating Storage Layout](#-generating-storage-layout)
  - [🔒 Security Audits](#-security-audits)
  - [🏆 Biconomy Champions League 🏆](#-biconomy-champions-league-)
    - [Champions Roster](#champions-roster)
    - [Entering the League](#entering-the-league)
  - [Documentation and Resources](#documentation-and-resources)
  - [License](#license)
  - [Connect with Biconomy 🍊](#connect-with-biconomy-)

## Getting Started

To kickstart, follow these steps:

### Prerequisites

- Node.js (v18.x or later)
- Yarn (or npm)
- Foundry (Refer to [Foundry installation instructions](https://book.getfoundry.sh/getting-started/installation))

### Installation

1. **Clone the repository:**

```bash
git clone https://github.com/bcnmy/nexus.git
cd nexus
```

2. **Install dependencies:**

```bash
yarn install
```

3. **Setup environment variables:**

Copy `.env.example` to `.env` and fill in your details.

## 🛠️ Essential Scripts

Execute key operations for Foundry and Hardhat with these scripts. Append `:forge` or `:hardhat` to run them in the respective environment.

### 🏗️ Build Contracts

```bash
yarn build
```

Compiles contracts for both Foundry and Hardhat.

### 🧪 Run Tests

```bash
yarn test
```

Carries out tests to verify contract functionality.

### ⛽ Gas Report

```bash
yarn test:gas
```

Creates detailed reports for test coverage.

### 📊 Coverage Report

```bash
yarn coverage
```

Creates detailed reports for test coverage.

### 📄 Documentation

```bash
yarn docs
```

Generate documentation from NatSpec comments.

### 🚀 Deploy Contracts

Nexus contracts are pre-deployed on most EVM chains.
Please see the addresses [here](https://docs.biconomy.io/contractsAndAudits).

If you need to deploy Nexus on your own chain or you want to deploy the contracts with different addresses, please see [this](https://github.com/bcnmy/nexus/tree/deploy-v1.0.1/scripts/bash-deploy) script. Or the same script on differnet deploy branches.

### 🎨 Lint Code

```bash
yarn lint
```

Checks code for style and potential errors.

### 🖌️ Auto-fix Linting Issues

```bash
yarn lint:fix
```

Automatically fixes linting problems found.

### 🚀 Generating Storage Layout

```bash
yarn check
```

To generate reports of the storage layout for potential upgrades safety using `hardhat-storage-layout`.

🔄 Add `:forge` or `:hardhat` to any script above to target only Foundry or Hardhat environment, respectively.

## 🔒 Security Audits

| Auditor          | Date       | Final Report Link       |
| ---------------- | ---------- | ----------------------- |
| CodeHawks-Cyfrin | 17-09-2024 | [View Report](./audits/CodeHawks-Cyfrin-17-09-2024.pdf) |
| Spearbit         | 10/11-2024 | [View Report](./audits/report-cantinacode-biconomy-0708-final.pdf) / [View Add-on](./audits/report-cantinacode-biconomy-erc7739-addon-final.pdf) |

### Entering the League

Your journey to becoming a champion can start in any domain:

- **Code Wizards**: Dive into our [Gas Optimization](./GAS_OPTIMIZATION.md) efforts.
- **Security Guardians**: Enhance our safety following the [Security Guidelines](./SECURITY.md).
- **Documentation Scribes**: Elevate our knowledge base with your contributions.

The **Champions League** is not just a recognition, it's a testament to the impactful work done by our community. Whether you're optimizing gas usage or securing our contracts, your contributions help shape the future of Biconomy.

> **To Join**: Leave a lasting impact in your chosen area. Our Hall of Fame is regularly updated to honor our most dedicated contributors.

Let's build a legacy together, championing innovation and excellence in the blockchain space.

## Documentation and Resources

For a comprehensive understanding of our project and to contribute effectively, please refer to the following resources:

- [**Contributing Guidelines**](./CONTRIBUTING.md): Learn how to contribute to our project, from code contributions to documentation improvements.
- [**Code of Conduct**](./CODE_OF_CONDUCT.md): Our commitment to fostering an open and welcoming environment.
- [**Security Policy**](./SECURITY.md): Guidelines for reporting security vulnerabilities.
- [**Gas Optimization Program**](./GAS_OPTIMIZATION.md): Contribute towards optimizing gas efficiency of our smart contracts.
- [**Changelog**](./CHANGELOG.md): Stay updated with the changes and versions.

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

## Connect with Biconomy 🍊

[![Website](https://img.shields.io/badge/🍊-Website-ff4e17?style=for-the-badge&logoColor=white)](https://biconomy.io) [![Telegram](https://img.shields.io/badge/Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/biconomy) [![Twitter](https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://twitter.com/biconomy) [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/company/biconomy) [![Discord](https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/biconomy) [![YouTube](https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/channel/UC0CtA-Dw9yg-ENgav_VYjRw) [![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/bcnmy/)
