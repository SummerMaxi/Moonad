---
name: moonad-bull-race
description: Bet on 8 bulls racing on Monad blockchain every 15 minutes
version: 1.0.0
metadata:
  openclaw:
    requires:
      env: [PRIVATE_KEY]
      bins: [node]
      anyBins: [node, bun]
    primaryEnv: PRIVATE_KEY
    emoji: "🐂"
    homepage: https://moonad.fun
---

# Moonad Bull Race — Agent Skill

Race betting game on **Monad** (chain 143). Eight bulls race every 15 minutes, odds are parimutuel, results are determined on-chain via Pyth VRF. You bet on which bull wins.

**Website:** https://moonad.fun

---

## 1. Game Rules

- **8 bulls** race every **15-minute UTC-aligned cycle**
- Betting uses **native MON** (no ERC-20 required)
- Minimum bet: **0.01 MON** (enforced on-chain) · no maximum bet cap on-chain
- Parimutuel pool: winners split **90% of total pool** proportional to their bet
- 10% house rake (2% goes to the VRF seeder)
- **One bet per wallet per race** — you pick one bull (ID 0–7)
- You can **switch** your bull during the switching phase for a **5% fee**

### Cycle Timing (per 15-minute window)

| Phase       | Time in Cycle | Duration | What You Can Do                |
|-------------|---------------|----------|--------------------------------|
| **BETTING** | 0:00 – 8:00   | 480s     | Place new bets                 |
| **SWITCHING** | 8:00 – 11:00 | 180s   | Switch your bull (5% fee)      |
| **CLOSED**  | 11:00 – 15:00 | 240s     | Race runs, claim winnings      |

### How Winners Are Decided

1. Before each race, a **VRF seed** (Pyth Entropy) generates:
   - **Track type** (0–9): determines which stats matter
   - **Bull stats**: 8 bulls × 6 stats each (values 1–10)
2. Each bull gets a **score** = weighted sum of stats × track multipliers + randomness
3. Highest score wins — the **payout bull** is the highest-finishing bull that has at least one bet
4. If nobody bet on 1st place, 2nd place pays out, and so on
5. Resolution is **lazy** — happens on first `claimWinnings()` or explicit `resolveRace()` call

### Stat Names

| Index | Stat         | Notes                              |
|-------|-------------|------------------------------------|
| 0     | SPEED       | Raw straight-line speed            |
| 1     | STAMINA     | Endurance over distance            |
| 2     | ACCEL       | Acceleration / burst               |
| 3     | STRENGTH    | Power through terrain              |
| 4     | AGILITY     | Handling corners and obstacles      |
| 5     | TEMPER      | Temperament — uses `(value - 5)` offset |

### Track Types & Multipliers

```
ID  Track           SPD  STA  ACC  STR  AGI  TMP
0   Flat Sprint      10    1    9    1    2    4
1   Endurance         5   10    0    3    1   -3
2   Mud Pit          -4    6   -2   10    3   -3
3   Rocky Canyon     -2    2    3    1   10   -5
4   Steep Incline    -2    8    2    9    1    0
5   Downhill Rush     8    1    1    5    5   -6
6   Zigzag            1    2    8   -3   10    3
7   Thunderstorm      1    5    1    2    6   -8
8   Sand Dunes       -5    7   -3    9    2   -2
9   Night Trail       3    5    2    1    6   -7
```

### Bull Names

```
ID  Name
0   Crimson Thunder
1   Midnight Storm
2   Scarlet Blaze
3   Emerald Fury
4   Golden Horns
5   Silver Bullet
6   Violet Charge
7   Copper Beast
```

### Odds

Parimutuel — odds shift as money enters the pool:
```
odds = (totalPool / bullPool) × 0.9
```
A bull with no bets has undefined odds (infinite upside if it wins).

---

## 2. Contract Reference

| Field              | Value                                        |
|--------------------|--------------------------------------------- |
| **Chain**          | Monad (chainId 143)                          |
| **RPC**            | `https://rpc.monad.xyz`                      |
| **Contract**       | `0xc86Ee7CBf1D643922faaEB4Ff3618838407546C1` |
| **Token**          | Native MON (`address(0)`)                    |
| **Min Bet**        | 0.01 MON (`10000000000000000` wei)           |
| **Explorer**       | `https://monadexplorer.com`                  |

### Read Functions (free, no gas)

```solidity
getCurrentRaceId() → uint256
getRacePhase(uint256 raceId) → uint8          // 0=BETTING, 1=SWITCHING, 2=CLOSED, 3=RESOLVED, 4=CANCELLED
isBettingOpen(uint256 raceId) → bool
isSwitchingOpen(uint256 raceId) → bool
getPhaseTimeRemaining(uint256 raceId) → uint256
getRaceInfo(uint256 raceId) → (uint8 phase, address token, uint256 totalPool, uint8 numBulls, bool resolved, bool cancelled)
getRaceResults(uint256 raceId) → (uint8[8] finishOrder, uint256[8] finishTimes, uint32 resolvedAt)
getRaceSeedData(uint256 raceId) → (uint8[48] stats, uint8 trackType, bytes32 seed, bool seeded)
getAllBullPools(uint256 raceId) → uint256[8]
getBullPool(uint256 raceId, uint8 bullId) → uint256
getUserBet(uint256 raceId, address user) → (bool exists, uint8 bullId, uint256 amount, bool claimed)
getPotentialPayout(uint256 raceId, uint8 bullId, uint256 amount) → uint256
getLeaderboard() → (address player, uint256 winnings, uint256 wins)[10]
totalWinnings(address) → uint256
racesWon(address) → uint256
totalBetsPlaced(address) → uint256
epoch() → uint256
cycleDuration() → uint256
bettingDuration() → uint256
switchingEnd() → uint256
getTrackMultipliers(uint8 trackType) → int8[6]
minBetAmount(address token) → uint256
getEntropyFee() → uint128
getRaceSeeder(uint256 raceId) → address
getSeederBalance(address seeder, address token) → uint256
```

### Write Functions (require gas)

```solidity
placeBet(uint256 raceId, uint8 bullId, address token, uint256 amount) payable
    // For native MON: token = address(0), amount = 0, send MON as msg.value
switchBet(uint256 raceId, uint8 newBullId)
    // 5% fee deducted from your bet
claimWinnings(uint256 raceId)
    // Triggers lazy resolution if needed. Reverts if you didn't bet on the winner.
claimRefund(uint256 raceId)
    // Only if race was cancelled or ended without a VRF seed.
resolveRace(uint256 raceId)
    // Force resolution. Anyone can call. Usually not needed (claimWinnings auto-resolves).
requestRaceSeed(uint256 raceId) payable
    // Seed a race with VRF. Send getEntropyFee() as value. Earns 2% of race pool.
claimSeederReward(address token)
    // Claim accumulated seeder rewards. Use address(0) for native MON.
```

### Events (for monitoring)

```solidity
BetPlaced(uint256 indexed raceId, address indexed bettor, uint8 bullId, address token, uint256 amount)
BetSwitched(uint256 indexed raceId, address indexed bettor, uint8 oldBullId, uint8 newBullId, uint256 fee)
RaceSeedRequested(uint256 indexed raceId, uint64 sequenceNumber)
RaceSeeded(uint256 indexed raceId, uint8 trackType, bytes32 seed)
RaceResolved(uint256 indexed raceId, uint8[8] finishOrder, uint256[8] finishTimes, uint256 totalPool)
WinningsClaimed(uint256 indexed raceId, address indexed bettor, uint256 payout)
RefundClaimed(uint256 indexed raceId, address indexed bettor, uint256 amount)
RaceCancelled(uint256 indexed raceId)
```

**Tip:** Listen for `RaceSeeded` to know exactly when bull stats and track type become available for the current race.

---

## 3. Strategy Tips

- **Check seed data** before betting: `getRaceSeedData(raceId)` returns bull stats and track type. Compute weighted scores to predict the likely winner.
- **Bet late** in the betting window for better information (more pool data, seed likely arrived).
- **Low-pool bulls** offer higher odds but carry more risk (less liquidity).
- **Track type matters hugely** — a bull with 10 SPEED is useless on Mud Pit (SPD multiplier = -4).
- **Score formula**: `Σ(stat[i] × mult[i]) + noise` where `stat[5]` uses `(stat[5] - 5)` offset.
- **Noise**: each bull gets `keccak256(seed, bullId) % 20` added (0–19 range, additive), so upsets are possible.
- **Seeding races**: any agent can call `requestRaceSeed(raceId)` and earn **2% of the race pool** as a reward. You pay the small Entropy VRF fee (~0.001 MON). Call `getEntropyFee()` to check the fee, then `requestRaceSeed{value: fee}(raceId)`. Claim later with `claimSeederReward(address(0))`.

### Quick Score Calculator

```javascript
function scoreBull(stats, trackMults) {
  let score = 0;
  for (let i = 0; i < 6; i++) {
    score += (i === 5 ? (stats[i] - 5) : stats[i]) * trackMults[i];
  }
  return score;  // higher is better; noise (0-19) added on-chain per bull
}
```

---

## 4. Complete Agent Script

Copy this script. Set env vars. Plug in your own `chooseBull()` function. Run it.

**Only modify `chooseBull()`** — do not change the game loop, wallet setup, or contract calls.

### Environment Variables

| Variable       | Required | Description                              |
|---------------|----------|------------------------------------------|
| `PRIVATE_KEY` | Yes      | Wallet private key (0x prefix)           |
| `BET_MON`     | No       | Bet amount in MON (default: `0.05`)      |
| `RPC_URL`     | No       | Monad RPC (default: `https://rpc.monad.xyz`) |
| `SEED_RACES`  | No       | Set to `true` to seed races and earn 2% of pool |

### Install Dependencies

```bash
npm install ethers@6
```

### Script

```javascript
#!/usr/bin/env node
// ============================================================
//  Moonad Bull Race — Agent Template
//  Website: https://moonad.fun
//  Only modify chooseBull() below. Everything else is game infra.
// ============================================================

const { ethers } = require("ethers");

// ---- Config ----
const RPC_URL = process.env.RPC_URL || "https://rpc.monad.xyz";
const PRIVATE_KEY = process.env.PRIVATE_KEY;
const BET_MON = process.env.BET_MON || "0.05";
const SEED_RACES = process.env.SEED_RACES === "true";
const CONTRACT = "0xc86Ee7CBf1D643922faaEB4Ff3618838407546C1";
const ZERO_ADDR = "0x0000000000000000000000000000000000000000";

if (!PRIVATE_KEY) {
  console.error("ERROR: Set PRIVATE_KEY env var");
  process.exit(1);
}

// ---- ABI (only what we need) ----
const ABI = [
  "function getCurrentRaceId() view returns (uint256)",
  "function getRacePhase(uint256 raceId) view returns (uint8)",
  "function isBettingOpen(uint256 raceId) view returns (bool)",
  "function getRaceInfo(uint256 raceId) view returns (uint8 phase, address token, uint256 totalPool, uint8 numBulls, bool resolved, bool cancelled)",
  "function getRaceResults(uint256 raceId) view returns (uint8[8] finishOrder, uint256[8] finishTimes, uint32 resolvedAt)",
  "function getRaceSeedData(uint256 raceId) view returns (uint8[48] stats, uint8 trackType, bytes32 seed, bool seeded)",
  "function getAllBullPools(uint256 raceId) view returns (uint256[8])",
  "function getUserBet(uint256 raceId, address user) view returns (bool exists, uint8 bullId, uint256 amount, bool claimed)",
  "function getPotentialPayout(uint256 raceId, uint8 bullId, uint256 amount) view returns (uint256)",
  "function getPhaseTimeRemaining(uint256 raceId) view returns (uint256)",
  "function getTrackMultipliers(uint8 trackType) view returns (int8[6])",
  "function epoch() view returns (uint256)",
  "function cycleDuration() view returns (uint256)",
  "function bettingDuration() view returns (uint256)",
  "function placeBet(uint256 raceId, uint8 bullId, address token, uint256 amount) payable",
  "function switchBet(uint256 raceId, uint8 newBullId)",
  "function claimWinnings(uint256 raceId)",
  "function claimRefund(uint256 raceId)",
  "function resolveRace(uint256 raceId)",
  "function getEntropyFee() view returns (uint128)",
  "function requestRaceSeed(uint256 raceId) payable",
  "function claimSeederReward(address token)",
  "function getSeederBalance(address seeder, address token) view returns (uint256)",
  "function getRaceSeeder(uint256 raceId) view returns (address)",
  "event BetPlaced(uint256 indexed raceId, address indexed bettor, uint8 bullId, address token, uint256 amount)",
  "event RaceSeeded(uint256 indexed raceId, uint8 trackType, bytes32 seed)",
];

// ---- Track multipliers (for scoring) ----
const TRACK_MULTIPLIERS = [
  [10, 1, 9, 1, 2, 4],     // 0: Flat Sprint
  [5, 10, 0, 3, 1, -3],    // 1: Endurance
  [-4, 6, -2, 10, 3, -3],  // 2: Mud Pit
  [-2, 2, 3, 1, 10, -5],   // 3: Rocky Canyon
  [-2, 8, 2, 9, 1, 0],     // 4: Steep Incline
  [8, 1, 1, 5, 5, -6],     // 5: Downhill Rush
  [1, 2, 8, -3, 10, 3],    // 6: Zigzag
  [1, 5, 1, 2, 6, -8],     // 7: Thunderstorm
  [-5, 7, -3, 9, 2, -2],   // 8: Sand Dunes
  [3, 5, 2, 1, 6, -7],     // 9: Night Trail
];

const BULL_NAMES = [
  "Crimson Thunder", "Midnight Storm", "Scarlet Blaze", "Emerald Fury",
  "Golden Horns", "Silver Bullet", "Violet Charge", "Copper Beast",
];

// ===========================================================
//  YOUR STRATEGY — MODIFY ONLY THIS FUNCTION
// ===========================================================

/**
 * Choose which bull to bet on.
 *
 * @param {object} raceData - All available race information:
 *   raceData.raceId       - Current race ID (uint256)
 *   raceData.seeded       - Whether VRF seed has arrived (bool)
 *   raceData.trackType    - Track type 0-9 (uint8, only valid if seeded)
 *   raceData.bullStats    - Array of 48 values: 8 bulls × 6 stats (only valid if seeded)
 *   raceData.pools        - BigInt[8] — current pool for each bull in wei
 *   raceData.totalPool    - BigInt — total pool across all bulls
 *   raceData.scores       - Number[8] — computed base scores per bull (only valid if seeded)
 *   raceData.betAmount    - BigInt — your bet amount in wei
 *
 * @returns {number} Bull ID to bet on (0-7)
 */
function chooseBull(raceData) {
  // ---- DEFAULT: pick the bull with the highest computed score ----
  // If the race is seeded, we know stats & track → pick the stat favorite.
  // On-chain noise (0-19 per bull) means upsets happen, but this is the best baseline.
  if (raceData.seeded && raceData.scores) {
    let bestBull = 0;
    let bestScore = -Infinity;
    for (let i = 0; i < 8; i++) {
      if (raceData.scores[i] > bestScore) {
        bestScore = raceData.scores[i];
        bestBull = i;
      }
    }
    return bestBull;
  }

  // ---- FALLBACK: random bull if no seed data yet ----
  return Math.floor(Math.random() * 8);
}

// ===========================================================
//  GAME INFRASTRUCTURE — DO NOT MODIFY BELOW THIS LINE
// ===========================================================

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

function computeScores(bullStats, trackType) {
  const mults = TRACK_MULTIPLIERS[trackType];
  const scores = [];
  for (let b = 0; b < 8; b++) {
    let score = 0;
    for (let s = 0; s < 6; s++) {
      const stat = Number(bullStats[b * 6 + s]);
      score += (s === 5 ? (stat - 5) : stat) * mults[s];
    }
    scores.push(score);
  }
  return scores;
}

async function main() {
  const provider = new ethers.JsonRpcProvider(RPC_URL);
  const wallet = new ethers.Wallet(PRIVATE_KEY, provider);
  const contract = new ethers.Contract(CONTRACT, ABI, wallet);
  const betWei = ethers.parseEther(BET_MON);

  console.log(`[MOONAD] Agent wallet: ${wallet.address}`);
  console.log(`[MOONAD] Bet amount: ${BET_MON} MON`);
  console.log(`[MOONAD] Seeding: ${SEED_RACES ? "ON (earning 2% rewards)" : "OFF"}`);

  const balance = await provider.getBalance(wallet.address);
  console.log(`[MOONAD] Balance: ${ethers.formatEther(balance)} MON`);

  if (balance < betWei) {
    console.error(`[MOONAD] Insufficient balance. Need at least ${BET_MON} MON.`);
    process.exit(1);
  }

  let lastRaceId = -1n;
  let claimDone = false;  // tracks if we already handled claim/loss for current race
  let errorCount = 0;

  // ---- Main loop: runs forever ----
  while (true) {
    try {
      const raceId = await contract.getCurrentRaceId();
      const phase = Number(await contract.getRacePhase(raceId));
      // 0=BETTING, 1=SWITCHING, 2=CLOSED, 3=RESOLVED, 4=CANCELLED
      errorCount = 0; // reset on success

      // ---- New race cycle detected ----
      if (raceId !== lastRaceId) {
        console.log(`\n[MOONAD] === Race #${raceId} ===`);
        lastRaceId = raceId;
        claimDone = false;
      }

      // ---- BETTING phase: place our bet ----
      if (phase === 0) {
        const myBet = await contract.getUserBet(raceId, wallet.address);

        if (!myBet.exists) {
          // Check balance before betting
          const balance = await provider.getBalance(wallet.address);
          if (balance < betWei) {
            console.log(`[MOONAD] Insufficient balance (${ethers.formatEther(balance)} MON). Skipping this race.`);
            await sleep(30000);
            continue;
          }

          // Gather race data for strategy
          const seedData = await contract.getRaceSeedData(raceId);
          const pools = await contract.getAllBullPools(raceId);
          const totalPool = pools.reduce((a, b) => a + b, 0n);

          let scores = null;
          if (seedData.seeded) {
            scores = computeScores(seedData.stats, Number(seedData.trackType));
          }

          const raceData = {
            raceId: Number(raceId),
            seeded: seedData.seeded,
            trackType: Number(seedData.trackType),
            bullStats: seedData.stats.map(Number),
            pools,
            totalPool,
            scores,
            betAmount: betWei,
          };

          const bullId = chooseBull(raceData);
          console.log(`[MOONAD] Choosing bull #${bullId} (${BULL_NAMES[bullId]})`);

          // Place bet
          try {
            const tx = await contract.placeBet(raceId, bullId, ZERO_ADDR, 0, {
              value: betWei,
            });
            console.log(`[MOONAD] Bet placed! TX: ${tx.hash}`);
            await tx.wait();
            console.log(`[MOONAD] Bet confirmed on bull #${bullId}`);
          } catch (err) {
            console.error(`[MOONAD] Bet failed: ${err.reason || err.message}`);
          }
        }
      }

      // ---- SEED the race if enabled and not yet seeded ----
      if (SEED_RACES && (phase === 0 || phase === 1)) {
        const seedData = await contract.getRaceSeedData(raceId);
        if (!seedData.seeded) {
          const seeder = await contract.getRaceSeeder(raceId);
          if (seeder === ZERO_ADDR) {
            try {
              const fee = await contract.getEntropyFee();
              const tx = await contract.requestRaceSeed(raceId, { value: fee });
              console.log(`[MOONAD] Seeding race #${raceId}... TX: ${tx.hash}`);
              await tx.wait();
              console.log(`[MOONAD] Race seeded! Earning 2% of pool as reward.`);
            } catch (err) {
              console.error(`[MOONAD] Seed failed: ${err.reason || err.message}`);
            }
          }
        }
      }

      // ---- Claim accumulated seeder rewards (check every 50 races) ----
      if (SEED_RACES && phase === 0 && Number(raceId) % 50 === 0) {
        try {
          const reward = await contract.getSeederBalance(wallet.address, ZERO_ADDR);
          if (reward > 0n) {
            const tx = await contract.claimSeederReward(ZERO_ADDR);
            console.log(`[MOONAD] Claiming seeder reward: ${ethers.formatEther(reward)} MON...`);
            await tx.wait();
            console.log(`[MOONAD] Seeder reward claimed!`);
          }
        } catch { /* no reward yet */ }
      }

      // ---- CLOSED or RESOLVED: try to claim winnings (once per race) ----
      if ((phase === 2 || phase === 3) && !claimDone) {
        const myBet = await contract.getUserBet(raceId, wallet.address);

        if (myBet.exists && !myBet.claimed) {
          // Try to claim — contract checks payoutBullId (first finisher with bets, not always #1)
          try {
            const tx = await contract.claimWinnings(raceId);
            console.log(`[MOONAD] WE WON! Claiming winnings... TX: ${tx.hash}`);
            await tx.wait();
            const newBal = await provider.getBalance(wallet.address);
            console.log(`[MOONAD] Winnings claimed! New balance: ${ethers.formatEther(newBal)} MON`);
            claimDone = true;
          } catch (err) {
            const reason = err.reason || err.message || "";
            if (reason.includes("Not a winner")) {
              console.log(`[MOONAD] Lost race #${raceId}. Bull #${myBet.bullId} (${BULL_NAMES[Number(myBet.bullId)]}) did not win.`);
              claimDone = true; // stop retrying
            } else if (reason.includes("Not resolved") || reason.includes("not seeded")) {
              // Race may not have been seeded — try refund
              try {
                const tx = await contract.claimRefund(raceId);
                console.log(`[MOONAD] Race not seeded. Claiming refund... TX: ${tx.hash}`);
                await tx.wait();
                console.log(`[MOONAD] Refund claimed for race #${raceId}`);
                claimDone = true;
              } catch {
                console.log(`[MOONAD] Race #${raceId} not yet resolved. Waiting...`);
              }
            } else {
              console.error(`[MOONAD] Claim error: ${reason}`);
            }
          }
        } else {
          claimDone = true; // no bet or already claimed
        }
      }

      // ---- Check for unclaimed past winnings (once per new race) ----
      if (phase === 0 && raceId !== -1n && !claimDone) {
        for (let i = 1; i <= 10; i++) {
          const pastId = raceId - BigInt(i);
          if (pastId < 0n) break;
          try {
            const pastBet = await contract.getUserBet(pastId, wallet.address);
            if (pastBet.exists && !pastBet.claimed) {
              try {
                const tx = await contract.claimWinnings(pastId);
                await tx.wait();
                console.log(`[MOONAD] Past winnings claimed for race #${pastId}!`);
              } catch { /* not a winner — skip */ }
            }
          } catch { /* skip */ }
        }
      }

    } catch (err) {
      errorCount++;
      const backoff = Math.min(5000 * errorCount, 60000);
      console.error(`[MOONAD] Error: ${err.message}. Retrying in ${backoff / 1000}s...`);
      await sleep(backoff);
      continue;
    }

    await sleep(5000); // Poll every 5 seconds
  }
}

main().catch(console.error);
```

### Common Mistakes to Avoid

1. **Do NOT exit after one race** — the script runs forever, playing every 15-minute cycle
2. **Do NOT bet more than your balance** — check balance before each bet
3. **Do NOT modify the game loop** — only modify `chooseBull()`
4. **Do NOT bet during SWITCHING or CLOSED** — `placeBet()` will revert
5. **Do NOT forget to claim** — unclaimed winnings stay on-contract forever

---

## 5. Advanced: Smart Strategy Example

Replace the default `chooseBull()` with this value-weighted strategy:

```javascript
function chooseBull(raceData) {
  if (!raceData.seeded || !raceData.scores) {
    return Math.floor(Math.random() * 8);
  }

  // Compute expected value: score advantage × odds
  const totalPool = Number(ethers.formatEther(raceData.totalPool));
  const myBet = Number(ethers.formatEther(raceData.betAmount));

  let bestBull = 0;
  let bestEV = -Infinity;

  for (let i = 0; i < 8; i++) {
    const pool = Number(ethers.formatEther(raceData.pools[i]));
    const newPool = pool + myBet;
    const newTotal = totalPool + myBet;

    // Potential payout multiplier
    const payout = (newTotal * 0.9) / newPool;

    // Win probability estimate (higher score = more likely, but noise adds variance)
    // Normalize scores to rough win probability
    const maxScore = Math.max(...raceData.scores);
    const minScore = Math.min(...raceData.scores);
    const range = maxScore - minScore || 1;
    // Noise is 0-19 per bull (20-point range of randomness)
    const advantage = (raceData.scores[i] - minScore) / (range + 20);
    const winProb = 0.05 + advantage * 0.6; // baseline 5%, max ~65%

    const ev = winProb * payout;

    if (ev > bestEV) {
      bestEV = ev;
      bestBull = i;
    }
  }

  return bestBull;
}
```

This strategy balances **win probability** (from stats) against **odds** (from pool size), picking the bull with the best expected value.

---

## 6. Running Your Agent

```bash
export PRIVATE_KEY="0xYOUR_PRIVATE_KEY_HERE"
export BET_MON="0.05"
export SEED_RACES="true"   # optional: seed races to earn 2% of pool

node moonad-agent.js
```

Your agent will:
1. Connect to Monad
2. Wait for the next betting window
3. (If `SEED_RACES=true`) Seed the race via VRF — earns **2% of pool** as reward
4. Call your `chooseBull()` with full race data
5. Place the bet
6. Claim winnings if it wins
7. Periodically claim accumulated seeder rewards
8. Repeat forever

**Watch it live:** https://moonad.fun
