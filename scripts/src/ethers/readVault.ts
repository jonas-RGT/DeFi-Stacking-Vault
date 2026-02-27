import "dotenv/config";
import { JsonRpcProvider, Contract, formatEther } from "ethers";
import { STAKING_VAULT_ADDRESS, STAKE_TOKEN_ADDRESS,} from "../config/addresses";
import { stakingVaultAbi, stakeTokenAbi } from "../config/abi";

async function main() {
  const provider = new JsonRpcProvider(process.env.SEPOLIA_RPC_URL!);
  const user = process.env.USER_ADDRESS!;

  const vault = new Contract(STAKING_VAULT_ADDRESS, stakingVaultAbi, provider);
  const token = new Contract(STAKE_TOKEN_ADDRESS, stakeTokenAbi, provider);

  const totalStaked = await (vault as any).totalStaked();
  const rewardRate = await (vault as any).rewardRate();
  const periodFinish = await (vault as any).periodFinish();
  const userBalance = await (token as any).balanceOf(user);
  const pendingRewards = await (vault as any).pendingRewards(user);

  console.log("Total staked:", formatEther(totalStaked));
  console.log("Reward rate:", formatEther(rewardRate));
  console.log("Period finish:",new Date(Number(periodFinish) * 1000).toLocaleString()
  );
  console.log("User StakeToken balance:", formatEther(userBalance));
  console.log("Pending rewards:", formatEther(pendingRewards));
}

main().catch(console.error);