// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ShareToken} from "./ShareToken.sol";

contract StakingVault is ReentrancyGuard, Ownable {
    using SafeERC20 for IERC20;

    IERC20 public immutable STAKE_TOKEN;
    IERC20 public immutable REWARD_TOKEN;
    ShareToken public immutable SHARE_TOKEN;

    uint256 public totalStaked;
    uint256 public rewardRate;
    uint256 public periodFinish;
    uint256 public lastUpdateTime;
    uint256 public rewardPerShareStored;

    mapping(address => uint256) public userRewardPerSharePaid;
    mapping(address => uint256) public rewards;

    event Deposited(address indexed user, uint256 amount, uint256 shares);
    event Withdrawn(address indexed user, uint256 amount, uint256 shares);
    event RewardsClaimed(address indexed user, uint256 amount);
    event RewardsAdded(uint256 amount, uint256 duration, uint256 newPeriodFinish);

    error ZeroAmount();
    error ZeroDuration();
    error InsufficientShares();
    error NoSharesInVault();

    constructor(address _stakeToken, address _rewardToken, address _shareToken, address initialOwner)
        Ownable(initialOwner)
    {
        STAKE_TOKEN = IERC20(_stakeToken);
        REWARD_TOKEN = IERC20(_rewardToken);
        SHARE_TOKEN = ShareToken(_shareToken);
    }

    /// @param amount Amount of stake tokens to deposit
    function deposit(uint256 amount) external nonReentrant updateReward(msg.sender) {
        if (amount == 0) revert ZeroAmount();

        uint256 totalShares = SHARE_TOKEN.totalSupply();
        uint256 shares = (totalShares == 0 || totalStaked == 0) ? amount : (amount * totalShares) / totalStaked;

        totalStaked += amount;
        STAKE_TOKEN.safeTransferFrom(msg.sender, address(this), amount);
        SHARE_TOKEN.mint(msg.sender, shares);

        emit Deposited(msg.sender, amount, shares);
    }

    /// @param shares Amount of shares to withdraw
    function withdraw(uint256 shares) external nonReentrant updateReward(msg.sender) {
        if (shares == 0) revert ZeroAmount();
        if (shares > SHARE_TOKEN.balanceOf(msg.sender)) revert InsufficientShares();

        uint256 totalShares = SHARE_TOKEN.totalSupply();
        if (totalShares == 0) revert NoSharesInVault();
        uint256 amount = (shares * totalStaked) / totalShares;

        totalStaked -= amount;
        SHARE_TOKEN.burn(msg.sender, shares);
        STAKE_TOKEN.safeTransfer(msg.sender, amount);

        emit Withdrawn(msg.sender, amount, shares);
    }

    function claimRewards() external nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            REWARD_TOKEN.safeTransfer(msg.sender, reward);
            emit RewardsClaimed(msg.sender, reward);
        }
    }

    /// @param amount Reward tokens to add
    /// @param duration Duration in seconds
    function addRewards(uint256 amount, uint256 duration) external onlyOwner updateReward(address(0)) {
        if (amount == 0) revert ZeroAmount();
        if (duration == 0) revert ZeroDuration();
        REWARD_TOKEN.safeTransferFrom(msg.sender, address(this), amount);

        if (block.timestamp >= periodFinish) {
            rewardRate = amount / duration;
        } else {
            uint256 remaining = (periodFinish - block.timestamp) * rewardRate;
            rewardRate = (amount + remaining) / duration;
        }

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp + duration;

        emit RewardsAdded(amount, duration, periodFinish);
    }

    /// @param account Address to check
    /// @return Pending rewards
    function pendingRewards(address account) external view returns (uint256) {
        uint256 totalShares = SHARE_TOKEN.totalSupply();
        if (totalShares == 0) return rewards[account];

        uint256 rewardPerShare =
            rewardPerShareStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalShares;

        return rewards[account]
            + ((SHARE_TOKEN.balanceOf(account) * (rewardPerShare - userRewardPerSharePaid[account])) / 1e18);
    }

    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    modifier updateReward(address account) {
        _updateReward(account);
        _;
    }

    function _updateReward(address account) internal {
        rewardPerShareStored = _rewardPerShare();
        lastUpdateTime = lastTimeRewardApplicable();

        if (account != address(0)) {
            rewards[account] = _earned(account);
            userRewardPerSharePaid[account] = rewardPerShareStored;
        }
    }

    function _rewardPerShare() internal view returns (uint256) {
        uint256 totalShares = SHARE_TOKEN.totalSupply();
        if (totalShares == 0) return rewardPerShareStored;
        return rewardPerShareStored + ((lastTimeRewardApplicable() - lastUpdateTime) * rewardRate * 1e18) / totalShares;
    }

    function _earned(address account) internal view returns (uint256) {
        return rewards[account]
            + ((SHARE_TOKEN.balanceOf(account) * (_rewardPerShare() - userRewardPerSharePaid[account])) / 1e18);
    }
}
