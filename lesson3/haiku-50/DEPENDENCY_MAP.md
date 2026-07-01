# DEPENDENCY MAP — Haiku 50

> Три зрізи: зовнішні, внутрішні, зворотні.
> Формат: **Твердження → Докази (file:line) → Впевненість (1-10)**
> Reference: `https://haiku-50.onrender.com` (multi-file) | Our build: single-file frontend + Express backend

---

## Зріз 1: Зовнішні залежності

### 1.1 NPM пакунки (runtime)

| Пакунок | Версія | Тип | Використання |
|---------|--------|-----|-------------|
| `express` | ^4.21.0 | runtime | HTTP-сервер, статика, маршрути |
| `cors` | ^2.8.5 | runtime | CORS-заголовки (dev mode) |
| `dotenv` | ^16.4.5 | runtime | Завантаження `.env` |
| `openai` | ^4.67.0 | runtime | OpenAI API клієнт (Chat Completions) |

**→ `package.json:7-14`**
**Впевненість: 10** — всі пакунки явно вказані в dependencies.

### 1.2 CDN / Зовнішні ресурси

| Ресурс | URL | Використання | Файл:рядок |
|--------|-----|-------------|-----------|
| Google Fonts: Noto Sans JP 400/500 | `fonts.googleapis.com/css2?family=Noto+Sans+JP:wght@400;500` | Body text (labels, controls, buttons, modals) | `index.html:12` |
| Google Fonts: Noto Serif JP 500/600 | `fonts.googleapis.com/css2?family=Noto+Serif+JP:wght@500;600` | Display (haiku lines, headings, splash title) | `index.html:12` |
| OpenAI API | `api.openai.com` | Haiku generation (Chat Completions) | `server.js:53-61` |

**→ статичні URL, preconnect для Google Fonts**
**Впевненість: 10**

### 1.3 Environment

| Змінна | Значення | Використання |
|--------|----------|-------------|
| `OPENAI_API_KEY` | `sk-...` (вставити вручну) | `new OpenAI({ apiKey })` — `server.js:15` |
| `PORT` | `3000` (default) | `app.listen(PORT)` — `server.js:106-107` |

**→ `.env` (шаблон), `server.js:15`, `server.js:106`**
**Впевненість: 10**

---

## Зріз 2: Внутрішні залежності

### 2.1 Module-level dependency graph

```
index.html (frontend, single file)
├── HTML structure (lines 799-896)
│   ├── Splash Screen (lines 800-811) ← CSS animation + SVG
│   ├── App Shell (lines 813-883)
│   │   ├── Header (lines 816-819)
│   │   └── Bento Grid (lines 822-883)
│   │       ├── Result Card     ← всі 4 стани render*()
│   │       ├── Keywords Card   ← renderKeywords()
│   │       ├── Language Card   ← renderLanguage()
│   │       ├── Wasabi Card     ← renderWasabi()
│   │       ├── History Card    ← renderHistory()
│   │       └── Info Card       ← Generate button
│   └── Profanity Modal (lines 886-896) ← showProfanityModal()
│
├── CSS <style> (lines 14-796)
│   ├── Design Tokens (lines 15-31) ← :root — використовуються ВСІМА
│   ├── Splash (lines 50-77) ← @keyframes
│   ├── Bento Grid (lines 114-125) ← grid-template-areas
│   ├── Card States (lines 147-260) ← empty/loading/error/done
│   ├── Language Dropdown (lines 318-397)
│   ├── Wasabi Dots (lines 399-483)
│   ├── History Grid (lines 485-568)
│   ├── Modal (lines 621-729)
│   ├── Responsive (lines 731-778) ← 3 breakpoints
│   └── Reduced Motion (lines 780-796)
│
└── JS <script> (lines 898-1386)
    ├── DOM Elements binding (lines 901-923) ← els.*
    ├── Constants (lines 925-941) ← LANGS[12], SPICE_LABELS[7]
    ├── State (lines 943-955) ← state object — центральний контракт
    ├── Helpers (lines 957-978) ← phrases(), labelOf(), timeLabel(), nextId()
    ├── RENDER FUNCTIONS (lines 980-1122)
    │   ├── renderResult()          ← state.resultState ⇒ dispatch
    │   │   ├── renderEmpty()       ← state: empty
    │   │   ├── renderLoading()     ← state: loading
    │   │   ├── renderError()       ← state.errorMsg
    │   │   └── renderDone()        ← state.lines, state.doneLang, state.doneSpice
    │   ├── renderKeywords()        ← state.keywords
    │   ├── renderLanguage()        ← state.lang, state.langOpen
    │   ├── renderWasabi()          ← state.spice
    │   ├── renderHistory()         ← state.history[]
    │   └── renderGenerateButton()  ← state.keywords, state.lang, state.resultState
    ├── History (lines 1132-1155)  ← localStorage
    │   ├── loadHistory()           ← на старті
    │   └── saveHistory()           ← після генерації
    ├── Profanity Modal (lines 1157-1172) ← show/hide
    ├── API Client (lines 1174-1205) → POST /generate-haiku
    │   └── generateHaiku()         ← fetch + AbortController (30s)
    ├── Main Handler (lines 1207-1281)
    │   └── generate()              ← validate → API → render → save history
    └── Event Binding (lines 1283-1376)
        └── bindEvents()            ← всі listeners


server.js (109 lines)
├── validateRequest()              ← words[3-7], language, wasabiLevel[0-6]
├── POST /generate-haiku           ← основний маршрут
│   ├── require('./prompts')       ← buildPrompt(), normalizeHaiku()
│   ├── openai.chat.completions.create()  ← API call
│   ├── normalizeHaiku(raw)        ← нормалізація відповіді
│   ├── RETRY (якщо < 3 lines)    ← повторний API call
│   └── FALLBACK (якщо retry fail) ← stock haiku
└── app.listen(PORT)              ← порт 3000


prompts.js (56 lines)
├── SPICE_DESCRIPTIONS[7]          ← описи рівнів "spiciness"
├── buildPrompt()                  ← base + spice + safety
└── normalizeHaiku()               ← 5-step normalization pipeline
```

### 2.2 Залежності між файлами

| Від | До | Тип залежності | Файл:рядок |
|-----|----|----------------|-----------|
| `index.html` (JS) | `server.js` | HTTP POST `/generate-haiku` | `index.html:1180-1184` |
| `server.js` | `prompts.js` | CommonJS `require('./prompts')` | `server.js:6` |
| `server.js` | `openai` | HTTP POST `api.openai.com` | `server.js:53-61` |
| `index.html` (CSS) | `fonts.googleapis.com` | Google Fonts `@import` | `index.html:12` |

**Впевненість: 10**

### 2.3 State-залежності (index.html JS)

**`state` object (line 944-955)** — центральний контракт всього frontend:

| Поле state | Тип | Скільки функцій читають | Хто саме |
|-----------|-----|------------------------|----------|
| `keywords` | `string` | 6 | `renderKeywords()`, `renderGenerateButton()`, `phrases()`, `generate()`, `input handler`, `clear handler` |
| `lang` | `string` | 4 | `renderLanguage()`, `renderGenerateButton()`, `generate()`, `labelOf()` |
| `spice` | `number` (0-6) | 3 | `renderWasabi()`, `renderGenerateButton()`, `generate()` |
| `resultState` | `string` | 5 | `renderResult()`, `renderGenerateButton()`, `generate()`, `showProfanityModal()`, API handlers |
| `errorMsg` | `string` | 2 | `renderError()`, `generate()` |
| `lines` | `string[]` | 2 | `renderDone()`, `generate()` |
| `doneLang` | `string` | 1 | `renderDone()` |
| `doneSpice` | `string` | 1 | `renderDone()` |
| `history` | `object[]` | 3 | `renderHistory()`, `generate()`, `loadHistory()` |
| `langOpen` | `boolean` | 1 | `renderLanguage()` |

**→ `index.html:944-955`**
**Впевненість: 10** — центральний контракт UI.

---

## Зріз 3: Зворотні залежності (Reverse)

> **Хто впаде при зміні X**

### 3.1 Зміна API контракту (server.js) — 🔴 КРИТИЧНО

| Поле | Скільки модулів | Хто |
|------|----------------|-----|
| `words[]` → `words: string[]` | 3 | `validateRequest()`, `buildPrompt()`, `generateHaiku()` (frontend fetch body) |
| `language` → `string` | 3 | `validateRequest()`, `buildPrompt()`, `generateHaiku()` |
| `wasabiLevel` → `number 0-6` | 3 | `validateRequest()`, `buildPrompt()`, `generateHaiku()` |
| Response `haiku` → `string` | 2 | `normalizeHaiku()`, `generate()` (frontend) |
| Response `fallback` → `boolean` | 2 | server retry logic, `generate()` (frontend — skip history) |
| Response `profanityWords` → `string[]` | 2 | server content filter, `showProfanityModal()` (frontend) |

**Впевненість: 10** — API contract is the single source of truth.

### 3.2 Зміна `state` структури (index.html JS) — 🟡 СЕРЕДНЬО

| Поле | Скільки функцій | Хто саме |
|------|----------------|---------|
| `keywords` | 6 | renderKeywords, renderGenerateButton, phrases, generate, input/clear handlers |
| `lang` | 4 | renderLanguage, renderGenerateButton, generate, labelOf |
| `spice` | 3 | renderWasabi, renderGenerateButton, generate |
| `resultState` | 5 | renderResult, renderGenerateButton, generate, showProfanityModal, API handlers |
| `history` | 3 | renderHistory, generate (push), loadHistory |

**Впевненість: 10**

### 3.3 Зміна HTML ID — 🟡 СЕРЕДНЬО

| DOM ID | Хто використовує в JS |
|--------|----------------------|
| `result-card` | `els.resultCard` → `renderEmpty/Loading/Error/Done()` |
| `keywords-input` | `els.keywords` → input events, value |
| `word-count` | `els.wordCount` → `textContent` |
| `btn-clear` | `els.btnClear` → click, disabled |
| `lang-selector`, `lang-selected`, `lang-menu` | `els.*` → dropdown toggle |
| `wasabi-dots` | `els.wasabiDots` → click delegation |
| `heat-level` | `els.heatLevel` → textContent |
| `spice-max` | `els.spiceMax` → class toggle |
| `history-list`, `history-empty` | `els.*` → render |
| `btn-history-clear` | `els.btnClearHist` → click |
| `btn-generate` | `els.btnGenerate` → click, disabled, text |
| `profanity-modal` | `els.profanityModal` → class toggle |
| `modal-words` | `els.modalWords` → innerHTML |
| `modal-close`, `modal-btn` | click → hide |

**→ HTML (lines 799-896), JS (lines 901-923)**
**Впевненість: 10**

### 3.4 Зміна `prompts.js` — 🟢 НИЗЬКИЙ

| Експорт | Хто залежить |
|---------|-------------|
| `buildPrompt()` | `server.js:50` — виклик перед OpenAI API |
| `normalizeHaiku()` | `server.js:65,80` — нормалізація відповіді |
| `SPICE_DESCRIPTIONS` | `buildPrompt()` — включення spice level в prompt |

**Впевненість: 10**

---

## Підсумок: Найчастіше посиланні файли

| Ранг | Файл | Скільки інших залежить | Наслідки змін |
|------|------|------------------------|--------------|
| 1 | `index.html` (JS) | Весь UI + API client + localStorage | Зміна state = зміна ~15 функцій |
| 2 | `server.js` | Frontend (HTTP), prompts.js (require), OpenAI API | Зміна API contract = зміна frontend + prompts |
| 3 | `prompts.js` | server.js (require) | Зміна normalizeHaiku = зміна формату відповіді |
| 4 | `index.html` (CSS) | DOM структура | Зміна CSS class = зміна JS рендеру |

---

## Граф залежностей (ASCII)

```
┌────────────────────────────────────────────────────────────┐
│                    Browser (index.html)                     │
│                                                             │
│  JS State (state object) ──► renderResult()                 │
│       │                        ├─ renderEmpty()             │
│       │                        ├─ renderLoading()           │
│       │                        ├─ renderError()             │
│       │                        └─ renderDone()              │
│       ├── renderKeywords() ───► DOM (#keywords-input)       │
│       ├── renderLanguage() ──► DOM (#lang-menu)             │
│       ├── renderWasabi() ────► DOM (#wasabi-dots)           │
│       ├── renderHistory() ───► DOM (#history-list)          │
│       └── renderGenerateButton() ──► DOM (#btn-generate)    │
│                                                             │
│  generate() ───► generateHaiku() ──── POST /generate-haiku  │
│       │                                    │                │
│       └── saveHistory() ──► localStorage   │                │
│                                             │                │
└─────────────────────────────────────────────┼────────────────┘
                                              │ HTTPS
┌─────────────────────────────────────────────┼────────────────┐
│                     server.js                │                │
│  validateRequest() ◄─────────────────────────┘                │
│       │                                                     │
│       ▼                                                     │
│  buildPrompt() ──► prompts.js                                │
│       │          (SPICE_DESCRIPTIONS + base prompt)          │
│       ▼                                                     │
│  openai.chat.completions.create() ──── HTTPS ───► OpenAI API │
│       │                                                     │
│       ▼                                                     │
│  normalizeHaiku() ──► prompts.js                             │
│       │          (strip markdown + split + trim)             │
│       ▼                                                     │
│  response: { haiku, fallback } ────► Browser                 │
└─────────────────────────────────────────────────────────────┘
```
