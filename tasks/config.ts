import { ethers } from "ethers";

export type ChainConfig = {

  TREASURY_ADDRESS: string;
  ROUTER_ADDRESS: string;
  V3_ROUTER_ADDRESS: string;
  V3_NFT_ADDRESS: string;
  PINU_TOKEN: string;
  USDT_TOKEN: string;
  DAI_TOKEN: string;
  EXEMPT_NFT_CONTRACTS: string[];

  GNOSIS_SERVICE_URL: string;

  CHAINLINK_FEED_REGISTRY?: string;
  DIA_ORACLE: string;
  PYTH_ORACLE: string;

  TEST_ERC20_1_CHAINLINK_FEED?: string;
};

export const CHAINS: Record<string, ChainConfig> = {
  "369": {
    TREASURY_ADDRESS: "0xf5d492fFBeC47DB69333A6812bEc227B6f670A86",
    ROUTER_ADDRESS: "0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02",
    V3_ROUTER_ADDRESS: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    V3_NFT_ADDRESS: "0xc36442b4a4522e871399cd717abdd847ab11fe88",
    PINU_TOKEN: "0xa12E2661ec6603CBbB891072b2Ad5b3d5edb48bd", // PINU
    USDT_TOKEN: "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT
    DAI_TOKEN: "0xefD766cCb38EaF1dfd701853BFCe31359239F305", // DAI
    EXEMPT_NFT_CONTRACTS: [],
    GNOSIS_SERVICE_URL: "https://safe-transaction.gnosis.io",

    CHAINLINK_FEED_REGISTRY: "0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf",
    DIA_ORACLE: "0xa93546947f3015c986695750b8bbea8e26d65856",
    PYTH_ORACLE: "0x4305FB66699C3B2702D4d05CF36551390A4c69C6",

    TEST_ERC20_1_CHAINLINK_FEED: "0x553303d460EE0afB37EdFf9bE42922D8FF63220e",
  },
  "943": {
    TREASURY_ADDRESS: "0xf5d492fFBeC47DB69333A6812bEc227B6f670A86",
    ROUTER_ADDRESS: "0x636f6407B90661b73b1C0F7e24F4C79f624d0738",
    V3_ROUTER_ADDRESS: "0xE592427A0AEce92De3Edee1F18E0157C05861564",
    V3_NFT_ADDRESS: "0xc36442b4a4522e871399cd717abdd847ab11fe88",
    PINU_TOKEN: "0x6eB0864C8568dC4361CC8A56703F154cC44dF353", // PINU
    USDT_TOKEN: "0xdAC17F958D2ee523a2206206994597C13D831ec7", // USDT
    DAI_TOKEN: "0x826e4e896cc2f5b371cd7bb0bd929db3e3db67c0", // tDAI
    EXEMPT_NFT_CONTRACTS: [],
    GNOSIS_SERVICE_URL: "https://safe-transaction.gnosis.io",

    CHAINLINK_FEED_REGISTRY: "0x47Fb2585D2C56Fe188D0E6ec628a38b74fCeeeDf",
    DIA_ORACLE: "0xa93546947f3015c986695750b8bbea8e26d65856",
    PYTH_ORACLE: "0x4305FB66699C3B2702D4d05CF36551390A4c69C6",

    TEST_ERC20_1_CHAINLINK_FEED: "0x553303d460EE0afB37EdFf9bE42922D8FF63220e",
  },
};
