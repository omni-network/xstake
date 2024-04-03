// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.23;

import {XApp} from "omni/contracts/src/pkg/XApp.sol";

/*
 * @title XGreeter
 * @notice A cross chain greeter
 */
contract XGreeter is XApp {
    /// @dev Emitted when someone greets the ether
    event Greetings(address indexed from, uint64 indexed fromChainId, string greeting);

    constructor(address portal) XApp(portal) {}

    /// @dev Greet on another chain
    ///      `feeFor` and `xcall` are inherited from `XApp`
    function xgreet(uint64 destChainId, address to, string calldata greeting) external payable {
        bytes memory data = abi.encodeWithSignature("greet(string)", greeting);

        // calculate xcall fee
        uint256 fee = feeFor(destChainId, data);

        // charge the caller
        require(msg.value >= fee, "XGreeter: insufficient fee");

        // make the xcall
        xcall(destChainId, to, data);
    }

    /// @dev Greet on this chain
    ///      The `xrecv` modifier reads the current xmsg into `xmsg` storage
    function greet(string calldata greeting) external xrecv {
        require(isXCall(), "XGreeter: only xcall");
        emit Greetings(xmsg.sender, xmsg.sourceChainId, greeting);
    }
}
