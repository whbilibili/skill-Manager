# HomeStock — Tokens

## 0. PRIMITIVES

Raw scales derived from the brand. These are the building blocks — semantic tokens reference them.

### Color Ramps

**Neutral** (cool-tinted gray — clean, organized feel)

| Step | Hex | Use |
|------|-----|-----|
| 50 | `#F7F8FA` | Lightest background, inset areas |
| 100 | `#F0F2F5` | Page canvas background |
| 200 | `#E4E7EC` | Borders, dividers (light) |
| 300 | `#D0D5DD` | Strong borders, input borders |
| 400 | `#98A2B3` | Placeholder text, disabled text |
| 500 | `#667085` | Muted text, tertiary labels |
| 600 | `#475467` | Secondary text, descriptions |
| 700 | `#344054` | Strong borders (dark mode) |
| 800 | `#1D2939` | Dark surfaces |
| 900 | `#101828` | Darkest surface, primary text |
| 950 | `#0C111D` | Near-black background (dark mode) |

**Brand** (mint-green)

| Step | Hex |
|------|-----|
| 50 | `#E8F5E9` |
| 100 | `#C8E6C9` |
| 200 | `#A5D6A7` |
| 300 | `#81C784` |
| 400 | `#66BB6A` |
| 500 | `#43A047` — primary accent |
| 600 | `#388E3C` |
| 700 | `#2E7D32` |
| 800 | `#1B5E20` |
| 900 | `#114A16` |
| 950 | `#0A2E0E` |

**Status Colors**

| Color | 50 (bg tint) | 500 (foreground) | 900 (dark tint) |
|-------|-------------|-----------------|-----------------|
| Red | `#FEF3F2` | `#E53935` | `#7A271A` |
| Green | `#E8F5E9` | `#43A047` | `#114A16` |
| Amber | `#FFF8E1` | `#FF9800` | `#7A4100` |

**Category Colors** (informational only — never interactive)

| Category | Color | Background tint |
|----------|-------|----------------|
| 食品饮料 | `#43A047` | `#E8F5E9` |
| 日用品 | `#4A90D9` | `#E3F2FD` |
| 清洁用品 | `#FF9800` | `#FFF8E1` |
| 个人护理 | `#E91E63` | `#FCE4EC` |
| 药品保健 | `#9C27B0` | `#F3E5F5` |
| 其他 | `#7C4DFF` | `#EDE7F6` |

### Spacing Primitives

`0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64, 96`

### Radii Primitives

`0, 4, 8, 12, 16, 999`

---

## 1. TYPOGRAPHY

### Font Stack

| Role | Font | Fallback | Weight | Use |
|------|------|----------|--------|-----|
| **Display** | `"Noto Sans SC"` | `"PingFang SC", -apple-system, sans-serif` | 600 | Screen titles, hero numbers, stat values |
| **Body / UI** | `"Noto Sans SC"` | `"PingFang SC", -apple-system, sans-serif` | 400 | Body text, descriptions, UI labels |
| **Mono / Data** | `"JetBrains Mono"` | `"SF Mono", "Menlo", monospace` | 400 | Quantities, prices, timestamps, percentages |

### Mono Font Rules

**`mono_for_code`: false** · **`mono_for_metrics`: true**

HomeStock is a consumer household app, not a dev tool — code snippets don't appear. But inventory quantities (2件, 0.5kg), prices (¥568.00), percentages (+12%), and dates (2024-05-25) benefit from tabular number alignment. Mono font keeps data columns scannable.

The display and body fonts are the same family (Noto Sans SC) at different weights — this creates cohesion in a Chinese-language UI where mixed font families can feel jarring.

### Type Scale

| Token | Size | Line Height | Letter Spacing | Weight | Use |
|-------|------|-------------|----------------|--------|-----|
| `--display` | 28px | 1.2 | -0.01em | 600 | Page titles ("首页"), large stat numbers |
| `--h1` | 24px | 1.25 | -0.01em | 600 | Section headings |
| `--h2` | 20px | 1.3 | 0 | 600 | Card titles ("库存预警") |
| `--h3` | 16px | 1.4 | 0 | 600 | Sub-section titles, item names |
| `--body` | 14px | 1.5 | 0 | 400 | Body text, descriptions, list labels |
| `--body-sm` | 13px | 1.5 | 0 | 400 | Secondary text, category labels |
| `--caption` | 12px | 1.5 | 0 | 400 | Timestamps, change indicators, footnotes |
| `--label` | 11px | 1.4 | 0.02em | 500 | Micro-labels, metadata tags |

### Typographic Rules

Chinese text does not use letter-spacing adjustments at body size — only display sizes get slight negative tracking for visual tightening. Line heights are generous (1.5 for body) because CJK characters need more vertical breathing room than Latin text. Never go below 1.4 line-height for any Chinese text.

---

## 2. COLOR SYSTEM (Semantic Tokens)

Semantic tokens reference the primitives above. Components use semantic tokens, never primitives directly.

### Primary Mode (Light)

| Token | Primitive | Hex | Role |
|-------|-----------|-----|------|
| `--background` | `{neutral.100}` | `#F0F2F5` | Page background |
| `--bg` | — | `var(--background)` | Shorthand alias |
| `--surface1` | — | `#FFFFFF` | Cards, elevated containers |
| `--surface2` | `{neutral.50}` | `#F7F8FA` | Table headers, inset areas |
| `--surface3` | `{neutral.200}` | `#E4E7EC` | Input backgrounds, wells |
| `--border` | `{neutral.200}` | `#E4E7EC` | Subtle dividers, card edges |
| `--border-visible` | `{neutral.300}` | `#D0D5DD` | Input borders, active controls |
| `--text1` | `{neutral.900}` | `#101828` | Primary text — headings, body |
| `--text2` | `{neutral.600}` | `#475467` | Secondary text — descriptions |
| `--text3` | `{neutral.500}` | `#667085` | Tertiary text — placeholders |
| `--text4` | `{neutral.400}` | `#98A2B3` | Disabled text |
| `--accent` | `{brand.500}` | `#43A047` | Primary accent — CTAs, active states |
| `--accent-subtle` | `{brand.50}` | `#E8F5E9` | Tinted backgrounds for accent |
| `--success` | `{green.500}` | `#43A047` | Confirmed, in-stock, positive |
| `--warning` | `{amber.500}` | `#FF9800` | Low stock, approaching expiry |
| `--error` | `{red.500}` | `#E53935` | Out of stock, expired, critical |

### Secondary Mode (Dark)

| Token | Primitive | Hex | Role |
|-------|-----------|-----|------|
| `--background` | `{neutral.950}` | `#0C111D` | Page background |
| `--surface1` | `{neutral.900}` | `#101828` | Cards, elevated containers |
| `--surface2` | `{neutral.800}` | `#1D2939` | Table headers, inset areas |
| `--surface3` | `{neutral.700}` | `#344054` | Input backgrounds, wells |
| `--border` | `{neutral.800}` | `#1D2939` | Subtle dividers |
| `--border-visible` | `{neutral.700}` | `#344054` | Input borders, active controls |
| `--text1` | `{neutral.50}` | `#F7F8FA` | Primary text |
| `--text2` | `{neutral.400}` | `#98A2B3` | Secondary text |
| `--text3` | `{neutral.500}` | `#667085` | Tertiary text |
| `--text4` | `{neutral.600}` | `#475467` | Disabled text |
| `--accent` | `{brand.400}` | `#66BB6A` | Primary accent |
| `--accent-subtle` | `{brand.950}` | `#0A2E0E` | Tinted backgrounds for accent |
| `--success` | `{green.500}` | `#43A047` | Positive states |
| `--warning` | `{amber.500}` | `#FF9800` | Caution states |
| `--error` | `{red.500}` | `#E53935` | Negative states |

### Accent & Status Tints

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `--accent-subtle` | `#E8F5E9` | `#0A2E0E` | Tinted backgrounds for accent |
| `--success-bg` | `#E8F5E9` | `#0A2E0E` | Success tinted backgrounds |
| `--warning-bg` | `#FFF8E1` | `#3D2200` | Warning tinted backgrounds |
| `--error-bg` | `#FEF3F2` | `#3D0D0D` | Error tinted backgrounds |

### Color Usage Rules

Brand green is the ONLY interactive accent. Category colors (blue, orange, pink, purple, violet) are informational — they tag categories in charts, badges, and icon backgrounds but never drive action. If you need a button color, it's green or neutral, period. Red and orange are reserved for alerts (low stock, expiry warnings) — never for CTAs.

---

## 3. SPACING

### Scale (8px base)

| Token | Value | Use |
|-------|-------|-----|
| `--space-2xs` | 2px | Optical adjustments only |
| `--space-xs` | 4px | Icon-to-label gaps, tight padding |
| `--space-sm` | 8px | Component internal padding, badge padding |
| `--space-md` | 16px | Standard padding, card gaps |
| `--space-lg` | 24px | Card padding, section item gaps |
| `--space-xl` | 32px | Section spacing |
| `--space-2xl` | 48px | Major section breaks |
| `--space-3xl` | 64px | Screen section divisions |
| `--space-4xl` | 96px | Hero breathing room |

---

## 4. BORDERS & RADII

### Radii Scale

| Token | Value | Use |
|-------|-------|-----|
| `--radius-element` | 4px | Checkboxes, small controls |
| `--radius-control` | 8px | Buttons, inputs, toggles, nav items |
| `--radius-component` | 12px | Cards, panels, icon backgrounds |
| `--radius-container` | 16px | Modals, sheets, popovers |
| `--radius-pill` | 999px | Tags, badges, search bar |

### Border Treatment

| Element | Border |
|---------|--------|
| Cards / Surfaces | `1px solid var(--border)` or shadow only |
| Buttons (primary) | none |
| Buttons (ghost) | `1px solid var(--accent)` |
| Inputs | `1px solid var(--border-visible)` |
| Tags / Chips | none (background-filled) |
| Modals / Sheets | `1px solid var(--border)` |

Corner philosophy: soft (8-12px). Cards and panels are gently rounded; buttons and inputs match at 8px. Only tags and badges go full-pill at 999px.

---

## 5. ELEVATION & SHADOWS

| Level | Light Mode | Dark Mode | Use |
|-------|-----------|----------|-----|
| **0** | None | None | Flat inline elements |
| **1** | `0 1px 3px rgba(16,24,40,0.06), 0 1px 2px rgba(16,24,40,0.04)` | `0 1px 3px rgba(0,0,0,0.3), 0 1px 2px rgba(0,0,0,0.2)` | Standard cards, containers |
| **2** | `0 4px 12px rgba(16,24,40,0.08), 0 2px 4px rgba(16,24,40,0.04)` | `0 4px 12px rgba(0,0,0,0.4), 0 2px 4px rgba(0,0,0,0.2)` | Floating cards, popovers |
| **3** | `0 12px 32px rgba(16,24,40,0.12), 0 4px 8px rgba(16,24,40,0.06)` | `0 12px 32px rgba(0,0,0,0.5), 0 4px 8px rgba(0,0,0,0.3)` | Modals, sheets |

Elevation strategy is "subtle." Shadows should be barely perceptible in light mode — the white-on-gray card structure already creates visual separation. Shadows exist to reinforce the layer, not to create it.

---

## 6. MOTION & INTERACTION

### Personality

Smooth — calm transitions that feel responsive without being flashy. Nothing bounces, nothing overshoots. The app should feel like organizing a real shelf: deliberate, satisfying, quiet.

### Timing

| Type | Duration | Easing | Use |
|------|----------|--------|-----|
| **Micro** | 150ms | `cubic-bezier(0.4, 0, 0.2, 1)` | Button press, toggle, color change |
| **Standard** | 250ms | `cubic-bezier(0.4, 0, 0.2, 1)` | Card expand, dropdown open, tab switch |
| **Emphasis** | 350ms | `cubic-bezier(0.4, 0, 0.2, 1)` | Modal present, page transitions |

### Interaction States

Hover: subtle background shift to `var(--surface2)` or `var(--surface3)`. No scaling, no shadow change on hover. Active/pressed: darken the background by one step. Focus: `0 0 0 3px var(--accent-subtle)` ring. Disabled: opacity 0.4, no interaction.

---

## 7. ICONOGRAPHY

> **⚠ Fallback disclosure.** The icons rendered in the generated preview come from the Phosphor icon kit, selected as the closest match to HomeStock's actual icons. They are **not** the brand's real glyphs.

### Observed style

| Attribute | Value |
|-----------|-------|
| Description | Clean 1.5px outline icons with rounded terminals. Friendly, approachable consumer-app style. |
| Stroke weight | regular (~1.5px) |
| Corner treatment | soft (rounded terminals) |
| Fill style | outline |
| Form language | humanist |
| Visual density | balanced |

### Fallback kit

- **Kit:** Phosphor
- **Weight / variant:** regular
- **Match score:** high
- **Why this kit:** Phosphor regular matches the observed 1.5px stroke weight, rounded terminals, and humanist form language. The warm, friendly personality aligns with HomeStock's consumer-app feel.
- **CDN:** `https://unpkg.com/@phosphor-icons/web@2/src/regular/style.css`
- **Usage:** `<i class="ph ph-house"></i>`

### Sizes

| Context | Size |
|---------|------|
| Inline with body text | 16px |
| Buttons | 18px |
| Navigation | 20px |
| Stat card icon background | 24px icon in 48px container |

### Color rule

Icons inherit text color by default. Inside tinted-background containers (stat cards, quick actions, category labels), the icon takes the full-saturation category color while the background is the 10% tint version.

### Don't

- Don't use filled/solid icon variants — HomeStock is an outline-only system.
- Don't mix icon kits — Phosphor regular everywhere.
- Never claim these are the brand's real icons — they are a best-match fallback.
