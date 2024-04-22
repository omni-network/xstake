// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MockPortal} from "../lib/omni/contracts/test/utils/MockPortal.sol";
import {Test, console} from "../lib/forge-std/src/Test.sol";
import {GlobalManager} from "../src/GlobalManager.sol";

// Test contract for GlobalManager functionality
contract GlobalTest is Test {
    GlobalManager globalManager;  // Instance of GlobalManager
    MockPortal portal;            // Instance of MockPortal for testing

    // Set up instances for testing
    function setUp() public {
        portal = new MockPortal();  // Initializes MockPortal
        globalManager = new GlobalManager(address(portal));  // Initializes GlobalManager with portal's address
    }

    // Test adding a contract to a chain
    function testAddChainContract() public {
        uint64 chainId = 1;  // Chain ID to be used
        address contractAddress = address(0x123);  // Example contract address
        globalManager.addChainContract(chainId, contractAddress);  // Adds the contract address to the specified chain
        assertEq(globalManager.contractOn(chainId), contractAddress);  // Asserts that the contract address matches the stored value
    }

    // Test adding a stake to a non-existent chain
    function testAddStakeNotListed() public {
        uint256 amount = 100;  // Stake amount
        address user = address(0x123);  // User address
        uint64 chainId = portal.chainId();  // Retrieves the current chain ID from portal
        vm.deal(user, 1000);  // Allocates funds to user for testing
        vm.expectRevert("GlobalManager: chain not found");  // Expecting a revert with specific error message
        portal.mockXCall(chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount));
        // Attempts to add stake, which should fail
    }

    // Test adding a stake from an invalid sender
    function testAddStakeInvalidSender() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        globalManager.addChainContract(chainId, contractAddress);  // Adds a chain contract
        vm.expectRevert("GlobalManager: invalid sender");  // Expecting revert due to invalid sender
        portal.mockXCall(chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount));
        assertEq(globalManager.stakeOn(user, chainId), 0);  // Ensures no stake is recorded
    }

    // Test successful stake addition
    function testAddStake() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        globalManager.addChainContract(chainId, contractAddress);  // Adds a chain contract
        vm.prank(contractAddress);  // Simulates a call from the contract
        portal.mockXCall(chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount));
        assertEq(globalManager.stakeOn(user, chainId), amount);  // Checks the stake amount is added correctly
    }

    // Test stake removal
    function testRemoveStake() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        vm.deal(contractAddress, 1 ether);  // Funds the contract with 1 ether
        globalManager.addChainContract(chainId, contractAddress);  // Adds a chain contract
        vm.prank(contractAddress);  // Simulates a call from the contract
        portal.mockXCall(chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount));
        assertEq(globalManager.stakeOn(user, chainId), amount);  // Asserts the stake has been added
        vm.deal(address(globalManager), 1 ether);  // Funds the GlobalManager with 1 ether
        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "feeFor(uint64,bytes)",
                chainId,
                abi.encodeWithSignature(
                    "xunstake(address,uint256)",
                    user,
                    amount
                )
            )
        );
        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes)",
                chainId,
                contractAddress,
                abi.encodeWithSignature(
                    "xunstake(address,uint256)",
                    user,
                    amount
                )
            )
        );
        vm.prank(contractAddress);  // Simulates a call from the contract
        portal.mockXCall(chainId, address(globalManager), abi.encodeWithSelector(globalManager.removeStake.selector, user, amount));
        assertEq(globalManager.stakeOn(user, chainId), 0);  // Asserts the stake has been removed
    }
}
