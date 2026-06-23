# TASK_SPEC — Prisoner's Dilemma Simulator

> **Проєкт:** Односторінковий браузерний симулятор Iterated Prisoner's Dilemma.
> **Domain spec:** [`docs/superpowers/prisoners-dilemma-domain-spec.md`](../docs/superpowers/prisoners-dilemma-domain-spec.md)
> **Правило роботи:** Всі зміни, кроки, рішення — тільки через цей файл. Жодних дій без посилання на TASK_SPEC.
> **Стек:** Чистий HTML + CSS + JS, один файл. Жодних білд-кроків, фреймворків, залежностей.
> **Тема:** GULAG (радянський табір) — замість Lovecraftian. Наколки, іржа, бруд, холодний метал, сірий бетон, червона зірка, гумові кийки.

---

## 1. Архітектура проєкту

### Структура файлів

```
prisoners-dilemma/
├── TASK_SPEC.md             ← єдиний робочий документ (цей файл)
├── index.html               ← вся аплікуха в одному файлі
└── docs/
    ├── prisoners-dilemma-domain-spec.md   ← domain knowledge base
    └── strategy-notes.md                  ← нотатки про стратегії (опціонально)
```

### Як влаштований index.html

Один HTML-файл з чотирма JS-секціями (аналогічно lesson2_1):

```
index.html
├── <head> — Google Fonts (UnifrakturCook + VT323), CSS стилі
├── <body>
│   ├── #app — кореневий контейнер
│   │   ├── .header — заголовок + кнопки керування
│   │   ├── .main-area — основна робоча зона
│   │   │   ├── .panels — панелі налаштувань (сайдбар)
│   │   │   └── .simulation-area — візуалізація матчів
│   │   └── .stats-bar — нижня панель статистики
│   └── <script>
│       ├── // SECTION 1: CORE — константи, PayoffMatrix, Move
│       ├── // SECTION 2: STRATEGIES — всі стратегії
│       ├── // SECTION 3: ENGINE — GameEngine, Tournament, Evolution
│       ├── // SECTION 4: UI — рендер, контролери, візуалізація
│       └── // SECTION 5: INIT — bootstrap, event listeners
└── (немає)
```

### Принципи

- **SOLID** — кожен модуль має одну відповідальність
- **Немає зовнішніх залежностей** — чистий Vanilla JS
- **Всі стратегії — чисті функції рішень** — отримують історію, повертають Move
- **Статистика відв'язана від ядра** — через callback/listener події
- **Налаштування через параметри** — жодних хардкоджених значень у функціях

---

## 2. Поточний статус

| Фаза | Статус |
|------|--------|
| **P1: Core Engine** (Move, PayoffMatrix, ScoreCalculator, GameEngine) | 🔲 Pending |
| **P2: Strategies** (TFT, Joss, Friedman, Graaskamp, Tester, Random + AllC, AllD) | 🔲 Pending |
| **P3: Tournament** (pairwise, ranking, statistics) | 🔲 Pending |
| **P3b: Strategy Comparison** (radar, what-if, pairwise matrix, edge analysis, cumulative chart) | 🔲 Pending |
| **P4: Environment** (noise, match config) | 🔲 Pending |
| **P5: Evolution** (population, generations, ecology) | 🔲 Pending |
| **P6: UI** (layout, controls, all visualizations + comparison components, Gulag theme) | 🔲 Pending |
| **P7: Analysis & Polish** (edge cases, perf, verify Axelrod results) | 🔲 Pending |

---

## 3. Дорожня карта (фази)

### P1: Core Engine

**Ціль:** Створити ядро симуляції — Move, PayoffMatrix, ScoreCalculator, GameEngine.

**Див.:** Domain spec §1, §5.2 (entities 1, 5, 6, 7)

**Критерії приймання:**
1. Move — просте значення (`'C' | 'D'`), функція `opposite(move)`
2. PayoffMatrix — об'єкт з `lookup(my, opp)`, налаштовується через T/R/P/S
3. ScoreCalculator — отримує PayoffMatrix, два Move, повертає `{ a: int, b: int }`
4. GameEngine — приймає StrategyA, StrategyB, config, повертає MatchResult
5. MatchResult містить: `rounds[]` (кожен раунд: moveA, moveB, scoreA, scoreB), total scores, metadata
6. GameEngine підтримує: фіксовану кількість раундів, probabilistic continuation
7. GameEngine викликає `strategy.reset()` на початку матчу
8. GameEngine пробрасує strategy тільки Move'и — стратегія не бачить PayoffMatrix
9. Всі функції чисті (детерміновані для given seed)

**Файли:** `index.html` — SECTION 1, SECTION 3 (частково)

---

### P2: Strategies

**Ціль:** Реалізувати всі 6 стратегій + 2 базові (AllC, AllD) через єдиний контракт.

**Див.:** Domain spec §2, §7.2 (state requirements)

**Критерії приймання:**
1. Стратегія — об'єкт/клас з методами: `name()`, `firstMove()`, `nextMove(history)`, `reset()`
2. `history` — це `{ myMoves: Move[], oppMoves: Move[] }` або `{ rounds: { mine: Move, theirs: Move }[] }`
3. AllC — завжди C
4. AllD — завжди D
5. TFT — C на першому ходу, далі копіює останній хід опонента
6. Joss — як TFT, але після C опонента з ймовірністю 0.1 грає D
7. Friedman — C, поки опонент не зіграє D хоча б раз, після цього завжди D
8. Graaskamp — C на першому ходу, далі D якщо частота D опонента за останні N ходів > threshold (N=10, threshold=0.5 як дефолт)
9. Tester — D на першому ходу, далі: якщо опонент відповів D → режим contrite (C + TFT); якщо C → режим exploitation (D,C,D,C...)
10. Random — C або D з 50/50
11. RNG для Random та Joss — seeded (приймає seed) або Math.random()
12. `reset()` очищає внутрішній стан: Friedman-flag, Tester-mode, Graaskamp-buffer
13. Стратегія **не знає** про PayoffMatrix, не рахує очки

**Файли:** `index.html` — SECTION 2

---

### P3: Tournament

**Ціль:** Запускати всі стратегії одна проти одної, збирати результати, ранжувати.

**Див.:** Domain spec §5.2 (entity 9), §6.2

**Критерії приймання:**
1. Tournament отримує список стратегій, roundsPerMatch, (опціонально) noise config
2. Кожна стратегія грає з кожною (включаючи себе) — round-robin
3. Матч A→B і B→A — це окремі матчі (обидві комбінації)
4. TournamentResult містить: `pairwiseScores[][]`, `totalScores[]`, ranking
5. Статистика: mean score, win rate, cooperation rate per strategy
6. Tournament використовує GameEngine (не дублює логіку)
7. Tournament не знає про UI — повертає дані, не рендерить

**Файли:** `index.html` — SECTION 3

---

### P4: Environment (Noise)

**Ціль:** Додати шум як конфігурований шар навколо GameEngine.

**Див.:** Domain spec §3.1, §5.2 (entities 8)

**Критерії приймання:**
1. NoiseModel — параметри: actionErrorRate, perceptionErrorRate, seed
2. `applyActionNoise(intended)`: з ймовірністю p фліпає C↔D
3. `applyPerceptionNoise(actualMove, observerSeed)`: з ймовірністю p фліпає C↔D в історії, яку бачить стратегія
4. GameEngine приймає опціональний NoiseModel
5. При NoiseModel — стратегія отримує спотворену історію, але очки рахуються за реальні ходи
6. Шум не ламає seeded reproducibility

**Файли:** `index.html` — SECTION 3 (розширення)

---

### P5: Evolution

**Ціль:** Симуляція еволюції популяції стратегій через покоління.

**Див.:** Domain spec §3.2, §5.2 (entities 10, 11, 12), §6.4

**Критерії приймання:**
1. Population — розподіл стратегій: `{ strategy: count }`
2. EvolutionEngine отримує initialPopulation, generationCount, roundsPerMatch
3. Кожне покоління: всі матчі → сумарні очки → новий розподіл (score → population share)
4. Опціонально: mutationRate, mutationPool, selectionPressure
5. EvolutionResult — per-generation population distribution, extinction events
6. EvolutionEngine використовує Tournament + GameEngine (не дублює)

**Файли:** `index.html` — SECTION 3 (розширення)

---

### P3b: Strategy Comparison (наскрізна фіча)

**Ціль:** Кожен режим показує не просто "хто виграв", а *чому* і в чому різниця між стратегіями. Comparison — це не окремий режим, а шар поверх усіх режимів.

**Принцип:** Користувач має побачити відповіді на питання:
- "Чому TFT виграв у Joss, хоча вони майже однакові?"
- "Скільки очок TFT втратив через Joss-івські random defections?"
- "Якби я замінив Graaskamp на TFT — скільки б виграв?"

**Типи порівнянь:**

| Тип | Де з'являється | Що показує |
|-----|---------------|------------|
| **Head-to-head** | Match mode (обидва гравці поряд) | Дві колонки ходів, два рахунки, хто лідирує і чому |
| **Pairwise matrix** | Tournament mode | Таблиця A×B: кожна клітинка = рахунок A vs B. Кольором виділено хто виграв |
| **Radar chart** | Tournament results | 7 параметрів (niceness, retaliation, forgiveness, predictability, exploitability, noise tolerance, avg score) — накладання двох стратегій |
| **What-if slider** | Match mode | Слайдер "замінити A на X" — моментальний перерахунок гіпотетичного рахунку |
| **Edge analysis** | Tournament results | Для кожного матчу: скільки раундів mutual cooperation, mutual defection, exploitation; середній темп |
| **Еволюційна траєкторія** | Evolution mode | Накладання графіків виживання всіх стратегій — хто коли вимер, хто домінує |

**Компоненти UI для порівняння:**
1. **Dual scoreboard** — два гравці поряд, кольорові індикатори лідера
2. **Round-by-round timeline** — стрічка: кожен раунд як кольорова клітинка (C=теплий жовтий/зелений для cooperate, D=холодний сірий/червоний для defect). Обидва гравці на одній лінії.
3. **Cumulative score chart** — лінійний графік: X=раунд, Y=score. Дві лінії (A і B) + область лідерства.
4. **Cooperation rate bar** — % cooperation per player, stacked
5. **Sankey diagram** (опціонально) — потік C→C, C→D, D→C, D→D між двома гравцями
6. **Radar comparison** — 7 параметрів, дві стратегії на одному графіку
7. **What-if panel** — випадаючий список "Порівняти з..." + гіпотетичний рахунок

**Критерії приймання:**
1. Match mode: два гравці видно одночасно, ходи йдуть синхронно
2. Tournament: pairwise matrix клікабельна — клік на клітинку відкриває деталі матчу
3. Radar chart: 7 осей, дві стратегії, зрозумілі підписи
4. What-if: заміна стратегії перераховує гіпотетичний матч і показує різницю в score
5. Всі візуалізації в Gulag стилі

**Файли:** `index.html` — SECTION 4 (візуалізація порівняння)

---

### P6: UI

**Ціль:** Повноцінний веб-інтерфейс для всіх режимів симуляції.

**Див.:** Domain spec §6

**Критерії приймання:**

#### Layout (відсутній скрол)
```
#app (height: 100vh, overflow: hidden)
├── .header (52px)
│   ├── h1 — "PRISONER'S DILEMMA"
│   ├── .mode-tabs — [Match] [Tournament] [Noisy] [Evolution] [Islands]
│   └── .global-controls — [Run] [Pause] [Reset] Speed slider
├── .main-area (flex: 1, overflow: hidden)
│   ├── .panels (left, ~240px)
│   │   ├── .strategy-select — вибір стратегій (залежить від режиму)
│   │   │   ├── [Match]: два селекти (Player A, Player B)
│   │   │   ├── [Tournament/Noisy]: мультивибір або чекбокси
│   │   │   └── [Evolution]: initial population sliders
│   │   ├── .config-panel — параметри режиму (rounds, noise, mutation...)
│   │   └── .info-panel — поточний раунд, стан, seed
│   └── .simulation-area (flex: 1)
│       ├── [Match режим]:
│       │   ├── .match-visualization
│       │   │   ├── .player-a-panel (ім'я, стратегія, рахунок, cooperation rate)
│       │   │   ├── .round-history (сітка ходів, останні N, два рядки — A та B)
│       │   │   │   └── кожна клітинка: C=жовтий/теплий, D=сірий/холодний
│       │   │   └── .player-b-panel (ім'я, стратегія, рахунок, cooperation rate)
│       │   ├── .comparison-charts
│       │   │   ├── .cumulative-score-chart — дві лінії, область лідерства
│       │   │   ├── .cooperation-meter — stacked bar
│       │   │   └── .what-if-panel — "замінити A на..." + гіпотетичний рахунок
│       │   └── .status-line — поточний раунд / "MATCH COMPLETE"
│       ├── [Tournament/Noisy режим]:
│       │   ├── .pairwise-matrix — таблиця A×B, кольорові клітинки, клікабельні
│       │   ├── .ranking-list — відсортовані стратегії з барами
│       │   └── .comparison-charts
│       │       ├── .radar-chart — 7 параметрів, вибір двох стратегій
│       │       └── .edge-analysis — таблиця "хто з ким як грав"
│       └── [Evolution/Islands режим]:
│           ├── .population-chart — лінійний графік зміни популяції
│           ├── .extinction-timeline — коли вимерла кожна
│           └── .comparison-charts
│               ├── .trajectory-overlay — накладання траєкторій
│               └── .dominance-heatmap — хто домінував коли
└── .stats-bar (bottom, 40px) — flash-повідомлення, поточний статус
```

#### #### Gulag Theme (радянський табір)
- **Палітра:** бетон `#3a3a3a`, іржа `#8b3a2a`, бруд `#4a3a2a`, холодна сталь `#6a7a8a», кров `#7a1a1a`, дим `#1a1a1a`, світло ліхтаря `#d4a050`
- **Текстури:** грубий бетон, іржавий метал, дерев'яні нари, колючий дріт
- **Шрифти:** заголовки — грубий рублений (Impact / Oswald / Grafika), тіло — VT323 (друкована машинка)
- **Деталі:** червона зірка замість рун, нашви/наколки замість декоративних ліній, гумовий кийок замість меча, грати на фоні
- **Атмосфера:** холод, бруд, безнадія, але з іскрою людяності (cooperation = тепло)
- **Анімації:** стrob-ефект ліхтаря, дим/пил, клацання наручників при defection
- **Reduced motion:** `@media (prefers-reduced-motion: reduce)`

#### Компоненти UI
1. **Mode tabs** — перемикання між 5 режимами, кожен показує свої панелі
2. **Strategy select** — для Match: два dropdown; для Tournament: чекбокси
3. **Config panel** — поля залежать від режиму (див. domain spec §7.3)
4. **Round history** — сітка кольорових клітинок (C=зелений, D=червоний), останні ~50 раундів
5. **Score display** — великі цифри, зміна кольору при лідируванні
6. **Cooperation meter** — простий бар або sparkline
7. **Pairwise matrix** — таблиця score A×B для турніру
8. **Ranking** — відсортований список зі смужками прогресу
9. **Population chart** — лінійний графік або area chart в стилі теми
10. **Speed slider** — затримка між раундами (ms)
11. **Status ticker** — telegram-style повідомлення внизу

**Файли:** `index.html` — SECTION 1 (CSS), SECTION 4, SECTION 5

---

### P7: Analysis & Polish

**Ціль:** Переконатись що все працює, додати edge case handling, фінальний полірунок.

**Критерії приймання:**
1. AllD vs AllC — AllD виграє в one-shot, AllC отримує 0
2. TFT vs TFT — mutual cooperation весь матч (крім останнього раунду якщо known end)
3. Friedman vs Tester — Tester починає з D, Friedman переключається на D назовсім, mutual defection
4. Joss vs TFT — Joss випадково дефектить → TFT відповідає D → Joss відповідає D → можливий feud
5. Graaskamp vs Random — Graaskamp періодично карає Random за часті D
6. Random — очікуваний score ~2.25/раунд (перевірка на великій кількості раундів)
7. Еволюція: TFT домінує в довгій перспективі (відтворення результату Axelrod)
8. Шум: TFT страждає, Graaskamp виживає краще
9. Режими перемикаються без помилок
10. Анімації не ламаються при швидкому перемиканні
11. Responsive: 1024×768+ без скролу

---

## 4. Деталі імплементації

### 4.1 Псевдокод / Контракти

```js
// ===== SECTION 1: CORE =====

const Move = { C: 'C', D: 'D' };

function opposite(move) { return move === 'C' ? 'D' : 'C'; }

class PayoffMatrix {
  constructor(T, R, P, S) { /* validate T > R > P > S && 2R > T+S */ }
  lookup(myMove, oppMove) { /* return points for me */ }
}

class ScoreCalculator {
  constructor(matrix) { /* ... */ }
  scoreRound(moveA, moveB) { /* return { a: int, b: int } */ }
}

class GameEngine {
  playMatch(strategyA, strategyB, config) { /* return MatchResult */ }
}

// ===== SECTION 2: STRATEGIES =====

class BaseStrategy { /* name(), firstMove(), nextMove(history), reset() — contract */ }

class TFT extends BaseStrategy { /* ... */ }
class Joss extends BaseStrategy { /* ... constructor(prob = 0.1, rng) ... */ }
class Friedman extends BaseStrategy { /* ... everDefected flag ... */ }
class Graaskamp extends BaseStrategy { /* ... buffer, threshold, windowSize ... */ }
class Tester extends BaseStrategy { /* ... mode state machine ... */ }
class RandomStrategy extends BaseStrategy { /* ... rng ... */ }
class AllC extends BaseStrategy { /* trivially */ }
class AllD extends BaseStrategy { /* trivially */ }

// ===== SECTION 3: ENGINE =====

class Tournament { /* round-robin, ranking */ }
class NoiseModel { /* action/perception errors */ }
class Population { /* strategy distribution */ }
class EvolutionEngine { /* generations */ }

// ===== SECTION 4: UI =====

function renderMatchView() { /* ... */ }
function renderTournamentView() { /* ... */ }
function renderEvolutionView() { /* ... */ }
function renderStats() { /* ... */ }

// ===== SECTION 5: INIT =====

function init() { /* read mode, wire controls, bootstrap */ }
```

### 4.2 Як GameEngine працює (псевдокод)

```
playMatch(stratA, stratB, config):
  stratA.reset()
  stratB.reset()
  historyA = [], historyB = []   // реальна історія
  perceivedA = [], perceivedB = [] // історія, яку бачить стратегія (з шумом)
  scores = { a: 0, b: 0 }
  rounds = []

  for round = 1 to config.rounds:
    // або: якщо continuationProbability, вирішити чи продовжувати

    moveA = stratA.nextMove({ myMoves: historyA, oppMoves: perceivedA })
    moveB = stratB.nextMove({ myMoves: historyB, oppMoves: perceivedB })

    executedA = noise ? noiseModel.applyActionNoise(moveA) : moveA
    executedB = noise ? noiseModel.applyActionNoise(moveB) : moveB

    roundScore = scoreCalculator.scoreRound(executedA, executedB)
    scores.a += roundScore.a; scores.b += roundScore.b

    perceivedByA = noise ? noiseModel.applyPerceptionNoise(executedB) : executedB
    perceivedByB = noise ? noiseModel.applyPerceptionNoise(executedA) : executedA

    historyA.push(executedA); historyB.push(executedB)
    perceivedA.push(perceivedByA); perceivedB.push(perceivedByB)

    rounds.push({ round, moveA, moveB, executedA, executedB, perceivedByA, perceivedByB, scoreA, scoreB })
    emit(RoundComplete)

  return { rounds, totalScoreA, totalScoreB, winner }
```

### 4.3 Стан стратегій (що треба скидати)

| Strategy | Internal State | Reset |
|----------|---------------|-------|
| TFT | (none — uses last history entry) | — |
| Joss | RNG offset/seed | optional reseed |
| Friedman | `everDefected = false` | `= false` |
| Graaskamp | `buffer = []` | `= []` |
| Tester | `mode = 'testing'`, `substate` | `= 'testing'` |
| Random | RNG offset | optional reseed |

### 4.4 UI Event Flow

```
User clicks [Run]
  → controller.getConfig() (читає поточні налаштування з UI)
  → controller.run(mode, config)
    → engine = new GameEngine(config)
    → result = await engine.playMatch(stratA, stratB, config)
      → loop з requestAnimationFrame або setInterval (speed slider)
      → кожен раунд: controller.onRoundComplete(roundData)
        → ui.renderRound(roundData)
        → ui.updateScores(scores)
      → кінець: controller.onMatchComplete(result)
        → ui.renderResult(result)
        → ui.updateStats(stats)
```

---

## 5. Відкриті питання

1. Чи потрібна підтримка AllC та AllD як повноцінних стратегій в UI, чи вони тільки для тестування ядра?
2. Graaskamp window size та threshold — зробити налаштовуваними в UI чи захардкодити?
3. Evolution — чи потрібна spatial simulation (grid) в першій версії, чи тільки population-level?
4. Islands mode — окремий режим чи підрежим evolution?
5. Чи показувати покрокову анімацію для турніру (всі матчі одразу) чи тільки підсумкову таблицю?
6. Чи потрібна мобільна версія? (Зараз: 1024×768+)
7. Як обробляти дуже великі турніри (50+ стратегій) — чи потрібен async/поступовий рендер?

---

## 6. Історія змін

| Дата | Зміна |
|------|-------|
| 2026-06-23 | Створено TASK_SPEC для Prisoner's Dilemma Simulator |
