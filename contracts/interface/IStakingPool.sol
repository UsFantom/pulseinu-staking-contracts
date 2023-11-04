// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IStakingPool {
    struct StakingInfo {
        uint256 balance;
        uint256 shares;
        uint256 rewardAccumulated;
        uint256 userRewardPerSharePaid;
        uint128 startDay;
        uint128 stakeDays;
    }

    function updateBoostNftBonusShares(address tokenSender, address tokenReceiver, uint256 tokenId) external;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 indexed stakeNumber, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}
