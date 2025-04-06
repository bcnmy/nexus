# make via-ir true
export FOUNDRY_PROFILE="via-ir"

### USAGE : 

# different chain name and custom chain name in foundry toml
# > bash verify.sh <chain_name> <etherscan_api_key_name>

# same chain name and custom chain name in foundry toml
# > bash verify.sh <chain_name>

# accept chain name and etherscan api key name as arguments
CHAIN_NAME=$1
ETHERSCAN_API_KEY_NAME=$2

printf "Verifying contracts on chain $CHAIN_NAME\n"

#if #2 is not provided, set it equal to #1
if [ -z "$ETHERSCAN_API_KEY_NAME" ]; then
    ETHERSCAN_API_KEY_NAME=$CHAIN_NAME
fi

# verify contracts

# NEXUS
{   (forge verify-contract 0x000000004F43C49e93C970E84001853a70923B03 Nexus --watch --chain $CHAIN_NAME --etherscan-api-key $ETHERSCAN_API_KEY_NAME --constructor-args 0x0000000000000000000000000000000071727de22e5e9d8baf0edac6f37da03200000000000000000000000000000000d12897ddadc2044614a9677b191a2d9500000000000000000000000000000000000000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000014eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000 1> ./logs/$CHAIN_NAME/$CHAIN_NAME-verify.log 2> ./logs/$CHAIN_NAME/$CHAIN_NAME-verify-errors.log) \
        || \
    ((printf "====== ALERT ======\n :: NEXUS IMPLEMENTATION :: probably errors => check logs\n====== ALERT ======\n"))
}
printf "NEXUS IMPLEMENTATION processed\n"

# NEXUS BOOTSTRAP
# add to log, not replace it
{   (forge verify-contract 0x00000000fc7930C6F28401804b9606669A015Ff7 NexusBootstrap --watch --chain $CHAIN_NAME --etherscan-api-key $ETHERSCAN_API_KEY_NAME --constructor-args 0x00000000000000000000000000000000d12897ddadc2044614a9677b191a2d9500000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000014eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee000000000000000000000000 1>> ./logs/$CHAIN_NAME/$CHAIN_NAME-verify.log 2>> ./logs/$CHAIN_NAME/$CHAIN_NAME-verify-errors.log) \
        || \
    ((printf "====== ALERT ======\n :: NEXUS BOOTSTRAP :: probably errors => check logs\n====== ALERT ======\n"))
}

printf "NEXUS BOOTSTRAP processed\n"

# NEXUS ACCOUNT FACTORY
{   (forge verify-contract 0x000000001D1D5004a02bAfAb9de2D6CE5b7B13de NexusAccountFactory --watch --chain $CHAIN_NAME --etherscan-api-key $ETHERSCAN_API_KEY_NAME --constructor-args 0x000000000000000000000000000000004f43c49e93c970e84001853a70923b03000000000000000000000000129443ca2a9dec2020808a2868b38dda457eacc7 1>> ./logs/$CHAIN_NAME/$CHAIN_NAME-verify.log 2>> ./logs/$CHAIN_NAME/$CHAIN_NAME-verify-errors.log) \
        || \
    ((printf "====== ALERT ======\n :: NEXUS ACCOUNT FACTORY :: probably errors => check logs\n====== ALERT ======\n"))
}

printf "NEXUS ACCOUNT FACTORY processed\n"

printf "== Verification complete\n"
