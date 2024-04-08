#!/usr/bin/env bash

# Compile all contracts
forge build

# RPC env vars
export OMNI_RPC_URL=http://localhost:8000
export OP_RPC_URL=http://localhost:8002
export ARB_RPC_URL=http://localhost:8003

# Omni Deployment
echo "\n"
echo "============================================================="
echo "Deploying Omni contracts to $OMNI_RPC_URL"
echo "============================================================="

# Deploy GlobalManager and capture its address
export GLOBAL_MANAGER_CONTRACT_ADDRESS=$(forge script DeployGlobalManager --broadcast --rpc-url $OMNI_RPC_URL --private-key $PRIVATE_KEY | grep "Contract Address:" | awk '{ print $3 }')

# Optimism Deployment
echo "============================================================="
echo "Deploying Optimism contracts to $OP_RPC_URL"
echo "============================================================="

# Deploy LocalToken and capture its address
export LOCAL_TOKEN_ADDRESS=$(forge script DeployLocalToken --broadcast --rpc-url $OP_RPC_URL --private-key $PRIVATE_KEY | grep "Contract Address:" | awk '{ print $3 }')
export OP_LOCAL_TOKEN_ADDRESS=$LOCAL_TOKEN_ADDRESS

# Deploy LocalStake using the environment variables for addresses
export LOCAL_STAKE_ADDRESS=$(forge script DeployLocalStake --broadcast --rpc-url $OP_RPC_URL --private-key $PRIVATE_KEY | grep "Contract Address:" | awk '{ print $3 }')
export OP_LOCAL_STAKE_ADDRESS=$LOCAL_STAKE_ADDRESS

# Arbitrum Deployment
echo "============================================================="
echo "Deploying Arbitrum contracts to $ARB_RPC_URL"
echo "============================================================="

# Deploy LocalToken and capture its address
export LOCAL_TOKEN_ADDRESS=$(forge script DeployLocalToken --broadcast --rpc-url $ARB_RPC_URL --private-key $PRIVATE_KEY | grep "Contract Address:" | awk '{ print $3 }')
export ARB_LOCAL_TOKEN_ADDRESS=$LOCAL_TOKEN_ADDRESS

# Deploy LocalStake using the environment variables for addresses
export LOCAL_STAKE_ADDRESS=$(forge script DeployLocalStake --broadcast --rpc-url $ARB_RPC_URL --private-key $PRIVATE_KEY | grep "Contract Address:" | awk '{ print $3 }')
export ARB_LOCAL_STAKE_ADDRESS=$LOCAL_STAKE_ADDRESS
echo "============================================================="
echo "\n"


# Output all contract addresses
echo "============================================================="
echo "Deployment Summary"
echo "============================================================="
echo "Omni GlobalManager: $GLOBAL_MANAGER_CONTRACT_ADDRESS"
echo "OP LocalToken: $OP_LOCAL_TOKEN_ADDRESS"
echo "OP LocalStake: $OP_LOCAL_STAKE_ADDRESS"
echo "ARB LocalToken: $ARB_LOCAL_TOKEN_ADDRESS"
echo "ARB LocalStake: $ARB_LOCAL_STAKE_ADDRESS"
echo "============================================================="
