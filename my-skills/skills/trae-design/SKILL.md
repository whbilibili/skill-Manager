---
name: trae-design
description: "This skill should be used when the user explicitly says 'Trae style', 'Trae design', '/trae-design', or directly asks to use/apply the Trae design system. NEVER trigger automatically for generic UI or design tasks."
version: 1.0.0
allowed-tools: [Read, Write, Edit, Glob, Grep]
# ^ allowed-tools is Claude Code specific. Codex ignores it but tolerates its presence.
---

# trae-design

You are a senior product designer. When this skill is active, every UI decision follows this design language.

**Before starting any design work, declare which fonts are required and how to load them** (see `platform-mapping.md`). Never assume fonts are already available.

---

## 1. DESIGN PHILOSOPHY

**Terminal cursor on a cold-blue stage.**

Trae is ByteDance's AI-native IDE — a tool that thinks alongside you. The design language is dense, immersive, and precision-engineered. Every surface is a cold blue-black stage; every interaction is deliberate. A single flash of **Intelligent Green (#10B981)** signals the machine is alive.

This is not a friendly consumer app. This is a cockpit. The emptiness is the statement — negative space is structural, not decorative. Information density is high, but never cluttered. Every pixel earns its place through function.

Core tenets:

- **Density over decoration.** Pack information tight. Developers scan, they don't browse. Whitespace is for hierarchy, not comfort.
- **Signal through restraint.** The brand color appears sparingly. When green lights up, it means something — AI is responding, a build succeeded, a suggestion is ready. Overuse kills the signal.
- **Cold precision.** The palette is cool-blue-tinted neutrals. No warm grays. The temperature says "machine" — reliable, fast, exact.
- **AI as co-pilot, not spectacle.** AI features integrate seamlessly into the editing flow. No glowing orbs, no animated mascots. The AI is present in the cursor blink, the inline suggestion, the quiet confidence of a tool that already knows what you need.

---

## 2. CRAFT RULES — HOW TO COMPOSE

**Layout & Density**
Use tight spacing (4–8px gaps between related elements, 16–24px between sections). Trae UIs feel like code editors: vertically compact, horizontally structured. Sidebars are narrow (240–280px). Content areas fill remaining space. Never center-align body text — left-align everything except hero headlines.

**Color Discipline**
The background is always `#171B26` in dark mode. Surfaces layer upward: `#262A37` → `#2A2E3E` → `#363B4E`. Never skip a surface level. Borders are subtle — same color as the surface below (`#262A37`) for quiet separation, or one step brighter (`#363B4E`) when the boundary must be visible. The brand green appears only for: primary CTAs, active/selected states, success indicators, and AI-activity signals. Purple (`#7563E7`) is reserved for badges, version indicators, and secondary categorization. Blue (`#387BFF`) is for links and progress bars only.

**Typography Pairing**
Inter handles all display and body text — it's neutral, highly legible at small sizes, and disappears into the content. JetBrains Mono handles code snippets, terminal output, file paths, keyboard shortcuts, and numeric metrics. When Inter and JetBrains Mono appear on the same line (e.g., a label next to a code value), align them by baseline and let the mono text be 1px smaller.

**Component Posture**
Buttons are compact (10px 20px padding, 6px radius) — never tall or pill-shaped. Cards are flat rectangles (8px radius, 1px border, no shadow in dark mode). Inputs sink into the background (`#171B26`) with a quiet border that brightens to green on focus. Tags are small, muted chips (4px radius, 12px font). Everything feels like it belongs in a toolbar, not a marketing page.

**Hierarchy Through Luminance**
In dark mode, hierarchy is controlled by text luminance, not size or weight. `text1` (#C9D1D9) for primary content, `text2` (#9599A6) for secondary, `text3` (#737780) for tertiary, `text4` (#5C6373) for disabled/placeholder. Use font-weight changes sparingly — medium (500) for emphasis, regular (400) for everything else, semibold (600) only for display headings.

**The Green Rule**
If more than ~15% of visible pixels are green, you've overused it. Green is a signal, not a theme. A page should feel monochromatic blue-gray with strategic green punctuation.

---

## 3. ANTI-PATTERNS — WHAT TO NEVER DO

- **No warm grays.** Every neutral must have a blue undertone. Warm grays (#888, #aaa) break the cold-stage illusion instantly.
- **No pill-shaped buttons.** Maximum border-radius on a button is 6px. Pill shapes (999px radius) belong to consumer apps, not developer tools.
- **No drop shadows in dark mode.** Elevation in dark mode comes from surface color stepping, not shadows. Shadows are invisible against dark backgrounds and add visual noise. (Light mode may use subtle shadows sparingly.)
- **No gradient backgrounds.** Surfaces are flat, solid colors. Gradients on backgrounds or cards feel decorative and break the precision aesthetic. The only acceptable gradient is a subtle vignette on hero stages.
- **No large border-radius on containers.** Cards max at 8px, modals at 12px. Anything rounder looks soft and consumer-grade.
- **No colorful illustrations or mascots.** If you need an empty state, use a single muted icon and a line of `text3` copy. No cartoon characters, no multi-color SVG scenes.
- **No centered body text.** Left-align all body copy, labels, and descriptions. Center alignment is only for hero headlines and single-line CTAs.
- **No green-on-green.** Never place green text on a green-tinted background. The accent must always contrast against neutral surfaces.
- **No animated AI indicators that loop forever.** If AI is processing, show a brief mechanical animation (120ms pulse or cursor blink). Kill it the moment the response arrives. Persistent animation is distracting in a coding environment.
- **No font mixing beyond the two families.** Inter + JetBrains Mono only. No third typeface for "decorative" purposes.

---

## 4. COLOR SYSTEM

### 4.1 Dark Mode (Primary)

| Token | Value | Usage |
|-------|-------|-------|
| `background` | `#171B26` | Page/app background, deepest layer |
| `surface1` | `#262A37` | Cards, sidebar, panels |
| `surface2` | `#2A2E3E` | Hover states, nested panels |
| `surface3` | `#363B4E` | Active states, visible borders |
| `border` | `#262A37` | Quiet dividers (same as surface1) |
| `border_visible` | `#363B4E` | Explicit boundaries |
| `text1` | `#C9D1D9` | Primary text |
| `text2` | `#9599A6` | Secondary text |
| `text3` | `#737780` | Tertiary/caption text |
| `text4` | `#5C6373` | Disabled/placeholder text |
| `accent` | `#10B981` | Brand green — CTAs, active states, AI signals |
| `accent_subtle` | `#022C22` | Green-tinted background for badges/highlights |

### 4.2 Light Mode

| Token | Value | Usage |
|-------|-------|-------|
| `background` | `#F0F2F5` | Page background |
| `surface1` | `#FFFFFF` | Cards, panels |
| `surface2` | `#E0E3EA` | Hover, nested panels |
| `surface3` | `#C9D1D9` | Active states, visible borders |
| `border` | `#E0E3EA` | Quiet dividers |
| `border_visible` | `#C9D1D9` | Explicit boundaries |
| `text1` | `#171B26` | Primary text |
| `text2` | `#5C6373` | Secondary text |
| `text3` | `#737780` | Tertiary text |
| `text4` | `#9599A6` | Disabled/placeholder |
| `accent` | `#059669` | Brand green (darker for light bg contrast) |
| `accent_subtle` | `#ECFDF5` | Green-tinted background |

### 4.3 Secondary Accents

| Color | Value | Usage |
|-------|-------|-------|
| Purple | `#7563E7` | Badges, version tags, secondary indicators |
| Blue | `#387BFF` | Links, progress bars, informational highlights |

### 4.4 Semantic Status

| Status | Value | Usage |
|--------|-------|-------|
| Success | `#10B981` | Build passed, tests green, save confirmed |
| Warning | `#EB9B61` | Deprecation notices, lint warnings |
| Error | `#CC4B53` | Build failures, validation errors, destructive actions |

---

## 5. TYPOGRAPHY

### 5.1 Font Stack

| Role | Family | Fallback |
|------|--------|----------|
| Display & Body | **Inter** | -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif |
| Code & Metrics | **JetBrains Mono** | "SF Mono", "Fira Code", "Cascadia Code", monospace |

### 5.2 Type Scale

| Token | Family | Size | Weight | Line Height | Usage |
|-------|--------|------|--------|-------------|-------|
| `display` | Inter | 36px | 600 (semibold) | 1.1 | Hero headlines, page titles |
| `heading-1` | Inter | 24px | 600 | 1.2 | Section headers |
| `heading-2` | Inter | 20px | 500 | 1.3 | Subsection headers |
| `heading-3` | Inter | 16px | 500 | 1.4 | Card titles, group labels |
| `body` | Inter | 14px | 400 | 1.5 | Default body text |
| `body-strong` | Inter | 14px | 500 | 1.5 | Emphasized body text |
| `caption` | Inter | 12px | 400 | 1.4 | Timestamps, metadata |
| `mono` | JetBrains Mono | 13px | 400 | 1.5 | Code, file paths, terminal |
| `mono-small` | JetBrains Mono | 12px | 400 | 1.4 | Inline code, keyboard shortcuts |
| `metric` | JetBrains Mono | 20px | 500 | 1.2 | Dashboard numbers, stats |

---

## 6. SPACING

Spacing follows a compressed scale tuned for information-dense developer UIs.

| Token | Value | Usage |
|-------|-------|-------|
| `2xs` | 2px | Hairline gaps, icon-to-badge offset |
| `xs` | 4px | Inline element gaps, tag padding-y |
| `sm` | 8px | Compact component padding, related-item gaps |
| `md` | 16px | Standard card padding, section gaps |
| `lg` | 24px | Panel padding, major section separation |
| `xl` | 32px | Page-level section breaks |
| `2xl` | 48px | Hero section padding |
| `3xl` | 64px | Major landmark separation |
| `4xl` | 96px | Full-bleed hero vertical padding |

---

## 7. BORDER RADII

Trae uses sharp-to-soft corners. Never pill-shaped.

| Token | Value | Usage |
|-------|-------|-------|
| `element` | 4px | Checkboxes, small controls, tags, badges |
| `control` | 6px | Buttons, inputs, dropdowns, toggles |
| `component` | 8px | Cards, panels, popovers |
| `container` | 12px | Modals, sheets, dialog boxes |

Maximum radius on any interactive element is 12px. No `border-radius: 999px` anywhere.

---

## 8. ELEVATION

**Strategy: Flat.** In dark mode, depth is communicated through surface color stepping, not shadows.

| Level | Dark Mode | Light Mode |
|-------|-----------|------------|
| 0 | `none` | `none` |
| 1 | `none` | `0 1px 3px rgba(0,0,0,0.08)` |
| 2 | `none` | `0 4px 12px rgba(0,0,0,0.12)` |
| 3 | `0 8px 24px rgba(0,0,0,0.5)` | `0 8px 24px rgba(0,0,0,0.16)` |

Level 3 in dark mode is reserved for critical overlays (command palette, modal dialogs) where the element must visually "lift" above the stage. All other dark-mode elevation is achieved by stepping to a brighter surface color.

---

## 9. MOTION

**Personality: Mechanical.** Animations are crisp, functional, and brief. Nothing bounces, nothing overshoots. The IDE responds like a precision instrument.

| Token | Value | Usage |
|-------|-------|-------|
| `duration-fast` | 120ms | Hover states, toggle flips, micro-interactions |
| `duration-normal` | 180ms | Panel slides, dropdown opens, tab switches |
| `duration-slow` | 300ms | Modal entrances, page transitions, complex reveals |
| `easing` | `ease-out` | All transitions — fast start, gentle stop |

Rules: never use `ease-in` (feels sluggish), never use `linear` (feels robotic in a bad way), never exceed 300ms for any UI transition. If something takes longer than 300ms, it should be a skeleton/loading state, not an animation.

---

## 10. ICONOGRAPHY

**Style: Geometric outline, 2px stroke, rounded terminals.**

| Property | Value |
|----------|-------|
| Fallback kit | **Lucide** |
| Stroke weight | 2px (default) |
| Grid | 24×24px |
| Corner treatment | Soft (rounded caps and joins) |
| Fill style | Outline only (no filled variants) |
| CDN | `https://unpkg.com/lucide-static@1.8.0/font/lucide.css` |
| Class prefix | `icon icon-` |

Icons are always rendered in `text2` (#9599A6) by default, stepping to `text1` (#C9D1D9) on hover/active, and to `accent` (#10B981) when representing an active/selected state. Never use colored icons for decoration — color on an icon must carry semantic meaning.

> **Disclaimer:** Icons are a best-match fallback from the Lucide kit. Trae's actual product icons are proprietary.

---

## 11. HERO STAGE

**Preset: Grid-on-Dark.**

The hero section is a dark stage with a subtle geometric grid pattern. The background is `#171B26` with faint grid lines in `#262A37`. A centered headline in Inter semibold dominates the upper portion. Below the text, a product screenshot (device mockup) floats as the visual anchor.

Construction rules:

- **Background:** Solid `#171B26` with a CSS grid pattern overlay (`background-image: linear-gradient(#262A37 1px, transparent 1px), linear-gradient(90deg, #262A37 1px, transparent 1px); background-size: 40px 40px;`). Optionally add a subtle radial vignette from center (slightly lighter) to edges (darker) for depth.
- **Headline:** Large display text (36–48px, Inter 600), color `text1`. Positioned in the upper 40% of the hero. One accent word may be colored `#10B981` for emphasis.
- **Subheadline:** Body text (16–18px, Inter 400), color `text2`. One line, directly below headline with `sm` (8px) gap.
- **CTA:** Primary button (green) centered below subheadline with `lg` (24px) gap. Optionally paired with a ghost button.
- **Product shot:** A device frame or browser mockup screenshot centered below the CTA area. The screenshot should show a dark IDE interface. Apply `border-radius: 8px` and a subtle `border: 1px solid #262A37`. No drop shadow — the grid pattern provides enough visual context.
- **Safe zone:** Keep the center 60% of the hero width clear for text readability. Grid pattern is visible but never competes with text.

> **Disclaimer:** Product screenshots are simulated with CSS. The actual Trae IDE interface is proprietary.

---

## 12. WORKFLOW

1. **Declare fonts** — check `platform-mapping.md` for loading instructions. You need Inter (400, 500, 600) and JetBrains Mono (400, 500).
2. **Set tokens** — apply CSS custom properties or framework variables from `tokens.md`. Start with dark mode as the default.
3. **Build components** — use specs from `components.md`. Key components: buttons (primary/secondary/ghost), cards, inputs, tags, toggles.
4. **Check hierarchy** — squint test: can you tell what's most important? In dark mode, the brightest text and the single green accent should draw the eye first.
5. **Verify both modes** — light and dark must both feel intentional, not derived. Light mode is not "invert dark mode" — it has its own surface/text mapping.
6. **Test extremes** — long text, empty states, single item, 100 items. Developer tools encounter extreme data regularly.
7. **Platform-adapt** — consult `platform-mapping.md` for output conventions (HTML/CSS, React/Tailwind, SwiftUI).

---

## 13. COMPONENT QUICK REFERENCE

These are the core component specs. Full details with variants and states are in `components.md`.

### Primary Button
```
background: #10B981 → hover: #059669
color: #FFFFFF
padding: 10px 20px
border-radius: 6px
font: Inter 500 14px
transition: background 120ms ease-out
```

### Secondary Button
```
background: #262A37 → hover: #2A2E3E
color: #C9D1D9
padding: 10px 20px
border: 1px solid #363B4E
border-radius: 6px
font: Inter 500 14px
```

### Ghost Button
```
background: transparent → hover: #2A2E3E
color: #C9D1D9
padding: 10px 16px
border-radius: 6px
font: Inter 400 14px
```

### Card
```
background: #262A37
border: 1px solid #262A37
border-radius: 8px
padding: 16px
```

### Text Input
```
background: #171B26
border: 1px solid #262A37 → focus: 1px solid #10B981
border-radius: 6px
height: 36px
padding: 8px 12px
font: Inter 400 14px
color: #C9D1D9
placeholder-color: #5C6373
```

### Tag / Badge
```
background: #2A2E3E
color: #C9D1D9
padding: 4px 10px
border-radius: 4px
font: Inter 400 12px
```

### Toggle
```
track: 36×20px, radius 10px
thumb: 16px circle
off: track #363B4E, thumb #9599A6
on: track #10B981, thumb #FFFFFF
transition: 120ms ease-out
```

---

## 14. REFERENCE FILES

| File | Contains |
|------|----------|
| `tokens.md` | Fonts, type scale, color system (light + dark), spacing, radii, elevation, motion, iconography — all as copy-paste-ready variables |
| `components.md` | Cards, buttons, inputs, lists, navigation, tags, toggles, overlays, state patterns — full specs with all variants |
| `platform-mapping.md` | HTML/CSS, SwiftUI, React/Tailwind — platform-specific code snippets and font loading instructions |
