# TASK_SPEC: 020 — Polish and Test

## Ціль
Фінальна інтеграція: переконатися що всі частини працюють разом, всі 5 стратегій коректні, UI не ламається.

## Залежності
- 016-prisoner-identity
- 017-mugshot-card
- 018-layout-no-scroll
- 019-path-visualization

## Критерії приймання
1. Всі 5 стратегій (loop, panic, hybrid, sacrifice, mercy) працюють без змін логіки
2. Мікшери оновлюються при зміні стратегії
3. Mugshot оновлюється кожен крок симуляції
4. WIN/LOSE оверлей працює (анімації, overlay-text класи win/lose)
5. Кнопки Run/Pause/Reset коректно блокуються/розблоковуються
6. Speed слайдер впливає на швидкість
7. Bottom bar статистика оновлюється (Wins, Losses, Rate, Streak, Meter)
8. Path лінії перемальовуються при resize вікна
9. Немає помилок в консолі
10. Немає скролу на 1024×768+

## Реалізація
- Перевірка що `Strategies` об'єкт не змінений
- `renderAll()` викликає всі рендер-функції
- `attachEventListeners()` коректно навішує обробники
- `onReset()` скидає всі лічильники
- `window.addEventListener('resize')` для SVG ліній

## Файли
- `lesson2_1/index.html` — фінальна інтеграція
