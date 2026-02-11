# MOONAD — Bull Race Game Design

## Core Loop — 15 Minute Cycle

```
4 races/hour × 23 hours/day = 92 races/day

MINUTE  EVENT                                    VRF
──────  ──────────────────────────────────────── ─────
 0:00   startRace() → VRF #1 requested           #1 →
 0:30   VRF #1 callback → bull stats generated    ← #1
 5:00   BULL STATS REVEALED → betting opens
10:00   revealTrack() → VRF #2 requested          #2 →
10:30   VRF #2 callback → TRACK REVEALED          ← #2
        Switch window opens (5% fee to change bet)
13:00   resolveRace() → noise from VRF#2 + prevrandao
        BETS LOCKED → race plays out in 3D scene
~13:15  Results stored onchain. Payouts ready.
13:30   Results displayed. Winners can claim.
15:00   Next cycle begins.
──────  ──────────────────────────────────────── ─────
```

**Why 15 minutes works better than 1 minute:**
- 5 full minutes to study bull stats before betting
- 3 minutes to reassess after track reveal (switch or hold?)
- Bigger betting pools (more time to accumulate bets)
- Agents have time to compute optimal strategies
- Humans aren't rushed — can actually think
- Fewer txs/day = lower operating cost

---

## Bull Traits (6 stats, each 1-10 via VRF)

| Trait          | What it means                                          |
|----------------|--------------------------------------------------------|
| **Speed**      | Raw top speed potential — how fast at full gallop       |
| **Stamina**    | Endurance — maintains speed over distance               |
| **Acceleration** | Burst — how quickly they reach top speed from start   |
| **Strength**   | Raw power — plowing through terrain resistance          |
| **Agility**    | Balance and footwork — turns, uneven ground, recovery   |
| **Temper**     | Volatility — HIGH = aggressive/explosive, LOW = calm/steady |

### Why Temper is special
Temper is the only trait that isn't "higher = better in some context." It's a **double-edged blade**:
- High Temper: Explosive bursts of speed, but panics on difficult terrain
- Low Temper: Steady and reliable, but lacks killer instinct on sprints
- Tracks explicitly reward one end or the other

### Stat Generation
- Each bull gets 6 stats, each rolled 1-10 independently via VRF
- Total stat sum is uncapped (a bull could be 8-8-8-8-8-8 or 2-10-3-9-1-10)
- No rerolls, no normalization — pure randomness creates the variance

---

## Track Types (10 types, selected by VRF)

### 1. FLAT SPRINT (200m)
Short explosive dash. Pure speed contest.
```
Speed        +++  (×1.0)
Acceleration +++  (×0.9)
Stamina       ·   (×0.1)
Strength      ·   (×0.1)
Agility       +   (×0.2)
Temper       HIGH FAVORED (×0.4 for high temper, ×-0.2 for low)
```
**Strategy**: Bet on high Speed + Acceleration + Temper bulls. Stamina is irrelevant.

### 2. ENDURANCE (800m)
The long haul. Speed means nothing if you gas out.
```
Stamina      +++  (×1.0)
Speed         ++  (×0.5)
Strength      +   (×0.3)
Acceleration  ·   (×0.0)
Agility       ·   (×0.1)
Temper       LOW FAVORED (×-0.3 for high temper — they burn out)
```
**Strategy**: Stamina kings. High temper bulls will sprint early and collapse.

### 3. MUD PIT (500m)
Heavy slog through thick mud. Every step is a fight.
```
Strength     +++  (×1.0)
Stamina       ++  (×0.6)
Agility       +   (×0.3)
Speed         --  (×-0.4)  ← fast legs spin out in mud
Acceleration  -   (×-0.2)
Temper       LOW FAVORED (×-0.3 — aggressive bulls waste energy thrashing)
```
**Strategy**: Strength + Stamina. Speed is actively harmful (over-rotation).

### 4. ROCKY CANYON (400m)
Uneven, jagged terrain. One wrong step = stumble.
```
Agility      +++  (×1.0)
Acceleration  +   (×0.3)  ← recovery from stumbles
Stamina       +   (×0.2)
Speed         -   (×-0.2) ← too fast = trip on rocks
Strength      ·   (×0.1)
Temper       LOW FAVORED (×-0.5 — aggressive = reckless footing)
```
**Strategy**: Agility is king. Calm bulls pick their steps carefully.

### 5. STEEP INCLINE (300m uphill)
Pure vertical grind. Legs burning, lungs screaming.
```
Strength     +++  (×0.9)
Stamina      +++  (×0.8)
Acceleration  +   (×0.2)
Speed         -   (×-0.2) ← speed stat is "flat ground" speed
Agility       ·   (×0.1)
Temper       NEUTRAL (×0.0)
```
**Strategy**: Strength + Stamina. Speed doesn't translate uphill.

### 6. DOWNHILL RUSH (300m downhill)
Gravity-assisted chaos. Momentum is everything.
```
Speed        +++  (×0.8)
Strength      ++  (×0.5)  ← momentum from mass
Agility       ++  (×0.5)  ← need balance at speed
Stamina       ·   (×0.1)
Acceleration  ·   (×0.1)
Temper       LOW FAVORED (×-0.6 — aggressive bulls wipe out)
```
**Strategy**: Speed + Agility + calm. High temper = reckless at high speed = crash.

### 7. ZIGZAG (400m with tight turns)
Hairpin turns every 50m. Raw speed is useless without control.
```
Agility      +++  (×1.0)
Acceleration +++  (×0.8)  ← constant stop-start from turns
Speed         ·   (×0.1)  ← can't reach top speed between turns
Strength      -   (×-0.3) ← heavy = slow turns
Stamina       +   (×0.2)
Temper       HIGH FAVORED (×0.3 — aggression helps attack turns)
```
**Strategy**: Agility + Acceleration. Strength is a penalty (heavy = wide turns).

### 8. THUNDERSTORM (500m, rain + lightning)
Slippery ground, loud cracks of thunder, chaos.
```
Agility       ++  (×0.6)  ← slippery footing
Stamina       ++  (×0.5)
Strength      +   (×0.2)
Speed         ·   (×0.1)
Acceleration  ·   (×0.1)
Temper       EXTREME LOW FAVORED (×-0.8 — high temper bulls panic at thunder)
```
**Strategy**: Temper is decisive. An aggressive bull with 10 Temper is almost guaranteed to panic and lose. Calm bulls cruise through.

### 9. SAND DUNES (500m)
Soft shifting ground. Every stride sinks.
```
Strength     +++  (×0.9)
Stamina       ++  (×0.7)
Agility       +   (×0.2)  ← adjusting to shifting sand
Speed         --  (×-0.5) ← fast legs dig into sand
Acceleration  -   (×-0.3)
Temper       LOW FAVORED (×-0.2)
```
**Strategy**: Similar to Mud Pit but even more anti-Speed. Strength + Stamina beasts.

### 10. NIGHT TRAIL (600m, darkness)
Low visibility. Bulls rely on instinct over vision.
```
Agility       ++  (×0.6)
Stamina       ++  (×0.5)
Speed         +   (×0.3)
Acceleration  +   (×0.2)
Strength      ·   (×0.1)
Temper       EXTREME LOW FAVORED (×-0.7 — darkness amplifies anxiety)
```
**Strategy**: Calm, balanced bulls. Darkness punishes volatile temperaments hard.

---

## Temper Scoring Formula

Temper doesn't use a simple multiplier. Instead:

```
For HIGH FAVORED tracks:
  temper_score = (temper - 5) × weight
  (temper 10 = +5 × weight, temper 1 = -4 × weight)

For LOW FAVORED tracks:
  temper_score = (5 - temper) × |weight|
  (temper 1 = +4 × weight, temper 10 = -5 × weight)

For NEUTRAL:
  temper_score = 0
```

This means Temper 5 is always neutral — the safe middle ground.

---

## Race Score Formula

```
race_score = Σ(trait_value × track_multiplier) + vrf_noise

where:
  - trait_value = bull's stat (1-10)
  - track_multiplier = from track type table above
  - vrf_noise = small random factor (±0-3) to prevent pure determinism
```

Higher race_score = faster finish time. Bulls are ranked by score.
The VRF noise ensures that even a "perfect" bull for a track can sometimes lose to a slightly worse one — like real racing.

---

## Betting System

### Phase 1: Stats Revealed (min 5:00 – 10:00, 5 minutes)
- Bull names, colors, and all 6 stats visible
- Bettors analyze stats and place bets
- Track type is HIDDEN
- Agents can run simulations against all 10 possible tracks

### Phase 2: Track Revealed (min 10:00 – 13:00, 3 minutes)
- Track type announced with visual change to scene
- Bettors can SWITCH their bet to a different bull
- **5% fee on switch** (deducted from bet amount)
- This is the strategic moment — "oh no, it's Thunderstorm and I bet on the 9-Temper bull"
- New bets still accepted (no switch fee for first-time bettors in this phase)

### Phase 3: Race (min 13:00 – ~13:15)
- No more bets
- Race plays out visually with the 3D scene (~15 seconds)
- Bull speeds/positions driven by the race_score calculation

### Phase 4: Payout & Cooldown (min ~13:15 – 15:00)
- Results stored onchain as struct in `BullRace.races[raceId]`
- Detailed event emitted for indexers/frontend
- Winner's pot: 90% to winning bettors (proportional to bet size), 10% to protocol (the "manager")
- If no one bet on the winner: pot rolls over to next race
- Winners call `claimWinnings()` to withdraw (pull pattern, safe for both humans and agents)
- ~1:45 buffer before next cycle starts

### Bet Types (future expansion)
| Type       | Description                           | Payout    |
|------------|---------------------------------------|-----------|
| **Win**    | Pick the 1st place bull               | Highest   |
| **Place**  | Pick a top-3 finisher                 | Medium    |
| **Show**   | Pick a top-5 finisher                 | Low       |
| **Exacta** | Pick 1st and 2nd in exact order       | Very high |

Start with just **Win** bets for v1.

---

## Race Result Storage (NOT NFTs)

NFTs (ERC-721) add token ownership tracking overhead we don't need. We're not selling race results — we're recording them. Three options:

| Approach           | Gas cost | Queryable onchain? | Notes                           |
|--------------------|----------|--------------------|---------------------------------|
| Events only        | Cheapest | No (need indexer)  | Emit logs, query via The Graph  |
| Contract storage   | Medium   | Yes                | Structs in mappings, direct reads |
| ERC-721 NFTs       | Highest  | Yes                | Unnecessary ownership tracking  |

**Recommendation: Contract storage + events (Option B)**
- Store compact struct onchain → anyone can verify any past race by calling `getRace(raceId)`
- Emit detailed event → indexers/frontend can build history pages cheaply
- No token minting, no ownership, no marketplace — just a database onchain

```solidity
struct RaceResult {
    uint32  timestamp;
    uint8   trackType;          // 0-9 (10 track types)
    uint8[8] finishOrder;       // bull indices in finishing order
    uint48[8] bullStats;        // 6 stats packed: 4 bits each = 24 bits per bull, packed into uint48
    uint128 totalPot;
    bytes32 vrfSeed;
}

mapping(uint256 => RaceResult) public races;
```

Each race costs ~1 SSTORE for the struct (~20k gas on EVM, much cheaper on Monad with parallel execution). At 92 races/day this is very manageable.

---

## Trait × Track Interaction Matrix (summary)

| Track         | Speed | Stamina | Accel | Strength | Agility | Temper best |
|---------------|-------|---------|-------|----------|---------|-------------|
| Flat Sprint   | +++   | ·       | +++   | ·        | +       | HIGH        |
| Endurance     | ++    | +++     | ·     | +        | ·       | LOW         |
| Mud Pit       | --    | ++      | -     | +++      | +       | LOW         |
| Rocky Canyon  | -     | +       | +     | ·        | +++     | LOW         |
| Steep Incline | -     | +++     | +     | +++      | ·       | NEUTRAL     |
| Downhill Rush | +++   | ·       | ·     | ++       | ++      | LOW         |
| Zigzag        | ·     | +       | +++   | -        | +++     | HIGH        |
| Thunderstorm  | ·     | ++      | ·     | +        | ++      | VERY LOW    |
| Sand Dunes    | --    | ++      | -     | +++      | +       | LOW         |
| Night Trail   | +     | ++      | +     | ·        | ++      | VERY LOW    |

**Key insight**: Speed is beneficial on 3 tracks, harmful on 3, neutral on 4. No stat is universally good. Temper HIGH is only favored on 2/10 tracks, making high-temper bulls high-risk/high-reward.

---

## Visual Reveal System — What Changes In The 3D Scene

The 15-minute cycle has 3 visual states the frontend must render:

### State 1: Pre-Reveal (min 0:00 – 5:00)
- Scene shows **empty starting gates** — 8 lanes, no bulls yet
- HUD shows countdown timer: `> NEXT RACE IN 4:32`
- Track is **neutral/generic** — the standard green wireframe grid
- Ambient state: waiting room vibe

### State 2: Bull Reveal (min 5:00 – 10:00)
**What appears:**
- 8 bulls walk in from behind the start gate to their lanes (current walk-in animation)
- Each bull's **stat card** appears above them or in the HUD sidebar

**Bull stat card (per bull):**
```
┌─ CRIMSON THUNDER ──────┐
│ SPD ████████░░  8      │
│ STA ███░░░░░░░  3      │
│ ACC █████████░  9      │
│ STR ██░░░░░░░░  2      │
│ AGI █████░░░░░  5      │
│ TMP █████████░  9  ⚡  │
└────────────────────────┘
```

**Visual hints on the bulls themselves (subtle, wireframe-compatible):**

| Trait        | Visual cue                                                    |
|--------------|---------------------------------------------------------------|
| Speed        | Wireframe line density — high speed = tighter, sleeker mesh   |
| Stamina      | No strong visual (internal trait)                             |
| Acceleration | Slight forward-lean idle pose                                 |
| Strength     | Scale — high strength = 5-10% bulkier model                   |
| Agility      | No strong visual (internal trait)                             |
| Temper HIGH  | Wireframe **flickers/pulses** — aggressive, unstable energy   |
| Temper LOW   | Wireframe is **steady, constant glow** — calm, reliable       |

The flickering temper effect is key — bettors can see at a glance which bulls are volatile without reading the numbers. A 9-temper bull's wireframe is visibly twitchy.

**Betting UI opens:** wallet connect, pick a bull, enter bet amount.

### State 3: Track Reveal (min 10:00 – 13:00)
**This is the dramatic moment.** The environment transforms:

The track type determines the **entire visual theme** of the scene. The base wireframe aesthetic stays, but colors, geometry, and effects change:

| Track           | Ground color   | Sky/fog         | Track geometry         | Special effects                     |
|-----------------|----------------|-----------------|------------------------|-------------------------------------|
| **Flat Sprint** | Green grid     | Black, clear    | Short 200m, no changes | Clean, bright lines                 |
| **Endurance**   | Green grid     | Black, clear    | Long 800m              | Track stretches out, distant finish |
| **Mud Pit**     | Brown/amber    | Dark brown fog  | Flat, textured ground  | Dripping particles, thick lines     |
| **Rocky Canyon**| Dark grey       | Black           | Jagged floor geometry  | Scattered rock wireframes           |
| **Steep Incline**| Green grid    | Black           | Track tilts upward     | Camera angle shifts                 |
| **Downhill Rush**| Green grid    | Black           | Track tilts downward   | Speed line particles increase       |
| **Zigzag**      | Green grid     | Black           | Visible turn markers   | Chevron arrows at each turn         |
| **Thunderstorm**| Blue-grey      | Dark, flickering| Flat                   | Lightning flashes, rain particles   |
| **Sand Dunes**  | Amber/orange   | Warm amber fog  | Wavy undulating ground | Sand particle drift                 |
| **Night Trail** | Very dim green  | Near-black fog  | Flat                   | Fog closes in, visibility drops     |

**Transition animation (~2 seconds):**
1. Current green grid **glitches** — scanlines intensify, flicker
2. Ground color shifts to track palette
3. Track geometry morphs (hills rise, turns appear, rocks scatter)
4. Fog/atmosphere fades in
5. Track name flashes on screen: `> TRACK: THUNDERSTORM_`

**Bull behavior changes on reveal:**
- High temper bulls on scary tracks (Thunderstorm, Night): idle animation becomes **agitated** — head shaking, pawing ground (use `Idle_3` or `Idle_5` variants for nervous energy)
- Calm bulls stay in normal idle
- This is a visual hint to bettors who haven't read the stats carefully

**Switch bet UI:** "SWITCH BET (5% FEE)" button appears with countdown.

### State 4: Race (min 13:00 – ~13:15)

**How bull speed is determined (replaces current random system):**

Currently in `index.html`:
```js
// OLD: pure random
speed: 10 + Math.random() * 5
```

New system — the **race_score from the contract** maps to actual 3D speed:
```js
// NEW: score-driven
// Contract gives us finishOrder[8] and scores[8]
// Map score range to speed range (10-15 m/s)
const minScore = Math.min(...scores);
const maxScore = Math.max(...scores);
for (const bull of bulls) {
    const normalized = (bull.score - minScore) / (maxScore - minScore); // 0-1
    bull.speed = 10 + normalized * 5; // 10-15 m/s, winner gets ~15
}
```

The finish order is **predetermined by the contract** (deterministic from VRF). The 3D scene is a visualization — the speeds are set so the onchain finish order is guaranteed to match.

**Track-specific race behaviors:**

| Track           | Bull animation changes                                          |
|-----------------|------------------------------------------------------------------|
| **Flat Sprint** | Standard run. Short distance, fast finish.                      |
| **Endurance**   | Run starts strong, low-stamina bulls visibly slow (lower timeScale mid-race) |
| **Mud Pit**     | Slower animation, dust → mud particles (brown), heavier footfalls |
| **Rocky Canyon**| Occasional stumble animation on low-agility bulls (brief slowdown) |
| **Steep Incline**| Camera tilts, bulls lean forward, slower overall animation       |
| **Downhill Rush**| Faster animation, camera follows downslope, momentum feel        |
| **Zigzag**      | Bulls turn at marked points, low-agility bulls swing wide        |
| **Thunderstorm**| Lightning flashes, high-temper bulls flinch (brief animation stutter) |
| **Sand Dunes**  | Wavy ground, heavier gait animation, sand kick particles         |
| **Night Trail** | Reduced draw distance, spotlight per bull, eerie atmosphere      |

**Race drama:** Even though the outcome is predetermined, the *pacing* creates drama:
- Apply small sine-wave surges (current system) so bulls overtake each other mid-race
- The predetermined winner still finishes first, but the journey has tension
- Close finishes are visually neck-and-neck even if scores differ by 1 point

### State 5: Results (min ~13:15 – 15:00)

- Winner celebration animation (Attack_Run → walk → idle)
- Losers decelerate → idle → lie down
- Results panel shows full finishing order + payouts
- Countdown to next race cycle

---

## Summary: What Actually Changes Per Race

| Element        | Changes every race? | Driven by        |
|----------------|---------------------|------------------|
| Bull stats     | Yes                 | VRF seed         |
| Bull colors    | No (fixed 8 colors) | Hardcoded        |
| Bull names     | No (fixed 8 names)  | Hardcoded        |
| Bull visual size | Yes (strength)    | Stats from VRF   |
| Bull temper glow | Yes (flicker)     | Stats from VRF   |
| Track type     | Yes                 | VRF seed         |
| Track visuals  | Yes                 | Track type       |
| Track length   | Yes (200-800m)      | Track type       |
| Bull race speed | Yes                | Score from contract |
| Finish order   | Yes                 | Score from contract |
| Weather/effects | Yes                | Track type       |

---

## Revenue Model

| Source            | Rate | Description                          |
|-------------------|------|--------------------------------------|
| Manager cut       | 10%  | From winning pot each race           |
| Bet switch fee    | 5%   | When changing bet after track reveal |

At 4 races/hour × 23 hours = **92 races/day**.

---

## Smart Contract Architecture (Monad / EVM)

Monad is EVM-compatible, so standard Solidity. Three contracts total:

### Contract 1: `BullRace.sol` — Core Orchestrator

The brain. Manages race lifecycle, computes results, stores history.

```
State machine per race:
  IDLE → BETTING → SWITCHING → RACING → RESOLVED
  (auto-advances on timestamp boundaries)
```

**Key functions:**
```solidity
// ---- Race Lifecycle (called by automation) ----
startRace()
  → requests VRF randomness
  → VRF callback generates 8 bulls × 6 stats + track type
  → sets race state to BETTING
  → emits RaceCreated(raceId, bullStats[8], timestamp)

revealTrack(uint256 raceId)
  → callable after betting window (30s) expires
  → reads track type from VRF result (was generated but hidden)
  → sets state to SWITCHING
  → emits TrackRevealed(raceId, trackType)

resolveRace(uint256 raceId)
  → callable after switch window (15s) expires
  → computes race_score for each bull using trait × track multipliers
  → adds VRF noise per bull
  → ranks bulls by score → finish order
  → stores RaceResult struct onchain
  → triggers payout in BettingPool
  → sets state to RESOLVED
  → emits RaceResolved(raceId, finishOrder, scores)

// ---- View functions ----
getRace(uint256 raceId) → RaceResult
getBullStats(uint256 raceId) → uint8[8][6]
getTrackType(uint256 raceId) → uint8
getCurrentRace() → uint256
```

**Race result storage:**
```solidity
struct RaceResult {
    uint32  timestamp;
    uint8   trackType;
    uint8[8] finishOrder;
    uint8[8][6] bullStats;   // 8 bulls × 6 traits
    uint128 totalPot;
    bytes32 vrfSeed;
}

mapping(uint256 => RaceResult) public races;
uint256 public raceCount;
```

### Contract 2: `BettingPool.sol` — Handles All Money

Separated from race logic so funds are isolated.

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BettingPool is ReentrancyGuard, Ownable {

    IBullRace public bullRace;

    uint256 public constant MIN_BET = 0.01 ether;    // 0.01 MON
    uint256 public constant MAX_BET = 100 ether;      // 100 MON (whale cap)
    uint256 public constant MANAGER_FEE_BPS = 1000;   // 10% = 1000 basis points
    uint256 public constant SWITCH_FEE_BPS = 500;     // 5%  = 500 basis points

    struct Bet {
        uint8 bullIndex;
        uint128 amount;
    }

    // raceId → bullIndex → total bet amount on that bull
    mapping(uint256 => mapping(uint8 => uint256)) public bullPool;
    // raceId → total pool across all bulls
    mapping(uint256 => uint256) public totalPool;
    // raceId → bettor → their bet
    mapping(uint256 => mapping(address => Bet)) public bets;
    // raceId → list of bettors (for refunds)
    mapping(uint256 => address[]) public raceBettors;

    // Claimable balances (pull pattern)
    mapping(address => uint256) public balances;
    uint256 public managerBalance;

    event BetPlaced(uint256 indexed raceId, address indexed bettor, uint8 bullIndex, uint256 amount);
    event BetSwitched(uint256 indexed raceId, address indexed bettor, uint8 oldBull, uint8 newBull, uint256 fee);
    event PayoutDistributed(uint256 indexed raceId, uint8 winnerBull, uint256 totalPot, uint256 managerCut);
    event Claimed(address indexed user, uint256 amount);
    event Refunded(uint256 indexed raceId, uint256 totalRefunded);

    constructor(address _bullRace) Ownable(msg.sender) {
        bullRace = IBullRace(_bullRace);
    }

    // ═══════════════════════════════════════
    //  PLACE BET — during BETTING or SWITCHING
    // ═══════════════════════════════════════
    function placeBet(uint256 raceId, uint8 bullIndex) external payable {
        require(msg.value >= MIN_BET, "below min bet");
        require(msg.value <= MAX_BET, "above max bet");
        require(bullIndex < 8, "invalid bull");

        // Check race is in a bettable state
        uint8 state = bullRace.getRaceState(raceId);
        require(
            state == 2 || state == 5,  // BETTING=2 or SWITCHING=5
            "betting closed"
        );

        // One bet per address per race (simplifies logic)
        require(bets[raceId][msg.sender].amount == 0, "already bet");

        bets[raceId][msg.sender] = Bet(bullIndex, uint128(msg.value));
        bullPool[raceId][bullIndex] += msg.value;
        totalPool[raceId] += msg.value;
        raceBettors[raceId].push(msg.sender);

        emit BetPlaced(raceId, msg.sender, bullIndex, msg.value);
    }

    // ═══════════════════════════════════════
    //  SWITCH BET — during SWITCHING only (5% fee)
    // ═══════════════════════════════════════
    function switchBet(uint256 raceId, uint8 newBullIndex) external {
        require(newBullIndex < 8, "invalid bull");

        uint8 state = bullRace.getRaceState(raceId);
        require(state == 5, "not in switch phase");  // SWITCHING=5

        Bet storage bet = bets[raceId][msg.sender];
        require(bet.amount > 0, "no bet to switch");
        require(bet.bullIndex != newBullIndex, "same bull");

        uint256 fee = (uint256(bet.amount) * SWITCH_FEE_BPS) / 10000;
        uint256 remaining = uint256(bet.amount) - fee;

        // Move pool amounts
        bullPool[raceId][bet.bullIndex] -= bet.amount;
        bullPool[raceId][newBullIndex] += remaining;
        totalPool[raceId] -= fee;  // fee leaves the pool

        uint8 oldBull = bet.bullIndex;
        bet.bullIndex = newBullIndex;
        bet.amount = uint128(remaining);

        // Fee goes to manager
        managerBalance += fee;

        emit BetSwitched(raceId, msg.sender, oldBull, newBullIndex, fee);
    }

    // ═══════════════════════════════════════
    //  DISTRIBUTE PAYOUT — called by BullRace.resolveRace()
    //  Pari-mutuel: winners split 90% of total pool
    // ═══════════════════════════════════════
    function distributePayout(uint256 raceId, uint8 winnerBullIndex) external {
        require(msg.sender == address(bullRace), "only BullRace");

        uint256 pool = totalPool[raceId];
        if (pool == 0) return;  // no bets placed, nothing to do

        uint256 winnerPool = bullPool[raceId][winnerBullIndex];

        // Edge case: no one bet on the winner
        // Try 2nd place, 3rd place, etc.
        if (winnerPool == 0) {
            uint8[8] memory order = bullRace.getFinishOrder(raceId);
            for (uint8 i = 1; i < 8; i++) {
                winnerPool = bullPool[raceId][order[i]];
                if (winnerPool > 0) {
                    winnerBullIndex = order[i];
                    break;
                }
            }
        }

        // If still no winner pool (nobody bet at all on any finisher?), refund
        if (winnerPool == 0) {
            _refundAll(raceId);
            return;
        }

        // Manager cut: 10% of total pool
        uint256 managerCut = (pool * MANAGER_FEE_BPS) / 10000;
        uint256 payoutPool = pool - managerCut;
        managerBalance += managerCut;

        // Credit each winning bettor proportional to their bet
        address[] storage bettors = raceBettors[raceId];
        for (uint256 i = 0; i < bettors.length; i++) {
            Bet storage bet = bets[raceId][bettors[i]];
            if (bet.bullIndex == winnerBullIndex && bet.amount > 0) {
                // Their share = (their bet / winner pool) × payout pool
                uint256 share = (uint256(bet.amount) * payoutPool) / winnerPool;
                balances[bettors[i]] += share;
            }
        }

        emit PayoutDistributed(raceId, winnerBullIndex, pool, managerCut);
    }

    // ═══════════════════════════════════════
    //  REFUND — if race is cancelled
    // ═══════════════════════════════════════
    function refundAll(uint256 raceId) external {
        require(msg.sender == address(bullRace), "only BullRace");
        _refundAll(raceId);
    }

    function _refundAll(uint256 raceId) internal {
        address[] storage bettors = raceBettors[raceId];
        uint256 total = 0;
        for (uint256 i = 0; i < bettors.length; i++) {
            uint256 amt = uint256(bets[raceId][bettors[i]].amount);
            if (amt > 0) {
                balances[bettors[i]] += amt;
                total += amt;
            }
        }
        emit Refunded(raceId, total);
    }

    // ═══════════════════════════════════════
    //  WITHDRAWALS (pull pattern)
    // ═══════════════════════════════════════
    function claimWinnings() external nonReentrant {
        uint256 amount = balances[msg.sender];
        require(amount > 0, "nothing to claim");
        balances[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Claimed(msg.sender, amount);
    }

    function withdrawManagerFees() external onlyOwner nonReentrant {
        uint256 amount = managerBalance;
        require(amount > 0, "nothing to withdraw");
        managerBalance = 0;
        payable(owner()).transfer(amount);
    }

    // ═══════════════════════════════════════
    //  VIEW FUNCTIONS
    // ═══════════════════════════════════════
    function getBet(uint256 raceId, address bettor) external view returns (Bet memory) {
        return bets[raceId][bettor];
    }

    function getPoolSize(uint256 raceId, uint8 bullIndex) external view returns (uint256) {
        return bullPool[raceId][bullIndex];
    }

    function getTotalPool(uint256 raceId) external view returns (uint256) {
        return totalPool[raceId];
    }

    function getBettorCount(uint256 raceId) external view returns (uint256) {
        return raceBettors[raceId].length;
    }

    receive() external payable {}
}

interface IBullRace {
    function getRaceState(uint256 raceId) external view returns (uint8);
    function getFinishOrder(uint256 raceId) external view returns (uint8[8] memory);
}
```

**Pari-mutuel payout math:**
```
Total pool:     All bets across all bulls
Winner pool:    All bets on the winning bull
Manager cut:    10% of total pool
Payout pool:    Total pool − manager cut = 90%

Each winner:    (their bet / winner pool) × payout pool

Example:
  Bull A: 60 MON  |  Bull B: 30 MON  |  Bull C: 10 MON
  Total: 100 MON. Bull B wins!
  Manager: 10 MON  |  Payout pool: 90 MON
  Bettor (20 on B): 90 × 20/30 = 60 MON (3x return)
  Bettor (10 on B): 90 × 10/30 = 30 MON (3x return)

Edge cases:
  No bets on winner → try 2nd place, 3rd, etc.
  No bets on ANY finisher → refund all bets
  Only one bull has bets and loses → falls through to 2nd/3rd
```

**Whale protection:** MAX_BET = 100 MON. Prevents one bettor from dominating the pool.

**Pull pattern:** Winners call `claimWinnings()` to withdraw. No auto-send avoids reentrancy and failed transfers to contracts.

### VRF Provider Comparison (Monad-supported)

Gelato VRF is NOT in Monad's official oracle docs. Three providers are:

| Provider       | API style           | Monad contract                | Callback gives         | Setup complexity |
|----------------|---------------------|-------------------------------|------------------------|------------------|
| **Pyth Entropy** | Inherit IEntropyConsumer | Testnet: `0x3682...e320`   | `bytes32` (one seed)   | Low — no registration |
| **Supra dVRF** | Call ISupraRouter    | Listed (need address)         | `uint256[]` (N values) | Medium — requires whitelisting |
| **Switchboard** | On-demand feeds     | Mainnet: `0xB7F0...0E67`     | TBD (EVM VRF docs thin) | Medium |

**Recommendation: Pyth Entropy**

Why:
- **Listed in Monad's official docs** with testnet contract address
- **Cleanest API** — inherit `IEntropyConsumer`, implement `entropyCallback`, done
- **V2 API** — no user commitment needed (simpler than V1)
- **bytes32 callback** — perfect for deriving many values via `keccak256(seed, index)`
- **No registration** — just deploy and call
- **Pay with native gas token** (MON) — call `getFeeV2()` to get the fee
- **npm SDK** — `@pythnetwork/entropy-sdk-solidity`

### Pyth Entropy Integration in BullRace.sol (Two VRF Calls)

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@pythnetwork/entropy-sdk-solidity/IEntropyV2.sol";
import "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract BullRace is IEntropyConsumer, ReentrancyGuard {

    IEntropyV2 public entropy;
    IBettingPool public bettingPool;
    uint8 constant NUM_BULLS = 8;

    enum RaceState { NONE, WAITING_STATS_VRF, BETTING, WAITING_TRACK_VRF, SWITCHING, RESOLVED, CANCELLED }

    // VRF request type tags
    uint8 constant VRF_STATS = 1;
    uint8 constant VRF_TRACK = 2;

    struct Race {
        RaceState state;
        uint32 timestamp;
        uint8 trackType;
        uint8[6][8] bullStats;      // 8 bulls × 6 traits
        uint8[8] finishOrder;
        int256[8] scores;
        bytes32 vrfSeed1;            // stats seed (VRF #1)
        bytes32 vrfSeed2;            // track seed (VRF #2)
        uint128 totalPot;
    }

    struct VRFRequest {
        uint256 raceId;
        uint8 vrfType;              // VRF_STATS or VRF_TRACK
    }

    mapping(uint256 => Race) public races;
    mapping(uint64 => VRFRequest) public vrfRequests;  // sequence → request info
    uint256 public raceCount;
    address public operator;

    event RaceCreated(uint256 indexed raceId, uint8[6][8] bullStats);
    event TrackRevealed(uint256 indexed raceId, uint8 trackType);
    event RaceResolved(uint256 indexed raceId, uint8[8] finishOrder, int256[8] scores);
    event RaceCancelled(uint256 indexed raceId);

    constructor(address _entropy, address _bettingPool, address _operator) {
        entropy = IEntropyV2(_entropy);
        bettingPool = IBettingPool(_bettingPool);
        operator = _operator;
    }

    function getEntropy() internal view override returns (address) {
        return address(entropy);
    }

    // ═══════════════════════════════════════════════════
    //  PHASE 1: START RACE — VRF #1 (bull stats)
    //  Called by automation at minute 0:00
    // ═══════════════════════════════════════════════════
    function startRace() external {
        require(msg.sender == operator, "only operator");

        uint256 raceId = raceCount++;
        uint128 fee = entropy.getFeeV2();
        uint64 seq = entropy.requestV2{value: fee}();

        vrfRequests[seq] = VRFRequest(raceId, VRF_STATS);
        races[raceId].state = RaceState.WAITING_STATS_VRF;
        races[raceId].timestamp = uint32(block.timestamp);
    }

    // ═══════════════════════════════════════════════════
    //  PHASE 2: REVEAL TRACK — VRF #2 (track type)
    //  Called by automation at minute 10:00
    // ═══════════════════════════════════════════════════
    function revealTrack(uint256 raceId) external {
        require(msg.sender == operator, "only operator");
        require(races[raceId].state == RaceState.BETTING, "not in betting");
        require(block.timestamp >= races[raceId].timestamp + 600, "too early");

        uint128 fee = entropy.getFeeV2();
        uint64 seq = entropy.requestV2{value: fee}();

        vrfRequests[seq] = VRFRequest(raceId, VRF_TRACK);
        races[raceId].state = RaceState.WAITING_TRACK_VRF;
    }

    // ═══════════════════════════════════════════════════
    //  VRF CALLBACK — handles both VRF #1 and VRF #2
    // ═══════════════════════════════════════════════════
    function entropyCallback(
        uint64 sequenceNumber,
        address,
        bytes32 randomNumber
    ) internal override {
        VRFRequest memory req = vrfRequests[sequenceNumber];
        Race storage race = races[req.raceId];

        if (req.vrfType == VRF_STATS) {
            // ---- VRF #1: Generate bull stats ----
            race.vrfSeed1 = randomNumber;

            for (uint8 bull = 0; bull < NUM_BULLS; bull++) {
                for (uint8 stat = 0; stat < 6; stat++) {
                    uint256 derived = uint256(
                        keccak256(abi.encode(randomNumber, bull, stat))
                    );
                    race.bullStats[bull][stat] = uint8(derived % 10) + 1;
                }
            }

            race.state = RaceState.BETTING;
            emit RaceCreated(req.raceId, race.bullStats);

        } else if (req.vrfType == VRF_TRACK) {
            // ---- VRF #2: Generate track type ----
            race.vrfSeed2 = randomNumber;

            uint256 trackRand = uint256(keccak256(abi.encode(randomNumber, "track")));
            race.trackType = uint8(trackRand % 10);

            race.state = RaceState.SWITCHING;
            emit TrackRevealed(req.raceId, race.trackType);
        }

        delete vrfRequests[sequenceNumber];
    }

    // ═══════════════════════════════════════════════════
    //  PHASE 3: RESOLVE RACE
    //  Called by automation at minute 13:00
    //  Noise uses VRF seed #2 + block.prevrandao
    // ═══════════════════════════════════════════════════
    function resolveRace(uint256 raceId) external nonReentrant {
        require(msg.sender == operator, "only operator");
        require(races[raceId].state == RaceState.SWITCHING, "not in switching");
        require(block.timestamp >= races[raceId].timestamp + 780, "too early");

        Race storage race = races[raceId];

        // Compute scores — noise derived from VRF #2 seed + block.prevrandao
        // block.prevrandao is unknowable until this block is produced
        for (uint8 b = 0; b < NUM_BULLS; b++) {
            uint256 noiseRand = uint256(keccak256(abi.encode(
                race.vrfSeed2, "noise", b, block.prevrandao
            )));
            uint8 noise = uint8(noiseRand % 31);  // 0-30

            race.scores[b] = _computeScore(race.bullStats[b], race.trackType, noise);
        }

        // Sort by score descending → finish order
        race.finishOrder = _sortByScore(race.scores);
        race.state = RaceState.RESOLVED;

        // Trigger payouts
        bettingPool.distributePayout(raceId, race.finishOrder[0]);

        emit RaceResolved(raceId, race.finishOrder, race.scores);
    }

    // ═══════════════════════════════════════════════════
    //  CANCEL — if VRF callback doesn't arrive in 5 min
    // ═══════════════════════════════════════════════════
    function cancelRace(uint256 raceId) external {
        require(msg.sender == operator, "only operator");
        Race storage race = races[raceId];
        require(
            race.state == RaceState.WAITING_STATS_VRF ||
            race.state == RaceState.WAITING_TRACK_VRF,
            "not waiting for VRF"
        );
        require(block.timestamp >= race.timestamp + 300, "wait 5 min");

        race.state = RaceState.CANCELLED;
        bettingPool.refundAll(raceId);
        emit RaceCancelled(raceId);
    }

    // ═══════════════════════════════════════════════════
    //  SCORE COMPUTATION
    // ═══════════════════════════════════════════════════

    // Track multipliers: [Speed, Stamina, Accel, Strength, Agility, Temper]
    // Stored as int8 (×10 for precision)
    int8[6][10] public TRACK_MULTIPLIERS = [
        [ int8(10),  1,  9,  1,  2,  4],   // 0: Flat Sprint
        [ int8( 5), 10,  0,  3,  1, -3],   // 1: Endurance
        [ int8(-4),  6, -2, 10,  3, -3],   // 2: Mud Pit
        [ int8(-2),  2,  3,  1, 10, -5],   // 3: Rocky Canyon
        [ int8(-2),  8,  2,  9,  1,  0],   // 4: Steep Incline
        [ int8( 8),  1,  1,  5,  5, -6],   // 5: Downhill Rush
        [ int8( 1),  2,  8, -3, 10,  3],   // 6: Zigzag
        [ int8( 1),  5,  1,  2,  6, -8],   // 7: Thunderstorm
        [ int8(-5),  7, -3,  9,  2, -2],   // 8: Sand Dunes
        [ int8( 3),  5,  2,  1,  6, -7]    // 9: Night Trail
    ];

    function _computeScore(
        uint8[6] memory stats,
        uint8 track,
        uint8 noise
    ) internal view returns (int256) {
        int256 score = 0;
        for (uint8 i = 0; i < 6; i++) {
            int256 mult = int256(TRACK_MULTIPLIERS[track][i]);
            if (i == 5) {
                // Temper: offset from 5 (neutral midpoint)
                int256 temperOffset = int256(uint256(stats[5])) - 5;
                score += temperOffset * mult;
            } else {
                score += int256(uint256(stats[i])) * mult;
            }
        }
        // Noise: 0-30, centered at 15 → add (noise - 15) for ±15 range
        score += int256(uint256(noise)) - 15;
        return score;
    }

    function _sortByScore(int256[8] memory scores)
        internal pure returns (uint8[8] memory order)
    {
        // Initialize order as [0,1,2,3,4,5,6,7]
        for (uint8 i = 0; i < 8; i++) order[i] = i;
        // Simple insertion sort (only 8 elements)
        for (uint8 i = 1; i < 8; i++) {
            uint8 key = order[i];
            int256 keyScore = scores[key];
            uint8 j = i;
            while (j > 0 && scores[order[j-1]] < keyScore) {
                order[j] = order[j-1];
                j--;
            }
            order[j] = key;
        }
    }

    // View functions
    function getRace(uint256 raceId) external view returns (Race memory) {
        return races[raceId];
    }

    function getCurrentRaceId() external view returns (uint256) {
        return raceCount > 0 ? raceCount - 1 : 0;
    }

    // Accept MON to fund VRF fees
    receive() external payable {}
}

interface IBettingPool {
    function distributePayout(uint256 raceId, uint8 winnerBullIndex) external;
    function refundAll(uint256 raceId) external;
}
```

**Monad contract addresses:**
```
Pyth Entropy (MAINNET): 0xD458261E832415CFd3BAE5E416FdF3230ce6F134
Pyth Price Feeds:       0x2880aB155794e7179c9eE2e38200202908C17B43
```

**Two VRF calls per race:**
```
1. min 0:00  — startRace() → VRF #1 requested
2. min 0:30  — VRF #1 callback → bull stats generated + stored
3. min 5:00  — Frontend reads bullStats → shows stat cards, betting opens
4. min 10:00 — revealTrack() → VRF #2 requested
5. min 10:30 — VRF #2 callback → track generated + revealed, switching opens
6. min 13:00 — resolveRace() → noise from VRF #2 seed + block.prevrandao
                                scores computed, finish order determined, payouts triggered
7. min 15:00 — next cycle
```

**Cost: 2 VRF calls per race × 92 races/day = 184 VRF calls/day. Still cheap.**

---

## Race Automation — Who Calls the Contracts?

The race loop needs an external trigger every 60 seconds. Options:

| Method                | Pros                         | Cons                         |
|-----------------------|------------------------------|------------------------------|
| **Backend cron job**  | Simple, reliable, cheap      | Centralized (single operator)|
| **Gelato Automate**   | Decentralized, no server     | Costs per execution          |
| **Incentivized keeper** | Anyone can trigger for reward | Complex, possible griefing |

**Recommendation for v1: Backend cron job**
- A simple Node.js script running on a server
- Fires transactions at the right minute marks in each 15-min cycle
- One wallet, one server, reliable
- Decentralize later with Gelato or keepers in v2

```
Cron script (per 15-minute cycle):
  1. min 0:00  → startRace()       — tx1, triggers VRF #1 (stats)
  2. min 0:30  → (VRF #1 callback arrives — no tx from us)
  3. min 5:00  → (frontend reads stats — no tx needed)
  4. min 10:00 → revealTrack()     — tx2, triggers VRF #2 (track)
  5. min 10:30 → (VRF #2 callback arrives — no tx from us)
  6. min 13:00 → resolveRace()     — tx3, computes results + payouts
```

3 transactions per race × 92 races/day = **276 txs/day**. Negligible.

---

## Contract Interaction Flow

```
                    ┌─────────────┐
                    │  Frontend   │
                    │ (Three.js)  │
                    └──────┬──────┘
                           │ reads race state, places bets
                           ▼
              ┌────────────────────────┐
              │     BettingPool.sol    │
              │  placeBet() switchBet()│
              │  claimWinnings()       │
              └────────────┬───────────┘
                           │ distributePayout()
                           ▼
    Backend   ┌────────────────────────┐       ┌──────────────────┐
    Cron ────►│      BullRace.sol      │◄─────►│  Pyth Entropy    │
  (every 15m) │  is IEntropyConsumer   │       │  (pre-deployed)  │
              │                        │       └──────────────────┘
              │  startRace()    ─── VRF #1 req ──► stats callback
              │  revealTrack()  ─── VRF #2 req ──► track callback
              │  resolveRace()  ─── scores + noise (block.prevrandao)
              │  cancelRace()   ─── timeout fallback
              │  getRace() view │
              └────────┬───────┘
                       │ distributePayout() / refundAll()
                       ▼
              ┌────────────────────────┐
              │     BettingPool.sol    │◄──── Users / Agents
              │  placeBet() switchBet()│
              │  claimWinnings()       │
              └────────────────────────┘
```

**Only 2 contracts to deploy:** `BullRace.sol` and `BettingPool.sol`.
Pyth Entropy is pre-deployed on Monad at `0xD458261E832415CFd3BAE5E416FdF3230ce6F134`.

---

## Race Score Computation (onchain in resolveRace)

```solidity
// Track multipliers stored as int8 (×10 for precision)
// e.g., 10 = ×1.0, -4 = ×-0.4, 0 = neutral
int8[6][10] public TRACK_MULTIPLIERS = [
    // Speed, Stamina, Accel, Strength, Agility, Temper
    [ 10,  1,  9,  1,  2,  4],  // 0: Flat Sprint    (temper HIGH favored)
    [  5, 10,  0,  3,  1, -3],  // 1: Endurance       (temper LOW favored)
    [ -4,  6, -2, 10,  3, -3],  // 2: Mud Pit         (temper LOW favored)
    [ -2,  2,  3,  1, 10, -5],  // 3: Rocky Canyon    (temper LOW favored)
    [ -2,  8,  2,  9,  1,  0],  // 4: Steep Incline   (temper NEUTRAL)
    [  8,  1,  1,  5,  5, -6],  // 5: Downhill Rush   (temper LOW favored)
    [  1,  2,  8, -3, 10,  3],  // 6: Zigzag          (temper HIGH favored)
    [  1,  5,  1,  2,  6, -8],  // 7: Thunderstorm    (temper VERY LOW)
    [ -5,  7, -3,  9,  2, -2],  // 8: Sand Dunes      (temper LOW favored)
    [  3,  5,  2,  1,  6, -7],  // 9: Night Trail     (temper VERY LOW)
];

function computeScore(uint8[6] stats, uint8 track, bytes32 seed, uint8 bullIdx)
    returns (int256)
{
    int256 score = 0;
    for (uint8 i = 0; i < 6; i++) {
        int256 mult = int256(TRACK_MULTIPLIERS[track][i]);
        if (i == 5) {
            // Temper: positive mult = high favored, negative = low favored
            int256 temperOffset = int256(uint256(stats[5])) - 5;
            score += temperOffset * mult;
        } else {
            score += int256(uint256(stats[i])) * mult;
        }
    }
    // Add VRF noise (0-30 range, so ±15 centered)
    uint256 noise = uint256(keccak256(abi.encode(seed, "noise", bullIdx))) % 31;
    score += int256(noise) - 15;
    return score;
}
```

**Fully deterministic**: Given the same VRF seed, anyone can recompute and verify all results.

---

## Deployment Checklist

```
Contracts (Solidity, deploy to Monad):
  ├── BullRace.sol         — inherits IEntropyConsumer (Pyth)
  │                           race lifecycle + results storage + VRF
  └── BettingPool.sol      — money handling, payouts, manager fees

Dependencies (npm, NOT deployed by us):
  └── @pythnetwork/entropy-sdk-solidity  — IEntropyV2, IEntropyConsumer

Pyth Entropy (already deployed on Monad):
  └── Mainnet: 0xD458261E832415CFd3BAE5E416FdF3230ce6F134
  └── Fund BullRace.sol with MON to pay VRF fees (getFeeV2())

Backend (Node.js):
  └── race-cron.js         — calls startRace/revealTrack/resolveRace every 15 min

Frontend (existing):
  └── index.html           — add wallet connect, bet UI, read race state from chain
```

---

## CRITICAL: Track + Outcome Predictability Problem

### The problem
Right now, `entropyCallback` stores the VRF seed onchain at minute 0. From that seed, ALL values are derived deterministically — stats, track type, AND noise. This means:

1. **Track is readable before "reveal"**: Anyone can call `races[raceId].trackType` or compute `keccak256(seed, "track")` at minute 0, even though the UI reveals it at minute 10. Smart agents bypass the two-phase reveal entirely.

2. **Finish order is knowable before the race**: Since stats + track + noise are all derived from the same seed, at minute 0 you can compute every bull's exact score and know the winner. The "race" becomes theater with a predetermined, publicly-known outcome.

This breaks the entire betting game. Nobody would lose a bet if they can compute the winner before betting closes.

### The fix: Two VRF calls

```
VRF #1 (min 0:00) → generates bull stats ONLY
VRF #2 (min 10:00) → generates track type + resolveEntropy

At min 13:00, resolveRace() computes noise from:
  noise = keccak256(vrfSeed2, "noise", bullIndex, block.prevrandao)
```

**Why this works:**
- After VRF #1 (min 0-10): Stats are known, track is unknown. Bettors analyze stats and simulate all 10 possible tracks. Good strategy, but no certainty.
- After VRF #2 (min 10-13): Track is known, but noise is NOT knowable yet because it depends on `block.prevrandao` of the future resolve block. Agents can compute approximate scores but the noise (±15) creates real uncertainty in close matchups.
- At min 13: `resolveRace` uses the resolve block's `prevrandao` mixed with the VRF seed to generate noise. Since `prevrandao` is only known at block time, no one can precompute the exact finish order.

**Cost**: 2 VRF calls per race instead of 1. At 92 races/day, still very cheap.

**Updated flow:**
```
MINUTE  EVENT                          VRF
──────  ─────────────────────          ────
 0:00   startRace()                    VRF #1 requested (stats)
 0:30   VRF #1 callback → stats stored
 5:00   Stats revealed → betting opens
10:00   revealTrack()                  VRF #2 requested (track)
10:30   VRF #2 callback → track stored + revealed
13:00   resolveRace() → noise from VRF #2 seed + block.prevrandao
15:00   Next cycle
```

### Updated contract code

```solidity
// VRF #1 callback — stats only
function _handleStatsVRF(bytes32 randomNumber, uint256 raceId) internal {
    Race storage race = races[raceId];
    race.vrfSeed1 = randomNumber;

    // Derive 8 bulls × 6 stats
    for (uint8 bull = 0; bull < NUM_BULLS; bull++) {
        for (uint8 stat = 0; stat < 6; stat++) {
            uint256 derived = uint256(keccak256(abi.encode(randomNumber, bull, stat)));
            race.bullStats[bull][stat] = uint8(derived % 10) + 1;
        }
    }
    race.state = RaceState.BETTING;
    emit RaceCreated(raceId, race.bullStats);
}

// VRF #2 callback — track only
function _handleTrackVRF(bytes32 randomNumber, uint256 raceId) internal {
    Race storage race = races[raceId];
    race.vrfSeed2 = randomNumber;
    race.trackType = uint8(uint256(keccak256(abi.encode(randomNumber, "track"))) % 10);
    race.state = RaceState.SWITCHING;
    emit TrackRevealed(raceId, race.trackType);
}

// Resolve — noise uses VRF seed + block.prevrandao (unknowable until this block)
function resolveRace(uint256 raceId) external {
    Race storage race = races[raceId];
    // ...
    for (uint8 b = 0; b < NUM_BULLS; b++) {
        uint256 noiseRand = uint256(keccak256(abi.encode(
            race.vrfSeed2, "noise", b, block.prevrandao
        )));
        uint8 noise = uint8(noiseRand % 31); // 0-30, centered at 15
        scores[b] = computeScore(race.bullStats[b], race.trackType, noise);
    }
    // ...
}
```

**Remaining limitation**: `block.prevrandao` on Monad comes from the sequencer, which could theoretically influence it. For v1 this is acceptable — the sequencer would need to know the specific race outcome they want AND be willing to manipulate block production for it, which is economically impractical for small pots. For v2, consider a third VRF call for noise.

---

## Pari-Mutuel Payout Math

Must be explicitly defined to avoid ambiguity.

**How it works (standard pari-mutuel):**
```
Total pool:     All bets across all bulls
Winner pool:    All bets placed on the winning bull
Manager cut:    10% of total pool
Payout pool:    Total pool - manager cut (90%)

Each winner gets: (their bet / winner pool) × payout pool
```

**Example:**
```
Bull A: 60 MON (3 bettors: 30 + 20 + 10)
Bull B: 30 MON (2 bettors: 20 + 10)
Bull C: 10 MON (1 bettor: 10)
─────────────────────────────
Total pool: 100 MON

Bull B wins!
  Manager cut:  10 MON (10%)
  Payout pool:  90 MON

  Bettor who bet 20 on B:  90 × (20/30) = 60 MON  → 3x return
  Bettor who bet 10 on B:  90 × (10/30) = 30 MON  → 3x return

  Bettors on A and C: lose their bets entirely.
```

**Edge case: No one bet on the winner**
- Try 2nd place, then 3rd place, etc.
- If no finisher has any bets → refund all bets (minus gas)
- Do NOT roll over pots — creates complexity and incentive issues

**Edge case: Only one bull has bets**
- That bull wins → bettors get back 90% (manager still takes 10%)
- That bull loses → same payout logic, the betted bull doesn't win, so if no one bet on the actual winner, we fall through to 2nd/3rd place

---

## Security Considerations

### 1. Reentrancy
```solidity
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

// BettingPool.sol
function claimWinnings() external nonReentrant {
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;        // effects before interaction
    payable(msg.sender).transfer(amount);
}
```

### 2. Contract upgradability
First deploy WILL have bugs. Use **UUPS proxy pattern**:
```
Contracts:
  ├── BullRaceProxy.sol          — ERC1967 proxy, holds state
  ├── BullRaceImplementation.sol — logic, upgradeable
  ├── BettingPoolProxy.sol       — ERC1967 proxy, holds state
  └── BettingPoolImpl.sol        — logic, upgradeable
```
Can fix bugs without redeploying and losing state.

### 3. VRF callback delay / failure
If Pyth's keeper doesn't callback within 5 minutes:
```solidity
function cancelRace(uint256 raceId) external {
    require(msg.sender == operator);
    require(races[raceId].state == RaceState.WAITING_VRF);
    require(block.timestamp >= races[raceId].timestamp + 300); // 5 min timeout
    races[raceId].state = RaceState.CANCELLED;
    // Refund any bets (shouldn't be any yet since betting hasn't opened)
    emit RaceCancelled(raceId);
}
```

### 4. Operator key security
The cron wallet can call `startRace`, `revealTrack`, `resolveRace`. If compromised:
- Attacker could skip phases, resolve early, or grief the system
- **Mitigation**: Use a timelock or require timestamp checks (already in place)
- **v2**: Multisig or decentralized keepers

### 5. Front-running / MEV
Bots can see pending `placeBet` transactions and front-run them.
- On Monad, the sequencer has ordering power
- **Mitigation for v1**: Accept it. Pari-mutuel pools are hard to front-run profitably because your bet increases the pool for that bull, reducing your own payout ratio
- **v2**: Private mempool or commit-reveal bets

### 6. Whale manipulation
A whale bets 1000 MON on the likely winner right before bets close.
- Other bettors' share of the pool is diluted
- **Mitigation**: Max bet cap (e.g., 10% of current pool or fixed max)
- Or: progressive fee — larger bets pay higher % (1% on small bets, 5% on large)

---

## Bet Token Decision

| Option          | Pros                           | Cons                        |
|-----------------|--------------------------------|-----------------------------|
| **Native MON**  | No approve step, simpler UX    | Can't pause/freeze          |
| **ERC-20 token**| Can add tokenomics, staking    | Extra approve tx, complexity |

**Recommendation: Native MON for v1.** Simpler for users and agents. No token approval step means fewer transactions. Can always add a MOONAD token in v2 with staking / governance.

---

## Frontend / UI Design

The current `index.html` is a static 3D demo. It needs to become a full betting interface that syncs to onchain race state. Everything follows the terminal CLI aesthetic from `design-system.xml`.

### Tech Stack

```
Frontend (single-page, no framework):
  ├── Three.js 0.160.0     — 3D bull race scene (existing)
  ├── ethers.js v6          — contract reads/writes (lighter than wagmi for vanilla JS)
  ├── MetaMask / injected   — wallet connect via window.ethereum
  └── All inline in index.html (existing pattern, keep it simple for v1)
```

No React, no build step. Keep the existing single-file approach.

### Race State Polling

```js
// Poll contract every 3 seconds
const race = await bullRace.getRace(currentRaceId);
const state = race.state;

switch (state) {
  case 0: // NONE           → "NO ACTIVE RACE"
  case 1: // WAITING_STATS  → "GENERATING BULLS..."
  case 2: // BETTING        → show stats + bet UI
  case 3: // WAITING_TRACK  → "REVEALING TRACK..."
  case 4: // SWITCHING      → show track + switch UI
  case 5: // RESOLVED       → show results + claim
  case 6: // CANCELLED      → "RACE CANCELLED — REFUNDS AVAILABLE"
}
```

### Layout — 5 UI Zones

```
┌──────────────────────────────────────────────────────────────────┐
│ [SYS] > MOONAD // RACE #1847        POOL: 342.5 MON    00:07:23│ ← TITLE BAR
├──────────────────────────────────────────────────────────────────┤
│                                                    ┌────────────┤
│                                                    │ LEADERBOARD│
│              3D BULL RACE SCENE                     │ 01. Bull A │ ← RIGHT
│              (existing Three.js)                    │ 02. Bull B │   PANEL
│                                                    │ 03. Bull C │
│                                                    │ ...        │
│                                                    ├────────────┤
│                                                    │ YOUR BET   │
│                                                    │ Bull: #4   │ ← BET
│                                                    │ Amt: 5 MON │   INFO
│                                                    │ [SWITCH]   │
│                                                    └────────────┤
├──────────────────────────────────────────────────────────────────┤
│ ┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌──────┐┌─────┐│
│ │BULL 1││BULL 2││BULL 3││BULL 4││BULL 5││BULL 6││BULL 7││BULL8││ ← BULL
│ │SPD: 8││SPD: 3││SPD: 6││SPD: 9││SPD: 4││SPD: 7││SPD: 2││SPD5││   CARDS
│ │STA: 4││STA: 9││STA: 5││STA: 2││STA: 8││STA: 3││STA: 7││STA6││   (bottom)
│ │[BET] ││[BET] ││[BET] ││[BET] ││[BET] ││[BET] ││[BET] ││BET ││
│ └──────┘└──────┘└──────┘└──────┘└──────┘└──────┘└──────┘└─────┘│
├──────────────────────────────────────────────────────────────────┤
│ > TRACK: ???  |  PHASE: BETTING  |  CAM: CHASE  |  BAL: 12 MON │ ← STATUS BAR
└──────────────────────────────────────────────────────────────────┘
```

### Phase-by-Phase UI States

#### Phase: WAITING (min 0:00 – 5:00)
```
┌──────────────────────────────────────────────────────┐
│ [SYS] > MOONAD // RACE #1847     NEXT IN: 04:32     │
├──────────────────────────────────────────────────────┤
│                                                      │
│                                                      │
│              > GENERATING BULLS..._                  │
│              [loading animation]                     │
│                                                      │
│                                                      │
├──────────────────────────────────────────────────────┤
│ > TRACK: ---  |  BETS: CLOSED  |  POOL: 0 MON       │
└──────────────────────────────────────────────────────┘
```
- 3D scene shows empty lanes with start gate
- Large center text with blinking cursor
- No betting UI visible

#### Phase: BETTING (min 5:00 – 10:00)
```
Bull cards appear along the bottom. Each card:
┌─ CRIMSON THUNDER ──────┐
│ SPD ████████░░  8      │
│ STA ███░░░░░░░  3      │
│ ACC █████████░  9      │
│ STR ██░░░░░░░░  2      │
│ AGI █████░░░░░  5      │
│ TMP █████████░  9  ⚡  │  ← flicker icon for high temper
├────────────────────────┤
│ POOL: 12.4 MON         │  ← how much bet on this bull
│ ODDS: 4.2x             │  ← implied payout multiplier
├────────────────────────┤
│ ┌────────────────────┐ │
│ │  [BET ON THIS BULL]│ │  ← click to select
│ └────────────────────┘ │
└────────────────────────┘
```

When a bull card is clicked, a **bet input modal** appears:
```
┌─ PLACE BET ──────────────────────┐
│                                  │
│  Bull: CRIMSON THUNDER           │
│  ┌──────────────────────┐       │
│  │ Amount: [____] MON   │       │
│  └──────────────────────┘       │
│                                  │
│  Min: 0.01 MON | Max: 100 MON   │
│  Est. return: ~4.2x             │
│                                  │
│  ┌────────┐  ┌────────┐         │
│  │ CANCEL │  │ CONFIRM│         │
│  └────────┘  └────────┘         │
│                                  │
│  > betting closes in 04:12_      │
└──────────────────────────────────┘
```

**Live odds update**: As bets come in, each bull card's `POOL` and `ODDS` update in real-time (poll every 3s). Odds = total pool / bull pool.

**3D scene**: Bulls walk in and idle at start gate. Bull models show visual trait hints (strength = bulk, temper = flicker).

#### Phase: TRACK REVEAL (min 10:00 – 10:02)
The dramatic moment. Full-screen flash:
```
┌──────────────────────────────────────────────────────┐
│                                                      │
│                                                      │
│           ████████████████████████████                │
│           █  > TRACK: THUNDERSTORM  █                │
│           ████████████████████████████                │
│                                                      │
│                                                      │
└──────────────────────────────────────────────────────┘
```
- 2-second glitch transition
- 3D scene transforms: colors, fog, particles, ground geometry
- Track name flashes in large amber text
- Then fades to switching phase

#### Phase: SWITCHING (min 10:00 – 13:00)
Same as betting layout, but with changes:
```
┌─ YOUR BET ─────────────────────┐
│                                │
│  Bull: CRIMSON THUNDER         │
│  Amount: 5.0 MON               │
│  Temper: 9 ⚡ on THUNDERSTORM  │
│  > WARNING: HIGH TEMPER BULL   │  ← context-aware warning
│    ON FEAR TRACK (-0.8 mult)   │
│                                │
│  ┌──────────────────────────┐  │
│  │ SWITCH BET (5% FEE)     │  │  ← amber button
│  │ You keep: 4.75 MON       │  │
│  └──────────────────────────┘  │
│                                │
│  > switching closes in 02:45_  │
└────────────────────────────────┘
```

**Smart warnings**: The UI checks if your betted bull has bad traits for the revealed track and warns you. Examples:
- High temper on Thunderstorm/Night → "WARNING: HIGH TEMPER ON FEAR TRACK"
- High speed on Mud Pit → "WARNING: SPEED PENALIZED ON MUD"
- Low stamina on Endurance → "WARNING: LOW STAMINA ON LONG TRACK"

**Switch flow**: Click SWITCH → select new bull → confirm → 5% deducted, bet moves.

#### Phase: RACE (min 13:00 – 13:15)
```
┌──────────────────────────────────────────────────────┐
│ [SYS] > RACE #1847 // THUNDERSTORM    00:00:08.3    │
├──────────────────────────────────────────────────────┤
│                                                      │
│           [3D RACE IN PROGRESS]                      │
│           Bulls running with track-specific effects  │
│                                                      │
│                                        ┌────────────┤
│                                        │ LIVE       │
│                                        │ 1. Bull E  │
│                                        │ 2. Bull C  │
│                                        │ 3. Bull A ←│ YOUR BET
│                                        │ 4. Bull F  │
│                                        │ ...        │
│                                        └────────────┤
├──────────────────────────────────────────────────────┤
│ > BETS LOCKED  |  TRACK: THUNDERSTORM  |  RACING... │
└──────────────────────────────────────────────────────┘
```
- Bull cards collapse away — full focus on 3D scene
- Leaderboard shows live positions
- Your bet highlighted with arrow marker
- No interaction possible (bets locked)

#### Phase: RESULTS (min 13:15 – 15:00)
```
┌──────────────────────────────────────────────────────┐
│ [SYS] > RACE #1847 COMPLETE                         │
├──────────────────────────────────────────────────────┤
│  ┌─ RESULTS ───────────────────────────────────────┐ │
│  │                                                 │ │
│  │  > WINNER: EMERALD FURY                         │ │
│  │  > TIME: 00:42.3                                │ │
│  │  > TRACK: THUNDERSTORM                          │ │
│  │                                                 │ │
│  │  01. Emerald Fury     score: 67   [WINNER]      │ │
│  │  02. Silver Bullet    score: 61                  │ │
│  │  03. Golden Horns     score: 58                  │ │
│  │  04. Copper Beast     score: 52                  │ │
│  │  05. Midnight Storm   score: 48                  │ │
│  │  06. Violet Charge    score: 41                  │ │
│  │  07. Scarlet Blaze    score: 35                  │ │
│  │  08. Crimson Thunder  score: 18  ← YOUR BET     │ │
│  │                                                 │ │
│  │  TOTAL POT: 342.5 MON                           │ │
│  │  YOUR BET: 5.0 MON on Crimson Thunder (8th)     │ │
│  │  RESULT: LOST                                    │ │
│  │                                                 │ │
│  │  > next race in 01:23_                          │ │
│  └─────────────────────────────────────────────────┘ │
├──────────────────────────────────────────────────────┤
│ > BALANCE: 12.0 MON  |  [CLAIM WINNINGS]            │
└──────────────────────────────────────────────────────┘
```

If you WON:
```
│  YOUR BET: 5.0 MON on Emerald Fury (1st!)           │
│  RESULT: WON — 14.2 MON (+9.2 MON profit)           │
│                                                      │
│  ┌──────────────────────────┐                        │
│  │  [CLAIM 14.2 MON]       │  ← green pulsing       │
│  └──────────────────────────┘                        │
```

### Wallet Connection

Top-right corner, always visible:
```
Not connected:
  ┌──────────────────┐
  │ [CONNECT WALLET] │  ← green border
  └──────────────────┘

Connected:
  ┌─────────────────────────────┐
  │ 0x1a2b...3c4d | 12.0 MON  │
  │ [CLAIM: 14.2 MON]          │  ← only shows if balance > 0
  └─────────────────────────────┘
```

**Connect flow:**
1. Click CONNECT WALLET
2. MetaMask popup → approve
3. If wrong chain → auto-prompt "Switch to Monad"
4. Once connected, all bet/claim buttons become active

```js
// Minimal wallet connect (no wagmi, just ethers.js)
async function connectWallet() {
    if (!window.ethereum) {
        alert('Install MetaMask');
        return;
    }
    const provider = new ethers.BrowserProvider(window.ethereum);
    const accounts = await provider.send('eth_requestAccounts', []);

    // Check chain (Monad mainnet chainId)
    const network = await provider.getNetwork();
    if (network.chainId !== MONAD_CHAIN_ID) {
        await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: ethers.toQuantity(MONAD_CHAIN_ID) }],
        });
    }

    const signer = await provider.getSigner();
    bullRace = new ethers.Contract(BULL_RACE_ADDR, BULL_RACE_ABI, signer);
    bettingPool = new ethers.Contract(BETTING_POOL_ADDR, BETTING_POOL_ABI, signer);
}
```

### Complete UI Element Map

```
┌─ ALWAYS VISIBLE ─────────────────────────────────────────────────┐
│  Title bar:      Race #, pool size, countdown timer              │
│  Wallet button:  Top-right, connect/address/balance              │
│  Camera controls: Bottom-left (FREE/TOP/SIDE/FRONT/CHASE)       │
│  Status bar:     Bottom, track type, phase, camera mode          │
│  CRT overlay:    Scanlines (existing)                            │
└──────────────────────────────────────────────────────────────────┘

┌─ PHASE-DEPENDENT ────────────────────────────────────────────────┐
│  WAITING:    Center text "GENERATING BULLS..."                   │
│  BETTING:    Bull cards (bottom), bet modal, pool/odds per bull  │
│  SWITCHING:  Bull cards + track banner + switch button + warnings│
│  RACING:     Live leaderboard (right), no controls               │
│  RESULTS:    Results panel (center), claim button, next countdown │
│  CANCELLED:  "RACE CANCELLED" + refund button                    │
└──────────────────────────────────────────────────────────────────┘

┌─ CONDITIONAL ────────────────────────────────────────────────────┐
│  Bet modal:      When clicking a bull card                       │
│  Switch modal:   When clicking SWITCH during switching phase     │
│  Claim banner:   When user has unclaimed balance > 0             │
│  Smart warnings: When your bet + track = bad combo               │
└──────────────────────────────────────────────────────────────────┘
```

### CSS Additions Needed

```css
/* Betting cards — bottom panel */
#bull-cards {
    position: fixed; bottom: 28px; left: 0; right: 0;
    display: flex; gap: 4px; padding: 0 10px;
    z-index: 50; overflow-x: auto;
}
.bull-card {
    background: rgba(10, 10, 10, 0.95);
    border: 1px solid var(--muted);
    padding: 8px; min-width: 140px;
    font-size: 10px; color: var(--primary);
    flex-shrink: 0; cursor: pointer;
}
.bull-card:hover { border-color: var(--primary); }
.bull-card.selected { border-color: var(--secondary); background: rgba(255,176,0,0.1); }
.bull-card .stat-bar { display: inline-block; height: 8px; background: var(--primary); }

/* Bet modal */
#bet-modal {
    position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%);
    background: var(--bg); border: 1px solid var(--primary);
    padding: 20px; z-index: 70; min-width: 300px;
    display: none;
}
#bet-modal input {
    background: var(--bg); border: 1px solid var(--muted);
    color: var(--primary); font-family: var(--font);
    padding: 6px 10px; font-size: 14px; width: 100%;
}

/* Track reveal flash */
#track-reveal {
    position: fixed; top: 0; left: 0; width: 100%; height: 100%;
    display: none; z-index: 80;
    background: var(--bg);
    justify-content: center; align-items: center;
}
#track-reveal .track-name {
    font-size: 8vw; font-weight: 800;
    color: var(--secondary);
    text-shadow: 0 0 30px rgba(255,176,0,0.5);
    letter-spacing: 0.1em;
}

/* Claim banner */
#claim-banner {
    position: fixed; top: 35px; left: 10px;
    background: rgba(10,10,10,0.95); border: 1px solid var(--primary);
    padding: 8px 12px; z-index: 55; cursor: pointer;
    color: var(--primary); font-size: 12px;
    animation: pulse-border 1.5s infinite;
}
@keyframes pulse-border {
    0%, 100% { border-color: var(--primary); }
    50% { border-color: var(--secondary); }
}

/* Warning badge */
.warning-badge {
    color: var(--error); font-size: 9px;
    border: 1px solid var(--error); padding: 1px 4px;
}
```

---

## Open Questions

- [x] ~~Exact timing~~ → 15-min cycle
- [x] ~~VRF provider~~ → Pyth Entropy on Monad mainnet
- [x] ~~Track predictability~~ → Two VRF calls + block.prevrandao for noise
- [x] ~~Bet token~~ → Native MON for v1
- [ ] Minimum/maximum bet amounts? (suggest: 0.01 MON min, 10% of pool max)
- [ ] Should bull names/colors be fixed or also randomized per race?
- [ ] Leaderboard for top bettors? Streak bonuses?
- [ ] Should the 1-hour maintenance window be at a fixed time or rolling?
- [ ] What if the same track type appears 3+ times in a row? Force variety?
- [ ] Agent SDK/API — dedicated package for bot developers to build betting agents?
