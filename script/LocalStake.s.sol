// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {LocalStake} from "../src/LocalStake.sol";

contract DeployLocalStake is Script {
    address public portalAddress = address(0xb93b2c22d78e24Fc52Db2bDE3EF8bE659e3FE7a3); // Update to the actual portal address
    uint64 public globalChainId = 16561; // Example chain ID for Omni Network (testnet)

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
