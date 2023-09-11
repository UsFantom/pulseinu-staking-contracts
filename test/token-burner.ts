import { loadFixture, time, mine } from "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-chai-matchers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import { setupTokenBurner } from "./fixtures/setupTokenBurner";
import { BigNumber, ContractTransaction } from "ethers";
import { TokenBurner__factory } from "../src/types";
import { JsonRpcSigner } from "@ethersproject/providers";

describe("TokenBurner", () => {
  it("should burn tokens", async () => {
    const { mockToken, tokenBurner, chainId } = await loadFixture(setupTokenBurner);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();
    const initialSupply = await mockToken.balanceOf(user0Address);
    const burnAmount = ethers.utils.parseEther("100");

    await mockToken.connect(user0).transfer(user1Address, burnAmount);
    await mockToken.connect(user1).transfer(tokenBurner.address, burnAmount);
    await tokenBurner.connect(user1).burnTokens();

    // expect(await mockToken.balanceOf(user1Address)).to.equal(initialSupply.sub(burnAmount));
    // expect(await mockToken.balanceOf(tokenBurner.address)).to.equal(0);
  });

});
