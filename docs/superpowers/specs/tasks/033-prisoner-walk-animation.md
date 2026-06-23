# Task 033: Prisoner Walk Animation

## Goal
Заключний фізично пересувається по сітці від коробки до коробки. Це дає відчуття, що персонаж реально йде і відкриває ящики.

## Dependencies
- 032 (Box Flip Animation) — потрібна структура box-елементів для позиціонування

## Acceptance Criteria
1. Над сіткою (або як частина сітки) з'являється іконка/маркер заключного.
2. Маркер анімовано рухається від поточної коробки до наступної.
3. Траєкторія: маркер з'являється біля first box, переміщується до другої, третьої і т.д.
4. Швидкість руху відповідає `s.speed` (speed slider).
5. Після FOUND/FAIL маркер зникає або змінює стан.
6. Маркер — мініатюрний mugshot заключного (у вигляді кола 16×16 з кольором та ініціалами).
7. Dual-column: маркери рухаються незалежно в обох колонках.

## Implementation Plan

### CSS
```css
.prisoner-walker {
  position: absolute;
  width: 18px;
  height: 18px;
  border-radius: 50%;
  z-index: 5;
  pointer-events: none;
  transition: left 0.15s ease, top 0.15s ease;
  box-shadow: 0 0 8px currentColor;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 8px;
  font-family: 'VT323', monospace;
  color: #fff;
  line-height: 1;
  text-shadow: 0 0 4px #000;
}
```

### DOM
- `.grid-wrapper` отримує `position: relative`.
- Додати `div.prisoner-walker` всередину `.grid-wrapper` (один на колонку).

### Renderer
- `updateWalkerPosition(s, walkerEl)`: обчислює позицію boxElement[i] через `getBoundingClientRect()`, встановлює `left`/`top` для `walkerEl`.
- Викликається після кожного `s.prisonerPath.push()` в `renderAll()`.
- При IDLE/неактивному стані — приховати `display: none`.

### Integration with Model
- В `prisonerRun()`, після `s.prisonerPath.push()` перед `renderAll()` — чекати `sleep(s.speed * 0.3)` для анімації переходу.
- Або використати CSS transition: JS встановлює нову позицію, CSS анімує перехід.

## Files
- `lesson2_1/index.html` (CSS + RENDERER + MODEL секції)
