# Task 032: Box Flip Animation (CSS + Renderer)

## Goal
Кожна коробка на сітці має два стани: закрита (показує порядковий номер ##01-##100) і відкрита (показує номер всередині). Перехід — CSS 3D flip-анімація.

## Dependencies
- Task 029 (proportion fix) — cancelled, superseded by 030
- **Залежить**: 030 (Dual Strategy Comparison) — впевнитись, що код не конфліктує

## Acceptance Criteria
1. Закриті коробки показують `##01`..`##100` (нумерація по grid position, 1-indexed).
2. При `s.revealed[i] = true` коробка робить flip (perspective + rotateY(180deg) за 200ms).
3. Після фліпа видно номер, який лежав всередині (`s.boxes[i]`).
4. Flip працює для обох станів (RUNNING і при швидкому перегляді).
5. `prefers-reduced-motion` — без анімації, миттєве перемикання.
6. Сумісність з dual-column: кожна колонка flip-ається незалежно.

## Implementation Plan

### CSS
```css
.box {
  perspective: 600px;
}
.box .box-inner {
  position: relative;
  width: 100%;
  height: 100%;
  transition: transform 0.2s ease;
  transform-style: preserve-3d;
}
.box.flipped .box-inner {
  transform: rotateY(180deg);
}
.box .box-front,
.box .box-back {
  position: absolute;
  inset: 0;
  backface-visibility: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
}
.box .box-back {
  transform: rotateY(180deg);
}
```

### DOM Structure Change
Кожен `.box` тепер містить:
```html
<div class="box" data-index="0">
  <div class="box-inner">
    <div class="box-front">##01</div>
    <div class="box-back">50</div>
  </div>
</div>
```

### Renderer Changes
- `ensureBoxElements()`: створювати `.box > .box-inner > .box-front + .box-back` замість голого тексту.
- `renderBoxGrid()`: для закритої коробки — показати `##N` у `.box-front`; при `revealed[i]` — додати клас `.flipped`, показати `s.boxes[i]` у `.box-back`.

## Files
- `lesson2_1/index.html` (CSS секція + RENDERER секція)
