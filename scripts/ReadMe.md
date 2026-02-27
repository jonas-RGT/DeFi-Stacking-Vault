# DeFi Staking Vault — Scripts

TypeScript scripts that connect to the Sepolia testnet and interact with a deployed Staking Vault contract using both **Ethers.js** and **Viem**. No UI — just direct blockchain interaction.

## Contracts (Sepolia)

| Contract | Address |
|---|---|
| StakingVault | `0x2e4C852B65d65Dc4Ae982Fc8c3A75Ea9f57337D8` |
| StakeToken | `0x2743A327511A3F28514aF0cDDf495062026582cb` |
| RewardToken | `0xa312726CEAF2df336596077cdB92D5B366139990` |
| ShareToken | `0xB2ff973130E98694C8281D68DB5603f0dE758813` |

---

## Installation

```bash
cd scripts
npm install
```

---

## Configuration

Copy the example env file and fill in your values:

```bash
cp .env.example .env
```

Open `.env` and set the following:

```env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
PRIVATE_KEY=0xyour_throwaway_testnet_private_key
USER_ADDRESS=0xaddress_to_check_balances_for
```

>  Never use a real wallet private key. Use a throwaway testnet-only key. `.env` is gitignored and must never be committed.

Get a free Infura API key at [infura.io](https://infura.io). Infura allows up to 10,000 blocks per `eth_getLogs` request on the free tier, which is required for the event scanning script to work efficiently.


---

## Scripts

### Part 1 — Read-Only

Reads `totalStaked`, `rewardRate`, `periodFinish`, user StakeToken balance, and pending rewards from the vault.

**Ethers.js version:**
```bash
npm run ethers:read
```

**Viem version:**
```bash
npm run viem:read
```

---

### Part 2 — Wallet Interaction (Viem)

Checks StakeToken allowance, approves if needed, deposits into the vault, waits for confirmations, and logs the updated vault state.

```bash
npm run viem:deposit
```

---

### Part 3 — Event Reading (Viem)

Fetches all `Deposited`, `Withdrawn`, and `RewardsAdded` events from the StakingVault and displays each with block number, user address, and amount.

```bash
npm run viem:events
```

> Note: This script uses Infura which supports up to 10,000 blocks per request. It scans in steps of 10,000 blocks with sequential requests and completes in a few seconds.


---
## Project Structure

```
scripts/
├── src/
│   ├── ethers/
│   │   └── readVault.ts        # Read vault state using Ethers.js
│   └── viem/
│       ├── readVaults.ts       # Read vault state using Viem
│       ├── deposit.ts          # Approve + deposit using Viem
│       ├── events.ts           # Fetch and display contract events
│       └── addRewards.ts       # Add rewards to the vault
├── config/
│   ├── abi.ts                  # StakingVault and StakeToken ABIs
│   ├── addresses.ts            # Contract addresses and RPC URL
│   └── format.ts               # Formatting helpers (fmt, tsToDate, shortAddr)
├── .env                        # Local env variables (gitignored)
├── .env.example                # Example env file (safe to commit)
└── package.json
```

---

## Ethers.js vs Viem — Write-up

Both libraries let you interact with EVM-compatible blockchains from TypeScript, but they have a different philosophy.

**Ethers.js** is the more established library. It has a class-based API — you create a `Provider`, wrap it in a `Contract`, and call methods directly on the contract object. It feels familiar if you come from an OOP background and has a huge ecosystem of tutorials and examples. The downside is that it can be harder to get full TypeScript type safety out of the box, and the bundle size is larger.

**Viem** is newer and takes a functional approach. Instead of classes, you call standalone functions like `readContract`, `writeContract`, and `getLogs` directly. It is built from the ground up with TypeScript in mind, so you get full type inference on ABI function inputs and outputs — if you pass the wrong argument type, TypeScript will catch it at compile time. It is also more explicit, which means more verbose in some cases, but you always know exactly what is happening.

**Which do I prefer?** Viem. The TypeScript experience is noticeably better — autocomplete on contract function names and argument types saves time and catches bugs early. The functional style also makes it easier to compose and reuse logic.