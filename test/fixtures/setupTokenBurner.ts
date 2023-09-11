import { ethers, config } from "hardhat";
import { TokenBurner__factory, MockToken__factory } from "../../src/types";

import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { BigNumber } from "ethers";

const ether1 = ethers.utils.parseEther("1");
const ether100 = ethers.utils.parseEther("100");

export async function getForkedChainId() {
  const forkedProvider = ethers.getDefaultProvider(config.networks.hardhat.forking?.url);
  const network = await forkedProvider.getNetwork();
  return network.chainId;
}

export async function setupTokenBurner() {
  const chainId = await getForkedChainId();
  const user0 = ethers.provider.getSigner(0);
  const user0Address = await user0.getAddress();
  // Deploy our contracts

  // Deploy MockToken
  const MockToken = <MockToken_factory>await ethers.getContractFactory("MockToken");
  const mockToken = await MockToken.deploy(
    ethers.utils.parseEther("1000")
  );
  await mockToken.deployed();

  // Deploy Token Burner
  const TokenBurner = <TokenBurner_factory>await ethers.getContractFactory("TokenBurner");
  const tokenBurner = await TokenBurner.deploy(
    mockToken.address
  );
  await tokenBurner.deployed();

  return {
    mockToken,
    tokenBurner,
    chainId,
  };
}
