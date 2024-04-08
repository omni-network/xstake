// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {LocalStake} from "../src/LocalStake.sol";

contract DeployLocalStake is Script {
    address public portalAddress = address(0xbeef); // Update to the actual portal address
    uint64 public globalChainId = 165; // Example chain ID for Omni Network (testnet)

    function run() external {
        // Retrieve the Global Manager Contract address from an environment variable
        address globalManagerContractAddress = vm.envAddress("GLOBAL_MANAGER_CONTRACT_ADDRESS");
        address localTokenAddress = vm.envAddress("LOCAL_TOKEN_ADDRESS");
        require(globalManagerContractAddress != address(0), "Global Manager Contract address not provided");
        require(localTokenAddress != address(0), "Local Token address not provided");

        vm.startBroadcast();

        LocalStake localStake = new LocalStake(portalAddress, globalManagerContractAddress, globalChainId, localTokenAddress);
        console.log("Deployed LocalStake at:", address(localStake));

        vm.stopBroadcast();
    }
}
