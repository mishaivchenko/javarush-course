# Task 041: Prompts Module
**GitHub Issue:** https://github.com/mishaivchenko/javarush-course/issues/2

## Goal
Create `prompts.js` with all prompt constants, spiciness descriptions, and the haiku normalization function.

## Dependencies
- 040 (project scaffolding — need the directory)

## Acceptance Criteria
- [ ] `lesson3/haiku-50/prompts.js` exists
- [ ] Exports `buildPrompt(words, language, wasabiLevel)` function
- [ ] Exports `normalizeHaiku(raw)` function
- [ ] `buildPrompt` returns a string that includes:
  - Base haiku instruction in the target language
  - The user's words
  - Spiciness description (level 0–6)
  - Safety instruction (no profanity)
  - Format requirement (exactly 3 lines)
- [ ] `normalizeHaiku` strips markdown wrappers, intros, returns exactly 3 lines
- [ ] Spiciness descriptions are defined as a const array

## Implementation

### prompts.js structure
```javascript
const SPICE_DESCRIPTIONS = [
  "Calm, traditional, contemplative haiku about nature and transience.",
  "A light, quiet sketch with a gentle mood.",
  "Slightly unexpected, with subtle irony.",
  "Playful, with humor and a surprising twist.",
  "Bold and sharp, with an absurd image.",
  "Very spicy, chaotic, grotesque and funny.",
  "Maximum heat: absurd, chaotic, surreal and dark-humored — yet still three lines of haiku.",
];

function buildPrompt(words, language, wasabiLevel) {
  const wordsStr = words.join(', ');
  const spice = SPICE_DESCRIPTIONS[wasabiLevel] || SPICE_DESCRIPTIONS[0];
  
  return `You are a haiku master. Write a haiku in ${language} using these words: ${wordsStr}.

Requirements:
- Exactly 3 lines, each line is one phrase
- Use the given words to set the imagery
- The haiku must feel poetic, not literal
- Do not explain, translate, or add preamble
- Output ONLY the 3 lines, separated by newlines

${spice}

- No profanity, aggression, or prohibited content
- Keep it safe for general audience`;
}

function normalizeHaiku(raw) {
  // 1. Strip markdown code blocks (``` or """)
  let cleaned = raw.replace(/```[\s\S]*?```/g, '').replace(/"""[\s\S]*?"""/g, '');
  
  // 2. Remove common introductory text
  cleaned = cleaned.replace(/^(Here is|Here's|I hope you|I've written|Sure|Of course|Certainly)[^]*?\n/i, '');
  
  // 3. Split by newline, trim each line, filter empty
  let lines = cleaned.split('\n').map(l => l.trim()).filter(Boolean);
  
  // 4. Keep exactly first 3 non-empty lines
  lines = lines.slice(0, 3);
  
  // 5. If less than 3, pad with empty strings
  while (lines.length < 3) {
    lines.push('');
  }
  
  return lines.join('\n');
}

module.exports = { buildPrompt, normalizeHaiku, SPICE_DESCRIPTIONS };
```

## Files Touched
- `lesson3/haiku-50/prompts.js` (create)
