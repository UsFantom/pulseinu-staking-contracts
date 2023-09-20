import "hardhat-deploy";
import "hardhat-deploy-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@typechain/hardhat";
import "hardhat-gas-reporter";
import "solidity-coverage";

// import "./tasks/update";
// import "./tasks/utils";

import { resolve } from "path";

import { config as dotenvConfig } from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import { ChainConfig, CHAINS } from "./tasks/config";

dotenvConfig({ path: resolve(__dirname, "./.env") });

export const chainIds = {
  // Dev
  hardhat: 31337,

  // Test
  goerli: 5,
  bscTest: 97,
  pulseTest: 943,
  sepolia: 11155111,

  // Production
  eth: 1,
  bsc: 56,
  pulse: 369,
};

const getAccounts = (key: keyof ChainConfig) => {
  const ids = Object.keys(CHAINS);
  const accounts: Record<string, string> = {};
  for (let i = 0; i < ids.length; i++) {
    const chainId = ids[i];
    if (chainId in CHAINS) {
      const account = CHAINS[chainId][key];
      if (account) accounts[chainId] = account.toString();
    }
  }
  return accounts;
};

const deployerKey: string = process.env.DEPLOYER_PRIV_KEY || "";
const deployerAddress: string = process.env.DEPLOYER_ADDRESS || "";

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  gasReporter: {
    currency: "USD",
    enabled: true,
    excludeContracts: [],
    src: "./contracts",
  },
  namedAccounts: {
    deployer: {
      default: deployerAddress,
      5: 0,
      31337: 0,
    },
    treasury: getAccounts("TREASURY_ADDRESS"),
    routerAddress: getAccounts("ROUTER_ADDRESS"),
    pinuToken: getAccounts("PINU_TOKEN"),
    daiToken: getAccounts("DAI_TOKEN"),
  },
  networks: {
    hardhat: {
      chainId: chainIds.hardhat,
      allowBlocksWithSameTimestamp: false,
      gas: 8000000,
      forking: {
        url: "https://rpc.ankr.com/eth",
        blockNumber: 17396037,
      },
      mining: {
        auto: true,
        interval: 0,
      },
    },
    eth: {
      accounts: [deployerKey],
      chainId: chainIds["eth"],
      url: `https://eth.public-rpc.com`,
      verify: {
        etherscan: {
          apiKey: process.env.ETH_API_KEY || "",
        },
      },
    },
    goerli: {
      accounts: [deployerKey],
      chainId: chainIds["goerli"],
      url: `https://rpc.ankr.com/eth_goerli`,
      verify: {
        etherscan: {
          apiKey: process.env.ETH_API_KEY || "",
        },
      },
    },
    sepolia: {
      accounts: [deployerKey],
      chainId: chainIds["sepolia"],
      url: `https://rpc.ankr.com/eth_sepolia`,
      verify: {
        etherscan: {
          apiKey: process.env.ETH_API_KEY || "",
        },
      },
    },
    bsc: {
      accounts: [deployerKey],
      chainId: chainIds["bsc"],
      url: "https://bsc-dataseed.binance.org/",
      verify: {
        etherscan: {
          apiKey: process.env.BSCSCAN_API_KEY || "",
        },
      },
    },
    bscTest: {
      accounts: [deployerKey],
      chainId: chainIds["bscTest"],
      url: "https://data-seed-prebsc-1-s1.binance.org:8545/",
      verify: {
        etherscan: {
          apiKey: process.env.BSCSCAN_API_KEY || "",
        },
      },
    },
    pulseTest: {
      accounts: [deployerKey],
      chainId: chainIds["pulseTest"],
      url: "https://rpc.v4.testnet.pulsechain.com",
      verify: {
        etherscan: {
          apiUrl: "https://scan.v4.testnet.pulsechain.com",
        },
      },
    },
    pulse: {
      accounts: [deployerKey],
      chainId: chainIds["pulse"],
      url: "https://rpc.pulsechain.com",
      verify: {
        etherscan: {
          apiUrl: "https://scan.pulsechain.com",
        },
      },
    }
  },
  etherscan: {
    apiKey: {
      pulseTest: process.env.ETH_API_KEY || "",
    },
    customChains: [
      {
        chainId: chainIds["pulseTest"],
        network: "pulseTest",
        urls: {
          apiURL: "https://scan.v4.testnet.pulsechain.com/api",
          browserURL: "https://scan.v4.testnet.pulsechain.com",
        },
      },
    ],
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.18",
    settings: {
      metadata: {
        // Not including the metadata hash
        // https://github.com/paulrberg/solidity-template/issues/31
        bytecodeHash: "none",
      },
      // Disable the optimizer when debugging
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 800,
      },
    },
  },
  typechain: {
    outDir: "src/types",
    target: "ethers-v5",
  },
};

export default config;
