// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {XApp} from "../lib/omni/contracts/src/pkg/XApp.sol";
import {IERC20} from "../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title LocalStake Contract
/// @notice A contract for staking tokens locally on a rollup chain
contract LocalStake is XApp {
    uint64 public globalChainId; // Chain ID of the global network
    address public globalManagerContract; // Address of the GlobalManager contract
    IERC20 public localToken; // Token interface for ERC20 interactions

    /// @notice Initializes a new LocalStake contract
    /// @param portal Address of the portal or relay used for cross-chain communication
    /// @param _globalManagerContract Address of the global management contract
    /// @param _globalChainId Chain ID for the Omni Network, specific chain for state
    /// @param _localToken Address of the ERC20 token used for staking
    constructor(
        address portal, 
        address _globalManagerContract,
        uint64 _globalChainId,
        address _localToken
    ) XApp(portal) {
        globalManagerContract = _globalManagerContract;
        globalChainId = _globalChainId;
        localToken = IERC20(_localToken);
    }

    /// @notice Stakes tokens by transferring them from the sender to this contract
    /// @param amount Amount of tokens to stake
    /// @dev Requires a value to cover xcall fees and checks for a minimum amount of tokens to stake
    function stake(uint256 amount) external payable {
        require(amount > 0, "LocalStake: must stake more than 0");
        require(msg.value > 0, "LocalStake: attach value for xcall fee");

        // Ensures token transfer from the user to this contract
        require(localToken.transferFrom(msg.sender, address(this), amount), "LocalStake: transfer failed");

        // Encode the function call to the global manager for adding a stake
        bytes memory data = abi.encodeWithSignature("addStake(address,uint256)", msg.sender,  amount);
        // Calculate and check xcall fee requirements
        uint256 portalFee = feeFor(globalChainId, data);
        require(msg.value > portalFee, "LocalStake: insufficient value for xcall fee");

        // Perform the xcall to the global manager contract
        xcall(globalChainId, globalManagerContract, data);
    }

    /// @notice Unstakes tokens by initiating a removal request via cross-chain communication
    /// @param amount The amount of tokens to be unstaked
    /// @dev Requires a value to cover xcall fees which are doubled for the xunstake process
    function unstake(uint256 amount) external payable {
        require(msg.value > 0, "LocalStake: attach value for xcall fee");

        // Encode the function call to the global manager for removing a stake
        bytes memory data = abi.encodeWithSignature("removeStake(address,uint256)", msg.sender,  amount);
        // Calculate xcall fee, doubling it for the unstake process
        uint256 portalFee = feeFor(globalChainId, data) * 2; 
        require(msg.value > portalFee, "LocalStake: insufficient value for xcall fee");

        // Perform the xcall to the global manager contract
        xcall(globalChainId, globalManagerContract, data);
    }

    /// @notice Handles the callback from a successful unstake request, transferring the unstaked tokens to the user
    /// @param user Address to receive the tokens
    /// @param amount Amount of tokens to transfer
    /// @dev Only callable via xrecv to ensure it's a result of an xcall operation
    function xunstake(address user, uint256 amount) external xrecv {
        require(isXCall(), "LocalStake: only xcall");
        require(xmsg.sourceChainId == globalChainId, "LocalStake: invalid source chain");
        require(xmsg.sender == globalManagerContract, "LocalStake: invalid sender");

        // Transfer the unstaked tokens to the user
        require(localToken.transfer(user, amount), "LocalStake: transfer failed");
    }
}
