# TASK_SPEC: 005 — Strategy Engine

## Ціль
Реалізувати 5 стратегій, які визначають, яку скриньку відкриває в'язень на кожному кроці.

## API
```js
const Strategies = {
  loop:      { name, mixers, decide },
  panic:     { name, mixers, decide },
  hybrid:    { name, mixers, decide },
  sacrifice: { name, mixers, decide },
  mercy:     { name, mixers, decide },
};
```

## Кожна стратегія
- `name`: рядок
- `mixers`: об'єкт `{ key: { min, max, default, step } }`
- `decide(prisonerId, currentBox, openedBoxes, config, boxes, stepCount)` → `number | null`
  - Повертає індекс наступної скриньки або null (зупинитись)

## 5 стратегій

### 1. The Loop Protocol
- **mixers:** `discipline` (0–1, default 1)
- **Логіка:** Починає зі `prisonerId`, потім переходить до `boxes[currentBox]`. З імовірністю `discipline` слідує циклу, інакше — випадкова невідкрита скринька.

### 2. Blind Panic
- **mixers:** `memory` (0–1, default 0.5)
- **Логіка:** Обирає випадкову скриньку серед невідкритих. `memory` контролює, чи фільтрує "погані" скриньки (які вже ніколи не приведуть до цілі).
  - High memory (≥0.8): оптимальний випадковий пошук (тільки серед невідкритих)
  - Low memory (≤0.2): може повторювати відкриті скриньки (чистіший хаос)

### 3. Hybrid Ritual
- **mixers:** `faith` (1–50, default 25), `panicThreshold` (1–50, default 10)
- **Логіка:** Починає як Loop Protocol. Якщо `stepCount > faith`, перемикається на Blind Panic (з високим memory). Або якщо кількість невдалих відкриттів > `panicThreshold`.

### 4. Lucky Sacrifice
- **mixers:** `obedienceRate` (0–1, default 0.5)
- **Логіка:** На початку проходу в'язня кидається монетка: з `obedienceRate` — Loop Protocol, інакше — Blind Panic з `memory=0.3`.

### 5. Warden's Mercy
- **mixers:** `mercyChance` (0–1, default 0.1), `extraBoxes` (1–50, default 10)
- **Логіка:** Loop Protocol. Якщо в'язень вичерпав ліміт (50) і не знайшов — з імовірністю `mercyChance` отримує `extraBoxes` додаткових спроб.

## Залежності
003 — State model

## Критерії приймання
1. 5 об'єктів у Strategies
2. Кожен має `decide()` який повертає число або null
3. Стратегія обирається через `state.strategy`
4. `decide` читає `state.config` — зміна слайдерів впливає негайно
5. Стратегія циклів дає ~30% успіху, випадкова ~0% (перевіряється статистично за 1000+ раундів)

## Обмеження
Чистий JS. Без DOM.
