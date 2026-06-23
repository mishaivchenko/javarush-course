# The Tomb of 100 Dead Men — Prisoner Simulation

## Project
`lesson2_1/index.html` — single-file browser simulation of the "100 prisoners and 100 boxes" problem. Lovecraftian horror theme (Bloodborne-inspired). Google Fonts: UnifrakturCook (display) + VT323 (body).

## Spec → Tasks Rule
Кожна велика зміна (feature) проходить через цей процес:

1. **Spec** — дизайн-документ в `docs/superpowers/specs/YYYY-MM-DD-name.md`. Описує: goal, scope, approach, architecture, success criteria.
2. **Tasks** — декомпозиція spec на окремі задачі в `docs/superpowers/specs/tasks/NNN-name.md`. Кожен task описує: ціль, залежності, критерії приймання, реалізацію, файли.
3. **Виконання** — tasks виконуються по черзі. Якщо під час реалізації зʼявляються нові деталі, вони додаються в task spec або створюється новий task.
4. **CLAUDE.md** — відображає актуальну архітектуру проекту.

### Нумерація
- Tasks нумеруються по порядку (001, 002…) незалежно від spec.
- Якщо spec описує велику зміну (наприклад UI redesign), його таски можуть мати крізну нумерацію: від 016 до 020.

## Key Files
- `lesson2_1/index.html` — main application (strategy engine, renderer, controller, all in one file)
- `docs/superpowers/specs/2026-06-22-100-dead-men-design.md` — original project design spec
- `docs/superpowers/specs/2026-06-22-100-dead-men-prisoner-ui-design.md` — prisoner UI redesign spec (mugshots, layout, path viz)
- `docs/superpowers/specs/2026-06-22-grid-vfx-design.md` — grid & visual effects spec (tasks 021-025)
- `docs/superpowers/specs/2026-06-22-tomb-of-100-dead-men-design.md` — Lovecraftian horror redesign spec
- `docs/superpowers/specs/2026-06-22-dual-strategy-comparison.md` — dual strategy comparison spec
- `docs/superpowers/specs/tasks/` — individual task specs

## Active Tasks (current feature cycle: Lose Reveal, Found Names, Blood Stone)
| # | Task | File | Status |
|---|---|---|---|
| 030 | Dual Strategy Comparison | `tasks/030-dual-strategy-comparison.md` | ✅ Done |
| 031 | Unsplash API Setup & Search | `tasks/031-unsplash-api-setup.md` | ✅ Done |
| 032 | Box Flip Animation (CSS + Renderer) | `tasks/032-box-flip-animation.md` | ✅ Done |
| 033 | Prisoner Walk Animation | `tasks/033-prisoner-walk-animation.md` | ✅ Done |
| 034 | Unsplash Background & Box Textures | `tasks/034-unsplash-background-integration.md` | ✅ Done |
| 035 | YOU DIED — Dark Souls Lose Screen | `tasks/035-you-died-souls-screen.md` | 🔲 Pending |
| 036 | Lose Reveal — All Boxes Reset to Closed | `tasks/036-lose-reveal-all-boxes.md` | 🔲 Pending |
| 037 | Found Name — Prisoner Name Under Box | `tasks/037-found-name-under-box.md` | 🔲 Pending |
| 038 | Dark Wood+Metal → Bloody Stone Textures | `tasks/038-dark-wood-and-blood-stone-textures.md` | 🔲 Pending |

## Task Archive (completed)
| # | Task | File |
|---|---|---|
| 001-015 | Core game (skeleton, theme, model, strategies, loop, renderers, controller) | `tasks/001-*.md` – `tasks/015-*.md` |
| 016 | Prisoner Identity | `tasks/016-prisoner-identity.md` |
| 017 | Mugshot Card | `tasks/017-mugshot-card.md` |
| 018 | Layout No-Scroll | `tasks/018-layout-no-scroll.md` |
| 019 | Path Visualization | `tasks/019-path-visualization.md` |
| 020 | Polish & Test | `tasks/020-polish-and-test.md` |
| 021 | Grid Expansion | `tasks/021-grid-expansion.md` |
| 022 | Compact Bottom | `tasks/022-compact-bottom.md` |
| 023 | Fill Sidebar Void | `tasks/023-sidebar-void.md` |
| 024 | First & Last Box Effects | `tasks/024-first-last-box-effects.md` |
| 025 | Blood Lose Screen | `tasks/025-blood-lose-screen.md` |
| 026 | Lovecraftian CSS Theme | `tasks/026-lovecraftian-css-theme.md` |
| 027 | Telegram Path Stripe | `tasks/027-telegram-path-stripe.md` |
| 028 | Lovecraftian Overlays | `tasks/028-lovecraftian-overlays.md` |
| 029 | Proportion Fix (cancelled — superseded by 030) | `tasks/029-proportion-fix.md` |
| 030 | Dual Strategy Comparison | `tasks/030-dual-strategy-comparison.md` |

## Architecture (single HTML file, 4 JS sections)
1. **PRISONER DB** — name pool, pixel avatar generation (`generatePixelAvatar`), sprite generation
2. **MODEL** — state, permutations, 5 strategies (loop, panic, hybrid, sacrifice, mercy), simulation loop
3. **RENDERER** — box grid, mugshot card, path stripe, SVG path lines, stats bar, overlay
4. **CONTROLLER** — event listeners, lifecycle (init, run, pause, reset)

## CSS Theme (Lovecraftian Horror)
- **Palette:** void `#0d0907`, panel `#17120e`, bone `#c4b8a8`, dried blood `#6b1414`, rusted gold `#8b7340`, vein `#2d1b1b`
- **Display:** UnifrakturCook 700 — h1, h2, overlays
- **Body:** VT323 — all other text, labels, stats, controls
- **Details:** trapdoor bevel on boxes, golden reliquary border on mugshot card, ambient vignette (`#app::after`), decorative ◈ runes
- **Reduced motion:** `@media (prefers-reduced-motion: reduce)` kills all animations

## Layout (no scroll)
- **Header** (52px): title + mugshot card (right, canvas 44×44)
- **Left sidebar** (200px): strategy select, mixers, buttons, speed slider
- **Center**: 10×10 box grid (flex, fills space, no max-width) + SVG path lines overlay + WIN/LOSE overlay
- **Path stripe** (38px): telegram-style idle message + path text
- **Bottom bar** (52px): Wins, Losses, Rate, Streak, State, cumulative meter

## Key Features
- 100 prisoners with unique names (40×40 pool, Soviet prison vibe)
- Pixel mugshots (canvas-generated 30×30, 5 hair styles, unique color per prisoner)
- 5 strategies with mixer sliders
- Path visualization: visited boxes colored by prisoner, SVG connection lines, step labels, pulsing name, ◈ rune marker on FOUND
- WIN/LOSE overlay animations (UnifrakturCook, decorative runes)
- Speed control slider
- Ambient vignette, golden decorative lines, telegram ticker

## Implementation Notes
- Prisoner colors: golden angle distribution, clamped to earth/blood/slate HSL gamut
- IDs 0-99, displayed as ##01-##100
- `renderBoxGrid()` sets inline styles (`borderColor`, `background`, `color`) for prisoner-colored boxes
- `renderPathLines()` draws SVG `<line>` elements between consecutive boxes
- CSS custom property `--prisoner-glow` and `--prisoner-glow-dim` for current-box pulse
- Google Fonts: UnifrakturCook 700 + VT323 (preconnect + preload)
- No build step, just open in browser
