#!/bin/bash

## Checks and deploys if not deployed:
# - Deterministic deployer (Create2 Factory) https://github.com/Arachnid/deterministic-deployment-proxy
# - Entry Point v0.7 https://github.com/eth-infinitism/account-abstraction/releases/tag/v0.7.0

printMan() {
    printf "Usage: $0 <Private Key> <Environment: local|mainnet|testnet> <Network Name>\n"
}

# Check if a contract name is provided
if [ $# -eq 0 ]; then
    printf "Please provide private key, environment and network name\n"
    printMan
    exit 1
fi

# Check if the private key is provided
if [ -z $1 ]; then
    printf "Please provide private key\n"
    printMan
    exit 1
fi

# Check if the environment is provided
if [ -z $2 ]; then
    printf "Please provide environment\n"
    printMan
    exit 1
fi

source ../../.env

PRIVATE_KEY=$1
ENVIRONMENT=$2
CHAIN_NAME=$3

#print environment
printf "Environment: $ENVIRONMENT\n"

# local environment
if [ $ENVIRONMENT == "local" ]; then
    CHAIN_NAME="localhost"
    { # try
        printf "Network: $CHAIN_NAME\n"
        printf "Chain ID: "
        #echo is all good, otherwise hide error msg
        cast chain-id --rpc-url $CHAIN_NAME 2> /dev/null
    } || { # catch
        printf "Can not connect to the network provided\n"
        exit 64
    }
else 
    # mainnet or testnet environment
    if [ $ENVIRONMENT = "mainnet" ] || [ $ENVIRONMENT = "testnet" ]; then
        # check if network name is provided correctly
        if [ -z $CHAIN_NAME ]; then
            # empty network name
            printf "Please provide a network name (should be configured in foundry.toml)\n"
            printMan
            exit 1
        else 
            #try to connect to the RPC
            { # try
                printf "Network: $CHAIN_NAME\n"
                printf "Chain ID: "
                #echo is all good, otherwise hide error msg
                cast chain-id --rpc-url $CHAIN_NAME # 2> /dev/null
            } || { # catch
                printf "Can not connect to the network provided\n"
                exit 64
            }
        fi
    # invalid environment argument
    else
        printf "Invalid environment\n"
        exit 64
    fi
fi

### Create2 Factory ###

CREATE2_FACTORY_SIZE=$(cast codesize --rpc-url $CHAIN_NAME 0x4e59b44847b379578588920ca78fbf26c0b4956c)
#printf "CREATE2 FACTORY Codesize: $CREATE2_FACTORY_SIZE\n"

if [ $CREATE2_FACTORY_SIZE -eq 0 ]; then
    printf "Create2 factory is not deployed, trying to deploy...\n"
    printf "Funding deployer...\n"
    cast send 0x3fAB184622Dc19b6109349B94811493BF2a45362 --rpc-url $CHAIN_NAME --private-key $PRIVATE_KEY --value 0.007ether | grep 'status'
    printf "Deploying Create2 factory...\n"
    cast publish --rpc-url $CHAIN_NAME 0xf8a58085174876e800830186a08080b853604580600e600039806000f350fe7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffe03601600081602082378035828234f58015156039578182fd5b8082525050506014600cf31ba02222222222222222222222222222222222222222222222222222222222222222a02222222222222222222222222222222222222222222222222222222222222222 > /dev/null
    CREATE2_FACTORY_SIZE=$(cast codesize --rpc-url $CHAIN_NAME 0x4e59b44847b379578588920ca78fbf26c0b4956c)
    if [ $CREATE2_FACTORY_SIZE -eq 69 ]; then
        printf "Create2 factory deployed successfully\n"
    else
        printf "Create2 factory deployment failed\n"
        exit 64
    fi
else
    printf "Create2 factory has already been deployed\n"
fi

### Entry Point ###

EP_V07_SIZE=$(cast codesize --rpc-url $CHAIN_NAME 0x0000000071727De22E5E9d8BAf0edAc6f37da032)
#printf "EP Codesize: $EP_V07_SIZE\n"

if [ $EP_V07_SIZE -eq 0 ]; then
    printf "Entry point is not deployed, trying to deploy...\n"
    cast send --rpc-url $CHAIN_NAME 0x4e59b44847b379578588920ca78fbf26c0b4956c --private-key $PRIVATE_KEY $EP_V07_DEPLOY_TX_DATA > /dev/null
    EP_V07_SIZE=$(cast codesize --rpc-url $CHAIN_NAME 0x0000000071727De22E5E9d8BAf0edAc6f37da032)
    if [ $EP_V07_SIZE -eq 0 ]; then
        printf "EP v0.7 deployment failed\n"
        exit 64 
    else
        printf "EP v0.7 deployed successfully\n"
    fi
else 
    printf "Entry point has already been deployed\n"
fi
