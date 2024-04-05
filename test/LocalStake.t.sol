// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {MockPortal} from "../lib/omni/contracts/test/utils/MockPortal.sol";
import {LocalStake} from "../src/LocalStake.sol";
import {GlobalManager} from "../src/GlobalManager.sol";

contract SimpleStakeTest is Test {
    LocalStake localStake;
    MockPortal portal;
    GlobalManager globalManager;
    address globalManagerAddress;
    uint64 globalChainId = 165;

    function setUp() public {
        portal = new MockPortal();
        globalManager = new GlobalManager(address(portal));
        globalManagerAddress = address(globalManager);
        localStake = new LocalStake(address(portal), globalManagerAddress);
    }

    function testStake() public {
        uint256 stakeAmount = 1 ether;
        uint256 initialBalance = address(localStake).balance;

        // calculate fee for the xcall in the stake function
        uint256 fee = portal.feeFor(1, abi.encodeWithSignature("addStake(address,uint256)", address(this), stakeAmount));
        
        // Simulate sending ETH to the stake function
        vm.deal(address(this), stakeAmount);
        vm.expectCall(
            address(portal), 
            abi.encodeWithSignature(
                "feeFor(uint64,bytes)",
                globalChainId,
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
                globalChainId,
                globalManagerAddress,
                abi.encodeWithSignature(
                    "addStake(address,uint256)", 
                    address(this), 
                    stakeAmount - fee - fee
                )
            )
        );
        vm.prank(address(this));
        localStake.stake{value: stakeAmount}();

        // Check balance of the contract has increased by the stake amount
        assertEq(address(localStake).balance, initialBalance + stakeAmount - fee, "Stake amount was not correctly received by the SimpleStake contract.");
    }

    function testInsufficientStake() public {
        uint256 stakeAmount = 1000000;

        // Simulate sending ETH to the stake function
        vm.deal(address(this), stakeAmount);
        vm.expectRevert("LocalStake: insufficient value for xcall fee");
        vm.prank(address(this));
        localStake.stake{value: stakeAmount}();
    }

    function testUnstake() public {
        uint256 stakeAmount = 1 ether;
        uint256 unstakeAmount = 0.5 ether;

        // Simulate unstake
        vm.deal(address(localStake), stakeAmount);
        vm.expectCall(
            address(portal), 
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes)",
                globalChainId,
                globalManagerAddress,
                abi.encodeWithSignature(
                    "removeStake(uint256,address)", 
                    unstakeAmount, 
                    address(this)
                )
            )
        );
        vm.prank(address(this));
        localStake.unstake(unstakeAmount);
    }

    function testXUnstake() public {
        uint256 unstakeAmount = 1 ether;
        address user = address(0xf00); // Mock user address for testing

        // Simulate admin contract calling xunstake
        vm.deal(address(localStake), unstakeAmount);
        vm.prank(globalManagerAddress);
        portal.mockXCall(globalChainId, address(localStake), abi.encodeWithSelector(localStake.xunstake.selector, user, unstakeAmount));

        // Check that the user received the unstake amount
        assertEq(address(user).balance, unstakeAmount, "User did not receive the unstake amount.");
    }
}
