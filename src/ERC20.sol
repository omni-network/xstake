// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract LocalToken is ERC20 {
    constructor() ERC20("LocalToken", "LT") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}
g