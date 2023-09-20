import { BigNumber, ethers } from "ethers";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { StakingPool__factory, BoostNft__factory } from "../src/types";

const deploy: DeployFunction = async hre => {
  console.log("Deploying StakingPool...");
  const { deploy, get } = hre.deployments;
  const { deployer, pinuToken, routerAddress, daiToken } = await hre.getNamedAccounts();

  // console.log("deployer", deployer);

  let pulseInuAddress = pinuToken;
  if (!pulseInuAddress) {
    console.log("PulseInu contract not found, using MockERC20...");
    const MockERC20 = await get("MockERC20");
    pulseInuAddress = MockERC20.address;
  }

  const BoostNft = await get("BoostNft");

  const boostNftFactory = <BoostNft__factory>await hre.ethers.getContractFactory("BoostNft");
  const boostNft = boostNftFactory.attach(BoostNft.address);
  const signer = boostNftFactory.signer;

  // stakingFee is the amount of PLS
  const stakingFee = ethers.utils.parseEther("100000");
  // shareRate is 1.5
  const shareRate = 15000;
  const result = await deploy("StakingPool", {
    from: deployer,
    args: [pulseInuAddress, routerAddress, daiToken, BoostNft.address, stakingFee, shareRate],
  });

  const stakingPool = StakingPool__factory.connect(result.address, signer);
  if (result.newlyDeployed) {
    console.log("Deployed at:", result.address);

    // set staking pool address to the boost nft contract
    console.log("Setting staking pool address to the boost nft contract...");
    let tx = await boostNft.setStakingPool(result.address);
    await tx.wait();

    // grant modify staking role to the nft contract
    console.log("Granting modify staking role to the boost nft contract...");
    tx = await stakingPool.grantRole(await stakingPool.STAKING_MODIFY_ROLE(), BoostNft.address);
    await tx.wait();
    console.log("Granted modify staking role to the boost nft contract");
  }
};

deploy.tags = ["PulseInu", "StakingPool"];
deploy.dependencies = ["BoostNft"];

export default deploy;
