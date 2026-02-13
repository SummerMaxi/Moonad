// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IEntropyV2} from "@pythnetwork/entropy-sdk-solidity/IEntropyV2.sol";
import {IEntropyConsumer} from "@pythnetwork/entropy-sdk-solidity/IEntropyConsumer.sol";

contract Moonad is ReentrancyGuard, Ownable, Pausable, IEntropyConsumer {
    using SafeERC20 for IERC20;

    // ======== CONSTANTS ========
    uint256 public constant HOUSE_RAKE_BPS = 1000; // 10% total rake
    uint256 public constant SWITCH_FEE_BPS = 500;  // 5%
    uint256 public constant SEEDER_RAKE_BPS = 200;  // 2% of pool goes to seeder (out of the 10%)
    uint256 private constant BPS_BASE = 10000;

    // Track multipliers: 10 track types × 6 stats (SPD, STA, ACC, STR, AGI, TMP)
    // Values match the frontend TRACK_MULTIPLIERS exactly.
    int8[6][10] private TRACK_MULTIPLIERS = [
        [int8(10),  1,  9,  1,  2,  4],   // Flat Sprint
        [int8( 5), 10,  0,  3,  1, -3],   // Endurance
        [int8(-4),  6, -2, 10,  3, -3],   // Mud Pit
        [int8(-2),  2,  3,  1, 10, -5],   // Rocky Canyon
        [int8(-2),  8,  2,  9,  1,  0],   // Steep Incline
        [int8( 8),  1,  1,  5,  5, -6],   // Downhill Rush
        [int8( 1),  2,  8, -3, 10,  3],   // Zigzag
        [int8( 1),  5,  1,  2,  6, -8],   // Thunderstorm
        [int8(-5),  7, -3,  9,  2, -2],   // Sand Dunes
        [int8( 3),  5,  2,  1,  6, -7]    // Night Trail
    ];

    // ======== ENUMS ========
    enum RacePhase { BETTING, SWITCHING, CLOSED, RESOLVED, CANCELLED }

    // ======== STRUCTS ========
    struct RaceConfig {
        address token;           // address(0) = native MON
        uint8   numBulls;
        uint8   trackType;
        bool    resolved;
        bool    cancelled;
        bool    seeded;
        uint8   payoutBullId;   // highest finisher with bets
        address seeder;          // who requested VRF seed — gets seeder reward
        uint256 totalPool;
        uint256 rakeAccumulated;
        bytes32 seed;           // Pyth Entropy randomness (stored for transparency)
        uint8[48] bullStats;    // 6 stats × 8 bulls, flattened
    }

    struct RaceResults {
        uint8[8]   finishOrder;  // bull IDs in finish order (index 0 = winner)
        uint256[8] finishTimes;  // milliseconds
        uint32     resolvedAt;   // timestamp
    }

    struct UserBet {
        uint8   bullId;
        bool    exists;
        bool    claimed;
        uint128 amount;
    }

    struct LeaderboardEntry {
        address player;
        uint256 winnings;
        uint256 wins;
    }

    // ======== STATE ========
    uint256 public epoch;              // UTC 00:00 of start day
    uint256 public cycleDuration = 900;      // 15 minutes
    uint256 public bettingDuration = 480;    // 0:00–8:00
    uint256 public switchingEnd = 660;       // switching ends at 11:00
    uint8   public defaultNumBulls = 8;
    address public defaultRaceToken;         // address(0) = native MON

    // Pyth Entropy
    IEntropyV2 public immutable entropy;

    // VRF request tracking: sequenceNumber → raceId
    mapping(uint64 => uint256) public vrfRequestToRace;

    // Token allowlist: token address => minBetAmount (0 means not accepted)
    mapping(address => uint256) public minBetAmount;
    mapping(address => bool) public acceptedTokens;
    address[] private _acceptedTokenList;

    // Per-token rake accumulation
    mapping(address => uint256) public rakeBalance;

    // Seeder reward balances: seeder address => token => claimable amount
    mapping(address => mapping(address => uint256)) public seederBalance;

    // Leaderboard: cumulative stats per address
    mapping(address => uint256) public totalWinnings;
    mapping(address => uint256) public racesWon;
    mapping(address => uint256) public totalBetsPlaced;

    // On-chain top-10 leaderboard
    LeaderboardEntry[10] public leaderboard;

    // Race data
    mapping(uint256 => RaceConfig) private _races;
    mapping(uint256 => RaceResults) private _results;
    mapping(uint256 => mapping(uint8 => uint256)) public bullPools;
    mapping(uint256 => mapping(address => UserBet)) private _userBets;

    // Track which races have been initialized (first bet or seed request)
    mapping(uint256 => bool) public raceInitialized;

    // ======== EVENTS ========
    event BetPlaced(uint256 indexed raceId, address indexed bettor, uint8 bullId, address token, uint256 amount);
    event BetSwitched(uint256 indexed raceId, address indexed bettor, uint8 oldBullId, uint8 newBullId, uint256 fee);
    event RaceSeedRequested(uint256 indexed raceId, uint64 sequenceNumber);
    event RaceSeeded(uint256 indexed raceId, uint8 trackType, bytes32 seed);
    event RaceResolved(uint256 indexed raceId, uint8[8] finishOrder, uint256[8] finishTimes, uint256 totalPool);
    event WinningsClaimed(uint256 indexed raceId, address indexed bettor, uint256 payout);
    event RefundClaimed(uint256 indexed raceId, address indexed bettor, uint256 amount);
    event RaceCancelled(uint256 indexed raceId);
    event RakeWithdrawn(address indexed token, address indexed to, uint256 amount);
    event SeederRewardCredited(uint256 indexed raceId, address indexed seeder, uint256 amount);
    event SeederRewardClaimed(address indexed seeder, address indexed token, uint256 amount);
    event TokenAdded(address indexed token, uint256 minBet);
    event TokenRemoved(address indexed token);
    event TimingConfigUpdated(uint256 cycle, uint256 betting, uint256 switchingEnd);

    // ======== CONSTRUCTOR ========
    constructor(uint256 _epoch, address _entropy) Ownable(msg.sender) {
        require(_epoch <= block.timestamp, "Epoch must be in the past");
        require(_entropy != address(0), "Zero entropy address");
        epoch = _epoch;
        entropy = IEntropyV2(_entropy);
    }

    // ======== PYTH ENTROPY VRF ========

    /// @notice Returns the Pyth Entropy contract address (required by IEntropyConsumer)
    function getEntropy() internal view override returns (address) {
        return address(entropy);
    }

    /// @notice Request VRF randomness for a race. Anyone can call. Caller pays Entropy fee.
    /// @param raceId The race to seed
    function requestRaceSeed(uint256 raceId) external payable whenNotPaused {
        require(raceId == getCurrentRaceId(), "Can only seed current race");
        RaceConfig storage race = _races[raceId];

        RacePhase phase = getRacePhase(raceId);
        require(
            phase == RacePhase.BETTING || phase == RacePhase.SWITCHING,
            "Too late to seed"
        );
        require(!race.seeded, "Already seeded");

        // Initialize if not yet
        if (!raceInitialized[raceId]) {
            _initRace(raceId, defaultRaceToken);
        }

        // Record seeder (first caller gets credit)
        if (race.seeder == address(0)) {
            race.seeder = msg.sender;
        }

        // Get Entropy fee and request randomness
        uint128 fee = entropy.getFeeV2();
        require(msg.value >= fee, "Insufficient Entropy fee");

        uint64 sequenceNumber = entropy.requestV2{value: fee}();
        vrfRequestToRace[sequenceNumber] = raceId;

        // Refund excess
        if (msg.value > fee) {
            (bool ok, ) = payable(msg.sender).call{value: msg.value - fee}("");
            require(ok, "Refund failed");
        }

        emit RaceSeedRequested(raceId, sequenceNumber);
    }

    /// @notice Pyth Entropy callback — derives stats + trackType on-chain from randomness.
    ///         Called automatically by Pyth keeper network.
    function entropyCallback(
        uint64 sequenceNumber,
        address /* provider */,
        bytes32 randomNumber
    ) internal override {
        uint256 raceId = vrfRequestToRace[sequenceNumber];
        RaceConfig storage race = _races[raceId];

        // Guard: don't overwrite if already seeded
        if (race.seeded) return;

        // Initialize if not yet (edge case: seed requested before any bet)
        if (!raceInitialized[raceId]) {
            _initRace(raceId, defaultRaceToken);
        }

        uint256 randomness = uint256(randomNumber);

        // Store raw randomness for transparency
        race.seed = randomNumber;

        // Derive trackType
        race.trackType = uint8(randomness % 10);

        // Derive 48 bull stats (8 bulls × 6 stats each), values 1-10
        for (uint256 i = 0; i < 48; i++) {
            race.bullStats[i] = uint8(
                (uint256(keccak256(abi.encode(randomness, i))) % 10) + 1
            );
        }

        race.seeded = true;

        emit RaceSeeded(raceId, race.trackType, race.seed);
    }

    /// @notice View: get the current Pyth Entropy fee for seeding a race
    function getEntropyFee() external view returns (uint128) {
        return entropy.getFeeV2();
    }

    // ====================================================================
    //                       TIME / PHASE HELPERS
    // ====================================================================

    function getCurrentRaceId() public view returns (uint256) {
        require(block.timestamp >= epoch, "Before epoch");
        return (block.timestamp - epoch) / cycleDuration;
    }

    function getRaceStartTime(uint256 raceId) public view returns (uint256) {
        return epoch + raceId * cycleDuration;
    }

    function getRacePhase(uint256 raceId) public view returns (RacePhase) {
        RaceConfig storage race = _races[raceId];
        if (race.cancelled) return RacePhase.CANCELLED;
        if (race.resolved) return RacePhase.RESOLVED;

        uint256 raceStart = getRaceStartTime(raceId);
        if (block.timestamp < raceStart) return RacePhase.BETTING; // future race

        uint256 elapsed = block.timestamp - raceStart;

        if (elapsed < bettingDuration) return RacePhase.BETTING;
        if (elapsed < switchingEnd) return RacePhase.SWITCHING;
        return RacePhase.CLOSED;
    }

    function isBettingOpen(uint256 raceId) public view returns (bool) {
        return getRacePhase(raceId) == RacePhase.BETTING;
    }

    function isSwitchingOpen(uint256 raceId) public view returns (bool) {
        RacePhase phase = getRacePhase(raceId);
        return phase == RacePhase.BETTING || phase == RacePhase.SWITCHING;
    }

    function getPhaseTimeRemaining(uint256 raceId) public view returns (uint256) {
        RaceConfig storage race = _races[raceId];
        if (race.cancelled || race.resolved) return 0;

        uint256 raceStart = getRaceStartTime(raceId);
        if (block.timestamp < raceStart) return raceStart - block.timestamp + bettingDuration;

        uint256 elapsed = block.timestamp - raceStart;

        if (elapsed < bettingDuration) {
            return bettingDuration - elapsed;
        } else if (elapsed < switchingEnd) {
            return switchingEnd - elapsed;
        } else if (elapsed < cycleDuration) {
            return cycleDuration - elapsed;
        }
        return 0;
    }

    // ====================================================================
    //                            BETTING
    // ====================================================================

    function placeBet(
        uint256 raceId,
        uint8 bullId,
        address token,
        uint256 amount
    ) external payable nonReentrant whenNotPaused {
        require(raceId == getCurrentRaceId(), "Can only bet current race");
        require(isBettingOpen(raceId), "Betting not open");

        RaceConfig storage race = _races[raceId];

        // Initialize race on first interaction
        if (!raceInitialized[raceId]) {
            _initRace(raceId, token);
        }

        require(token == race.token, "Wrong token for this race");
        require(acceptedTokens[token], "Token not accepted");
        require(bullId < race.numBulls, "Invalid bull ID");

        UserBet storage bet = _userBets[raceId][msg.sender];
        require(!bet.exists, "Already bet");

        // Handle payment
        uint256 betAmount = _collectPayment(token, amount);
        require(betAmount >= minBetAmount[token], "Below minimum bet");

        // Store bet
        bet.bullId = bullId;
        bet.exists = true;
        bet.amount = uint128(betAmount);

        bullPools[raceId][bullId] += betAmount;
        race.totalPool += betAmount;
        totalBetsPlaced[msg.sender] += 1;

        emit BetPlaced(raceId, msg.sender, bullId, token, betAmount);
    }

    function switchBet(uint256 raceId, uint8 newBullId) external nonReentrant whenNotPaused {
        require(isSwitchingOpen(raceId), "Switching not open");

        RaceConfig storage race = _races[raceId];
        UserBet storage bet = _userBets[raceId][msg.sender];

        require(bet.exists, "No existing bet");
        require(newBullId < race.numBulls, "Invalid bull ID");
        require(newBullId != bet.bullId, "Same bull");

        uint8 oldBullId = bet.bullId;
        uint256 oldAmount = uint256(bet.amount);
        uint256 fee = (oldAmount * SWITCH_FEE_BPS) / BPS_BASE;
        uint256 newAmount = oldAmount - fee;

        // Update pools
        bullPools[raceId][oldBullId] -= oldAmount;
        bullPools[raceId][newBullId] += newAmount;
        race.totalPool -= fee;

        // Fee goes to house rake
        rakeBalance[race.token] += fee;
        race.rakeAccumulated += fee;

        // Update user bet
        bet.bullId = newBullId;
        bet.amount = uint128(newAmount);

        emit BetSwitched(raceId, msg.sender, oldBullId, newBullId, fee);
    }

    // ====================================================================
    //                            CLAIMS
    // ====================================================================

    function claimWinnings(uint256 raceId) external nonReentrant {
        RaceConfig storage race = _races[raceId];

        // Lazy resolution: auto-resolve if seeded + CLOSED but not yet resolved
        if (!race.resolved && race.seeded && !race.cancelled && getRacePhase(raceId) == RacePhase.CLOSED) {
            _resolveRace(raceId);
        }
        require(race.resolved, "Not resolved");

        UserBet storage bet = _userBets[raceId][msg.sender];
        require(bet.exists, "No bet placed");
        require(!bet.claimed, "Already claimed");
        require(bet.bullId == race.payoutBullId, "Not a winner");

        bet.claimed = true;

        uint256 netPool = race.totalPool - race.rakeAccumulated;
        uint256 userBet = uint256(bet.amount);
        uint256 winningPool = bullPools[raceId][race.payoutBullId];
        uint256 payout = (netPool * userBet) / winningPool;

        // Update leaderboard stats
        totalWinnings[msg.sender] += payout;
        racesWon[msg.sender] += 1;
        _updateLeaderboard(msg.sender);

        _sendPayment(race.token, msg.sender, payout);

        emit WinningsClaimed(raceId, msg.sender, payout);
    }

    function claimRefund(uint256 raceId) external nonReentrant {
        RaceConfig storage race = _races[raceId];
        // Allow refund if cancelled OR if race ended without a seed (bettors shouldn't lose funds)
        require(
            race.cancelled ||
            (getRacePhase(raceId) == RacePhase.CLOSED && !race.seeded && !race.resolved),
            "Race not refundable"
        );

        UserBet storage bet = _userBets[raceId][msg.sender];
        require(bet.exists, "No bet placed");
        require(!bet.claimed, "Already claimed");

        bet.claimed = true;

        uint256 refundAmount = uint256(bet.amount);
        _sendPayment(race.token, msg.sender, refundAmount);

        emit RefundClaimed(raceId, msg.sender, refundAmount);
    }

    /// @notice Seeders claim accumulated rewards across all races they seeded
    function claimSeederReward(address token) external nonReentrant {
        uint256 amount = seederBalance[msg.sender][token];
        require(amount > 0, "No seeder reward");
        seederBalance[msg.sender][token] = 0;
        _sendPayment(token, msg.sender, amount);
        emit SeederRewardClaimed(msg.sender, token, amount);
    }

    // ====================================================================
    //                    PERMISSIONLESS RACE RESOLUTION
    // ====================================================================

    /// @notice Resolve a race on-chain. Anyone can call — results are deterministic from VRF seed.
    /// @param raceId The race to resolve
    function resolveRace(uint256 raceId) external nonReentrant {
        _resolveRace(raceId);
    }

    /// @notice Internal resolution logic. Called by resolveRace() or lazily by claimWinnings().
    function _resolveRace(uint256 raceId) internal {
        RaceConfig storage race = _races[raceId];

        require(getRacePhase(raceId) == RacePhase.CLOSED, "Race not in closed phase");
        require(!race.resolved, "Already resolved");
        require(!race.cancelled, "Race cancelled");
        require(race.seeded, "Race not seeded");

        // Compute scores and sorted finish order
        (uint8[8] memory finishOrder, uint256[8] memory finishTimes) = _computeResults(
            race.numBulls, race.seed, race.trackType, race.bullStats
        );

        // Distribute rake
        _distributeRake(raceId, race);

        // Find payout bull: first finisher with bets
        for (uint8 i = 0; i < race.numBulls; i++) {
            if (bullPools[raceId][finishOrder[i]] > 0) {
                race.payoutBullId = finishOrder[i];
                break;
            }
        }

        race.resolved = true;

        // Store results
        RaceResults storage results = _results[raceId];
        results.finishOrder = finishOrder;
        results.finishTimes = finishTimes;
        results.resolvedAt = uint32(block.timestamp);

        emit RaceResolved(raceId, finishOrder, finishTimes, race.totalPool);
    }

    /// @notice Compute scores, sort, and derive finish times — pure computation, no state writes.
    function _computeResults(
        uint8 numBulls,
        bytes32 seed,
        uint8 trackType,
        uint8[48] storage bullStats
    ) internal view returns (uint8[8] memory finishOrder, uint256[8] memory finishTimes) {
        int256[8] memory scores;
        int8[6] memory mults = TRACK_MULTIPLIERS[trackType];

        for (uint8 i = 0; i < numBulls; i++) {
            int256 score = 0;
            for (uint8 j = 0; j < 6; j++) {
                int256 stat = int256(uint256(bullStats[i * 6 + j]));
                score += j == 5 ? (stat - 5) * int256(mults[j]) : stat * int256(mults[j]);
            }
            score += int256(uint256(keccak256(abi.encode(seed, i))) % 20);
            scores[i] = score;
        }

        // Sort by score descending (insertion sort, max 8 elements)
        for (uint8 i = 0; i < numBulls; i++) finishOrder[i] = i;
        for (uint8 i = 1; i < numBulls; i++) {
            uint8 key = finishOrder[i];
            int256 keyScore = scores[key];
            uint8 j = i;
            while (j > 0 && scores[finishOrder[j - 1]] < keyScore) {
                finishOrder[j] = finishOrder[j - 1];
                j--;
            }
            finishOrder[j] = key;
        }

        // Derive cosmetic finish times
        int256 topScore = scores[finishOrder[0]];
        for (uint8 i = 0; i < numBulls; i++) {
            finishTimes[i] = 25000 + uint256(topScore - scores[finishOrder[i]]) * 200;
        }
    }

    /// @notice Distribute rake between house and seeder.
    function _distributeRake(uint256 raceId, RaceConfig storage race) internal {
        uint256 totalRake = (race.totalPool * HOUSE_RAKE_BPS) / BPS_BASE;
        uint256 additionalRake = 0;
        if (totalRake > race.rakeAccumulated) {
            additionalRake = totalRake - race.rakeAccumulated;
        }
        race.rakeAccumulated = totalRake;

        uint256 seederCut = 0;
        if (race.seeder != address(0) && race.totalPool > 0) {
            seederCut = (race.totalPool * SEEDER_RAKE_BPS) / BPS_BASE;
            if (seederCut > additionalRake) seederCut = additionalRake;
            seederBalance[race.seeder][race.token] += seederCut;
            emit SeederRewardCredited(raceId, race.seeder, seederCut);
        }
        rakeBalance[race.token] += (additionalRake - seederCut);
    }

    // ====================================================================
    //                        OWNER ADMIN FUNCTIONS
    // ====================================================================

    function cancelRace(uint256 raceId) external onlyOwner {
        RaceConfig storage race = _races[raceId];
        require(!race.resolved, "Already resolved");
        require(!race.cancelled, "Already cancelled");

        race.cancelled = true;

        // Refund any switch-fee rake accumulated for this race
        if (race.rakeAccumulated > 0 && rakeBalance[race.token] >= race.rakeAccumulated) {
            rakeBalance[race.token] -= race.rakeAccumulated;
            race.totalPool += race.rakeAccumulated;
            race.rakeAccumulated = 0;
        }

        emit RaceCancelled(raceId);
    }

    function setEpoch(uint256 _epoch) external onlyOwner {
        require(_epoch <= block.timestamp, "Epoch must be in the past");
        epoch = _epoch;
    }

    function setTimingConfig(
        uint256 _cycleDuration,
        uint256 _bettingDuration,
        uint256 _switchingEnd
    ) external onlyOwner {
        require(_bettingDuration < _switchingEnd, "Betting must end before switching");
        require(_switchingEnd < _cycleDuration, "Switching must end before cycle");
        require(_cycleDuration > 0, "Cycle must be > 0");

        cycleDuration = _cycleDuration;
        bettingDuration = _bettingDuration;
        switchingEnd = _switchingEnd;

        emit TimingConfigUpdated(_cycleDuration, _bettingDuration, _switchingEnd);
    }

    function setNumBulls(uint8 n) external onlyOwner {
        require(n >= 2 && n <= 16, "Invalid bull count");
        defaultNumBulls = n;
    }

    function addAcceptedToken(address token, uint256 _minBet) external onlyOwner {
        if (!acceptedTokens[token]) {
            acceptedTokens[token] = true;
            _acceptedTokenList.push(token);
        }
        minBetAmount[token] = _minBet;
        emit TokenAdded(token, _minBet);
    }

    function removeAcceptedToken(address token) external onlyOwner {
        require(acceptedTokens[token], "Token not accepted");
        acceptedTokens[token] = false;
        for (uint256 i = 0; i < _acceptedTokenList.length; i++) {
            if (_acceptedTokenList[i] == token) {
                _acceptedTokenList[i] = _acceptedTokenList[_acceptedTokenList.length - 1];
                _acceptedTokenList.pop();
                break;
            }
        }
        emit TokenRemoved(token);
    }

    function setMinBetAmount(address token, uint256 _minBet) external onlyOwner {
        require(acceptedTokens[token], "Token not accepted");
        minBetAmount[token] = _minBet;
    }

    function setDefaultRaceToken(address token) external onlyOwner {
        require(acceptedTokens[token], "Token not accepted");
        defaultRaceToken = token;
    }

    function withdrawRake(address token, address to) external onlyOwner {
        require(to != address(0), "Zero address");
        uint256 amount = rakeBalance[token];
        require(amount > 0, "No rake to withdraw");
        rakeBalance[token] = 0;

        _sendPayment(token, to, amount);

        emit RakeWithdrawn(token, to, amount);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    // ====================================================================
    //                         VIEW FUNCTIONS
    // ====================================================================

    function getRaceInfo(uint256 raceId) external view returns (
        RacePhase phase,
        address token,
        uint256 totalPool,
        uint8 numBulls,
        bool resolved,
        bool cancelled
    ) {
        RaceConfig storage race = _races[raceId];
        return (
            getRacePhase(raceId),
            race.token,
            race.totalPool,
            race.numBulls,
            race.resolved,
            race.cancelled
        );
    }

    function getRaceResults(uint256 raceId) external view returns (
        uint8[8] memory finishOrder,
        uint256[8] memory finishTimes,
        uint32 resolvedAt
    ) {
        RaceResults storage results = _results[raceId];
        return (results.finishOrder, results.finishTimes, results.resolvedAt);
    }

    function getRaceSeedData(uint256 raceId) external view returns (
        uint8[48] memory stats,
        uint8 trackType,
        bytes32 seed,
        bool seeded
    ) {
        RaceConfig storage race = _races[raceId];
        return (race.bullStats, race.trackType, race.seed, race.seeded);
    }

    function getBullPool(uint256 raceId, uint8 bullId) external view returns (uint256) {
        return bullPools[raceId][bullId];
    }

    function getAllBullPools(uint256 raceId) external view returns (uint256[8] memory pools) {
        for (uint8 i = 0; i < 8; i++) {
            pools[i] = bullPools[raceId][i];
        }
    }

    function getUserBet(uint256 raceId, address user) external view returns (
        bool exists,
        uint8 bullId,
        uint256 amount,
        bool claimed
    ) {
        UserBet storage bet = _userBets[raceId][user];
        return (bet.exists, bet.bullId, uint256(bet.amount), bet.claimed);
    }

    function getPotentialPayout(
        uint256 raceId,
        uint8 bullId,
        uint256 amount
    ) external view returns (uint256) {
        RaceConfig storage race = _races[raceId];
        uint256 newTotal = race.totalPool + amount;
        uint256 newBullPool = bullPools[raceId][bullId] + amount;
        uint256 netPool = (newTotal * (BPS_BASE - HOUSE_RAKE_BPS)) / BPS_BASE;
        if (newBullPool == 0) return 0;
        return (netPool * amount) / newBullPool;
    }

    function getAcceptedTokens() external view returns (address[] memory) {
        return _acceptedTokenList;
    }

    /// @notice Get the track multipliers for a given track type
    function getTrackMultipliers(uint8 trackType) external view returns (int8[6] memory) {
        require(trackType < 10, "Invalid track type");
        return TRACK_MULTIPLIERS[trackType];
    }

    /// @notice Get the seeder address for a race
    function getRaceSeeder(uint256 raceId) external view returns (address) {
        return _races[raceId].seeder;
    }

    /// @notice Get a seeder's claimable reward balance for a token
    function getSeederBalance(address seeder, address token) external view returns (uint256) {
        return seederBalance[seeder][token];
    }

    // ====================================================================
    //                         LEADERBOARD
    // ====================================================================

    /// @notice Update the top-10 leaderboard after a claim. O(10) worst case.
    function _updateLeaderboard(address player) internal {
        uint256 w = totalWinnings[player];
        uint256 wins = racesWon[player];

        // Check if player is already on the board
        int256 existIdx = -1;
        for (uint256 i = 0; i < 10; i++) {
            if (leaderboard[i].player == player) {
                existIdx = int256(i);
                break;
            }
        }

        if (existIdx >= 0) {
            // Update stats in place
            uint256 idx = uint256(existIdx);
            leaderboard[idx].winnings = w;
            leaderboard[idx].wins = wins;
            // Bubble up if needed
            while (idx > 0 && leaderboard[idx].winnings > leaderboard[idx - 1].winnings) {
                LeaderboardEntry memory tmp = leaderboard[idx - 1];
                leaderboard[idx - 1] = leaderboard[idx];
                leaderboard[idx] = tmp;
                idx--;
            }
        } else {
            // Not on board — check if qualifies (better than last entry)
            if (w > leaderboard[9].winnings) {
                leaderboard[9] = LeaderboardEntry(player, w, wins);
                // Bubble up
                uint256 idx = 9;
                while (idx > 0 && leaderboard[idx].winnings > leaderboard[idx - 1].winnings) {
                    LeaderboardEntry memory tmp = leaderboard[idx - 1];
                    leaderboard[idx - 1] = leaderboard[idx];
                    leaderboard[idx] = tmp;
                    idx--;
                }
            }
        }
    }

    /// @notice Get the full top-10 leaderboard
    function getLeaderboard() external view returns (LeaderboardEntry[10] memory) {
        return leaderboard;
    }

    /// @notice Owner-only: seed leaderboard from old contract data (migration helper)
    function seedLeaderboard(
        address[] calldata players,
        uint256[] calldata winnings,
        uint256[] calldata wins
    ) external onlyOwner {
        require(players.length == winnings.length && players.length == wins.length, "Length mismatch");
        require(players.length <= 10, "Max 10 entries");
        for (uint256 i = 0; i < players.length; i++) {
            leaderboard[i] = LeaderboardEntry(players[i], winnings[i], wins[i]);
            totalWinnings[players[i]] = winnings[i];
            racesWon[players[i]] = wins[i];
        }
    }

    // ====================================================================
    //                         INTERNAL HELPERS
    // ====================================================================

    function _initRace(uint256 raceId, address token) internal {
        RaceConfig storage race = _races[raceId];
        race.token = token;
        race.numBulls = defaultNumBulls;
        raceInitialized[raceId] = true;
    }

    function _collectPayment(address token, uint256 amount) internal returns (uint256) {
        if (token == address(0)) {
            // Native MON
            require(msg.value > 0, "No value sent");
            return msg.value;
        } else {
            // ERC20
            require(msg.value == 0, "Do not send MON with ERC20 bet");
            require(amount > 0, "Amount must be > 0");
            IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
            return amount;
        }
    }

    function _sendPayment(address token, address to, uint256 amount) internal {
        if (token == address(0)) {
            (bool ok, ) = payable(to).call{value: amount}("");
            require(ok, "Native transfer failed");
        } else {
            IERC20(token).safeTransfer(to, amount);
        }
    }

    /// @notice Accept native MON for Entropy fees
    receive() external payable {}
}
