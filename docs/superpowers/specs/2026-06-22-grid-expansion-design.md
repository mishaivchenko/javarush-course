# Grid Expansion — Design Spec

## Goal
Радикально збільшити сітку 10×10, яка зараз займає ~40% ширини екрану. Забрати обмеження `max-width: 560px`, дати сітці рости пропорційно вікну. Коробки мають бути великими, читабельними.

## Scope
Один файл: `lesson2_1/index.html`. Тільки CSS + дрібні корективи HTML/JS. Ніяких нових фіч.

## What Changes

### 1. Grid width
- `.grid`: прибрати `max-width: 560px` → дозволити `width: 100%` від center-area
- `max-width` все ж залишити на 85% щоб не впиралось в краї зовсім
- `.grid-wrapper` центрує сітку

### 2. Box size & readability
- `.box`: `font-size` з `0.55em` → `0.85em` (цифри читаються на великих коробках)
- `.box .step-label`: `font-size` з `0.5em` → `0.6em`
- `gap` з `3px` → `4px` (більше повітря)

### 3. Compact surroundings
Щоб звільнити максимум висоти для сітки:
- `--header-h`: 48 → 40px
- `--bottom-h`: 48 → 40px
- `--path-h`: 32 → 28px
- Header шрифт h1: `1.6em` → `1.3em`
- Mugshot картка трохи компактніша

### 4. Sidebar
- `--sidebar-w`: 175 → 165px (легке звуження)
- Mixer шрифти: `0.6em` → `0.55em`
- Всі padding в `.panel` трохи менші

## Projected cell sizes
| Screen | Before | After |
|---|---|---|
| 1920×1080 | ~52px | ~82px |
| 1440×900 | ~48px | ~70px |
| 1280×720 | ~42px | ~52px |
| 1024×768 | ~40px | ~44px |

## Success Criteria
1. Grid займає ~85% ширини center-area, не 40%
2. Box font-size достатній для читання номерів
3. Нічого не вилазить за межі екрану (no scroll)
4. Всі функції працюють як раніше
5. На 1024×768 — мінімум комфортний (44px+)
