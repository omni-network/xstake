#!/usr/bin/env bash

# !NOTE: Run from the root of the project
# gather env vars
source script/bash/env.sh

# Deployed contract addresses
export GLOBAL_MANAGER_CONTRACT_ADDRESS=0x0B306BF915C4d645ff596e518fAf3F9669b97016
export OP_LOCAL_TOKEN_ADDRESS=0x8A791620dd6260079BF849Dc5567aDC3F2FdC318
export OP_LOCAL_STAKE_ADDRESS=0x610178dA211FEF7D417bC0e6FeD39F05609AD788

# Approve the LocalStake contract to spend tokens
echo "\n"
echo "============================================================="
echo "Approve the LocalStake"
echo "============================================================="
cast send $OP_LOCAL_TOKEN_ADDRESS "approve(address,uint256)" $OP_LOCAL_STAKE_ADDRESS 1ether --private-key $PRIVATE_KEY --rpc-url $OP_RPC_URL
echo "============================================================="

# Add OP chain ID and stake contract address to the Global Manager contract
echo "\n"
echo "============================================================="
echo "Add OP Staking Contract to Global Manager"
echo "============================================================="
cast send $GLOBAL_MANAGER_CONTRACT_ADDRESS "addChainContract(uint64,address)" $OP_CHAIN_ID $OP_LOCAL_STAKE_ADDRESS --private-key $PRIVATE_KEY --rpc-url $OMNI_RPC_URL
echo "============================================================="

# Stake the tokens
echo "\n"
echo "============================================================="
echo "Stake Tokens"
echo "============================================================="
cast send $OP_LOCAL_STAKE_ADDRESS "stake(uint256)" 1ether --value 0.01ether --private-key $PRIVATE_KEY --rpc-url $OP_RPC_URL
echo "============================================================="

echo "\n"
echo "Querying Balances..."
# Check the ERC-20 balance of the LocalStake contract
TOKEN_BALANCE_HEX=$(cast call $OP_LOCAL_TOKEN_ADDRESS "balanceOf(address)" $OP_LOCAL_STAKE_ADDRESS --rpc-url $OP_RPC_URL)
TOKEN_BALANCE_DEC=$(cast to-dec $TOKEN_BALANCE_HEX)
TOKEN_BALANCE=$(cast to-unit $TOKEN_BALANCE_DEC ether)

sleep 5
# Query the total staked amount from the GlobalManager contract on Omni
TOTAL_STAKED_HEX=$(cast call $GLOBAL_MANAGER_CONTRACT_ADDRESS "totalStake()" --rpc-url $OMNI_RPC_URL)
TOTAL_STAKED_DEC=$(cast to-dec $TOTAL_STAKED_HEX)
TOTAL_STAKED=$(cast to-unit $TOTAL_STAKED_DEC ether)

echo "============================================================="
echo "Staking Summary"
echo "============================================================="
echo "SimpleStake Token Balance in Decimal:     $TOKEN_BALANCE"
echo "Omni Mgr Total Staked in Decimal:         $TOTAL_STAKED"
echo "============================================================="
