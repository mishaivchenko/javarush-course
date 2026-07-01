# Haiku 50 — Design Spec

> **Date:** 2026-06-30
> **Project:** `lesson3/haiku-50/`
> **Status:** Design phase (no code)
> **Reference:** `https://haiku-50.onrender.com` (audited in `HANDOFF_REVIEW.md`)

---

## 1. Goal

Build a Japanese minimalistic haiku generator powered by OpenAI API. The app lets users enter 3–7 keywords, choose a language and "wasabi" (spiciness) level, then generates a 3-line haiku. This is a JavaRush homework assignment — the objective is to **apply structured methodology** (audit → spec → tasks → code), not to copy a reference.

---

## 2. Scope

### In Scope
- Bento Grid UI (single-file HTML)
- 12 languages (same set as reference: uk, en, de, ja, fr, es, it, pt, pl, zh, ko, ar)
- Wasabi level 0–6 with dot indicators
- Keywords input (textarea, 3–7 words validated)
- API integration (Express + OpenAI `gpt-5-nano-2025-08-07`)
- Two-layer prompt system (base + spiciness) in a separate `prompts.js`
- History (last 100, localStorage)
- Profanity detection (server-side, localized)
- Responsive design (3 breakpoints: default, tablet, mobile)
- Error handling (client + server side, modal for profanity)
- Security (API key in `.env`, `.env` in `.gitignore`)

### Out of Scope
- Database
- Authentication
- User registration
- Mobile app
- Syllable analyzer
- Build pipeline / bundler
- Social sharing
- Multiple AI models

---

## 3. Architecture

```
┌─────────────────────────────────────────────────┐
│                   Browser                         │
│  ┌───────────────────────────────────────────┐   │
│  │         index.html (single file)          │   │
│  │  ┌─────┐ ┌──────┐ ┌─────┐ ┌──────────┐  │   │
│  │  │Bento│ │State │ │Fetch│ │localStorage│  │   │
│  │  │ Grid│ │Machine│ │client│ │ (history) │  │   │
│  │  └─────┘ └──────┘ └─────┘ └──────────┘  │   │
│  └───────────────────────────────────────────┘   │
│                        │ POST /generate-haiku     │
│                        ▼                          │
└────────────────────────┼──────────────────────────┘
                         │ HTTPS
┌────────────────────────┼──────────────────────────┐
│  server.js (Express)   │                          │
│  ┌────────────────┐    │                          │
│  │ Validation      │◄───┘                          │
│  │ (source of truth)│                              │
│  └───────┬────────┘                                │
│          │ (validated)                              │
│          ▼                                          │
│  ┌────────────────┐                                │
│  │ prompts.js      │──── prompts ────► OpenAI API   │
│  │ (base + spice + │                                │
│  │  safety + fmt)  │                                │
│  └────────────────┘                                │
└─────────────────────────────────────────────────────┘
```

### Data Flow
1. User enters keywords, selects language, adjusts wasabi level
2. Frontend validates (3–7 words, language required)
3. POST to `/generate-haiku` with `{words[], language, wasabiLevel}`
4. Server validates (same rules, source of truth)
5. Server builds prompt from `prompts.js`
6. Server calls OpenAI API with constructed prompt
7. Server normalizes response (strip markdown, split into 3 lines)
8. Returns `{haiku: string}`
9. Frontend renders haiku + metadata, saves to history

---

## 4. API Contract

### Endpoint
```
POST /generate-haiku
```

### Request
```json
{
  "words": ["sakura", "rain", "silence"],
  "language": "en",
  "wasabiLevel": 0
}
```

| Field | Type | Range | Notes |
|---|---|---|---|
| `words` | `string[]` | 3–7 items | Trimmed, non-empty |
| `language` | `string` | One of 12 codes | `"en"`, `"ja"`, etc. |
| `wasabiLevel` | `number` | 0–6 | 0 = calm, 6 = max heat |

### Success Response (200)
```json
{
  "haiku": "Sakura petals drift\nrain traces circles on the pond\nsilence holds its breath"
}
```

### Validation Error (400)
```json
{
  "error": "Enter 3 to 7 words or short phrases",
  "profanityWords": ["word1", "word2"]
}
```

The `profanityWords` field is only present when profanity was detected.

### Server Error (500)
```json
{
  "error": "Something went wrong. Try again."
}
```

---

## 5. Prompt Architecture

All prompts live in `prompts.js` — completely separate from the server logic.

### Base Layer
```
You are a haiku master. Write a haiku in {language} using these words: {words}.

Requirements:
- Exactly 3 lines
- Each line is one phrase (not one word per line)
- Use the given words to set the imagery
- The haiku must feel poetic, not literal
- Do not explain, translate, or add preamble
- Output ONLY the 3 lines, separated by newlines
```

### Spiciness Layer (appended to base)
```
Spiciness level: {wasabiLevel}
{spiceDescription}
```

Spice descriptions (from the reference, adapted):

| Level | Description |
|---|---|
| 0 | Calm, traditional, contemplative haiku about nature and transience. |
| 1 | A light, quiet sketch with a gentle mood. |
| 2 | Slightly unexpected, with subtle irony. |
| 3 | Playful, with humor and a surprising twist. |
| 4 | Bold and sharp, with an absurd image. |
| 5 | Very spicy, chaotic, grotesque and funny. |
| 6 | Maximum heat: absurd, chaotic, surreal and dark-humored — yet still three lines of haiku. |

### Safety Layer (appended last)
```
- No profanity, aggression, or prohibited content
- Keep it safe for general audience
```

### Format Normalization (post-API)
```javascript
function normalizeHaiku(raw) {
  // 1. Strip markdown wrappers (``` ... ``` or """ ... """)
  // 2. Remove introductory text ("Here is a haiku:")
  // 3. Split by newline
  // 4. Keep exactly first 3 non-empty lines
  // 5. If < 3 lines, pad or error
  // 6. Trim whitespace per line
}
```

### Model Configuration
- **Model:** `gpt-5-nano-2025-08-07`
- **reasoning_effort:** `"low"` or `"medium"` (cheaper, faster)
- **verbosity:** `"low"` (exactly 3 lines, no surrounding text)

---

## 6. Component Tree (Frontend)

```
app
├── SplashScreen          (3s animation, SVG logo, fade-out)
├── Screen
│   ├── Header
│   │   ├── Brand         (Haiku 50 + 俳句)
│   │   └── Description   (instructional text)
│   ├── Bento Grid
│   │   ├── ResultCard     (Haiku output / empty / loading / error)
│   │   ├── KeywordsCard   (textarea + count + clear)
│   │   ├── LanguageCard   (dropdown, 12 options)
│   │   ├── WasabiCard     (button + 6 dots + heat label)
│   │   ├── HistoryCard    (saved haiku list, 2-col grid)
│   │   └── InfoCard       (5-7-5 info + Generate button)
│   └── ProfanityModal     (overlay, word list, close handlers)
```

### State Machine
```
EMPTY ──► LOADING ──► DONE
  │                      │
  └──► ERROR ◄───────────┘
        │
        └──► EMPTY (on clear/retry)

PROFANITY_MODAL (overlays any state, returns to EMPTY on close)
```

---

## 7. CSS Architecture

### Design Tokens
```css
--bg-cream:   #f1efe8
--card-white: rgba(255, 255, 255, 0.88)
--text-dark:  #232220
--text-muted: #a8a496
--text-dim:   #b3afa3
--accent:     #5c8a4a
--accent-bg:  #eef3e9
--border:     rgba(231, 227, 216, 0.78)
--error-red:  #c0392b
--wasabi-max: #c98a3a
```

### Fonts
- **Display/Serif:** `Noto Serif JP` (headings, haiku lines, splash title)
- **Body:** `Noto Sans JP` (all other text, labels, controls)

### Layout
- CSS Grid with 3 columns → 2 columns → 1 column (responsive)
- Same grid-template-areas pattern as reference:
  ```
  Desktop:              Tablet:               Mobile:
  ┌──────┬─────┬────┐   ┌────────┬──────┐   ┌──────────┐
  │result│result│words│  │ result │result│   │  result   │
  │      │      ├────┤   ├────────┼──────┤   ├──────────┤
  │      │      │lang│   │ word   │ lang │   │  input    │
  ├──────┼──────┼────┤   ├────────┼──────┤   ├──────────┤
  │history│hist │info│   │ wasabi │ info │   │  lang     │
  └──────┴──────┴────┘   ├────────┴──────┤   ├──────────┤
                          │   history    │   │  wasabi   │
                          └──────────────┘   ├──────────┤
                                             │  info     │
                                             ├──────────┤
                                             │ history   │
                                             └──────────┘
  ```

### Animations
- `@keyframes h50splash` — splash screen fade (3s)
- `@keyframes h50splashLogo` — logo entrance
- `@keyframes h50spin` — loading spinner
- `@keyframes h50up` — card content entrance
- `@keyframes h50pop` — result pop-in
- `@media (prefers-reduced-motion: reduce)` — disables all animations

---

## 8. Error Handling

### Client-Side (index.html)
| Scenario | UX |
|---|---|
| < 3 words | Show error in result card: "Enter 3 to 7 words or phrases" |
| > 7 words | Show error: "Too many — keep it to 7 words or phrases at most" |
| No language | Show error: "Choose a generation language" |
| API timeout (30s) | Show error: "The request took too long. Try again." |
| Network error | Show error: "Server is temporarily unavailable. Try later." |
| Profanity detected | Show modal with list of flagged words |

### Server-Side (server.js)
| Scenario | Response |
|---|---|
| < 3 words | 400 with error message |
| > 7 words | 400 with error message |
| No language | 400 with error message |
| Profanity detected | 400 with `profanityWords` array |
| OpenAI API error | 500 with generic message |
| Malformed response | Retry or return fallback haiku |

### Profanity Detection
- Server-side only
- Uses OpenAI's built-in content filtering AND/OR a custom blocklist
- Returns flagged words to frontend
- Frontend shows modal with flagged words in their language

---

## 9. Security

- API key in `.env` only (never in code, chat, or repo)
- `.env` listed in `.gitignore` (already exists at repo root)
- Key loaded via `process.env.OPENAI_API_KEY` in `server.js`
- Frontend never sees the key
- Input sanitization: `escapeHtml()` for user text in DOM
- No secrets in logs

---

## 10. Project Structure

```
lesson3/haiku-50/
├── index.html       — Single-file frontend (inline <style> + <script>)
├── server.js        — Express server, routes, API calls
├── prompts.js       — Prompt constants (base, spice, safety, format)
├── .env             — OPENAI_API_KEY=sk-...
└── package.json     — express, cors, dotenv, openai
```

---

## 11. Success Criteria

1. User can enter 3–7 keywords, select language, set wasabi, and generate a haiku
2. Haiku appears as exactly 3 lines in the Bento Grid result card
3. History persists across page reloads (localStorage, max 100)
4. Profanity is detected and shown in a modal
5. Responsive layout works on desktop, tablet, mobile
6. All error states are handled (validation, timeout, network, API error)
7. API key is NOT exposed in frontend
8. Splash screen plays on load then fades
9. Empty, loading, error, done states all render correctly
10. `npm start` serves the app on localhost

---

## 12. Open Questions / Decisions for Tasks

1. **Profanity detection strategy:** OpenAI content filter vs custom blocklist? (Design: use OpenAI's built-in filtering, supplement with a small blocklist per language for the major languages)
2. **Fallback behavior:** If OpenAI returns < 3 lines, what should happen? (Design: retry once; if still fails, return a stock fallback)
3. **History migration:** Do we need backward compatibility with reference's old format? (Design: No — this is a fresh build)
4. **Port:** Which port to use? (Design: 3000, with env override via `PORT`)
5. **Rate limiting:** Should we add rate limiting? (Design: Not in initial version — add as follow-up if needed)
