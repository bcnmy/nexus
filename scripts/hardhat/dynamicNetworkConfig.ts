import { NetworksUserConfig } from "hardhat/types";
import * as dotenv from "dotenv";
dotenv.config();

const url = process.env.HH_RPC_URL!;
const chainName = process.env.HH_CHAIN_NAME!;
const chainId = parseInt(process.env.HH_CHAIN_ID!);

export const dynamicNetworkConfig = (): NetworksUserConfig | undefined => { 
    if ([url, chainName, chainId].every(Boolean)) {
        return {
            [chainName]: {
                allowUnlimitedContractSize: true,
                url,
                chainId,
            }
        }
    }
}