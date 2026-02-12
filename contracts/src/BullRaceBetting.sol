// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BullRaceBetting is ReentrancyGuard, Ownable {

    // ======== CONSTANTS ========
    uint256 public constant HOUSE_RAKE_BPS = 1000; // 10%
    uint256 public constant SWITCH_FEE_BPS = 500;  // 5%
    uint256 private constant BPS_BASE = 10000;

    // ======== ENUMS ========
    enum RaceState { BETTING, CLOSED, RESOLVED }

    // ======== STRUCTS ========
    struct Race {
        RaceState state;
        uint8 numBulls;
        uint8 winningBullId;
        uint256 totalPool;
        uint256 rakeAccumulated;
        mapping(uint8 => uint256) bullPools;
        mapping(address => uint8) userBullId;
        mapping(address => uint256) userBetAmount;
        mapping(address => bool) hasBet;
        mapping(address => bool) hasClaimed;
    }

    // ======== STATE ========
    uint256 public nextRaceId;
    uint256 public houseRake;
    mapping(uint256 => Race) private races;

    // ======== EVENTS ========
    event RaceCreated(uint256 indexed raceId, uint8 numBulls);
    event BetPlaced(uint256 indexed raceId, address indexed bettor, uint8 bullId, uint256 amount);
    event BetSwitched(uint256 indexed raceId, address indexed bettor, uint8 oldBullId, uint8 newBullId, uint256 fee);
    event BettingClosed(uint256 indexed raceId);
    event RaceResolved(uint256 indexed raceId, uint8 winningBullId, uint256 totalPool);
    event WinningsClaimed(uint256 indexed raceId, address indexed bettor, uint256 payout);
    event EmergencyRefund(uint256 indexed raceId, address indexed bettor, uint256 amount);
    event RakeWithdrawn(address indexed to, uint256 amount);

    // ======== CONSTRUCTOR ========
    constructor() Ownable(msg.sender) {}

    // ======== OWNER FUNCTIONS ========

    function createRace(uint8 numBulls) external onlyOwner returns (uint256 raceId) {
        require(numBulls >= 2 && numBulls <= 16, "Invalid bull count");
        raceId = nextRaceId++;
        Race storage race = races[raceId];
        race.state = RaceState.BETTING;
        race.numBulls = numBulls;
        emit RaceCreated(raceId, numBulls);
    }

    function closeBetting(uint256 raceId) external onlyOwner {
        Race storage race = races[raceId];
        require(race.state == RaceState.BETTING, "Not in betting state");
        race.state = RaceState.CLOSED;
        emit BettingClosed(raceId);
    }

    function resolveRace(uint256 raceId, uint8 winningBullId) external onlyOwner {
        Race storage race = races[raceId];
        require(race.state == RaceState.CLOSED, "Not in closed state");
        require(winningBullId < race.numBulls, "Invalid bull ID");
        race.winningBullId = winningBullId;
        // Deduct house rake from total pool
        uint256 rake = (race.totalPool * HOUSE_RAKE_BPS) / BPS_BASE;
        race.rakeAccumulated = rake;
        houseRake += rake;
        race.state = RaceState.RESOLVED;
        emit RaceResolved(raceId, winningBullId, race.totalPool);
    }

    function emergencyRefund(uint256 raceId, address[] calldata bettors) external onlyOwner {
        Race storage race = races[raceId];
        require(race.state != RaceState.RESOLVED, "Already resolved");
        for (uint256 i = 0; i < bettors.length; i++) {
            address bettor = bettors[i];
            if (race.hasBet[bettor] && !race.hasClaimed[bettor]) {
                uint256 amount = race.userBetAmount[bettor];
                race.hasClaimed[bettor] = true;
                race.bullPools[race.userBullId[bettor]] -= amount;
                race.totalPool -= amount;
                (bool ok, ) = payable(bettor).call{value: amount}("");
                require(ok, "Refund transfer failed");
                emit EmergencyRefund(raceId, bettor, amount);
            }
        }
    }

    function withdrawRake(address to) external onlyOwner {
        require(to != address(0), "Zero address");
        uint256 amount = houseRake;
        require(amount > 0, "No rake to withdraw");
        houseRake = 0;
        (bool ok, ) = payable(to).call{value: amount}("");
        require(ok, "Rake transfer failed");
        emit RakeWithdrawn(to, amount);
    }

    // ======== PUBLIC FUNCTIONS ========

    function placeBet(uint256 raceId, uint8 bullId) external payable nonReentrant {
        Race storage race = races[raceId];
        require(race.state == RaceState.BETTING, "Betting not open");
        require(bullId < race.numBulls, "Invalid bull ID");
        require(!race.hasBet[msg.sender], "Already bet");
        require(msg.value > 0, "Bet must be > 0");

        race.hasBet[msg.sender] = true;
        race.userBullId[msg.sender] = bullId;
        race.userBetAmount[msg.sender] = msg.value;
        race.bullPools[bullId] += msg.value;
        race.totalPool += msg.value;

        emit BetPlaced(raceId, msg.sender, bullId, msg.value);
    }

    function switchBet(uint256 raceId, uint8 newBullId) external nonReentrant {
        Race storage race = races[raceId];
        require(race.state == RaceState.BETTING, "Betting not open");
        require(race.hasBet[msg.sender], "No existing bet");
        require(newBullId < race.numBulls, "Invalid bull ID");

        uint8 oldBullId = race.userBullId[msg.sender];
        require(newBullId != oldBullId, "Same bull");

        uint256 oldAmount = race.userBetAmount[msg.sender];
        uint256 fee = (oldAmount * SWITCH_FEE_BPS) / BPS_BASE;
        uint256 newAmount = oldAmount - fee;

        // Update pools
        race.bullPools[oldBullId] -= oldAmount;
        race.bullPools[newBullId] += newAmount;
        race.totalPool -= fee;

        // Update user state
        race.userBullId[msg.sender] = newBullId;
        race.userBetAmount[msg.sender] = newAmount;

        // Fee goes to house rake
        houseRake += fee;

        emit BetSwitched(raceId, msg.sender, oldBullId, newBullId, fee);
    }

    function claimWinnings(uint256 raceId) external nonReentrant {
        Race storage race = races[raceId];
        require(race.state == RaceState.RESOLVED, "Not resolved");
        require(race.hasBet[msg.sender], "No bet placed");
        require(!race.hasClaimed[msg.sender], "Already claimed");
        require(race.userBullId[msg.sender] == race.winningBullId, "Not a winner");

        race.hasClaimed[msg.sender] = true;

        uint256 netPool = race.totalPool - race.rakeAccumulated;
        uint256 userBet = race.userBetAmount[msg.sender];
        uint256 winningPool = race.bullPools[race.winningBullId];
        uint256 payout = (netPool * userBet) / winningPool;

        (bool ok, ) = payable(msg.sender).call{value: payout}("");
        require(ok, "Claim transfer failed");

        emit WinningsClaimed(raceId, msg.sender, payout);
    }

    // ======== VIEW FUNCTIONS ========

    function getRaceInfo(uint256 raceId) external view returns (
        RaceState state,
        uint8 numBulls,
        uint8 winningBullId,
        uint256 totalPool
    ) {
        Race storage race = races[raceId];
        return (race.state, race.numBulls, race.winningBullId, race.totalPool);
    }

    function getBullPool(uint256 raceId, uint8 bullId) external view returns (uint256) {
        return races[raceId].bullPools[bullId];
    }

    function getUserBet(uint256 raceId, address user) external view returns (
        bool hasBet,
        uint8 bullId,
        uint256 amount,
        bool claimed
    ) {
        Race storage race = races[raceId];
        return (race.hasBet[user], race.userBullId[user], race.userBetAmount[user], race.hasClaimed[user]);
    }

    function getPotentialPayout(uint256 raceId, uint8 bullId, uint256 betAmount) external view returns (uint256) {
        Race storage race = races[raceId];
        uint256 newTotal = race.totalPool + betAmount;
        uint256 newBullPool = race.bullPools[bullId] + betAmount;
        uint256 netPool = (newTotal * (BPS_BASE - HOUSE_RAKE_BPS)) / BPS_BASE;
        return (netPool * betAmount) / newBullPool;
    }
}
