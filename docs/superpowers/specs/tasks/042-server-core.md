# Task 042: Server Core
**GitHub Issue:** https://github.com/mishaivchenko/javarush-course/issues/3

## Goal
Implement `server.js` with Express routes, OpenAI integration, validation, and error handling. Serve `index.html` as static file.

## Dependencies
- 040 (scaffolding — `package.json`, `.env`)
- 041 (`prompts.js`)

## Acceptance Criteria
- [ ] `GET /` serves `index.html` from the project directory
- [ ] `POST /generate-haiku` validates:
  - `words` is array of 3–7 non-empty strings → 400 if invalid
  - `language` is one of 12 allowed codes → 400 if invalid
  - `wasabiLevel` is 0–6 → 400 if invalid
- [ ] Calls OpenAI API with prompt from `prompts.js`
- [ ] Uses `gpt-5-nano-2025-08-07` model
- [ ] Sets `reasoning_effort: "low"` (or `"medium"` if low unavailable)
- [ ] Returns `{haiku: string}` on success (200)
- [ ] Returns `{error: string}` on validation error (400)
- [ ] Returns `{error: string, profanityWords: string[]}` on profanity (400, if detectable)
- [ ] Returns `{error: string}` on server error (500)
- [ ] `normalizeHaiku()` applied to API response before returning
- [ ] Error: if `normalizeHaiku()` produces < 3 lines, retry once; if still fails, return fallback
- [ ] Port configurable via `PORT` env (default 3000)
- [ ] CORS enabled for development

## Implementation

### server.js
```javascript
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const OpenAI = require('openai');
const { buildPrompt, normalizeHaiku } = require('./prompts');

const app = express();
app.use(cors());
app.use(express.json());

// Serve static files
app.use(express.static(path.join(__dirname)));

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

const ALLOWED_LANGUAGES = [
  'uk', 'en', 'de', 'ja', 'fr', 'es', 'it', 'pt', 'pl', 'zh', 'ko', 'ar'
];

function validateRequest(body) {
  const { words, language, wasabiLevel } = body || {};
  
  if (!Array.isArray(words) || words.length < 3 || words.length > 7) {
    return { valid: false, error: 'Enter 3 to 7 words or short phrases' };
  }
  
  if (words.some(w => !w.trim())) {
    return { valid: false, error: 'All words must be non-empty' };
  }
  
  if (!language || !ALLOWED_LANGUAGES.includes(language)) {
    return { valid: false, error: 'Please select a valid language' };
  }
  
  if (typeof wasabiLevel !== 'number' || wasabiLevel < 0 || wasabiLevel > 6) {
    return { valid: false, error: 'Wasabi level must be 0–6' };
  }
  
  return { valid: true };
}

app.post('/generate-haiku', async (req, res) => {
  const validation = validateRequest(req.body);
  if (!validation.valid) {
    return res.status(400).json({ error: validation.error });
  }
  
  const { words, language, wasabiLevel } = req.body;
  const prompt = buildPrompt(words, language, wasabiLevel);
  
  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-5-nano-2025-08-07',
      messages: [
        { role: 'system', content: 'You are a haiku master. Output exactly 3 lines, no more, no less.' },
        { role: 'user', content: prompt }
      ],
      reasoning_effort: 'low',
      max_tokens: 150,
      temperature: 0.8,
    });
    
    const raw = completion.choices[0]?.message?.content || '';
    let haiku = normalizeHaiku(raw);
    
    // Retry once if normalization failed
    if (haiku.split('\n').filter(Boolean).length < 3) {
      const retry = await openai.chat.completions.create({
        model: 'gpt-5-nano-2025-08-07',
        messages: [
          { role: 'system', content: 'You are a haiku master. Output exactly 3 lines, no more, no less.' },
          { role: 'user', content: prompt + '\n\nIMPORTANT: Output EXACTLY 3 lines, separated by newlines. Nothing else.' }
        ],
        reasoning_effort: 'low',
        max_tokens: 150,
        temperature: 0.7,
      });
      const retryRaw = retry.choices[0]?.message?.content || '';
      haiku = normalizeHaiku(retryRaw);
    }
    
    // Final fallback if still bad
    if (haiku.split('\n').filter(Boolean).length < 3) {
      haiku = 'Silence\nwhere words should be\na blank page';
    }
    
    res.json({ haiku });
    
  } catch (err) {
    console.error('OpenAI API error:', err.message);
    
    // Check for content policy violation (profanity)
    if (err.status === 400 && err.message?.includes('content_filter')) {
      return res.status(400).json({
        error: 'Your input contains prohibited content. Please remove offensive words.',
        profanityWords: words.filter(w => /fuck|shit|damn|ass/i.test(w)) // basic detection
      });
    }
    
    res.status(500).json({ error: 'Something went wrong. Try again.' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Haiku 50 server running on http://localhost:${PORT}`);
});
```

### package.json update
Add `"start": "node server.js"` script (already in scaffolding task).

## Files Touched
- `lesson3/haiku-50/server.js` (create — full implementation, replaces skeleton)
