// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

import {XApp} from "omni/contracts/src/pkg/XApp.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";


import {GlobalManager} from "./GlobalManager.sol";

/**
 * @title LocalStake Contract
 * @notice A contract for staking tokens locally on a rollup chain
 * @dev Contract uses cross-chain communication for stake coordination
 */
contract LocalStake is XApp, Ownable {
    /**
     * @notice Chain ID of the global network
     * @dev State variable to store the Omni Network's specific chain ID
     */
    uint64 public globalChainId;

    /**
     * @notice Address of the GlobalManager contract
     * @dev State variable to store the address for cross-chain interactions
     */
    address public globalManagerContract;

    /**
     * @notice Token interface for ERC20 interactions
     * @dev ERC20 interface used for token transactions
     */
    IERC20 public immutable token;

    /**
     * @dev Events to register stake and unstake actions
     */
    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    /**
     * @dev Initializes a new LocalStake contract with necessary addresses and identifiers
     * @param portal                 Address of the portal or relay used for cross-chain communication
     * @param _globalManagerContract Address of the global management contract
     * @param _globalChainId         Chain ID for the Omni Network, specific chain for state coordination
     * @param _token                 Address of the ERC20 token used for staking
     */
    constructor(address portal, address _globalManagerContract, uint64 _globalChainId, address _token) XApp(portal) Ownable(msg.sender) {
        globalManagerContract = _globalManagerContract;
        globalChainId = _globalChainId;
        token = IERC20(_token);
    }

    /**
     * @notice Stakes tokens by transferring them from the sender to this contract
     * @param amount Amount of tokens to stake
     * @dev Requires a value to cover xcall fees and checks for a minimum amount of tokens to stake
     */
    function stake(uint256 amount) external payable {
        require(amount > 0, "LocalStake: stake more than 0");

        require(token.transferFrom(msg.sender, address(this), amount), "LocalStake: transfer failed");

        emit Staked(msg.sender, amount);

        uint256 fee = xcall(
            globalChainId,
            globalManagerContract,
            abi.encodeWithSelector(GlobalManager.addStake.selector, msg.sender, amount)
        );

        require(msg.value >= fee, "LocalStake: user xcall gas fee");
    }

    /**
     * @notice Unstakes tokens by initiating a removal request via cross-chain communication
     * @param amount The amount of tokens to be unstaked
     * @dev Requires a value to cover xcall fees which are doubled for the xunstake process
     */
    function unstake(uint256 amount) external payable {
        // Unstake on global manager
        uint256 baseFee = xcall(
            globalChainId,
            globalManagerContract,
            abi.encodeWithSelector(GlobalManager.removeStake.selector, msg.sender, amount)
        );

        // Fee for this.xunstake callback
        uint256 callbackFee =
            feeFor(uint64(block.chainid), abi.encodeWithSelector(this.xunstake.selector, msg.sender, amount));

        // Require that user cover both base and callback fees
        require(msg.value >= baseFee + callbackFee, "LocalStake: user xcalls gas fee");
    }

    /**
     * @notice Handles the callback from a successful unstake request, transferring the unstaked tokens to the user
     * @param user   Address to receive the tokens
     * @param amount Amount of tokens to transfer
     * @dev Only callable via xrecv to ensure it's a result of an xcall operation
     */
    function xunstake(address user, uint256 amount) external xrecv {
        require(isXCall(), "LocalStake: only xcall");
        require(xmsg.sourceChainId == globalChainId, "LocalStake: invalid source chain");
        require(xmsg.sender == globalManagerContract, "LocalStake: invalid sender");

        require(token.transfer(user, amount), "LocalStake: transfer failed");
        emit Unstaked(user, amount);
    }

    /**
     * @notice Withdraws the entire ETH balance of this contract to a specified destination
     * @param destination The address to which the ETH will be sent
     * @dev Can only be called by the contract owner. Ensures that the destination is not the zero address.
     */
    function withdraw(address destination) external onlyOwner {
        require(destination != address(0), "LocalStake: invalid destination");
        uint256 balance = address(this).balance;
        require(balance > 0, "LocalStake: no ETH balance");

        (bool sent, ) = destination.call{value: balance}("");
        require(sent, "LocalStake: Failed send ETH");
    }
}
