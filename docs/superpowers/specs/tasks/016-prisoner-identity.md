# TASK_SPEC: 016 — Prisoner Identity

## Ціль
Додати кожному зі 100 в'язнів унікальну візуальну ідентичність: ім'я, піксельний аватар, унікальний колір.

## Залежності
Немає.

## Критерії приймання
1. 100 в'язнів з унікальними іменами (пул 40 first × 40 last = 1600 комбінацій, радянські/моторошні прізвища)
2. Кожен має піксельний аватар (canvas 30×30, 5 зачісок, випадковий тон шкіри, темна палітра)
3. Кожен має унікальний колір (золотий перетин по hue, clamped в earth/blood/slate)
4. Аватар генерується один раз при initPrisoners() через seededRandom
5. Дані зберігаються в масиві prisoners[] — { id, firstName, lastName, color, avatar }

## Реалізація
- `prisonerColor(index)` — повертає `hsl(h, 45%, 45%)` з golden angle
- `seededRandom(seed)` — LCG для детермінованої генерації
- `generatePixelAvatar(seed, color)` — малює на tempCanvas 30×30, скейлиться x4
- `initPrisoners()` — shuffle + цикл на 100 ітерацій

## Файли
- `lesson2_1/index.html` — PRISONER DB скрипт
