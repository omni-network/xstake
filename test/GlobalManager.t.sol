// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MockPortal} from "../lib/omni/contracts/test/utils/MockPortal.sol";
import {Test,console} from "../lib/forge-std/src/Test.sol";
import {GlobalManager} from "../src/GlobalManager.sol";

contract GlobalTest is Test {
    GlobalManager globalManager;
    MockPortal portal;

    function setUp() public {
        portal = new MockPortal();
        globalManager = new GlobalManager(address(portal));
    }

    function testAddChainContract() public {
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        globalManager.addChainContract(chainId, contractAddress);
        assertEq(globalManager.chainIdToContract(chainId), contractAddress);
    }

    function testAddStakeNotListed() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = portal.chainId();
        vm.deal(user, 1000);
        vm.expectRevert("GlobalManager: chain not found");
        portal.mockXCall(chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount));
    }

    function testAddStakeInvalidSender() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        globalManager.addChainContract(chainId, contractAddress);
        vm.expectRevert("GlobalManager: invalid sender");
        portal.mockXCall(chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount));
        assertEq(globalManager.userToChainIdToStake(user, chainId), 0);
    }

    function testAddStake() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        globalManager.addChainContract(chainId, contractAddress);
        vm.prank(contractAddress);
        portal.mockXCall(chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount));
        assertEq(globalManager.userToChainIdToStake(user, chainId), amount);
    }

    function testRemoveStake() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        vm.deal(contractAddress, 1 ether);
        globalManager.addChainContract(chainId, contractAddress);
        vm.prank(contractAddress);
        portal.mockXCall(chainId, address(globalManager), abi.encodeWithSelector(globalManager.addStake.selector, user, amount));
        assertEq(globalManager.userToChainIdToStake(user, chainId), amount);
        vm.deal(address(globalManager), 1 ether);
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
        vm.prank(contractAddress);
        portal.mockXCall(chainId, address(globalManager), abi.encodeWithSelector(globalManager.removeStake.selector, user, amount));
        assertEq(globalManager.userToChainIdToStake(user, chainId), 0);
    }
}
