# Birchline — Tokens

## 0. PRIMITIVES

Raw scales derived from brand analysis. Semantic tokens reference them.

### Color Ramps

**Neutral** (Warm sand — amber-tinted, never cool gray)

| Step | Hex | Use |
|------|-----|-----|
| 50  | `#FDFAF5` | Lightest surface (cards) |
| 100 | `#F8F3EA` | Page background (warm paper) |
| 200 | `#F0E9DA` | Borders, inputs, inset areas |
| 300 | `#E4D9C8` | Strong borders, dividers |
| 400 | `#C8BAA4` | Placeholder text, disabled |
| 500 | `#A89880` | Muted text, timestamps |
| 600 | `#7A6E5F` | Secondary text, labels |
| 700 | `#5A5048` | Strong secondary text |
| 800 | `#3D3530` | Dark surfaces |
| 900 | `#2C2416` | Primary text, dark buttons |
| 950 | `#1A1510` | Near-black background (dark mode) |

**Brand** (Amber-orange — warm, editorial, not neon)

| Step | Hex |
|------|-----|
| 50  | `#FDF6EC` — accent subtle bg |
| 100 | `#FAEBD4` — slot tag background |
| 200 | `#F5D4A8` |
| 300 | `#EDB96E` |
| 400 | `#E09A42` — dark mode accent |
| 500 | `#C17B3A` — primary accent |
| 600 | `#A36228` — slot tag text |
| 700 | `#844D1E` |
| 800 | `#653B17` |
| 900 | `#472A10` |
| 950 | `#2A1808` — dark mode accent subtle |

**Status Colors**

| Color | 50 (bg tint) | 500 (foreground) | 900 (dark tint) |
|-------|-------------|-----------------|-----------------|
| Red   | `#FEF2F2` | `#DC4A4A` | `#7F1D1D` |
| Green | `#F0FDF4` | `#4A9B6A` | `#14532D` |
| Amber | `#FFFBEB` | `#D97706` | `#78350F` |

**Plan Tier Tints** (observed from screenshot)

| Tier | Background | Text |
|------|-----------|------|
| Free | `#E8F0E0` | `#3A6B2A` |
| Team | `#E0EAF5` | `#2A4A7A` |
| Studio | `#EDE0F5` | `#5A2A7A` |

### Spacing Primitives

`0, 2, 4, 8, 12, 16, 20, 24, 32, 48, 64, 96`

### Radii Primitives

`0, 4, 6, 8, 12, 16, 999`

---

## 1. TYPOGRAPHY

### Font Stack

| Role | Font | Fallback | Weight | Use |
|------|------|----------|--------|-----|
| **Display / UI** | `"DM Sans"` | `system-ui, -apple-system, sans-serif` | 400–600 | All UI text, headings, body, labels |
| **Mono / Code** | `"JetBrains Mono"` | `"Fira Code", "Cascadia Code", monospace` | 400 | Template slots `{{var}}`, code, technical IDs |

> Note: DM Sans serves both display and body roles. No separate display typeface — hierarchy comes from size and weight, not font switching.

### Mono Font Rules

**`mono_for_code`: true** · **`mono_for_metrics`: false**

Use JetBrains Mono for: template slot tags `{{variable}}`, code blocks, file paths, API endpoints, technical identifiers. Use DM Sans for: all numeric values (counts, percentages, pricing), timestamps, labels, and all prose.

The slot tag is the primary mono use case — it visually distinguishes template syntax from natural language in the editor.

### Type Scale

| Token | Size | Line Height | Letter Spacing | Weight | Use |
|-------|------|-------------|----------------|--------|-----|
| `--display` | 28px | 1.2 | -0.01em | 600 | Page titles, hero headings |
| `--heading` | 20px | 1.3 | -0.01em | 600 | Section headings, card titles |
| `--subheading` | 16px | 1.4 | 0em | 500 | Subsection titles, panel headers |
| `--body` | 14px | 1.6 | 0em | 400 | Body text, template content, descriptions |
| `--body-sm` | 13px | 1.5 | 0em | 400 | Secondary text, helper text, notes |
| `--caption` | 11px | 1.4 | 0em | 500 | Timestamps, footnotes, char counts |
| `--label` | 11px | 1.3 | 0.06em | 600 | Section labels (UPPERCASE), metadata keys |

### Typographic Rules

- Section labels (`TEMPLATE`, `AVAILABLE SLOTS`, `LIVE PREVIEW`) are always `--label` size, uppercase, `--text3` color
- Template content uses `--body` with generous `1.6` line height for readability
- Slot tags `{{variable}}` use JetBrains Mono at 12–13px, amber background pill
- Breadcrumbs use `--label` style: uppercase, letter-spaced, `--text3` color
- Never mix DM Sans and JetBrains Mono in the same sentence except for inline slot tags

---

## 2. COLOR SYSTEM (Semantic Tokens)

Semantic tokens reference the primitives above. Components use semantic tokens, never primitives directly.

### Primary Mode (Light — Warm Paper)

| Token | Primitive | Hex | Role |
|-------|-----------|-----|------|
| `--background` | `{neutral.100}` | `#F8F3EA` | Page background — warm paper |
| `--bg` | — | `var(--background)` | Shorthand alias |
| `--surface1` | `{neutral.50}` | `#FDFAF5` | Cards, panels, elevated containers |
| `--surface2` | `{neutral.100}` | `#F8F3EA` | Nested surfaces, grouped backgrounds |
| `--surface3` | `{neutral.200}` | `#F0E9DA` | Inputs, wells, inset areas |
| `--border` | `{neutral.200}` | `#F0E9DA` | Subtle dividers, card edges |
| `--border-visible` | `{neutral.300}` | `#E4D9C8` | Intentional borders, input outlines |
| `--text1` | `{neutral.900}` | `#2C2416` | Primary text — headings, body |
| `--text2` | `{neutral.600}` | `#7A6E5F` | Secondary text — descriptions, labels |
| `--text3` | `{neutral.500}` | `#A89880` | Tertiary text — placeholders, section labels |
| `--text4` | `{neutral.400}` | `#C8BAA4` | Disabled text, ghost elements |
| `--accent` | `{brand.500}` | `#C17B3A` | Amber — slot tags, CTAs, focus rings |
| `--accent-subtle` | `{brand.50}` | `#FDF6EC` | Tinted backgrounds for accent elements |
| `--success` | `{green.500}` | `#4A9B6A` | Confirmed, completed |
| `--warning` | `{amber.500}` | `#D97706` | Caution, pending |
| `--error` | `{red.500}` | `#DC4A4A` | Destructive, error |

### Secondary Mode (Dark — Warm Charcoal)

| Token | Primitive | Hex | Role |
|-------|-----------|-----|------|
| `--background` | `{neutral.950}` | `#1A1510` | Page background |
| `--surface1` | `{neutral.900}` | `#2C2416` | Cards, panels |
| `--surface2` | `{neutral.800}` | `#3D3530` | Nested surfaces |
| `--surface3` | `{neutral.700}` | `#5A5048` | Inputs, wells |
| `--border` | `{neutral.800}` | `#3D3530` | Subtle dividers |
| `--border-visible` | `{neutral.700}` | `#5A5048` | Intentional borders |
| `--text1` | `{neutral.50}` | `#FDFAF5` | Primary text |
| `--text2` | `{neutral.300}` | `#E4D9C8` | Secondary text |
| `--text3` | `{neutral.500}` | `#A89880` | Tertiary text |
| `--text4` | `{neutral.600}` | `#7A6E5F` | Disabled text |
| `--accent` | `{brand.400}` | `#E09A42` | Amber — brighter in dark mode |
| `--accent-subtle` | `{brand.950}` | `#2A1808` | Tinted backgrounds |
| `--success` | `{green.500}` | `#4A9B6A` | Positive states |
| `--warning` | `{amber.500}` | `#D97706` | Caution states |
| `--error` | `{red.500}` | `#DC4A4A` | Error states |

### Accent & Status Tints

| Token | Light | Dark | Usage |
|-------|-------|------|-------|
| `--accent-subtle` | `#FDF6EC` | `#2A1808` | Slot tag backgrounds, accent tints |
| `--success-bg` | `#F0FDF4` | `#052e16` | Success tinted backgrounds |
| `--warning-bg` | `#FFFBEB` | `#1c1400` | Warning tinted backgrounds |
| `--error-bg` | `#FEF2F2` | `#1c0000` | Error tinted backgrounds |

### Color Usage Rules

- Amber (`--accent`) appears only on: slot tags, primary buttons, focus rings, active states, links
- Plan tier badges use their own fixed tints (free/team/studio) — not the semantic accent
- Never use `--accent` for decorative purposes — it must always signal interactivity or template syntax
- Background is always `--background` (warm paper). Never tint section backgrounds with accent

---

## 3. SPACING

### Scale (8px base)

| Token | Value | Use |
|-------|-------|-----|
| `--space-2xs` | 2px | Optical adjustments, tight icon gaps |
| `--space-xs` | 4px | Icon-to-label gaps, slot tag internal padding |
| `--space-sm` | 8px | Component internal padding, list item gaps |
| `--space-md` | 16px | Card padding, standard element gaps |
| `--space-lg` | 24px | Card padding (generous), section item gaps |
| `--space-xl` | 32px | Section spacing |
| `--space-2xl` | 48px | Major section breaks |
| `--space-3xl` | 64px | Screen section divisions |
| `--space-4xl` | 96px | Hero breathing room |

---

## 4. BORDERS & RADII

### Radii Scale

| Token | Value | Use |
|-------|-------|-----|
| `--radius-element` | 4px | Checkboxes, small icons, tight controls |
| `--radius-control` | 6px | Buttons, inputs, toggles |
| `--radius-component` | 8px | Cards, panels, list containers |
| `--radius-container` | 12px | Modals, sheets, popovers |
| `--radius-pill` | 999px | Slot tags `{{var}}`, plan badges, status pills |

### Border Treatment

| Element | Border |
|---------|--------|
| Cards / Surfaces | `1px solid var(--border)` |
| Buttons (secondary) | `1px solid var(--border-visible)` |
| Inputs | `1px solid var(--border-visible)` |
| Slot Tags | none (background-only) |
| Modals / Sheets | `1px solid var(--border-visible)` |

Corner philosophy: **soft-but-not-round**. Cards at 8px feel document-like. Pills at 999px for tags only. Never exceed 12px on rectangular containers.

---

## 5. ELEVATION & SHADOWS

| Level | Light Mode | Dark Mode | Use |
|-------|-----------|----------|-----|
| **0** | None | None | Flat inline elements, section labels |
| **1** | `0 1px 3px rgba(44,36,22,0.06), 0 1px 2px rgba(44,36,22,0.04)` | `0 1px 3px rgba(0,0,0,0.25)` | Standard cards, panels |
| **2** | `0 4px 12px rgba(44,36,22,0.08), 0 2px 4px rgba(44,36,22,0.05)` | `0 4px 12px rgba(0,0,0,0.35)` | Floating menus, popovers |
| **3** | `0 8px 32px rgba(44,36,22,0.12), 0 4px 8px rgba(44,36,22,0.06)` | `0 8px 32px rgba(0,0,0,0.45)` | Modals, dialogs |

Elevation strategy: **subtle**. Cards always have a 1px border AND a level-1 shadow. The shadow uses warm brown tones (`rgba(44,36,22,...)`) in light mode — never pure black shadows.

---

## 6. MOTION & INTERACTION

### Personality

Smooth and calm. Transitions feel like turning a page — deliberate, not snappy. No spring physics, no bounce. The tool is for focused work; motion should not distract.

### Timing

| Type | Duration | Easing | Use |
|------|----------|--------|-----|
| **Micro** | 120ms | `ease-in-out` | Button press, color change, toggle |
| **Standard** | 200ms | `ease-in-out` | Card expand, input focus, dropdown |
| **Emphasis** | 300ms | `ease-in-out` | Modal present, panel slide, page transition |

### Interaction States

- **Hover:** Background lightens by one step (e.g. `--surface1` → `--surface2` reversed). No scale transforms.
- **Focus:** `2px solid var(--accent)` outline with `2px offset`. Amber focus ring is the primary accessibility signal.
- **Active/Pressed:** Background darkens by one step. No scale.
- **Disabled:** `opacity: 0.4`. No interaction. Maintains layout.

---

## 7. ICONOGRAPHY

> **⚠ Fallback disclosure.** Icons in the generated preview come from Lucide, selected as the closest match. They are not the brand's real glyphs — Birchline uses minimal iconography and relies primarily on typography.

### Observed style (the brand's actual icons)

| Attribute | Value |
|-----------|-------|
| Description | Minimal usage. Breadcrumb uses '/' text separator. No icon library visible — typography carries navigation. |
| Stroke weight | regular (1.5px) |
| Corner treatment | soft |
| Fill style | outline |
| Form language | geometric |
| Visual density | minimal |

### Fallback kit (what the preview actually renders)

- **Kit:** Lucide
- **Weight / variant:** regular (1.5px stroke)
- **Match score:** high
- **Why this kit:** Lucide's clean geometric outlines at 1.5px stroke match the minimal, precise character of the Birchline UI. The kit's restraint aligns with a brand that uses icons sparingly.
- **CDN:** `https://unpkg.com/lucide-static/font/lucide.css`
- **Usage:** `<i class="lucide lucide-{name}"></i>`

### Sizes

| Context | Size |
|---------|------|
| Inline with body text | 14px |
| Buttons | 14px |
| Navigation / breadcrumb | 12px |

### Color rule

Icons inherit `--text2` by default. Interactive icons use `--accent`. Never use icons in multiple colors on the same surface.

### Don't

- Never use icons as primary navigation labels — text breadcrumbs are the Birchline pattern
- Never claim these are the brand's real icons — they are a best-match fallback
