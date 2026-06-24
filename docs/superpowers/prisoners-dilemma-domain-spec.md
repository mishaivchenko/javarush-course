# Prisoner's Dilemma — Domain Specification & Knowledge Base

> Based on the Veritasium video transcript "ЩО ТАКЕ ДИЛЕМА В'ЯЗНЯ?" (YouTube), Robert Axelrod's *The Evolution of Cooperation*, and related tournament analyses.
>
> **Purpose:** Foundational reference for building a modular, SOLID-compliant Prisoner's Dilemma simulation engine.

---

## 1. Formal Game Rules

### 1.1 Actions

Each player chooses one of two actions simultaneously (or sequentially with hidden choice):

| Action | Symbol | Meaning |
|--------|--------|---------|
| **Cooperate** | `C` | Trust the partner; stay silent; share. |
| **Defect** | `D` | Betray the partner; confess; take the deal. |

### 1.2 Payoff Matrix (Utility Form — higher is better)

The standard canonical matrix used in Axelrod's tournaments:

| Player A \ Player B | Cooperate (C) | Defect (D) |
|---------------------|:-------------:|:----------:|
| **Cooperate (C)**   | (3, 3)        | (0, 5)     |
| **Defect (D)**      | (5, 0)        | (1, 1)     |

- **(3, 3)** — *Reward (R)*: both cooperate. Mutual benefit.
- **(5, 0)** — *Temptation (T) / Sucker's (S)*: A defects, B cooperates. A gets maximum, B gets minimum.
- **(0, 5)** — *Sucker's (S) / Temptation (T)*: A cooperates, B defects. Reversed symmetry.
- **(1, 1)** — *Punishment (P)*: both defect. Worst collective outcome.

### 1.3 The Dilemma Explained

**Why mutual cooperation > mutual defection:**  
(3, 3) > (1, 1). Both players are better off if they both cooperate.

**Why unilateral defection is tempting:**  
If my opponent cooperates and I defect, I get 5 instead of 3. Greed pulls toward defection.

**Why the dilemma exists:**  
From an individual player's perspective:
- If opponent cooperates → I get 5 by defecting vs 3 by cooperating. Defect wins.
- If opponent defects → I get 1 by defecting vs 0 by cooperating. Defect wins.
- **Defection is a dominant strategy**: regardless of what the opponent does, defecting yields a higher individual payoff. Yet if both follow this logic, both get (1, 1) which is worse for both than (3, 3). The paradox is that rational individual choice leads to a collectively worse outcome.

**The four payoff inequalities that define a Prisoner's Dilemma:**
1. `T > R > P > S` (here: 5 > 3 > 1 > 0)
2. `2R > T + S` (avoid alternating exploitation being better than mutual cooperation)

### 1.4 One-Shot vs Iterated Prisoner's Dilemma

| Aspect | One-Shot (Single Round) | Iterated (Repeated) |
|--------|------------------------|---------------------|
| Rounds | 1                       | N (fixed, indefinite, or probabilistic) |
| Strategy space | Narrow — one decision | Rich — patterns, learning, reciprocity |
| Dominant strategy | Always defect (AllD) | Depends — cooperation can emerge |
| Shadow of the future | None — no consequence | Future rounds create consequences for today's actions |
| Cooperation possible? | No | Yes, under the right conditions |

### 1.5 The Importance of an Uncertain Final Round

**If the final round is known:**
- Rational players defect on the last round (no future consequences).
- Backward induction: if last round is defection, the second-to-last round also has no future, so defect there too.
- This chain collapses all the way to round 1 → defection on every round.
- The iterated game collapses into a one-shot game.

**If the final round is unknown / probabilistic:**
- The "shadow of the future" remains — today's defection can be punished tomorrow.
- Cooperation becomes an equilibrium if the discount factor (probability of continuation) is sufficiently high.
- The condition: `w ≥ (T − R) / (T − P)` where `w` is the probability of another round.

**Implementation consequence:**  
The engine must support matches with a known round count, an unknown/unlimited round count, and a probabilistic continuation (e.g., `continuationProbability` parameter where each round may be the last with `1 − p` chance).

---

## 2. Strategy Registry / Behavioral Models

### 2.1 Character Parameters Framework

Each strategy can be described along the following dimensions. These map directly to class properties in the future implementation.

| Parameter | Type | Range | Meaning |
|-----------|------|-------|---------|
| **Niceness** | float | 0.0–1.0 | Probability of cooperating first, or tendency to initiate cooperation |
| **Retaliation** | float | 0.0–1.0 | How aggressively it punishes defection |
| **Forgiveness** | float | 0.0–1.0 | How quickly it returns to cooperation after punishment |
| **Predictability** | float | 0.0–1.0 | 1.0 = deterministic; 0.0 = random/unpredictable |
| **Exploitability** | float | 0.0–1.0 | 1.0 = easily exploited by defectors; 0.0 = cannot be exploited |
| **Noise Tolerance** | float | 0.0–1.0 | How well it maintains cooperation under perception/action errors |
| **Memory Depth** | int | 0–N | Number of past rounds it remembers to make decisions |

### 2.2 Strategy Catalog

#### 2.2.1 Tit for Tat (TFT) — Anatol Rapoport

| Property | Value |
|----------|-------|
| **Behavioral idea** | Start cooperative, then mirror the opponent's previous move. Simple reciprocity. |
| **First move** | Cooperate |
| **After opponent cooperates** | Cooperate |
| **After opponent defects** | Defect (exactly once) |
| **History needed** | Opponent's last move only |
| **Deterministic?** | Yes |
| **Internal state** | None (or last opponent move) |
| **Strengths** | Nice, retaliatory, forgiving, clear. Won both Axelrod tournaments. |
| **Weaknesses** | Vulnerable to noise (one accidental defection causes a feud). Cannot exploit weak strategies. |
| **Performs well against** | Other nice strategies, diverse fields |
| **Performs poorly against** | Noisy environments, strategies that occasionally probe (Joss, Tester — TFT enters feuds) |

**Character parameters:**

| Niceness | Retaliation | Forgiveness | Predictability | Exploitability | Noise Tolerance | Memory Depth |
|:--------:|:-----------:|:-----------:|:--------------:|:--------------:|:---------------:|:------------:|
| 1.0      | 1.0         | 1.0         | 1.0            | 0.5            | 0.2             | 1            |

---

#### 2.2.2 Joss — John Joss

| Property | Value |
|----------|-------|
| **Behavioral idea** | TFT variant that occasionally defects randomly (~10% chance) even after opponent cooperates, trying to get the temptation payoff. |
| **First move** | Cooperate |
| **After opponent cooperates** | Usually cooperate, but defect with probability ~0.1 |
| **After opponent defects** | Defect (retaliate like TFT) |
| **History needed** | Opponent's last move (plus random seed) |
| **Deterministic?** | No — probabilistic defection |
| **Internal state** | Random number generator state |
| **Strengths** | Can occasionally exploit pure cooperators for extra points |
| **Weaknesses** | Its own 10% defection triggers TFT's retaliation → mutual defection spiral. The loss from feuds outweighs gains from occasional exploitation. |
| **Performs well against** | Very forgiving or unconditional cooperators |
| **Performs poorly against** | TFT, other retaliatory nice strategies |

**Character parameters:**

| Niceness | Retaliation | Forgiveness | Predictability | Exploitability | Noise Tolerance | Memory Depth |
|:--------:|:-----------:|:-----------:|:--------------:|:--------------:|:---------------:|:------------:|
| 0.9      | 1.0         | 0.9         | 0.9            | 0.4            | 0.15            | 1            |

**Note on forgiveness vs predictability:** Joss appears forgiving (0.9) because it usually cooperates after opponent cooperates, but the *probabilistic* nature (not reliably forgiving) is captured by predictability = 0.9.

---

#### 2.2.3 Friedman / Grudger / Grim Trigger — James Friedman

| Property | Value |
|----------|-------|
| **Behavioral idea** | Cooperate until the opponent defects once, then defect forever. Also known as "Grim Trigger" or "Grudger." A permanent grudge. |
| **First move** | Cooperate |
| **After opponent cooperates** | Cooperate |
| **After opponent defects** | Defect for all remaining rounds |
| **History needed** | Has the opponent *ever* defected? (Boolean flag) |
| **Deterministic?** | Yes |
| **Internal state** | `everDefected: boolean` (persistent flag) |
| **Strengths** | Very strong deterrent; establishes cooperation with other nice strategies. Stable in deterministic, noiseless play. |
| **Weaknesses** | Zero forgiveness. One mistake (noise) → permanent mutual defection. Cannot recover. Terrible in noisy environments. |
| **Performs well against** | Other nice strategies, AllD (both defect forever — parity) |
| **Performs poorly against** | Any strategy that defects even once (noise, Tester, Joss). Never recovers. |

**Character parameters:**

| Niceness | Retaliation | Forgiveness | Predictability | Exploitability | Noise Tolerance | Memory Depth |
|:--------:|:-----------:|:-----------:|:--------------:|:--------------:|:---------------:|:------------:|
| 1.0      | 1.0         | 0.0         | 1.0            | 0.0            | 0.0             | ∞ (flag)     |

---

#### 2.2.4 Graaskamp — Jim Graaskamp

| Property | Value |
|----------|-------|
| **Behavioral idea** | Adaptive forgiveness based on recent opponent behavior. Cooperates unless the opponent's *recent* defection frequency exceeds a threshold. Tracks a sliding window. |
| **First move** | Cooperate |
| **After opponent cooperates** | Cooperate |
| **After opponent defects** | Depends on recent frequency. If defection rate in the last N moves > threshold (≈50%), defect. Otherwise, continue cooperating. |
| **History needed** | Opponent's last N moves (sliding window) |
| **Deterministic?** | Yes (with defined window/threshold) |
| **Internal state** | Circular buffer / dequeue of recent opponent moves (e.g., last 10–20 moves) |
| **Strengths** | Forgiving of isolated defections. Tolerant of noise. Punishes sustained defection. More robust than TFT in noisy environments. |
| **Weaknesses** | Can be exploited by a strategy that defects rarely or cleverly (just below threshold). More complex to analyze. |
| **Performs well against** | Noisy opponents, strategies with occasional defections |
| **Performs poorly against** | Clever exploiters that stay just under the threshold, pure cooperators (no advantage gained though) |

**Character parameters:**

| Niceness | Retaliation | Forgiveness | Predictability | Exploitability | Noise Tolerance | Memory Depth |
|:--------:|:-----------:|:-----------:|:--------------:|:--------------:|:---------------:|:------------:|
| 1.0      | 0.6–1.0     | 0.8         | 1.0            | 0.3            | 0.8             | 10–20        |

**Note:** Retaliation depends on threshold. At low threshold (e.g., 30%), it's more retaliatory than TFT. At high threshold (e.g., 70%), it's more forgiving. Values are for a ~50% threshold with a 10-move window.

---

#### 2.2.5 Tester — David Gladstein

| Property | Value |
|----------|-------|
| **Behavioral idea** | Probe the opponent's willingness to retaliate. Defect on move 1. If opponent retaliates, become contrite and play TFT. If opponent does not retaliate (cooperates after the probe), exploit them with alternating D, C. |
| **First move** | Defect (the "test") |
| **After opponent cooperates** (post-probe) | Interpret as weakness → switch to exploitation: defect, cooperate, defect, cooperate... |
| **After opponent defects** (post-probe) | Interpret as strength → become contrite, cooperate, then play TFT |
| **History needed** | Opponent's response to the first move; then TFT (last move); or alternating pattern state |
| **Deterministic?** | Yes |
| **Internal state** | `mode: "testing" | "contrite" | "exploiting"`; plus TFT or pattern state |
| **Strengths** | Can extract high scores from unconditional cooperators or overly forgiving strategies. Adaptive. |
| **Weaknesses** | Against retaliatory strategies (TFT), the initial defection starts a mini-feud. Alternating D,C pattern can be exploited by strategies that recognize it. |
| **Performs well against** | Always Cooperate (AllC), very forgiving strategies |
| **Performs poorly against** | TFT, Grim Trigger (Friedman — permanent defection from move 1), strategies that recognize patterns |

**Character parameters:**

| Niceness | Retaliation | Forgiveness | Predictability | Exploitability | Noise Tolerance | Memory Depth |
|:--------:|:-----------:|:-----------:|:--------------:|:--------------:|:---------------:|:------------:|
| 0.0      | 1.0         | 1.0         | 0.7            | 0.7            | 0.3             | 2+ (mode + last move) |

**Note:** Niceness = 0 because it defects first. But forgiveness = 1.0 because if opponent retaliates, it immediately "apologizes" and shifts to TFT. Predictability is lower because the response depends on a hidden state.

---

#### 2.2.6 Random

| Property | Value |
|----------|-------|
| **Behavioral idea** | Choose C or D with equal probability (50/50) each round, independent of history. |
| **First move** | Random (50% C, 50% D) |
| **After opponent cooperates** | Random |
| **After opponent defects** | Random |
| **History needed** | None |
| **Deterministic?** | No |
| **Internal state** | Random number generator |
| **Strengths** | Unpredictable. Cannot be exploited by pattern-based strategies. |
| **Weaknesses** | Cannot establish or maintain cooperation. Performs at the bottom of virtually every tournament. Fails to get the benefits of mutual cooperation. |
| **Performs well against** | Strategies that rely on pattern recognition or prediction (marginally) |
| **Performs poorly against** | Everyone. Expected score per round is (3 + 5 + 0 + 1) / 4 = 2.25, below the mutual cooperation (3, 3). |

**Character parameters:**

| Niceness | Retaliation | Forgiveness | Predictability | Exploitability | Noise Tolerance | Memory Depth |
|:--------:|:-----------:|:-----------:|:--------------:|:--------------:|:---------------:|:------------:|
| 0.5      | 0.0         | 0.5         | 0.0            | 0.0 (cannot be exploited) | 1.0 (immune — already random) | 0 |

**Note:** Random is trivially noise-tolerant — since its decisions are already stochastic, additional noise doesn't affect its behavior. It cannot be exploited because there is nothing to exploit; it offers no consistent response surface.

---

### 2.3 Strategy Interface (Conceptual)

Every strategy shall implement this contract (described as an interface, not code):

```
Strategy:
  - name(): string
  - firstMove(): Move (C or D)
  - nextMove(opponentHistory: Move[], myHistory: Move[], roundNumber: int): Move
  - reset(): void  (reset internal state for a new match)
```

- The strategy receives the *full history* of both sides. It chooses what to ignore.
- Strategies like TFT ignore everything except the last element of `opponentHistory`.
- Strategies like Graaskamp maintain their own sliding window from the histories.
- `reset()` clears per-match internal state (the `everDefected` flag for Friedman, the mode for Tester, etc.).
- Strategies are *stateless across matches* — they must be reset between matches in a tournament.

---

## 3. Environment Dynamics

### 3.1 Noise

**Definition:**  
Noise is an error or perturbation that distorts the intended action, the perceived action, or the recorded action.

**Types of noise in the Prisoner's Dilemma:**

| Noise Type | What Happens | Example |
|------------|-------------|---------|
| **Action noise** | The move that was *executed* differs from what the strategy intended | Strategy says Cooperate, but the engine plays Defect with error probability `p` |
| **Perception noise** | The opponent's move is *observed* incorrectly | Opponent played Cooperate, but my strategy records it as Defect |
| **Implementation noise** | The move is correctly executed and perceived, but recorded in history with errors | Less common; usually subsumed by perception noise |

**Why noise destabilizes cooperation:**  
In a noiseless world, TFT detects defection only when the opponent intentionally defects. With 1% action noise, TFT occasionally sees a defection that was an error → retaliates → opponent (if also TFT) sees the retaliation as a defection → retaliates back → a feud spiral begins that may never end.

**Simple retaliation becomes dangerous in noisy environments:**
- TFT in 1% noise: cooperation collapses into mutual defection and never recovers.
- Strategies need forgiveness mechanisms (e.g., "forgive one defection in a window") to survive noise.
- Friedman/Grim Trigger is catastrophic in noise — one error → permanent defection.
- Graaskamp's sliding-window approach is specifically designed to survive noise.

**Engine parameters to anticipate:**

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `noiseEnabled` | boolean | false | — | Master switch for noise |
| `actionErrorRate` | float | 0.01 | 0.0–1.0 | Probability that an executed move is flipped |
| `perceptionErrorRate` | float | 0.01 | 0.0–1.0 | Probability that an observed move is flipped |
| `noiseSeed` | int | — | — | Seed for reproducible noise |

### 3.2 Ecological / Evolutionary Simulation

Axelrod ran an "ecological" tournament where strategies reproduced based on their cumulative scores.

**How it works:**
1. An initial population is defined as a distribution of strategies (e.g., equal shares).
2. Each generation: strategies play matches against each other, with match frequency proportional to population share.
3. After all matches: total scores determine the next generation's population share.
4. Higher-scoring strategies increase their share; lower-scoring strategies shrink or disappear.
5. This repeats for many generations.

**Key insight:**
Even a strategy that loses in direct head-to-head can thrive in an ecology if it scores well against the most common strategies. The ecology favors strategies that perform well *in the environment they actually encounter*, not in a theoretical average.

**Engine parameters to anticipate:**

| Parameter | Type | Default | Range | Description |
|-----------|------|---------|-------|-------------|
| `populationSize` | int | 100 | 10–N | Number of agents per generation |
| `roundsPerMatch` | int | 200 | 1–N | Rounds per pairwise match |
| `mutationRate` | float | 0.0 | 0.0–1.0 | Probability that a new generation includes a mutant strategy |
| `mutationPool` | string[] | — | — | List of strategies that mutants can become |
| `selectionPressure` | float | 1.0 | 0.0–∞ | How strongly score differences affect reproduction (higher = more winner-take-all) |
| `generationCount` | int | 50 | 1–N | Number of generations to simulate |

### 3.3 Islands of Cooperation

**The problem:**
In a population of mostly selfish (AllD) strategies, cooperators get a low score because they are exploited. Cooperation seems impossible to start.

**The resolution (from Axelrod's analysis):**
- If cooperators form *clusters* or interact preferentially with each other, they achieve high mutual-cooperation scores among themselves.
- A small cluster of TFT players, if they interact frequently enough among themselves, can achieve a higher average score than the surrounding AllD population.
- Over generations, the TFT cluster grows, and cooperation expands through the population.

**How to model this:**
- **Spatial model:** Agents are placed on a grid; interactions are limited to neighbors. Cooperators on adjacent cells benefit from mutual cooperation; AllD agents on adjacent cells harm each other.
- **Island model:** The population is divided into sub-populations ("islands"). Migration between islands is limited. Cooperation can evolve on one island and then seed others.
- **Preferential matching:** Instead of random pairing, probability of match is proportional to similarity or distance in strategy space.

**Engine parameters to anticipate:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `populationStructure` | enum | `"random"` | `"random"` | `"grid"` | `"islands"` |
| `gridWidth` | int | 20 | Grid width for spatial simulation |
| `gridHeight` | int | 20 | Grid height for spatial simulation |
| `islandCount` | int | 5 | Number of islands |
| `migrationRate` | float | 0.01 | Per-generation migration between islands |
| `neighborhoodRadius` | int | 1 | How far interaction reaches on a grid |

---

## 4. Axelrod's Analytical Conclusions

### 4.1 The Four Principles of a Successful Strategy

| # | Principle | Meaning | Simulation Consequence |
|---|-----------|---------|----------------------|
| 1 | **Do not be envious** | Do not try to outscore your opponent. Aim for mutual cooperation. An envied strategy (trying to "win" every interaction) defects to get 5 instead of 3, but triggers retaliation. | Strategies should not minimize opponent's score but maximize their own over the long run. The engine should not reward "beating" the opponent — only cumulative points. |
| 2 | **Do not be the first to defect** | Being "nice" (never initiating defection) is the strongest predictor of tournament success. 8 of the top 15 strategies in the first tournament were nice. | First-move behavior is critical. Strategies that defect first (Tester, AllD) must be evaluated in context. |
| 3 | **Reciprocate both cooperation and defection** | Be responsive: reward cooperation with cooperation, punish defection with defection. Unconditional cooperators get wiped out. Unconditional defectors never establish cooperation. | The strategy must map opponent actions to responses. Reciprocity gives the opponent incentive to cooperate. |
| 4 | **Do not be too clever / Be understandable** | Complex strategies (pattern recognition, statistical analysis, Bayesian inference) were outperformed by simple TFT. Cleverness makes behavior unpredictable, which prevents the opponent from establishing stable cooperation. | Simplicity is a design virtue. The strategy's behavior should be obvious to the opponent after a few rounds. Complex strategies that are not "understandable" score poorly on average. |

### 4.2 Non-Zero-Sum Nature

**Crucial domain concept:**  
The Prisoner's Dilemma is a **non-zero-sum game**. Unlike chess or poker where one player's gain is another's loss (zero-sum), in the Prisoner's Dilemma:

- Both can gain (CC: 3+3 = 6 total points)
- Both can lose (DD: 1+1 = 2 total points)
- One can exploit the other (CD: 0+5 = 5 total points; DC: 5+0 = 5 total points)

**Why this matters for simulation:**
- The total points are not fixed. Mutual cooperation creates *more value* than mutual defection.
- A strategy's score is not directly subtracted from the opponent's.
- The "Banker of the World" (the scoring mechanism) is an external source that dispenses points based on outcomes. This models a positive-sum interaction where cooperation literally creates value.

**Implementation consequence:**  
The payoff matrix defines total points produced per outcome. The `ScoreCalculator` adds points to both players from an external pool — not from each other. This is a fundamental distinction from competitive games.

---

## 5. Domain Model for Future Implementation

### 5.1 Conceptual Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                   Simulation Orchestration               │
│  (Tournament, EvolutionEngine, SpatialSimulation)        │
├─────────────────────────────────────────────────────────┤
│                    Match Layer                           │
│  (GameEngine — runs N rounds between two strategies)     │
├─────────────────────────────────────────────────────────┤
│                   Payoff Layer                           │
│  (PayoffMatrix, ScoreCalculator — deterministic)        │
├─────────────────────────────────────────────────────────┤
│                   Strategy Layer                         │
│  (Individual strategy implementations)                   │
├─────────────────────────────────────────────────────────┤
│                   Cross-Cutting Concerns                 │
│  (NoiseModel, RandomProvider, HistoryLogger)             │
└─────────────────────────────────────────────────────────┘
```

### 5.2 Domain Entities

| # | Concept | Responsibility | Owns | Not Responsible For | Collaborates With |
|---|---------|---------------|------|--------------------|-------------------|
| 1 | **Move** | Represents a single action choice | Value (C or D), Player identity, Round number | Scoring, strategy logic | Round, GameEngine |
| 2 | **Strategy** | Makes a decision given game history | Name, decision logic, internal state | Scoring, noise, history keeping | GameEngine (receives histories), History |
| 3 | **Round** | Holds two moves (one per player) | Player A's move, Player B's move | Scoring, timing | Match |
| 4 | **Match** | Runs a sequence of rounds between two strategies | Strategy A, Strategy B, Round list, Cumulative scores | Tournament registration, population logic | GameEngine, ScoreCalculator, NoiseModel |
| 5 | **PayoffMatrix** | Defines points for each outcome combination | Values for CC, CD, DC, DD | Strategy logic, tournament rules | ScoreCalculator |
| 6 | **ScoreCalculator** | Computes points for a round using PayoffMatrix | Reference to PayoffMatrix | Storing scores, strategy logic | PayoffMatrix, Round |
| 7 | **GameEngine** | Orchestrates a single match: request moves, apply noise, score, log | References to everything needed for a match | Tournament-level results, visualization | Strategy (x2), NoiseModel, ScoreCalculator, HistoryLogger |
| 8 | **NoiseModel** | Applies action/perception errors probabilistically | Error rates, random source, type of noise | Strategy decisions, scoring | GameEngine, RandomProvider |
| 9 | **Tournament** | Runs all pairwise matches between a set of strategies | Strategy list, match results table, total scores | Per-round details, population dynamics | GameEngine, Match |
| 10 | **Population** | Represents a distribution of strategies with abundance scores | Strategy → count/shares mapping, parameters | Running matches, generation transitions | EvolutionEngine, Tournament |
| 11 | **Generation** | One iteration of evolutionary simulation | Population snapshot, match results | Reproduction logic | EvolutionEngine |
| 12 | **EvolutionEngine** | Manages multi-generation runs: evaluate, select, reproduce | Population, parameters, generation history | One-off matches, tournament results | Tournament, Population, SelectionStrategy |
| 13 | **SimulationResult** | Stores all output data from a simulation run | Scores per strategy, rounds, population history, metadata | Running simulations, visualization | GameEngine, Tournament, EvolutionEngine |
| 14 | **StatisticsCollector** | Aggregates raw results into computed metrics | Mean scores, win rates, cooperation rates, standard deviations | Running simulations, storage | SimulationResult |

### 5.3 SOLID Design Principles Applied

**S — Single Responsibility:**
- A Strategy makes decisions. It does not compute scores.
- A ScoreCalculator computes scores. It does not store them.
- A NoiseModel applies noise. It does not decide strategy moves.
- A Match runs rounds. It does not manage tournaments.

**O — Open/Closed:**
- New strategies implement the `Strategy` interface without modifying the engine.
- New payoff matrices (e.g., different scales, alternative dilemmas) can be injected without changing game logic.
- EvolutionEngine can accept different `SelectionStrategy` implementations (proportional, tournament, rank-based).

**L — Liskov Substitution:**
- Any strategy implementation can replace another in any simulation mode. The game engine must work identically regardless of which strategy is plugged in.
- A `NaiveStrategy` (e.g., Random) and a `ComplexStrategy` (e.g., Graaskamp) are both `Strategy` — the engine treats them identically through the interface.

**I — Interface Segregation:**
- Separating `Strategy` (decision making) from `Scorable` (score tracking) from `Resettable` (per-match state reset).
- Tournaments need `Named` and `Scorable` but not `NoiseModel`.

**D — Dependency Inversion:**
- `GameEngine` depends on the `Strategy` abstraction, not concrete strategy classes.
- `Tournament` depends on `GameEngine` (abstraction for a match), not on round-level details.
- `ScoreCalculator` depends on `PayoffMatrix` (injectable), not on hardcoded values.

### 5.4 Possible Interface Contracts (Conceptual)

```
Strategy:
  - firstMove(): Move
  - nextMove(history: MatchHistory): Move
  - reset(): void
  - name(): String
  - parameters(): StrategyParams  // the character parameters for analysis

PayoffMatrix:
  - reward(): int       // R — both cooperate
  - temptation(): int   // T — defect vs cooperate
  - sucker(): int       // S — cooperate vs defect
  - punishment(): int   // P — both defect
  - lookup(myMove: Move, opponentMove: Move): int

NoiseModel:
  - applyActionNoise(intendedMove: Move): Move
  - applyPerceptionNoise(actualMove: Move, observer: Strategy): Move
  - reset(): void

GameEngine:
  - playMatch(strategyA: Strategy, strategyB: Strategy, rounds: int): MatchResult

Tournament:
  - run(strategies: Strategy[], roundsPerMatch: int): TournamentResult

EvolutionEngine:
  - run(initialPopulation: Population, generations: int): EvolutionResult
```

---

## 6. Simulation Modes

### 6.1 Single Match

**Purpose:** Observe the dynamics of two specific strategies interacting.

| Aspect | Detail |
|--------|--------|
| **Inputs** | Strategy A, Strategy B, Number of rounds, Payoff matrix, Noise parameters (optional) |
| **Process** | Run N rounds. Collect each round's moves and scores. |
| **Outputs** | Per-round move sequence (C/D for each player), cumulative scores after each round, total score |
| **Statistics** | Cooperation rate per player, total points, average points per round, whether mutual cooperation was achieved |
| **Modules involved** | Strategy, GameEngine, ScoreCalculator, PayoffMatrix, NoiseModel (optional) |

### 6.2 Tournament

**Purpose:** Rank a set of strategies by total performance against each other.

| Aspect | Detail |
|--------|--------|
| **Inputs** | Strategy list, rounds per match, payoff matrix |
| **Process** | Every strategy plays every other strategy (including itself). Score is summed across all matches. |
| **Outputs** | Ranked list of strategies by total score, pairwise score matrix |
| **Statistics** | Mean score, max/min/median, standard deviation, win rate (highest score in a match), cooperation rate per strategy across all matches |
| **Modules involved** | Strategy, GameEngine, Tournament, StatisticsCollector |

### 6.3 Noisy Tournament

**Purpose:** Evaluate strategy robustness under imperfect conditions.

| Aspect | Detail |
|--------|--------|
| **Inputs** | Same as Tournament + actionErrorRate, perceptionErrorRate, noiseSeed |
| **Process** | Same as Tournament, but NoiseModel is enabled during match play. Strategies are NOT notified about noise (unless perception noise is designed differently). |
| **Outputs** | Same as Tournament, plus noise statistics (how many errors occurred, how many feuds were triggered) |
| **Statistics** | Same as Tournament + noise-related metrics: score drop per strategy vs clean tournament, recovery rate after defection |
| **Modules involved** | Strategy, GameEngine, NoiseModel, Tournament, StatisticsCollector |

**Critical design note:**  
In the first Axelrod tournament, strategies were submitted as Fortran subroutines and the history passed to them was the *actual* history (no noise). If we add noise, we must decide whether the strategy sees the *intended* moves or the *executed* moves of its opponent. The Veritasium transcript and most literature assume perception noise (the strategy sees what it saw, not what actually happened). The engine should support both models.

### 6.4 Evolutionary Run

**Purpose:** Study how strategy distributions evolve over generations.

| Aspect | Detail |
|--------|--------|
| **Inputs** | Initial population distribution (strategy → count), rounds per match, generations count, selectionPressure, mutationRate, mutationPool (optional) |
| **Process** | For each generation: run matches proportional to population shares → score → compute next-generation shares based on scores → (optional) apply mutation → repeat |
| **Outputs** | Per-generation population distribution, trajectory of each strategy's share over time |
| **Statistics** | Which strategies survive/go extinct, time to extinction, final distribution, Gini coefficient of score inequality per generation, diversity index (Shannon) |
| **Modules involved** | Strategy, GameEngine, Population, EvolutionEngine, StatisticsCollector |

### 6.5 Cooperation Island Simulation

**Purpose:** Demonstrate that cooperation can emerge from a small cluster within a hostile population.

| Aspect | Detail |
|--------|--------|
| **Inputs** | Population size, percentage of cooperators (TFT), percentage of defectors (AllD), grid dimensions (if spatial), rounds per match, generations count |
| **Process** | Place strategies on a grid or into sub-populations. Cooperators in a cluster interact preferentially with each other (mutual cooperation bonus). AllD agents harm each other (mutual defection). Over generations, cooperative cluster's score advantage causes it to grow. |
| **Outputs** | Generational snapshots of the spatial/spread distribution, score trajectory for each cluster |
| **Statistics** | Cluster growth rate, critical cluster size needed for survival, speed of cooperation spread |
| **Modules involved** | Strategy, GameEngine, Population (spatial), EvolutionEngine, StatisticsCollector |

---

## 7. Implementation-Relevant Notes

### 7.1 Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **Payoff matrix is a first-class object** | It's the mathematical foundation of the entire simulation. Making it injectable allows exploring different parameterizations of the dilemma (different T/R/P/S values). It must be separated from strategy logic to keep strategies pure decision-makers. |
| **`(3, 3) > (1, 1)` is encoded in the payoff matrix, not in strategy code** | Strategies don't know the payoff values — they only see history. The payoff matrix is for the engine. This is critical for the strategy interface to be clean. |
| **`(5, 0)` temptation is stored as `temptation = 5, sucker = 0` in PayoffMatrix** | The numeric values 5 and 0 encode the greedy incentive. The controller/matcher can use these values, but strategies never see them. |
| **Per-match state reset** | Every strategy must have a `reset()` method. Strategies carry state across rounds within a match (Friedman's `everDefected` flag, Tester's `mode`, Graaskamp's sliding window). This state must be cleared between matches in a tournament. |
| **History ownership** | The `Match` (or `GameEngine`) owns the canonical history. Strategies may maintain their own copy or window. The engine passes history to the strategy each round; the strategy is not trusted to modify the engine's history. |
| **Noise as a layer** | Noise should be an engine-level concern, not a strategy concern. The NoiseModel sits between the strategy's decision and the recorded outcome. Strategies play "normally" — noise is applied by the environment. This models the real situation where a player intends one thing but the world introduces error. |
| **Evolution as an extension** | Evolution builds on top of tournament/matches. It does not modify the game engine. Tournament results are fed into the population model, which computes next-generation shares. This keeps the core engine simple and the evolution layer separable. |
| **Statistics as observers** | Statistics collection should be an observer/listener pattern. Core modules emit events (`RoundComplete`, `MatchComplete`, `TournamentComplete`, `GenerationComplete`). Collectors listen and aggregate. This decouples analysis from simulation. |

### 7.2 State Requirements by Strategy

| Strategy | Internal State | Resets Between Matches? | Notes |
|----------|---------------|------------------------|-------|
| Tit for Tat | Last opponent move (or nothing — can derive from history index) | No explicit state needed | Effectively stateless; decision depends on `history[-1]` |
| Joss | Last opponent move + RNG state | RNG state should be reseeded or continued | Random component needs deterministic seed option |
| Friedman | `everDefected: boolean` | Yes, must reset to `false` | Simple flag, but catastrophic if not reset |
| Graaskamp | Circular buffer of last N opponent moves | Yes, clear buffer | Window size is a parameter (configurable) |
| Tester | `mode: "testing" | "contrite" | "exploiting"`, plus sub-state | Yes, reset to `"testing"` | Multi-mode state machine |
| Random | RNG state | Reseed or continue | If seeded, should get a fresh seed per match |
| Always Cooperate | None | No | Trivial |
| Always Defect | None | No | Trivial |

### 7.3 Anticipated Engine Parameters (Master List)

| Parameter | Type | Where Used |
|-----------|------|------------|
| `roundsPerMatch` | int | GameEngine, Tournament, EvolutionEngine |
| `continuationProbability` | float | GameEngine (uncertain-length matches) |
| `actionErrorRate` | float | NoiseModel |
| `perceptionErrorRate` | float | NoiseModel |
| `noiseType` | enum: "action" | "perception" | "both" | NoiseModel |
| `populationSize` | int | Population, EvolutionEngine |
| `generationCount` | int | EvolutionEngine |
| `mutationRate` | float | EvolutionEngine |
| `selectionPressure` | float | EvolutionEngine |
| `populationStructure` | enum | SpatialSimulation |
| `gridWidth` | int | SpatialSimulation |
| `gridHeight` | int | SpatialSimulation |
| `migrationRate` | float | IslandModel |
| `seed` | int | RandomProvider (reproducibility) |

### 7.4 Assumptions and Open Questions

1. **Assumption:** The canonical payoff matrix (5, 3, 1, 0) is the default. The engine should support any matrix satisfying `T > R > P > S` and `2R > T + S`.

2. **Assumption:** Strategies receive raw history (moves as played/perceived, not scores). They do not see the payoff matrix.

3. **Open:** Should strategies receive the opponent's *intended* move or the *executed* (noise-affected) move? The literature is ambiguous. Two implementation options:
   - `playMatch(noiseModel: NOISE_ACTION)` — strategy decides, action noise flips the executed move, opponent sees the flipped move in their history.
   - `playMatch(noiseModel: NOISE_PERCEPTION)` — strategy decides, move is executed cleanly, but the opponent's history records a flipped version.
   - Best approach: make the noise type configurable and document clearly what the strategy receives.

4. **Open:** What happens in a tournament when two strategies with different noise tolerances clash? The noise affects the *execution/perception*, the strategies just respond to what they see. This should be emergent, not precomputed.

5. **Assumption:** All strategies in a match play the same number of rounds and under the same noise conditions.

6. **Open:** Should mutation in evolutionary runs produce entirely new strategies, or slightly modified versions of existing ones? Axelrod's work used a pool of known strategies. Later work (e.g., genetic algorithms by John Miller) mutated strategy parameters. The engine should support both approaches: `mutationPool` for new strategies and `parameterMutationRate` for mutating existing ones.

7. **Assumption:** The engine runs synchronously and deterministically (for a given seed). Asynchronous or distributed simulation is not required.

---

## 8. Output Format Compliance Note

This document is structured technical documentation for designing classes, interfaces, modules, and simulation flows.

**Sections that directly enable implementation:**
- §1 → PayoffMatrix, Round, GameEngine, condition checking
- §2 → Strategy interface, concrete strategy classes
- §3 → NoiseModel, Population, EvolutionEngine, spatial model
- §4 → Design heuristics, evaluation criteria for strategy success
- §5 → Full domain model with responsibility mapping
- §6 → Simulation mode specifications (test cases for integration)
- §7 → Implementation notes, state requirements, parameter catalog

No implementation code has been written. This document is the specification from which code will be derived.
