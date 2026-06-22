# TASK_SPEC: 012 — Cumulative Success Rate Meter

## Ціль
Горизонтальний CSS-бар, який показує загальний відсоток успішних раундів.

## Візуал
- Темний кам'яний трек
- Червоний заповнювач (колір змінюється залежно від рівня):
  - < 30%: `#8b0000`
  - 30–50%: `#cc0000`
  - > 50%: `#aa3333`
- Праворуч від бару — числове значення у відсотках (`29.7%`)
- Анімація заповнення (CSS transition на width)

## Розмітка
```html
<div class="meter-track">
  <div class="meter-fill" style="width: 29.7%"></div>
  <span class="meter-label">29.7%</span>
</div>
```

## Функція
```js
function renderMeter() {
  const rate = state.totalWins + state.totalLosses === 0
    ? 0
    : (state.totalWins / (state.totalWins + state.totalLosses)) * 100;
  // оновити width метра і текст
}
```

## Залежності
002 — CSS theme, 011 — Statistics panel

## Критерії приймання
1. Бар показує 0% спочатку
2. Змінюється після кожного раунду
3. Колір змінюється на порогах 30% і 50%
4. Плавна CSS transition на width

## Обмеження
Чистий CSS + JS. Без бібліотек.
