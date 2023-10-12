import { ethers, config } from "hardhat";
import { IPulseXRouter02__factory, StakingPool__factory, BoostNft__factory, MockERC20__factory } from "../../src/types";

import { loadFixture, time } from "@nomicfoundation/hardhat-network-helpers";
import { BigNumber } from "ethers";
import { CHAINS } from "../../tasks/config";

const ether1 = ethers.utils.parseEther("1");
const ether100 = ethers.utils.parseEther("100");

export async function getForkedChainId() {
  const forkedProvider = ethers.getDefaultProvider(config.networks.hardhat.forking?.url);
  const network = await forkedProvider.getNetwork();
  return network.chainId;
}

export async function setupStakingPool() {
  const chainId = await getForkedChainId();
  const user0 = ethers.provider.getSigner(0);
  const user0Address = await user0.getAddress();
  // Deploy our contracts

  // Deploy MockERC20
  const MockERC20 = <MockERC20__factory>await ethers.getContractFactory("MockERC20");
  const pinuToken = await MockERC20.deploy("MockToken", "MTK", ethers.utils.parseUnits("1000000000000", 12));
  await pinuToken.deployed();

  let routerAddress;
  let daiToken;
  if (chainId in CHAINS) {
    routerAddress = CHAINS[chainId].ROUTER_ADDRESS;
    daiToken = CHAINS[chainId].DAI_TOKEN;

    // add a liquidity with pinuToken and daiToken
    const pulseXRouter02 = IPulseXRouter02__factory.connect(routerAddress, user0);
    const deadline = (await time.latest()) + 1000;
    await pinuToken.approve(routerAddress, ether100);
    await pulseXRouter02.addLiquidityETH(
      pinuToken.address,
      ether100,
      ether1,
      ether1,
      user0Address,
      deadline,
      { value: ether1 },
    );
  } else {
    routerAddress = ethers.constants.AddressZero;
    daiToken = ethers.constants.AddressZero;
  }

  // Deploy BoostNft
  const BoostNft = <BoostNft__factory>await ethers.getContractFactory("BoostNft");
  const name = "BoostNft";
  const symbol = "BNFT";
  const baseURI = "https://nftstorage.link/ipfs/bafybeiccq4iah4osmiszzlmfp6iqvw6o2pzhqjokhcdo4p7jlx4utstsdi/";
  const legendaryPrice = ethers.utils.parseUnits("5000000000", 12);
  const collectorPrice = ethers.utils.parseUnits("1000000000", 12);
  const boostNft = await BoostNft.deploy(name, symbol, baseURI, legendaryPrice, collectorPrice, pinuToken.address);
  await boostNft.deployed();

  // Deploy StakingPool
  const stakingFee = ethers.utils.parseEther("1");
  const shareRate = 15000;
  const StakingPool = <StakingPool__factory>await ethers.getContractFactory("StakingPool");
  const stakingPool = await StakingPool.deploy(
    pinuToken.address,
    routerAddress,
    daiToken,
    boostNft.address,
    stakingFee,
    shareRate,
  );
  await stakingPool.deployed();
  const startsAt = await stakingPool.startsAt();

  // set staking pool address and grant modify staking role to the boost nft contract
  let tx = await boostNft.setStakingPool(stakingPool.address);
  await tx.wait();
  tx = await stakingPool.grantRole(await stakingPool.STAKING_MODIFY_ROLE(), boostNft.address);
  await tx.wait();

  return {
    pinuToken,
    boostNft,
    startsAt,
    stakingFee,
    stakingPool,
    chainId,
  };
}
