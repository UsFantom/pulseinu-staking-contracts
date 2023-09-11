import { BigNumber } from "ethers";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { PulseInu__factory } from "../src/types";

const deploy: DeployFunction = async hre => {
  console.log("Deploying PulseInu...");
  const { deploy } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

  console.log("deployer", deployer);

  const _airdropDuration = 60 * 60 * 24 * 90; // 90 days
  const _mintDuration = 60 * 60 * 24 * 180; // 180 days
  const _firstAdopterPercent = 20; // 0.002% -> 1,000,000 = 100%
  const _referrerPercent = 2000; // 20% -> 10,000 = 100%
  const _price = 10; // 1 PINU = 0.00001 PLS (18 - 5 - 12)
  const _airdropAmount = 1000000000; // 1,000,000,000 PINU

  const args = [
    "PulseInu",
    "PINU",
    _airdropDuration,
    _mintDuration,
    _firstAdopterPercent,
    _referrerPercent,
    _price,
    _airdropAmount,
  ];

  const result = await deploy("PulseInu", {
    from: deployer,
    args: args,
  });

  if (result.newlyDeployed) {
    console.log("Deployed at:", result.address);
  }
};

deploy.tags = ["PulseInu", "PulseInuToken"];

export default deploy;
