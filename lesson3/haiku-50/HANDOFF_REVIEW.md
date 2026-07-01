# HANDOFF REVIEW: Haiku 50 Reference Project Audit

> **Date:** 2026-06-30
> **Source:** `https://haiku-50.onrender.com`
> **Method:** Source code extraction via HTTP (HTML `index.html`, CSS `css/style.css`, JS `js/app.js`, API probe)
> **Context:** Audit before building our own version at `lesson3/haiku-50/`
>
> **Build Status:** ✅ Our version is built — this doc remains as reference audit

---

## 1. File Structure

| File | Path | Notes |
|---|---|---|
| `index.html` | `/` | HTML shell, references external CSS/JS |
| `css/style.css` | `/css/style.css` | ~700 lines, all styling (incl. responsive, animations, modal) |
| `js/app.js` | `/js/app.js` | ~400 lines, all client logic in an IIFE |
| `bg.svg` | `/bg.svg` | ~37KB, abstract red/gray background illustration (Adobe Illustrator export) |
| `server.js` | (not publicly accessible) | Express backend (inferred from `/api/generate` POST endpoint) |
| `package.json` | (not publicly accessible) | Not served — good security practice |
| `.env` | (not accessible) | Contains API key — not exposed |

**Evidence:** HTML `<link href="css/style.css">` + `<script src="js/app.js">` confirm separate files.
API probe `POST /api/generate` returns `{"haiku":"...","fallback":false}` confirming Express-like backend.

---

## 2. UI State Machine

The frontend uses a `state.resultState` enum with **5 states:**

| State | Trigger | Render | Notes |
|---|---|---|---|
| `empty` | Initial load / after clearing | "No haiku yet" with circle + instruction | Default state |
| `loading` | Generate clicked, validation passes | Spinning ring + "Composing the lines…" | Blocks button |
| `done` | API success | 3 haiku lines + language/spice meta tags | Saves to history |
| `error` | Validation fail / API error | Red error icon + message | Client- and server-side errors |
| profanity modal | API returns `profanityWords` | Modal overlay, separate from resultState | Overrides resultState → resets to `empty` |

**Evidence:** `js/app.js` lines define `resultState` as `"empty" | "loading" | "error" | "done"`; profanity modal is a separate concern at DOM level.

**Edge case:** If API returns `result.haiku` as empty string, the code replaces it with a fallback: `["Silence", "where words should be", "a blank page"]`.

---

## 3. API Contract (Inferred)

```
POST /api/generate
Content-Type: application/json

Request:
{
  "keywords": "sakura, rain, silence",   // string, comma or newline separated
  "language": "en",                        // string, language code
  "spiciness": 0                            // number, 0-6
}

Response (200):
{
  "haiku": "Sakura petals drift\nrain traces circles on the pond\nsilence holds its breath",
  "fallback": false
}

Response (400 with profanity):
{
  "error": "Виявлено нецензурні слова",
  "profanityWords": ["word1", "word2"]
}

Response (400 validation):
{
  "error": "Введіть щонайменше 3 ключові слова або фрази"
}

Response (500):
{
  "error": "Something went wrong. Try again."
}
```

**Evidence:** Confirmed by live API test (3 keyword → successful response), and profanity/validation responses from JS error handling.

---

## 4. Languages — 12 Supported

| Code | Label | Native |
|---|---|---|
| `uk` | Ukrainian | Українська |
| `en` | English | English |
| `de` | German | Deutsch |
| `ja` | Japanese | 日本語 |
| `fr` | French | Français |
| `es` | Spanish | Español |
| `it` | Italian | Italiano |
| `pt` | Portuguese | Português |
| `pl` | Polish | Polski |
| `zh` | Chinese | 中文 |
| `ko` | Korean | 한국어 |
| `ar` | Arabic | العربية |

**Evidence:** `js/app.js` — `const LANGS = [...]`

---

## 5. Wasabi (Spiciness) Levels

| Level | Description | Visual |
|---|---|---|
| 0 | "Calm, traditional, contemplative haiku about nature and transience." | 0 dots active |
| 1 | "A light, quiet sketch with a gentle mood." | 1 dot active |
| 2 | "Slightly unexpected, with subtle irony." | 2 dots active |
| 3 | "Playful, with humor and a surprising twist." | 3 dots active |
| 4 | "Bold and sharp, with an absurd image." | 4 dots active |
| 5 | "Very spicy, chaotic, grotesque and funny." | 5 dots active |
| 6 | "Maximum heat: absurd, chaotic, surreal and dark-humored — yet still three lines of haiku." | 6 dots active, max indicator shown |

**Evidence:** `js/app.js` — `const SPICE = [...]`; 6 dots rendered, cycling button (0→1→2→3→4→5→6→0).

---

## 6. Keywords Textarea — Validation

| Condition | Error Message |
|---|---|
| 0-2 words | "Enter 3 to 7 words or short phrases" |
| 8+ words | "Too many — keep it to 7 words or phrases at most" |
| 3-7 words | Count label shows `"3 of 3–7 ✓"` to `"7 of 3–7 ✓"` |
| No language selected | "Choose a generation language" |

**Evidence:** `js/app.js` — `generate()` function checks validation before API call.
Keywords parsed by splitting on `,` or newline, trimming, filtering empty.

---

## 7. History

| Feature | Implementation |
|---|---|
| Storage | `localStorage` key `"haikuHistory"` |
| Max entries | 100 (`MAX_HISTORY = 100`) |
| UI | 2-column grid of cards, each showing lines + language + spice + time |
| Empty state | "No haiku yet" centered |
| Clear button | ✕ button, removes `localStorage` key |

**Evidence:** `js/app.js` — `STORAGE_KEY`, `loadHistory()`, history render.

---

## 8. Security Assessment

| Concern | Status | Evidence |
|---|---|---|
| API key in frontend? | ❌ **No** — key is server-side only | Frontend calls `/api/generate`, never includes API key |
| `.env` served? | ❌ **No** — not publicly accessible | `Cannot GET /.env` (verify) |
| Input sanitization | ✅ Basic — `escapeHtml()` used | JS function escapes HTML |
| Validation depth | ✅ Client + server validate | Error handling catches both sides |
| API exposed? | ✅ Only POST `/api/generate` | Single endpoint |
| Rate limiting | ❓ **Unknown** — not visible from frontend code | Not confirmed |
| CORS | ✅ Same-origin | Frontend fetches from same origin |

**Key Observation:** API key is properly server-side only. No credentials in frontend code. ✅

---

## 9. Gaps & Issues (with Evidence)

### 9.1. No Selected-Language Visual Indicator
The language menu sets `aria-selected` but the CSS only highlights options on hover. No checkmark or dot indicating selection. User must visually scan.

**Evidence:** CSS `.lang-option.is-selected` only changes background to `#eef3e9` — no visible checkmark.

### 9.2. Profanity Detection — Ukrainian-Only (Reference)
The reference's profanity modal is entirely in Ukrainian. **Our build fixes this** — uses English text ("Watch your language", "Some words you entered may not be appropriate…") plus localized error message from server.

**Reference evidence:** HTML modal: `<h2>Виявлено нецензурні слова</h2>`, `<p>Будь ласка, видаліть...</p>`.
**Our fix:** `index.html:891-893` — English modal + dynamic error string from API response.

### 9.3. External File Architecture (Not Single-File)
Reference uses 3 files: `index.html`, `css/style.css`, `js/app.js`. **Our version is single-file HTML** per project convention.

**Evidence:** HTML references `href="css/style.css"` and `src="js/app.js"`.

### 9.4. Large bg.svg (37KB)
Reference background SVG is 37KB (Adobe Illustrator export). **Our build uses CSS gradients** (`linear-gradient` + `radial-gradient`), eliminating the asset.

**Evidence:** `curl -s https://haiku-50.onrender.com/bg.svg` → 36.8KB.

### 9.5. No Fallback on API Timeout Beyond 30s
Timeout is 30s (`TIMEOUT_MS = 30000`) with `AbortController`. If request times out, error shows "The request took too long. Please try again." — no retry button.

**Evidence:** `js/app.js` — `setTimeout(() => controller.abort(), TIMEOUT_MS)`.

### 9.6. No Word Suggestions / Examples
Empty state shows "Enter your words and press 'Generate'" — no example haiku or suggested keywords.

### 9.7. Single-Column History on Mobile
History is 2-column desktop, 1-column mobile (<640px). No pagination or virtual scrolling. With 100 items, the DOM could get heavy.

**Evidence:** CSS `@media (max-width: 639px)` — `.history-list { grid-template-columns: 1fr; }`.

### 9.8. No Loading Animation Variation
Loading state is always a spinning ring with "Composing the lines…". No progress indication.

---

## 10. What Works Well

| Feature | Why |
|---|---|
| Splash screen animation | Smooth 3s animation with SVG logo + fade-out, good first impression |
| Bento Grid layout | Clean, responsive CSS Grid with 3 breakpoints |
| Wasabi cycling | Simple tap-to-cycle UX (0→6), dots show current level visually |
| Language dropdown | Accessible (`role="listbox"`, `aria-selected`) |
| History persistence | localStorage with backward compatibility |
| Profanity modal | Blocks interaction with overlay, shows offending words |
| Clean error UX | Error icon + message, not technical stack trace |
| Responsive design | 3 breakpoints, cards adapt gracefully |

---

## 11. Key Differences: Reference vs Our Build

| Aspect | Reference (haiku-50.onrender.com) | Our Build (lesson3/haiku-50/) |
|---|---|---|
| Frontend architecture | 3 files (HTML + CSS + JS) | **Single-file HTML** (inline `<style>` + `<script>`) |
| Prompt system | Mixed into server.js | **Separate `prompts.js`** |
| API endpoint | `POST /api/generate` | **POST /generate-haiku** |
| Request body | `keywords` (raw string) | **`words` (array: `string[]`)** |
| Language field | `language` | **`language`** (same) |
| Spice field | `spiciness` (0-6) | **`wasabiLevel`** (0-6) |
| Background | External `bg.svg` (37KB) | **CSS gradients only** |
| Profanity language | Ukrainian-only | **English** (generic) |
| Model | Unknown (assumed GPT) | **`gpt-5-nano-2025-08-07`** |
| Parameters | Unknown | **`reasoning_effort: low`**, `temperature: 0.8` |
| History format | Flat `{haiku, language, spiciness, keywords, timestamp}` | **`{id, haiku, langLabel, spice, timeLabel}`** |
| Splash SVG | Inline SVG | **Inline SVG** (same, adapted) |
| Fonts | Noto Sans JP + Noto Serif JP | **Same** |

---

## 12. What We Fixed vs Reference

| Issue in Reference | Our Fix |
|---|---|
| Profanity modal Ukrainian-only (9.2) | English modal + server error string |
| Large bg.svg (37KB) (9.4) | CSS gradients (0 KB overhead) |
| Mixed prompt/API logic in server.js | Separated into `prompts.js` |
| `keywords` string (harder to validate) | `words` array (type-safe) |
| Reference's history format (no `id`) | `nextId()` — Date.now + random suffix |

---

## 13. Design Decisions We Kept

| Decision | Why |
|---|---|
| Bento Grid layout | Clean, responsive, same as reference |
| Wasabi cycling 0→6 + dots | Intuitive UX, same as reference |
| 12 languages | Matches reference |
| 30s API timeout | Matches reference |
| localStorage history (max 100) | Matches reference |
| Splash screen animation | Good first impression |
| 3 breakpoints (desktop/tablet/mobile) | Same responsive strategy |

---

## Next Steps

1. ✅ ~~Phase 1: HANDOFF REVIEW~~ **(complete)**
2. ✅ ~~Phase 2: Design Spec → `2026-06-30-haiku-50-design.md`~~ **(complete)**
3. ✅ ~~Phase 3: Task Decomposition → `docs/superpowers/specs/tasks/040-046-*.md`~~ **(complete)**
4. ✅ ~~Phase 4: Implementation~~ **(complete — all tasks done)**
5. ⬜ **Phase 5: Verify & Deploy** — test all flows, push to GitHub Pages
