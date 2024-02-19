import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-storage-layout";
import "@bonadocs/docgen";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000000,
        details: {
          yul: true,
        },
      },
    },
  },
  docgen: {
    projectName: "Biconomy Modular Smart Account",
    projectDescription: "ERC-7579 Modular Smart Account",
  },
};

export default config;
