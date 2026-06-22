# TASK_SPEC: 014 — Controller Integration

## Ціль
За'язати все докупи: event listeners, render pipeline, sleep() helper, ініціалізація.

## Структура controller секції
```js
// Helpers
function sleep(ms) { return new Promise(r => setTimeout(r, ms)); }

// Init
function init() {
  generatePermutation();
  renderAll();
  attachEventListeners();
}

// Render all
function renderAll() {
  renderBoxGrid();
  renderStatusPanel();
  renderMixerPanel();
  renderMeter();
  renderPrisonerPath();
}

// Event listeners
function attachEventListeners() {
  // strategy selector → onStrategyChange
  // mixers → onMixerChange
  // run button → onRun
  // pause button → onPause
  // reset button → onReset
  // speed slider → onSpeedChange
}
```

## Event Handlers
- `onRun()`: `state.running = true`, запускає `runLoop()` (якщо не біжить)
- `onPause()`: `state.running = false`
- `onReset()`: `state.running = false`, скидає стан, generatePermutation(), renderAll()
- `onStrategyChange(value)`: `state.strategy = value`, `state.config = defaults`, renderMixerPanel()
- `onMixerChange(key, value)`: `state.config[key] = value`
- `onSpeedChange(value)`: `state.speed = value`

## runLoop
```js
async function runLoop() {
  while (state.running) {
    state.round++;
    state.roundState = 'RUNNING';
    await runRound(); // з 006
    renderAll();
    if (!state.running) break;
    if (state.roundState === 'WIN') await sleep(2000);
    else await sleep(2000);
  }
}
```

## Залежності
001–013

## Критерії приймання
1. init() викликається при завантаженні
2. Всі event listeners працюють
3. renderAll() викликається після кожного кроку
4. sleep() працює коректно
5. Немає помилок у консолі

## Обмеження
Чистий JS.
