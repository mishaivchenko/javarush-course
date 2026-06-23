# Task 038: Dark Wood+Metal → Bloody Stone Textures

## Goal
Замінити текстури коробок. Закриті — dark wood з металом (Olli Kilpi). При фліпі (відкриті) — bloody stone (Wilhelm Gunkel). Кам'яна текстура була, але тепер вона червоно-чорна (кривава).

## Dependencies
- 032 (Box Flip) — box-front/back структура
- 031 (Unsplash API) — ключ і пошук

## Acceptance Criteria
1. `.box` (закрита) — фон: dark wood+metal текстура Olli Kilpi.
2. `.box .box-back` (відкрита) — фон: bloody stone текстура Wilhelm Gunkel.
3. `background-blend-mode: overlay` для обох.
4. Unsplash attribution оновлено з новими іменами.

## Implementation

### URLs
- **Closed (box-front)**: https://images.unsplash.com/photo-1698746396053-ce2807d855e3?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400 (Olli Kilpi — black metal organic)
- **Open (box-back)**: https://images.unsplash.com/photo-1639907087057-971905eeda58?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&q=80&w=400 (Wilhelm Gunkel — blood red stone)

### CSS changes
```css
.box {
  background-image: url('...Olli Kilpi...');
}
.box .box-back {
  background-image: url('...Wilhelm Gunkel...');
}
```

### Attribution
Оновити в comparison bar:
```
Wood: O.Kilpi. Stone: W.Gunkel. /Unsplash
```

## Files
- `lesson2_1/index.html` (CSS — `.box` background-image, `.box .box-back` background-image, attribution)
