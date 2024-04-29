// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {LocalStake} from "../src/LocalStake.sol";

/// @title Deployment script for LocalStake contract
/// @notice This script deploys the LocalStake contract using Forge's script tooling
contract DeployLocalStake is Script {
    /// @dev Main function that executes the deployment
    function run() external {
        // Fetch environment variables required for deployment
        address portalAddress = vm.envAddress("PORTAL_ADDRESS"); // Portal address for cross-chain operations
        address globalManagerContractAddress = vm.envAddress("GLOBAL_MANAGER_CONTRACT_ADDRESS"); // Address of the GlobalManager contract
        address localTokenAddress = vm.envAddress("LOCAL_TOKEN_ADDRESS"); // Address of the LocalToken used for staking
        uint256 globalChainId256 = vm.envUint("GLOBAL_CHAIN_ID"); // Global chain ID where the contract will operate

        // Ensure that required addresses are not zero to avoid errors in deployment
        require(globalManagerContractAddress != address(0), "Global Manager Contract address not provided");
        require(localTokenAddress != address(0), "Local Token address not provided");

        vm.startBroadcast(); // Start broadcasting transactions to the network

        // Deploy the LocalStake contract with provided addresses and chain ID
        LocalStake localStake =
            new LocalStake(portalAddress, globalManagerContractAddress, uint64(globalChainId256), localTokenAddress);
        // Log the deployment address to the console
        console.log("Deployed LocalStake at:", address(localStake));

        vm.stopBroadcast(); // Stop broadcasting transactions
    }
}
