#!/usr/bin/env bash

# !NOTE: Run from the root of the project
# gather env vars
source script/bash/env.sh

# Deployed contract addresses
source script/bash/deploy.sh

# Add chains and contracts to the Global Manager contract
source script/bash/chain.sh
