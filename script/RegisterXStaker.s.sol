// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {XStakeController} from "src/XStaker.sol";
import {Script} from "forge-std/Script.sol";

contract RegisterXStaker is Script {
    function run(address controller, uint64 onChainID, address xstaker)  public {
        vm.startBroadcast();
        XStakeController(controller).registerXStaker(onChainID, xstaker);
        vm.stopBroadcast();
    }
}
