# TASK_SPEC: 026 — Lovecraftian CSS Theme

## Ціль
Повна заміна візуальної ідентичності: нова палітра (void, bone, dried blood, rusted gold, vein), нова типографіка (UnifrakturCook + VT323), фактурні деталі (bevel на коробках, golden border на mugshot, decorative runes, ambient vignette).

## Залежності
Немає.

## Критерії приймання
1. `:root` палітра замінена на Lovecraftian: `--bg: #0d0907`, `--panel: #17120e`, `--text: #c4b8a8`, `--accent: #6b1414`, `--accent-bright: #c92a2a`, `--gold: #8b7340`, `--vein: #2d1b1b`
2. Google Fonts підключені: UnifrakturCook 700 + VT323
3. `h1` та `.panel h2` використовують `font-family: 'UnifrakturCook'`
4. Вся інша типографіка — `font-family: 'VT323'`
5. `.box` має направлений bevel (світліший зверху/зліва, темніший знизу/справа)
6. `.mugshot-card` має золоту border-рамку через CSS mask-composite
7. `#app::after` додає ambient vignette на весь екран
8. Медіа-запит `prefers-reduced-motion: reduce` вимикає всі анімації
9. Всі JS `id` та використовувані класи не змінені
10. Немає помилок в браузерній консолі

## Реалізація
- CSS: повна заміна всього `<style>` блоку
- Google Fonts: `<link>` в `<head>`
- Зміни палітри зворотно сумісні (нові кольори, ті ж CSS-змінні)

## Файли
- `lesson2_1/index.html` — CSS theme, Google Fonts
