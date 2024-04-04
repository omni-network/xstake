// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import {XApp} from "../lib/omni/contracts/src/pkg/XApp.sol";

contract OmniAdmin is XApp {
    address public owner;
    uint64[] public chainIds;
    mapping(uint64 => address) public chainIdContracts;
    mapping (address => mapping(uint64 => uint256)) public userChainIdStakes;

    constructor(address portal) XApp(portal) {
        owner = msg.sender;
    }

    function addChainContract(uint64 chainId, address contractAddress) external {
        require(msg.sender == owner, "OmniAdmin: only owner");
        addChainId(chainId);
        chainIdContracts[chainId] = contractAddress;
    }

    function addStake(address user, uint256 amount) external xrecv {
        require(isXCall(), "OmniAdmin: only xcall");
        require(isExistingChainId(xmsg.sourceChainId), "OmniAdmin: chain not found");
        require(xmsg.sender == chainIdContracts[xmsg.sourceChainId], "OmniAdmin: invalid sender");
        userChainIdStakes[user][xmsg.sourceChainId] += amount;
    }

    function removeStake(address user, uint256 amount) external xrecv {
        require(isXCall(), "OmniAdmin: only xcall");
        require(isExistingChainId(xmsg.sourceChainId), "OmniAdmin: chain not found");
        require(xmsg.sender == chainIdContracts[xmsg.sourceChainId], "OmniAdmin: invalid sender");
        require(userChainIdStakes[user][xmsg.sourceChainId] >= amount, "OmniAdmin: insufficient stake");
        bytes memory data = abi.encodeWithSignature("xunstake(address,uint256)", user, amount);
        uint256 fee = feeFor(xmsg.sourceChainId, data);
        require(address(this).balance >= fee, "OmniAdmin: insufficient fee");
        userChainIdStakes[user][xmsg.sourceChainId] -= amount;
        xcall(xmsg.sourceChainId, xmsg.sender, data);
    }

    function addChainId(uint64 chainId) internal {
        for (uint i = 0; i < chainIds.length; i++) {
            if (chainIds[i] == chainId) {
                return;
            }
        }
        chainIds.push(chainId);
    }

    function isExistingChainId(uint64 chainId) internal view returns (bool) {
        for (uint256 i = 0; i < chainIds.length; i++) {
            if (chainIds[i] == chainId) {
                return true;
            }
        }
        return false;
    }
}
