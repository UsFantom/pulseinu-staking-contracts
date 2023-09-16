// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import { AccessControlEnumerable } from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721Enumerable } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import { IPulseXRouter02 } from "./interface/IPulseXRouter02.sol";
import { IStakingPool } from "./interface/IStakingPool.sol";
import { IBoostNft } from "./interface/IBoostNft.sol";

import "hardhat/console.sol";

contract StakingPool is ReentrancyGuard, IStakingPool, AccessControlEnumerable, Pausable {
    using SafeERC20 for IERC20;

    address public constant BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;

    bytes32 public constant STAKING_MODIFY_ROLE = keccak256("STAKING_MODIFY_ROLE");

    address public constant PULSE_X_ROUTER_02 = 0x98bf93ebf5c380C0e6Ae8e192A7e2AE08edAcc02;

    uint256 public immutable stakingFee;
    uint256 public constant PERCENT_BASIS = 1e4;
    uint256 public constant STAKING_REWARDS_PERCENT = 7000; // 70 %
    uint256 public constant STAKING_BURN_PERCENT = 3000; // 30 %
    uint256 public constant STAKING_REFERRER_PERCENT = 2000; // 20 %

    uint256 public constant LEGENDARY_BOOST_PERCENT = 3000; // 30 %
    uint256 public constant COLLECTOR_BOOST_PERCENT = 500; // 5 %

    uint256 public constant PLS_TO_PINU_RATE = 1e5; // 1 PLS = 100,000 PINU
    uint256 public constant PINU_UNIT = 1e12;

    uint256 public constant SHARE_RATE_BASIS = 1e4;

    IERC20 public immutable pinuToken;
    address public immutable boostNft;

    // Timestamp of when the staking starts
    uint256 public startsAt;
    // Reward per token stored
    uint256 public rewardPerShareStored;
    // Reward per token paid
    mapping(address => uint256) public userRewardPerSharePaid;
    // User address => rewards to be claimed
    mapping(address => uint256) public rewards;

    // Raw amount staked by all users
    uint256 public totalStaked;
    // Total shares staked by all users
    uint256 public totalShares;
    // Total rewards staked by all users
    uint256 public totalReward;
    // Current reward staked by all users
    uint256 public currentReward;
    // Current Share rate
    uint256 public currentShareRate;

    // User address => staking information
    mapping(address => StakingInfo) public override userStakingInfo;

    // BoostNft tokenId => user address
    mapping(uint256 => address) public boostNftToUser;

    mapping(address => address[]) public referrals;
    mapping(address => StakingInfo[]) public stakingInfos;

    constructor(address _pinuToken, address _boostNft, uint256 _stakingFee, uint256 _shareRate) {
        pinuToken = IERC20(_pinuToken);
        boostNft = _boostNft;
        stakingFee = _stakingFee;
        startsAt = block.timestamp;
        currentShareRate = _shareRate;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== VIEWS ========== */

    function getCurrentDay() public view returns (uint256) {
        return (block.timestamp - startsAt) / 1 days;
    }

    function calcShares(uint256 _stakedAmount, uint256 _stakingDays) public view returns (uint256) {
        uint256 _shares = ((_stakedAmount + _bonus(_stakedAmount, _stakingDays)) / currentShareRate) * SHARE_RATE_BASIS;
        return _shares;
    }

    /**
     * Calculates how much rewards a user has earned up to current block, every time the user stakes/unstakes/withdraw.
     * We update "rewards[_user]" with how much they are entitled to, up to current block.
     * Next time we calculate how much they earned since last update and accumulate on rewards[_user].
     */
    function getUserRewards(address _user) public view returns (uint256) {
        console.log("userRewardPerSharePaid[_user]: ", userRewardPerSharePaid[_user]);
        console.log("rewards[_user]: ", rewards[_user]);
        console.log("rewardPerShare(): ", rewardPerShare());
        console.log("userStakingInfo[_user].shares: ", userStakingInfo[_user].shares);
        uint256 rewardsSinceLastUpdate = ((userStakingInfo[_user].shares *
            (rewardPerShare() - userRewardPerSharePaid[_user])) / 1e18);
        return rewardsSinceLastUpdate + rewards[_user];
    }

    function getLengthBonus(uint256 _amount, uint256 _days) external pure returns (uint256) {
        return _bonus(_amount, _days);
    }

    function getNftBonus(uint256 _amount) external view returns (uint256) {
        uint256 nftBalance = IERC721Enumerable(boostNft).balanceOf(msg.sender);
        if (nftBalance > 0) {
            uint256 boostPercent = 0;
            for (uint256 i = 0; i < nftBalance; i++) {
                uint256 tokenId = IERC721Enumerable(boostNft).tokenOfOwnerByIndex(msg.sender, i);
                if (boostNftToUser[tokenId] == address(0)) {
                    boostPercent += _getBoostPercent(tokenId);
                }
            }
            return (_amount * boostPercent) / PERCENT_BASIS;
        }
        return 0;
    }

    function _bonus(uint256 _amount, uint256 _days) private pure returns (uint256) {
        return (_amount * (_days - 1)) / 1850;
    }

    function rewardPerShare() public view returns (uint256) {
        if (totalStaked == 0) {
            return rewardPerShareStored;
        }
        return rewardPerShareStored + ((currentReward * 1e18) / totalShares);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _swapPlsToPinu(uint256 plsAmount) private {
        address[] memory path = new address[](2);
        path[0] = IPulseXRouter02(PULSE_X_ROUTER_02).WPLS();
        path[1] = address(pinuToken);
        IPulseXRouter02(PULSE_X_ROUTER_02).swapExactETHForTokens{ value: plsAmount }(
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function _burnPls(uint256 amount) private {
        uint256 initialPinuBalance = pinuToken.balanceOf(address(this));
        _swapPlsToPinu(amount);
        uint256 newPinuBalance = pinuToken.balanceOf(address(this));
        uint256 pinuSwapped = newPinuBalance - initialPinuBalance;
        pinuToken.transfer(BURN_ADDRESS, pinuSwapped);
    }

    function stake(
        uint256 _amount,
        uint256 _stakeDays,
        address _referrer
    ) external payable nonReentrant whenNotPaused updateReward(msg.sender) {
        require(userStakingInfo[msg.sender].balance == 0, "StakingPool::stakeMore: active stake exists, unstake first");
        require(_amount > 0, "StakingPool::stake: amount = 0");
        require(_stakeDays > 0, "StakingPool::stake: _stakeDays = 0");
        require(msg.value == stakingFee, "StakingPool::stake: incorrect fee amount");

        // burn fee
        uint256 _burnFee = (stakingFee * STAKING_BURN_PERCENT) / PERCENT_BASIS;
        if (_referrer != address(0)) {
            uint256 _referrerFee = (stakingFee * STAKING_REFERRER_PERCENT) / PERCENT_BASIS;
            _safeTranferFunds(_referrer, _referrerFee);
            _burnFee -= _referrerFee;
            referrals[_referrer].push(msg.sender);
        }
        _burnPls(_burnFee);

        userStakingInfo[msg.sender].balance = _amount;
        userStakingInfo[msg.sender].shares = calcShares(_amount, _stakeDays);
        userStakingInfo[msg.sender].startDay = uint16(getCurrentDay());
        userStakingInfo[msg.sender].stakeDays = uint16(_stakeDays);

        pinuToken.safeTransferFrom(msg.sender, address(this), _amount);

        totalStaked += _amount;
        totalShares += userStakingInfo[msg.sender].shares;
        currentReward = (stakingFee * STAKING_REWARDS_PERCENT) / PERCENT_BASIS;
        totalReward += currentReward;

        // add boost nft bonus shares
        uint256 nftBalance = IERC721Enumerable(boostNft).balanceOf(msg.sender);
        if (nftBalance > 0) {
            for (uint256 i = 0; i < nftBalance; i++) {
                uint256 tokenId = IERC721Enumerable(boostNft).tokenOfOwnerByIndex(msg.sender, i);
                if (boostNftToUser[tokenId] == address(0)) {
                    _increaseShares(msg.sender, tokenId);
                }
            }
        }

        emit Staked(msg.sender, _amount);
    }

    function _convertPlsToPinu(uint256 amount) private pure returns (uint256) {
        return (amount * PLS_TO_PINU_RATE * PINU_UNIT) / 1e18;
    }

    function unstake() external nonReentrant updateReward(msg.sender) {
        address _user = msg.sender;
        require(
            getCurrentDay() > userStakingInfo[_user].startDay + userStakingInfo[_user].stakeDays,
            "StakingPool::unstake: stake not matured"
        );
        uint256 userBalance = userStakingInfo[_user].balance;
        require(userBalance > 0, "StakingPool::unstake: no active stake");

        // claim rewards first
        uint256 reward = rewards[_user];
        if (reward > 0) {
            rewards[_user] = 0;
            _safeTranferFunds(_user, reward);
            emit RewardPaid(_user, reward);
        }
        currentReward = 0;

        // recalculate the share rate
        uint256 _totalPinu = userBalance + _convertPlsToPinu(reward);
        uint256 _newShareRate = (_totalPinu + _bonus(_totalPinu, userStakingInfo[_user].stakeDays)) /
            userStakingInfo[_user].shares;
        if (_newShareRate > currentShareRate) {
            currentShareRate = _newShareRate;
        }

        // remove boost nft info
        uint256 nftBalance = IERC721Enumerable(boostNft).balanceOf(_user);
        if (nftBalance > 0) {
            for (uint256 i = 0; i < nftBalance; i++) {
                uint256 tokenId = IERC721Enumerable(boostNft).tokenOfOwnerByIndex(_user, i);
                if (boostNftToUser[tokenId] == _user) {
                    _decreaseShares(_user, tokenId);
                }
            }
        }

        // remove the staking info
        totalShares -= userStakingInfo[_user].shares;
        totalStaked -= userBalance;

        stakingInfos[_user].push(userStakingInfo[_user]);
        delete userStakingInfo[_user];

        pinuToken.safeTransfer(_user, userBalance);
        emit Unstaked(_user, userBalance);
    }

    function _safeTranferFunds(address to, uint256 amount) private {
        (bool success, ) = payable(to).call{ value: amount }("");
        require(success, "Failed to transfer PLS to address");
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setPause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (paused()) {
            _unpause();
        } else {
            _pause();
        }
    }

    function _getBoostPercent(uint256 tokenId) private view returns (uint256) {
        if (IBoostNft(boostNft).tokenIdToType(tokenId) == IBoostNft.TokenType.Legendary) {
            return LEGENDARY_BOOST_PERCENT;
        } else {
            return COLLECTOR_BOOST_PERCENT;
        }
    }

    function _decreaseShares(address user, uint256 tokenId) private {
        uint256 boostPercent = _getBoostPercent(tokenId);
        uint256 boostNftBonusShares = (userStakingInfo[user].shares * boostPercent) / PERCENT_BASIS;
        userStakingInfo[user].shares -= boostNftBonusShares;
        totalShares -= boostNftBonusShares;

        delete boostNftToUser[tokenId];
    }

    function _increaseShares(address user, uint256 tokenId) private {
        uint256 boostPercent = _getBoostPercent(tokenId);
        uint256 boostNftBonusShares = (userStakingInfo[user].shares * boostPercent) / PERCENT_BASIS;
        userStakingInfo[user].shares += boostNftBonusShares;
        totalShares += boostNftBonusShares;

        boostNftToUser[tokenId] = user;
    }

    function updateBoostNftBonusShares(
        address tokenSender,
        address tokenReceiver,
        uint256 tokenId
    ) public onlyRole(STAKING_MODIFY_ROLE) {
        if (userStakingInfo[tokenSender].shares > 0 && boostNftToUser[tokenId] == tokenSender) {
            // reduce the shares of the user
            _decreaseShares(tokenSender, tokenId);
        }
        if (userStakingInfo[tokenReceiver].shares > 0 && boostNftToUser[tokenId] == address(0)) {
            // increase the shares of the user
            _increaseShares(tokenReceiver, tokenId);
        }
    }

    /* ========== MODIFIERS ========== */

    modifier updateReward(address _user) {
        rewardPerShareStored = rewardPerShare();
        if (_user != address(0)) {
            rewards[_user] = getUserRewards(_user);
            userRewardPerSharePaid[_user] = rewardPerShareStored;
        }
        _;
    }
}
