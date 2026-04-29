---
name: homestock-design
description: "This skill should be used when the user explicitly says 'HomeStock style', 'HomeStock design', '/homestock-design', or directly asks to use/apply the HomeStock design system. NEVER trigger automatically for generic UI or design tasks."
version: 1.0.0
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# homestock-design

You are a senior product designer. When this skill is active, every UI decision follows this design language.

**Before starting any design work, declare which fonts are required and how to load them** (see `references/platform-mapping.md`). Never assume fonts are already available.

---

## 1. DESIGN PHILOSOPHY

Clean domestic order. HomeStock treats household inventory like a well-organized pantry -- everything has its place, its quantity, and its freshness date. The visual language draws from modern home organization aesthetics: white surfaces, soft edges, and a single fresh-green accent that reads "stocked and healthy." The primary tension is between data density (a real management tool needs numbers, lists, charts, and alerts) and visual lightness (a home context demands comfort and calm, never enterprise anxiety). Think MUJI store meets grocery app -- functional warmth with zero clutter.

The design lineage runs through consumer-grade management tools (Notion's friendliness, Home app's simplicity) filtered through Chinese consumer-app sensibilities -- generous touch targets, clear status colors, and multi-category color coding that lets a pantry shelf worth of items stay legible at a glance.

---

## 2. CRAFT RULES -- HOW TO COMPOSE

**Rule 1 -- White floats on gray.** Every content card is pure white (#FFFFFF) on a cool-gray canvas (#F0F2F5). This single contrast layer creates depth without shadows. The gray is the room; the white is the shelf. Never reverse this.

**Rule 2 -- One green, many categories.** The brand green (#43A047) is the only accent that drives action (CTAs, active nav, toggles). Category identification uses a six-color system (green/blue/orange/pink/purple/violet) exclusively for informational tagging -- never for interactive elements.

**Rule 3 -- Number hierarchy through weight, not size.** Large metric numbers (256, Y568.00) use font-weight 600 at 28px. Their labels sit at 13px weight-400 above. Supporting change indicators (+12%, -8%) sit at 12px in semantic color.

**Rule 4 -- List density is 56px rows.** Every horizontal list row has a consistent 56px minimum height with: 40px icon/image left, two lines of text center, status/value block right.

**Rule 5 -- Icon backgrounds are tinted squares.** Every functional icon sits inside a 40-48px rounded-square (radius 12px) filled with a 10% tint of its semantic color. The icon itself is the full-saturation version.

| Layer | Treatment | Example |
|-------|-----------|---------|
| L1 -- Canvas | Cool gray #F0F2F5 | Page background |
| L2 -- Surface | Pure white, subtle shadow | Cards, sidebar |
| L3 -- Inset | Neutral-50 #F7F8FA | Table headers, input backgrounds |
| L4 -- Accent | Brand green 10% tint bg + full color icon/text | Stat icons, category badges |

**Squint test:** At arm's length, the page should read as a grid of white cards on gray with one green anchor.

---

## 3. ANTI-PATTERNS -- WHAT TO NEVER DO

- No gradient backgrounds on cards or buttons. Surfaces are flat white or flat tinted.
- No border-radius above 16px on cards. Cards are 12px radius. Pill shapes (999px) reserved for tags, badges, search bar only.
- No colored text for body copy. Text is always neutral-900/600/500. Only status values and change indicators use color.
- No icon-only buttons without labels in main content area.
- No more than 4 stat cards in a row.
- No shadows darker than rgba(16,24,40,0.08) on any element.
- No red or orange for interactive elements. Reserved for alert states only.
- No horizontal scrolling in list cards.
- No uppercase text transforms in Chinese UI.
- No skeleton loading screens with gray rectangles. Use a single centered spinner.
- No toast notifications from the bottom-right. Alerts appear inline or as top-center banners.

---

## 4. WORKFLOW

1. **Declare fonts** -- check `references/platform-mapping.md` for loading instructions
2. **Set tokens** -- apply variables from `references/tokens.md`
3. **Build components** -- use specs from `references/components.md`
4. **Check hierarchy** -- squint test: can you tell what is most important?
5. **Verify both modes** -- light and dark must both feel intentional
6. **Test extremes** -- long text, empty states, single item, 100 items
7. **Platform-adapt** -- consult `references/platform-mapping.md` for output conventions

---

## 5. REFERENCE FILES

| File | Contains |
|------|----------|
| `references/tokens.md` | Fonts, type scale, color system (light + dark), spacing, radii, elevation, motion, iconography |
| `references/components.md` | Cards, buttons, inputs, lists, navigation, tags, overlays, state patterns |
| `references/platform-mapping.md` | HTML/CSS, SwiftUI, React/Tailwind -- platform-specific code and loading instructions |
