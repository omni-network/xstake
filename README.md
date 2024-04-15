# Omni Advanced Cross-Rollup Staking Example

![Omni Unites Rollups](banner.png)

This repository contains an advanced example of a cross-chain dApp for staking tokens across multiple rollup networks. It showcases the use of an Omni contract for global state of cross-rollup staking operations and includes a frontend for user interactions.

## Repository Structure

```
|
├── frontend # Frontend React application for the dApp
│ ├── README.md # README for the frontend directory
│ ├── package.json # NPM package configuration
│ ├── public # Public assets and HTML template
│ ├── src # Source code for the React application
│ └── tsconfig.json # TypeScript configuration
├── lib # Libraries and dependencies
│ ├── forge-std # Standard library for Foundry
│ ├── omni # Omni protocol libraries
│ └── openzeppelin-contracts # OpenZeppelin smart contract libraries
├── script # Deployment and utility scripts
│ ├── *.s.sol # Solidity contract deployment scripts
│ └── bash # Bash scripts for deployment and dapp setup
├── src # Solidity contracts source
│ ├── GlobalManager.sol
│ ├── LocalStake.sol
│ └── LocalToken.sol
├── test # Tests for contracts
| ├── GlobalManager.t.sol
| └── LocalStake.t.sol
└── foundry.toml # Foundry build and test configuration
└── ...
```

## Contract Interaction

```
┌──────────────────────┐                     ┌──────────────────────┐
│                      │                     │                      │
│       Optimism       │                     │       Arbitrum       │
│                      │                     │                      │
│                      │                     │                      │
│     LocalToken.sol   ├───────┐      ┌──────┤    LocalToken.sol    │
│     LocalStake.sol   │       │      │      │    LocalStake.sol    │
│                      │       │      │      │                      │
│                      │       │      │      │                      │
│                      │       │      │      │                      │
└──────────▲───────────┘   (1) │      │ (1)  └───────────▲──────────┘
           │                   │      │                  │           
           │                   │      │                  │           
           │                   │      │                  │           
           │                   │      │                  │           
           │          ┌────────▼──────▼──────┐           │           
           │          │                      │           │           
           │          │       Omni EVM       │           │           
           │          │                      │           │           
           │          │                      │           │           
           └──────────┤   GlobalManager.sol  ├───────────┘           
                (2)   │                      │    (2)                
                      │                      │                       
                      │                      │                       
                      │                      │                       
                      └──────────────────────┘                       
```

Networks `Arbitrum` and `Optimism` post updates to the `GlobalManager` contract deployed on Omni (1). `GlobalManager` aggregates the state for both networks and is responsible for delegating actions dependent on this global state.

In the contract implementations in `src/`, `GlobalManager` verifies its global state before delegating an `unstake` operation to any of the deployed `LocalStake` contracts in whichever network.

:warning: **Note:** `GlobalManager` requires knowing what addresses have the deployed staking contract and their network to perform validity checks on state before delegating actions.

## Contract Deployment

Because `GlobalManager` requires knowledge of staking contract addresses and networks to perform verification checks it should be deployed first. The ERC20 and staking contracts follow. The deployment script in `script/bash/deploy.sh` performs this sequence for deployment, namely: 

1. Deploys the `GlobalManager` contract to the Omni EVM
2. Deploys the `LocalToken` contract and `LocalStake` to the first rollup (`Optimism` in this case)
3. Deploys the `LocalToken` contract and `LocalStake` to the second rollup (`Arbitrum` in this case)
4. Prints deployment addresses for all five contracts

To run this deployment, configure `script/bash/env.sh` first and then run:

```bash
sh script/bash/setup.sh
```

This will deploy the contracts according to the configured environment and add the deployed addresses of the staking contracts to the `GlobalManager` contract (by running `chain.sh`).

## Run the App Locally

### Run Networks and Omni Locally

To run the app locally make sure you have a running version of `devnet`. To run `devnet`:

1. First clone `https://github.com/omni-network/omni`
2. then run `make build-docker`
3. then run `make devnet-deploy`

### Contracts Setup

Having run this, you can find the address for the Portal contracts by running:

```bash
cat e2e/runs/devnet1/validator01/config/network.json
```

Add this Portal contract address to `script/bash/env.sh`.

You will need a `PRIVATE_KEY` environment variable for running the scripts too, we can use the [`anvil`](https://book.getfoundry.sh/reference/anvil/) rich keys:

```bash
export PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

Now you can run:

```
sh script/bash/setup.sh
```

The contract addresses will be shown on your terminal output.

### Frontend Setup

Ensure the addresses shown before match those seen in `frontend/src/constants/networks.ts`. 

Then change directories into `frontend/` and run:

```bash
yarn && yarn start
```

Use the previously used anvil rich key to sign into metamask and interact with the app :)
