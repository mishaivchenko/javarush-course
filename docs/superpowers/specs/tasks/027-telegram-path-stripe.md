# TASK_SPEC: 027 — Telegram Path Stripe

## Ціль
Заміна path stripe на "телеграф з пекла": idle-текст з блімаючим курсором, rune marker перед "FOUND", золота декоративна лінія.

## Залежності
- 026-lovecraftian-css-theme (палітра та шрифти)

## Критерії приймання
1. Idle-стан: текст "Awaiting the warden's decree" з блімаючим квадратним курсором (■) через CSS `::after`
2. Клас `.idle-ticker` додається до `.path-stripe` коли стан IDLE
3. Перед "FOUND" з'являється rune marker `◈` з flash-анімацією (3 швидких спалахи)
4. `.path-stripe` має золоту декоративну лінію зверху (CSS `::before` градієнт)
5. Всі зміни — CSS + мінімальні JS (текст idle, клас, rune marker)

## Реалізація
- CSS: `.path-stripe.idle-ticker` з `::after { content: '■'; animation: ticker-blink }`
- CSS: `.rune-marker` з `animation: rune-flash`
- JS: `renderPathStripe()` — встановлює idle текст і клас; додає `<span class="rune-marker">◈</span>` перед FOUND

## Файли
- `lesson2_1/index.html` — CSS `.path-stripe`, `.idle-ticker`, `.rune-marker`; JS `renderPathStripe()`
