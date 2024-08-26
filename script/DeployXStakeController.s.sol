// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {XStakeController} from "src/XStaker.sol";
import {Script} from "forge-std/Script.sol";

contract DeployXStakeController is Script {
    function run(address owner, address portal) public {
        vm.startBroadcast();
        new XStakeController(portal, owner);
        vm.stopBroadcast();
    }
}
