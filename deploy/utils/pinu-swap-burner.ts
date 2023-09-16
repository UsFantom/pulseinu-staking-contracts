import { BigNumber } from "ethers";
import { DeployFunction } from "hardhat-deploy/dist/types";

const deploy: DeployFunction = async hre => {
  console.log("Deploying PinuSwapBurner...");
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  // console.log("deployer", deployer);

  const result = await deploy("PinuSwapBurner", {
    from: deployer,
    args: [],
  });

  if (result.newlyDeployed) {
    console.log("Deployed at:", result.address);
  }
};

deploy.tags = ["PinuSwapBurner"];

export default deploy;
