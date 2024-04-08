// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script, console} from "../lib/forge-std/src/Script.sol";
import {LocalToken} from "../src/LocalToken.sol";

contract DeployLocalToken is Script {
    function run() external {
        vm.startBroadcast();

        LocalToken localToken = new LocalToken();
        console.log("Deployed LocalToken at:", address(localToken));

        vm.stopBroadcast();
    }
}
