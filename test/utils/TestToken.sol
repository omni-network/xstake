// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.25;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract TestToken is ERC20 {
    constructor() ERC20("Test Token", "TT") {}

    /// @dev Expose mint for dev / testing purposes.
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
