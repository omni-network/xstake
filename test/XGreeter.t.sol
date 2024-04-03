// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {MockPortal} from "omni/contracts/test/utils/MockPortal.sol";
import {Test} from "forge-std/Test.sol";
import {XGreeter} from "../src/XGreeter.sol";

contract XGreeterTest is Test {
    event Greetings(address indexed from, uint64 indexed fromChainId, string greeting);

    XGreeter public xgreeter;
    MockPortal public portal;

    function setUp() public {
        portal = new MockPortal();
        xgreeter = new XGreeter(address(portal));
    }

    // @dev Test that xgreet makes the expected xcall
    function test_xgreet_succeeds() public {
        // xgreet params
        uint64 destChainId = 1;
        address to = address(0xdead);
        string memory greeting = "Hello, blockchain!";

        // calculate xcall fee
        bytes memory expectedXCallData = abi.encodeWithSignature("greet(string)", greeting);
        uint256 fee = portal.feeFor(destChainId, expectedXCallData);

        // assert xgreet(...) calls portal.xcall(...) appropriately
        vm.expectCall(
            address(portal),
            fee,
            abi.encodeWithSignature("xcall(uint64,address,bytes)", destChainId, to, expectedXCallData)
        );
        xgreeter.xgreet{value: fee}(destChainId, to, greeting);
    }

    // @dev Test that xgreet reverts if the fee is insufficient
    function test_xgreet_insufficientFee_reverts() public {
        vm.expectRevert("XGreeter: insufficient fee");
        xgreeter.xgreet(1, address(0xdead), "doesn't matter");
    }

    /// @dev Test that an xcall to greet() succeeds
    function test_greet_xcall_succeeds() public {
        uint64 sourceChainId = 1;
        address sender = address(0xdead);
        string memory greeting = "Hello, blockchain!";

        vm.expectEmit();
        emit Greetings(sender, sourceChainId, greeting);

        // use portal.mockXCall to simulate an xcall to xgreeter.greet(...)
        vm.prank(sender);
        portal.mockXCall(sourceChainId, sender, address(xgreeter), abi.encodeWithSignature("greet(string)", greeting));
    }

    /// @dev Test that call to greet() must be an xcall
    function test_greet_notXCall_reverts() public {
        vm.expectRevert("XGreeter: only xcall");
        xgreeter.greet("doesn't matter");
    }
}
