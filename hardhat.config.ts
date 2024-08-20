import * as dotenv from "dotenv";
import type { HardhatUserConfig } from "hardhat/config";
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
		hardhat: {
			allowUnlimitedContractSize: true,
		},
		localhost: {
			allowUnlimitedContractSize: true,
			url: "http://localhost:61128", // Must be a valid rpcUrl for the network you want to deploy to
			chainId: 31337,
			accounts: {
				mnemonic: "test test test test test test test test test test test junk",
				initialIndex: 0,
			},
		},
	},
	docgen: {
		projectName: "Nexus",
		projectDescription: "Nexus - Biconomy Modular Smart Account - ERC-7579",
	},
};

export default config;
