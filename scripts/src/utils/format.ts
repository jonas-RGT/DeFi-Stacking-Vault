import { formatUnits } from "viem";

  export function fmt(wei: bigint, decimals = 18, dp = 4): string {
    return parseFloat(formatUnits(wei, decimals)).toLocaleString("en-US", {
      minimumFractionDigits: 0,
      maximumFractionDigits: dp,
    });
  }

  export function tsToDate(ts: bigint): string {
    if (ts === 0n) return "Not started";
      return new Date(Number(ts) * 1000).toLocaleString("en-US", {
        dateStyle: "medium",
        timeStyle: "short",
      });
  }

  export function shortAddr(addr: string): string {
    return `${addr.slice(0, 6)}…${addr.slice(-4)}`;
  }