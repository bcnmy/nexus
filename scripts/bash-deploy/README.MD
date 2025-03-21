# Deploying Nexus contracts with a bash script
This script allows for seamless and automated deployment of Nexus contracts.

# Usage

## Clone the repository

```bash
git clone https://github.com/nexus-labs/nexus.git
git fetch --all
git checkout 'deploy-vx.x.x'
```

This script is using the pre-compiled artifacts from the `v.x.x.x` release tag.
To ensure consistent addresses accross chains, it is highly recommended to use the pre-compiled artifacts.
In this case you do not even need to install any dependencies.

If you still want to compile the contracts yourself, you can do so by running the following 

```bash
yarn
forge clean
forge build
```

Otherwise, just proceed with the following steps.

## Configure env variables

In order to deploy to a network, you need to set the correct env variables.

### .env
Copy env example file and set the correct values

```bash
cp .env.example .env
```
- Add private keys for local, testnet and mainnet environments.
- Add RPC URL's for the networks you want to deploy to.
- Add the correct block explorer API keys for the networks you want to deploy to.

Example: 
``` .env

# PRIVATE KEYS
export MAINNET_DEPLOYER_PRIVATE_KEY="0x..."
export TESTNET_DEPLOYER_PRIVATE_KEY="0x..."
export LOCAL_DEPLOYER_PRIVATE_KEY="0x..." #use some of the pre-funded anvil keys here

# SCROLL
export SCROLL_RPC_URL="https://scroll-rpc.publicnode.com"
export SCROLL_SEPOLIA_RPC_URL="https://scroll-sepolia-rpc.publicnode.com"

export SCROLLSCAN_API_KEY="ABCDEXYZ"

```

### foundry.toml

After that, you need to configure the foundry.toml file to use env variables.
- Configure `[rpc_endpoints]` section to use the correct RPC URL's.
- Configure `[etherscan]` section to use the correct API key.

Example:

```toml
[rpc_endpoints]
  scroll = "${SCROLL_RPC_URL}"
  scroll-sepolia = "${SCROLL_SEPOLIA_RPC_URL}"

[etherscan]
  scroll = { key = "${SCROLLSCAN_API_KEY}", url = "https://api.scrollscan.com/api" }
  scroll-sepolia = { key = "${SCROLLSCAN_API_KEY}", url = "https://api-sepolia.scrollscan.com/api" }
```

## Run the script

```bash
cd scripts/bash-deploy
bash deploy-nexus.sh <environment> <chain>
```

Where `<environment>` is the environment you want to deploy to and `<chain>` is the chain you want to deploy to.

`<environment>` possible values:
- `local`
- `testnet`
- `mainnet`

`<chain>` is any chain you configured.

If you choose `local` as environment, you do not need to specify `<chain>`, the script will deploy to the local anvil network. 
Do not forget to start the `anvil` network before running the script with local environment.

Environment influences which `PRIVATE_KEY` is used for the deployment.

Example:
```bash
bash deploy-nexus.sh testnet scroll-sepolia
```

## Interacting with the script

First, the script will check the network connection by requesting chainId.

```bash
$ bash deploy-nexus.sh local

Environment: local
Network: localhost
Chain ID: 31337
```

Then, it will check if the Create2 factory and Entry Point v0.7.0 has already been deployed at a proper address.
If they are not deployed, the script will deploy them.

```bash
Create2 factory has already been deployed
Entry point is not deployed, trying to deploy...
EP v0.7 deployed successfully
```
After that, the script will prompt you to decide if you want to use pre-compiled artifacts (recommended) or re-compile the contracts and use the locally compiled artifacts.

In any case, the next stage is pre-calculating the addresses for the Nexus smart contracts.
Script will display expected addresses for the contracts and check if they are already deployed.

```bash
Do you want to rebuild Nexus artifacts from your local sources? (y/n): n
Using precompiled artifacts
Addresses for Nexus SCs:
  Nexus Addr:  0x000000008761E87F023f65c49DC9cb1C7EdFEaaf  || >> Code Size:  0
  Nexus K1 Validator Addr:  0x0000002D6DB27c52E3C11c1Cf24072004AC75cBa  || >> Code Size:  0
  Nexus Bootstrap Addr:  0x000000F5b753Fdd20C5CA2D7c1210b3Ab1EA5903  || >> Code Size:  0
  K1ValidatorFactory Addr:  0x00000024115AA990F0bAE0B6b0D5B8F68b684cd6  || >> Code Size:  0
  Nexus Account Factory Addr:  0x000000226cada0d8b36034F5D5c06855F59F6F3A  || >> Code Size:  0
  =====> On this chain we have 0  contracts already deployed out of  5
```

Addresses depend on the bytecode that is about to be deployed and the salt.
Salts are pre-configured in the DeployNexus.s.sol script.
Those are salts used by Biconomy to deploy the contracts on most chains.
If you want different addresses, you can change the salts in the script.

```solidity
    // NEXUS CONTRACTS DEPLOYMENT SALTS
    bytes32 constant NEXUS_SALT = 0x0000000000000000000000000000000000000000f2bd6e8e0a8d8b01a83be4c5;
    bytes32 constant K1VALIDATOR_SALT = 0x000000000000000000000000000000000000000014fedeb9e1c61d030943b78e;
    bytes32 constant NEXUSBOOTSTRAP_SALT = 0x0000000000000000000000000000000000000000685bdf10d2a63f043e248cc0;
    bytes32 constant K1VALIDATORFACTORY_SALT = 0x0000000000000000000000000000000000000000d07e828a05cf8c02ef869155;
    bytes32 constant NEXUS_ACCOUNT_FACTORY_SALT = 0x0000000000000000000000000000000000000000a00deaddeb69f9031a251b40;
```

For the addresses that are already deployed, the script will skip the deployment stage.
For the rest of the contracts, the script will deploy and verify the smart contracts.

After you select `y` to proceed with the addresses above, the script will prompt you to decide if you want to configure gas prices.
- On most chains you can just type `n` to use the automatic gas price estimation by Foundry. However, on Ethereum mainnet it may be worth it to set the gas price manually.
- If you type `y`, the script will prompt you to set the gas prices.

```bash
Do you want to proceed with the addresses above? (y/n): y
Do you want to specify gas price? (y/n): y
Enter gas prices args: 
 For the EIP-1559 chains, enter two args: base fee and priority fee in gwei
 For the legacy chains, enter one argument. 
 Example eip-1559: 20 1 
 Example legacy: 20 

```

After you set the gas prices, the script will deploy and verify the contracts.

```bash
Enter gas prices args: 
 For the EIP-1559 chains, enter two args: base fee and priority fee in gwei
 For the legacy chains, enter one argument. 
 Example eip-1559: 20 1 
 Example legacy: 20 
1 1
Proceeding with deployment 
Deployment successful
  Nexus deployed at:  0x000000008761E87F023f65c49DC9cb1C7EdFEaaf
  Nexus K1 Validator deployed at:  0x0000002D6DB27c52E3C11c1Cf24072004AC75cBa
  Nexus Bootstrap deployed at:  0x000000F5b753Fdd20C5CA2D7c1210b3Ab1EA5903
  Nexus K1 Validator Factory deployed at:  0x00000024115AA990F0bAE0B6b0D5B8F68b684cd6
  Nexus Account Factory deployed at:  0x000000226cada0d8b36034F5D5c06855F59F6F3A
```

The deployment process may take a while, depending on how busy the network is.
The script won't display live logs, but you can check the live logs in the `logs/<chain>/<chain>-deploy-nexus.log` file and `logs/<chain>/<chain>-deploy-nexus-errors.log` file.
Run the script on localhost to see the live logs example.

# Further automation

If you want to achieve even higher degree of automation, you can use the wrapper over the `deploy-nexus.sh` script to deploy to multiple chains with one command.
To achieve this, you can automate inputs for the script prompts.
Example of such a wrapper script is below:

```bash
# TESTNETS
printf '%s\n' n y n | bash deploy-mee.sh testnet sepolia
printf '%s\n' n y n | bash deploy-mee.sh testnet base-sepolia
printf '%s\n' n y n | bash deploy-mee.sh testnet scroll-sepolia
printf '%s\n' n y n | bash deploy-mee.sh testnet arbitrum-sepolia
printf '%s\n' n y n | bash deploy-mee.sh testnet bsc-testnet
{ 
  (printf '%s\n' n y n | bash deploy-mee.sh testnet gnosis-chiado) 
} || { 
  (printf "Gnosis chiado :: probably errors => check logs\n") 
}
printf '%s\n' n y n | bash deploy-mee.sh testnet amoy
printf '%s\n' n y n | bash deploy-mee.sh testnet optimism-sepolia
{ 
  (printf '%s\n' n y n | bash deploy-mee.sh testnet berachain-bartio) 
} || { 
  (printf "Berachain bartio :: probably errors => check logs\n") 
}


# MAINNETS
printf '%s\n' n y n | bash deploy-mee.sh mainnet base
printf '%s\n' n y n | bash deploy-mee.sh mainnet scroll
printf '%s\n' n y n | bash deploy-mee.sh mainnet gnosis
printf '%s\n' n y n | bash deploy-mee.sh mainnet bsc
printf '%s\n' n y n | bash deploy-mee.sh mainnet arbitrum
printf '%s\n' n y n | bash deploy-mee.sh mainnet polygon
printf '%s\n' n y n | bash deploy-mee.sh mainnet optimism
```

This script will answer `n` , `y` and `n` to the prompts on every chain. 

# Troubleshooting

## Can not connect to the network provided

```bash
Chain ID: Can not connect to the network provided
Deployment prerequisites failed
```

This error means that the script can not connect to the network you provided.
Check if the RPC URL is correct and if you're using local environment, if the anvil network is running.

## Submit an issue.
Feel free to [submit an issue](https://github.com/bcnmy/nexus/issues/new/choose) if you can't find the solution here or you have any suggestions for the script.
