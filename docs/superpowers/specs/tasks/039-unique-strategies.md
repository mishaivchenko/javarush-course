# Task 039 — Unique Strategies (Dual Column)

## Goal
Заборонити вибір однакової стратегії в колонках A та B. Якщо користувач вибирає стратегію в колонці A, вона стає недоступною для вибору в колонці B, і навпаки.

## Dependencies
- Поточна архітектура Dual Strategy (дві колонки з окремими `<select>`) — вже працює

## Acceptance Criteria
- [ ] Колонка A та B не можуть мати однакову стратегію одночасно
- [ ] При зміні стратегії в A, варіант що збігається з B — блокується (або прибирається з опцій)
- [ ] При зміні стратегії в B, варіант що збігається з A — блокується
- [ ] Якщо стратегії збігаються після зміни — автоматично перемикаємо ту, що змінюється, на першу доступну відмінну
- [ ] `<option>` що вже вибрана в іншій колонці — має `disabled` (не можна вибрати)

## Implementation

### Файл
- `lesson2_1/index.html` — Controller секція

### Логіка
1. Знайти функцію, яка обробляє зміну стратегії ( `onStrategyChange` або аналогічний `change` listener на `<select>`)
2. Додати перевірку: якщо вибрана стратегія збігається з тією що вже вибрана в іншій колонці:
   - Знайти першу стратегію (по порядку з `Strategies`), яка не збігається
   - Перемкнути поточний `<select>` на неї
3. Оновити `renderStrategySelector` — при генерації `<option>` додавати `disabled` для стратегії що вибрана в іншій колонці (якщо вона не поточна)
4. Викликати `renderStrategySelector` для обох колонок після зміни стратегії в будь-якій

### Код (псевдо)
```js
function updateStrategyExclusivity(changedState, otherState) {
  if (changedState.strategy === otherState.strategy) {
    // Find first available strategy that differs
    const keys = Object.keys(Strategies);
    const alt = keys.find(k => k !== changedState.strategy);
    changedState.strategy = alt || keys[0];
  }
  // Re-render both selectors to update disabled states
  renderStrategySelector(stateA, 'strat-select-a');
  renderStrategySelector(stateB, 'strat-select-b');
}
```

### renderStrategySelector changes
```js
function renderStrategySelector(s, selectId) {
    const select = document.getElementById(selectId);
    if (!select) return;
    select.innerHTML = '';
    const other = (s === stateA) ? stateB : stateA;
    const otherStrat = other.strategy;
    for (const [key, strat] of Object.entries(Strategies)) {
      const opt = document.createElement('option');
      opt.value = key;
      opt.textContent = strat.name;
      if (key === s.strategy) opt.selected = true;
      if (key === otherStrat && key !== s.strategy) opt.disabled = true;
      select.appendChild(opt);
    }
}
```

## Files
- `lesson2_1/index.html` (Controller секція — `onStrategyChange`, `renderStrategySelector`)
