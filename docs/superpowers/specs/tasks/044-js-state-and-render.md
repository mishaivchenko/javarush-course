# Task 044: index.html — State Machine & Render Functions
**GitHub Issue:** https://github.com/mishaivchenko/javarush-course/issues/5

## Goal
Implement the JavaScript state machine, render functions, and DOM element binding inside `index.html`.

## Dependencies
- 043 (HTML structure and CSS — elements must exist in DOM)

## Acceptance Criteria
- [ ] All DOM elements bound via `document.getElementById` in a `bindElements()` function
- [ ] Global `state` object with:
  - `keywords: string`
  - `lang: string` (language code)
  - `spice: number` (0–6)
  - `langOpen: boolean`
  - `resultState: "empty" | "loading" | "error" | "done"`
  - `errorMsg: string`
  - `lines: string[]`
  - `doneLang: string`
  - `doneSpice: string`
  - `history: Array<{id, lines[], haiku, langLabel, spice, timeLabel}>`
- [ ] `LANGS` constant array with 12 languages (code, label, native field)
- [ ] `SPICE_DESCRIPTIONS` array (0–6) for rendering spice label on done state
- [ ] `renderResult()` — dispatches to:
  - `renderEmpty()` — shows empty state with ring
  - `renderLoading()` — shows spinner and text
  - `renderError()` — shows error icon + message
  - `renderDone()` — shows 3 haiku lines + metadata tags
- [ ] `renderKeywords()` — syncs textarea value, updates count label
- [ ] `renderLanguage()` — builds menu, updates button text, toggles dropdown visibility
- [ ] `renderWasabi()` — renders 6 dots, updates label, shows max indicator when spice=6
- [ ] `renderHistory()` — renders history item cards, shows/hides empty state
- [ ] `renderGenerateButton()` — updates text and disabled state
- [ ] `render()` — calls all render sub-functions
- [ ] `LAZY` rendering: keywords and wasabi render independently (for real-time updates)
- [ ] `phrases()` helper — parses keywords string into array (split by comma/newline, trim, filter empty)
- [ ] `labelOf(code)` — returns language label for a code

## Implementation Notes
- All JS in a single `<script>` block at the end of `<body>` (or in `<head>` with DOMContentLoaded)
- Use an IIFE `(function(){ 'use strict'; ... })()` to avoid global scope pollution
- Render functions should be pure (read from state, write to DOM)
- State is the single source of truth — DOM reads state, not the other way around
- `renderKeywords()` handles the case where `els.keywords.value !== state.keywords` (user pasted)

## Files Touched
- `lesson3/haiku-50/index.html` (edit — add JS state section)
