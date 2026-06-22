# TASK_SPEC: 011 — Live Statistics Panel

## Ціль
Панель зі статистикою в реальному часі: номер раунду, поточний в'язень, стан, перемоги/поразки, відсоток, стрік.

## Поля (всі live)
- **Round:** `state.round`
- **Prisoner:** `state.currentPrisoner + 1 / 100`
- **Boxes opened:** `state.prisonerStep / 50`
- **State:** IDLE | RUNNING | WIN | LOSE (різними кольорами)
- **Wins:** `state.totalWins`
- **Losses:** `state.totalLosses`
- **Success rate:** `(totalWins / (totalWins+totalLosses)) * 100` або `0%`
- **Longest streak:** `state.maxStreak`

## Візуал
- Кожен рядок — лейбл зліва, значення справа
- State має колір: RUNNING = жовтий, WIN = зелений, LOSE = червоний, IDLE = сірий
- Значення оновлюються через `renderStatusPanel()`

## Функція
```js
function renderStatusPanel() {
  // Оновити текст у відповідних DOM-елементах
}
```

## Залежності
003 — State model

## Критерії приймання
1. Всі поля показують коректні значення
2. Оновлюються при кожному render()
3. State має кольорове позначення
4. Success rate показує 0% поки немає раундів

## Обмеження
Чистий JS + CSS.
