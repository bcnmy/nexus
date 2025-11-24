#!/bin/bash

# K1 Validator Multi-Chain Deployment Script
# This script deploys K1MeeValidator to multiple testnets/mainnets and tracks failures
#
# Usage:
#   bash nyn.sh                    # Deploy to all testnets (default)
#   bash nyn.sh testnets           # Deploy to all testnets
#   bash nyn.sh mainnets           # Deploy to all mainnets
#   bash nyn.sh sepolia base       # Deploy to specific chains

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Arrays to track results
SUCCESSFUL_CHAINS=()
FAILED_CHAINS=()
SKIPPED_CHAINS=()
VERIFICATION_FAILED_CHAINS=()  # Deployed successfully but verification failed

# Start time
START_TIME=$(date +%s)
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Determine environment (default: testnet)
ENVIRONMENT="testnet"
DEPLOY_MODE="testnets"

# Parse first argument to determine mode
if [ ! -z "$1" ]; then
    if [ "$1" = "mainnets" ]; then
        ENVIRONMENT="mainnet"
        DEPLOY_MODE="mainnets"
        shift # Remove first argument
    elif [ "$1" = "testnets" ]; then
        ENVIRONMENT="testnet"
        DEPLOY_MODE="testnets"
        shift # Remove first argument
    else
        # If first arg is not mainnets/testnets, treat all args as specific chains
        ENVIRONMENT="testnet"
        DEPLOY_MODE="custom"
    fi
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}K1 Validator Multi-Chain Deployment${NC}"
echo -e "${BLUE}Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}Started at: $(date)${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Create logs directory
mkdir -p ./logs/multi-deploy-$TIMESTAMP

# Function to deploy to a single chain
deploy_to_chain() {
    local chain=$1
    local env=$2
    local wrapper_log="./logs/multi-deploy-$TIMESTAMP/${chain}.log"
    local deploy_log="./logs/${chain}/${chain}-deploy-nexus.log"

    echo -e "\n${YELLOW}>>> Deploying to: $chain ($env)${NC}"
    echo ">>> Started at: $(date)" | tee -a ./logs/multi-deploy-$TIMESTAMP/summary.log

    # Run deployment (n = don't rebuild, y = proceed, n = no custom gas)
    if printf '%s\n' n y n | bash deploy-nexus.sh $env $chain >> $wrapper_log 2>&1; then
        # Script succeeded - deployment and verification both successful
        echo -e "${GREEN}✓ SUCCESS: $chain (deployed + verified)${NC}" | tee -a ./logs/multi-deploy-$TIMESTAMP/summary.log
        SUCCESSFUL_CHAINS+=("$chain")
        return 0
    else
        # Script failed - check if deployment was successful despite verification failure
        if [ -f "$deploy_log" ] && grep -q "ONCHAIN EXECUTION COMPLETE & SUCCESSFUL" $deploy_log; then
            # Deployment succeeded but verification failed
            echo -e "${YELLOW}✓ SUCCESS: $chain (deployed, verification failed)${NC}" | tee -a ./logs/multi-deploy-$TIMESTAMP/summary.log
            SUCCESSFUL_CHAINS+=("$chain")
            VERIFICATION_FAILED_CHAINS+=("$chain")
            return 0
        else
            # Deployment itself failed
            echo -e "${RED}✗ FAILED: $chain (deployment failed)${NC}" | tee -a ./logs/multi-deploy-$TIMESTAMP/summary.log
            FAILED_CHAINS+=("$chain")
            return 1
        fi
    fi
}

# List of all testnets from foundry.toml
TESTNETS=(
    # Ethereum testnets
    "sepolia"
    "base-sepolia"
    "amoy"
    "arbitrum-sepolia"
    "optimism-sepolia"
    "bsc-testnet"
    "sonic-blaze-testnet"
    "scroll-sepolia"
    "gnosis-chiado"
    "fuji"
    "apechain-testnet"
    "coredao-testnet"
    "neura-testnet"
    "sei-testnet"
    "unichain-testnet"
    "worldchain-testnet"
    "fluent-testnet"
    "monad-testnet"
    "plasma-testnet"
    "sophon-zk-testnet"
    "arc-testnet"
)

# List of all mainnets from foundry.toml
MAINNETS=(
    "mainnet"
    "base"
    "polygon"
    "arbitrum"
    "optimism"
    "bsc"
    "sonic-mainnet"
    "scroll"
    "gnosis"
    "avalanche"
    "apechain"
    "hyperevm"
    "sei-mainnet"
    "unichain-mainnet"
    "katana-mainnet"
    "lisk-mainnet"
    "worldchain-mainnet"
    "monad-mainnet"
    "plasma-mainnet"
)

# Select which chains to deploy based on mode
CHAINS_TO_DEPLOY=()

if [ "$DEPLOY_MODE" = "mainnets" ]; then
    CHAINS_TO_DEPLOY=("${MAINNETS[@]}")
    echo -e "${YELLOW}Deploying to ALL MAINNETS${NC}"
    echo -e "${RED}WARNING: You are about to deploy to production networks!${NC}"
    echo -e "${RED}Press Ctrl+C within 10 seconds to cancel...${NC}\n"
    sleep 10
elif [ "$DEPLOY_MODE" = "testnets" ]; then
    CHAINS_TO_DEPLOY=("${TESTNETS[@]}")
    echo -e "${YELLOW}Deploying to all testnets${NC}\n"
elif [ "$DEPLOY_MODE" = "custom" ]; then
    CHAINS_TO_DEPLOY=("$@")
    echo -e "${YELLOW}Deploying to specific chains: $@${NC}\n"
fi

# Deploy to all selected chains
for chain in "${CHAINS_TO_DEPLOY[@]}"; do
    deploy_to_chain "$chain" "$ENVIRONMENT"
    # Small delay between deployments
    sleep 2
done

# Calculate duration
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# Print summary
SUCCESS_COUNT=${#SUCCESSFUL_CHAINS[@]}
FAILED_COUNT=${#FAILED_CHAINS[@]}
SKIPPED_COUNT=${#SKIPPED_CHAINS[@]}
VERIFICATION_FAILED_COUNT=${#VERIFICATION_FAILED_CHAINS[@]}

echo -e "\n${BLUE}========================================${NC}"
echo -e "${BLUE}DEPLOYMENT SUMMARY${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "Total duration: ${MINUTES}m ${SECONDS}s"
echo -e "Completed at: $(date)\n"

echo -e "${GREEN}Successful deployments ($SUCCESS_COUNT):${NC}"
if [ $SUCCESS_COUNT -eq 0 ]; then
    echo "  None"
else
    for chain in "${SUCCESSFUL_CHAINS[@]}"; do
        # Check if this chain had verification failure
        if [[ " ${VERIFICATION_FAILED_CHAINS[@]} " =~ " ${chain} " ]]; then
            echo -e "  ${GREEN}✓${NC} $chain ${YELLOW}(verification failed)${NC}"
        else
            echo -e "  ${GREEN}✓${NC} $chain ${GREEN}(fully verified)${NC}"
        fi
    done
fi

echo -e "\n${RED}Failed deployments ($FAILED_COUNT):${NC}"
if [ $FAILED_COUNT -eq 0 ]; then
    echo "  None"
else
    for chain in "${FAILED_CHAINS[@]}"; do
        echo -e "  ${RED}✗${NC} $chain"
    done
fi

if [ $SKIPPED_COUNT -gt 0 ]; then
    echo -e "\n${YELLOW}Skipped deployments ($SKIPPED_COUNT):${NC}"
    for chain in "${SKIPPED_CHAINS[@]}"; do
        echo -e "  ${YELLOW}⊘${NC} $chain"
    done
fi

if [ $VERIFICATION_FAILED_COUNT -gt 0 ]; then
    echo -e "\n${YELLOW}Chains with verification failures ($VERIFICATION_FAILED_COUNT):${NC}"
    echo -e "${YELLOW}Note: Contracts deployed successfully but verification failed${NC}"
    for chain in "${VERIFICATION_FAILED_CHAINS[@]}"; do
        echo -e "  ${YELLOW}⚠${NC} $chain"
    done
fi

echo -e "\n${BLUE}Logs saved to: ./logs/multi-deploy-$TIMESTAMP/${NC}"
echo -e "${BLUE}Summary log: ./logs/multi-deploy-$TIMESTAMP/summary.log${NC}"

# Exit with error code if any deployments failed
if [ $FAILED_COUNT -gt 0 ]; then
    echo -e "\n${RED}⚠ Some deployments failed. Check logs for details.${NC}"
    exit 1
else
    echo -e "\n${GREEN}✓ All deployments completed successfully!${NC}"
    exit 0
fi