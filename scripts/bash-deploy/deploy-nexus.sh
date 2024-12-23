#!/bin/bash

### VERIFY INPUTS ###
printMan() {
    printf "Usage: $0 <Environment: local|mainnet|testnet> <Network Name>\n"
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
        if [ $CHAIN_NAME = "vechain" || $CHAIN_NAME = "vechain-testnet" ]; then
            VERIFY="--verify --verifier sourcify"
        fi
    else 
        printf "Invalid environment\n"
        printMan
        exit 1
    fi
fi

source ../../.env

# set private key based on the environment
if [ $ENVIRONMENT = "mainnet" ]; then
    PRIVATE_KEY=$MAINNET_DEPLOYER_PRIVATE_KEY
else 
    if [ $ENVIRONMENT = "testnet" ]; then
        PRIVATE_KEY=$TESTNET_DEPLOYER_PRIVATE_KEY
    else 
        PRIVATE_KEY=$LOCAL_DEPLOYER_PRIVATE_KEY
    fi
fi

### DEPLOY PRE-REQUISITES ###
{ (bash deploy-prerequisites.sh $PRIVATE_KEY $ENVIRONMENT $CHAIN_NAME) } || {
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
    cp ../../out/Nexus.sol/Nexus.json ./artifacts/Nexus/.
    cp ../../out/K1Validator.sol/K1Validator.json ./artifacts/K1Validator/.
    cp ../../out/NexusBootstrap.sol/NexusBootstrap.json ./artifacts/NexusBootstrap/.
    cp ../../out/K1ValidatorFactory.sol/K1ValidatorFactory.json ./artifacts/K1ValidatorFactory/.
    cp ../../out/NexusAccountFactory.sol/NexusAccountFactory.json ./artifacts/NexusAccountFactory/.
    printf "Artifacts copied\n"

    ### CREATE VERIFICATION ARTIFACTS ###
    printf "Creating verification artifacts\n"
    
    forge verify-contract --show-standard-json-input $(cast address-zero) Nexus > ./artifacts/Nexus/verify.json
    forge verify-contract --show-standard-json-input $(cast address-zero) K1Validator > ./artifacts/K1Validator/verify.json
    forge verify-contract --show-standard-json-input $(cast address-zero) NexusBootstrap > ./artifacts/NexusBootstrap/verify.json
    forge verify-contract --show-standard-json-input $(cast address-zero) K1ValidatorFactory > ./artifacts/K1ValidatorFactory/verify.json
    forge verify-contract --show-standard-json-input $(cast address-zero) NexusAccountFactory > ./artifacts/NexusAccountFactory/verify.json
    
else 
    printf "Using precompiled artifacts\n"
fi

### DEPLOY NEXUS SCs ###
printf "Addresses for Nexus SCs:\n"
forge script DeployNexus true --sig "run(bool)" --rpc-url $CHAIN_NAME -vv | grep -e "Addr" -e "already deployed"
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
            GAS_SUFFIX="--with-gas-price ${GAS_ARGS[0]}gwei"
        fi
    else 
        GAS_SUFFIX=""
    fi
    {   
        printf "Proceeding with deployment \n"
        mkdir -p ./logs/$CHAIN_NAME
        forge script DeployNexus false --sig "run(bool)" --rpc-url $CHAIN_NAME --etherscan-api-key $CHAIN_NAME --private-key $PRIVATE_KEY $VERIFY -vv --broadcast --slow $GAS_SUFFIX 1> ./logs/$CHAIN_NAME/$CHAIN_NAME-deploy-nexus.log 2> ./logs/$CHAIN_NAME/$CHAIN_NAME-deploy-nexus-errors.log 
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