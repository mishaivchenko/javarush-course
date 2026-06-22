# TASK_SPEC: 003 — Central State Model

## Ціль
Реалізувати центральний об'єкт стану, який містить усі дані симуляції: скриньки, в'язнів, раунди, статистику, конфігурацію стратегії.

## Структура
```js
const state = {
  // Permutation
  boxes: new Array(100).fill(null),  // boxes[i] = number inside
  revealed: new Array(100).fill(false), // чи відкрита скринька

  // Round
  round: 0,
  currentPrisoner: 0,
  prisonerStep: 0,
  roundState: 'IDLE', // IDLE | RUNNING | WIN | LOSE
  prisonerPath: [],    // індекси відкритих скриньок в поточному проході

  // Strategy
  strategy: 'loop',
  config: { discipline: 1.0 },

  // Stats
  totalWins: 0,
  totalLosses: 0,
  maxStreak: 0,
  currentStreak: 0,
  history: [], // масив win/lose по раундах

  // Simulation control
  running: false,
  speed: 50, // ms затримка
};
```

## Залежності
001 — HTML skeleton

## Критерії приймання
1. Об'єкт стану визначений у секції model
2. Всі поля ініціалізовані коректно
3. Доступний з renderer та controller секцій

## Обмеження
Чистий JS. Без DOM-залежностей.
