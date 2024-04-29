// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Test,console} from "../lib/forge-std/src/Test.sol";
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
                "feeFor(uint64,bytes,uint64)",
                globalChainId,
                abi.encodeWithSignature("addStake(address,uint256)", user, stakeAmount),
                localStake.ADD_STAKE_GAS()
            )
        );
        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes,uint64)",
                globalChainId,
                globalManagerAddress,
                abi.encodeWithSignature("addStake(address,uint256)", user, stakeAmount),
                localStake.ADD_STAKE_GAS()
            )
        );
        localStake.stake{value: feeAmount}(stakeAmount);
        vm.stopPrank();

        assertEq(localToken.balanceOf(address(localStake)), stakeAmount, "Contract did not receive the stake amount.");
    }

    /// @dev Tests staking with an insufficient fee provided
    function testStakeInsufficientFee() public {
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
    function testUnstake() public {
        uint256 stakeAmount = 100 ether;
        uint256 feeAmount = 1000 gwei;
        address user = address(0xf00);

        vm.deal(user, 3 * feeAmount); // Ensuring sufficient ether for fees
        localToken.transfer(user, stakeAmount);

        vm.startPrank(user);
        localToken.approve(address(localStake), stakeAmount);
        localStake.stake{value: feeAmount}(stakeAmount);

        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes,uint64)",
                globalChainId,
                globalManagerAddress,
                abi.encodeWithSignature("removeStake(address,uint256)", user, stakeAmount),
                localStake.REMOVE_STAKE_GAS()
            )
        );
        localStake.unstake{value: feeAmount}(stakeAmount);
        vm.stopPrank();
    }

    /// @dev Tests unstaking with an insufficient xcall fee, expecting a revert
    function testUnstakeWithInsufficientFee() public {
        uint256 stakeAmount = 100 ether;
        uint256 feeAmount = 1000 gwei;
        uint256 tooLowFeeAmount = 1000 wei;
        address user = address(0xf00);

        vm.deal(user, 3 * feeAmount); // Ensuring sufficient ether for fees
        localToken.transfer(user, stakeAmount);

        vm.startPrank(user);
        localToken.approve(address(localStake), stakeAmount);
        localStake.stake{value: feeAmount}(stakeAmount);

        vm.expectCall(
            address(portal),
            abi.encodeWithSignature(
                "xcall(uint64,address,bytes,uint64)",
                globalChainId,
                globalManagerAddress,
                abi.encodeWithSignature("removeStake(address,uint256)", user, stakeAmount),
                localStake.REMOVE_STAKE_GAS()
            )
        );
        vm.expectRevert("LocalStake: user xcalls gas fee");
        localStake.unstake{value: tooLowFeeAmount}(stakeAmount);
        vm.stopPrank();
    }

    /// @dev Profiles gas usage of xunstake method
    function testXUnstakeGasProfile() public {
        uint256 stakeAmount = 100 ether;
        uint256 feeAmount = 1000 gwei;
        address user = address(0xf00);

        vm.deal(user, 3 * feeAmount); // Ensuring sufficient ether for fees
        localToken.transfer(user, stakeAmount);

        vm.startPrank(user);
        localToken.approve(address(localStake), stakeAmount);
        localStake.stake{value: feeAmount}(stakeAmount);
        vm.stopPrank();

        vm.prank(globalManagerAddress);
        uint256 gasUsed = gasleft(); // start gas measure
        portal.mockXCall(
            globalChainId, address(localStake), abi.encodeWithSelector(localStake.xunstake.selector, user, stakeAmount)
        );
        gasUsed = gasUsed - gasleft();
        console.log("xunstake gas used:", gasUsed); // use this value for gasLimit variable in GlobalManager.removeStake()
        assertTrue(globalManager.XUNSTAKE_GAS() > gasUsed, "xunstake gas usage unexpectedly high");
    }
}
