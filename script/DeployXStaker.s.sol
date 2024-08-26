// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {XStaker} from "src/XStaker.sol";
import {Script} from "forge-std/Script.sol";

contract DeployXStaker is Script {
    function run(address portal, address controller, address token) public {
        vm.startBroadcast();
        new XStaker(portal, controller, token);
        vm.stopBroadcast();
    }
}
