import { ethers } from "ethers";

export type ChainConfig = {

  TREASURY_ADDRESS: string;
  ROUTER_ADDRESS: string;
  V3_ROUTER_ADDRESS: string;
  V3_NFT_ADDRESS: string;
  PINU_TOKEN: string;
  USDT_TOKEN: string;
  EXEMPT_NFT_CONTRACTS: string[];

  GNOSIS_SERVICE_URL: string;

  CHAINLINK_FEED_REGISTRY?: string;
  DIA_ORACLE: string;
  PYTH_ORACLE: string;

  TEST_ERC20_1_CHAINLINK_FEED?: string;
};

export const CHAINS: Record<string, ChainConfig> = {
  "1": {
    TREASURY_ADDRESS: "0xf5d492fFBeC47DB69333A6812bEc227B6f670A86",
    ROUTER_ADDRESS: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
    V3_ROUTER_ADDRESS: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    V3_NFT_ADDRESS: "0xc36442b4a4522e871399cd717abdd847ab11fe88",
    USDT_TOKEN: "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT
    EXEMPT_NFT_CONTRACTS: [
      "0x0398947346144d39e1983c3d9a63248a2655ec00",
      "0x177312b692F92f1D2498637fcFC90B79b1FC7719",
      "0x90Ff5796b1e7711F1b13afd69D2E36e28A60C708",
      "0x1E18de8a026A1CAB515E105A26eA95Cf35300037",
      "0x064F9547a78bD5Ba35a7aEB2221DE69b86CD6307",
    ],
    GNOSIS_SERVICE_URL: "https://safe-transaction.gnosis.io",

    CHAINLINK_FEED_REGISTRY: "0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf",
    DIA_ORACLE: "0xa93546947f3015c986695750b8bbea8e26d65856",
    PYTH_ORACLE: "0x4305FB66699C3B2702D4d05CF36551390A4c69C6",

    TEST_ERC20_1_CHAINLINK_FEED: "0x553303d460EE0afB37EdFf9bE42922D8FF63220e",
  },
  "369": {
    TREASURY_ADDRESS: "0xf5d492fFBeC47DB69333A6812bEc227B6f670A86",
    ROUTER_ADDRESS: "0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02",
    V3_ROUTER_ADDRESS: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    V3_NFT_ADDRESS: "0xc36442b4a4522e871399cd717abdd847ab11fe88",
    PINU_TOKEN: "0xa12E2661ec6603CBbB891072b2Ad5b3d5edb48bd", // PINU
    USDT_TOKEN: "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT
    EXEMPT_NFT_CONTRACTS: [],
    GNOSIS_SERVICE_URL: "https://safe-transaction.gnosis.io",

    CHAINLINK_FEED_REGISTRY: "0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf",
    DIA_ORACLE: "0xa93546947f3015c986695750b8bbea8e26d65856",
    PYTH_ORACLE: "0x4305FB66699C3B2702D4d05CF36551390A4c69C6",

    TEST_ERC20_1_CHAINLINK_FEED: "0x553303d460EE0afB37EdFf9bE42922D8FF63220e",
  },
  "943": {
    TREASURY_ADDRESS: "0xf5d492fFBeC47DB69333A6812bEc227B6f670A86",
    ROUTER_ADDRESS: "0xDaE9dd3d1A52CfCe9d5F2fAC7fDe164D500E50f7",
    V3_ROUTER_ADDRESS: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    V3_NFT_ADDRESS: "0xc36442b4a4522e871399cd717abdd847ab11fe88",
    PINU_TOKEN: "0xa12E2661ec6603CBbB891072b2Ad5b3d5edb48bd", // PINU
    USDT_TOKEN: "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT
    EXEMPT_NFT_CONTRACTS: [],
    GNOSIS_SERVICE_URL: "https://safe-transaction.gnosis.io",

    CHAINLINK_FEED_REGISTRY: "0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf",
    DIA_ORACLE: "0xa93546947f3015c986695750b8bbea8e26d65856",
    PYTH_ORACLE: "0x4305FB66699C3B2702D4d05CF36551390A4c69C6",

    TEST_ERC20_1_CHAINLINK_FEED: "0x553303d460EE0afB37EdFf9bE42922D8FF63220e",
  },
  "31337": {
    TREASURY_ADDRESS: "0xf5d492fFBeC47DB69333A6812bEc227B6f670A86",
    ROUTER_ADDRESS: "0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D",
    V3_ROUTER_ADDRESS: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    V3_NFT_ADDRESS: "0xc36442b4a4522e871399cd717abdd847ab11fe88",
    USDT_TOKEN: "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT
    EXEMPT_NFT_CONTRACTS: [],
    GNOSIS_SERVICE_URL: "https://safe-transaction.gnosis.io",

    CHAINLINK_FEED_REGISTRY: "0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf",
    DIA_ORACLE: "0xa93546947f3015c986695750b8bbea8e26d65856",
    PYTH_ORACLE: "0x4305FB66699C3B2702D4d05CF36551390A4c69C6",

    TEST_ERC20_1_CHAINLINK_FEED: "0x553303d460EE0afB37EdFf9bE42922D8FF63220e",
  },
};
