// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {XApp} from "omni/core/src/pkg/XApp.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ConfLevel} from "omni/core/src/libraries/ConfLevel.sol";
import {GasLimits} from "./GasLimits.sol";
import {XStaker} from "./XStaker.sol";

/**
 * @title XStakeController
 *
 * @notice The global accountant of our cross-chain staking protocol. This is a
 *      singleton contract, deployed on Omni. It tracks stakes for all users
 *      across each supported chain, and directs the XStaker to payout users
 *      when they unstake.
 *
 * @dev We initialize our XApp with default ConfLevel.Finalized (see constructor),
 *      and do not specify conf level in individual xcalls, as we do in XStaker.
 *      This is bescause XStakeController is deployed on Omni. Omni only
 *      supports Finalized conf level, as OmniEVM has instant finality.
 */
contract XStakeController is XApp, Ownable {
    /// @notice Address of XStaker contract by chain id.
    mapping(uint64 => address) public xstakerOn;

    /// @notice Map account to chain id to stake.
    mapping(address => mapping(uint64 => uint256)) public stakeOn;

    constructor(address portal, address owner) XApp(portal, ConfLevel.Finalized) Ownable(owner) {}

    /**
     * @notice Record `amount` staked by `user` on `xmsg.sourceChainId`.
     *         Only callable via xcall by a known XStaker contract.
     * @param user   Account that staked.
     * @param amount Amount staked.
     */
    function recordStake(address user, uint256 amount) external xrecv {
        require(isXCall(), "Controller: only xcall");
        require(xstakerOn[xmsg.sourceChainId] != address(0), "Controller: unsupported chain");
        require(xstakerOn[xmsg.sourceChainId] == xmsg.sender, "Controller: only xstaker");

        stakeOn[user][xmsg.sourceChainId] += amount;
    }

    /**
     * @notice Unstake msg.sender `onChainID`.
     * @dev Unstaking starts on the controller, because the controller is the
     *      source of truth for user stakes. The controller directs the XStaker to
     *      payout the user via xcall.
     */
    function unstake(uint64 onChainID) external payable {
        uint256 stake = stakeOn[msg.sender][onChainID];
        require(stake > 0, "Controller: no stake");

        stakeOn[msg.sender][onChainID] = 0;

        uint256 fee = xcall({
            destChainId: onChainID,
            to: xstakerOn[onChainID],
            data: abi.encodeCall(XStaker.withdraw, (msg.sender, stake)),
            gasLimit: GasLimits.Withdraw
        });

        require(msg.value >= fee, "Controller: insufficient fee");
    }

    /**
     * @notice Return the fee required to unstake `onChainID`.
     */
    function unstakeFee(uint64 onChainID) external view returns (uint256) {
        return feeFor({
            destChainId: onChainID,
            data: abi.encodeCall(XStaker.withdraw, (msg.sender, stakeOn[msg.sender][onChainID])),
            gasLimit: GasLimits.Withdraw
        });
    }

    /**
     * @notice Admin function to register an XSaker deployment.
     *         Deployments must be registered before they can be used.
     * @param chainId Chain ID of the XStaker deployment.
     * @param addr    Deployment address.
     */
    function registerXStaker(uint64 chainId, address addr) external onlyOwner {
        xstakerOn[chainId] = addr;
    }
}
