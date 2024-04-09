#!/usr/bin/env bash

# !NOTE: Run from the root of the project
# gather env vars
source script/env.sh

# Deployed contract addresses
export GLOBAL_MANAGER_CONTRACT_ADDRESS=0xc6e7DF5E7b4f2A278906862b61205850344D4e7d
export OP_LOCAL_TOKEN_ADDRESS=0x84eA74d481Ee0A5332c457a4d796187F6Ba67fEB
export OP_LOCAL_STAKE_ADDRESS=0x9E545E3C0baAB3E08CdfD552C960A1050f373042

# Approve the LocalStake contract to spend tokens
cast send $OP_LOCAL_TOKEN_ADDRESS "approve(address,uint256)" $OP_LOCAL_STAKE_ADDRESS 100 --private-key $PRIVATE_KEY --rpc-url $OP_RPC_URL

# Add OP chain ID and stake contract address to the Global Manager contract
cast send $GLOBAL_MANAGER_CONTRACT_ADDRESS "addChainContract(uint64,address)" $OP_CHAIN_ID $OP_LOCAL_STAKE_ADDRESS --private-key $PRIVATE_KEY --rpc-url $OMNI_RPC_URL

# Stake the tokens
cast send $OP_LOCAL_STAKE_ADDRESS "stake(uint256)" 100 --value 0.01ether --private-key $PRIVATE_KEY --rpc-url $OP_RPC_URL

# Check the ERC-20 balance of the LocalStake contract
TOKEN_BALANCE_HEX=$(cast call $OP_LOCAL_TOKEN_ADDRESS "balanceOf(address)" $OP_LOCAL_STAKE_ADDRESS --rpc-url $OP_RPC_URL)

# Query the total staked amount from the GlobalManager contract on Omni
TOTAL_STAKED_HEX=$(cast call $GLOBAL_MANAGER_CONTRACT_ADDRESS "getTotalStake()" --rpc-url $OMNI_RPC_URL)

echo "\n"
echo "============================================================="
echo "Staking Summary"
echo "============================================================="
TOKEN_BALANCE_DEC=$(echo $((16#${TOKEN_BALANCE_HEX#0x})))
echo "SimpleStake Token Balance in Decimal:     $TOKEN_BALANCE_DEC"
TOTAL_STAKED_DEC=$(echo $((16#${TOTAL_STAKED_HEX#0x})))
echo "Omni Mgr Total Staked in Decimal:         $TOTAL_STAKED_DEC"
echo "============================================================="
