# API MAP — Internal Function Interfaces

> Haiku 50 — Express + OpenAI + single-file frontend
> **HTTP endpoints:** 1 (POST `/generate-haiku`)
> **Internal modules:** 3 (index.html, server.js, prompts.js)

---

## Зріз 1: HTTP API (Server → Client Contract)

### `POST /generate-haiku`

**Ендпоінт:** `http://localhost:3000/generate-haiku` (або production URL)
**Content-Type:** `application/json`

#### Request Body

| Поле | Тип | Валідація | Опис |
|------|-----|-----------|------|
| `words` | `string[]` | 3–7 items, non-empty after trim | Ключові слова для хайку |
| `language` | `string` | Один з 12 кодів | Мова генерації |
| `wasabiLevel` | `number` | 0–6 | Рівень "spiciness" |

**→ `server.js:22-41`**
**Впевненість: 10**

#### Success Response (200)

```json
{
  "haiku": "Sakura petals drift\nrain traces circles on the pond\nsilence holds its breath",
  "fallback": false
}
```

| Поле | Тип | Опис |
|------|-----|------|
| `haiku` | `string` | 3 рядки, розділені `\n` |
| `fallback` | `boolean` | `true` = OpenAI не зміг згенерувати, використано stock fallback |

**→ `server.js:89`**
**Впевненість: 10**

#### Error Response (400 — Validation)

```json
{
  "error": "Enter 3 to 7 words or short phrases"
}
```

| Сценарій | `error` |
|----------|---------|
| words < 3 | "Enter 3 to 7 words or short phrases" |
| words > 7 | "Enter 3 to 7 words or short phrases" |
| empty word in array | "All words must be non-empty" |
| invalid language | "Please select a valid language" |
| wasabiLevel not 0-6 | "Wasabi level must be 0-6" |

**→ `server.js:24-40`**
**Впевненість: 10**

#### Error Response (400 — Profanity)

```json
{
  "error": "Your input contains prohibited content. Please remove offensive words.",
  "profanityWords": ["word1", "word2"]
}
```

| Поле | Тип | Опис |
|------|-----|------|
| `error` | `string` | Статичне повідомлення |
| `profanityWords` | `string[]` | Список слів, що тригернули фільтр |

**→ `server.js:95-99`**
**Впевненість: 10**

#### Error Response (500 — Server Error)

```json
{
  "error": "Something went wrong. Try again."
}
```

**→ `server.js:102`**
**Впевненість: 10**

---

## Зріз 2: Frontend Render API (index.html)

### Архітектура — State-driven Rendering

```
state.resultState ──► renderResult() ──► dispatch
                     │   ├─ "empty"   → renderEmpty()
                     │   ├─ "loading" → renderLoading()
                     │   ├─ "error"   → renderError()
                     │   └─ "done"    → renderDone()
                     │
render()             ├─ renderKeywords()
(викликає всі)       ├─ renderLanguage()
                     ├─ renderWasabi()
                     ├─ renderHistory()
                     └─ renderGenerateButton()
```

**→ `index.html:1115-1122`**
**Впевненість: 10**

### `renderEmpty()` — Initial State

```
Використання: state.resultState === 'empty'
Що робить:
  - Встановлює className 'card result-empty' на #result-card
  - Замінює innerHTML на:
    <div class="result-ring">◌</div>
    <div class="result-label">No haiku yet</div>
    <div class="result-hint">Enter 3–7 words and press Generate</div>

→ index.html:983-989
```

### `renderLoading()` — Loading State

```
Використання: state.resultState === 'loading'
Що робить:
  - Встановлює className 'card result-loading'
  - innerHTML:
    <div class="result-spinner"></div>
    <div class="result-label">Composing the lines…</div>

→ index.html:991-996
```

### `renderError()` — Error State

```
Використання: state.resultState === 'error'
Що робить:
  - Встановлює className 'card result-error'
  - innerHTML: icon "!" + escapeHtml(state.errorMsg)

Параметри:
  state.errorMsg: string (dynamic, from validation or API)

→ index.html:998-1003
```

### `renderDone()` — Success State

```
Використання: state.resultState === 'done'
Що робить:
  - Встановлює className 'card result-done'
  - Рендерить 3 рядки хайку (з <br> між рядками)
  - Під хайку: meta-теги (мова + spice level)

Параметри:
  state.lines: string[] (3 елементи)
  state.doneLang: string (назва мови, e.g. "English")
  state.doneSpice: string (назва spice, e.g. "Calm")

→ index.html:1005-1021
```

### `renderKeywords()` — Keywords Section

```
Що робить:
  - Рахує кількість слів (phrases(state.keywords))
  - Оновлює #word-count: "0 / 3–7" або "5 / 3–7"
  - Додає клас 'warn' якщо > 7 слів
  - Disables/enables #btn-clear

Параметри:
  state.keywords: string (raw value з textarea)

Залежить від: phrases() helper (split by comma/newline, trim, filter empty)
→ index.html:1032-1043
```

### `renderLanguage()` — Language Dropdown

```
Що робить:
  - Будує .lang-menu HTML (12 option buttons з class 'selected' для поточної)
  - Оновлює #lang-selected текст (назва мови або "Choose language")
  - Toggle .open class на .lang-menu та .lang-selector

Параметри:
  state.lang: string (code, e.g. "en", "ja") або ''
  state.langOpen: boolean (dropdown open/closed)

→ index.html:1045-1065
```

### `renderWasabi()` — Spiciness Dots

```
Що робить:
  - Рендерить 6 dot-кнопок (data-level 1-6)
  - Ставить .active клас на перші N dots
  - Оновлює #heat-level текст (SPICE_LABELS[state.spice])
  - Показує/ховає .spice-max індикатор

Параметри:
  state.spice: number (0-6)

Залежить від: SPICE_LABELS (index.html:941)
→ index.html:1068-1077
```

### `renderHistory()` — History List

```
Що робить:
  - Якщо history порожня → показує #history-empty, ховає #history-list
  - Якщо є записи → ховає empty, показує list
  - Рендерить .history-item для кожного entry (в зворотньому порядку)
  - Disables/enables #btn-history-clear

Параметри:
  state.history: Array<{id, haiku, langLabel, spice, timeLabel}>

→ index.html:1079-1103
```

### `renderGenerateButton()` — Generate Button

```
Що робить:
  - Перевіряє чи можна генерувати:
    canGenerate = words.length >= 3 && <= 7 && !!lang && state.resultState !== 'loading'
  - Disables/enables #btn-generate
  - Текст: "Generating…" (loading) або "Generate"

Параметри:
  state.keywords, state.lang, state.resultState

→ index.html:1105-1113
```

### `render()` — Master Render

```
Викликає всі 6 render-функцій послідовно:
  renderResult() → renderKeywords() → renderLanguage() → renderWasabi() → renderHistory() → renderGenerateButton()

→ index.html:1115-1122
```

---

## Зріз 3: API Client (index.html → server)

### `generateHaiku(words, language, wasabiLevel)` → Promise

```
Параметри:
  words: string[] (вже відфільтровані, 3-7)
  language: string (code)
  wasabiLevel: number (0-6)

Повертає: Promise → { haiku: string, fallback: boolean }

Логіка:
  1. Створює AbortController + 30s timeout
  2. fetch POST /generate-haiku з JSON body
  3. response.ok → response.json()
  4. !response.ok → response.json() → throw Error(data.error)
     - Якщо data.profanityWords → додає до error.profanityWords
  5. Помилки:
     - AbortError → "The request took too long. Try again."
     - Failed to fetch → "Server is temporarily unavailable. Try later."
     - Інші прокидує далі

→ index.html:1176-1205
```

### `generate()` — Main Handler (controller)

```
Параметри: немає (читає state + DOM)
Викликається: клік Generate / Enter в textarea

Логіка:
  1. Guard: if loading → return (double-submit)
  2. words = phrases(state.keywords)
  3. Client validation (3-7, language)
  4. state.resultState = 'loading', render()
  5. generateHaiku(words, state.lang, state.spice)
     ├─ success → state.lines = lines, state.resultState = 'done'
     │            save to history (if !fallback), render()
     └─ error →
         ├─ profanity → state.resultState = 'empty', render(), showProfanityModal()
         └─ other → state.resultState = 'error', render()

→ index.html:1209-1281
```

---

## Зріз 4: History (localStorage)

### `loadHistory()` → void

```
Зчитує localStorage key 'haikuHistory':
  - null → state.history = []
  - JSON.parse(valid array) → state.history = parsed
  - catch(e) → state.history = []

→ index.html:1134-1143
```

### `saveHistory()` → void

```
1. if state.history.length > 100 → .slice(-100)
2. localStorage.setItem('haikuHistory', JSON.stringify(state.history))
3. catch(e) → silent fail (full storage / disabled)

→ index.html:1145-1155
```

### Entry Format

```json
{
  "id": "a1b2c3d4e5",
  "haiku": "Sakura petals drift\nrain...",
  "langLabel": "English",
  "spice": "Calm",
  "timeLabel": "14:30"
}
```

| Поле | Тип | Генерація |
|------|-----|-----------|
| `id` | `string` | `nextId()` = Date.now(36) + Math.random(36).slice(2,6) |
| `haiku` | `string` | Оригінальний API response (3 lines, \n separated) |
| `langLabel` | `string` | `labelOf(state.lang)` |
| `spice` | `string` | `SPICE_LABELS[state.spice]` |
| `timeLabel` | `string` | `HH:MM` (локальний час) |

**→ `index.html:1255-1261`**
**Впевненість: 10**

---

## Зріз 5: Prompts API (server.js → prompts.js)

### `buildPrompt(words, language, wasabiLevel)` → string

```
Параметри:
  words: string[] (3-7 ключових слів)
  language: string (code, e.g. "en")
  wasabiLevel: number (0-6)

Повертає: string (повний prompt для OpenAI)

Структура prompt:
  "You are a haiku master. Write a haiku in {language} using these words: {words}.

  Requirements:
  - Exactly 3 lines, each line is one phrase
  - Use the given words to set the imagery
  - The haiku must feel poetic, not literal
  - Do not explain, translate, or add preamble
  - Output ONLY the 3 lines, separated by newlines

  {SPICE_DESCRIPTIONS[wasabiLevel]}

  - No profanity, aggression, or prohibited content
  - Keep it safe for general audience"

→ prompts.js:11-28
```

### `normalizeHaiku(raw)` → string

```
Параметри:
  raw: string (сира відповідь OpenAI)

Повертає: string (3 lines, joined by \n)

Pipeline:
  1. Strip markdown code blocks: /```[\s\S]*?```/g → keep content inside
  2. Strip """ blocks: /"""[\s\S]*?"""/g → keep content inside
  3. Remove intro text: /^(Here is|Here's|I hope|I've written|Sure|Of course|Certainly)…/i
  4. Split by \n, trim each line, filter empty
  5. Keep first 3 lines
  6. Pad to 3 if < 3 (push '')

→ prompts.js:30-53
```

### `SPICE_DESCRIPTIONS` — Array[7]

```javascript
SPICE_DESCRIPTIONS = [
  "Calm, traditional, contemplative haiku about nature and transience.",
  "A light, quiet sketch with a gentle mood.",
  "Slightly unexpected, with subtle irony.",
  "Playful, with humor and a surprising twist.",
  "Bold and sharp, with an absurd image.",
  "Very spicy, chaotic, grotesque and funny.",
  "Maximum heat: absurd, chaotic, surreal and dark-humored — yet still three lines of haiku.",
];

→ prompts.js:1-9
```

---

## Зріз 6: State Machine (всі стани та переходи)

```
                ┌──────────────────┐
                │      EMPTY       │ ◄── початковий стан
                │  (result-state)  │
                └────────┬─────────┘
                         │ generate() — client validation OK
                         ▼
                ┌──────────────────┐
                │     LOADING      │
                │  (result-state)  │
                └────────┬─────────┘
                    ┌────┴────┐
                    │         │
                    ▼         ▼
           ┌──────────┐  ┌──────────┐
           │   DONE    │  │  ERROR   │
           │ (success) │  │ (failure)│
           └──────────┘  └────┬─────┘
                               │ clear / retry
                               ▼
                         ┌──────────┐
                         │  EMPTY   │
                         └──────────┘

PROFANITY_MODAL (overlay):
  ─── може з'явитися з LOADING якщо profanityWords ≠ []
  ─── накладається поверх будь-якого стану
  ─── при закритті → повертає до EMPTY

Додаткові стани UI-елементів:
  ── langOpen (boolean): dropdown open/closed
  ── #btn-generate: disabled/enabled (залежить від words + lang + loading)
  ── #btn-clear: disabled/enabled (залежить від keywords тексту)
  ── #btn-history-clear: disabled/enabled (залежить від history.length)
  ── #spice-max: visible/hidden (залежить від spice === 6)
```

---

## Діаграма викликів (Call Graph)

```
HTTP POST /generate-haiku
  │
  ├─ server.js:validateRequest()
  │     │
  │     └─ (invalid) → 400 JSON
  │
  ├─ prompts.js:buildPrompt(words, lang, wasabiLevel)
  │     │
  │     └─ SPICE_DESCRIPTIONS[wasabiLevel]
  │
  ├─ openai.chat.completions.create({ model, messages, ... })
  │     │
  │     ├─ (success) → raw response
  │     ├─ (content_filter error) → 400 { error, profanityWords }
  │     └─ (API error) → 500 { error }
  │
  ├─ prompts.js:normalizeHaiku(raw)
  │     │
  │     ├─ lines < 3 → RETRY (server.js)
  │     └─ still < 3 → FALLBACK
  │
  └─ → 200 { haiku, fallback }


Frontend: generate()
  │
  ├─ phrases(state.keywords) → word count
  │
  ├─ (invalid) → state.resultState = 'error', render()
  │
  ├─ generateHaiku() → fetch POST /generate-haiku
  │     │
  │     ├─ (200) → state.resultState = 'done', saveHistory(), render()
  │     ├─ (400 profanity) → showProfanityModal(), reset to 'empty'
  │     ├─ (400 validation) → state.resultState = 'error', render()
  │     ├─ (500) → state.resultState = 'error', render()
  │     ├─ (timeout) → state.resultState = 'error', render()
  │     └─ (network error) → state.resultState = 'error', render()
  │
  └─ render() → всі 6 render-функцій
```
