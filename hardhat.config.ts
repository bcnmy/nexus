import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-storage-layout";
import "hardhat-deploy";
import { dynamicNetworkConfig } from "./scripts/hardhat/dynamicNetworkConfig";

dotenv.config();

const SHOULD_ENABLE_VIA_IR: Boolean = process.env.SHOULD_ENABLE_VIA_IR
  ? process.env.SHOULD_ENABLE_VIA_IR === "true"
  : true;

const config: HardhatUserConfig = {
	solidity: {
		version: "0.8.27",
		settings: {
			viaIR: SHOULD_ENABLE_VIA_IR,
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
		baseSepolia: {
            url: "https://sepolia.base.org/",
            accounts: [process.env.PRIVATE_KEY ? process.env.PRIVATE_KEY : "73ed0ec4066c265e5582135248178562d5689811dbf3c1b44d3cec1a9bf6ae56"], // random pk
            chainId: 84532,
            allowUnlimitedContractSize: true,
        },
		...dynamicNetworkConfig(),
	},
	docgen: {
		projectName: "Nexus",
		projectDescription: "Nexus - Biconomy Modular Smart Account - ERC-7579",
	},
};

export default config;
