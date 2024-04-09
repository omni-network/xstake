// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {LocalStake} from "../src/LocalStake.sol";

contract DeployLocalStake is Script {
    function run() external {
        address portalAddress = vm.envAddress("PORTAL_ADDRESS");
        address globalManagerContractAddress = vm.envAddress("GLOBAL_MANAGER_CONTRACT_ADDRESS");
        address localTokenAddress = vm.envAddress("LOCAL_TOKEN_ADDRESS");
        uint256 globalChainId256 = vm.envUint("GLOBAL_CHAIN_ID");
        require(globalManagerContractAddress != address(0), "Global Manager Contract address not provided");
        require(localTokenAddress != address(0), "Local Token address not provided");

        vm.startBroadcast();

        LocalStake localStake = new LocalStake(portalAddress, globalManagerContractAddress, uint64(globalChainId256), localTokenAddress);
        console.log("Deployed LocalStake at:", address(localStake));

        vm.stopBroadcast();
    }
}
