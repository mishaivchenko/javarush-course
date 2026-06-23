# Task 036: Lose Reveal — All Boxes Reset to Closed State

## Goal
Правила: проіграв один — проіграли всі. При LOSE всі 100 коробок повинні повернутися в початковий закритий стан (як до початку раунду). Не просто фліп, а візуально — всі revealed скидаються.

## Dependencies
- 032 (Box Flip) — потрібна flip-структура

## Acceptance Criteria
1. При `s.roundState === 'LOSE'` всі коробки перевертаються назад: `.flipped` знімається з усіх.
2. `.box-front` показує порядковий номер.
3. `.box-back` прихований.
4. Стан `revealed` **не** скидається в моделі (щоб статистика коректна) — це суто візуальний ефект.
5. Колір/фон коробок при цьому — `failed` (темно-червоний).
6. Анімація — масова: всі коробки синхронно перевертаються.

## Implementation
В `renderBoxGrid()` додати блок на початку:
```js
if (s.roundState === 'LOSE') {
  // Force all boxes to show closed state visually
  for (...) {
    el.classList.add('failed');
    el.classList.remove('flipped', 'revealed');
    if (front) front.textContent = String(i+1).padStart(2, '0');
    if (back) back.textContent = '';
  }
  return; // skip normal rendering
}
```
Це після того як в моделі `s.revealed` все ще містить дані, але візуально все закрито з `failed` класом.

**Важно**: виконати цю логіку **після** того, як `s.roundState` встановлено в 'LOSE', але до `renderAll()`. Можна прямо на початку `renderBoxGrid()`.

## Files
- `lesson2_1/index.html` (RENDERER — `renderBoxGrid()`)
