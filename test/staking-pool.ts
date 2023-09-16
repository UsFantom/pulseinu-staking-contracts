import { loadFixture, time, mine } from "@nomicfoundation/hardhat-network-helpers";
import "@nomicfoundation/hardhat-chai-matchers";
import { expect } from "chai";
import { ethers, network } from "hardhat";
import { setupStakingPool } from "./fixtures/setupStakingPool";
import { BigNumber, ContractTransaction } from "ethers";
import { StakingPool__factory } from "../src/types";
import { JsonRpcSigner } from "@ethersproject/providers";

describe("StakingPool", () => {
  /* test all possible cases */

  it("should allow users to stake tokens", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();
    const initialSupply = await mockToken.balanceOf(user0Address);

    // Verify that the user1 stake
    const stakeAmount = ethers.utils.parseEther("100");
    await mockToken.connect(user0).transfer(user1Address, stakeAmount);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount);

    await time.setNextBlockTimestamp(startsAt.add(10));

    const stakeDays = 2;
    let tx = await stakingPool.connect(user1).stake(stakeAmount, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    const totalStaked = await stakingPool.totalStaked();
    expect(totalStaked).to.equal(stakeAmount);
  });

  it("should allow users to stake tokens with referrer", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();
    const initialSupply = await mockToken.balanceOf(user0Address);

    // Verify that the user1 stake
    const stakeAmount = ethers.utils.parseEther("100");
    await mockToken.connect(user0).transfer(user1Address, stakeAmount);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount);

    await time.setNextBlockTimestamp(startsAt.add(10));

    const user0InitialBalance = await ethers.provider.getBalance(user0Address);
    const stakeDays = 2;
    let tx = await stakingPool.connect(user1).stake(stakeAmount, stakeDays, user0Address, { value: stakingFee });
    await tx.wait();

    // check the staking result
    const totalStaked = await stakingPool.totalStaked();
    expect(totalStaked).to.equal(stakeAmount);

    // check the referral result
    const referrals = await stakingPool.referrals(user0Address, 0);
    expect(referrals).to.equal(user1Address);

    const expectReferrerFee = stakingFee.mul(20).div(100);
    const user0CurrentBalance = await ethers.provider.getBalance(user0Address);
    expect(expectReferrerFee).to.equal(user0CurrentBalance.sub(user0InitialBalance));
  });

  it("should not allow staking zero tokens", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();

    // verify that the user1 can't stake 0 tokens
    await expect(stakingPool.connect(user1).stake(0, 1, ethers.constants.AddressZero, { value: stakingFee })).to.be.revertedWith(
      "StakingPool::stake: amount = 0",
    );
  });

  it("should not allow staking with stake period less than or equal to zero", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();

    // verify that the user1 can't stake with stake period less than or equal to zero
    const stakeAmount = ethers.utils.parseEther("100");
    await mockToken.connect(user0).transfer(user1Address, stakeAmount);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount);

    await expect(stakingPool.connect(user1).stake(stakeAmount, 0, ethers.constants.AddressZero, { value: stakingFee })).to.be.revertedWith(
      "StakingPool::stake: _stakeDays = 0",
    );
  });

  it("should receive staked tokens into the contract", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();

    // Verify that the user1 stake
    const stakeAmount = ethers.utils.parseEther("100");
    await mockToken.connect(user0).transfer(user1Address, stakeAmount);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount);

    await time.setNextBlockTimestamp(startsAt.add(100));

    const stakeDays = 2;
    let tx = await stakingPool.connect(user1).stake(stakeAmount, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    const totalStaked = await stakingPool.totalStaked();
    expect(totalStaked).to.equal(stakeAmount);

    const user1Balance = await mockToken.balanceOf(user1Address);
    expect(user1Balance).to.equal(0);
  });

  it("should not allow unstaking before the minimum stake period", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();

    // Verify that the user1 stake
    const stakeAmount = ethers.utils.parseEther("100");
    await mockToken.connect(user0).transfer(user1Address, stakeAmount);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount);

    await time.setNextBlockTimestamp(startsAt.add(100));

    const stakeDays = 2;
    let tx = await stakingPool.connect(user1).stake(stakeAmount, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    await expect(stakingPool.connect(user1).unstake()).to.be.revertedWith("StakingPool::unstake: stake not matured");
  });

  it("should transfer unstaked tokens back to the user", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();

    // Verify that the user1 stake
    const stakeAmount = ethers.utils.parseEther("100");
    await mockToken.connect(user0).transfer(user1Address, stakeAmount);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount);

    await time.setNextBlockTimestamp(startsAt.add(100));

    const stakeDays = 2;
    let tx = await stakingPool.connect(user1).stake(stakeAmount, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    const threeDays = 60 * 60 * 24 * 3;
    await time.increase(threeDays + 1000);

    const user1Balance = await mockToken.balanceOf(user1Address);
    await stakingPool.connect(user1).unstake();
    const user1BalanceAfter = await mockToken.balanceOf(user1Address);
    expect(user1BalanceAfter).to.equal(user1Balance.add(stakeAmount));
  });

  it("should get whole reward the user1 stake alone", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();

    // Verify that the user1 stake
    const stakeAmount = ethers.utils.parseEther("100");
    await mockToken.connect(user0).transfer(user1Address, stakeAmount);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount);

    await time.setNextBlockTimestamp(startsAt.add(100));

    const stakeDays = 2;
    let tx = await stakingPool.connect(user1).stake(stakeAmount, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    const threeDays = 60 * 60 * 24 * 3;
    await time.increase(threeDays + 1);

    // Check user1 rewards
    const rewards1 = await stakingPool.connect(user1).getUserRewards(user1Address);
    let expected1 = ethers.utils.parseEther("0.7"); // 0.7 PLS
    expect(expected1).to.approximately(rewards1, 100);
    expect(stakingPool.connect(user1).unstake()).to.changeEtherBalance(user1, rewards1);
  });

  it("should only allow the contract owner to pause/unpause the contract", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const owner = ethers.provider.getSigner(0);
    const ownerAddress = await owner.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();

    // not owner should be reverted
    await expect(stakingPool.connect(user1).setPause()).to.be.reverted;
    // owner should succeed to pause
    await expect(stakingPool.connect(owner).setPause()).to.not.be.reverted;
  });

  it("should handle scenarios with no staked tokens and attempted unstaking", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();

    await expect(stakingPool.connect(user0).unstake()).to.be.revertedWith("StakingPool::unstake: no active stake");
  });

  it("should handle division by zero gracefully in reward calculation functions", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const user0 = ethers.provider.getSigner(0);
    const user0Address = await user0.getAddress();

    // rewardPerShare() should be 0
    const rewardPerShare = await stakingPool.rewardPerShare();
    expect(rewardPerShare).to.equal(0);
  });

  it("should distribute rewards correctly among 2 users", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const owner = ethers.provider.getSigner(0);
    const ownerAddress = await owner.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();
    const user2 = ethers.provider.getSigner(2);
    const user2Address = await user2.getAddress();

    // Verify that the user1 stake
    const stakeAmount1 = ethers.utils.parseEther("100");
    await mockToken.connect(owner).transfer(user1Address, stakeAmount1);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount1);

    await time.setNextBlockTimestamp(startsAt.add(100));

    const stakeDays = 2;
    let tx = await stakingPool.connect(user1).stake(stakeAmount1, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    // Verify that the user2 stake
    const stakeAmount2 = ethers.utils.parseEther("200");
    await mockToken.connect(owner).transfer(user2Address, stakeAmount2);
    await mockToken.connect(user2).approve(stakingPool.address, stakeAmount2);

    tx = await stakingPool.connect(user2).stake(stakeAmount2, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    // increase time 3 days
    const threeDays = 60 * 60 * 24 * 3;
    await time.increase(threeDays + 1);

    // Check user1 rewards
    const rewards1 = await stakingPool.connect(user1).getUserRewards(user1Address);
    /* user1 reward :
      1 - 0.7 PLS of itself
      2 - reward from the user2
        0.7 PLS * 100 / 300 = 0.233333333333333333 PLS
      So total reward is 0.933333333333333333 PLS
    */
    let expected1 = ethers.utils.parseEther("0.933333333333333333"); // 0.933333333333333333 PLS
    expect(expected1).to.approximately(rewards1, 100);
    expect(stakingPool.connect(user1).unstake()).to.changeEtherBalance(user1, rewards1);

    // Check user2 rewards
    const rewards2 = await stakingPool.connect(user2).getUserRewards(user2Address);
    /* user2 reward :
      1 - 0.7 PLS of itself * 200 / 300 = 0.466666666666666666 PLS
    */
    let expected2 = ethers.utils.parseEther("0.466666666666666666"); // 0.466666666666666666 PLS
    expect(expected2).to.approximately(rewards2, 100);
    expect(stakingPool.connect(user2).unstake()).to.changeEtherBalance(user2, rewards2);
  });

  it("should distribute rewards correctly unstake() lately", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const owner = ethers.provider.getSigner(0);
    const ownerAddress = await owner.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();
    const user2 = ethers.provider.getSigner(2);
    const user2Address = await user2.getAddress();

    // Verify that the user1 stake
    const stakeAmount1 = ethers.utils.parseEther("100");
    await mockToken.connect(owner).transfer(user1Address, stakeAmount1);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount1);

    await time.setNextBlockTimestamp(startsAt.add(100));

    const stakeDays = 2;
    let tx = await stakingPool.connect(user1).stake(stakeAmount1, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    // Verify that the user2 stake
    const stakeAmount2 = ethers.utils.parseEther("200");
    await mockToken.connect(owner).transfer(user2Address, stakeAmount2);
    await mockToken.connect(user2).approve(stakingPool.address, stakeAmount2);

    tx = await stakingPool.connect(user2).stake(stakeAmount2, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    // increase time 3 days
    const threeDays = 60 * 60 * 24 * 3;
    await time.increase(threeDays + 1);

    // Check user2 rewards first
    const rewards2 = await stakingPool.connect(user2).getUserRewards(user2Address);
    /* user2 reward :
      1 - 0.7 PLS of itself * 200 / 300 = 0.466666666666666666 PLS
    */
    let expected2 = ethers.utils.parseEther("0.466666666666666666"); // 0.466666666666666666 PLS
    expect(expected2).to.approximately(rewards2, 100);
    expect(stakingPool.connect(user2).unstake()).to.changeEtherBalance(user2, rewards2);

    // Check user1 rewards later
    const rewards1 = await stakingPool.connect(user1).getUserRewards(user1Address);

    /* user1 reward :
      1 - 0.7 PLS of itself
      2 - reward from the user2
        0.7 PLS * 100 / 300 = 0.233333333333333333 PLS
      So total reward is 0.933333333333333333 PLS
    */
    let expected1 = ethers.utils.parseEther("0.933333333333333333"); // 0.933333333333333333 PLS
    expect(expected1).to.approximately(rewards1, 100);
    expect(stakingPool.connect(user1).unstake()).to.changeEtherBalance(user1, rewards1);
  });

  it("should distribute rewards correctly among 3 users", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt } = await loadFixture(setupStakingPool);
    const owner = ethers.provider.getSigner(0);
    const ownerAddress = await owner.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();
    const user2 = ethers.provider.getSigner(2);
    const user2Address = await user2.getAddress();
    const user3 = ethers.provider.getSigner(3);
    const user3Address = await user3.getAddress();

    // Verify that the user1 stake
    const stakeAmount1 = ethers.utils.parseEther("100");
    await mockToken.connect(owner).transfer(user1Address, stakeAmount1);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount1);

    await time.setNextBlockTimestamp(startsAt.add(100));

    const stakeDays = 2;
    let tx = await stakingPool.connect(user1).stake(stakeAmount1, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    // Verify that the user2 stake
    const stakeAmount2 = ethers.utils.parseEther("200");
    await mockToken.connect(owner).transfer(user2Address, stakeAmount2);
    await mockToken.connect(user2).approve(stakingPool.address, stakeAmount2);

    tx = await stakingPool.connect(user2).stake(stakeAmount2, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    // Verify that the user3 stake
    const stakeAmount3 = ethers.utils.parseEther("300");
    await mockToken.connect(owner).transfer(user3Address, stakeAmount3);
    await mockToken.connect(user3).approve(stakingPool.address, stakeAmount3);

    tx = await stakingPool.connect(user3).stake(stakeAmount3, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    // increase time 3 days
    const threeDays = 60 * 60 * 24 * 3;
    await time.increase(threeDays + 1);

    // Check user1 rewards
    const rewards1 = await stakingPool.connect(user1).getUserRewards(user1Address);

    /* user1 reward :
      1 - 0.7 PLS of itself
      2 - reward from the user2
        0.7 PLS * 100 / 300 = 0.233333333333333333 PLS
      3 - reward from the user3
        0.7 PLS * 100 / 600 = 0.116666666666666666 PLS
      So total reward is 1.05 PLS
    */
    let expected1 = ethers.utils.parseEther("1.05"); // 1.05 PLS
    expect(expected1).to.approximately(rewards1, 100);
    expect(stakingPool.connect(user1).unstake()).to.changeEtherBalance(user1, rewards1);

    // Check user2 rewards
    const rewards2 = await stakingPool.connect(user2).getUserRewards(user2Address);
    /* user2 reward :
      1 - 0.7 PLS of itself * 200 / 300 = 0.466666666666666666 PLS
      2 - reward from the user3
        0.7 PLS * 200 / 600 = 0.233333333333333333 PLS
      So total reward is 0.7 PLS
    */
    let expected2 = ethers.utils.parseEther("0.7"); // 0.7 PLS
    expect(expected2).to.approximately(rewards2, 100);
    expect(stakingPool.connect(user2).unstake()).to.changeEtherBalance(user2, rewards2);

    // Check user3 rewards
    const rewards3 = await stakingPool.connect(user3).getUserRewards(user3Address);
    /* user3 reward :
      1 - 0.7 PLS of itself * 300 / 600 = 0.35 PLS
    */
    let expected3 = ethers.utils.parseEther("0.35"); // 0.35 PLS
    expect(expected3).to.approximately(rewards3, 100);
    expect(stakingPool.connect(user3).unstake()).to.changeEtherBalance(user3, rewards3);
  });

  it("should distribute rewards correctly staking with a legendary boost nft", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt, boostNft } = await loadFixture(setupStakingPool);
    const owner = ethers.provider.getSigner(0);
    const ownerAddress = await owner.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();
    const user2 = ethers.provider.getSigner(2);
    const user2Address = await user2.getAddress();

    // user1 mint a boost nft
    const legendaryPrice = await boostNft.tokenTypePrice(0);
    await mockToken.connect(owner).transfer(user1Address, legendaryPrice);
    await mockToken.connect(user1).approve(boostNft.address, legendaryPrice);
    await boostNft.connect(user1).mint(0);

    // Verify that the user1 stake
    const stakeAmount1 = ethers.utils.parseEther("100");
    await mockToken.connect(owner).transfer(user1Address, stakeAmount1);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount1);

    await time.setNextBlockTimestamp(startsAt.add(100));

    const stakeDays = 2;
    let tx = await stakingPool.connect(user1).stake(stakeAmount1, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    // Verify that the user2 stake
    const stakeAmount2 = ethers.utils.parseEther("200");
    await mockToken.connect(owner).transfer(user2Address, stakeAmount2);
    await mockToken.connect(user2).approve(stakingPool.address, stakeAmount2);

    tx = await stakingPool.connect(user2).stake(stakeAmount2, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    // increase time 3 days
    const threeDays = 60 * 60 * 24 * 3;
    await time.increase(threeDays + 1);

    // Check user1 rewards
    const rewards1 = await stakingPool.connect(user1).getUserRewards(user1Address);
    /* user1 reward :
      1 - 0.7 PLS of itself
      2 - reward from the user2
        user1's shares increase by 30% of legendary boost nft, so it would be 130
        so total shares would 330
        0.7 PLS * 130 / 330 = 0.275757575757576 PLS
      So total reward is 0.975757575757576 PLS
    */
    let expected1 = ethers.utils.parseEther("0.975757575757576"); // 0.975757575757576 PLS
    expect(expected1).to.approximately(rewards1, 1e6);
    expect(stakingPool.connect(user1).unstake()).to.changeEtherBalance(user1, rewards1);

    // Check user2 rewards
    const rewards2 = await stakingPool.connect(user2).getUserRewards(user2Address);
    /* user2 reward :
      1 - 0.7 PLS of itself * 200 / 330 = 0.424242424242424242 PLS
    */
    let expected2 = ethers.utils.parseEther("0.424242424242424242"); // 0.424242424242424242 PLS
    expect(expected2).to.approximately(rewards2, 1e6);
    expect(stakingPool.connect(user2).unstake()).to.changeEtherBalance(user2, rewards2);
  });

  it("should distribute rewards correctly after minting a legendary boost nft", async function () {
    const { mockToken, stakingPool, stakingFee, startsAt, boostNft } = await loadFixture(setupStakingPool);
    const owner = ethers.provider.getSigner(0);
    const ownerAddress = await owner.getAddress();
    const user1 = ethers.provider.getSigner(1);
    const user1Address = await user1.getAddress();
    const user2 = ethers.provider.getSigner(2);
    const user2Address = await user2.getAddress();

    // Verify that the user1 stake
    const stakeAmount1 = ethers.utils.parseEther("100");
    await mockToken.connect(owner).transfer(user1Address, stakeAmount1);
    await mockToken.connect(user1).approve(stakingPool.address, stakeAmount1);

    await time.setNextBlockTimestamp(startsAt.add(100));

    const stakeDays = 2;
    let tx = await stakingPool
      .connect(user1)
      .stake(stakeAmount1, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    // user1 mint a boost nft
    const legendaryPrice = await boostNft.tokenTypePrice(0);
    await mockToken.connect(owner).transfer(user1Address, legendaryPrice);
    await mockToken.connect(user1).approve(boostNft.address, legendaryPrice);
    await boostNft.connect(user1).mint(0);

    // Verify that the user2 stake
    const stakeAmount2 = ethers.utils.parseEther("200");
    await mockToken.connect(owner).transfer(user2Address, stakeAmount2);
    await mockToken.connect(user2).approve(stakingPool.address, stakeAmount2);

    tx = await stakingPool
      .connect(user2)
      .stake(stakeAmount2, stakeDays, ethers.constants.AddressZero, { value: stakingFee });
    await tx.wait();

    // increase time 3 days
    const threeDays = 60 * 60 * 24 * 3;
    await time.increase(threeDays + 1);

    // Check user1 rewards
    const rewards1 = await stakingPool.connect(user1).getUserRewards(user1Address);
    /* user1 reward :
      1 - 0.7 PLS of itself
      2 - reward from the user2
        user1's shares increase by 30% of legendary boost nft, so it would be 130
        so total shares would 330
        0.7 PLS * 130 / 330 = 0.275757575757576 PLS
      So total reward is 0.975757575757576 PLS
    */
    let expected1 = ethers.utils.parseEther("0.975757575757576"); // 0.975757575757576 PLS
    expect(expected1).to.approximately(rewards1, 1e6);
    expect(stakingPool.connect(user1).unstake()).to.changeEtherBalance(user1, rewards1);

    // Check user2 rewards
    const rewards2 = await stakingPool.connect(user2).getUserRewards(user2Address);
    /* user2 reward :
      1 - 0.7 PLS of itself * 200 / 330 = 0.424242424242424242 PLS
    */
    let expected2 = ethers.utils.parseEther("0.424242424242424242"); // 0.424242424242424242 PLS
    expect(expected2).to.approximately(rewards2, 1e6);
    expect(stakingPool.connect(user2).unstake()).to.changeEtherBalance(user2, rewards2);
  });
});
