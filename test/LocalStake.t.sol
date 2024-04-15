// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {MockPortal} from "../lib/omni/contracts/test/utils/MockPortal.sol";
import {LocalStake} from "../src/LocalStake.sol";
import {GlobalManager} from "../src/GlobalManager.sol";
import {LocalToken} from "../src/LocalToken.sol";

// Test contract for staking operations
contract SimpleStakeTest is Test {
    LocalStake localStake;           // LocalStake contract instance
    MockPortal portal;               // MockPortal for simulation
    GlobalManager globalManager;     // GlobalManager contract instance
    LocalToken localToken;           // LocalToken contract instance
    address globalManagerAddress;    // Address of GlobalManager
    uint64 globalChainId = 165;      // Testnet Omni EVM chain ID

    // Set up the test environment
    function setUp() public {
        portal = new MockPortal();  // Initialize MockPortal
        globalManager = new GlobalManager(address(portal));  // Set up GlobalManager with the portal's address
        localToken = new LocalToken();  // Initialize LocalToken
        globalManagerAddress = address(globalManager);  // Store address of GlobalManager
        localStake = new LocalStake(address(portal), globalManagerAddress, globalChainId, address(localToken));  // Initialize LocalStake
    }

    // Test the stake functionality with proper fee and amount
    function testStake() public {
        uint256 feeAmount = 1000 gwei;  // Fee amount in gwei
        uint256 stakeAmount = 100 ether;  // Stake amount in ether
        address user = address(0xf00);  // Mock user address for testing

        localToken.transfer(user, stakeAmount);  // Transfer tokens to the user
        vm.deal(user, 1 ether);  // Provide ether to the user for fees
        vm.startPrank(user);  // Start simulation as the user
        localToken.approve(address(localStake), stakeAmount);  // User approves the stake amount
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
        localStake.stake{value: feeAmount}(stakeAmount);  // User stakes the amount
        vm.stopPrank();  // End simulation

        // Verify the stake amount has been transferred to the contract
        assertEq(localToken.balanceOf(address(localStake)), stakeAmount, "Contract did not receive the stake amount.");
    }

    // Test staking with insufficient fee provided
    function testInsufficientFee() public {
        uint256 feeAmount = 1000 wei;  // Fee amount too small, in wei
        uint256 stakeAmount = 1000000;  // Arbitrary stake amount
        address user = address(0xf00);  // Mock user address

        localToken.transfer(user, stakeAmount);  // Transfer tokens to the user
        vm.deal(user, stakeAmount);  // Provide ether to the user
        vm.startPrank(user);  // Start simulation as the user
        localToken.approve(address(localStake), stakeAmount);  // User approves the stake amount
        vm.expectRevert("LocalStake: insufficient value for xcall fee");  // Expect revert due to insufficient fee
        localStake.stake{value: feeAmount}(stakeAmount);  // Attempt to stake with insufficient fee
        vm.stopPrank();  // End simulation
    }

    // Test the unstake functionality
    function testUnstake() public {
        uint256 feeAmount = 1000 gwei;  // Fee amount in gwei
        uint256 unstakeAmount = 100 ether;  // Unstake amount in ether
        address user = address(0xf00);  // Mock user address for testing

        vm.deal(user, feeAmount);  // Provide ether to the user for fees
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
        vm.prank(user);  // Simulate action as the user
        localStake.unstake{value: feeAmount}(unstakeAmount);  // User unstakes the amount
    }

    // Test the administrative unstake function, xunstake
    function testXUnstake() public {
        uint256 unstakeAmount = 100 ether;  // Unstake amount in ether
        uint256 feeAmount = 1000 gwei;  // Fee amount in gwei
        address user = address(0xf00);  // Mock user address for testing

        localToken.transfer(address(localStake), unstakeAmount);  // Transfer unstake amount to the stake contract

        // Simulate administrative contract calling xunstake
        vm.deal(address(localStake), feeAmount);  // Provide fees to the contract
        vm.prank(globalManagerAddress);  // Simulate call from GlobalManager
        portal.mockXCall(globalChainId, address(localStake), abi.encodeWithSelector(localStake.xunstake.selector, user, unstakeAmount));

        // Verify the user received the unstake amount
        assertEq(localToken.balanceOf(user), unstakeAmount, "User did not receive the unstake amount.");
    }
}
