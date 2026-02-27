import "dotenv/config";
import {createWalletClient,createPublicClient,http,parseEther, formatEther} from "viem";
import { sepolia } from "viem/chains";
import {STAKING_VAULT_ADDRESS,STAKE_TOKEN_ADDRESS} from "../config/addresses";
import { stakingVaultAbi, stakeTokenAbi } from "../config/abi";
import { privateKeyToAccount } from "viem/accounts";

async function main() {
  const account = privateKeyToAccount(process.env.PRIVATE_KEY as `0x${string}`);

  const publicClient = createPublicClient({
    chain: sepolia,
    transport: http(process.env.SEPOLIA_RPC_URL),
  });

  const walletClient = createWalletClient({
    account,
    chain: sepolia,
    transport: http(process.env.SEPOLIA_RPC_URL),
  });

  const amount = parseEther("1");

  const allowance = await publicClient.readContract({
    address: STAKE_TOKEN_ADDRESS as `0x${string}`,
    abi: stakeTokenAbi,
    functionName: "allowance",
    args: [account.address, STAKING_VAULT_ADDRESS],
  });

  if ((allowance as bigint) < amount) {
    const approveHash = await walletClient.writeContract({
      address: STAKE_TOKEN_ADDRESS as `0x${string}`,
      abi: stakeTokenAbi,
      functionName: "approve",
      args: [STAKING_VAULT_ADDRESS, amount],
    });

    console.log("Approve tx:", approveHash);
    await publicClient.waitForTransactionReceipt({ hash: approveHash });
  }

  const depositHash = await walletClient.writeContract({
    address: STAKING_VAULT_ADDRESS as `0x${string}`,
    abi: stakingVaultAbi,
    functionName: "deposit",
    args: [amount],
  });

  console.log("Deposit tx:", depositHash);
  await publicClient.waitForTransactionReceipt({ hash: depositHash });

  const totalStaked = await publicClient.readContract({
    address: STAKING_VAULT_ADDRESS as `0x${string}`,
    abi: stakingVaultAbi,
    functionName: "totalStaked",
  });

  console.log("Updated total staked:", formatEther(totalStaked as bigint));
}

main().catch(console.error);