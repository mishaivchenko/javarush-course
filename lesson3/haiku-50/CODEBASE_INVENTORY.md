# CODEBASE INVENTORY — Haiku 50

> **Дата:** 2026-06-30
> **Стек:** Node.js (Express) + OpenAI API + чистий HTML/CSS/JS (frontend, single-file)
> **Reference:** `https://haiku-50.onrender.com` (audited in `HANDOFF_REVIEW.md`)
> **Start команда:** `npm start` → `http://localhost:3000`

---

## 1. Структура проєкту

```
lesson3/haiku-50/
├── index.html        # 🎨 Frontend — single-file (1389 рядків, ~40 KB)
├── server.js         # ⚙️ Express сервер — маршрути, OpenAI API, валідація (109 рядків)
├── prompts.js        # 📝 Prompt-константи — base, spice, safety, normalizeHaiku (56 рядків)
├── package.json      # 📦 express, cors, dotenv, openai
├── package-lock.json # Lockfile
├── .env              # 🔑 OPENAI_API_KEY=your-key-here (шаблон, в .gitignore)
├── node_modules/     # Встановлені залежності
│
├── 2026-06-30-haiku-50-design.md    # 📐 Дизайн-спека
├── HANDOFF_REVIEW.md                # 🔍 Аудит референсу
├── CODEBASE_INVENTORY.md            # 📋 Цей файл
├── DEPENDENCY_MAP.md                # 🗺️ Карта залежностей
├── RUNTIME_FLOW.md                  # 🔄 Runtime flow
└── API_MAP.md                       # 📡 API контракти (застарілий — від lesson2)
```

---

## 2. Модулі та відповідальність

### 2.1 `index.html` — Frontend (1389 рядків)

**Тип:** Single-file HTML з inline `<style>` і `<script>`
**Статус:** ✅ Готово до деплою

| Секція | Рядки | Відповідальність |
|--------|-------|------------------|
| **HTML — Splash Screen** | 800–811 | SVG-анімація (3s), логотип "Haiku 50 俳句", fade-out |
| **HTML — App Shell** | 813–883 | Bento Grid: 6 карток (Result, Keywords, Language, Wasabi, History, Info) |
| **HTML — Modal** | 886–896 | Profanity modal overlay |
| **CSS — Design Tokens** | 15–31 | `:root` — кольори, шрифти, тіні, радіуси |
| **CSS — Splash** | 50–77 | `@keyframes h50splash`, `h50splashLogo` |
| **CSS — Bento Grid** | 114–125 | `grid-template-areas` (3 колонки → 2 → 1) |
| **CSS — Cards** | 127–145 | Базові стилі карток (backdrop-filter, box-shadow) |
| **CSS — Result Card** | 147–260 | 4 стани: `empty`, `loading`, `error`, `done` |
| **CSS — Keywords** | 262–316 | textarea, word count, clear button |
| **CSS — Language** | 318–397 | Dropdown з 12 мовами, `aria-selected`, chevron |
| **CSS — Wasabi** | 399–483 | Spiciness dots (6 шт), cycling, max-indicator |
| **CSS — History** | 485–568 | 2-колонковий grid, localStorage |
| **CSS — Info / Generate** | 570–618 | 5-7-5 info, Generate button |
| **CSS — Modal** | 621–729 | Profanity modal, overlay, word chips |
| **CSS — Responsive** | 731–778 | 3 breakpoints: ≤979px (tablet), ≤639px (mobile) |
| **CSS — Reduced Motion** | 780–796 | `@media (prefers-reduced-motion: reduce)` |
| **JS — DOM Elements** | 901–923 | `els` — lazy binding для всіх елементів |
| **JS — Constants** | 925–941 | `LANGS` (12), `SPICE_LABELS` (7) |
| **JS — State** | 943–955 | `state` object — keywords, lang, spice, resultState, lines, history |
| **JS — Helpers** | 957–978 | `phrases()`, `labelOf()`, `timeLabel()`, `nextId()` |
| **JS — Render Functions** | 980–1122 | `renderEmpty()`, `renderLoading()`, `renderError()`, `renderDone()`, `renderKeywords()`, `renderLanguage()`, `renderWasabi()`, `renderHistory()`, `renderGenerateButton()` |
| **JS — escapeHtml** | 1126–1130 | XSS-захист |
| **JS — History (localStorage)** | 1132–1155 | `loadHistory()`, `saveHistory()` — max 100 |
| **JS — Profanity Modal** | 1157–1172 | `showProfanityModal()`, `hideProfanityModal()` |
| **JS — API Client** | 1174–1205 | `generateHaiku()` — fetch POST, 30s timeout, error handling |
| **JS — Main Handler** | 1207–1281 | `generate()` — validation → API → render → history |
| **JS — Event Binding** | 1283–1376 | `bindEvents()` — всі listener'и |
| **JS — Init** | 1379–1385 | `bindElements()`, `loadHistory()`, `bindEvents()`, `render()` |

**Ключові стани:**
```
EMPTY ──► LOADING ──► DONE
  │                      │
  └──► ERROR ◄───────────┘
        │
        └──► EMPTY (on clear/retry)

PROFANITY_MODAL (overlays any state → returns to EMPTY on close)
```

### 2.2 `server.js` — Backend (109 рядків)

**Тип:** Express.js сервер
**Статус:** ✅ Готово

| Секція | Рядки | Відповідальність |
|--------|-------|------------------|
| Ініціалізація | 1–15 | dotenv, express, cors, openai client |
| ALLOWED_LANGUAGES | 17–19 | 12 кодів мов |
| `validateRequest()` | 21–41 | Валідація: `words[3-7]`, `language`, `wasabiLevel[0-6]` |
| `POST /generate-haiku` | 43–104 | Основний маршрут — валідація → prompt → OpenAI → normalize → retry → fallback |
| Content filter (profanity) | 94–99 | Перевірка `content_filter` помилки OpenAI |
| Server start | 106–109 | `PORT=3000` |

**OpenAI Config:**
- **Model:** `gpt-5-nano-2025-08-07`
- **reasoning_effort:** `"low"`
- **Temperature:** `0.8` (перша спроба), `0.7` (retry)
- **Max tokens:** `150`
- **System prompt:** "You are a haiku master. Output exactly 3 lines, no more, no less."
- **Retry:** 1 retry if < 3 lines
- **Fallback:** Stock haiku if retry fails

### 2.3 `prompts.js` — Prompt Constants (56 рядків)

**Тип:** Експортований модуль
**Статус:** ✅ Готово

| Експорт | Рядки | Відповідальність |
|---------|-------|------------------|
| `SPICE_DESCRIPTIONS` | 1–9 | 7 рівнів "spiciness" (calm → insane) |
| `buildPrompt(words, language, wasabiLevel)` | 11–28 | Збирає повний prompt: base requirements + spice + safety |
| `normalizeHaiku(raw)` | 30–53 | 5-крокова нормалізація |
| module.exports | 55 | `{ buildPrompt, normalizeHaiku, SPICE_DESCRIPTIONS }` |

**normalizeHaiku pipeline:**
1. Strip markdown code blocks (` ```...``` ` або ` """...""" `)
2. Remove introductory text ("Here is", "Sure", "Of course", etc.)
3. Split by newline, trim, filter empty
4. Keep first 3 lines
5. Pad to 3 lines if needed

---

## 3. Точки входу (Entry Points)

| URL / File | Призначення |
|------------|-------------|
| `node server.js` | **Головний entry point** — Express на :3000 |
| `npm start` | Скорочений запуск сервера |
| `http://localhost:3000/` | Frontend (serve static `index.html`) |
| `POST http://localhost:3000/generate-haiku` | API endpoint |

---

## 4. Команди

| Команда | Використання |
|---------|-------------|
| `npm start` | Запуск сервера на localhost:3000 |
| `open http://localhost:3000` | Відкрити frontend |

---

## 5. Зони ризику

### 🔴 Високий ризик

1. **OpenAI API ключ в .env** — `.env` є в `.gitignore`, але ключ треба вставити вручну. Якщо хтось запушить `.env` — ключ скомпрометовано.
   - **Доказ:** `.env` → `OPENAI_API_KEY=your-key-here`
   - **Ризик:** Витік ключа → фінансові втрати

2. **API rate limiting відсутній** — немає захисту від DDoS/спаму. Кожен запит коштує грошей.
   - **Ризик:** Хтось може спамити `/generate-haiku` і витратити бюджет

### 🟡 Середній ризик

3. **Profanity detection — basic regex** — використовує простий `regex` на 4 слова (fuck, shit, damn, ass). Не покриває всі мови.
   - **Доказ:** `server.js:98`
   - **Ризик:** Помилкові спрацьовування або пропущені лайки

4. **Retry без rate limiting** — retry викликає OpenAI API повторно без затримки. Може подвоїти витрати на поганий prompt.
   - **Доказ:** `server.js:69-81`

5. **Немає кешування** — кожен запит іде в OpenAI. Однакові keywords+language+spice = повторний API call.
   - **Ризик:** Марна трата токенів

### 🟢 Низький ризик

6. **Single-file frontend** — весь HTML+CSS+JS в одному файлі. Для малого проєкту це ОК, але ускладнює підтримку при зростанні.

7. **Немає тестів** — ні unit, ні E2E. Покладаємось на ручне тестування.

8. **API_MAP.md застарів** — описує lesson2 проєкти, не Haiku 50.

---

## 6. Зовнішні залежності

| Залежність | Тип | Місце використання |
|------------|-----|-------------------|
| Google Fonts: Noto Sans JP 400/500 | CDN (preconnect) | index.html — body text, labels, controls |
| Google Fonts: Noto Serif JP 500/600 | CDN (preconnect) | index.html — haiku lines, headings |
| OpenAI API | HTTPS | server.js — `openai.chat.completions.create()` |
| express ^4.21.0 | npm | server.js — HTTP server |
| cors ^2.8.5 | npm | server.js — CORS middleware |
| dotenv ^16.4.5 | npm | server.js — .env loading |
| openai ^4.67.0 | npm | server.js — OpenAI client |

---

## 7. Відкриті питання

1. Чи потрібен rate limiting? (Spec: "Add as follow-up if needed.")
2. Чи додавати кешування (in-memory) для однакових запитів?
3. Profanity detection — розширити на всі 12 мов чи залишити базовий regex?
4. Чи планується деплой на Vercel/Render (як reference)?
5. API_MAP.md застарів — видалити чи переписати під Haiku 50?
