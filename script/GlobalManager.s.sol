// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {GlobalManager} from "../src/GlobalManager.sol";

contract DeployGlobalManager is Script {
    address public portalAddress = address(0x123); // Update to the actual portal address

    function run() external {
        vm.startBroadcast();

        GlobalManager globalManager = new GlobalManager(portalAddress);
        console.log("Deployed GlobalManager at:", address(globalManager));

        vm.stopBroadcast();
    }
}
