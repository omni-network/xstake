// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {Script, console} from "forge-std/Script.sol";
import {XGreeter} from "../src/XGreeter.sol";

contract DeployXGreeter is Script {
    address public portalAddress = address(0x123); // Update to the actual portal address

    function run() external {
        vm.startBroadcast();

        XGreeter xGreeter = new XGreeter(portalAddress);
        console.log("Deployed XGreeter at:", address(xGreeter));

        vm.stopBroadcast();
    }
}
