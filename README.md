# Omni Forge Template

This repository serves as a template for Ethereum smart contract development using Foundry, specifically designed for projects intending to utilize the Omni protocol for cross-chain interactions. The template features the `XGreeter` contract as an example to demonstrate how contracts can interact across different blockchain networks.

## Getting Started

To use this template for your project, initialize a new project with Foundry by running the following within your project directory:

```bash
forge init --template https://github.com/omni-network/omni-forge-template.git
```

### Cloning the Template

To clone this template along with its dependencies, use the following command:

```bash
git clone --recursive https://github.com/omni-network/omni-forge-template.git
```

If you've already cloned the repository without submodules, initialize and update them with:

```bash
git submodule update --init --recursive
```

## Compiling Contracts

After initializing your project with this template, compile the smart contracts using:

```bash
forge build
```

## Running Tests

This template includes tests for the `XGreeter` contract. Run these tests to ensure everything is set up correctly:

```bash
forge test
```

## Contributing

Contributions to this template are welcome. To contribute:

1. Fork the repository.
2. Create a new branch for your feature (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -am 'feat(dir): Add some amazing feature'`).
4. Push to the branch (`git push origin feature/amazing-feature`).
5. Open a pull request.

## Acknowledgments

- This template is designed for developers looking to explore cross-chain capabilities with the Omni protocol.
- Special thanks to the Foundry team for providing such a powerful tool for smart contract development.
