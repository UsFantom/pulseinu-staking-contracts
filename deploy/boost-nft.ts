import { BigNumber, ethers } from "ethers";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { BoostNft__factory } from "../src/types";

const deploy: DeployFunction = async hre => {
  console.log("Deploying BoostNft...");
  const { deploy, get } = hre.deployments;
  const { deployer } = await hre.getNamedAccounts();

//   console.log("deployer", deployer);

  const PulseInu = await get("PulseInu");

  const name = "BoostNft";
  const symbol = "BNFT";
  const baseUri = "https://nftstorage.link/ipfs/bafybeiccq4iah4osmiszzlmfp6iqvw6o2pzhqjokhcdo4p7jlx4utstsdi/";
  const legendaryPrice = ethers.utils.parseEther("5000000000");
  const collectorPrice = ethers.utils.parseEther("1000000000");
  const result = await deploy("BoostNft", {
    from: deployer,
    args: [name, symbol, baseUri, legendaryPrice, collectorPrice, PulseInu.address],
  });

  if (result.newlyDeployed) {
    console.log("Deployed at:", result.address);
  }
};

deploy.tags = ["PulseInu", "BoostNft"];
deploy.dependencies = ["PulseInuToken"];

export default deploy;
