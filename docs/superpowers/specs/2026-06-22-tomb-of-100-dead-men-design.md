# The Tomb of 100 Dead Men — Lovecraftian Horror Redesign

## Goal
Переробити візуальну ідентичність сторінки: від "generic dark theme" до атмосферного Lovecraftian/Bloodborne horror. Новий колір, типографіка, фактури, мікро-анімації. Друга фаза: виправити пропорції елементів.

## Scope
Один файл: `lesson2_1/index.html`. Тільки CSS + косметичні JS зміни (тексти, класи). Жодних змін логіки стратегій або симуляції.

## Architecture
- **Zero external deps** крім Google Fonts (2 шрифти)
- Всі зміни — в CSS та дрібні правки renderer JS
- Всі `id` та класи для JS залишаються незмінними
- Ніяких брейкінг-змін для існуючих задач

## Palette

| Роль | Hex | Використання |
|---|---|---|
| Void | `#0d0907` | Фон — теплий органічний морок |
| Panel | `#17120e` | Панелі, як старий пергамент у темряві |
| Stone | `#221c16` | Коробки, рамки |
| Bone | `#c4b8a8` | Текст |
| Dried Blood | `#6b1414` | Акцент, заголовки |
| Fresh Blood | `#c92a2a` | Активні елементи, слайдери |
| Rusted Gold | `#8b7340` | Окантовка, цифри, декоративні лінії |
| Vein | `#2d1b1b` | Границі панелей |
| Found | `#6aaa6a` | Знайдена коробка |

## Typography

| Роль | Шрифт | Де |
|---|---|---|
| Display | UnifrakturCook 700 | Заголовок, h2 панелей, оверлеї |
| Body/UI | VT323 | Весь текст, кнопки, статистика, path stripe |

## Tasks

### 026 — Lovecraftian CSS Theme
Повна заміна `:root` палітри, типографіки, візуальних стилів.
- Нова палітра: void, bone, dried blood, rusted gold, vein
- Google Fonts: UnifrakturCook + VT323
- UnifrakturCook для h1, h2, .overlay-text
- VT323 для всього іншого
- Мікродеталі: bevel на коробках, golden border на mugshot, decorative ◈ руни, vignette

### 027 — Telegram Path Stripe
Заміна path stripe на "телеграф з пекла".
- Idle текст: "Awaiting the warden's decree" з блімаючим курсором
- Rune marker (◈) з flash-анімацією перед "FOUND"
- Золота декоративна лінія зверху

### 028 — Lovecraftian Overlays
Заміна оверлеїв на UnifrakturCook + декоративні руни.
- Декоративні ◈ над і під текстом (CSS псевдоелементи)
- Lose: посилене тремтіння, більш драматичне

### 029 — Proportion Fix
Виправити диспропорцію елементів: збільшити всі інтерактивні елементи без ламання лейауту.
- **Сітку** — прибрати `max-width: 560px`. Сітка займає 100% ширини `.center-area`. Box font-size збільшити
- **Сайдбар** — збільшити ширину (175px → 200px). Збільшити шрифти selector, mixer labels, mixer sliders, buttons, speed slider
- **Header** — підняти на 4px (48px → 52px). Mugshot card збільшити
- **Path stripe** — збільшити до 38px для кращої читабельності
- **Bottom bar** — збільшити до 52px. Статистика читається легше
- **Mugshot canvas** — 36px → 44px для кращої видимості аватара
- **Головне правило:** всё растёт пропорционально, жоден елемент не вилазить за межі, немає скролу

## Success Criteria
1. Сторінка виглядає як Lovecraftian horror, не як generic dark theme
2. UnifrakturCook використовується тільки для акцентів (не для всього тексту)
3. Всі JS-функції працюють без змін
4. Жодних змін в стратегіях або симуляції
5. Немає скролу на 1024×768+
6. Елементи пропорційні: сітка, сайдбар, пат, нижня панель збалансовані
7. All prisoner names, colors, mugshots залишаються без змін
