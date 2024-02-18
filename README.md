[![Biconomy](https://img.shields.io/badge/Made_with_%F0%9F%8D%8A_by-Biconomy-ff4e17?style=flat)](https://biconomy.io) [![License MIT](https://img.shields.io/badge/License-MIT-blue?&style=flat)](./LICENSE) [![Hardhat](https://img.shields.io/badge/Built%20with-Hardhat-FFDB1C.svg)](https://hardhat.org/) [![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFBD10.svg)](https://getfoundry.sh/)

![Codecov Hardhat Coverage](https://img.shields.io/codecov/c/gh/bcnmy/sc-template?token=2BYDIFQ56W&flag=hardhat&label=Hardhat-coverage&logo=codecov) ![Codecov Foundry Coverage](https://img.shields.io/codecov/c/gh/bcnmy/sc-template?token=2BYDIFQ56W&flag=foundry&label=Foundry-coverage&logo=codecov)

# Smart Contract Template Base 🚀

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/bcnmy/sc-template)

This repository serves as a comprehensive foundation for smart contract projects, streamlining the development process with a focus on best practices, security, and efficiency.

## 📚 Table of Contents

- [🚀 Introduction](#smart-contract-template-base-)
- [🌟 Features](#features)
- [🏁 Getting Started](#getting-started)
- [🔧 Essential Scripts](#️-essential-scripts)
- [🔒 Security Audits](#-security-audits)
- [🏆 Biconomy Champions League](#-biconomy-champions-league-)
- [📖 Documentation and Resources](#documentation-and-resources)
- [📄 License](#license)
- [🤝 Connect with Biconomy](#connect-with-biconomy-)

## Features

- **Smart Contract Template Base**: A robust foundation for future smart contract projects.
- **Hardhat & Foundry Support**: Equipped with both Hardhat and Foundry tools and an adapted folder structure for seamless development.
- **Best Practices**: Adheres to industry best practices in smart contract programming to ensure code quality and security.
- **Continuous Integration & Deployment**: Utilizes GitHub Actions for automated testing and deployment, ensuring code reliability.
- **Strict Linting**: Implements Solhint based on the Solidity style guide, enhancing code quality and consistency.
- **Comprehensive Testing**: Includes a wide range of tests (unit, fuzz, fork) for both Foundry and Hardhat environments.
- **Environment Configuration**: Comes with `.env.example` for easy setup of API keys and environmental variables.
- **Code Formatting**: Uses Prettier to maintain a consistent code style across the project.
- **Configurations for Foundry & Hardhat**: Provides essential settings and scripts for building, testing, and deployment, tailored for both development environments.

## Getting Started

To kickstart your smart contract development with this template, follow these steps:

### Prerequisites

- Node.js (v18.x or later)
- Yarn (or npm)
- Foundry (Refer to [Foundry installation instructions](https://getfoundry.sh/docs/installation))

### Installation

1. **Clone the repository:**

```bash
git clone https://github.com/bcnmy/sc-template.git
cd sc-template
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

```bash
yarn deploy
```

Deploys contracts onto the blockchain network.

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

| Auditor   | Date       | Final Report Link       |
| --------- | ---------- | ----------------------- |
| Firm Name | DD-MM-YYYY | [View Report](./audits) |
| Firm Name | DD-MM-YYYY | [View Report](./audits) |
| Firm Name | DD-MM-YYYY | [View Report](./audits) |

## 🏆 Biconomy Champions League 🏆

Welcome to the Champions League, a place where your contributions to Biconomy are celebrated and immortalized in our Hall of Fame. This elite group showcases individuals who have significantly advanced our mission, from enhancing code efficiency to strengthening security, and enriching our documentation.

### Champions Roster

| 🍊 Contributor | 🛡️ Domain         |
| -------------- | ----------------- |
| @user1         | Code Optimization |
| @user2         | Security          |
| @user3         | Documentation     |
| ...            | ...               |

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
