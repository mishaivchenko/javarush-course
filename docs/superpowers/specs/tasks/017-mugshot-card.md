# TASK_SPEC: 017 — Mugshot Card

## Ціль
Додати mugshot-картку в header (правий верхній кут) для відображення поточного в'язня.

## Залежності
- 016-prisoner-identity (prisoners[] масив)

## Критерії приймання
1. Картка показує: піксель-аватар, ім'я (last, first), номер (#01–#100), статус
2. Статуси: AWAITING ORDER (idle), SEARCHING (жовтий пульс), SURVIVED (зелений), EXECUTED (червоний пульс)
3. Бордер картки змінюється на колір поточного в'язня
4. Плейсхолдер коли IDLE — "?" на чорному тлі
5. Розмір: ~240×42px, вписується в header-row

## Реалізація
- HTML: `.mugshot-card` всередині `.header-row`
- `renderMugshot()` — оновлює canvas, name, number, status, borderColor
- Canvas 36×36 px в .mugshot-badge

## Файли
- `lesson2_1/index.html` — HTML структура + renderMugshot()
