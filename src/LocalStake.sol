// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {XApp} from "../lib/omni/contracts/src/pkg/XApp.sol";

/// @title LocalStake Contract
/// @notice A contract for staking tokens locally on a rollup chain
contract LocalStake is XApp {
    uint64 public globalChainId = 165; // testnet Omni Network chain id
    address public globalManagerContract;

    constructor(address portal, address _globalManagerContract) XApp(portal) {
        globalManagerContract = _globalManagerContract;
    }

    /// @notice Stake tokens
    /// @dev Requires the sender to attach a value for the xcall fee
    function stake() external payable {
        require(msg.value > 0, "LocalStake: attach value for xcall fee");
        uint256 portalFee = feeFor(globalChainId, abi.encodeWithSignature("addStake(address,uint256)", msg.sender,  msg.value));
        uint256 totalPortalFee = portalFee + portalFee; // two xcalls: one in this chain and one in the global chain
        require(msg.value > totalPortalFee, "LocalStake: insufficient value for xcall fee");
        xcall(globalChainId, globalManagerContract, abi.encodeWithSignature("addStake(address,uint256)", msg.sender,  msg.value - totalPortalFee));
    }

    /// @notice Unstake tokens
    /// @param amount The amount of tokens to unstake
    function unstake(uint256 amount) external {
        address user = msg.sender;
        xcall(globalChainId, globalManagerContract, abi.encodeWithSignature("removeStake(uint256,address)", amount, user));
    }

    /// @notice Callback function for unstaking tokens
    /// @param user The address of the user to transfer the tokens to
    /// @param amount The amount of tokens to transfer
    function xunstake(address user, uint256 amount) external xrecv {
        require(isXCall(), "LocalStake: only xcall");
        require(xmsg.sourceChainId == globalChainId, "LocalStake: invalid source chain");
        require(xmsg.sender == globalManagerContract, "LocalStake: invalid sender");
        payable(user).transfer(amount);
    }
}
