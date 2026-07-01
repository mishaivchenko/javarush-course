# Task 043: index.html — HTML Structure & CSS
**GitHub Issue:** https://github.com/mishaivchenko/javarush-course/issues/4

## Goal
Implement the full HTML structure and CSS styling for the Haiku 50 Bento Grid UI as a single-file `index.html`. The JS section remains empty (deferred to tasks 044–045).

## Dependencies
- 040 (scaffolding — project directory ready)

## Acceptance Criteria
- [ ] `index.html` is a single-file document with `<style>` block and empty `<script>` block
- [ ] DOCTYPE `html`, `lang="uk"` (Ukrainian default)
- [ ] Google Fonts: `Noto Sans JP` (400, 500) + `Noto Serif JP` (500, 600) via preconnect
- [ ] Viewport meta tag for responsive
- [ ] HTML structure matches component tree from design spec:
  - Splash screen (SVG logo)
  - Page shell → Screen → Header (brand + description)
  - Bento Grid with 6 cards: result, keywords, language, wasabi, history, info
  - Profanity modal
- [ ] Splash screen CSS:
  - Fixed overlay, z-index 10000
  - Background `#f1efe8` with radial gradient
  - SVG logo (circle ring + drop + "Haiku 50" + "俳句")
  - `h50splash` animation (3s ease, fades out)
- [ ] Bento Grid CSS:
  - Desktop: 3 columns, 3 rows (`"result result input"`, `"result result lang"`, `"result result wasabi"`, `"history history info"`)
  - Tablet (<980px): 2 columns
  - Mobile (<640px): 1 column
  - Gap: 16px
- [ ] Card design:
  - Background `rgba(255,255,255,0.88)`, border `rgba(231,227,216,0.78)`
  - Border-radius 20px, box-shadow subtle
  - backdrop-filter blur for glass effect
- [ ] Result card:
  - 3 internal states styled: empty (ring + text), loading (spinner), error (red), done (haiku lines)
  - Empty state: 96px circle ring, "No haiku yet", instruction text
  - Loading: spinning ring (38px), "Composing the lines…"
  - Error: red circle with "!", error message
  - Done: haiku lines in Noto Serif JP, 32px, metadata tags
- [ ] Keywords card:
  - Textarea with placeholder, focus state with green border
  - Count label underneath
  - Clear button (disabled when empty)
- [ ] Language card:
  - Dropdown button with chevron
  - Menu with 12 language options (label + native name)
  - Selected state styling
- [ ] Wasabi card:
  - Wasabi button with icon (crossed lines in dashed box)
  - 6 dots (13px circles, green active)
  - Heat level label + max indicator
- [ ] History card:
  - Header with count + clear button
  - Empty state: "No haiku yet"
  - History list: 2-col grid of cards
  - Each history item: lines, tags (lang, spice, time)
  - Mobile: 1-col grid
- [ ] Info card:
  - Dark panel with "5·7·5" heading + explanation
  - Green Generate button (disabled during loading)
- [ ] Profanity modal:
  - Fixed overlay with backdrop blur
  - White card, 420px max-width
  - Close button (✕), icon (⚠️), title, word list, action button
  - Animations: fadeIn + slideIn
- [ ] Body background: `#f1efe8` with subtle CSS gradient overlay
- [ ] Animations defined: `h50spin`, `h50up`, `h50pop`, `h50splash`, `h50splashLogo`, modal animations
- [ ] `@media (prefers-reduced-motion: reduce)` disables all animations
- [ ] Responsive breakpoints: default, ≤979px, ≤639px

## Implementation Notes
- All CSS is inline in `<style>` in `<head>`
- Use CSS custom properties for design tokens
- Grid areas use `grid-template-areas` pattern
- Use `aria-live="polite"` on result stage for accessibility
- SVG splash logo: 1200×800 viewBox, `<circle>` ring, `<path>` drop, `<text>` title + subtitle
- Language menu uses absolute positioning inside the card (`position: relative` on card)
- All interactive elements are `<button>` elements

## Files Touched
- `lesson3/haiku-50/index.html` (create)
