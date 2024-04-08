// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import {XApp} from "../lib/omni/contracts/src/pkg/XApp.sol";

/// @title GlobalManager contract
/// @dev Manages global operations and interactions with other contracts
/// @notice Deployed on Omni
contract GlobalManager is XApp {
    address public owner;
    mapping(uint64 => address) public chainIdToContract;
    mapping(address => mapping(uint64 => uint256)) public userToChainIdToStake;
    mapping(uint64 => uint256) public chainIdToTotalStake;
    uint256 public totalStake;

    constructor(address portal) XApp(portal) {
        owner = msg.sender;
    }

    /// @dev Adds a chain contract to the mapping
    /// @param chainId The ID of the chain
    /// @param contractAddress The address of the contract
    function addChainContract(uint64 chainId, address contractAddress) external {
        require(msg.sender == owner, "GlobalManager: only owner");
        chainIdToContract[chainId] = contractAddress;
    }

    /// @dev Adds stake for a user on a specific chain
    /// @param user The address of the user
    /// @param amount The amount of stake to add
    function addStake(address user, uint256 amount) external xrecv {
        require(isXCall(), "GlobalManager: only xcall");
        require(isExistingChainId(xmsg.sourceChainId), "GlobalManager: chain not found");
        require(xmsg.sender == chainIdToContract[xmsg.sourceChainId], "GlobalManager: invalid sender");
        
        userToChainIdToStake[user][xmsg.sourceChainId] += amount;
        chainIdToTotalStake[xmsg.sourceChainId] += amount;
        totalStake += amount;
    }

    /// @dev Removes stake for a user on a specific chain
    /// @param user The address of the user
    /// @param amount The amount of stake to remove
    function removeStake(address user, uint256 amount) external xrecv {
        require(isXCall(), "GlobalManager: only xcall");
        require(isExistingChainId(xmsg.sourceChainId), "GlobalManager: chain not found");
        require(xmsg.sender == chainIdToContract[xmsg.sourceChainId], "GlobalManager: invalid sender");
        require(userToChainIdToStake[user][xmsg.sourceChainId] >= amount, "GlobalManager: insufficient stake");

        bytes memory data = abi.encodeWithSignature("xunstake(address,uint256)", user, amount);
        uint256 fee = feeFor(xmsg.sourceChainId, data);
        require(address(this).balance >= fee, "GlobalManager: insufficient fee");

        userToChainIdToStake[user][xmsg.sourceChainId] -= amount;
        chainIdToTotalStake[xmsg.sourceChainId] -= amount;
        totalStake -= amount;

        xcall(xmsg.sourceChainId, xmsg.sender, data);
    }

    function getUserStakeOnChain(address user, uint64 chainId) external view returns (uint256) {
        return userToChainIdToStake[user][chainId];
    }

    function getTotalStakeOnChain(uint64 chainId) external view returns (uint256) {
        return chainIdToTotalStake[chainId];
    }

    function getTotalStake() external view returns (uint256) {
        return totalStake;
    }

    function isExistingChainId(uint64 chainId) internal view returns (bool) {
        return chainIdToContract[chainId] != address(0);
    }
}
