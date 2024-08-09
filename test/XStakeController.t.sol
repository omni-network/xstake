// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {XStaker} from "src/XStaker.sol";
import {XStakeController} from "src/XStakeController.sol";
import {TestToken} from "./utils/TestToken.sol";
import {MockPortal} from "omni/core/test/utils/MockPortal.sol";
import {ConfLevel} from "omni/core/src/libraries/ConfLevel.sol";
import {GasLimits} from "src/GasLimits.sol";
import {Test} from "forge-std/Test.sol";

/**
 * @title XStakeController_Test
 * @notice Test suite for XStakerController
 */
contract XStakeController_Test is Test {
    TestToken token;
    MockPortal portal;
    XStakeController controller;
    address owner;

    address xstaker1;
    address xstaker2;

    uint64 chainId1 = 1;
    uint64 chainId2 = 2;

    function setUp() public {
        owner = makeAddr("owner");
        xstaker1 = makeAddr("xstaker1");
        xstaker2 = makeAddr("xstaker2");

        token = new TestToken();
        portal = new MockPortal();
        controller = new XStakeController(address(portal), owner);
    }

    /**
     * @notice Test XStakeController.recordStake
     */
    function test_recordStake() public {
        address user = makeAddr("user");
        uint256 amount = 10 ether;

        // only xcall
        vm.expectRevert("Controller: only xcall");
        controller.recordStake(user, amount);

        // only supported chain
        vm.expectRevert("Controller: unsupported chain");
        portal.mockXCall({
            sourceChainId: chainId1, // not registered yet
            sender: xstaker1,
            to: address(controller),
            data: abi.encodeCall(XStakeController.recordStake, (user, amount)),
            gasLimit: GasLimits.RecordStake
        });

        // only known xstaker1
        vm.prank(owner);
        controller.registerXStaker(chainId1, xstaker1);

        vm.expectRevert("Controller: only xstaker");
        portal.mockXCall({
            sourceChainId: chainId1,
            sender: address(1234), // not xstaker1
            to: address(controller),
            data: abi.encodeCall(XStakeController.recordStake, (user, amount)),
            gasLimit: GasLimits.RecordStake
        });

        // report stake
        portal.mockXCall({
            sourceChainId: chainId1,
            sender: xstaker1,
            to: address(controller),
            data: abi.encodeCall(XStakeController.recordStake, (user, amount)),
            gasLimit: GasLimits.RecordStake
        });

        // assert stake
        assertEq(controller.stakeOn(user, chainId1), amount);
    }

    /**
     * @notice Test XStakeController.unstake
     */
    function test_unstake() public {
        address user = makeAddr("user");
        uint256 amount = 10 ether;

        vm.prank(owner);
        controller.registerXStaker(chainId1, xstaker1);

        // no stake
        vm.expectRevert("Controller: no stake");
        vm.prank(user);
        controller.unstake(chainId1);

        // stake, to give user something to unstake
        portal.mockXCall({
            sourceChainId: chainId1,
            sender: xstaker1,
            to: address(controller),
            data: abi.encodeCall(XStakeController.recordStake, (user, amount)),
            gasLimit: GasLimits.RecordStake
        });

        // requires fee
        vm.expectRevert("XApp: insufficient funds");
        vm.prank(user);
        controller.unstake(chainId1);

        // charges fee to user
        vm.deal(address(controller), 10 ether); // give controller some ether, so it ~could~ cover fee
        vm.expectRevert("Controller: insufficient fee"); // but it doesn't
        vm.prank(user);
        controller.unstake(chainId1);

        // unstake, expect xcall to xstaker1
        uint256 fee = controller.unstakeFee(chainId1);
        vm.expectCall(
            address(portal),
            abi.encodeCall(
                MockPortal.xcall,
                (
                    chainId1,
                    ConfLevel.Finalized,
                    xstaker1,
                    abi.encodeCall(XStaker.withdraw, (user, amount)),
                    GasLimits.Withdraw
                )
            )
        );
        vm.prank(user);
        vm.deal(user, fee);
        controller.unstake{value: fee}(chainId1);

        // check balances
        assertEq(token.balanceOf(address(controller)), 0);
    }
}
