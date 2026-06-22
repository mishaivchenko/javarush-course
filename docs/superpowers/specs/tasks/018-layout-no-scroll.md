# TASK_SPEC: 018 — Layout No-Scroll

## Ціль
Переробити компонування сторінки так, щоб усе вміщувалося в один viewport без скролу.

## Залежності
Немає.

## Критерії приймання
1. Відсутній скрол на viewport 1024×768+
2. Чотири зони: header (48px), sidebar (175px) + center (flex), path stripe (32px), bottom bar (48px)
3. Сітка 10×10 центрована, aspect-ratio 1, max-width 560px
4. Сайдбар: стратегія, мікшери, кнопки, швидкість
5. Bottom bar: Wins, Losses, Rate, Streak, State, Meter (inline)
6. Всі панелі з panel-класом, темна тема збережена
7. Sidebar scrollable якщо контент не влазить (запасний варіант)

## Реалізація
- CSS Grid/Flex: `.middle-area { display: flex }`, `.sidebar { width: var(--sidebar-w) }`
- `.center-area { flex: 1 }` з `.grid-wrapper { flex: 1; display: flex; align-items: center; justify-content: center }`
- Прибрані зайві панелі старого layout

## Файли
- `lesson2_1/index.html` — CSS + HTML структура
