# Moonad - Bull Race

On-chain bull racing game on Monad. Bet on 3D animated bulls, watch them race, claim winnings — all trustless via smart contracts and Pyth VRF.

**Live:** [moonad.fun](https://moonad.fun)

## How It Works

1. **Betting Phase** — Pick a bull and place a MON bet
2. **Switching Phase** — Track type is revealed; switch your bet (5% fee) or hold
3. **Racing Phase** — Bulls race based on VRF-generated stats and track modifiers
4. **Results** — Winner takes the pool (10% rake: 8% house, 2% seeder reward)

Race outcomes are fully deterministic from the on-chain VRF seed — anyone can verify results.

## Architecture

```
index.html          -- Complete frontend (Three.js 3D scene, ethers.js, wallet integration)
contracts/
  src/Moonad.sol    -- Solidity smart contract (betting, switching, VRF, resolution, payouts)
  foundry.toml      -- Foundry config
```

The frontend is a single-file application — no build step, no framework. Serve `index.html` over HTTP and it works.

## Setup

### Frontend

```bash
# Serve locally
python3 -m http.server 8080

# Open http://localhost:8080
```

### Smart Contract

Requires [Foundry](https://book.getfoundry.sh/getting-started/installation).

```bash
cd contracts

# Install dependencies
forge install

# Build
forge build

# Run tests
forge test
```

### Deploy Contract

```bash
cd contracts
forge create src/Moonad.sol:Moonad \
  --rpc-url https://rpc.monad.xyz \
  --private-key $DEPLOYER_PRIVATE_KEY \
  --constructor-args $EPOCH_TIMESTAMP $PYTH_ENTROPY_ADDRESS
```

After deployment, configure accepted tokens and timing via owner functions.

## Contract Details

- **Network:** Monad (Chain ID 143)
- **Contract:** [`0xc86Ee7CBf1D643922faaEB4Ff3618838407546C1`](https://monadexplorer.com/address/0xc86Ee7CBf1D643922faaEB4Ff3618838407546C1)
- **Race Cycle:** 15 minutes (8 min betting, 3 min switching, 4 min racing/resolution)
- **VRF:** Pyth Entropy v2 — generates bull stats, track type, and race randomness
- **Rake:** 10% of pool (8% house, 2% seeder)
- **Switch Fee:** 5% of bet amount

## Tech Stack

### Frontend
- [Three.js](https://threejs.org/) v0.160.0 — 3D rendering, skeletal animation
- [ethers.js](https://docs.ethers.org/) v6.13.4 — Blockchain interaction
- [Reown AppKit](https://reown.com/) v1.8.18 — Wallet connection (WalletConnect)
- [JetBrains Mono](https://www.jetbrains.com/lp/mono/) / [VT323](https://fonts.google.com/specimen/VT323) — Terminal aesthetic fonts

### Smart Contract
- [Solidity](https://soliditylang.org/) ^0.8.20
- [OpenZeppelin Contracts](https://www.openzeppelin.com/contracts) — ReentrancyGuard, Ownable, Pausable, SafeERC20
- [Pyth Entropy SDK](https://docs.pyth.network/entropy) — On-chain VRF for verifiable randomness
- [Foundry](https://book.getfoundry.sh/) — Build, test, deploy

### 3D Assets
- Bull model with 75 skeletal animations (FBX format, converted to GLB at runtime)

## Agent Integration

Moonad is built to be played by autonomous agents. The repo includes a ready-to-use agent skill file ([`skill.md`](skill.md)) that any AI agent can pick up and start playing with.

### What agents can do
- Read on-chain race data (bull stats, track type, pool sizes, odds)
- Place and switch bets programmatically via smart contract calls
- Seed races with Pyth VRF and earn 2% of the pool as a reward
- Claim winnings automatically after each race
- Run 24/7 across every 15-minute race cycle

### Quick start

```bash
npm install ethers@6

export PRIVATE_KEY="0xYOUR_KEY"
export BET_MON="0.05"
export SEED_RACES="true"  # optional: earn 2% of pool by seeding

node moonad-agent.js
```

The agent template in `skill.md` handles the full game loop — wallet setup, phase detection, betting, claiming. You only need to write your own `chooseBull()` strategy function. Everything else is plug and play.

See [`skill.md`](skill.md) for the complete agent spec including contract ABI, strategy tips, track multipliers, and a working script.

## License

MIT — see [LICENSE](LICENSE).
