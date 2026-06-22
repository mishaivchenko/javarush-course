# TASK_SPEC: 009 — Strategy Selector and Runtime Mixers

## Ціль
Селектор стратегій (dropdown/radio) і динамічна панель міксерів, яка змінюється при виборі стратегії.

## Селектор
- `<select>` з 5 опціями (назви стратегій)
- При зміні: `state.strategy = value`, `state.config = Strategies[value].mixers.defaults`
- Перерендерити панель міксерів

## Mixer Panel
- Для кожної стратегії свій набір слайдерів
- Кожен слайдер: `<input type="range">` з min, max, step, value
- Поряд зі слайдером — числове значення
- При зміні: `state.config[key] = value`
- Слайдери можна міняти під час роботи симуляції — зміна впливає на наступний `decide()`

## Функція
```js
function renderMixerPanel() {
  const strategy = Strategies[state.strategy];
  // очистити панель
  // для кожного mixer: створити label + input + value
}
```

## Залежності
005 — Strategy engine, 003 — State model

## Критерії приймання
1. 5 стратегій у dropdown
2. При виборі — слайдери змінюються
3. Слайдери працюють
4. Зміна під час симуляції впливає негайно

## Обмеження
Тільки HTML + CSS + JS.
