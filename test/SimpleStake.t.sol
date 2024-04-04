// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {MockPortal} from "../lib/omni/contracts/test/utils/MockPortal.sol";
import {SimpleStake} from "../src/SimpleStake.sol";
import {OmniAdmin} from "../src/Admin.sol";

contract SimpleStakeTest is Test {
    SimpleStake simpleStake;
    MockPortal portal;
    OmniAdmin admin;
    address adminContractAddress;

    function setUp() public {
        portal = new MockPortal();
        admin = new OmniAdmin(address(portal));
        adminContractAddress = address(admin);
        simpleStake = new SimpleStake(address(portal), adminContractAddress);
    }

    function testStake() public {
        uint256 stakeAmount = 1 ether;
        uint256 initialBalance = address(simpleStake).balance;

        // calculate fee for the xcall in the stake function
        uint256 fee = portal.feeFor(1, abi.encodeWithSignature("addStake(address,uint256)", address(this), stakeAmount));
        
        // Simulate sending ETH to the stake function
        vm.deal(address(this), stakeAmount);
        vm.expectCall(
            address(portal), 
            abi.encodeWithSignature(
                "feeFor(uint64,bytes)",
                1,
                abi.encodeWithSignature(
                    "addStake(address,uint256)", 
                    address(this), 
                    stakeAmount
                )
            )
        );
        vm.expectCall(
            address(portal), 
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes)",
                1,
                adminContractAddress,
                abi.encodeWithSignature(
                    "addStake(address,uint256)", 
                    address(this), 
                    stakeAmount - fee - fee
                )
            )
        );
        vm.prank(address(this));
        simpleStake.stake{value: stakeAmount}();

        // Check balance of the contract has increased by the stake amount
        assertEq(address(simpleStake).balance, initialBalance + stakeAmount - fee, "Stake amount was not correctly received by the SimpleStake contract.");
    }

    function testInsufficientStake() public {
        uint256 stakeAmount = 1000000;

        // Simulate sending ETH to the stake function
        vm.deal(address(this), stakeAmount);
        vm.expectRevert("SimpleStake: insufficient value for fee");
        vm.prank(address(this));
        simpleStake.stake{value: stakeAmount}();
    }

    function testUnstake() public {
        uint256 stakeAmount = 1 ether;
        uint256 unstakeAmount = 0.5 ether;

        // Simulate unstake
        vm.deal(address(simpleStake), stakeAmount);
        vm.expectCall(
            address(portal), 
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes)",
                1,
                adminContractAddress,
                abi.encodeWithSignature(
                    "removeStake(uint256,address)", 
                    unstakeAmount, 
                    address(this)
                )
            )
        );
        vm.prank(address(this));
        simpleStake.unstake(unstakeAmount);
    }

    function testXUnstake() public {
        uint256 unstakeAmount = 1 ether;
        address user = address(0xf00); // Mock user address for testing

        // Simulate admin contract calling xunstake
        vm.deal(address(simpleStake), unstakeAmount);
        vm.prank(adminContractAddress);
        portal.mockXCall(1, address(simpleStake), abi.encodeWithSelector(simpleStake.xunstake.selector, user, unstakeAmount));

        // Check that the user received the unstake amount
        assertEq(address(user).balance, unstakeAmount, "User did not receive the unstake amount.");
    }
}
