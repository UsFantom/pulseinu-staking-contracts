import { BigNumber } from "ethers";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { MockERC20__factory } from "../src/types";

const deploy: DeployFunction = async hre => {
  console.log("Deploying MockERC20...");
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  // console.log("deployer", deployer);

  const initialSupply = ethers.utils.parseUnits("1000000000000", 12);
  const args = [
    "MockERC20",
    "PINU",
    initialSupply,
  ];

  const result = await deploy("MockERC20", {
    from: deployer,
    args: args,
  });

  if (result.newlyDeployed) {
    console.log("Deployed at:", result.address);
  }
};

deploy.tags = ["PulseInu", "MockERC20"];

export default deploy;
