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
        uint256 rewardsSinceLastUpdate = ((userStakingInfo[_user].shares *
            (rewardPerShare() - userRewardPerSharePaid[_user])) / 1e18);
        return rewardsSinceLastUpdate + rewards[_user];
    }

    function getLengthBonus(uint256 _amount, uint256 _days) external pure returns (uint256) {
        return _bonus(_amount, _days);
    }

    function getNftBonus(uint256 _amount) external view returns (uint256) {
        return _amount * getUserBoostPercent(msg.sender);
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

    function getUserBoostPercent(address _user) public view returns (uint256) {
        uint256 nftBalance = IERC721Enumerable(boostNft).balanceOf(_user);
        if (nftBalance > 0) {
            uint256 boostPercent = 0;
            for (uint256 i = 0; i < nftBalance; i++) {
                uint256 tokenId = IERC721Enumerable(boostNft).tokenOfOwnerByIndex(_user, i);
                boostPercent += _getBoostPercent(tokenId);
            }
            return boostPercent;
        }
        return 0;
    }

    function _updateReward(address _user) private {
        rewards[_user] = getUserRewards(_user);
        rewardPerShareStored = rewardPerShare();
        userRewardPerSharePaid[_user] = rewardPerShareStored;
    }

    function stake(
        uint256 _amount,
        uint256 _stakeDays,
        address _referrer
    ) external payable nonReentrant whenNotPaused {
        require(userStakingInfo[msg.sender].balance == 0, "StakingPool::stakeMore: active stake exists, unstake first");
        require(_amount > 0, "StakingPool::stake: amount = 0");
        require(_stakeDays > 0, "StakingPool::stake: _stakeDays = 0");
        require(msg.value == stakingFee, "StakingPool::stake: incorrect fee amount");

        _updateReward(msg.sender);

        // burn fee
        uint256 _burnFee = (stakingFee * STAKING_BURN_PERCENT) / PERCENT_BASIS;
        if (_referrer != address(0)) {
            uint256 _referrerFee = (stakingFee * STAKING_REFERRER_PERCENT) / PERCENT_BASIS;
            _safeTranferFunds(_referrer, _referrerFee);
            _burnFee -= _referrerFee;
            referrals[_referrer].push(msg.sender);
        }
        // _burnPls(_burnFee);

        userStakingInfo[msg.sender].balance = _amount;
        uint256 _shares = calcShares(_amount, _stakeDays);
        userStakingInfo[msg.sender].shares = _shares + (_shares * getUserBoostPercent(msg.sender)) / PERCENT_BASIS;
        userStakingInfo[msg.sender].startDay = uint16(getCurrentDay());
        userStakingInfo[msg.sender].stakeDays = uint16(_stakeDays);

        pinuToken.safeTransferFrom(msg.sender, address(this), _amount);

        totalStaked += _amount;
        totalShares += userStakingInfo[msg.sender].shares;
        currentReward = (stakingFee * STAKING_REWARDS_PERCENT) / PERCENT_BASIS;
        totalReward += currentReward;

        emit Staked(msg.sender, _amount);
    }

    function _convertPlsToPinu(uint256 amount) private pure returns (uint256) {
        return (amount * PLS_TO_PINU_RATE * PINU_UNIT) / 1e18;
    }

    function unstake() external nonReentrant {
        address _user = msg.sender;
        _updateReward(_user);
        currentReward = 0;

        uint256 userBalance = userStakingInfo[_user].balance;
        require(userBalance > 0, "StakingPool::unstake: no active stake");
        require(
            getCurrentDay() > userStakingInfo[_user].startDay + userStakingInfo[_user].stakeDays,
            "StakingPool::unstake: stake not matured"
        );
        // claim rewards first
        uint256 reward = rewards[_user];
        if (reward > 0) {
            rewards[_user] = 0;
            _safeTranferFunds(_user, reward);
            emit RewardPaid(_user, reward);
        }

        // recalculate the share rate
        uint256 _totalPinu = userBalance + _convertPlsToPinu(reward);
        uint256 _newShareRate = (_totalPinu + _bonus(_totalPinu, userStakingInfo[_user].stakeDays)) /
            userStakingInfo[_user].shares;
        if (_newShareRate > currentShareRate) {
            currentShareRate = _newShareRate;
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

    function _updateShares(address user, uint256 tokenId, bool _sign) private {
        // update reward first
        _updateReward(user);
        currentReward = 0;

        uint256 userBoostPercent = getUserBoostPercent(user);
        uint256 tokenBoostPercent = _getBoostPercent(tokenId);
        uint256 originShares = (userStakingInfo[user].shares * PERCENT_BASIS) / (PERCENT_BASIS + userBoostPercent);
        uint256 newUserBoostPercent = (
            _sign == true ? userBoostPercent + tokenBoostPercent : userBoostPercent - tokenBoostPercent
        );
        uint256 newShares = originShares + (originShares * newUserBoostPercent) / PERCENT_BASIS;

        // update total shares and the user shares
        totalShares = totalShares - userStakingInfo[user].shares + newShares;
        userStakingInfo[user].shares = newShares;
    }

    function updateBoostNftBonusShares(
        address tokenSender,
        address tokenReceiver,
        uint256 tokenId
    ) external nonReentrant onlyRole(STAKING_MODIFY_ROLE) {
        if (userStakingInfo[tokenSender].shares > 0) {
            // reduce the shares of the user
            _updateShares(tokenSender, tokenId, false);
        }
        if (userStakingInfo[tokenReceiver].shares > 0) {
            // increase the shares of the user
            _updateShares(tokenReceiver, tokenId, true);
        }
    }
}
