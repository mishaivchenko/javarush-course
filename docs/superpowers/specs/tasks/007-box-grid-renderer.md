# TASK_SPEC: 007 — Box Grid Renderer

## Ціль
Відрендерити 100 скриньок як сітку 10×10 у DOM. Кожна скринька — `<div class="box">`.

## Рендеринг
- Створити сітку через `.grid { display: grid; grid-template-columns: repeat(10, 1fr); }`
- Кожна скринька має `data-index` (0–99)
- Стани скриньок через CSS класи:
  - `.box` — закрита, темна
  - `.box.revealed` — показує число всередині
  - `.box.current` — червоний бордер (поточна)
  - `.box.found` — блідий зелений (знайдено свій номер)
  - `.box.failed` — темно-червоний (частина failed path)
  - `.box.in-path` — сірий/димчастий (частина шляху поточного в'язня)

## Функція
```js
function renderBoxGrid() {
  // for i in 0..99:
  //   отримати box = document.querySelector(`[data-index="${i}"]`)
  //   або створити новий
  //   встановити класи згідно state.revealed[i], state.prisonerPath, ...
  //   якщо revealed, показати state.boxes[i]
}
```

## Залежності
002 — CSS theme, 003 — State model

## Критерії приймання
1. 100 комірок у сітці 10×10
2. Кожна має data-index
3. Стани міняються згідно класів
4. Текст числа показаний при відкритті
5. Не створювати нові div-и при кожному render — оновлювати існуючі

## Обмеження
Чистий JS + CSS. DOM-маніпуляції тільки через renderBoxGrid().
