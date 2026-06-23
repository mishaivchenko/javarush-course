# Task 037: Found Name — Prisoner Name Under Successful Box

## Goal
Коли заключний знаходить свою картку (FOUND), під коробкою (або всередині, на back-стороні) відображається його ім'я. В успішному раунді всі 100 коробок матимуть імена під номерами.

## Dependencies
- 032 (Box Flip) — box-back структура

## Acceptance Criteria
1. При `foundPrisoner === prisonerId` (в `prisonerRun`) — в бокс записується ім'я заключного.
2. Ім'я показується на звороті коробки (під номером або замість), або як додатковий елемент `.found-name` всередині коробки.
3. Якщо заключний знайшов свою картку — `s.boxes[i]` дорівнює prisonerId, і ми знаємо хто це — `prisoners[prisonerId]`.
4. Ім'я залишається видимим після завершення раунду.
5. При наступному раунді (reset) — імена очищуються.
6. Формат: `Ivan Volkov` дрібним шрифтом VT323.

## Implementation

### Data model
В `renderBoxGrid()` при `(s.roundState === 'WIN' || s.revealed[i]) && s.boxes[i] === i`:
```js
const ownerId = s.boxes[i];
if (ownerId === i && prisoners[ownerId]) {
  // The box contains the prisoner's own number — show their name
  let nameEl = el.querySelector('.found-name');
  if (!nameEl) {
    nameEl = document.createElement('div');
    nameEl.className = 'found-name';
    el.appendChild(nameEl);
  }
  nameEl.textContent = prisoners[ownerId].firstName + ' ' + prisoners[ownerId].lastName;
}
```

### CSS
```css
.box .found-name {
  position: absolute;
  bottom: 1px;
  left: 0;
  right: 0;
  font-size: 0.45em;
  font-family: 'VT323', monospace;
  color: var(--found-text);
  text-align: center;
  line-height: 1;
  pointer-events: none;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
```

### Clear on reset
В `resetState()` — встановити прапорець або просто в `renderBoxGrid()` при IDLE стані видалити всі `.found-name`.

## Files
- `lesson2_1/index.html` (CSS + RENDERER — `renderBoxGrid()`)
