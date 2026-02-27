import "dotenv/config";
import { createPublicClient, http, parseAbiItem } from "viem";
import { sepolia } from "viem/chains";
import { RPC_URL, STAKING_VAULT_ADDRESS } from "../config/addresses";

const client = createPublicClient({
  chain: sepolia,
  transport: http(RPC_URL),
});

const depositedEvent = parseAbiItem(
  "event Deposited(address indexed user, uint256 amount, uint256 shares)"
);
const withdrawnEvent = parseAbiItem(
  "event Withdrawn(address indexed user, uint256 amount, uint256 shares)"
);
const rewardsAddedEvent = parseAbiItem(
  "event RewardsAdded(uint256 amount, uint256 duration, uint256 newPeriodFinish)"
);

const delay = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function fetchLogs(event: any, fromBlock: bigint, toBlock: bigint) {
  return client.getLogs({
    address: STAKING_VAULT_ADDRESS as `0x${string}`,
    event,
    fromBlock,
    toBlock,
  });
}

async function main() {
  const latestBlock = await client.getBlockNumber();
  console.log("Scanning from block 10300040 to", latestBlock.toString());

  let fromBlock = 10300040n;
  const step = 9999n;
  const allLogs: any[] = [];

  while (fromBlock <= latestBlock) {
    const toBlock =
      fromBlock + step > latestBlock ? latestBlock : fromBlock + step;

    const deposited = await fetchLogs(depositedEvent, fromBlock, toBlock);
    await delay(500);
    const withdrawn = await fetchLogs(withdrawnEvent, fromBlock, toBlock);
    await delay(500);
    const rewardsAdded = await fetchLogs(rewardsAddedEvent, fromBlock, toBlock);
    await delay(500);

    allLogs.push(...deposited, ...withdrawn, ...rewardsAdded);
    fromBlock = toBlock + 1n;
  }

  allLogs.sort((a, b) => Number(a.blockNumber) - Number(b.blockNumber));

  if (allLogs.length === 0) {
    console.log("No events found.");
    return;
  }

  for (const log of allLogs) {
    console.log("Event:", log.eventName);
    console.log("Args:", log.args);
    console.log("Block:", log.blockNumber?.toString());
    console.log("Tx:", log.transactionHash);
    console.log("--------------");
  }
}

main().catch(console.error);