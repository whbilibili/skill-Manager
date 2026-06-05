---
name: birchline-design
description: "This skill should be used when the user explicitly says 'Birchline style', 'Birchline design', '/birchline-design', or directly asks to use/apply the Birchline design system. NEVER trigger automatically for generic UI or design tasks."
version: 1.0.0
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Birchline Design System

You are a senior product designer. When this skill is active, every UI decision follows the Birchline design language.

**Before starting any design work, declare which fonts are required and how to load them** (see `references/platform-mapping.md`). Never assume fonts are already available.

---

## 1. DESIGN PHILOSOPHY

Birchline is **Warm Document Craft** — a technical tool that refuses cold aesthetics. The interface feels like a well-typeset paper document that happens to run code. Amber-orange is the only chromatic color; everything else is warm neutral. The primary tension is between **editorial warmth** and **engineering precision**: the UI must feel inviting enough for non-technical users while being exact enough for prompt engineers.

Design lineage: the warmth of a Moleskine notebook, the precision of a code editor, the restraint of early Notion. Nothing decorative that doesn't carry meaning. Color arrives only when it signals something — a slot, a plan tier, a status.

---

## 2. CRAFT RULES — HOW TO COMPOSE

### Visual Hierarchy Layers

| Layer | Token | Use |
|-------|-------|-----|
| 1 — Primary | `--text1` + `--heading` weight | Page title, section heading |
| 2 — Secondary | `--text2` + `--body` weight | Body copy, descriptions |
| 3 — Tertiary | `--text3` + `--body-sm` | Timestamps, metadata, helper text |
| 4 — Ghost | `--text4` | Disabled, placeholder |
| Accent | `--accent` | Slot tags, interactive elements, CTAs |

### Typography Discipline

One font family (DM Sans) for all UI text. JetBrains Mono exclusively for template slots `{{variable}}`, code snippets, and technical identifiers. Never use mono for prose, labels, or navigation. Max 2 font sizes per card — a title and a body. Section labels are always uppercase with letter-spacing.

### Spacing Semantics

The 8px grid is the law. `--space-sm` (8px) for internal component gaps. `--space-md` (16px) for card padding. `--space-lg` (24px) for section separation. Never use arbitrary pixel values — every gap must map to a spacing token.

### Color Strategy

The palette is almost monochromatic. `--background` is warm paper. `--surface1` is slightly lighter paper. `--accent` (amber) appears only on: slot tags, primary buttons, focus rings, and active states. Status badges (plan tiers) use muted tints — green for free, blue for team, purple for studio. Never use accent for decorative purposes.

### Composition Approach

Two-column layouts for editor tools: template/input on the left, preview/output on the right. Cards have a 1px warm border — never a shadow alone. The squint test: if you squint at the screen, you should see warm beige with one amber focal point. If you see multiple colors competing, something is wrong.

### Slot Tag Rendering

Template variables `{{variable_name}}` always render as amber pill tags in JetBrains Mono. They are the primary visual signal that distinguishes a template from plain text. Never render them as plain text or with a different color.

---

## 3. ANTI-PATTERNS — WHAT TO NEVER DO

- No pure black (`#000000`) or pure white (`#FFFFFF`) — always use warm-tinted neutrals
- No cool grays — every neutral must have a warm amber/sand undertone
- No blue as an accent color — amber is the only chromatic accent
- No gradients on backgrounds — the paper surface is flat
- No drop shadows on cards — use 1px warm border + subtle box-shadow only
- No border-radius > 12px on cards or panels — this is a document tool, not a consumer app
- No uppercase body text — uppercase is reserved for section labels and plan badges only
- No icons as primary navigation — breadcrumbs and text labels carry navigation
- No skeleton screens — use a simple opacity fade-in
- No toast notifications — inline status messages only
- No more than 3 chromatic colors on a single screen (amber accent + 2 status tints max)
- No `font-weight: 700` or bold — max weight is 600 for headings, 500 for buttons
- No colored backgrounds on cards — `--surface1` only, never tinted card backgrounds

---

## 4. WORKFLOW

1. **Declare fonts** — check `references/platform-mapping.md` for loading instructions
2. **Set tokens** — apply variables from `references/tokens.md`
3. **Build components** — use specs from `references/components.md`
4. **Check hierarchy** — squint test: warm beige with one amber focal point
5. **Verify both modes** — light (primary) and dark must both feel like the same brand
6. **Test extremes** — long template text, empty preview, single slot, many slots
7. **Platform-adapt** — consult `references/platform-mapping.md` for output conventions

---

## 5. REFERENCE FILES

| File | Contains |
|------|----------|
| `references/tokens.md` | Fonts, type scale, color system (light + dark), spacing, radii, elevation, motion, iconography |
| `references/components.md` | Cards, buttons, inputs, slot tags, plan badges, breadcrumbs, overlays, state patterns |
| `references/platform-mapping.md` | HTML/CSS custom properties, SwiftUI extensions, React/Tailwind config |
