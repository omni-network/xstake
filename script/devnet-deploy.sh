#!/usr/bin/env bash
#
# Deploy contracts to Omni's devnet

set -e

# Private key for dev account 8, funded on devnet chains
deployer=0x23618e81E3f5cdF7f54C3d65f7FBc0aBf5B21E8f
deployer_pk=0xdbda1821b80551c9d65939329250298aa3472ba22feea921c0cf5d620ea67b97

# Private key for dev account 9, funded on devnet chains
owner=0xa0Ee7A142d267C1f36714E4a8F75612F20a79720
owner_pk=0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6

# Devnet info - portal address is same for all chains
devnet=$(omni devnet info)
portal=$(echo $devnet | jq -r '.[] | select(.chain_name == "omni_evm") | .portal_address')

# Get RPC URLs for each chain
rpcurl() {
  local chain=$1
  echo $(echo $devnet | jq -r ".[] | select(.chain_name == \"$chain\") | .rpc_url")
}

op_rpc=$(rpcurl mock_op)
arb_rpc=$(rpcurl mock_arb)
omni_rpc=$(rpcurl omni_evm)


# Get address of next contract to be deployed by deployer
getaddr() {
  local rpc=$1
  local prefix="Computed Address: " # Need to remove prefix from cast output
  echo $(cast compute-address $deployer --rpc-url $rpc | sed -e "s/^$prefix//")
}

# Deploys TestToken, return address
deploy_token() {
  local rpc=$1
  local token=$(getaddr $rpc)

  forge script DeployTestToken \
    --silent \
    --broadcast \
    --rpc-url $rpc \
    --private-key $deployer_pk

  if [ $? -ne 0 ]; then { exit 1; } fi

  echo $token
}

# Deploy XStaker, return address
deploy_xstaker() {
  local rpc=$1
  local controller=$2
  local token=$3

  # deploy xstaker
  local xstaker=$(getaddr $rpc)

  forge script DeployXStaker \
    --silent \
    --broadcast \
    --rpc-url $rpc \
    --private-key $deployer_pk \
    --sig $(cast calldata "run(address,address,address)" $portal $controller $token)

  if [ $? -ne 0 ]; then { exit 1; } fi

  echo $xstaker
}

# Deploy XStakeController, return address
deploy_controller() {
  local rpc=$1
  local controller=$(getaddr $rpc)

  forge script DeployXStakeController \
    --silent \
    --broadcast \
    --rpc-url $rpc \
    --private-key $deployer_pk \
    --sig $(cast calldata "run(address,address)" $owner $portal)

  if [ $? -ne 0 ]; then { exit 1; } fi

  echo $controller
}

# Register XStaker with controller
register_xstaker() {
  local rpc=$1
  local controller=$2
  local chain_id=$3
  local xstaker=$4

  forge script RegisterXStaker \
    --broadcast \
    --rpc-url $rpc \
    --private-key $owner_pk \
    --sig $(cast calldata "run(address,uint64,address)" $controller $chain_id $xstaker)
}


# Deploy tokens
op_token=$(deploy_token $op_rpc)
arb_token=$(deploy_token $arb_rpc)

# Deploy controller
controller=$(deploy_controller $omni_rpc)

# Deploy xstakers
op_xstaker=$(deploy_xstaker $op_rpc $controller $op_token)
arb_xstaker=$(deploy_xstaker $arb_rpc $controller $arb_token)

# Register xstakers
register_xstaker $omni_rpc $controller $(cast chain-id --rpc-url $op_rpc) $op_xstaker
register_xstaker $omni_rpc $controller $(cast chain-id --rpc-url $arb_rpc) $arb_xstaker

echo "Token(op): $op_token"
echo "Token(arb): $arb_token"
echo "XStaker(op): $op_xstaker"
echo "XStaker(arb): $arb_xstaker"
echo "XStakeController(omni): $controller"

echo "
OP_TOKEN=$op_token
ARB_TOKEN=$arb_token
OP_XSTAKER=$op_xstaker
ARB_XSTAKER=$arb_xstaker
CONTROLLER=$controller
OMNI_RPC=$omni_rpc
OP_RPC=$op_rpc
ARB_RPC=$arb_rpc
OP_CHAINID=$(cast chain-id --rpc-url $op_rpc)
ARB_CHAINID=$(cast chain-id --rpc-url $arb_rpc)
OMNI_CHAINID=$(cast chain-id --rpc-url $omni_rpc)
" > deployments.sh
