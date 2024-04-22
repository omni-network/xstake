// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/**
 * @title LocalToken Contract
 * @dev A contract for the ERC20 token on the rollup chain.
 */
contract LocalToken is ERC20 {
    /**
     * @dev Constructor function that initializes the LocalToken contract with specific name and symbol.
     * @notice Mints 1,000,000 LT tokens to the deploying account.
     */
    constructor() ERC20("LocalToken", "LT") {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }
}
