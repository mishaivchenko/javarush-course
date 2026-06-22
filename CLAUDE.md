# 100 Dead Men — Prisoner Simulation

## Project
`lesson2_1/index.html` — single-file browser simulation of the "100 prisoners and 100 boxes" problem. Dark pixel-prison theme (Bloodborne-inspired). No external dependencies.

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
- `docs/superpowers/specs/2026-06-22-100-dead-men-prisoner-ui-design.md` — current UI redesign spec (prisoner visuals + layout + path viz)
- `docs/superpowers/specs/tasks/` — individual task specs

## Active Tasks (current feature cycle)
| # | Task | File | Status |
|---|---|---|---|
| 016 | Prisoner Identity | `tasks/016-prisoner-identity.md` | ✅ Done |
| 017 | Mugshot Card | `tasks/017-mugshot-card.md` | ✅ Done |
| 018 | Layout No-Scroll | `tasks/018-layout-no-scroll.md` | ✅ Done |
| 019 | Path Visualization | `tasks/019-path-visualization.md` | ✅ Done |
| 020 | Polish & Test | `tasks/020-polish-and-test.md` | ✅ Done |

## Architecture (single HTML file, 4 JS sections)
1. **PRISONER DB** — name pool, pixel avatar generation (`generatePixelAvatar`), sprite generation
2. **MODEL** — state, permutations, 5 strategies (loop, panic, hybrid, sacrifice, mercy), simulation loop
3. **RENDERER** — box grid, mugshot card, path stripe, SVG path lines, stats bar, overlay
4. **CONTROLLER** — event listeners, lifecycle (init, run, pause, reset)

## Layout (no scroll)
- **Header** (48px): title + mugshot card (right)
- **Left sidebar** (175px): strategy select, mixers, buttons, speed slider
- **Center**: 10×10 box grid (flex, fills space) + SVG path lines overlay + WIN/LOSE overlay
- **Path stripe** (32px): single-line path text under grid
- **Bottom bar** (48px): Wins, Losses, Rate, Streak, State, cumulative meter

## Key Features
- 100 prisoners with unique names (40×40 pool, Soviet prison vibe)
- Pixel mugshots (canvas-generated 30×30, 5 hair styles, unique color per prisoner)
- 5 strategies with mixer sliders
- Path visualization: visited boxes colored by prisoner, SVG connection lines, step labels, pulsing name
- WIN/LOSE overlay animations
- Speed control slider

## Implementation Notes
- Prisoner colors: golden angle distribution, clamped to earth/blood/slate HSL gamut
- IDs 0-99, displayed as ##01-##100
- `renderBoxGrid()` sets inline styles (`borderColor`, `background`, `color`) for prisoner-colored boxes
- `renderPathLines()` draws SVG `<line>` elements between consecutive boxes
- CSS custom property `--prisoner-glow` and `--prisoner-glow-dim` for current-box pulse
- No external deps, no build step, just open in browser
