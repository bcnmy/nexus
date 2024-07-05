import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-storage-layout";
import "hardhat-deploy";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.26",
    settings: {
      viaIR: true,
      optimizer: {
        enabled: true,
        runs: 1000000,
        details: {
          yul: true,
        },
      },
    },
  },
  networks: {
    /*
    baseSepolia: {
      url: process.env.BASE_SEPOLIA_URL || "https://sepolia.base.org/",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 84532,
    },
    */
  },
  etherscan: {
    apiKey: {
      baseSepolia: process.env.BASE_SEPOLIA_API_KEY || "",
    }
  },
  docgen: {
    projectName: "Nexus",
    projectDescription: "Nexus - Biconomy Modular Smart Account - ERC-7579",
  },
};

export default config;
