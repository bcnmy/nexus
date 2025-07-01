

#!/bin/bash

### VERIFY INPUTS ###
printMan() {
    printf "Usage: $0 <Environment: local|mainnet|testnet> <Network Name>\n"
    printf "Supported networks: avalanche, ethereum, polygon, arbitrum, base\n"
}

if [ $# -eq 0 ]; then
    printf "Please provide private key, environment and network name\n"
    printMan
    exit 1
fi

if [ -z $1 ]; then
    printf "Please provide environment\n"
    printMan
    exit 1
fi

ENVIRONMENT=$1
VERIFY=""

if [ $ENVIRONMENT = "local" ]; then
    CHAIN_NAME="localhost"
else 
    if [ $ENVIRONMENT = "mainnet" ] || [ $ENVIRONMENT = "testnet" ]; then
        if [ -z $2 ]; then
            printf "Please provide network name\n"
            printMan
            exit 1
        fi
        CHAIN_NAME=$2
        VERIFY="--verify"
    else 
        printf "Invalid environment\n"
        printMan
        exit 1
    fi
fi

# Load environment variables from .env (for EP_V07_DEPLOY_TX_DATA and other variables)
source ../../.env

# Load private key from OnePassword for all environments
PRIVATE_KEY=$(op read op://uppkq2linnagjo7zxcclzjvrvm/V2_Deployer/credential)

# Define chain configurations - Load RPC URLs directly from OnePassword
setup_chain_config() {
    case $CHAIN_NAME in
        "avalanche")
            CHAIN_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/AVALANCHE_RPC_URL/credential)
            ;;
        "ethereum")
            CHAIN_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ETHEREUM_RPC_URL/credential)
            ;;
        "polygon")
            CHAIN_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/POLYGON_RPC_URL/credential)
            ;;
        "arbitrum")
            CHAIN_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/ARBITRUM_RPC_URL/credential)
            ;;
        "base")
            CHAIN_RPC_URL=$(op read op://5ylebqljbh3x6zomdxi3qd7tsa/BASE_RPC_URL/credential)
            ;;
        *)
            printf "Unsupported chain: $CHAIN_NAME\n"
            printf "Supported chains: avalanche, ethereum, polygon, arbitrum, base\n"
            exit 1
            ;;
    esac
}

# Set up chain configuration
setup_chain_config

### DEPLOY PRE-REQUISITES ###
{ (bash deploy-prerequisites.sh $PRIVATE_KEY $ENVIRONMENT $CHAIN_NAME $CHAIN_RPC_URL) } || {
    printf "Deployment prerequisites failed\n"
    exit 1
}

### COPY ARTIFACTS ###
read -r -p "Do you want to rebuild Nexus artifacts from your local sources? (y/n): " proceed
if [ $proceed = "y" ]; then
    ### BUILD ARTIFACTS ###
    printf "Building Nexus artifacts\n"
    { (forge build 1> ./logs/forge-build.log 2> ./logs/forge-build-errors.log) } || {
        printf "Build failed\n See logs for more details\n"
        exit 1
    }
    printf "Copying Nexus artifacts\n"
    mkdir -p ./artifacts/Nexus
    mkdir -p ./artifacts/K1Validator
    mkdir -p ./artifacts/NexusBootstrap
    mkdir -p ./artifacts/K1ValidatorFactory
    mkdir -p ./artifacts/NexusAccountFactory
    mkdir -p ./artifacts/NexusProxy

    cp ../../out/Nexus.sol/Nexus.json ./artifacts/Nexus/.
    cp ../../out/K1Validator.sol/K1Validator.json ./artifacts/K1Validator/.
    cp ../../out/NexusBootstrap.sol/NexusBootstrap.json ./artifacts/NexusBootstrap/.
    cp ../../out/K1ValidatorFactory.sol/K1ValidatorFactory.json ./artifacts/K1ValidatorFactory/.
    cp ../../out/NexusAccountFactory.sol/NexusAccountFactory.json ./artifacts/NexusAccountFactory/.
    cp ../../out/NexusProxy.sol/NexusProxy.json ./artifacts/NexusProxy/.

    printf "Artifacts copied\n"

    ### CREATE VERIFICATION ARTIFACTS ###
    printf "Creating verification artifacts\n"
    
    forge verify-contract --show-standard-json-input $(cast address-zero) Nexus > ./artifacts/Nexus/verify.json
    forge verify-contract --show-standard-json-input $(cast address-zero) K1Validator > ./artifacts/K1Validator/verify.json
    forge verify-contract --show-standard-json-input $(cast address-zero) NexusBootstrap > ./artifacts/NexusBootstrap/verify.json
    forge verify-contract --show-standard-json-input $(cast address-zero) K1ValidatorFactory > ./artifacts/K1ValidatorFactory/verify.json
    forge verify-contract --show-standard-json-input $(cast address-zero) NexusAccountFactory > ./artifacts/NexusAccountFactory/verify.json
    forge verify-contract --show-standard-json-input $(cast address-zero) NexusProxy > ./artifacts/NexusProxy/verify.json


else 
    printf "Using precompiled artifacts\n"
fi

### DEPLOY NEXUS SCs ###
printf "Addresses for Nexus SCs:\n"
forge script DeployNexus true --sig "run(bool)" --rpc-url $CHAIN_RPC_URL -vv | grep -e "Addr" -e "already deployed"
printf "Do you want to proceed with the addresses above? (y/n): "
read -r proceed
if [ $proceed = "y" ]; then
    printf "Do you want to specify gas price? (y/n): "
    read -r proceed
    if [ $proceed = "y" ]; then
        printf "Enter gas prices args: \n For the EIP-1559 chains, enter two args: base fee and priority fee in gwei\n For the legacy chains, enter one argument. \n Example eip-1559: 20 1 \n Example legacy: 20 \n"
        read -r -a GAS_ARGS
        if [ ${#GAS_ARGS[@]} -eq 2 ]; then
            GAS_SUFFIX="--with-gas-price ${GAS_ARGS[0]}gwei --priority-gas-price ${GAS_ARGS[1]}gwei"
        else 
            GAS_SUFFIX="--legacy --with-gas-price ${GAS_ARGS[0]}gwei"
        fi
    else 
        GAS_SUFFIX=""
    fi
    {   
        printf "Proceeding with deployment \n"
        mkdir -p ./logs/$CHAIN_NAME
        forge script DeployNexus false --sig "run(bool)" --rpc-url $CHAIN_RPC_URL --etherscan-api-key $CHAIN_NAME --private-key $PRIVATE_KEY $VERIFY -vv --broadcast --slow $GAS_SUFFIX 1> ./logs/$CHAIN_NAME/$CHAIN_NAME-deploy-nexus.log 2> ./logs/$CHAIN_NAME/$CHAIN_NAME-deploy-nexus-errors.log 
    } || {
        printf "Deployment failed\n See logs for more details\n"
        exit 1
    }
    printf "Deployment successful\n"
    cat ./logs/$CHAIN_NAME/$CHAIN_NAME-deploy-nexus.log | grep "deployed at"
    
else 
    printf "Exiting\n"
    exit 1
fi  







