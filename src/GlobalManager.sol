// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import {XApp} from "../lib/omni/contracts/src/pkg/XApp.sol";

/**
 * @title GlobalManager contract
 * @notice Manages global operations and interactions with other contracts
 * @dev Deployed on Omni
 */
contract GlobalManager is XApp {
    /**
     * @notice Owner of the contract
     * @dev State variable to store the owner's address
     */
    address public owner;

    /**
     * @notice Maps chain IDs to contract addresses
     * @dev State mapping of chain IDs to addresses for cross-chain interactions
     */
    mapping(uint64 => address) public contractOn;

    /**
     * @notice Maps user addresses and chain IDs to stake amounts
     * @dev Nested mapping to store stake amounts for each user across different chains
     */
    mapping(address => mapping(uint64 => uint256)) public stakeOn;

    /**
     * @notice Total staked amount across all chains
     * @dev State variable to track the cumulative staking across all chains
     */
    uint256 public totalStake;

    /**
     * @dev Initializes the contract with the specified portal address and sets the owner
     * @param portal The portal address used for initialization
     */
    constructor(address portal) XApp(portal) {
        owner = msg.sender;
    }

    /**
     * @notice Adds a contract address for a specific chain ID
     * @param chainId         The ID of the chain where the contract is deployed
     * @param contractAddress The address of the contract to be mapped
     */
    function addChainContract(uint64 chainId, address contractAddress) external {
        require(msg.sender == owner, "GlobalManager: only owner");
        contractOn[chainId] = contractAddress;
    }

    /**
     * @notice Adds stake for a user on a specific chain
     * @dev This function is designed to be called via cross-chain calls
     * @param user   The address of the user adding the stake
     * @param amount The amount of stake to add
     */
    function addStake(address user, uint256 amount) external xrecv {
        require(isXCall(), "GlobalManager: only xcall");
        require(isSupportedChain(xmsg.sourceChainId), "GlobalManager: chain not found");
        require(xmsg.sender == contractOn[xmsg.sourceChainId], "GlobalManager: invalid sender");

        stakeOn[user][xmsg.sourceChainId] += amount;
        totalStake += amount;
    }

    /**
     * @notice Removes stake for a user on a specific chain
     * @dev Initiates an xcall to execute a stake removal operation
     * @param user   The address of the user removing the stake
     * @param amount The amount of stake to remove
     */
    function removeStake(address user, uint256 amount) external xrecv {
        require(isXCall(), "GlobalManager: only xcall");
        require(isSupportedChain(xmsg.sourceChainId), "GlobalManager: chain not found");
        require(xmsg.sender == contractOn[xmsg.sourceChainId], "GlobalManager: invalid sender");
        require(stakeOn[user][xmsg.sourceChainId] >= amount, "GlobalManager: insufficient stake");

        bytes memory data = abi.encodeWithSignature("xunstake(address,uint256)", user, amount);
        uint256 fee = feeFor(xmsg.sourceChainId, data);
        require(address(this).balance >= fee, "GlobalManager: insufficient fee");

        stakeOn[user][xmsg.sourceChainId] -= amount;
        totalStake -= amount;

        xcall(xmsg.sourceChainId, xmsg.sender, data);
    }

    /**
     * @dev Checks if a chain ID has an associated contract address
     * @param chainId The chain ID to check
     * @return bool True if there is a contract address associated with the chain ID
     */
    function isSupportedChain(uint64 chainId) internal view returns (bool) {
        return contractOn[chainId] != address(0);
    }
}
