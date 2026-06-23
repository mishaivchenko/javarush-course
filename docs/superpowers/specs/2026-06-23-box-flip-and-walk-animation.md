# Box Flip & Prisoner Walk Animation

## Goal
Зробити процес пошуку коробок візуально зрозумілим: заключний фізично пересувається від коробки до коробки, а коробки роблять фліп-анімацію при відкритті (показуючи номер всередині замість порядкового номера коробки).

## Scope
- **Box flip**: кожна коробка має порядковий номер в закритому стані. При відкритті — 3D flip-анімація.
- **Prisoner walk**: анімоване переміщення іконки заключного від коробки до коробки по сітці.
- **Textures**: dark wood + metal з Unsplash для закритих коробок, bloody stone для відкритих.
- **YOU DIED**: заміна EXECUTED на YOU DIED (Souls серія).
- **Lose reveal**: при програші всі коробки перевертаються в початковий стан (rules: проиграл один — проиграли все).
- **Found name**: якщо заключний знаходить свою картку (FOUND), під коробкою залишається ім'я.

## Approach
- Чистий CSS 3D transform для flip-анімації (perspective, rotateY).
- Для walk-анімації — абсолютно позиціонований `div` заключного.
- Unsplash API для текстур: dark wood/metal → bloody stone.
- Без ##, гра на шрифтах (UnifrakturCook для закритих, VT323 для відкритих).

## Architecture
- **CSS**: `.box.flipped`, `.box .box-front`, `.box .box-back`, `.prisoner-walker`, `.box .found-name`.
- **Renderer**: `renderBoxGrid()`, `updateWalkerPosition()`, `renderFoundNames()`.
- **Controller**: інтеграція анімацій в `prisonerRun()`.

## Success Criteria
1. Кожна закрита коробка показує номер (01-100) готичним шрифтом.
2. При фліпі — bloody stone текстура, номер VT323.
3. Іконка заключного рухається по сітці.
4. При LOSE — всі коробки повертаються в закритий стан.
5. При FOUND — під коробкою ім'я заключного.
6. Unsplash текстури: dark wood+metal → bloody stone.
7. YOU DIED замість EXECUTED.
8. Dual-column.

## Dependencies
- Unsplash API key
