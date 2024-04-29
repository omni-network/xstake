// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MockPortal} from "../lib/omni/contracts/test/utils/MockPortal.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {GlobalManager} from "../src/GlobalManager.sol";
import {LocalStake} from "../src/LocalStake.sol";
import {LocalToken} from "../src/LocalToken.sol";

/**
 * @title Test suite for the GlobalManager functionality
 * @dev This contract tests the interaction with the GlobalManager, including chain management and stake handling, using a mock portal for cross-chain simulation.
 */
contract GlobalTest is Test {
    GlobalManager globalManager;
    MockPortal portal;

    /// @dev Sets up the test environment with GlobalManager and MockPortal
    function setUp() public {
        portal = new MockPortal();
        globalManager = new GlobalManager(address(portal));
    }

    /// @dev Tests the addition of a contract address to a specific chain ID
    function testAddChainContract() public {
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        globalManager.addChainContract(chainId, contractAddress);
        assertEq(
            globalManager.contractOn(chainId), contractAddress, "The contract address should match what was added."
        );
    }

    /// @dev Ensures that adding stake to a non-existent chain causes a revert
    function testAddStakeNotListed() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = portal.chainId();
        vm.deal(user, 1000);
        vm.expectRevert("GlobalManager: chain not found");
        portal.mockXCall(
            chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount)
        );
    }

    /// @dev Verifies that stakes added from an unauthorized address are rejected
    function testAddStakeInvalidSender() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        globalManager.addChainContract(chainId, contractAddress);
        vm.expectRevert("GlobalManager: invalid sender");
        portal.mockXCall(
            chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount)
        );
        assertEq(globalManager.stakeOn(user, chainId), 0, "No stake should be recorded for invalid senders.");
    }

    /// @dev Tests the successful addition of a stake from a valid sender
    function testAddStake() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        globalManager.addChainContract(chainId, contractAddress);
        vm.prank(contractAddress);
        portal.mockXCall(
            chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount)
        );
        assertEq(globalManager.stakeOn(user, chainId), amount, "Stake should be correctly added to the chain.");
    }

    /// @dev Tests the removal of stake and ensures that the stake amount is cleared
    function testRemoveStake() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        uint64 gasLimit = 200_000;

        vm.deal(contractAddress, 1 ether);
        globalManager.addChainContract(chainId, contractAddress);
        vm.prank(contractAddress);
        portal.mockXCall(
            chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount)
        );
        assertEq(globalManager.stakeOn(user, chainId), amount, "Initial stake should be correctly set.");

        vm.deal(address(globalManager), 1 ether); // Ensures sufficient funds for fee handling
        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "feeFor(uint64,bytes,uint64)", chainId, abi.encodeWithSignature("xunstake(address,uint256)", user, amount), gasLimit
            )
        );
        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes,uint64)",
                chainId,
                contractAddress,
                abi.encodeWithSignature("xunstake(address,uint256)", user, amount),
                gasLimit
            )
        );
        vm.prank(contractAddress);
        portal.mockXCall(
            chainId, address(globalManager), abi.encodeWithSelector(globalManager.removeStake.selector, user, amount)
        );
        assertEq(globalManager.stakeOn(user, chainId), 0, "Stake should be removed successfully.");
    }
}
