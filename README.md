# XStake

Cross-chain staking, built with Omni.

This repository is meant as an example. It demonstrates how to accept ERC20 deposits
chains on multiple chains, and maintain global accounting on Omni.

These contracts are unaudited, and should not be used in production.

## How it works

The protocol has two contracts

- [`XStaker`](./src/XStaker.sol)
- [`XStakeController`](./src/XStakeController.sol)


The first accepts deposits, and pays out withdrawals. The second maintains global accounting, and authorizes withdrawals. To learn how each contract works, read the source code. It's not long, and is commented generously. Read in the following order:


1. [`XStaker.stake`](./src/XStaker.sol#L65)

    Entrypoint for staking. This function accepts deposits, and records them with the `XStakeController` via `xcall`.


2. [`XStakeController.recordStake`](./src/XStakeController.sol#L38)

    Records stake. Only callable by a known `XStaker` contract on a supported chain.

3. [`XStakeController.unstake`](./src/XStakeController.sol#L54)

    Entrypoint for unstaking. This function authorizes withdrawals, and directs a payout to the corresponding `XStaker` via `xcall`.

4. [`XStaker.withdraw`](./src/XStaker.sol#L103)

    Withdraws stake back to the user. Only callable by the `XStakeController`.

## Testing

This example includes example solidity [tests](./test) . They make use of Omni's `MockPortal` utility to test cross chain interactions.

Run tests with

```bash
make test
```


## Try it out

To try out the contracts, you can deploy them to a local Omni devnet.

```bash
make devnet-start
make devnet-deploy
```

This deploys an `XStakeController` to Omni's devnet EVM. Along with an
`XStaker` to each mock rollup - mock arb and mock op. It also deploys an ERC20
staking token to each rollup. This token has a public `mint()` method, so you
can mint tokens to test with.
