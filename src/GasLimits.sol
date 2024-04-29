// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.25;

/**
 * @title Gas Limits for Cross-Chain Operations
 * @notice This abstract contract defines gas limits used in cross-chain operations.
 * @dev These constants and variables are set based on empirical values observed during testing.
 *      They are used to ensure successful execution of cross-chain calls by providing enough gas.
 */
abstract contract GasLimits {
    /**
     * @notice Maximum gas used for delegating unstaking operations via cross-chain communication.
     * @dev This value is derived from test results in LocalStakeTest.testXUnstakeGasProfile().
     */
    uint64 public constant XUNSTAKE_GAS = 90_000;

    /**
     * @notice Maximum gas limit for adding stake in cross-chain operations.
     * @dev This value is derived from test results in GlobalManagerTest.testAddStakeProfileGas().
     */
    uint64 public ADD_STAKE_GAS = 110_000;

    /**
     * @notice Maximum gas limit for removing stake in cross-chain operations.
     * @dev This value is derived from test results in GlobalManagerTest.testRemoveStakeProfileGas().
     */
    uint64 public REMOVE_STAKE_GAS = 90_000;
}
