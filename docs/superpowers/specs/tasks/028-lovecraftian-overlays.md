# TASK_SPEC: 028 — Lovecraftian Overlays

## Ціль
Оформлення WIN/LOSE оверлеїв у стилі Lovecraftian horror: UnifrakturCook, декоративні rune-символи, посилені анімації.

## Залежності
- 026-lovecraftian-css-theme (палітра та шрифти)

## Критерії приймання
1. `.overlay-text` використовує `font-family: 'UnifrakturCook'`
2. Декоративні `◈` над і під текстом через CSS `::before` та `::after`
3. Lose-оверлей має посилену pulse-анімацію (більша амплітуда shadow)
4. WIN-оверлей: зелений зі спокійним світінням
5. Фон оверлею: `rgba(5, 3, 2, 0.8)` — не чорний, а теплий морок
6. Анімація появи: scale + fade (overlay-fade)

## Реалізація
- CSS: `.overlay-text` — UnifrakturCook; `::before`, `::after` — ◈
- CSS: `.overlay-text.lose` — посилений `text-shadow` та `lose-pulse`
- CSS: `.overlay` — новий `background: rgba(5, 3, 2, 0.8)`
- Жодних змін JS (renderOverlay.js не чіпати)

## Файли
- `lesson2_1/index.html` — CSS `.overlay`, `.overlay-text`, `.overlay-text.win`, `.overlay-text.lose`
