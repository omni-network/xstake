// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {MockPortal} from "../lib/omni/contracts/test/utils/MockPortal.sol";
import {Test,console} from "../lib/forge-std/src/Test.sol";
import {OmniAdmin} from "../src/Admin.sol";

contract AdminTest is Test {
    OmniAdmin admin;
    MockPortal portal;

    function setUp() public {
        portal = new MockPortal();
        admin = new OmniAdmin(address(portal));
    }

    function testAddChainContract() public {
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        admin.addChainContract(chainId, contractAddress);
        assertEq(admin.chainIds(0), chainId);
        assertEq(admin.chainIdContracts(chainId), contractAddress);
    }

    function testAddStakeNotListed() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = portal.chainId();
        vm.deal(user, 1000);
        vm.expectRevert("OmniAdmin: chain not found");
        portal.mockXCall(chainId, address(admin), abi.encodeWithSelector(admin.addStake.selector, user, amount));
    }

    function testAddStakeInvalidSender() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        admin.addChainContract(chainId, contractAddress);
        vm.expectRevert("OmniAdmin: invalid sender");
        portal.mockXCall(chainId, address(admin), abi.encodeWithSelector(admin.addStake.selector, user, amount));
        assertEq(admin.userChainIdStakes(user, chainId), 0);
    }

    function testAddStake() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        admin.addChainContract(chainId, contractAddress);
        vm.prank(contractAddress);
        portal.mockXCall(chainId, address(admin), abi.encodeWithSelector(admin.addStake.selector, user, amount));
        assertEq(admin.userChainIdStakes(user, chainId), amount);
    }

    function testRemoveStake() public {
        uint256 amount = 100;
        address user = address(0x123);
        uint64 chainId = 1;
        address contractAddress = address(0x123);
        vm.deal(contractAddress, 1 ether);
        admin.addChainContract(chainId, contractAddress);
        vm.prank(contractAddress);
        portal.mockXCall(chainId, address(admin), abi.encodeWithSelector(admin.addStake.selector, user, amount));
        assertEq(admin.userChainIdStakes(user, chainId), amount);
        vm.deal(address(admin), 1 ether);
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
        portal.mockXCall(chainId, address(admin), abi.encodeWithSelector(admin.removeStake.selector, user, amount));
        assertEq(admin.userChainIdStakes(user, chainId), 0);
    }
}
