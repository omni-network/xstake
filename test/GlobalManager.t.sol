// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MockPortal} from "../lib/omni/contracts/test/utils/MockPortal.sol";
import {Test} from "../lib/forge-std/src/Test.sol";
import {GlobalManager} from "../src/GlobalManager.sol";
import {LocalStake} from "../src/LocalStake.sol";
import {LocalToken} from "../src/LocalToken.sol";

/**
 * @title Exposed Global Manager Contract for Testing
 * @notice This contract extends the GlobalManager to expose internal functions for testing purposes.
 */
contract ExposedGlobalManager is GlobalManager {
    constructor(address portal) GlobalManager(portal) {}

    /// @dev This function allows for direct interaction with the internal _removeStake function, 
    ///      bypassing the usual security checks for demonstration purposes.
    function exposeRemoveStake(address user, uint256 amount, uint64 gasLimit) public xrecv {
        require(isXCall(), "GlobalManager: only xcall");
        require(isSupportedChain(xmsg.sourceChainId), "GlobalManager: chain not found");
        require(xmsg.sender == contractOn[xmsg.sourceChainId], "GlobalManager: invalid sender");
        require(stakeOn[user][xmsg.sourceChainId] >= amount, "GlobalManager: insufficient stake");

        _removeStake(user, amount, gasLimit);
    }
}

/**
 * @title Heavy Local Stake Contract for Testing
 * @notice Extends the LocalStake contract to include gas-intensive operations for testing gas limits and behaviors.
 */
contract HeavyLocalStake is LocalStake {
    constructor(address portal, address _globalManagerContract, uint64 _globalChainId, address _token)
        LocalStake(portal, _globalManagerContract, _globalChainId, _token) {}

    /// @dev Heavily gas consuming unstake operation for demonstration purposes.
    function heavyXUnstake(address user, uint256 amount) external {
        // Introducing heavy computation
        uint256 dummyComputation = 0;
        for (uint256 i = 0; i < 1000; i++) {
            dummyComputation += i;
        }

        _unstake(user, amount);
    }
}

/**
 * @title Test suite for the GlobalManager functionality
 * @dev This contract tests the interaction with the GlobalManager, including chain management and stake handling, using a mock portal for cross-chain simulation.
 */
contract GlobalTest is Test {
    ExposedGlobalManager globalManager;
    MockPortal portal;

    /// @dev Sets up the test environment with GlobalManager and MockPortal
    function setUp() public {
        portal = new MockPortal();
        globalManager = new ExposedGlobalManager(address(portal));
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
        uint64 gasLimit = 50_000;

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

    /// @dev Gas limit test showing global state can change, but stake can fail to go back to user
    function testRemoveStakeWithInsufficientGasLimitFails() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        uint64 insufficientGasLimit = 21_000;

        // initialize basic state for staking contract to show full unstake flow
        LocalToken localToken = new LocalToken();
        HeavyLocalStake localStake = new HeavyLocalStake(
            address(portal),
            address(globalManager),
            chainId,
            address(localToken)
        );
        localToken.transfer(address(localStake), amount);

        // stake using globalManager
        vm.deal(contractAddress, 1 ether);
        globalManager.addChainContract(chainId, contractAddress);
        vm.prank(contractAddress);
        portal.mockXCall(
            chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount)
        );
        assertEq(globalManager.stakeOn(user, chainId), amount, "Initial stake should be correctly set.");

        // unstake using globalManager
        vm.deal(address(globalManager), 1 ether); // Ensures sufficient funds for fee handling
        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "feeFor(uint64,bytes,uint64)", chainId, abi.encodeWithSignature("xunstake(address,uint256)", user, amount), insufficientGasLimit
            )
        );
        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes,uint64)",
                chainId,
                contractAddress,
                abi.encodeWithSignature("xunstake(address,uint256)", user, amount),
                insufficientGasLimit
            )
        );
        vm.prank(contractAddress);
        portal.mockXCall(
            chainId, address(globalManager), abi.encodeWithSelector(globalManager.exposeRemoveStake.selector, user, amount, insufficientGasLimit)
        );

        // user should have modified state on globalManager, no stake left
        assertEq(globalManager.stakeOn(user, chainId), 0, "Stake should be removed successfully.");

        // call fails with gasLimit that is too low for its execution on dest chain
        vm.expectRevert();
        localStake.heavyXUnstake{ gas: insufficientGasLimit }(user, amount);

        assertEq(localToken.balanceOf(address(localStake)), amount, "Staking contract should still hold user stake");
    }
}
