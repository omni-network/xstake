#!/usr/bin/env bash

# Compile all contracts
forge build

# Deploy GlobalManager and capture its address
GLOBAL_MANAGER_CONTRACT_ADDRESS=$(forge script DeployGlobalManager --broadcast --rpc-url $OMNI_RPC_URL --private-key $PRIVATE_KEY --json | jq -r ".receipts[0].contractAddress")
echo "GlobalManager deployed at: $GLOBAL_MANAGER_CONTRACT_ADDRESS"

# Deploy LocalToken and capture its address
LOCAL_TOKEN_ADDRESS=$(forge script DeployLocalToken --broadcast --rpc-url $OP_RPC_URL --private-key $PRIVATE_KEY --json | jq -r ".receipts[0].contractAddress")
echo "OP LocalToken deployed at: $LOCAL_TOKEN_ADDRESS"

export OP_LOCAL_TOKEN_ADDRESS=$LOCAL_TOKEN_ADDRESS

# Deploy LocalStake using the environment variables for addresses
LOCAL_STAKE_ADDRESS=$(forge script DeployLocalStake --broadcast --rpc-url $OP_RPC_URL --private-key $PRIVATE_KEY --json | jq -r ".receipts[0].contractAddress")
echo "OP LocalStake deployed at: $LOCAL_STAKE_ADDRESS"

export OP_LOCAL_STAKE_ADDRESS=$LOCAL_STAKE_ADDRESS

# Deploy LocalToken and capture its address
LOCAL_TOKEN_ADDRESS=$(forge script DeployLocalToken --broadcast --rpc-url $ARB_RPC_URL --private-key $PRIVATE_KEY --json | jq -r ".receipts[0].contractAddress")
echo "ARB LocalToken deployed at: $LOCAL_TOKEN_ADDRESS"

export ARB_LOCAL_TOKEN_ADDRESS=$LOCAL_TOKEN_ADDRESS

# Deploy LocalStake using the environment variables for addresses
LOCAL_STAKE_ADDRESS=$(forge script DeployLocalStake --broadcast --rpc-url $ARB_RPC_URL --private-key $PRIVATE_KEY --json | jq -r ".receipts[0].contractAddress")
echo "ARB LocalStake deployed at: $LOCAL_STAKE_ADDRESS"

export ARB_LOCAL_STAKE_ADDRESS=$LOCAL_STAKE_ADDRESS

# Output all contract addresses
echo "Deployment Summary:"
echo "Omni GlobalManager: $GLOBAL_MANAGER_ADDRESS"
echo "OP LocalToken: $OP_LOCAL_TOKEN_ADDRESS"
echo "OP LocalStake: $OP_LOCAL_STAKE_ADDRESS"
echo "ARB LocalToken: $ARB_LOCAL_TOKEN_ADDRESS"
echo "ARB LocalStake: $ARB_LOCAL_STAKE_ADDRESS"
