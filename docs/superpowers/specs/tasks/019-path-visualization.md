# TASK_SPEC: 019 — Path Visualization

## Ціль
Візуалізувати шлях в'язня по коробках: підсвітка на сітці + SVG лінії з'єднань + текстова стрічка.

## Залежності
- 016-prisoner-identity (prisoners[] для кольору)
- 018-layout-no-scroll (path stripe місце в layout)

## Критерії приймання
1. Посещені коробки: dim-версія кольору в'язня (background: `color + '33'`, borderColor: color, color: color)
2. Поточна коробка: glow + pulse (`current-pulse` анімація, `--prisoner-glow` CSS custom property)
3. Знайдена коробка: зелена вспышка + scale (клас `.flash-green`, `current-found` анімація)
4. SVG лінії між послідовними коробками в шляху, колір в'язня, старші кроки dimmer
5. Текстова стрічка під сіткою: останні 8 кроків, ім'я пульсує під час пошуку
6. Номер кроку на кожній посещеній коробці (step-label)
7. При LOSE — остання коробка підсвічується `.failed` (скидає inline стилі)

## Реалізація
- `renderBoxGrid()` — inline стилі для `.visited`, `.current`, `.flash-green`, `.failed`
- `renderPathLines()` — SVG `<line>` елементи в `#path-lines` overlay
- `renderPathStripe()` — HTML з останніми 8 кроками, клас `.pulse-name`
- `.path-lines { position: absolute; pointer-events: none }` всередині `.grid-wrapper`

## Файли
- `lesson2_1/index.html` — CSS + renderBoxGrid() + renderPathLines() + renderPathStripe()
