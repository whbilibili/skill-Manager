# Trae — Tokens

## 0. PRIMITIVES

Raw scales derived from the brand. These are the building blocks — semantic tokens reference them.

### Color Ramps

**Neutral** (cool-blue tinted)

| Step | Hex | Use |
|------|-----|-----|
| 50 | `#F0F2F5` | Lightest background |
| 100 | `#E0E3EA` | Light surfaces |
| 200 | `#C9D1D9` | Borders, dividers (light) |
| 300 | `#9599A6` | Strong borders (light) |
| 400 | `#737780` | Placeholder text |
| 500 | `#5C6373` | Muted text |
| 600 | `#3A3F4B` | Secondary text |
| 700 | `#363B4E` | Strong borders (dark) |
| 800 | `#2A2E3E` | Dark surfaces |
| 900 | `#262A37` | Darkest surface |
| 950 | `#171B26` | Near-black background |

**Brand** (Intelligent Green)

| Step | Hex |
|------|-----|
| 50 | `#ECFDF5` |
| 100 | `#D1FAE5` |
| 200 | `#A7F3D0` |
| 300 | `#6EE7B7` |
| 400 | `#34D399` |
| 500 | `#10B981` — primary accent |
| 600 | `#059669` |
| 700 | `#047857` |
| 800 | `#065F46` |
| 900 | `#064E3B` |
| 950 | `#022C22` |

**Secondary** (Purple)

| Step | Hex |
|------|-----|
| 50 | `#F5F3FF` |
| 100 | `#EDE9FE` |
| 200 | `#DDD6FE` |
| 300 | `#C4B5FD` |
| 400 | `#A78BFA` |
| 500 | `#7563E7` — secondary accent |
| 600 | `#6D28D9` |
| 700 | `#5B21B6` |
| 800 | `#4C1D95` |
| 900 | `#3B0764` |
| 950 | `#1E0038` |

**Blue** (Links & Progress)

| Step | Hex |
|------|-----|
| 50 | `#EFF6FF` |
| 100 | `#DBEAFE` |
| 200 | `#BFDBFE` |
| 300 | `#93C5FD` |
| 400 | `#60A5FA` |
| 500 | `#387BFF` — link color |
| 600 | `#2563EB` |
| 700 | `#1D4ED8` |
| 800 | `#1E40AF` |
| 900 | `#1E3A8A` |
| 950 | `#172554` |

**Status Colors**

| Color | 50 (bg tint) | 500 (foreground) | 900 (dark tint) |
|-------|-------------|-----------------|-----------------|
| Red | `#FEF2F2` | `#CC4B53` | `#7F1D1D` |
| Green | `#ECFDF5` | `#10B981` | `#064E3B` |
| Amber | `#FFFBEB` | `#EB9B61` | `#78350F` |

### Spacing Primitives

`0, 1, 2, 4, 6, 8, 12, 16, 20, 24, 32, 40, 48, 64, 96`

### Radii Primitives

`0, 2, 4, 6, 8, 12`

---

## 1. TYPOGRAPHY

### Font Stack

| Role | Font | Fallback | Weight | Use |
|------|------|----------|--------|-----|
| **Display** | `"Inter"` | `system-ui, -apple-system, sans-serif` | 600 | Screen titles, hero numbers |
| **Body / UI** | `"Inter"` | `system-ui, -apple-system, sans-serif` | 400 | Body text, descriptions, UI labels |
| **Mono / Code** | `"JetBrains Mono"` | `"Fira Code", "Cascadia Code", monospace` | 400 | Code snippets, technical identifiers |

### Mono Font Rules

**`mono_for_code`: true** · **`mono_for_metrics`: true**

Trae is an AI-native IDE — code is the primary content surface, so JetBrains Mono is the default typeface inside the editor, terminal, and any code-facing context. Because the product lives entirely in the developer-tooling domain, metrics like line counts, token usage, latency numbers, and file sizes also render in mono to reinforce the technical, data-dense aesthetic. This is consistent with the "terminal cursor on a cold-blue stage" philosophy.

- **`mono_for_code: true`:** Use the mono font for code blocks, file paths, shell commands, and inline technical tokens (variable names, CSS properties, API endpoints). Almost every brand with a mono font sets this to `true`.
- **`mono_for_code: false`:** Even code snippets use the body font. Rare — only the most editorial/typographic brands.
- **`mono_for_metrics: true`:** Use the mono font for pricing, counts, timestamps, percentages, ID strings, IP addresses, speeds, file sizes. Common for dev-tool and terminal-aesthetic brands (Linear, Nothing) where data is part of the visual identity.
- **`mono_for_metrics: false`:** Use the body font for all numeric/data values. Mono is reserved for code only. Common for consumer and editorial brands (Apple, mymind, Notion). Many brands use mono for code but NOT for metrics — e.g. Cursor uses mono inside IDE screenshots, but `$20` pricing stays in the sans.

Inter is the backbone sans-serif — highly legible at small sizes on screen, with open counters and tabular figures that work well in dense UI layouts. JetBrains Mono pairs naturally as the code typeface: it was designed for the same developer-tool context, with programming ligatures and clear disambiguation of `0O`, `1lI`, `|!`. Together they produce a clean split: Inter for human-facing text, JetBrains Mono for machine-facing text.

### Type Scale

| Token | Size | Line Height | Letter Spacing | Weight | Use |
|-------|------|-------------|----------------|--------|-----|
| `--display` | 36px | 1.1 | -0.02em | 600 | Hero numbers, screen titles |
| `--heading` | 24px | 1.2 | -0.015em | 600 | Section headings |
| `--subheading` | 18px | 1.3 | -0.01em | 500 | Subsection titles, card titles |
| `--body` | 14px | 1.5 | 0 | 400 | Body text, descriptions |
| `--body-sm` | 13px | 1.5 | 0 | 400 | Secondary text, notes |
| `--caption` | 12px | 1.4 | 0.01em | 400 | Timestamps, footnotes |
| `--label` | 11px | 1.3 | 0.02em | 500 | Micro-labels, metadata |

### Typographic Rules

Body text is always set in Inter 400 at 14px. Headings use Inter 600 with slight negative letter-spacing to tighten the display weight. Mono text (JetBrains Mono 400 at 13px) is used for all code, file paths, terminal output, and data metrics — including inline code tokens within body paragraphs. Labels and captions use the body font at smaller sizes. Uppercase text is avoided except for very short status badges (e.g. "BETA"). Line lengths should not exceed ~72ch in content areas for comfortable reading.

---

## 2. COLOR SYSTEM (Semantic Tokens)

Semantic tokens reference the primitives above. Components use semantic tokens, never primitives directly.

### Primary Mode (Dark)

| Token | Primitive | Hex | Role |
|-------|-----------|-----|------|
| `--background` | `{neutral.950}` | `#171B26` | Page background |
| `--bg` | — | `var(--background)` | Shorthand alias for `--background` |
| `--surface1` | `{neutral.900}` | `#262A37` | Cards, elevated containers |
| `--surface2` | `{neutral.800}` | `#2A2E3E` | Secondary cards, grouped backgrounds |
| `--surface3` | `{neutral.700}` | `#363B4E` | Tertiary surfaces, inset areas |
| `--border` | `{neutral.900}` | `#262A37` | Subtle dividers, card edges |
| `--border-visible` | `{neutral.700}` | `#363B4E` | Stronger borders — inputs, active controls |
| `--text1` | `{neutral.200}` | `#C9D1D9` | Primary text — headings, body |
| `--text2` | `{neutral.300}` | `#9599A6` | Secondary text — descriptions, labels |
| `--text3` | `{neutral.400}` | `#737780` | Tertiary text — placeholders, timestamps |
| `--text4` | `{neutral.500}` | `#5C6373` | Disabled text, ghost elements |
| `--accent` | `{brand.500}` | `#10B981` | Primary accent — interactive elements, CTAs |
| `--accent-subtle` | `{brand.950}` | `#022C22` | Tinted backgrounds for accent |
| `--success` | `{green.500}` | `#10B981` | Confirmed, completed, positive |
| `--warning` | `{amber.500}` | `#EB9B61` | Caution, pending, approaching limit |
| `--error` | `{red.500}` | `#CC4B53` | Destructive, overdue, critical |

### Secondary Mode (Light)

| Token | Primitive | Hex | Role |
|-------|-----------|-----|------|
| `--background` | `{neutral.50}` | `#F0F2F5` | Page background |
| `--surface1` | — | `#FFFFFF` | Cards, elevated containers |
| `--surface2` | `{neutral.100}` | `#E0E3EA` | Secondary cards, grouped backgrounds |
| `--surface3` | `{neutral.200}` | `#C9D1D9` | Tertiary surfaces, inset areas |
| `--border` | `{neutral.100}` | `#E0E3EA` | Subtle dividers, card edges |
| `--border-visible` | `{neutral.200}` | `#C9D1D9` | Stronger borders — inputs, active controls |
| `--text1` | `{neutral.950}` | `#171B26` | Primary text |
| `--text2` | `{neutral.500}` | `#5C6373` | Secondary text |
| `--text3` | `{neutral.400}` | `#737780` | Tertiary text |
| `--text4` | `{neutral.300}` | `#9599A6` | Disabled text |
| `--accent` | `{brand.600}` | `#059669` | Primary accent |
| `--accent-subtle` | `{brand.50}` | `#ECFDF5` | Tinted backgrounds for accent |
| `--success` | `{green.500}` | `#10B981` | Positive states |
| `--warning` | `{amber.500}` | `#EB9B61` | Caution states |
| `--error` | `{red.500}` | `#CC4B53` | Negative states |

### Accent & Status Tints

| Token | Primary (Dark) | Secondary (Light) | Usage |
|-------|---------|-----------|-------|
| `--accent-subtle` | `#022C22` | `#ECFDF5` | Tinted backgrounds for accent elements |
| `--success-bg` | `#064E3B` | `#ECFDF5` | Success tinted backgrounds |
| `--warning-bg` | `#78350F` | `#FFFBEB` | Warning tinted backgrounds |
| `--error-bg` | `#7F1D1D` | `#FEF2F2` | Error tinted backgrounds |

### Color Usage Rules

The Intelligent Green (`#10B981`) is the sole expressive color in the palette — it signals that the AI is active, available, or has contributed to a result. Use it sparingly: primary buttons, active states, inline AI attribution marks, and the blinking cursor. It should never fill large surface areas. Purple (`#7563E7`) is reserved for secondary indicators like badges, progress stages, and non-interactive highlights. Blue (`#387BFF`) is used only for hyperlinks and progress bars. Red, amber, and green status colors follow standard semantic conventions. In dark mode, borders default to `neutral.900` (nearly invisible) to maintain the flat, immersive feel — use `--border-visible` (`neutral.700`) only when a control needs a clear edge (inputs, focused cards). In light mode, the same logic inverts: `neutral.100` for subtle borders, `neutral.200` for visible ones. Never use raw hex values in components — always reference semantic tokens.

---

## 3. SPACING

### Scale (8px base)

| Token | Value | Use |
|-------|-------|-----|
| `--space-2xs` | 2px | Optical adjustments only |
| `--space-xs` | 4px | Icon-to-label gaps, tight padding |
| `--space-sm` | 8px | Component internal padding |
| `--space-md` | 16px | Standard padding, element gaps |
| `--space-lg` | 24px | Card padding, section item gaps |
| `--space-xl` | 32px | Section spacing, generous padding |
| `--space-2xl` | 48px | Major section breaks |
| `--space-3xl` | 64px | Screen section divisions |
| `--space-4xl` | 96px | Hero breathing room |

---

## 4. BORDERS & RADII

### Radii Scale (Semantic → Primitive)

| Token | Value | Primitive | Use |
|-------|-------|-----------|-----|
| `--radius-element` | 4px | `{radii[2]}` | Small controls, checkboxes, icons |
| `--radius-control` | 6px | `{radii[3]}` | Buttons, inputs, toggles |
| `--radius-component` | 8px | `{radii[4]}` | Cards, panels, list items |
| `--radius-container` | 12px | `{radii[5]}` | Modals, sheets, popovers |
| `--radius-pill` | 9999px | — | Pills, tags (not standard — use sparingly) |

### Border Treatment

| Element | Border |
|---------|--------|
| Cards / Surfaces | `1px solid var(--border)` — nearly invisible in dark mode, defines edge in light |
| Buttons | Primary: none (solid fill). Secondary: `1px solid {neutral.700}`. Ghost: none |
| Inputs | `1px solid var(--border)` default → `1px solid var(--accent)` on focus |
| Tags / Chips | None — filled background (`neutral.800` dark / `neutral.100` light) |
| Modals / Sheets | None — elevated via shadow (light) or surface contrast (dark) |

Trae uses sharp-to-soft corners (4–8px range), never pill-shaped CTAs. The `--radius-pill` token exists for status badges only. Corner rounding increases with component scale: small controls are tightest (4px), containers are softest (12px). This graduated approach reinforces the hierarchy — small elements feel precise and tool-like, while large containers feel enclosed and stable.

---

## 5. ELEVATION & SHADOWS

| Level | Light Mode | Dark Mode | Use |
|-------|-----------|----------|-----|
| **0** | None | None | Flat, inline elements |
| **1** | `0 1px 3px rgba(0,0,0,0.08)` | None | Standard cards, containers |
| **2** | `0 4px 12px rgba(0,0,0,0.12)` | `0 4px 12px rgba(0,0,0,0.4)` | Floating cards, menus, popovers |
| **3** | `0 8px 24px rgba(0,0,0,0.16)` | `0 8px 24px rgba(0,0,0,0.5)` | Modals, sheets, dialogs |

Trae follows a **flat elevation strategy**. In dark mode, level 1 has no shadow at all — hierarchy is communicated through surface color steps (`neutral.950` → `900` → `800` → `700`) rather than drop shadows. Shadows only appear at level 2+ in dark mode for floating overlays that need to visually detach from the canvas. In light mode, subtle shadows are used more freely since the white/light-gray surfaces don't provide enough contrast on their own. The philosophy is: if you can show depth through color, don't add a shadow.

---

## 6. MOTION & INTERACTION

### Personality

**Mechanical.** Transitions are crisp, immediate, and utilitarian — like a cursor snapping to position or a terminal printing a new line. There is no bounce, no overshoot, no organic ease-in-out. Elements appear where they should be, when they should be there. The only easing is `ease-out` (fast start, gentle stop) which feels like a machine decelerating. This matches Trae's identity as a precision tool: every motion communicates responsiveness, not personality.

### Timing

| Type | Duration | Easing | Use |
|------|----------|--------|-----|
| **Micro** | 120ms | `ease-out` | Button press, toggle, color change |
| **Standard** | 180ms | `ease-out` | Card expand, content transitions |
| **Emphasis** | 300ms | `ease-out` | Sheet present, navigation, page transitions |

### Interaction States

All interactive elements follow a consistent state model. **Hover** applies a single-step surface color shift (e.g. `neutral.900` → `neutral.800` in dark mode) with no transform or scale change. **Active/pressed** darkens one further step and may apply `transform: scale(0.98)` on buttons for tactile feedback. **Focus** uses a `2px solid var(--accent)` ring offset by 2px — visible, high-contrast, and consistent across all controls. **Disabled** reduces opacity to `0.4` and removes pointer events. There are no glow effects, no color-shift animations on hover, and no shadow transitions — state changes are communicated through flat color swaps only, consistent with the mechanical motion personality.

---

## 7. ICONOGRAPHY

> **⚠ Fallback disclosure.** The icons rendered in the generated preview come from a freely-licensed kit selected as the closest match to the brand's actual icons. They are **not** the brand's real glyphs — the brand's icon set is proprietary and not redistributed with this skill. If you need the authentic look, swap these out with licensed assets.

### Observed style (the brand's actual icons)

| Attribute | Value |
|-----------|-------|
| Description | Clean geometric outline icons at ~1.5px stroke, rounded terminals, consistent 24px grid. Similar to VS Code's Codicon set but cleaner. No hand-drawn quality — precise, tool-like. |
| Stroke weight | regular |
| Corner treatment | soft |
| Fill style | outline |
| Form language | geometric |
| Visual density | minimal |

### Fallback kit (what the preview actually renders)

- **Kit:** Lucide
- **Weight / variant:** default (2px)
- **Match score:** high
- **Why this kit:** Lucide's geometric-clean 2px stroke with rounded caps closely matches Trae's icon style. Both are developer-tool-oriented with minimal visual density. Tabler would be second choice for breadth, but Lucide's cleaner geometry wins for this brand.
- **CDN:** `https://unpkg.com/lucide-static@1.8.0/font/lucide.css`
- **Usage:** `<i class="icon icon-{name}"></i>`

### Sizes

| Context | Size |
|---------|------|
| Inline with body text | 16px |
| Buttons | 18px |
| Navigation | 20px |

### Color rule

Icons inherit `currentColor` by default, taking on the text color of their context (`--text1`, `--text2`, `--text3`). Accent-colored icons use `var(--accent)` explicitly — only for active/selected states or AI-attributed indicators. Status icons use their respective semantic color (`--success`, `--warning`, `--error`). Never apply opacity to icons for de-emphasis — use a lower text-tier color instead.

### Don't

- Don't mix filled and outline styles in the same context — all icons should be outline unless an active/selected state calls for a filled variant.
- Never claim these are the brand's real icons — they are a best-match fallback.
