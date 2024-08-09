// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {XStaker} from "src/XStaker.sol";
import {XStakeController} from "src/XStakeController.sol";
import {TestToken} from "./utils/TestToken.sol";
import {MockPortal} from "omni/core/test/utils/MockPortal.sol";
import {ConfLevel} from "omni/core/src/libraries/ConfLevel.sol";
import {GasLimits} from "src/GasLimits.sol";
import {Test} from "forge-std/Test.sol";

/**
 * @title XStaker_Test
 * @notice Test suite for XStaker
 */
contract XStaker_Test is Test {
    TestToken token;
    MockPortal portal;
    XStaker staker;
    address controller;

    function setUp() public {
        controller = makeAddr("controller");
        token = new TestToken();
        portal = new MockPortal();
        staker = new XStaker(address(portal), address(controller), address(token));
    }

    /**
     * @notice Test XStaker.stake
     */
    function test_stake() public {
        address user = makeAddr("user");
        uint256 balance = 100 ether;
        uint256 amount = 10 ether;
        uint256 fee = staker.stakeFee(amount);

        // give user some tokens
        token.mint(user, balance);

        // approve the xstaker to spend them
        vm.prank(user);
        token.approve(address(staker), balance);

        // requires fee
        vm.expectRevert("XApp: insufficient funds");
        vm.prank(user);
        staker.stake(amount, ConfLevel.Finalized);

        // charges fee to user
        vm.deal(address(staker), 10 ether); // give staker some ether, so it ~could~ cover fee
        vm.expectRevert("XStaker: insufficient fee"); // but it doesn't
        vm.prank(user);
        staker.stake(amount, ConfLevel.Finalized);

        // stake, expect xcall to controller
        vm.expectCall(
            address(portal),
            abi.encodeCall(
                MockPortal.xcall,
                (
                    portal.omniChainId(),
                    ConfLevel.Finalized,
                    address(controller),
                    abi.encodeCall(XStakeController.recordStake, (user, amount)),
                    GasLimits.RecordStake
                )
            )
        );
        vm.prank(user);
        vm.deal(user, fee);
        staker.stake{value: fee}(amount, ConfLevel.Finalized);

        // check balances
        assertEq(token.balanceOf(address(staker)), amount);
        assertEq(token.balanceOf(user), balance - amount);
    }

    /**
     * @notice Test XStaker.withdraw
     */
    function test_withdraw() public {
        address user = makeAddr("user");
        uint256 amount = 10 ether;
        uint64 omniChainId = portal.omniChainId();
        token.mint(address(staker), amount);

        // only xcall
        vm.expectRevert("XStaker: only xcall");
        staker.withdraw(user, amount);

        // only omni
        vm.expectRevert("XStaker: only omni");
        portal.mockXCall({
            sourceChainId: 1234, // not omni chain id
            sender: address(controller),
            to: address(staker),
            data: abi.encodeCall(XStaker.withdraw, (user, amount)),
            gasLimit: GasLimits.Withdraw
        });

        // only controller
        vm.expectRevert("XStaker: only controller");
        portal.mockXCall({
            sourceChainId: omniChainId,
            sender: address(1234), // not controller
            to: address(staker),
            data: abi.encodeCall(XStaker.withdraw, (user, amount)),
            gasLimit: GasLimits.Withdraw
        });

        // withdraw
        portal.mockXCall({
            sourceChainId: portal.omniChainId(),
            sender: address(controller),
            to: address(staker),
            data: abi.encodeCall(XStaker.withdraw, (user, amount)),
            gasLimit: GasLimits.Withdraw
        });

        // assert balances
        assertEq(token.balanceOf(address(staker)), 0);
        assertEq(token.balanceOf(user), amount);
    }
}
