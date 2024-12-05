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
printf "Do you want to rebuild Nexus artifacts from your local sources? \n (y/n): "
read -r proceed
if [ $proceed = "y" ]; then
    ### BUILD ARTIFACTS ###
    printf "Building Nexus artifacts\n"
    { (forge build 1> ./logs/forge-build.log 2> ./logs/forge-build-errors.log) } || {
        printf "Build failed\n See logs for more details\n"
        exit 1
    }
    printf "Copying Nexus artifacts\n"
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
    printf "Proceeding with deployment\n"
    {
        forge script DeployNexus false --sig "run(bool)" --rpc-url $CHAIN_NAME --chain $CHAIN_NAME --etherscan-api-key $CHAIN_NAME --private-key $PRIVATE_KEY $VERIFY -v --broadcast --slow 1> ./logs/deploy-nexus.log 2> ./logs/deploy-nexus-errors.log 
    } || {
        printf "Deployment failed\n See logs for more details\n"
        exit 1
    }
    printf "Deployment successful\n"
    cat ./logs/deploy-nexus.log | grep "deployed at"
    
else 
    printf "Exiting\n"
    exit 1
fi  