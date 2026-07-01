# Task 045: index.html — Event Handlers & API Client
**GitHub Issue:** https://github.com/mishaivchenko/javarush-course/issues/6

## Goal
Implement event binding, the `generateHaiku()` API client, the `generate()` main handler, history persistence via localStorage, and profanity modal control.

## Dependencies
- 044 (state and render functions must exist)

## Acceptance Criteria
- [ ] `bindEvents()` registers all event listeners on `DOMContentLoaded`
- [ ] Keywords textarea `input` → updates `state.keywords` → calls `renderKeywords()`
- [ ] Language button `click` → toggles `state.langOpen` → calls `renderLanguage()`
- [ ] Language menu options `click` → sets `state.lang` = selected code → closes menu → calls `render()`
- [ ] Outside click on language card → closes menu
- [ ] Wasabi button `click` → cycles `state.spice` (0→1→2→3→4→5→6→0) → calls `renderWasabi()`
- [ ] Generate button `click` → calls `generate()`
- [ ] Clear keywords `click` → clears keywords, focuses textarea, re-renders
- [ ] Clear history `click` → clears `state.history`, removes from localStorage, re-renders
- [ ] Modal close button `click` → `hideProfanityModal()`
- [ ] Modal action button `click` → `hideProfanityModal()`
- [ ] Modal overlay `click` (on backdrop) → `hideProfanityModal()`
- [ ] Escape key `keydown` → `hideProfanityModal()` if modal visible
- [ ] Enter key in textarea → trigger generate button click (if not disabled)
- [ ] `generateHaiku(words, language, wasabiLevel)` API client:
  - POST to `/generate-haiku` with JSON body
  - `AbortController` with 30s timeout
  - Handles network errors ("Failed to fetch" → "Server unavailable")
  - Handles abort errors ("AbortError" → "Request took too long")
  - Returns parsed JSON on success
  - Throws on HTTP error, preserving `profanityWords` if present
- [ ] `generate()` main handler:
  - Guards against double-submit (return if `resultState === "loading"`)
  - Client-side validation: word count 3–7, language required
  - Sets `resultState = "loading"` → calls `render()`
  - Calls `generateHaiku()`
  - On success: parses lines (max 3), saves to history, saves to localStorage, sets `resultState = "done"`, calls `render()`
  - On profanity error: calls `showProfanityModal()`, resets to `"empty"`
  - On other error: sets `resultState = "error"`, `errorMsg`, calls `render()`
  - On API returning empty haiku: uses fallback `["Silence", "where words should be", "a blank page"]`
- [ ] `showProfanityModal(words)`:
  - Renders word list using `escapeHtml()`
  - Sets `modal.hidden = false`
  - Sets `document.body.style.overflow = "hidden"`
- [ ] `hideProfanityModal()`:
  - Sets `modal.hidden = true`
  - Restores `document.body.style.overflow = ""`
- [ ] `loadHistory()`:
  - Reads `localStorage.getItem('haikuHistory')`
  - Parses JSON, validates array
  - Sets `state.history`
  - Handles corrupted data (starts fresh)
- [ ] `escapeHtml(str)` utility function
- [ ] Init flow on `DOMContentLoaded`: `bindElements()` → `loadHistory()` → `bindEvents()` → `render()`

## Files Touched
- `lesson3/haiku-50/index.html` (edit — add JS events + API section)
