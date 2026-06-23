# TASK_SPEC: 030 — Dual Strategy Comparison

## Ціль
Додати можливість запустити дві стратегії одночасно, порівняти результати на двох полях.

## Залежності
- Виправити баги з tasks 026-029 (зламаний HTML, canvas draw)
- 018-layout-no-scroll (лейаут без скролу має лишитись)

## Критерії приймання

### Bugfix (перед новою фічею)
1. HTML path-stripe закритий правильно (`</div>`)
2. Mugshot canvas idle draw: `fillRect(0, 0, 44, 44)` — весь canvas
3. Mugshot canvas prisoner draw: `drawImage(img, 0, 0, 44, 44)` — весь canvas
4. Idle '?' текст: `ctx.fillText('?', 22, 30)` — центрований на 44×44

### Dual Strategy
5. Два поля 10×10, розташовані горизонтально
6. **Кожне поле має:** свій select стратегії, свої mixer sliders, свою path stripe, свою статистику (Wins, Losses, Rate, Streak, State)
7. Header: загальні кнопки Run All / Pause All / Reset All + спільний Speed slider
8. Mugshot card прибраний з хедера (недоречно для двох полів)
9. **Обидві симуляції біжать паралельно** (`Promise.all`)
10. **Однакова permutation** для обох полів — чесне порівняння
11. Під полями — **comparison bar**: Win Rate A vs B, Avg Steps/Found A vs B
12. Lovecraftian тема збережена
13. Немає скролу
14. Всі 5 стратегій працюють на обох полях

### Скрол — допустимий на малих екранах
На 1024×768+ скролу немає. На менших — вертикальний скрол допустимий (але не бажаний).

## Архітектура

### State
```js
const stateA = { /* повна копія поточного state */ }
const stateB = { /* повна копія поточного state */ }
```

### Permutation (спільна)
```js
const perm = generatePermutation();
stateA.boxes = perm;
stateB.boxes = [...perm];
```

### DOM
```
#app
  .header-row (без mugshot)
    h1
    Global controls: [Run All] [Pause All] [Reset All] Speed slider
  .dual-area
    .column-a
      .panel (strategy select + mixers)
      .grid-wrapper > .grid-a
      .path-stripe-a
      .stats-a
    .column-b
      .panel (strategy select + mixers)
      .grid-wrapper > .grid-b
      .path-stripe-b
      .stats-b
  .comparison-bar
    Win Rate: A xx% | B yy% | Diff: zz
    Avg Steps: A x.x | B y.y
```

### Renderer
Кожна функція дублюється: `renderBoxGridA()`, `renderBoxGridB()`. Вони ідентичні за логікою, але пишуть в різні DOM-елементи.

### Simulation
```js
async function runAll() {
  stateA.running = true; stateB.running = true;
  const perm = generatePermutation();
  stateA.boxes = perm; stateB.boxes = [...perm];
  await Promise.all([runLoopA(), runLoopB()]);
}
```

## Файли
- `lesson2_1/index.html` — всі зміни (CSS, HTML, MODEL, RENDERER, CONTROLLER)
