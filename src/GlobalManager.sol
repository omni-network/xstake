// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import {XApp} from "../lib/omni/contracts/src/pkg/XApp.sol";

/// @title GlobalManager contract
/// @dev Manages global operations and interactions with other contracts
/// @notice Deployed on Omni
contract GlobalManager is XApp {
    address public owner;  // Owner of the contract
    mapping(uint64 => address) public chainIdToContract;  // Maps chain IDs to contract addresses
    mapping(address => mapping(uint64 => uint256)) public userToChainIdToStake;  // Maps user addresses and chain IDs to stake amounts
    uint256 public totalStake;  // Total staked amount across all chains

    /// @notice Initializes the contract with the portal address and sets the owner
    constructor(address portal) XApp(portal) {
        owner = msg.sender;
    }

    /// @dev Adds a contract address for a specific chain ID
    /// @param chainId The ID of the chain where the contract is deployed
    /// @param contractAddress The address of the contract to be mapped
    function addChainContract(uint64 chainId, address contractAddress) external {
        require(msg.sender == owner, "GlobalManager: only owner");  // Ensures that only the owner can add contracts
        chainIdToContract[chainId] = contractAddress;
    }

    /// @dev Adds stake for a user on a specific chain
    /// @param user The address of the user adding the stake
    /// @param amount The amount of stake to add
    /// @notice This function is designed to be called via cross-chain calls
    function addStake(address user, uint256 amount) external xrecv {
        require(isXCall(), "GlobalManager: only xcall");  // Ensures function is called via cross-chain communication
        require(isExistingChainId(xmsg.sourceChainId), "GlobalManager: chain not found");  // Checks if the chain ID is valid
        require(xmsg.sender == chainIdToContract[xmsg.sourceChainId], "GlobalManager: invalid sender");  // Validates the sender

        userToChainIdToStake[user][xmsg.sourceChainId] += amount;  // Adds the stake to the user's total on the specified chain
        totalStake += amount;  // Updates the total stake across all chains
    }

    /// @dev Removes stake for a user on a specific chain
    /// @param user The address of the user removing the stake
    /// @param amount The amount of stake to remove
    /// @notice Initiates an xcall to execute a stake removal operation
    function removeStake(address user, uint256 amount) external xrecv {
        require(isXCall(), "GlobalManager: only xcall");  // Ensures function is called via cross-chain communication
        require(isExistingChainId(xmsg.sourceChainId), "GlobalManager: chain not found");  // Checks if the chain ID is valid
        require(xmsg.sender == chainIdToContract[xmsg.sourceChainId], "GlobalManager: invalid sender");  // Validates the sender
        require(userToChainIdToStake[user][xmsg.sourceChainId] >= amount, "GlobalManager: insufficient stake");  // Checks if the user has enough stake

        bytes memory data = abi.encodeWithSignature("xunstake(address,uint256)", user, amount);  // Prepares the data for the unstake call
        uint256 fee = feeFor(xmsg.sourceChainId, data);  // Calculates the fee for the cross-chain call
        require(address(this).balance >= fee, "GlobalManager: insufficient fee");  // Ensures there are enough funds to cover the fee

        userToChainIdToStake[user][xmsg.sourceChainId] -= amount;  // Deducts the stake from the user's total
        totalStake -= amount;  // Updates the total stake

        xcall(xmsg.sourceChainId, xmsg.sender, data);  // Makes the cross-chain call to remove the stake
    }

    /// @notice Retrieves the stake amount for a user on a specific chain
    /// @param user The user's address
    /// @param chainId The chain ID to query
    /// @return The amount of stake for the user on the specified chain
    function getUserStakeOnChain(address user, uint64 chainId) external view returns (uint256) {
        return userToChainIdToStake[user][chainId];
    }

    /// @notice Returns the total stake across all chains
    /// @return The total staked amount
    function getTotalStake() external view returns (uint256) {
        return totalStake;
    }

    /// @dev Checks if a chain ID has an associated contract address
    /// @param chainId The chain ID to check
    /// @return True if there is a contract address associated with the chain ID
    function isExistingChainId(uint64 chainId) internal view returns (bool) {
        return chainIdToContract[chainId] != address(0);
    }
}
