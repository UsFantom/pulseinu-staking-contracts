# PulseInu Staking Contracts

![License](https://img.shields.io/badge/license-MIT-blue.svg)

Welcome to the PulseInu Staking Contracts repository. This repository contains the smart contracts for the PulseInu staking platform, which enables users to stake tokens and earn rewards.

## Table of Contents

- [Getting Started](#getting-started)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Testing](#testing)
- [Contributing](#contributing)
- [License](#license)

## Getting Started

These instructions will help you set up and deploy the PulseInu staking contracts on the Ethereum blockchain.

### Prerequisites

Before you begin, make sure you have the following software installed:

- [Node.js](https://nodejs.org/)
- [Yarn](https://classic.yarnpkg.com/en/docs/install)
- [Hardhat](https://hardhat.org/)

### Installation

1. Clone the repository to your local machine:

   ```bash
   git clone https://github.com/ricknightcrypto/Pulse-Inu-staking-contracts
   cd Pulse-Inu-staking-contracts
   ```

2. Install the project dependencies:

   ```bash
   yarn install
   ```

### Usage

To compile and deploy the PulseInu staking contracts, follow these steps:

1. Configure your Ethereum wallet and network settings in the `.env` file.

2. Compile the contracts:

   ```bash
   yarn compile
   ```

3. Deploy the staking contracts to the Pulse chain testnet v4 network:

   ```bash
   yarn hardhat deploy --network pulseTest --tags StakingPool
   ```
4. Verify the contracts to the Pulse chain testnet v4 network:

   ```bash
   yarn hardhat etherscan-verify --network pulseTest
   ```

5. Interact with the deployed contracts using the provided JavaScript/TypeScript APIs.

### Testing

You can run tests for the PulseInu staking contracts by executing the following command:

```bash
yarn test:staking-pool
```

### Contributing

If you would like to contribute to this project, please follow these steps:

1. Fork the repository.

2. Create a new branch for your feature or bug fix:

   ```bash
   git checkout -b feature-name
   ```

3. Make your changes and commit them:

   ```bash
   git commit -m "Add your commit message here"
   ```

4. Push the changes to your fork:

   ```bash
   git push origin feature-name
   ```

5. Create a pull request to the `main` branch of the original repository.

6. Your pull request will be reviewed, and once approved, it will be merged.

### License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
