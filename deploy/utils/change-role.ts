import { BigNumber, ethers } from "ethers";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { StakingPool__factory, BoostNft__factory } from "../src/types";

const deploy: DeployFunction = async hre => {
  console.log("Deploying StakingPool...");
  const { deploy, get } = hre.deployments;
  const { deployer, pinuToken, routerAddress, daiToken } = await hre.getNamedAccounts();

  console.log("deployer", deployer);

  const BoostNft = await get("BoostNft");
  const boostNftFactory = <BoostNft__factory>await hre.ethers.getContractFactory("BoostNft");
  const boostNft = boostNftFactory.attach(BoostNft.address);
  const signer = boostNftFactory.signer;

  const StakingPool = await get("StakingPool");
  const stakingPoolFactory = <StakingPool__factory>await hre.ethers.getContractFactory("StakingPool");
  const stakingPool = stakingPoolFactory.attach(StakingPool.address, signer);

  const newAdminAddress = "0x3f5983508E876795731184648DCd0e06F1BDc9a9";

  // granting admin role of the staking pool contract to the new admin address
  console.log("Granting admin role of the staking pool contract to the new admin address...");
  // if the new admin address doesn't have the admin role, grant it
  const hasAdminRole = await stakingPool.hasRole(await stakingPool.DEFAULT_ADMIN_ROLE(), newAdminAddress);
  if (!hasAdminRole) {
    let tx = await stakingPool.grantRole(await stakingPool.DEFAULT_ADMIN_ROLE(), newAdminAddress);
    await tx.wait();
  }
  console.log("Granted admin role of the staking pool contract to the new admin address");
  // renounce the admin role from the deployer address
  console.log("Renouncing admin role of the staking pool contract from the deployer address...");
  // if the deployer address has the admin role, renounce it
  const hasDeployerAdminRole = await stakingPool.hasRole(await stakingPool.DEFAULT_ADMIN_ROLE(), deployer);
  if (hasDeployerAdminRole) {
    let tx = await stakingPool.renounceRole(await stakingPool.DEFAULT_ADMIN_ROLE(), deployer);
    await tx.wait();
  }
  console.log("Renounced admin role of the staking pool contract from the deployer address");

  // granting admin role of the boost nft contract to the new admin address
  console.log("Granting admin role of the boost nft contract to the new admin address...");
  // if the new admin address doesn't have the admin role, grant it
  const hasBoostNftAdminRole = await boostNft.hasRole(await boostNft.DEFAULT_ADMIN_ROLE(), newAdminAddress);
  if (!hasBoostNftAdminRole) {
    let tx = await boostNft.grantRole(await boostNft.DEFAULT_ADMIN_ROLE(), newAdminAddress);
    await tx.wait();
  }
  console.log("Granted admin role of the boost nft contract to the new admin address");
  // renounce admin role of the boost nft contract
  console.log("Renouncing admin role of the boost nft contract from the deployer address...");
  // if the deployer address has the admin role, renounce it
  const hasDeployerBoostNftAdminRole = await boostNft.hasRole(await boostNft.DEFAULT_ADMIN_ROLE(), deployer);
  if (hasDeployerBoostNftAdminRole) {
    let tx = await boostNft.renounceRole(await boostNft.DEFAULT_ADMIN_ROLE(), deployer);
    await tx.wait();
  }
  console.log("Renounced admin role of the boost nft contract from the deployer address");
};

deploy.tags = ["ChangeRole"];
deploy.dependencies = ["StakingPool"];

export default deploy;
