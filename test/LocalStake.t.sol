// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {MockPortal} from "../lib/omni/contracts/test/utils/MockPortal.sol";
import {LocalStake} from "../src/LocalStake.sol";
import {GlobalManager} from "../src/GlobalManager.sol";
import {LocalToken} from "../src/LocalToken.sol";

contract SimpleStakeTest is Test {
    LocalStake localStake;
    MockPortal portal;
    GlobalManager globalManager;
    LocalToken localToken;
    address globalManagerAddress;
    uint64 globalChainId = 165; // Testnet Omni EVM chain ID

    function setUp() public {
        portal = new MockPortal();
        globalManager = new GlobalManager(address(portal));
        localToken = new LocalToken();
        globalManagerAddress = address(globalManager);
        localStake = new LocalStake(address(portal), globalManagerAddress, globalChainId, address(localToken));
    }

    function testStake() public {
        uint256 feeAmount = 1000 gwei;
        uint256 stakeAmount = 100 ether;
        address user = address(0xf00); // Mock user address for testing

        // Simulate staking tokens to the stake function
        localToken.transfer(user, stakeAmount);
        vm.deal(user, 1 ether);
        vm.startPrank(user);
        localToken.approve(address(localStake), stakeAmount);
        vm.expectCall(
            address(portal), 
            abi.encodeWithSignature(
                "feeFor(uint64,bytes)",
                globalChainId,
                abi.encodeWithSignature(
                    "addStake(address,uint256)", 
                    user, 
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
                    user, 
                    stakeAmount
                )
            )
        );
        localStake.stake{value: feeAmount}(stakeAmount);
        vm.stopPrank();

        // Check balance of the contract has increased by the stake amount
        assertEq(localToken.balanceOf(address(localStake)), stakeAmount, "Contract did not receive the stake amount.");
    }

    function testInsufficientFee() public {
        uint256 feeAmount = 1000 wei;
        uint256 stakeAmount = 1000000;
        address user = address(0xf00); // Mock user address for testing

        // Simulate stake with insufficient fee
        localToken.transfer(user, stakeAmount);
        vm.deal(user, stakeAmount);
        vm.startPrank(user);
        localToken.approve(address(localStake), stakeAmount);
        vm.expectRevert("LocalStake: insufficient value for xcall fee");
        localStake.stake{value: feeAmount}(stakeAmount);
        vm.stopPrank();
    }

    function testUnstake() public {
        uint256 feeAmount = 1000 gwei;
        uint256 unstakeAmount = 100 ether;
        address user = address(0xf00); // Mock user address for testing

        // Simulate unstake
        vm.deal(user, feeAmount);
        vm.expectCall(
            address(portal), 
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes)",
                globalChainId,
                globalManagerAddress,
                abi.encodeWithSignature(
                    "removeStake(address,uint256)",
                    user, 
                    unstakeAmount
                )
            )
        );
        vm.prank(user);
        localStake.unstake{value: feeAmount}(unstakeAmount);
    }

    function testXUnstake() public {
        uint256 unstakeAmount = 100 ether;
        uint256 feeAmount = 1000 gwei;
        address user = address(0xf00); // Mock user address for testing

        localToken.transfer(address(localStake), unstakeAmount);

        // Simulate admin contract calling xunstake
        vm.deal(address(localStake), feeAmount);
        vm.prank(globalManagerAddress);
        portal.mockXCall(globalChainId, address(localStake), abi.encodeWithSelector(localStake.xunstake.selector, user, unstakeAmount));

        // Check that the user received the unstake amount
        assertEq(localToken.balanceOf(user), unstakeAmount, "User did not receive the unstake amount.");
    }
}
