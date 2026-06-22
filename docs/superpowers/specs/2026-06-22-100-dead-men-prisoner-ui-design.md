# Prisoner Visual Identity & UI Clarity — Design Spec

## Goal
Single-page `lesson2_1/index.html` overhaul: give each of the 100 prisoners a unique visual identity (name + pixel mugshot + color) and reorganize the layout so everything fits in one viewport with clear start→steps→result zones.

## What Changes

### 1. Prisoner Identity System

**Name Pool** — 100 prisoners, each gets a unique name generated at init from arrays:
- First names: `['Ivan','Dmitri','Alexei','Nikolai','Vladimir','Boris','Sergei','Mikhail','Pavel','Yuri','Andrei','Konstantin','Oleg','Maxim','Viktor','Grigori','Anton','Valentin','Roman','Eduard','Semyon','Ignat','Arkadi','Leonid','Vasili','Fyodor','Gennadi','Stepan','Yaroslav','Taras','Bogdan','Zakhar','Artem','Danil','Makar','Timur','Ruslan','Marat','David','Daniel']`
- Last names: `['Volkov','Morozov','Kozlov','Petrov','Sokolov','Romanov','Fedorov','Ivanov','Smirnov','Kuznetsov','Popov','Lebedev','Novikov','Zaitsev','Baranov','Sorokin','Belyaev','Titov','Gromov','Alexandrov','Chernov','Orlov','Yakovlev','Vorobiev','Vinogradov','Karpov','Mironov','Lavrov','Timofeev','Matveev','Scheglov','Astakhov','Zolotov','Krutov','Serebrov','Belov','Isaev','Medvedev','Voropaev','Sudakov']`

**Pixel Avatar** — each prisoner rendered on a 30×30 canvas with:
- Random skintone from a dark/morbid palette
- Simple pixel face (eyes, nose, mouth — generated from seed)
- Random hair color & style (bald, short, mohawk, etc.)
- Prison uniform accent color (their unique color)
- Canvas converts to data URL for `<img>` in mugshot

**Unique Color** — each prisoner assigned a Hue from a distributed palette (hue rotation around an earth/blood/slate gamut), used for:
- Mugshot card border
- Box grid path indicators for this prisoner
- Name tag color
- Path text markers

**Mugshot Card** — rendered in the top-right corner during a round:
```
┌───────────────────┐
│ [#01] IVAN VOLKOV │  ← Name + number, colored by prisoner
│ ┌──────┐          │
│ │pixel │ SEARCHING│  ← Status text (pulsing yellow)
│ │avatar│          │
│ └──────┘          │
│ FOUND: 0/50 steps │  ← Step progress
└───────────────────┘
```
- Size: ~180×130px (compact, fits corner)
- When IDLE: shows placeholder "AWAITING ORDER"
- When RUNNING: shows current prisoner with animated status
- When WIN/LOSE: flash overlay (existing) + mugshot shows final state

### 2. Layout Overhaul (No Scroll)

```
┌──────────────────────────────────────────────────────────────┐
│ HEADER: 100 DEAD MEN              │     [Mugshot Card]      │
├─────────────┬────────────────────────────────────────────────┤
│  CONTROLS   │                                               │
│  ─────────  │        BOX GRID (10×10) — centered            │
│  Strategy   │                                               │
│  Mixers     │    (path highlights on grid cells)            │
│  Speed      │                                               │
│  [▶][⏸][↺]  │                                               │
│             ├────────────────────────────────────────────────┤
│             │ PATH: box#5→[42]→box#17→[71]→...→FOUND ✓     │
├─────────────┴────────────────────────────────────────────────┤
│  Wins: 12  Losses: 8  Rate: 60%  Streak: 5  [████░░] 62.3% │
└──────────────────────────────────────────────────────────────┘
```

**Sections:**
- **HEADER** (35px): Title left, Mugshot card right (180×130, overlaps slightly)
- **LEFT SIDEBAR** (~180px): Controls panel — strategy select, mixers, speed, buttons. Compact vertical stack.
- **CENTER** (remaining space): Box grid 10×10. Grid gap reduced to 3px to save space.
- **PATH STRIPE** (30px): Single line of text below grid, shows last 8 steps with arrows.
- **BOTTOM BAR** (40px): Stats inline — Wins, Losses, Rate, Streak, plus thin cumulative meter bar.

All heights calculated to fit within 100vh at common resolutions (1024×768 minimum).

### 3. Box Grid Path Visualization

When a prisoner searches:
- **Current box**: bright red pulse + step number shown in cell
- **Visited boxes**: dim red with step number overlay
- **Found box**: green background + flash animation
- **Failed box**: dark red + skull-like overlay
- Boxes that belong to current prisoner's chain are connected with a subtle line overlay (SVG or CSS)

Path stripe below grid (single line, no scroll):
```
box#05 → slip 42 → box#17 → slip 71 → box#33 → FOUND ✓
```
- Shows last 8 steps max
- Green for found, red if failed
- Colored by prisoner's accent color

### 4. Layout Details

**Spacing budget (1024×768):**
- Header: 35px + 8px padding
- Grid area: 480×480px (48px per cell, 10 cells, 4px gap)
- Path stripe: 30px
- Bottom bar: 40px
- Sidebar: full height (~570px), scrollable if content overflows (but should be compact)
- Mugshot: floats over header/grid edge, ~180×130px

**Responsiveness:**
- Works on 1280×720 and larger
- Minimum: 1024×768
- Below that — browser scaling handles it, no media queries needed for scope

### 5. When WIN/LOSE

- Existing overlay animation preserved (scale + pulse effect)
- Mugshot card freezes on the last prisoner with final status
- Bottom bar shows the result in the rate/meter

### 6. What Stays the Same

- All 5 strategies (loop, panic, hybrid, sacrifice, mercy) — zero changes
- Mixer sliders per strategy
- Permutation generation
- Simulation loop logic
- Dark Bloodborne CSS theme (colors, fonts, borders)
- WIN/LOSE overlay with animations

### 7. Technical Implementation

**File:** `lesson2_1/index.html` (single file, zero external deps)

**New sections to add (see individual task specs):**
1. **Prisoner DB** — array of 100 `{id, firstName, lastName, hexColor, avatarDataUrl}` generated at init → `tasks/016-prisoner-identity.md`
2. **Avatar renderer** — `generatePixelAvatar(seed, color)` → canvas → data URL → `tasks/016-prisoner-identity.md`
3. **Mugshot DOM** — new element in HTML, rendered by renderMugshot() → `tasks/017-mugshot-card.md`
4. **Layout CSS** — flexbox/grid layout: sidebar + center + bottom bar, no overflow scroll → `tasks/018-layout-no-scroll.md`
5. **Path viz** — step numbers in grid cells, removed old path-display → `tasks/019-path-visualization.md`
6. **Path text** — one-line text under grid replacing old path-display content → `tasks/019-path-visualization.md`
7. **Prisoner-colored path** — visited boxes tinted by prisoner color, SVG connection lines, pulsing name → `tasks/019-path-visualization.md`
8. **Integration & test** — verify all strategies, no errors, no scroll → `tasks/020-polish-and-test.md`

### 8. Post-Design Additions (implemented after initial spec)

**Prisoner-colored path visualization on grid:**
- Visited boxes take dim version (`color + '33'` background) of prisoner's unique color instead of generic red
- Current box gets prisoner-color glow + pulse animation (`current-pulse` keyframes, CSS custom property `--prisoner-glow`)
- Found box: green flash with scale animation (`current-found`)
- SVG path lines between consecutive boxes in the chain, colored by prisoner, older steps dimmer
- Prisoner name in path-stripe pulses during RUNNING state (`.pulse-name` animation)
- `.box` element styles use inline `style` properties (`borderColor`, `background`, `color`) set per-prisoner

## Success Criteria
1. No scrollbar on 1024×768+ viewports
2. Each prisoner has a visible name + mugshot + color during run
3. Box grid shows step numbers and path highlights
4. Path text line under grid shows current chain
5. Mugshot updates every step
6. All 5 strategies work identically to before
7. WIN/LOSE animations still work
8. Layout never cuts off content
9. Visited boxes show prisoner's color, not generic red
10. SVG lines connect visited boxes in path order
