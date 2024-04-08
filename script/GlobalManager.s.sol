// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {GlobalManager} from "../src/GlobalManager.sol";

contract DeployGlobalManager is Script {

    function run() external {
        address portalAddress = vm.envAddress("PORTAL_ADDRESS");

        vm.startBroadcast();

        GlobalManager globalManager = new GlobalManager(portalAddress);
        console.log("Deployed GlobalManager at:", address(globalManager));

        vm.stopBroadcast();
    }
}
