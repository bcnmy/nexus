import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-foundry";
import "hardhat-storage-layout";
import "hardhat-deploy";

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
				runs: 999,
				details: {
					yul: true,
				},
			},
			evmVersion: "cancun",
		},
	},
	networks: {
		hardhat: {
			allowUnlimitedContractSize: true,
		},
	},
};

export default config;
