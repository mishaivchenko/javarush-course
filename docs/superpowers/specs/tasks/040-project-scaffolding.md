# Task 040: Project Scaffolding
**GitHub Issue:** https://github.com/mishaivchenko/javarush-course/issues/1

## Goal
Create the `lesson3/haiku-50/` directory structure, `package.json`, `.env` template, and verify `npm install` works.

## Dependencies
None — first task of this project.

## Acceptance Criteria
- [ ] `lesson3/haiku-50/` directory exists
- [ ] `package.json` with `express`, `cors`, `dotenv`, `openai` dependencies
- [ ] `npm install` succeeds with no errors
- [ ] `.env` file with `OPENAI_API_KEY=your-key-here` placeholder
- [ ] `.env` is already in `.gitignore` at repo root (verify)
- [ ] `lesson3/` added to git tracking (but not committed until next tasks)
- [ ] Minimal `server.js` skeleton renders OK

## Implementation
```bash
mkdir -p lesson3/haiku-50
cd lesson3/haiku-50
```

### package.json
```json
{
  "name": "haiku-50",
  "version": "1.0.0",
  "description": "Haiku 50 — Japanese minimalistic haiku generator",
  "main": "server.js",
  "scripts": {
    "start": "node server.js"
  },
  "dependencies": {
    "express": "^4.21.0",
    "cors": "^2.8.5",
    "dotenv": "^16.4.5",
    "openai": "^4.67.0"
  }
}
```

### .env
```
OPENAI_API_KEY=your-key-here
```

### server.js (skeleton)
```javascript
require('dotenv').config();
const express = require('express');
const cors = require('cors');

const app = express();
app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;

app.get('/', (req, res) => {
  res.send('Haiku 50 server running');
});

app.listen(PORT, () => {
  console.log(`Haiku 50 server running on port ${PORT}`);
});
```

## Files Touched
- `lesson3/haiku-50/package.json` (create)
- `lesson3/haiku-50/.env` (create)
- `lesson3/haiku-50/server.js` (create — skeleton)
