import { resolve } from "path";

import { config as dotenvConfig } from "dotenv";
import hardhatConfig, { chainIds } from "./hardhat.config";

dotenvConfig({ path: resolve(__dirname, "./.env") });

if (hardhatConfig.networks?.hardhat) {
  hardhatConfig.networks.hardhat = {
    chainId: chainIds.hardhat,
    forking: {
      url: `https://rpc.v4.testnet.pulsechain.com`,
      blockNumber: 17553929,
    },
  };
}

export default hardhatConfig;
