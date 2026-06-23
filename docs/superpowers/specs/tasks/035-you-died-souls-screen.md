# Task 035: YOU DIED — Dark Souls Style Lose Screen

## Goal
Замінити "EXECUTED" на "YOU DIED" з кінематографічним стилем (Dark Souls).

## Dependencies
- 032 (Box Flip)

## Acceptance Criteria
1. При LOSE state текст оверлею — "YOU DIED".
2. Шрифт UnifrakturCook, червоний, з ефектом появи (fade in).
3. Під текстом декоративна лінія.
4. Path stripe теж показує "YOU DIED" замість "EXECUTED".
5. Dual-column.

## Implementation
В `renderOverlay()`:
```
text.textContent = 'YOU DIED';
```
В `renderPathStripe()`:
```
html += ' — <span class="fail-text">✖ YOU DIED</span>';
```

## Files
- `lesson2_1/index.html` (RENDERER секція)
