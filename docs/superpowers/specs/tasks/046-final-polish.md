# Task 046: Final Polish & Verification
**GitHub Issue:** https://github.com/mishaivchenko/javarush-course/issues/7

## Goal
End-to-end verification, edge case testing, cleanup, and final commit.

## Dependencies
- 045 (all JS functionality in place)

## Acceptance Criteria
- [ ] Server starts with `npm start` and serves all files
- [ ] `http://localhost:3000` loads the app
- [ ] Splash screen plays (3s animation with SVG)
- [ ] **Empty state:** App shows Bento Grid with "No haiku yet", empty history
- [ ] **Validation errors:**
  - 0 words → error "Enter 3 to 7 words or phrases"
  - 2 words → error "Enter 3 to 7 words or phrases"
  - 8 words → error "Too many — keep it to 7 words or phrases at most"
  - No language → error "Choose a generation language"
- [ ] **Keywords input:**
  - Comma-separated words work
  - Newline-separated words work
  - Count label updates in real-time (✓ when 3–7)
  - Clear button works
- [ ] **Language dropdown:**
  - Opens on click, shows 12 languages with native names
  - Selecting a language updates the button text
  - Clicking outside closes the dropdown
- [ ] **Wasabi cycling:**
  - Click cycles 0→1→2→3→4→5→6→0
  - Dots light up correctly
  - "Heat level" label updates
  - "As hot as it gets" shows at level 6
- [ ] **Generate flow:**
  - Button disabled during loading, shows "Generating…"
  - Loading spinner visible
  - Result appears as 3 lines in Noto Serif JP
  - Language and wasabi meta tags shown below haiku
- [ ] **History:**
  - New haiku saved to history (most recent first)
  - Persists on page reload (localStorage)
  - Max 100 items
  - Clear history works
- [ ] **Error states:**
  - API timeout → "The request took too long"
  - Network disconnect → "Server is temporarily unavailable"
  - Server error → generic error message
- [ ] **Profanity modal:**
  - Shows when profanity detected (if possible to test)
  - Shows flagged words
  - Close via ✕, action button, overlay click, Escape
  - Body scroll locked when modal open
- [ ] **Responsive:**
  - Desktop (>979px): 3-column grid
  - Tablet (640–979px): 2-column grid
  - Mobile (<640px): 1-column grid, single-column history
- [ ] **Reduced motion:** `prefers-reduced-motion: reduce` disables animations
- [ ] **No console errors**
- [ ] **No API key in any committed file** (check `.env` not in git, no key in `index.html` or `server.js`)
- [ ] **Final commit** with descriptive message

## Verification Commands
```bash
# Start server
cd lesson3/haiku-50 && npm start

# Test API
curl -X POST http://localhost:3000/generate-haiku \
  -H "Content-Type: application/json" \
  -d '{"words":["sakura","rain","silence"],"language":"en","wasabiLevel":0}'

# Test validation
curl -X POST http://localhost:3000/generate-haiku \
  -H "Content-Type: application/json" \
  -d '{"words":["too","few"],"language":"en","wasabiLevel":0}'

# Check no .env in git
git check-ignore lesson3/haiku-50/.env
```

## Files Touched
- `lesson3/haiku-50/index.html` (final edits if needed)
- `lesson3/haiku-50/server.js` (final edits if needed)
- `lesson3/haiku-50/prompts.js` (final edits if needed)
