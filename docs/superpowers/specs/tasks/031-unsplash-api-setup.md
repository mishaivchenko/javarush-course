# Task 031: Unsplash API Setup & Search

## Goal
Налаштувати Unsplash API ключ, виконати пошук тематичних зображень для гри (хорор, в'язниця, dungeons).

## Dependencies
— (перший task)

## Acceptance Criteria
1. Отримано Unsplash API key від користувача.
2. Виконано пошук по query `"horror prison dungeon"`, `"dark corridor"`, `"torture chamber"` — по 3 результати.
3. Обрано найкращі зображення для:
   — Фон сторінки (landscape, dark, atmospheric)
   — Box texture reference (optional)
4. Посилання на URL зображень збережено для використання в CSS/HTML.

## Implementation
1. Запитати в користувача Unsplash API key (або взяти з `.env` в `lesson1/`).
2. Запустити `./scripts/search.sh "horror prison dungeon" 1 5 latest landscape black_and_white`
3. Запустити `./scripts/search.sh "dark corridor" 1 5 latest landscape dark`
4. Запустити `./scripts/search.sh "torture chamber" 1 3 latest portrait`
5. Зберегти URL обраних зображень.

## Files
- `lesson1/.env` (API key)
- `.claude/skills/unsplash/scripts/search.sh`
