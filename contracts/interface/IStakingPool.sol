// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

interface IStakingPool {
    struct StakingInfo {
        uint256 balance;
        uint256 shares;
        uint80 minimumStakeTimestamp;
        uint16 stakeDays;
    }

    function userStakingInfo(address _user) external view returns (uint256, uint256, uint80, uint16);

    function updateBoostNftBonusShares(address tokenSender, address tokenReceiver, uint256 tokenId) external;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
}
