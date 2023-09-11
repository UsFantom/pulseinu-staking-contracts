import { loadFixture, time, mine } from "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-chai-matchers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import { setupPulseInu } from "./fixtures/setupPulseInu";
import { BigNumber, ContractTransaction } from "ethers";
import { PulseInu__factory } from "../src/types";
import { JsonRpcSigner } from "@ethersproject/providers";

describe("Certificate", () => {
  it("should mint a new token", async () => {
    const { pulseInu, chainId } = await loadFixture(setupPulseInu);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();
    const tokenId = 0;
    const tokenURI = "https://floki-university/storage/" + tokenId;

    const hashedMessage = await certificateNft.getMessageHash(tokenId, tokenURI);
    const signedMessage = await signMessage(hashedMessage, user0);

    await expect(certificateNft.connect(user0).mint(tokenURI, v, r, s))
      .to.emit(certificateNft, "TokenMinted")
      .withArgs(user0Address, tokenId);

    expect(await certificateNft.ownerOf(tokenId)).to.equal(user0Address);
    expect(await certificateNft.tokenURI(tokenId)).to.equal(tokenURI);
  });

  async function signMessage(message: string, signer: JsonRpcSigner) {
    const messageHash = ethers.utils.arrayify(message);
    const signedMessage = await signer.signMessage(messageHash);
    return signedMessage;
  }
});
