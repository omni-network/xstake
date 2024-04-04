// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {XApp} from "../lib/omni/contracts/src/pkg/XApp.sol";

contract SimpleStake is XApp {
    uint64 public adminChainId = 1;
    address public adminContract;

    constructor(address portal, address _adminContract) XApp(portal) {
        adminContract = _adminContract;
    }

    function stake() external payable {
        require(msg.value > 0, "SimpleStake: attach value");
        uint256 fee = feeFor(adminChainId, abi.encodeWithSignature("addStake(address,uint256)", msg.sender,  msg.value));
        require(msg.value > fee, "SimpleStake: insufficient value for fee");
        xcall(adminChainId, adminContract, abi.encodeWithSignature("addStake(address,uint256)", msg.sender,  msg.value - fee - fee));
    }

    function unstake(uint256 amount) external {
        xcall(adminChainId, adminContract, abi.encodeWithSignature("removeStake(uint256,address)", amount, msg.sender));
    }

    function xunstake(address user, uint256 amount) external xrecv {
        require(isXCall(), "SimpleStake: only xcall");
        require(xmsg.sourceChainId == adminChainId, "SimpleStake: invalid source chain");
        require(xmsg.sender == adminContract, "SimpleStake: invalid sender");
        payable(user).transfer(amount);
    }
}
