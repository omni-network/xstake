// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {XApp} from "../lib/omni/contracts/src/pkg/XApp.sol";

contract LocalStake is XApp {
    uint64 public globalChainId = 165; // testnet Omni Network chain id
    address public globalManagerContract;

    constructor(address portal, address _globalManagerContract) XApp(portal) {
        globalManagerContract = _globalManagerContract;
    }

    function stake() external payable {
        require(msg.value > 0, "LocalStake: attach value for xcall fee");
        address user = msg.sender;
        uint256 amountStakeSent = msg.value;
        uint256 portalFee = feeFor(globalChainId, abi.encodeWithSignature("addStake(address,uint256)", user,  amountStakeSent));
        uint256 totalPortalFee = portalFee + portalFee; // two xcalls: one in this chain and one in the global chain
        require(msg.value > totalPortalFee, "LocalStake: insufficient value for xcall fee");
        xcall(globalChainId, globalManagerContract, abi.encodeWithSignature("addStake(address,uint256)", user,  amountStakeSent - totalPortalFee));
    }

    function unstake(uint256 amount) external {
        address user = msg.sender;
        xcall(globalChainId, globalManagerContract, abi.encodeWithSignature("removeStake(uint256,address)", amount, user));
    }

    function xunstake(address user, uint256 amount) external xrecv {
        require(isXCall(), "LocalStake: only xcall");
        require(xmsg.sourceChainId == globalChainId, "LocalStake: invalid source chain");
        require(xmsg.sender == globalManagerContract, "LocalStake: invalid sender");
        payable(user).transfer(amount);
    }
}
