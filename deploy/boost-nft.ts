import { BigNumber, ethers } from "ethers";
import { DeployFunction } from "hardhat-deploy/dist/types";
import { BoostNft__factory, MockERC20__factory } from "../src/types";

const deploy: DeployFunction = async hre => {
  console.log("Deploying BoostNft...");
  const { deploy, get } = hre.deployments;
  const { deployer, pulseInu } = await hre.getNamedAccounts();

  //   console.log("deployer", deployer);

  let pulseInuAddress = pulseInu;
  if (!pulseInuAddress) {
    const MockERC20 = await get("MockERC20");
    pulseInuAddress = MockERC20.address;
  }

  const name = "BoostNft";
  const symbol = "BNFT";
  const baseUri = "https://nftstorage.link/ipfs/bafybeiccq4iah4osmiszzlmfp6iqvw6o2pzhqjokhcdo4p7jlx4utstsdi/";
  const legendaryPrice = ethers.utils.parseUnits("5000000000", 12);
  const collectorPrice = ethers.utils.parseUnits("1000000000", 12);
  const result = await deploy("BoostNft", {
    from: deployer,
    args: [name, symbol, baseUri, legendaryPrice, collectorPrice, pulseInuAddress],
  });

  if (result.newlyDeployed) {
    console.log("Deployed at:", result.address);
  }
};

deploy.tags = ["PulseInu", "BoostNft"];
deploy.dependencies = ["MockERC20"];

export default deploy;
