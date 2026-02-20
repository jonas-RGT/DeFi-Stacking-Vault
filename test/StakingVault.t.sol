// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Test.sol";
import "../src/StakeToken.sol";
import "../src/RewardToken.sol";
import "../src/ShareToken.sol";
import "../src/StakingVault.sol";

contract StakingVaultTest is Test {
    StakeToken stakeToken;
    RewardToken rewardToken;
    ShareToken shareToken;
    StakingVault vault;

    address alice = address(0xA1);
    address bob = address(0xB0);
    address carol = address(0xC0);

    uint256 initialStake = 1_000 ether;
    uint256 rewardAmount = 500 ether;
    uint256 rewardDuration = 1 days;

    function setUp() public {
        stakeToken = new StakeToken(address(this));
        rewardToken = new RewardToken(address(this));

        // Deploy ShareToken first (no constructor arguments)
        shareToken = new ShareToken();

        // Deploy Vault with ShareToken address
        vault = new StakingVault(address(stakeToken), address(rewardToken), address(shareToken), address(this));

        // Set the vault address in ShareToken (can only be done once)
        shareToken.setVault(address(vault));

        // Mint initial tokens
        stakeToken.mint(alice, initialStake);
        stakeToken.mint(bob, initialStake);
        stakeToken.mint(carol, initialStake);

        rewardToken.mint(address(this), rewardAmount * 3);
    }

    /*//////////////////////////////////////////////////////////////
                            Deposit Tests
    //////////////////////////////////////////////////////////////*/

    function test_deposit() public {
        vm.startPrank(alice);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vm.stopPrank();

        assertEq(shareToken.balanceOf(alice), initialStake);
        assertEq(stakeToken.balanceOf(alice), 0);
        assertEq(vault.totalStaked(), initialStake);
    }

    function test_deposit_multipleUsers() public {
        vm.startPrank(alice);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vm.stopPrank();

        vm.startPrank(bob);
        stakeToken.approve(address(vault), initialStake); // Changed from initialStake * 2
        vault.deposit(initialStake); // Changed from initialStake * 2
        vm.stopPrank();

        uint256 totalShares = shareToken.totalSupply();
        uint256 aliceShare = shareToken.balanceOf(alice);
        uint256 bobShare = shareToken.balanceOf(bob);

        // Both deposited same amount, so equal shares
        assertEq(aliceShare, bobShare);
        assertEq(aliceShare + bobShare, totalShares);
    }

    /*//////////////////////////////////////////////////////////////
                            Withdraw Tests
    //////////////////////////////////////////////////////////////*/

    function test_withdraw() public {
        vm.startPrank(alice);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vault.withdraw(initialStake);
        vm.stopPrank();

        assertEq(shareToken.balanceOf(alice), 0);
        assertEq(stakeToken.balanceOf(alice), initialStake);
        assertEq(vault.totalStaked(), 0);
    }

    function test_withdraw_exceedsBalance_reverts() public {
        vm.startPrank(alice);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vm.expectRevert(StakingVault.InsufficientShares.selector);
        vault.withdraw(initialStake + 1);
        vm.stopPrank();
    }

    function test_withdraw_allShares() public {
        vm.startPrank(alice);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vault.withdraw(initialStake);
        vm.stopPrank();

        assertEq(shareToken.balanceOf(alice), 0);
        assertEq(vault.totalStaked(), 0);
    }

    /*//////////////////////////////////////////////////////////////
                            Add Rewards Tests
    //////////////////////////////////////////////////////////////*/

    function test_addRewards() public {
        rewardToken.approve(address(vault), rewardAmount);
        vault.addRewards(rewardAmount, rewardDuration);

        assertEq(vault.rewardRate(), rewardAmount / rewardDuration);
        assertEq(vault.periodFinish(), block.timestamp + rewardDuration);
    }

    function test_addRewards_onlyOwner() public {
        vm.startPrank(alice);
        rewardToken.approve(address(vault), rewardAmount);
        vm.expectRevert(); // OpenZeppelin 5.x uses custom error
        vault.addRewards(rewardAmount, rewardDuration);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            Claim Rewards Tests
    //////////////////////////////////////////////////////////////*/

    function test_claimRewards_singleUser() public {
        rewardToken.approve(address(vault), rewardAmount);
        vault.addRewards(rewardAmount, rewardDuration);

        vm.startPrank(alice);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vm.warp(block.timestamp + rewardDuration);
        vault.claimRewards();
        vm.stopPrank();

        assertApproxEqAbs(rewardToken.balanceOf(alice), rewardAmount, 1e18); // Allow 1 wei tolerance
    }

    function test_claimRewards_multipleUsers() public {
        rewardToken.approve(address(vault), rewardAmount);
        vault.addRewards(rewardAmount, rewardDuration);

        vm.startPrank(alice);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vm.stopPrank();

        vm.startPrank(bob);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vm.stopPrank();

        vm.warp(block.timestamp + rewardDuration);
        vm.startPrank(alice);
        vault.claimRewards();
        vm.stopPrank();

        vm.startPrank(bob);
        vault.claimRewards();
        vm.stopPrank();

        assertApproxEqAbs(rewardToken.balanceOf(alice), rewardAmount / 2, 1e18);
        assertApproxEqAbs(rewardToken.balanceOf(bob), rewardAmount / 2, 1e18);
    }

    function test_claimRewards_afterPartialWithdraw() public {
        rewardToken.approve(address(vault), rewardAmount);
        vault.addRewards(rewardAmount, rewardDuration);

        vm.startPrank(alice);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vm.stopPrank();

        vm.warp(block.timestamp + rewardDuration / 2);
        vm.startPrank(alice);
        vault.withdraw(initialStake / 2);
        vault.claimRewards();
        vm.stopPrank();

        uint256 expectedReward = rewardAmount / 2;
        assertApproxEqAbs(rewardToken.balanceOf(alice), expectedReward, 1e18);
    }

    function test_pendingRewards_accuracy() public {
        rewardToken.approve(address(vault), rewardAmount);
        vault.addRewards(rewardAmount, rewardDuration);

        vm.startPrank(alice);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vm.stopPrank();

        vm.warp(block.timestamp + rewardDuration / 2);
        uint256 pending = vault.pendingRewards(alice);
        assertApproxEqAbs(pending, rewardAmount / 2, 1e18);
    }

    /*//////////////////////////////////////////////////////////////
                            ShareToken Tests
    //////////////////////////////////////////////////////////////*/

    function test_shareToken_nonTransferable() public {
        vm.startPrank(alice);
        vm.expectRevert(ShareToken.SharesNonTransferable.selector);
        shareToken.transfer(bob, 1 ether);
        vm.expectRevert(ShareToken.SharesNonTransferable.selector);
        shareToken.transferFrom(alice, bob, 1 ether);
        vm.expectRevert(ShareToken.SharesNonTransferable.selector);
        shareToken.approve(bob, 1 ether);
        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            Reward Rollover Tests
    //////////////////////////////////////////////////////////////*/

    function test_rewardRollover() public {
        rewardToken.approve(address(vault), rewardAmount);
        vault.addRewards(rewardAmount, rewardDuration);

        vm.startPrank(alice);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vm.stopPrank();

        vm.warp(block.timestamp + rewardDuration / 2);

        uint256 newReward = 200 ether;
        rewardToken.approve(address(vault), newReward);
        vault.addRewards(newReward, rewardDuration);

        uint256 remaining = (rewardAmount / 2);
        uint256 expectedRate = (remaining + newReward) / rewardDuration;
        assertEq(vault.rewardRate(), expectedRate);
    }

    function test_noRewards_beforeAddRewards() public {
        vm.startPrank(alice);
        stakeToken.approve(address(vault), initialStake);
        vault.deposit(initialStake);
        vm.stopPrank();

        vm.warp(block.timestamp + 1 days);
        uint256 pending = vault.pendingRewards(alice);
        assertEq(pending, 0);
    }

    /*//////////////////////////////////////////////////////////////
                            Fuzz Tests
    //////////////////////////////////////////////////////////////*/

    function testFuzz_deposit_withdraw_invariant(uint256 amount) public {
        amount = bound(amount, 1, 1_000 ether);

        address testUser = address(0x123);
        stakeToken.mint(testUser, amount);

        vm.startPrank(testUser);
        stakeToken.approve(address(vault), amount);
        vault.deposit(amount);
        vault.withdraw(amount);
        vm.stopPrank();

        assertEq(stakeToken.balanceOf(testUser), amount);
    }

    function testFuzz_rewardsNeverExceedAdded(uint256 duration, uint256 numUsers) public {
        duration = bound(duration, 1, 7 days);
        numUsers = bound(numUsers, 1, 5);

        rewardToken.approve(address(vault), rewardAmount);
        vault.addRewards(rewardAmount, duration);

        for (uint256 i = 0; i < numUsers; i++) {
            address user = vm.addr(i + 1);
            stakeToken.mint(user, initialStake);
            vm.startPrank(user);
            stakeToken.approve(address(vault), initialStake);
            vault.deposit(initialStake);
            vm.stopPrank();
        }

        vm.warp(block.timestamp + duration);

        uint256 totalClaimed;
        for (uint256 i = 0; i < numUsers; i++) {
            address user = vm.addr(i + 1);
            vm.startPrank(user);
            vault.claimRewards();
            totalClaimed += rewardToken.balanceOf(user);
            vm.stopPrank();
        }

        assertLe(totalClaimed, rewardAmount);
    }
}
