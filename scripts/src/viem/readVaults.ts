import "dotenv/config";
import { createPublicClient, http, formatEther } from "viem";
import { sepolia } from "viem/chains";
import {STAKING_VAULT_ADDRESS,STAKE_TOKEN_ADDRESS} from "../config/addresses";
import { stakingVaultAbi, stakeTokenAbi } from "../config/abi";
import { fmt, tsToDate } from "../utils/format";

async function main() {
  const client = createPublicClient({
    chain: sepolia,
    transport: http(process.env.SEPOLIA_RPC_URL),
  });

  const user = process.env.USER_ADDRESS as `0x${string}`;

  const totalStaked = await client.readContract({
    address: STAKING_VAULT_ADDRESS as `0x${string}`,
    abi: stakingVaultAbi,
    functionName: "totalStaked",
  });

  const rewardRate = await client.readContract({
    address: STAKING_VAULT_ADDRESS as `0x${string}`,
    abi: stakingVaultAbi,
    functionName: "rewardRate",
  });

  const periodFinish = await client.readContract({
    address: STAKING_VAULT_ADDRESS as `0x${string}`,
    abi: stakingVaultAbi,
    functionName: "periodFinish",
  });

  const balance = await client.readContract({
    address: STAKE_TOKEN_ADDRESS as `0x${string}`,
    abi: stakeTokenAbi,
    functionName: "balanceOf",
    args: [user],
  });

  const rewards = await client.readContract({
    address: STAKING_VAULT_ADDRESS as `0x${string}`,
    abi: stakingVaultAbi,
    functionName: "pendingRewards",
    args: [user],
  });

  console.log("Total staked:", formatEther(totalStaked as bigint));
  console.log("Reward rate:", formatEther(rewardRate as bigint));
  console.log("Period finish:", tsToDate(periodFinish as bigint));
  console.log("User StakeToken balance:", formatEther(balance as bigint));
  console.log("Pending rewards:", formatEther(rewards as bigint));
}

main().catch(console.error);