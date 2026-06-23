# Task 034: Unsplash Background & Box Texture Integration

## Goal
Вбудувати зображення з Unsplash в гру: фон сторінки + текстура на кожну клітинку поля.

## Dependencies
- 031 (Unsplash API Setup) — отримано URL зображень

## Acceptance Criteria
1. Body отримує background image з Unsplash (темний коридор).
2. Зображення затемнене через overlay, щоб не заважати читабельності.
3. Кожна закрита коробка (`div.box`) має текстуру каменю/цегли з Unsplash як background.
4. Текстура клітинок не заважає тексту (номеру всередині).
5. Attribution Unsplash відображається десь на сторінці.
6. Dual-column: обидві колонки використовують ті самі текстури.

## Implementation

### Background
```css
body {
  background: url('https://images.unsplash.com/photo-1720642436687-6969d99712f9?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w5ODAyNDJ8MHwxfHNlYXJjaHwxfHxob3Jyb3IlMjBwcmlzb24lMjBkdW5nZW9uJTIwZGFyayUyMGNvcnJpZG9yfGVufDB8MHwyfGJsYWNrX2FuZF93aGl0ZXwxNzgyMTk4MjMxfDA&ixlib=rb-4.1.0&q=80&w=1080') center/cover no-repeat fixed;
}
#app::before {
  content: '';
  position: fixed;
  inset: 0;
  background: rgba(13, 9, 7, 0.85);
  pointer-events: none;
  z-index: -1;
}
```

### Box texture
```css
.box {
  background-image: url('https://images.unsplash.com/photo-1737033764140-fcd66828325e?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3w5ODAyNDJ8MHwxfHNlYXJjaHwxfHxzdG9uZSUyMHRleHR1cmV8ZW58MHwyfHx8MTc4MjE5ODI2MHww&ixlib=rb-4.1.0&q=80&w=400');
  background-size: cover;
  background-blend-mode: overlay;
  /* text still readable on top */
}
```
- `background-blend-mode: overlay` + темний `background-color` — текстура проглядає, але текст читається.
- При `revealed`/`visited`/`current` — текстура зберігається, але колір змінюється через `background-blend-mode`.

### Attribution
Внизу `.header-row` або в `.comparison-bar`:
```html
<span style="font-size:0.5em;color:var(--text-dim);opacity:0.5;">
  Bg: Alan Pope / Unsplash. Textures: Freddie / Unsplash.
</span>
```

## Files
- `lesson2_1/index.html` (CSS секція — body background, .box background-image, attribution)
