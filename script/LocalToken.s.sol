// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {LocalToken} from "../src/LocalToken.sol";

/// @title Deployment script for LocalToken contract
/// @notice This script deploys the LocalToken contract using Forge's script tooling
contract DeployLocalToken is Script {
    /// @dev Main function that executes the deployment
    function run() external {
        vm.startBroadcast(); // Start broadcasting transactions to the network

        // Creates a new instance of LocalToken
        LocalToken localToken = new LocalToken();
        // Log the deployment address to the console
        console.log("Deployed LocalToken at:", address(localToken));

        vm.stopBroadcast(); // Stop broadcasting transactions
    }
}
