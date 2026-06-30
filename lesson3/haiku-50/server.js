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
      model: 'gpt-4o-mini',
      messages: [
        { role: 'system', content: 'You are a haiku master. Output exactly 3 lines, no more, no less.' },
        { role: 'user', content: prompt }
      ],
      max_tokens: 150,
      temperature: 0.8,
    });

    const raw = completion.choices[0]?.message?.content || '';
    let haiku = normalizeHaiku(raw);

    // Retry once if normalization failed
    if (haiku.split('\n').filter(Boolean).length < 3) {
      const retry = await openai.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: [
          { role: 'system', content: 'You are a haiku master. Output exactly 3 lines, no more, no less.' },
          { role: 'user', content: prompt + '\n\nIMPORTANT: Output EXACTLY 3 lines, separated by newlines. Nothing else.' }
        ],
        max_tokens: 150,
        temperature: 0.7,
      });
      const retryRaw = retry.choices[0]?.message?.content || '';
      haiku = normalizeHaiku(retryRaw);
    }

    // Final fallback if still bad
    if (haiku.split('\n').filter(Boolean).length < 3) {
      haiku = 'Silence\nwhere words should be\na blank page';
      return res.json({ haiku, fallback: true });
    }

    res.json({ haiku, fallback: false });

  } catch (err) {
    console.error('OpenAI API error:', err.message);

    // Check for content policy violation (profanity)
    if (err.status === 400 && err.message?.includes('content_filter')) {
      return res.status(400).json({
        error: 'Your input contains prohibited content. Please remove offensive words.',
        profanityWords: words.filter(w => /fuck|shit|damn|ass/i.test(w))
      });
    }

    res.status(500).json({ error: 'Something went wrong. Try again.' });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Haiku 50 server running on http://localhost:${PORT}`);
});
