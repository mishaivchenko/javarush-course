# RUNTIME FLOW — Haiku 50 Full Request Cycle

> **Формат:** Твердження → Докази (file:line) → Впевненість (1-10)
> **Стек:** Node.js (Express) + OpenAI API + single-file frontend (inline CSS/JS)

---

## Flow A: Splash → App Load

### Вхід: Відкриття `http://localhost:3000`

```
1. Browser GET /
   ├─ server.js:13 — express.static(__dirname) повертає index.html
   │
   └─ Index.html завантажується:
       ├─ CSS <style> — одразу всі стилі (token, grid, cards, modal, responsive, reduced-motion)
       │  Доказ: index.html:14-796
       │
       ├─ Google Fonts preconnect + stylesheet
       │  Доказ: index.html:9-12
       │
       ├─ Splash Screen <div id="splash"> — видимий одразу
       │  │  Доказ: index.html:800-811
       │  ├─ CSS animation: @keyframes h50splash — 3s, opacity 1→0
       │  │  Доказ: index.html:69-72
       │  └─ SVG logo з @keyframes h50splashLogo — scale(0.85→1), fade in
       │     Доказ: index.html:74-76
       │
       ├─ App Shell <div id="app"> — прихована до кінця splash
       │  │  Доказ: index.html:814 (animation-delay: 2.8s)
       │  └─ @keyframes h50up — translateY(12px→0), fade in
       │     Доказ: index.html:616-618
       │
       └─ <script> — IIFE, одразу після DOM
          │  Доказ: index.html:898-1385
          │
          ├─ bindElements() — els.* = document.getElementById(ID)
          │  Доказ: index.html:904-923
          │
          ├─ loadHistory() — localStorage.getItem('haikuHistory')
          │  │  Доказ: index.html:1134-1143
          │  ├─ Якщо ключ відсутній → state.history = []
          │  ├─ Якщо JSON.parse падає → state.history = []
          │  └─ Якщо parsed — не масив → state.history = []
          │
          ├─ bindEvents() — всі event listeners
          │  │  Доказ: index.html:1285-1376
          │  ├─ keywords input / clear → renderKeywords()
          │  ├─ lang-selector click → toggle dropdown
          │  ├─ lang-menu click → select language via delegation
          │  ├─ document click → close lang dropdown
          │  ├─ wasabi-dots click → cycle spice level via delegation
          │  ├─ btn-generate click → generate()
          │  ├─ keywords keydown — Enter triggers generate()
          │  ├─ modal close buttons / backdrop / Escape → hideProfanityModal()
          │  └─ btn-history-clear click → wipe history
          │
          └─ render() — фінальний рендер з порожнім станом
             │  Доказ: index.html:1383
             ├─ renderResult() → EMPTY state
             ├─ renderKeywords() → "0 / 3–7", Clear disabled
             ├─ renderLanguage() → "Choose language", menu closed
             ├─ renderWasabi() → 0 dots active, label "Calm", max hidden
             ├─ renderHistory() → "No haiku yet", Clear all disabled
             └─ renderGenerateButton() → disabled (no words, no lang)
```

**Впевненість: 10** — весь init шлях прочитано.

### Гілки помилок при завантаженні

| Ситуація | Де | Реакція |
|----------|-----|---------|
| Google Fonts не завантажились | `<link>` | Fallback: `sans-serif` / `serif` |
| localStorage недоступний | `loadHistory()` | `catch(e)` → `state.history = []` |
| `localStorage.setItem` падає (full) | `saveHistory()` | `catch(e)` → silent fail |
| `getElementById` → null | `bindElements()` | `els.*` = null — зламані listener'и |

---

## Flow B: Generate Haiku (основний шлях)

### Вхід: клік "Generate" або Enter в textarea

```
1. generate()
   │  Доказ: index.html:1209-1281
   │
   ├─ Guard: if state.resultState === 'loading' → return (double-submit захист)
   │  Доказ: index.html:1211
   │
   ├─ words = phrases(state.keywords) — split by comma/newline, trim, filter empty
   │  Доказ: index.html:1213
   │
   ├─ CLIENT VALIDATION:
   │  ├─ if words.length < 3 → error: "Enter 3 to 7 words or short phrases"
   │  ├─ if words.length > 7 → error: "Too many — keep it to 7 words or phrases at most"
   │  └─ if !state.lang → error: "Choose a generation language"
   │  │  Доказ: index.html:1217-1231
   │  ├─ Встановлює state.resultState = 'error'
   │  ├─ Встановлює state.errorMsg
   │  └─ render() → показує error state в result card
   │
   ├─ SET LOADING:
   │  ├─ state.resultState = 'loading'
   │  ├─ state.lines = []
   │  ├─ state.errorMsg = ''
   │  └─ render() → спіннер + "Composing the lines…"
   │  Доказ: index.html:1234-1237
   │
   └─ generateHaiku(words, state.lang, state.spice) → Promise
      │  Доказ: index.html:1239
      │
      └─ 2. generateHaiku() — API call
         │  Доказ: index.html:1176-1205
         │
         ├─ AbortController + 30s timeout
         │  Доказ: index.html:1177-1178
         │
         ├─ fetch POST /generate-haiku
         │  ├─ headers: Content-Type: application/json
         │  ├─ body: { words: string[], language: string, wasabiLevel: number }
         │  └─ signal: controller.signal
         │  Доказ: index.html:1180-1184
         │
         ├─ response.ok === true → parse JSON → return data
         │  Доказ: index.html:1187-1194
         │
         ├─ response.ok === false → parse JSON → throw Error(data.error)
         │  │  Якщо data.profanityWords — додати до error.profanityWords
         │  └─ Доказ: index.html:1188-1193
         │
         └─ catch:
            ├─ AbortError → throw Error("The request took too long…")
            ├─ Failed to fetch → throw Error("Server is temporarily unavailable…")
            └─ інші → throw err (прокидується далі)
            Доказ: index.html:1195-1204
```

### 3. server.js — POST /generate-haiku

```
   POST /generate-haiku
   │  Доказ: server.js:43-104
   │
   ├─ validateRequest(req.body)
   │  │  Доказ: server.js:22-41
   │  ├─ words: Array.isArray && length 3-7 && all non-empty
   │  ├─ language: in ALLOWED_LANGUAGES (12 codes)
   │  └─ wasabiLevel: number 0-6
   │  ├─ if !valid → return 400 { error: validation.error }
   │
   ├─ Valid → extract { words, language, wasabiLevel }
   │
   ├─ buildPrompt(words, language, wasabiLevel)
   │  │  Доказ: server.js:50
   │  └─ prompts.js:
   │     │  Доказ: prompts.js:11-28
   │     ├─ SPICE_DESCRIPTIONS[wasabiLevel] — "Calm…" / "Insane…"
   │     └─ Returns: multiline string with base prompt + spice + safety
   │
   ├─ openai.chat.completions.create({...})
   │  │  Доказ: server.js:53-61
   │  ├─ model: 'gpt-5-nano-2025-08-07'
   │  ├─ messages: [system + user (prompt)]
   │  ├─ reasoning_effort: 'low'
   │  ├─ max_tokens: 150
   │  └─ temperature: 0.8
   │
   ├─ normalizeHaiku(raw)
   │  │  Доказ: server.js:65
   │  └─ prompts.js:normalizeHaiku()
   │     │  Доказ: prompts.js:30-53
   │     ├─ 1. Strip markdown code blocks (``` / """)
   │     ├─ 2. Strip intro text ("Here is", "Sure", etc.)
   │     ├─ 3. Split by \n, trim, filter empty
   │     ├─ 4. Keep first 3 lines
   │     └─ 5. Pad to 3 if needed (push '')
   │
   ├─ if lines < 3 → RETRY (один раз)
   │  │  Доказ: server.js:68-81
   │  ├─ Повторний API call з тим же prompt + "IMPORTANT: 3 lines"
   │  ├─ Temperature: 0.7 (lower = менше хаосу)
   │  └─ normalizeHaiku(retryRaw)
   │
   ├─ if still < 3 → FALLBACK
   │  │  Доказ: server.js:84-87
   │  ├─ haiku = "Silence\nwhere words should be\na blank page"
   │  └─ return 200: { haiku, fallback: true }
   │
   └─ if OK → return 200: { haiku, fallback: false }
      Доказ: server.js:89
```

### 4. Response handling (frontend)

```
   generateHaiku().then(function(data))
   │  Доказ: index.html:1239-1266
   │
   ├─ lines = data.haiku.split('\n').filter(Boolean).slice(0, 3)
   │
   ├─ if lines.length === 0 → fallback lines: ["Silence", "where words should be", "a blank page"]
   │
   ├─ state.lines = lines
   ├─ state.doneLang = labelOf(state.lang)
   ├─ state.doneSpice = SPICE_LABELS[state.spice]
   ├─ state.resultState = 'done'
   │
   ├─ if (!data.fallback) — зберігаємо в історію
   │  ├─ entry = { id: nextId(), haiku, langLabel, spice, timeLabel }
   │  ├─ state.history.push(entry)
   │  └─ saveHistory() → localStorage
   │  Доказ: index.html:1254-1264
   │
   └─ render() — оновлює всі секції
      ├─ renderResult() → DONE state — haiku lines + language/spice tags + pop-in animation
      ├─ renderHistory() → новий entry на початку списку
      └─ renderGenerateButton() → re-enable
```

### 5. Error handling (frontend)

```
   .catch(function(err))
   │  Доказ: index.html:1268-1280
   │
   ├─ if err.profanityWords && err.profanityWords.length > 0:
   │  ├─ state.resultState = 'empty'
   │  ├─ render()
   │  └─ showProfanityModal(err.profanityWords)
   │  │  Доказ: index.html:1270-1274
   │  └─ Modal: backdrop click / ✕ / Escape → hideProfanityModal()
   │
   └─ інакше:
      ├─ state.resultState = 'error'
      ├─ state.errorMsg = err.message || 'Something went wrong…'
      └─ render() → error state з icon + message
```

**Гілки помилок:**

| Ситуація | Де | Реакція |
|----------|-----|---------|
| < 3 words (client) | `generate()` | error state: "Enter 3 to 7 words" |
| > 7 words (client) | `generate()` | error state: "Too many…" |
| No language (client) | `generate()` | error state: "Choose a language" |
| < 3 words (server) | `validateRequest()` | 400: error message |
| Invalid language (server) | `validateRequest()` | 400: "Please select a valid language" |
| Invalid wasabi (server) | `validateRequest()` | 400: "Wasabi level must be 0–6" |
| Profanity detected (server) | content_filter error | 400: `{error, profanityWords}` → modal |
| OpenAI API error (server) | API call | 500: generic error |
| Malformed response (server) | `normalizeHaiku()` → < 3 lines | Retry → Fallback |
| API timeout 30s (client) | AbortController | error: "The request took too long…" |
| Network offline (client) | fetch fails | error: "Server is temporarily unavailable…" |
| Double-submit (client) | guard `state.resultState === 'loading'` | Silent return |

---

## Flow C: Wasabi Cycling

### Вхід: клік по dot у Wasabi Card

```
1. wasabi-dots click delegation
   │  Доказ: index.html:1327-1335
   │
   ├─ e.target.closest('.dot') — знайти клікнутий dot
   ├─ level = parseInt(dot.dataset.level, 10)  // 1-6
   ├─ state.spice = (state.spice === level) ? 0 : level
   │  // Tap same level = reset to 0
   │
   ├─ renderWasabi()
   │  │  Доказ: index.html:1068-1077
   │  ├─ Оновлює .dot.active класи (0-6)
   │  ├─ Оновлює .heatLevel текст (SPICE_LABELS[state.spice])
   │  └─ Показує/ховає .spice-max індикатор (level 6)
   │
   └─ renderGenerateButton() — перевіряє чи можна active
      (Wasabi не впливає на disabled/enabled generate)
```

**Впевненість: 10**

---

## Flow D: Language Selection

### Вхід: клік по "Choose language" або "▾"

```
1. lang-selector click → toggle langOpen
   │  Доказ: index.html:1303-1306
   │
   ├─ state.langOpen = !state.langOpen
   └─ renderLanguage()
      ├─ Оновлює .lang-menu (open/closed)
      └─ Оновлює .lang-selector .chevron (rotate 180°)
```

### Вхід: клік по мові в меню

```
2. lang-menu click delegation
   │  Доказ: index.html:1310-1316
   │
   ├─ e.target.closest('.lang-option') → data-code
   ├─ state.lang = data-code
   ├─ state.langOpen = false
   └─ render()
      ├─ renderResult() — не змінюється (EMPTY)
      ├─ renderKeywords() — не змінюється
      ├─ renderLanguage() — оновлює selected стиль + "Choose language" → label
      ├─ renderWasabi() — не змінюється
      ├─ renderHistory() — не змінюється
      └─ renderGenerateButton() — re-check: чи можна тепер active?
```

### Вхід: клік поза меню

```
3. document click → close dropdown
   │  Доказ: index.html:1319-1324
   │
   ├─ if state.langOpen === true → false + renderLanguage()
```

**Впевненість: 10**

---

## Flow E: History (localStorage)

### Запис (після успішної генерації)

```
1. generate() — після API success
   │
   ├─ entry = {
   │    id: nextId(),           // Date.now(36) + random(36)
   │    haiku: data.haiku,      // оригінальний текст
   │    langLabel: labelOf(lang),
   │    spice: SPICE_LABELS[spice],
   │    timeLabel: HH:MM        // локальний час
   │  }
   ├─ state.history.push(entry)
   │
   └─ saveHistory()
      │  Доказ: index.html:1145-1155
      ├─ if state.history.length > 100 → state.history = state.history.slice(-100)
      ├─ localStorage.setItem('haikuHistory', JSON.stringify(state.history))
      └─ catch(e) → silent fail (full storage)
```

### Відновлення (при завантаженні сторінки)

```
2. loadHistory()
   │  Доказ: index.html:1134-1143
   │
   ├─ localStorage.getItem('haikuHistory')
   ├─ null → state.history = []
   ├─ JSON.parse → if Array → state.history = parsed
   └─ catch → state.history = []
```

### Очищення

```
3. btn-history-clear click
   │  Доказ: index.html:1371-1376
   │
   ├─ state.history = []
   ├─ saveHistory()
   ├─ renderHistory()
   └─ renderGenerateButton()
```

**Впевненість: 10**

---

## Підсумок: Ключові точки відмови

| Точка | Тип | Наслідок |
|-------|-----|----------|
| `state.resultState === 'loading'` | Guard | Double-submit захист |
| `AbortController` (30s) | Timeout | "The request took too long" |
| `validateRequest()` | Server validation | 400 помилка, не йде до OpenAI |
| `content_filter` error | OpenAI safety | Profanity modal |
| `normalizeHaiku()` → < 3 lines | Response quality | Retry → Fallback |
| `localStorage.setItem` full | Storage | Silent fail (history не зберігається) |
| `fetch` network error | Connection | "Server is temporarily unavailable" |

## Примітки до швидкості

| Етап | Типова тривалість | Залежить від |
|------|------------------|-------------|
| Splash animation | 3s | CSS (завжди фіксовано) |
| OpenAI API call | 2-8s | Модель, розмір prompt, серверне навантаження |
| History render | < 10ms | Кількість записів (max 100) |
| Responsive reflow | < 50ms | CSS Grid (без JS re-render) |

## Security Flow

```
Browser              server.js             prompts.js        OpenAI API
  │                     │                      │                │
  │  POST /generate    │                      │                │
  │  { words, lang,   │──► validateRequest()  │                │
  │    wasabiLevel }   │     (source of truth) │                │
  │                    │         │             │                │
  │  ← 400 error       │◄────────┘ (invalid)   │                │
  │                    │                       │                │
  │                    │──► buildPrompt() ────►│                │
  │                    │     words, lang,      │                │
  │                    │     wasabiLevel       │─ SPICE_DESCR. ─┤
  │                    │                       │                │
  │                    │──► openai.chat.       │                │
  │                    │     completions       │                │
  │                    │     .create(prompt)   │── HTTPS ──────►│
  │                    │                       │                │
  │                    │◄── raw response ──────│◄───────────────┤
  │                    │                       │                │
  │                    │──► normalizeHaiku() ─►│                │
  │                    │     strip → split     │                │
  │                    │     → trim → 3 lines  │                │
  │                    │                       │                │
  │                    ├── < 3 lines? → RETRY ─┤──► OpenAI API  │
  │                    │                       │                │
  │                    ├── still < 3? → FALLBACK               │
  │                    │                       │                │
  │  ← { haiku,       │◄── response            │                │
  │      fallback }   │                       │                │
```

**Ключове:** API key ніколи не потрапляє в frontend. Frontend бачить тільки `/generate-haiku`. Вся логіка prompt + normalisation — на сервері в `prompts.js`.
