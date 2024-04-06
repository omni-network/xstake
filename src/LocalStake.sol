// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {XApp} from "../lib/omni/contracts/src/pkg/XApp.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title LocalStake Contract
/// @notice A contract for staking tokens locally on a rollup chain
contract LocalStake is XApp {
    uint64 public globalChainId;
    address public globalManagerContract;
    IERC20 public localToken;

    constructor(
        address portal, 
        address _globalManagerContract,
        uint64 _globalChainId, // Chain ID for Omni Network (testnet: 165)
        address _localToken // Address of the ERC20 token used for staking
    ) XApp(portal) {
        globalManagerContract = _globalManagerContract;
        globalChainId = _globalChainId;
        localToken = IERC20(_localToken);
    }

    /// @notice Stake tokens
    /// @dev Requires the sender to attach a value for the xcall fee
    function stake(uint256 amount) external payable {
        require(amount > 0, "LocalStake: must stake more than 0");
        require(msg.value > 0, "LocalStake: attach value for xcall fee");

        // Transfer tokens from the user to this contract for staking
        require(localToken.transferFrom(msg.sender, address(this), amount), "LocalStake: transfer failed");

        // Calculate the xcall fees
        bytes memory data = abi.encodeWithSignature("addStake(address,uint256)", msg.sender,  amount);
        uint256 portalFee = feeFor(globalChainId, data);
        require(msg.value > portalFee, "LocalStake: insufficient value for xcall fee");

        xcall(globalChainId, globalManagerContract, data);
    }

    /// @notice Unstake tokens
    /// @param amount The amount of tokens to unstake
    function unstake(uint256 amount) external payable {
        require(msg.value > 0, "LocalStake: attach value for xcall fee");

        // Calculate the xcall fees
        bytes memory data = abi.encodeWithSignature("removeStake(address,uint256)", msg.sender,  amount);
        uint256 portalFee = feeFor(globalChainId, data) * 2; // Double the fee for the xunstake call, as xcall is used twice
        require(msg.value > portalFee, "LocalStake: insufficient value for xcall fee");

        xcall(globalChainId, globalManagerContract, data);
    }

    /// @notice Callback function for unstaking tokens
    /// @param user The address of the user to transfer the tokens to
    /// @param amount The amount of tokens to transfer
    function xunstake(address user, uint256 amount) external xrecv {
        require(isXCall(), "LocalStake: only xcall");
        require(xmsg.sourceChainId == globalChainId, "LocalStake: invalid source chain");
        require(xmsg.sender == globalManagerContract, "LocalStake: invalid sender");
        require(localToken.transfer(user, amount), "LocalStake: transfer failed");
    }
}
