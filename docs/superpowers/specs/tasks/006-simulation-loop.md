# TASK_SPEC: 006 — Simulation Loop

## Ціль
Асинхронна функція, яка виконує один раунд симуляції: в'язні один за одним відкривають скриньки. Кожен крок — await sleep(delay) для візуалізації.

## API
```js
async function runRound() {
  // 1. generatePermutation()
  // 2. for prisoner 0..99:
  //    2a. prisonerRun(prisonerId)
  //    2b. if failed → LOSE, break
  // 3. if all succeeded → WIN
  // 4. updateStats()
  // 5. if state.running → runRound() again
}
```

## Функція prisonerRun
```js
async function prisonerRun(prisonerId) {
  // 1. state.currentPrisoner = prisonerId
  // 2. state.prisonerStep = 0
  // 3. state.prisonerPath = []
  // 4. currentBox = strategy.decide(prisonerId, ...)
  // 5. while currentBox !== null && step < 50:
  //    5a. open box → reveal number
  //    5b. state.prisonerPath.push(currentBox)
  //    5c. render()
  //    5d. await sleep(state.speed)
  //    5e. if boxes[currentBox] === prisonerId → SUCCESS, return
  //    5f. state.prisonerStep++
  //    5g. currentBox = strategy.decide(prisonerId, boxes[currentBox], ...)
  // 6. FAILURE — prisoner didn't find
}
```

## Принципи
- `await sleep()` між кожним відкриттям
- `state.roundState = 'RUNNING'` під час роботи
- Після WIN/LOSE — пауза ~1.5s, потім новий раунд (якщо running)
- Якщо `state.running` стає false під час паузи — не стартувати новий раунд

## Залежності
004 — Permutation, 005 — Strategy Engine, 003 — State model

## Критерії приймання
1. В'язні біжать один за одним
2. Кожен крок — затримка
3. При невдачі негайний LOSE
4. При успіху всіх — WIN
5. Автоматичний старт наступного раунду
6. Pause зупиняє цикл

## Обмеження
Чистий JS. Асинхронний. Використовує `setTimeout` в `sleep()`.
