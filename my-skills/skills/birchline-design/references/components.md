# Birchline — Components

## 1. BUTTONS

### Variants

| Variant | Background | Text | Border | Radius | Height |
|---------|-----------|------|--------|--------|--------|
| Primary | `--text1` (#2C2416) | `--surface1` | none | 6px | 32px |
| Secondary | `--surface3` | `--text2` | `1px solid var(--border-visible)` | 6px | 32px |
| Ghost | transparent | `--text2` | none | 6px | 32px |
| Destructive | `#FEF2F2` | `--error` | `1px solid rgba(220,74,74,0.3)` | 6px | 32px |

### Specs

| Property | Value |
|----------|-------|
| Height (large) | 32px |
| Height (small) | 26px |
| Padding (large) | 8px 16px |
| Padding (small) | 4px 10px |
| Font | `DM Sans` 500, 13px |
| Min touch target | 44px |

### States

| State | Change |
|-------|--------|
| **Hover** | Primary: `--neutral-800`. Secondary: `--surface2`. Ghost: `--surface3` bg |
| **Active / Pressed** | Opacity 0.85 |
| **Disabled** | Opacity 0.4, no interaction |
| **Focus** | `2px solid var(--accent)` outline, 2px offset |

---

## 2. SLOT TAGS (Birchline-specific)

The primary brand component. Template variables rendered as amber pill tags.

### Specs

| Property | Value |
|----------|-------|
| Background | `--accent-subtle` (#FDF6EC) |
| Text color | `--accent` (#C17B3A) in light / `#E09A42` in dark |
| Font | `JetBrains Mono`, 12px, weight 400 |
| Padding | 2px 8px |
| Radius | 999px (pill) |
| Border | none |
| Display | inline-flex |

### Usage

Render any `{{variable_name}}` in template text as a slot tag. The double-brace syntax is the trigger. Never render slot syntax as plain text.

```html
<span class="slot-tag">{{customer_name}}</span>
```

---

## 3. PLAN BADGES

Status badges for subscription tiers. Fixed tints, not semantic accent.

### Variants

| Tier | Background | Text | Font |
|------|-----------|------|------|
| FREE | `#E8F0E0` | `#3A6B2A` | DM Sans 600, 11px, uppercase |
| TEAM | `#E0EAF5` | `#2A4A7A` | DM Sans 600, 11px, uppercase |
| STUDIO | `#EDE0F5` | `#5A2A7A` | DM Sans 600, 11px, uppercase |

### Specs

| Property | Value |
|----------|-------|
| Height | 20px |
| Padding | 2px 8px |
| Radius | 999px |
| Letter spacing | 0.04em |
| Text transform | uppercase |

---

## 4. CARDS / SURFACES

### Standard Card (Template Panel, Preview Panel)

- Background: `--surface1`
- Border: `1px solid var(--border)`
- Radius: 8px
- Padding: 20px
- Shadow: level-1 (warm brown tint)

### Section Card (Sample Preview)

- Background: `--surface1`
- Border: `1px solid var(--border-visible)`
- Radius: 8px
- Padding: 16px
- Shadow: none (border carries the depth)

### Content Layout

- Title: `--subheading`, `--text1`
- Description: `--body`, `--text2`
- Metadata: `--caption`, `--text3`
- Internal spacing between elements: `--space-sm` (8px)

---

## 5. INPUTS / TEXTAREA

### Template Textarea

| Property | Value |
|----------|-------|
| Background | `--surface1` |
| Border (default) | `1px solid var(--border)` |
| Border (focus) | `1px solid var(--accent)` |
| Border (error) | `1px solid var(--error)` |
| Radius | 8px |
| Padding | 16px |
| Font | `DM Sans`, `--body` (14px) |
| Line height | 1.6 |
| Placeholder color | `--text3` |
| Min height | 200px |
| Resize | vertical |

### Text Field (Standard)

| Property | Value |
|----------|-------|
| Height | 32px |
| Background | `--surface3` |
| Border (default) | `1px solid var(--border-visible)` |
| Border (focus) | `1px solid var(--accent)` |
| Radius | 6px |
| Padding | 6px 12px |
| Font | `DM Sans`, `--body-sm` (13px) |
| Placeholder color | `--text3` |

### States

| State | Treatment |
|-------|-----------|
| **Default** | `1px solid var(--border-visible)` |
| **Focus** | `1px solid var(--accent)`. Amber focus ring. |
| **Error** | `1px solid var(--error)`. Error text below in `--error`, `--caption` |
| **Disabled** | Opacity 0.4, no interaction |

---

## 6. SECTION LABELS

The uppercase dividers that separate template zones.

| Property | Value |
|----------|-------|
| Font | `DM Sans`, 11px, weight 600 |
| Text transform | uppercase |
| Letter spacing | 0.06em |
| Color | `--text3` |
| Margin bottom | 8px |

Examples: `TEMPLATE`, `AVAILABLE SLOTS`, `LIVE PREVIEW — 3 SAMPLE TICKETS`

---

## 7. BREADCRUMB

| Property | Value |
|----------|-------|
| Font | `DM Sans`, `--label` (11px, 600, uppercase, 0.06em) |
| Link color | `--text3` |
| Link hover | `--text2` |
| Separator | `/` text character |
| Separator color | `--text3` |
| Separator spacing | 6px each side |
| Current page | `--text2` |

Example: `BIRCHLINE / EDITOR / PROMPT-TUNER`

---

## 8. LISTS / DATA ROWS

### Standard Row

| Property | Value |
|----------|-------|
| Min height | 36px |
| Padding | 8px 12px |
| Divider | `1px solid var(--border)` |
| Label font | `DM Sans`, `--body`, `--text1` |
| Value font | `DM Sans`, `--body`, `--text2` |

### Interaction States

| State | Treatment |
|-------|-----------|
| **Default** | Transparent background |
| **Hover** | `--surface2` background |
| **Selected** | `--accent-subtle` background, `--accent` left border 2px |

---

## 9. NAVIGATION / BREADCRUMB BAR

### Top Bar

| Property | Value |
|----------|-------|
| Height | 40px |
| Background | `--background` |
| Border bottom | `1px solid var(--border)` |
| Padding | 0 24px |

### Breadcrumb States

| State | Treatment |
|-------|-----------|
| **Active (current)** | `--text2`, no underline |
| **Inactive (parent)** | `--text3`, hover → `--text2` |

---

## 10. TAGS / CHIPS (Generic)

| Property | Value |
|----------|-------|
| Height | 22px |
| Padding | 2px 8px |
| Radius | 4px |
| Font | `DM Sans`, `--caption` (11px), weight 500 |
| Background | `--surface3` |
| Text color | `--text2` |
| Border | `1px solid var(--border-visible)` |

### Selected State

- Background: `--accent-subtle`
- Text: `--accent`
- Border: `1px solid var(--accent)`

### Status Variants

Use status colors: `--success-bg` + `--success`, `--warning-bg` + `--warning`, `--error-bg` + `--error`.

---

## 11. OVERLAYS

### Modal / Dialog

| Property | Value |
|----------|-------|
| Background | `--surface1` |
| Radius | 12px |
| Shadow | level-3 |
| Backdrop | `rgba(44, 36, 22, 0.4)` blur(4px) |
| Max width | 480px |
| Padding | 24px |
| Close button | Ghost button, top-right |

### Dropdown / Popover

| Property | Value |
|----------|-------|
| Background | `--surface1` |
| Radius | 8px |
| Shadow | level-2 |
| Border | `1px solid var(--border-visible)` |
| Item height | 32px |
| Item padding | 6px 12px |
| Selected indicator | `--accent-subtle` bg + `--accent` text |

---

## 12. STATE PATTERNS

### Empty State

- Layout: centered, 48px top padding
- Icon: Lucide icon at 32px, `--text3` color
- Headline: `--subheading`, `--text2`
- Description: `--body`, `--text3`, max 2 lines
- CTA: primary button, 16px below description

### Loading

- Inline: spinner at 16px, `--accent` color
- Full screen: centered spinner, `--text3` color
- Content appearance: `opacity: 0` → `opacity: 1`, 200ms ease-in-out

### Error

- Inline (field): `--error` text in `--caption` below element
- Screen-level: centered card with error icon, `--error` headline, retry button
- Tone: factual, not apologetic. "Could not load template." not "Oops!"

### Disabled

- Opacity 0.4, no interaction, maintains layout
- Borders fade to `--border` default
- No hover/focus states

---

## 13. CHAR COUNT / TOKEN COUNT

The template editor shows character and token counts.

| Property | Value |
|----------|-------|
| Font | `DM Sans`, `--caption` (11px) |
| Color | `--text3` |
| Position | top-right of textarea |
| Format | `303 chars · ~91 tokens` |
| Separator | `·` (middle dot) |

---

## 14. TOGGLE / SWITCH

### Specs

| Property | Value |
|----------|-------|
| Track width | 32px |
| Track height | 18px |
| Track radius | 999px |
| Thumb size | 14px |
| Thumb radius | 50% |
| Thumb offset | 2px |
| Label position | right |
| Label gap | 8px |
| Label font | `DM Sans`, `--body`, `--text1` |

### States

| State | Track Background | Thumb |
|-------|-----------------|-------|
| **Off** | `--border-visible` | `--surface1` white |
| **On** | `--accent` | `--surface1` white |
| **Disabled** | Opacity 0.4 | — |
| **Focus** | `2px solid var(--accent)` outline | — |

---

## 15. TOOLTIP

| Property | Value |
|----------|-------|
| Background | `--text1` (#2C2416) |
| Text color | `--surface1` |
| Font | `DM Sans`, `--caption` (11px) |
| Radius | 4px |
| Padding | 4px 8px |
| Max width | 240px |
| Arrow | 4px triangle |
| Delay (show) | 400ms |
| Delay (hide) | 100ms |
| Shadow | level-2 |
