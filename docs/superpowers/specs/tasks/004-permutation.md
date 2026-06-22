# TASK_SPEC: 004 — Permutation Generation

## Ціль
Функція, яка генерує випадкову перестановку чисел 0–99 (номери в'язнів) для 100 скриньок. Використовує Fisher-Yates shuffle.

## API
```js
function generatePermutation() {
  // returns array of 100 ints, each 0-99, no repeats
}
```

## Поведінка
- Кожен новий раунд викликає `generatePermutation()`
- Результат записується в `state.boxes`
- `state.revealed` скидається в `false`

## Залежності
003 — State model

## Критерії приймання
1. `state.boxes` містить числа 0–99 без повторів
2. Кожен виклик дає різний порядок (імовірнісно)
3. Викликається при старті нового раунду

## Обмеження
Чистий JS. Без crypto API — Math.random достатньо.
