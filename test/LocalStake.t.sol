// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test, console} from "../lib/forge-std/src/Test.sol";
import {MockPortal} from "../lib/omni/contracts/test/utils/MockPortal.sol";
import {LocalStake} from "../src/LocalStake.sol";
import {GlobalManager} from "../src/GlobalManager.sol";
import {LocalToken} from "../src/LocalToken.sol";

/**
 * @title Test contract for LocalStake functionality
 * @dev This suite tests the staking and unstaking functionality of LocalStake contract, including gas limit handling for cross-chain operations.
 */
contract LocalStakeTest is Test {
    LocalStake localStake;
    MockPortal portal;
    GlobalManager globalManager;
    LocalToken localToken;
    address globalManagerAddress;
    uint64 globalChainId = 165; // Testnet Omni EVM chain ID as reference value

    /// @dev Sets up the testing environment with required contract instances
    function setUp() public {
        portal = new MockPortal();
        globalManager = new GlobalManager(address(portal));
        localToken = new LocalToken();
        globalManagerAddress = address(globalManager);
        localStake = new LocalStake(address(portal), globalManagerAddress, globalChainId, address(localToken));
    }

    /// @dev Tests the stake functionality with the correct fee and amount
    function testStake() public {
        uint256 feeAmount = 1000 gwei;
        uint256 stakeAmount = 100 ether;
        address user = address(0xf00);

        localToken.transfer(user, stakeAmount);
        vm.deal(user, 1 ether); // Make sure the user has enough ether to cover gas and xcall fees
        vm.startPrank(user);
        localToken.approve(address(localStake), stakeAmount);
        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "feeFor(uint64,bytes)",
                globalChainId,
                abi.encodeWithSignature("addStake(address,uint256)", user, stakeAmount)
            )
        );
        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes)",
                globalChainId,
                globalManagerAddress,
                abi.encodeWithSignature("addStake(address,uint256)", user, stakeAmount)
            )
        );
        localStake.stake{value: feeAmount}(stakeAmount);
        vm.stopPrank();

        assertEq(localToken.balanceOf(address(localStake)), stakeAmount, "Contract did not receive the stake amount.");
    }

    /// @dev Tests staking with an insufficient fee provided
    function testInsufficientFee() public {
        uint256 feeAmount = 1000 wei;
        uint256 stakeAmount = 1000000;
        address user = address(0xf00);

        localToken.transfer(user, stakeAmount);
        vm.deal(user, 1 ether); // Providing enough ether to simulate realistic test conditions
        vm.startPrank(user);
        localToken.approve(address(localStake), stakeAmount);
        vm.expectRevert("XApp: insufficient funds");
        localStake.stake{value: feeAmount}(stakeAmount);
        vm.stopPrank();
    }

    /// @dev Tests unstaking with a sufficient gas limit
    function testUnstakeWithSufficientGas() public {
        uint256 unstakeAmount = 100 ether;
        uint256 feeAmount = 1000 gwei;
        uint64 gasLimit = 500000;  // A typical gas limit sufficient for the operation
        address user = address(0xf00);

        vm.deal(user, 3 * feeAmount); // Ensuring sufficient ether for fees
        localToken.transfer(user, unstakeAmount);
        vm.startPrank(user);
        localToken.approve(address(localStake), unstakeAmount);
        localStake.stake{value: feeAmount}(unstakeAmount);

        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes,uint64)",
                globalChainId,
                globalManagerAddress,
                abi.encodeWithSignature("removeStake(address,uint256)", user, unstakeAmount),
                gasLimit
            )
        );
        localStake.unstake{value: feeAmount}(unstakeAmount, gasLimit);
        vm.stopPrank();
    }

    /// @dev Tests unstaking with an insufficient gas limit, expecting a revert
    function testUnstakeWithInsufficientGas() public {
        uint256 unstakeAmount = 100 ether;
        uint256 feeAmount = 1000 gwei;
        uint64 gasLimit = 21_000;  // insufficient gas limit for operation, passes basic min amount check
        address user = address(0xf00);

        vm.deal(user, feeAmount + 1 ether); // Providing enough ether for potential gas costs

        localToken.transfer(user, unstakeAmount);
        vm.startPrank(user);
        localToken.approve(address(localStake), unstakeAmount);
        localStake.stake{value: feeAmount}(unstakeAmount);

        vm.expectRevert("LocalStake: gasLimit too low");
        localStake.unstake{value: feeAmount}(unstakeAmount, gasLimit);
        vm.stopPrank();
    }
}
