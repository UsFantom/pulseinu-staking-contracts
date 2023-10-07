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

    address public immutable pulseXRouter02;
    address public immutable daiToken;

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
    mapping(address => StakingInfo[]) public userStakingInfo;

    mapping(address => address[]) private referrals;

    constructor(
        address _pinuToken,
        address _routerAddress,
        address _daiToken,
        address _boostNft,
        uint256 _stakingFee,
        uint256 _shareRate
    ) {
        pinuToken = IERC20(_pinuToken);
        pulseXRouter02 = _routerAddress;
        daiToken = _daiToken;
        boostNft = _boostNft;
        stakingFee = _stakingFee;
        startsAt = block.timestamp;
        currentShareRate = _shareRate;

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /* ========== VIEWS ========== */

    function getTokenPrice(address _tokenIn, address _tokenOut, uint256 _amountIn) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = _tokenIn;
        path[1] = _tokenOut;

        uint256[] memory amountsOut = IPulseXRouter02(pulseXRouter02).getAmountsOut(_amountIn, path);
        return amountsOut[1]; // Returns the estimated amount of _tokenOut for _amountIn
    }

    function getPinuPriceOfPls() external view returns (uint256) {
        return getTokenPrice(address(pinuToken), IPulseXRouter02(pulseXRouter02).WPLS(), PINU_UNIT);
    }

    function getPlsPriceOfUsd() external view returns (uint256) {
        return getTokenPrice(IPulseXRouter02(pulseXRouter02).WPLS(), daiToken, 1e18);
    }

    function getCurrentDay() public view returns (uint256) {
        return (block.timestamp - startsAt) / 1 days;
    }

    function calcShares(
        uint256 _stakedAmount,
        uint256 _stakeDays,
        uint256 _boostPercent
    ) public view returns (uint256) {
        uint256 _totalPinuAmount = _stakedAmount +
            getLengthBonus(_stakedAmount, _stakeDays) +
            (_stakedAmount * _boostPercent) /
            PERCENT_BASIS;
        uint256 _shares = (_totalPinuAmount * SHARE_RATE_BASIS) / currentShareRate;
        return _shares;
    }

    /**
     * Calculates how much rewards a user has earned up to current block, every time the user stakes/unstakes/withdraw.
     * We update "rewards[_user]" with how much they are entitled to, up to current block.
     * Next time we calculate how much they earned since last update and accumulate on rewards[_user].
     */
    function getUserRewards(address _user, uint256 _stakeNumber) public view returns (uint256) {
        uint256 rewardsSinceLastUpdate = ((userStakingInfo[_user][_stakeNumber].shares *
            (rewardPerShare() - userStakingInfo[_user][_stakeNumber].userRewardPerSharePaid)) / 1e18);
        return rewardsSinceLastUpdate + userStakingInfo[_user][_stakeNumber].rewards;
    }

    function getUserReferrals(address _user) external view returns (address[] memory) {
        return referrals[_user];
    }

    function getUserStakes(address _user) external view returns (StakingInfo[] memory) {
        return userStakingInfo[_user];
    }

    function getLengthBonus(uint256 _amount, uint256 _days) public pure returns (uint256) {
        return _bonus(_amount, _days);
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
        path[0] = IPulseXRouter02(pulseXRouter02).WPLS();
        path[1] = address(pinuToken);
        IPulseXRouter02(pulseXRouter02).swapExactETHForTokens{ value: plsAmount }(
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

    function _updateReward(address _user, uint256 _stakeNumber) private {
        userStakingInfo[_user][_stakeNumber].rewards = getUserRewards(_user, _stakeNumber);
        rewardPerShareStored = rewardPerShare();
        userStakingInfo[_user][_stakeNumber].userRewardPerSharePaid = rewardPerShareStored;
    }

    function stake(uint256 _amount, uint256 _stakeDays, address _referrer) external payable nonReentrant whenNotPaused {
        require(_amount > 0, "StakingPool::stake: amount = 0");
        require(_stakeDays > 1, "StakingPool::stake: stakeDays <= 1");
        require(_stakeDays <= 1000, "StakingPool::stake: stakeDays > 1000");
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

        StakingInfo memory _stakingInfo = StakingInfo({
            balance: _amount,
            shares: calcShares(_amount, _stakeDays, getUserBoostPercent(msg.sender)),
            rewards: 0,
            userRewardPerSharePaid: rewardPerShare(),
            startDay: uint16(getCurrentDay()),
            stakeDays: uint16(_stakeDays)
        });

        userStakingInfo[msg.sender].push(_stakingInfo);

        uint256 _stakeNumber = userStakingInfo[msg.sender].length - 1;

        _updateReward(msg.sender, _stakeNumber);

        totalStaked += _amount;
        totalShares += userStakingInfo[msg.sender][_stakeNumber].shares;

        currentReward = (stakingFee * STAKING_REWARDS_PERCENT) / PERCENT_BASIS;
        totalReward += currentReward;

        pinuToken.safeTransferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function _convertPlsToPinu(uint256 amount) private pure returns (uint256) {
        return (amount * PLS_TO_PINU_RATE * PINU_UNIT) / 1e18;
    }

    function unstake(uint256 _stakeNumber) external nonReentrant {
        address _user = msg.sender;

        require(_stakeNumber < userStakingInfo[_user].length, "StakingPool::unstake: invalid stake number");
        require(
            getCurrentDay() >
                userStakingInfo[_user][_stakeNumber].startDay + userStakingInfo[_user][_stakeNumber].stakeDays,
            "StakingPool::unstake: stake not matured"
        );

        _updateReward(_user, _stakeNumber);
        currentReward = 0;

        uint256 userBalance = userStakingInfo[_user][_stakeNumber].balance;

        // claim rewards first
        uint256 reward = userStakingInfo[_user][_stakeNumber].rewards;
        if (reward > 0) {
            _safeTranferFunds(_user, reward);
            emit RewardPaid(_user, reward);
        }

        // recalculate the share rate
        uint256 _totalPinu = userBalance + _convertPlsToPinu(reward);
        uint256 _newShareRate = (_totalPinu + _bonus(_totalPinu, userStakingInfo[_user][_stakeNumber].stakeDays)) /
            userStakingInfo[_user][_stakeNumber].shares;
        if (_newShareRate > currentShareRate) {
            currentShareRate = _newShareRate;
        }

        // remove the staking info
        totalShares -= userStakingInfo[_user][_stakeNumber].shares;
        totalStaked -= userBalance;

        // remove the staking info from array
        userStakingInfo[_user][_stakeNumber] = userStakingInfo[_user][userStakingInfo[_user].length - 1];
        userStakingInfo[_user].pop();

        pinuToken.safeTransfer(_user, userBalance);
        emit Unstaked(_user, _stakeNumber, userBalance);
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
        _updateReward(user, 0);
        currentReward = 0;
        for (uint256 i = 1; i < userStakingInfo[user].length; i++) {
            _updateReward(user, i);
        }

        uint256 userBoostPercent;
        uint256 tokenBoostPercent;
        uint256 newUserBoostPercent;
        uint256 newShares;
        for (uint256 i = 0; i < userStakingInfo[user].length; i++) {
            userBoostPercent = getUserBoostPercent(user);
            tokenBoostPercent = _getBoostPercent(tokenId);
            newUserBoostPercent = (
                _sign == true ? userBoostPercent + tokenBoostPercent : userBoostPercent - tokenBoostPercent
            );
            newShares = calcShares(
                userStakingInfo[user][i].balance,
                userStakingInfo[user][i].stakeDays,
                newUserBoostPercent
            );

            // update total shares and the user shares
            totalShares = totalShares - userStakingInfo[user][i].shares + newShares;
            userStakingInfo[user][i].shares = newShares;
        }
    }

    function updateBoostNftBonusShares(
        address tokenSender,
        address tokenReceiver,
        uint256 tokenId
    ) external nonReentrant onlyRole(STAKING_MODIFY_ROLE) {
        if (userStakingInfo[tokenSender].length > 0) {
            // reduce the shares of the user
            _updateShares(tokenSender, tokenId, false);
        }
        if (userStakingInfo[tokenReceiver].length > 0) {
            // increase the shares of the user
            _updateShares(tokenReceiver, tokenId, true);
        }
    }
}
