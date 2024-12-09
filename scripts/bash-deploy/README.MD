# Deploying Nexus contracts with a bash script
This script allows for seamless and automated deployment of Nexus contracts.

# Usage

## Clone the repository

```bash
git clone https://github.com/nexus-labs/nexus.git
git fetch --all
git checkout 'release/nexus-1.0.1'
```

This script is using the pre-compiled artifacts from the `v.1.0.1` release tag.
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
bash deploy-nexus.sh testnet scroll
```

## Interacting with the script

First 


# Troubleshooting

Submit an issue
