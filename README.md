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

Unfortunately, one of the dependencies does not populate the `package.json` file. That prevents hardhat from building the project successfully, while Foundry builds just fine.

So you may want to add this package.json manually.
After doing `yarn install`, you can do:

```bash
cd node_modules/prep
touch package.json
```

then add the following content to the `package.json` file:

```json
{
  "name": "prep",
  "version": "0.0.0",
  "private": true,
  "dependencies": {}
}
```

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

If you need to deploy Nexus on your own chain or you want to deploy the contracts with different addresses, please see [this](https://github.com/bcnmy/nexus/tree/deploy-v1.0.1/scripts/bash-deploy) script. Or the same script on different deploy branches.

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
| Zenith           | 03-2025 | [View Report](./audits/Biconomy-Nexus_Zenith-Audit-Report.pdf) |
| Pashov           | 03-2025 | [View Report](./audits/Nexus-Pashov-Review_2025-03.pdf) |

### Before you fork or self-deploy

`main` contains a fix for a disclosed issue affecting classic (non-7702) accounts that hold funds **before** they are deployed. Build from `main` at or after commit `272c408`; earlier commits and tags do not contain it. Accounts already deployed on chain were never exposed, and EIP-7702 and Fusion flows are unaffected.

The full description, including which versions are affected and what to do if you already deployed from an earlier commit, is in [SECURITY.md](./SECURITY.md#published-advisories).

## License

This project is licensed under the MIT License. See the [LICENSE](./LICENSE) file for details.

## Connect with Biconomy 🍊

[![Website](https://img.shields.io/badge/🍊-Website-ff4e17?style=for-the-badge&logoColor=white)](https://biconomy.io) [![Telegram](https://img.shields.io/badge/Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/biconomy) [![Twitter](https://img.shields.io/badge/Twitter-1DA1F2?style=for-the-badge&logo=twitter&logoColor=white)](https://twitter.com/biconomy) [![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/company/biconomy) [![Discord](https://img.shields.io/badge/Discord-7289DA?style=for-the-badge&logo=discord&logoColor=white)](https://discord.gg/biconomy) [![YouTube](https://img.shields.io/badge/YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white)](https://www.youtube.com/channel/UC0CtA-Dw9yg-ENgav_VYjRw) [![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/bcnmy/)
