// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import "forge-std/Script.sol";
import "forge-std/console2.sol";

import {StakeToken} from "../src/StakeToken.sol";
import {RewardToken} from "../src/RewardToken.sol";
import {ShareToken} from "../src/ShareToken.sol";
import {StakingVault} from "../src/StakingVault.sol";

contract Deploy is Script {
    function run() external {
        // Foundry injects the signer at runtime (Anvil or --private-key)
        vm.startBroadcast();

        address deployer = msg.sender;

        console2.log("=== Deploying Staking System ===");
        console2.log("Deployer:", deployer);
        console2.log("Chain ID:", block.chainid);

        // Example test address for StakeToken mint
        address testUser = address(0xBEEF);

        // 1. Deploy tokens
        StakeToken stakeToken = new StakeToken(deployer);
        RewardToken rewardToken = new RewardToken(deployer);
        ShareToken shareToken = new ShareToken();

        // 2. Deploy vault
        StakingVault vault = new StakingVault(address(stakeToken), address(rewardToken), address(shareToken), deployer);

        // 3. Transfer ShareToken authority to vault
        shareToken.setVault(address(vault));

        // 4. Mint initial supplies
        stakeToken.mint(testUser, 100_000e18); // test address for staking
        rewardToken.mint(deployer, 100_000e18); // deployer for addRewards()

        vm.stopBroadcast();

        console2.log("\n=== Deployment Complete ===");
        console2.log("StakeToken:   ", address(stakeToken));
        console2.log("RewardToken:  ", address(rewardToken));
        console2.log("ShareToken:   ", address(shareToken));
        console2.log("StakingVault: ", address(vault));
    }
}
