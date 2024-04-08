// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import {Script, console} from "lib/forge-std/src/Script.sol";
import {GlobalManager} from "../src/GlobalManager.sol";

contract DeployGlobalManager is Script {
    address public portalAddress = address(0xb93b2c22d78e24Fc52Db2bDE3EF8bE659e3FE7a3); // Update to the actual portal address

    function run() external {
        vm.startBroadcast();

        GlobalManager globalManager = new GlobalManager(portalAddress);
        console.log("Deployed GlobalManager at:", address(globalManager));

        vm.stopBroadcast();
    }
}
