#!/usr/bin/env bash

# Function to execute the cast command and check the status
send_transaction() {
  # Execute the cast command, capturing stdout and stderr
  output=$(cast send "$@" 2>&1)
  # Check the exit status of the cast command
  if [ $? -eq 0 ]; then
    echo "  ✔ Transaction successfull."
  else
    echo "  ❌ Transaction failed. Error: $output"
  fi
}

# Adding chains and contracts to the Global Manager contract
echo "\n"
echo "============================================================="
echo "Adding chains and contracts to the Global Manager contract"
echo "============================================================="
echo "Adding Optimism chain and contract to the Global Manager contract"
# Pass all arguments to the send_transaction function
send_transaction $GLOBAL_MANAGER_CONTRACT_ADDRESS "addChainContract(uint64,address)" $OP_CHAIN_ID $OP_LOCAL_STAKE_ADDRESS --private-key $PRIVATE_KEY --rpc-url $OMNI_RPC_URL
echo "Adding Arbitrum chain and contract to the Global Manager contract"
# Pass all arguments to the send_transaction function
send_transaction $GLOBAL_MANAGER_CONTRACT_ADDRESS "addChainContract(uint64,address)" $ARB_CHAIN_ID $ARB_LOCAL_STAKE_ADDRESS --private-key $PRIVATE_KEY --rpc-url $OMNI_RPC_URL
echo "============================================================="
