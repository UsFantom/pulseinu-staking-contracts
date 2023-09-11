import { BigNumber } from "ethers";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { TokenBurner__factory } from "../src/types";

const deploy: DeployFunction = async hre => {
  console.log("Deploying TokenBurner...");
  const { deploy, get } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  console.log("deployer", deployer);

  const PulseInu = await get("PulseInu");

  const result = await deploy("TokenBurner", {
    from: deployer,
    args: [PulseInu.address],
  });

  if (result.newlyDeployed) {
    console.log("Deployed at:", result.address);
  }
};

deploy.tags = ["PulseInu", "TokenBurner"];
deploy.dependencies = ["PulseInuToken"];

export default deploy;
