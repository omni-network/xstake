// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {TestToken} from "test/utils/TestToken.sol";
import {Script} from "forge-std/Script.sol";

contract DeployTestToken is Script {
    function run() public {
        vm.startBroadcast();
        new TestToken();
        vm.stopBroadcast();
    }
}
