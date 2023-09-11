import { ethers, config } from "hardhat";
import { PulseInu__factory } from "../../src/types";

import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { BigNumber } from "ethers";

const ether1 = ethers.utils.parseEther("1");
const ether100 = ethers.utils.parseEther("100");

export async function getForkedChainId() {
  const forkedProvider = ethers.getDefaultProvider(config.networks.hardhat.forking?.url);
  const network = await forkedProvider.getNetwork();
  return network.chainId;
}

export async function setupPulseInu() {
  const chainId = await getForkedChainId();
  const user0 = ethers.provider.getSigner(0);
  const user0Address = await user0.getAddress();
  // Deploy our contracts

  // Deploy PulseInu
  const _airdropDuration = 60 * 60 * 24 * 90; // 90 days
  const _mintDuration = 60 * 60 * 24 * 180; // 180 days
  const _firstAdopterPercent = 20; // 0.002% -> 1,000,000 = 100%
  const _referrerPercent = 2000; // 20% -> 10,000 = 100%
  const _price = 10; // 1 PINU = 0.00001 PLS (18 - 5 - 12)
  const _airdropAmount = 1000000000; // 1,000,000,000 PINU

  const PulseInu = <PulseInu_factory>await ethers.getContractFactory("PulseInu");
  const pulseInu = await PulseInu.deploy(
    "PulseInu",
    "PINU",
    _airdropDuration,
    _mintDuration,
    _firstAdopterPercent,
    _referrerPercent,
    _price,
    _airdropAmount
  );
  await pulseInu.deployed();

  return {
    pulseInu,
    chainId,
  };
}
