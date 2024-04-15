# Cross-Rollup Staking Example Frontend

This project is the frontend for a decentralized application (dApp) that allows users to stake tokens for rewards, governance, and yield across multiple rollup networks. The dApp is built with React and leverages Ethereum smart contracts through Ethers.js.

## Overview

The frontend is a user interface that interacts with the `LocalStake`, `GlobalManager`, and `LocalToken` smart contracts to enable staking on the Omni network. Users can connect their Ethereum wallets, switch networks, and manage their stakes.

![Omni Staking Interface](./path-to-image/image.png)

*Replace the above path with the actual path to the image within your project if needed.*

## Features

- **Wallet Connection**: Allows users to connect their MetaMask wallet to interact with the dApp.
- **Network Switching**: Users can switch between different rollup networks.
- **Stake Management**: Users can stake and view their current and total stakes on the network.
- **Responsive Stats Display**: Real-time display of staking statistics, including user-specific and global stakes.

# Project Structure

```
├── README.md
├── package.json
├── public
│   ├── favicon.svg
│   ├── index.html
│   ├── logo.svg
│   ├── manifest.json
│   └── robots.txt
├── src
│   ├── App.css
│   ├── App.tsx
│   ├── abis
│   │   ├── GlobalManager.json
│   │   ├── LocalStake.json
│   │   └── LocalToken.json
│   ├── components
│   │   ├── LoadingModal
│   │   │   ├── LoadingModal.css
│   │   │   └── LoadingModal.tsx
│   │   ├── Navbar
│   │   │   ├── Navbar.css
│   │   │   └── Navbar.tsx
│   │   ├── StakeInput
│   │   │   ├── StakeInput.css
│   │   │   └── StakeInput.tsx
│   │   └── StakingStats
│   │       ├── StakingStats.css
│   │       └── StakingStats.tsx
│   ├── constants
│   │   └── networks.ts
│   └── index.tsx
├── tsconfig.json
└── yarn.lock
```

## Getting Started

To run this project locally, follow these steps:

1. Clone the repository:

    ```sh
    git clone https://your-repository-url
    ```

2. Change directory to the repo and install packages with: 

    ```sh
    yarn install
    ```

3. Start the development server:

    ```sh
    yarn start
    ```

## Components

- `Navbar`: The navigation bar allows the user to connect their wallet and switch networks.
- `StakeInput`: A component that allows users to input the amount of tokens they wish to stake.
- `StakingStats`: Displays the staking statistics such as total stakes on the network and the user's stakes.
- `LoadingModal`: A modal that appears during transaction processing.

## Smart Contract ABIs

The ABIs for the `LocalStake`, `GlobalManager`, and `LocalToken` contracts are located in the src/abis/ directory.

## Constants

The src/constants/ directory contains the `networks.ts` file, which holds the configuration for different networks and contract addresses.

## Environment Variables

Ensure you have the following environment variables set:

`REACT_APP_PORTAL_ADDRESS`: Address of the Portal for cross-chain operations.
`REACT_APP_GLOBAL_MANAGER_CONTRACT_ADDRESS`: Address of the `GlobalManager` contract.
`REACT_APP_LOCAL_TOKEN_ADDRESS`: Address of the `LocalToken` contract.
`REACT_APP_GLOBAL_CHAIN_ID`: The global chain ID for the Omni network.
