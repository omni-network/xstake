// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {XApp} from "omni/core/src/pkg/XApp.sol";
import {ConfLevel} from "omni/core/src/libraries/ConfLevel.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {GasLimits} from "./GasLimits.sol";
import {XStakeController} from "./XStakeController.sol";

/**
 * @title XStaker
 *
 * @notice Deployed on multiple chains, this contract is the entry / exit point for
 *      our cross-chain staking protocol. It accepts ERC20 deposits, and records
 *      them with the XStakeController on Omni. When a user unstakes on Omni,
 *      this contract pays out the widrawal.
 *
 * @dev Here we allow the user to specify the confirmation level for the xcall.
 *      The options are:
 *
 *      - ConfLevel.Finalized
 *          Strongest security guarantee - the xcall will be delivered exactly once.
 *
 *          It is only confirmed and relayed when the source tx is finalized.
 *          L2 txs are finalized only when posted to L1, and the corresponding
 *          L1 block is finalized. This can take 5-20 minutes.
 *
 *      - ConfLevel.Latest
 *          Weaker security guarantees - best effort delivery.
 *
 *          These xcalls are subject to reorg risk. It is possible that
 *          1. The xcall is delivered, but excluded from the canonical source chain.
 *          2. The xcall is included in the canonical source chain, but not delivered.
 *
 *          In scenario 1, our XStakeController will view this user as staked, but
 *          the user will still cutsody their tokens on the source.
 *  8
 *          In scenario 2, the XStaker will take cutsody of the user's tokens, but
 *          the XStakeController will not recognize the user as staked.
 *
 *      We can choose to reduce protocol risk, by requiring ConfLevel.Finalized for deposits
 *      over a certain maximum. Or, there are alternative protocol designs that can mitigate
 *      the impact of reorgs, and offer recovery mechanisms.
 *
 *      Finally, note that current reorg risk on today's L2s (like Optimism and Arbitrum)
 *      is low. Though it should remain a consideration.
 */
contract XStaker is XApp {
    /// @notice Stake token.
    IERC20 public immutable token;

    /// @notice Address of the XStakeController contract on omni.
    address public controller;

    constructor(address portal_, address controller_, address token_) XApp(portal_, ConfLevel.Finalized) {
        controller = controller_;
        token = IERC20(token_);
    }

    /**
     * @notice Stakes `amount` tokens.
     * @param amount    Amount of tokens to stake.
     * @param confLevel XCall confirmation level
     */
    function stake(uint256 amount, uint8 confLevel) public payable {
        require(amount > 0, "XStaker: insufficient amount");
        require(token.transferFrom(msg.sender, address(this), amount), "XStaker: transfer failed");

        uint256 fee = xcall({
            destChainId: omniChainId(),
            conf: confLevel,
            to: controller,
            data: abi.encodeCall(XStakeController.recordStake, (msg.sender, amount)),
            gasLimit: GasLimits.RecordStake
        });

        // Make sure the user paid
        require(msg.value >= fee, "XStaker: insufficient fee");
    }

    /**
     * @notice Stakes `amount` tokens with default confirmation level.
     */
    function stake(uint256 amount) public payable {
        stake(amount, defaultConfLevel);
    }

    /**
     * @notice Returns the xcall fee for required to stake.
     */
    function stakeFee(uint256 amount) public view returns (uint256) {
        return feeFor({
            destChainId: omniChainId(),
            data: abi.encodeCall(XStakeController.recordStake, (msg.sender, amount)),
            gasLimit: GasLimits.RecordStake
        });
    }

    /**
     * @notice Withdraws `amount` tokens to `to`.
     *         Only callable by via xcall by XStakeController on Omni.
     */
    function withdraw(address to, uint256 amount) external xrecv {
        require(isXCall(), "XStaker: only xcall");
        require(xmsg.sourceChainId == omniChainId(), "XStaker: only omni");
        require(xmsg.sender == controller, "XStaker: only controller");
        require(token.transfer(to, amount), "XStaker: transfer failed");
    }
}
