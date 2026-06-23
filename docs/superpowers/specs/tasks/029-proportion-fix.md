# TASK_SPEC: 029 — Proportion Fix

## Ціль
Виправити диспропорцію елементів: всі інтерактивні елементи (сайдбар, сітка, path stripe, bottom bar, mugshot) збільшені пропорційно. Жоден елемент не вилазить, немає скролу.

## Залежності
- 018-layout-no-scroll (перевірити що лейаут без скролу не зламаний)
- 021-grid-expansion (перевірити що сітка без max-width все ще працює)

## Критерії приймання
1. **Сітка:** `max-width` прибраний; сітка займає всю доступну ширину `.center-area` (за мінусом gap/padding)
2. **Box font-size:** збільшено з 0.5em до 0.7-0.9em (цифри читаються на великих коробках)
3. **Сайдбар:** ширина збільшена з 175px до 200px
4. **Selector:** шрифт збільшений, паддінг збільшений
5. **Mixer sliders:** товщина слайдера збільшена з 4px до 6px; thumb з 12px до 14px
6. **Buttons:** font-size збільшений, padding збільшений
7. **Speed slider:** аналогічно mixer sliders — збільшений
8. **Header:** збільшено з 48px до 52px
9. **Mugshot canvas:** збільшено з 36px до 44px
10. **Path stripe:** збільшено з 30px до 38px, font-size збільшено
11. **Bottom bar:** збільшено з 44px до 52px
12. **Немає скролу на 1024×768+** — перевірено
13. **Всі елементи поміщаються** — нічого не вилазить за межі
14. **Всі стратегії працюють** — жодних змін логіки

## Реалізація
- CSS: зміни `:root` змінних (`--sidebar-w`, `--header-h`, `--bottom-h`, `--path-h`)
- CSS: збільшені `font-size` та `padding` для `.box`, `select`, `.btn`, `.mixer-group`, `input[type="range"]`
- CSS: збільшений `#mugshot-canvas` width/height
- HTML: `<canvas>` width/height з 36 до 44

## Важливі зауваження
- Не змінювати `#app max-width` (залишити 1200px) — це обмежує загальну ширину
- Не чіпати `.grid` aspect-ratio 1/1 і gap
- Перевірити що `.grid-wrapper` flex-центрування працює з новими розмірами
- Перевірити `.box` aspect-ratio 1/1 не зламаний

## Файли
- `lesson2_1/index.html` — CSS змінні, HTML canvas розмір
