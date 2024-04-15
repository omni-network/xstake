// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {GlobalManager} from "../src/GlobalManager.sol";

/// @title Deployment script for GlobalManager contract
/// @notice This script deploys the GlobalManager contract using Forge's script tooling
contract DeployGlobalManager is Script {
    /// @dev Main function that executes the deployment
    function run() external {
        // Fetch the portal address from environment variables; the portal is used for cross-chain interactions
        address portalAddress = vm.envAddress("PORTAL_ADDRESS");

        vm.startBroadcast();  // Start broadcasting transactions to the network

        // Create a new instance of the GlobalManager contract
        GlobalManager globalManager = new GlobalManager(portalAddress);
        // Log the deployment address to the console
        console.log("Deployed GlobalManager at:", address(globalManager));

        vm.stopBroadcast();  // Stop broadcasting transactions
    }
}
