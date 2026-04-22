# Trae Design — Platform Mapping

## 1. HTML / CSS / WEB

### Font Loading

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&amp;family=JetBrains+Mono:wght@400;500&amp;display=swap" rel="stylesheet">
```

### CSS Custom Properties — Dark Mode (Primary)

```css
:root {
  /* Colors */
  --trae-background: #171B26;
  --trae-bg: var(--trae-background);
  --trae-surface1: #262A37;
  --trae-surface2: #2A2E3E;
  --trae-surface3: #363B4E;
  --trae-border: #262A37;
  --trae-border-visible: #363B4E;
  --trae-text1: #C9D1D9;
  --trae-text2: #9599A6;
  --trae-text3: #737780;
  --trae-text4: #5C6373;
  --trae-accent: #10B981;
  --trae-accent-subtle: #022C22;
  --trae-success: #10B981;
  --trae-success-bg: #064E3B;
  --trae-warning: #EB9B61;
  --trae-warning-bg: #78350F;
  --trae-error: #CC4B53;
  --trae-error-bg: #7F1D1D;
  --trae-secondary: #7563E7;
  --trae-blue: #387BFF;

  /* Fonts */
  --trae-font-display: "Inter", system-ui, -apple-system, sans-serif;
  --trae-font-body: "Inter", system-ui, -apple-system, sans-serif;
  --trae-font-mono: "JetBrains Mono", ui-monospace, "Cascadia Code", "Fira Code", monospace;

  /* Type Scale */
  --trae-text-display: 36px;
  --trae-text-heading: 24px;
  --trae-text-subheading: 18px;
  --trae-text-body: 14px;
  --trae-text-body-sm: 13px;
  --trae-text-caption: 12px;
  --trae-text-label: 11px;

  /* Spacing */
  --trae-space-2xs: 2px;
  --trae-space-xs: 4px;
  --trae-space-sm: 8px;
  --trae-space-md: 16px;
  --trae-space-lg: 24px;
  --trae-space-xl: 32px;
  --trae-space-2xl: 48px;
  --trae-space-3xl: 64px;
  --trae-space-4xl: 96px;

  /* Radii */
  --trae-radius-element: 4px;
  --trae-radius-control: 6px;
  --trae-radius-component: 8px;
  --trae-radius-container: 12px;

  /* Motion */
  --trae-ease: ease-out;
  --trae-duration-fast: 120ms;
  --trae-duration-normal: 180ms;
  --trae-duration-slow: 300ms;

  /* Elevation / Shadows (dark mode: mostly flat) */
  --trae-shadow-0: none;
  --trae-shadow-1: none;
  --trae-shadow-2: 0 4px 12px rgba(0,0,0,0.4);
  --trae-shadow-3: 0 8px 24px rgba(0,0,0,0.5);
}
```

### Light Mode

```css
@media (prefers-color-scheme: light) {
  :root {
    --trae-background: #F0F2F5;
    --trae-bg: var(--trae-background);
    --trae-surface1: #FFFFFF;
    --trae-surface2: #E0E3EA;
    --trae-surface3: #C9D1D9;
    --trae-border: #E0E3EA;
    --trae-border-visible: #C9D1D9;
    --trae-text1: #171B26;
    --trae-text2: #5C6373;
    --trae-text3: #737780;
    --trae-text4: #9599A6;
    --trae-accent: #059669;
    --trae-accent-subtle: #ECFDF5;
    --trae-success: #10B981;
    --trae-success-bg: #ECFDF5;
    --trae-warning: #EB9B61;
    --trae-warning-bg: #FFFBEB;
    --trae-error: #CC4B53;
    --trae-error-bg: #FEF2F2;
    --trae-shadow-0: none;
    --trae-shadow-1: 0 1px 3px rgba(0,0,0,0.08);
    --trae-shadow-2: 0 4px 12px rgba(0,0,0,0.12);
    --trae-shadow-3: 0 8px 24px rgba(0,0,0,0.16);
  }
}

/* Class-based toggle alternative */
.trae-light {
  --trae-background: #F0F2F5;
  --trae-bg: var(--trae-background);
  --trae-surface1: #FFFFFF;
  --trae-surface2: #E0E3EA;
  --trae-surface3: #C9D1D9;
  --trae-border: #E0E3EA;
  --trae-border-visible: #C9D1D9;
  --trae-text1: #171B26;
  --trae-text2: #5C6373;
  --trae-text3: #737780;
  --trae-text4: #9599A6;
  --trae-accent: #059669;
  --trae-accent-subtle: #ECFDF5;
  --trae-success: #10B981;
  --trae-success-bg: #ECFDF5;
  --trae-warning: #EB9B61;
  --trae-warning-bg: #FFFBEB;
  --trae-error: #CC4B53;
  --trae-error-bg: #FEF2F2;
  --trae-shadow-0: none;
  --trae-shadow-1: 0 1px 3px rgba(0,0,0,0.08);
  --trae-shadow-2: 0 4px 12px rgba(0,0,0,0.12);
  --trae-shadow-3: 0 8px 24px rgba(0,0,0,0.16);
}
```

---

## 2. REACT / TAILWIND

### tailwind.config.js

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        background: "var(--trae-background)",
        surface: {
          1: "var(--trae-surface1)",
          2: "var(--trae-surface2)",
          3: "var(--trae-surface3)",
        },
        border: {
          DEFAULT: "var(--trae-border)",
          visible: "var(--trae-border-visible)",
        },
        text: {
          1: "var(--trae-text1)",
          2: "var(--trae-text2)",
          3: "var(--trae-text3)",
          4: "var(--trae-text4)",
        },
        accent: {
          DEFAULT: "var(--trae-accent)",
          subtle: "var(--trae-accent-subtle)",
        },
        secondary: "var(--trae-secondary)",
        blue: "var(--trae-blue)",
        success: {
          DEFAULT: "var(--trae-success)",
          bg: "var(--trae-success-bg)",
        },
        warning: {
          DEFAULT: "var(--trae-warning)",
          bg: "var(--trae-warning-bg)",
        },
        error: {
          DEFAULT: "var(--trae-error)",
          bg: "var(--trae-error-bg)",
        },
      },
      fontFamily: {
        display: ["Inter", "system-ui", "-apple-system", "sans-serif"],
        body: ["Inter", "system-ui", "-apple-system", "sans-serif"],
        mono: ["JetBrains Mono", "ui-monospace", "Cascadia Code", "Fira Code", "monospace"],
      },
      fontSize: {
        display: ["36px", { lineHeight: "1.1", letterSpacing: "-0.02em" }],
        heading: ["24px", { lineHeight: "1.2", letterSpacing: "-0.01em" }],
        subheading: ["18px", { lineHeight: "1.3", letterSpacing: "-0.005em" }],
        body: ["14px", { lineHeight: "1.5", letterSpacing: "0" }],
        "body-sm": ["13px", { lineHeight: "1.5", letterSpacing: "0" }],
        caption: ["12px", { lineHeight: "1.4", letterSpacing: "0.01em" }],
        label: ["11px", { lineHeight: "1.3", letterSpacing: "0.02em" }],
      },
      spacing: {
        "2xs": "2px",
        xs: "4px",
        sm: "8px",
        md: "16px",
        lg: "24px",
        xl: "32px",
        "2xl": "48px",
        "3xl": "64px",
        "4xl": "96px",
      },
      borderRadius: {
        element: "4px",
        control: "6px",
        component: "8px",
        container: "12px",
      },
      transitionTimingFunction: {
        trae: "ease-out",
      },
      transitionDuration: {
        fast: "120ms",
        normal: "180ms",
        slow: "300ms",
      },
      boxShadow: {
        0: "none",
        1: "var(--trae-shadow-1)",
        2: "var(--trae-shadow-2)",
        3: "var(--trae-shadow-3)",
      },
    },
  },
  plugins: [],
};
```

### Font Loading via @fontsource

```bash
npm install @fontsource/inter @fontsource/jetbrains-mono
```

```js
import "@fontsource/inter/400.css";
import "@fontsource/inter/500.css";
import "@fontsource/inter/600.css";
import "@fontsource/inter/700.css";
import "@fontsource/jetbrains-mono/400.css";
import "@fontsource/jetbrains-mono/500.css";
```

### React Theme Object (styled-components / CSS Modules)

```ts
export const traeTheme = {
  colors: {
    background: "#171B26",
    surface1: "#262A37",
    surface2: "#2A2E3E",
    surface3: "#363B4E",
    border: "#262A37",
    borderVisible: "#363B4E",
    text1: "#C9D1D9",
    text2: "#9599A6",
    text3: "#737780",
    text4: "#5C6373",
    accent: "#10B981",
    accentSubtle: "#022C22",
    secondary: "#7563E7",
    blue: "#387BFF",
    success: "#10B981",
    successBg: "#064E3B",
    warning: "#EB9B61",
    warningBg: "#78350F",
    error: "#CC4B53",
    errorBg: "#7F1D1D",
  },
  fonts: {
    display: '"Inter", system-ui, -apple-system, sans-serif',
    body: '"Inter", system-ui, -apple-system, sans-serif',
    mono: '"JetBrains Mono", ui-monospace, "Cascadia Code", monospace',
  },
  fontSizes: {
    display: "36px",
    heading: "24px",
    subheading: "18px",
    body: "14px",
    bodySm: "13px",
    caption: "12px",
    label: "11px",
  },
  spacing: {
    "2xs": "2px",
    xs: "4px",
    sm: "8px",
    md: "16px",
    lg: "24px",
    xl: "32px",
    "2xl": "48px",
    "3xl": "64px",
    "4xl": "96px",
  },
  radii: {
    element: "4px",
    control: "6px",
    component: "8px",
    container: "12px",
  },
  shadows: {
    level0: "none",
    level1: "none",
    level2: "0 4px 12px rgba(0,0,0,0.4)",
    level3: "0 8px 24px rgba(0,0,0,0.5)",
  },
  motion: {
    easing: "ease-out",
    fast: "120ms",
    normal: "180ms",
    slow: "300ms",
  },
} as const;

export type TraeTheme = typeof traeTheme;
```

### ThemeProvider Setup (styled-components)

```tsx
import { ThemeProvider } from "styled-components";
import { traeTheme } from "./theme";

export function App() {
  return (
    <ThemeProvider theme={traeTheme}>
      {/* your app */}
    </ThemeProvider>
  );
}

// Usage in styled-components:
// const Panel = styled.div`
//   background: ${({ theme }) => theme.colors.surface1};
//   border: 1px solid ${({ theme }) => theme.colors.border};
//   border-radius: ${({ theme }) => theme.radii.component};
//   padding: ${({ theme }) => theme.spacing.md};
//   color: ${({ theme }) => theme.colors.text1};
// `;
```

### CSS Variables

Include the `:root` CSS custom properties from Section 1 in your global stylesheet (`globals.css` or `index.css`). The Tailwind config references these via `var(--trae-*)` for automatic dark/light mode support.

---

## 3. VS CODE / TRAE EDITOR THEME JSON

Maps Trae design tokens to VS Code / Trae IDE `workbench.colorCustomizations` keys. Save as a `.json` theme file or embed within `settings.json`.

```jsonc
{
  "name": "Trae Dark",
  "type": "dark",
  "colors": {
    "editor.background": "#171B26",
    "editor.foreground": "#C9D1D9",
    "editor.lineHighlightBackground": "#262A3780",
    "editor.selectionBackground": "#387BFF40",
    "editor.inactiveSelectionBackground": "#387BFF20",
    "editor.wordHighlightBackground": "#10B98130",
    "editor.findMatchBackground": "#10B98140",
    "editor.findMatchHighlightBackground": "#10B98120",
    "editorCursor.foreground": "#10B981",
    "editorWhitespace.foreground": "#363B4E",
    "editorIndentGuide.background": "#2A2E3E",
    "editorIndentGuide.activeBackground": "#363B4E",
    "editorLineNumber.foreground": "#5C6373",
    "editorLineNumber.activeForeground": "#9599A6",
    "editorBracketMatch.background": "#10B98120",
    "editorBracketMatch.border": "#10B98180",
    "editorGutter.addedBackground": "#10B981",
    "editorGutter.modifiedBackground": "#387BFF",
    "editorGutter.deletedBackground": "#CC4B53",

    "editorGroup.border": "#262A37",
    "editorGroupHeader.tabsBackground": "#171B26",
    "tab.activeBackground": "#262A37",
    "tab.activeForeground": "#C9D1D9",
    "tab.inactiveBackground": "#171B26",
    "tab.inactiveForeground": "#737780",
    "tab.border": "#171B26",
    "tab.activeBorderTop": "#10B981",

    "activityBar.background": "#171B26",
    "activityBar.foreground": "#C9D1D9",
    "activityBar.inactiveForeground": "#5C6373",
    "activityBarBadge.background": "#10B981",
    "activityBarBadge.foreground": "#FFFFFF",
    "sideBar.background": "#1C2030",
    "sideBar.foreground": "#9599A6",
    "sideBar.border": "#262A37",
    "sideBarTitle.foreground": "#C9D1D9",
    "sideBarSectionHeader.background": "#171B26",
    "sideBarSectionHeader.foreground": "#9599A6",

    "titleBar.activeBackground": "#171B26",
    "titleBar.activeForeground": "#C9D1D9",
    "titleBar.inactiveBackground": "#171B26",
    "titleBar.inactiveForeground": "#5C6373",
    "titleBar.border": "#262A37",

    "statusBar.background": "#171B26",
    "statusBar.foreground": "#9599A6",
    "statusBar.border": "#262A37",
    "statusBar.debuggingBackground": "#EB9B61",
    "statusBar.debuggingForeground": "#171B26",
    "statusBar.noFolderBackground": "#171B26",
    "statusBarItem.remoteBackground": "#10B981",
    "statusBarItem.remoteForeground": "#FFFFFF",

    "terminal.background": "#171B26",
    "terminal.foreground": "#C9D1D9",
    "terminalCursor.foreground": "#10B981",
    "terminal.ansiBlack": "#171B26",
    "terminal.ansiRed": "#CC4B53",
    "terminal.ansiGreen": "#10B981",
    "terminal.ansiYellow": "#EB9B61",
    "terminal.ansiBlue": "#387BFF",
    "terminal.ansiMagenta": "#7563E7",
    "terminal.ansiCyan": "#34D399",
    "terminal.ansiWhite": "#C9D1D9",
    "terminal.ansiBrightBlack": "#5C6373",
    "terminal.ansiBrightRed": "#CC4B53",
    "terminal.ansiBrightGreen": "#34D399",
    "terminal.ansiBrightYellow": "#EB9B61",
    "terminal.ansiBrightBlue": "#60A5FA",
    "terminal.ansiBrightMagenta": "#A78BFA",
    "terminal.ansiBrightCyan": "#6EE7B7",
    "terminal.ansiBrightWhite": "#F0F2F5",

    "panel.background": "#171B26",
    "panel.border": "#262A37",
    "panelTitle.activeBorder": "#10B981",
    "panelTitle.activeForeground": "#C9D1D9",
    "panelTitle.inactiveForeground": "#737780",

    "input.background": "#171B26",
    "input.foreground": "#C9D1D9",
    "input.border": "#262A37",
    "input.placeholderForeground": "#5C6373",
    "inputOption.activeBorder": "#10B981",
    "focusBorder": "#10B981",

    "dropdown.background": "#262A37",
    "dropdown.foreground": "#C9D1D9",
    "dropdown.border": "#363B4E",

    "list.activeSelectionBackground": "#2A2E3E",
    "list.activeSelectionForeground": "#C9D1D9",
    "list.hoverBackground": "#262A37",
    "list.inactiveSelectionBackground": "#262A37",
    "list.highlightForeground": "#10B981",

    "button.background": "#10B981",
    "button.foreground": "#FFFFFF",
    "button.hoverBackground": "#059669",
    "button.secondaryBackground": "#262A37",
    "button.secondaryForeground": "#C9D1D9",
    "button.secondaryHoverBackground": "#2A2E3E",

    "badge.background": "#10B981",
    "badge.foreground": "#FFFFFF",

    "scrollbarSlider.background": "#363B4E40",
    "scrollbarSlider.hoverBackground": "#363B4E80",
    "scrollbarSlider.activeBackground": "#363B4EA0",

    "peekView.border": "#10B981",
    "peekViewEditor.background": "#1C2030",
    "peekViewResult.background": "#171B26",
    "peekViewTitle.background": "#262A37",

    "diffEditor.insertedTextBackground": "#10B98120",
    "diffEditor.removedTextBackground": "#CC4B5320",

    "gitDecoration.addedResourceForeground": "#10B981",
    "gitDecoration.modifiedResourceForeground": "#387BFF",
    "gitDecoration.deletedResourceForeground": "#CC4B53",
    "gitDecoration.untrackedResourceForeground": "#34D399",
    "gitDecoration.ignoredResourceForeground": "#5C6373",

    "minimap.findMatchHighlight": "#10B98160",
    "minimap.selectionHighlight": "#387BFF40",

    "notificationCenter.border": "#262A37",
    "notifications.background": "#262A37",
    "notifications.foreground": "#C9D1D9",
    "notificationsErrorIcon.foreground": "#CC4B53",
    "notificationsWarningIcon.foreground": "#EB9B61",
    "notificationsInfoIcon.foreground": "#387BFF"
  },
  "tokenColors": [
    { "scope": "comment", "settings": { "foreground": "#5C6373", "fontStyle": "italic" } },
    { "scope": "string", "settings": { "foreground": "#10B981" } },
    { "scope": "constant.numeric", "settings": { "foreground": "#EB9B61" } },
    { "scope": "constant.language", "settings": { "foreground": "#CC4B53" } },
    { "scope": "keyword", "settings": { "foreground": "#7563E7" } },
    { "scope": "keyword.operator", "settings": { "foreground": "#C9D1D9" } },
    { "scope": ["storage.type", "storage.modifier"], "settings": { "foreground": "#7563E7" } },
    { "scope": "entity.name.function", "settings": { "foreground": "#387BFF" } },
    { "scope": "entity.name.type", "settings": { "foreground": "#34D399" } },
    { "scope": "entity.name.tag", "settings": { "foreground": "#CC4B53" } },
    { "scope": "entity.other.attribute-name", "settings": { "foreground": "#EB9B61" } },
    { "scope": "variable", "settings": { "foreground": "#C9D1D9" } },
    { "scope": "variable.parameter", "settings": { "foreground": "#C9D1D9", "fontStyle": "italic" } },
    { "scope": "support.function", "settings": { "foreground": "#387BFF" } },
    { "scope": "support.type", "settings": { "foreground": "#34D399" } },
    { "scope": "punctuation", "settings": { "foreground": "#737780" } },
    { "scope": "meta.tag", "settings": { "foreground": "#C9D1D9" } },
    { "scope": "markup.heading", "settings": { "foreground": "#387BFF", "fontStyle": "bold" } },
    { "scope": "markup.bold", "settings": { "fontStyle": "bold" } },
    { "scope": "markup.italic", "settings": { "fontStyle": "italic" } },
    { "scope": "markup.inline.raw", "settings": { "foreground": "#10B981" } }
  ]
}
```

### Token to VS Code Key Quick Reference

| Design Token | VS Code Theme Key | Value (Dark) |
|---|---|---|
| `background` | `editor.background`, `activityBar.background`, `titleBar.activeBackground` | `#171B26` |
| `surface1` | `tab.activeBackground`, `list.inactiveSelectionBackground` | `#262A37` |
| `surface2` | `list.activeSelectionBackground` | `#2A2E3E` |
| `surface3` | `editorIndentGuide.activeBackground`, `scrollbarSlider.background` | `#363B4E` |
| `border` | `sideBar.border`, `panel.border`, `editorGroup.border` | `#262A37` |
| `text1` | `editor.foreground`, `tab.activeForeground` | `#C9D1D9` |
| `text2` | `sideBar.foreground`, `statusBar.foreground` | `#9599A6` |
| `text3` | `tab.inactiveForeground`, `panelTitle.inactiveForeground` | `#737780` |
| `text4` | `editorLineNumber.foreground`, `activityBar.inactiveForeground` | `#5C6373` |
| `accent` (brand) | `editorCursor.foreground`, `focusBorder`, `button.background`, `badge.background` | `#10B981` |
| `secondary` | `keyword` tokenColor, `terminal.ansiMagenta` | `#7563E7` |
| `blue` | `entity.name.function` tokenColor, `editorGutter.modifiedBackground` | `#387BFF` |
| `error` | `editorGutter.deletedBackground`, `terminal.ansiRed` | `#CC4B53` |
| `warning` | `statusBar.debuggingBackground`, `constant.numeric` tokenColor | `#EB9B61` |

---

## 4. FIGMA VARIABLES

Structure Trae tokens as Figma Variable Collections for design-development handoff.

### Collection: "Trae / Primitives"

A single-mode collection containing the raw color scales. These are not used directly in designs — they back the semantic aliases.

| Variable Name | Type | Value |
|---|---|---|
| `neutral/50` | Color | `#F0F2F5` |
| `neutral/100` | Color | `#E0E3EA` |
| `neutral/200` | Color | `#C9D1D9` |
| `neutral/300` | Color | `#9599A6` |
| `neutral/400` | Color | `#737780` |
| `neutral/500` | Color | `#5C6373` |
| `neutral/600` | Color | `#3A3F4B` |
| `neutral/700` | Color | `#363B4E` |
| `neutral/800` | Color | `#2A2E3E` |
| `neutral/900` | Color | `#262A37` |
| `neutral/950` | Color | `#171B26` |
| `brand/50` | Color | `#ECFDF5` |
| `brand/100` | Color | `#D1FAE5` |
| `brand/200` | Color | `#A7F3D0` |
| `brand/300` | Color | `#6EE7B7` |
| `brand/400` | Color | `#34D399` |
| `brand/500` | Color | `#10B981` |
| `brand/600` | Color | `#059669` |
| `brand/700` | Color | `#047857` |
| `brand/800` | Color | `#065F46` |
| `brand/900` | Color | `#064E3B` |
| `brand/950` | Color | `#022C22` |
| `secondary/500` | Color | `#7563E7` |
| `blue/500` | Color | `#387BFF` |
| `red/500` | Color | `#CC4B53` |
| `green/500` | Color | `#10B981` |
| `amber/500` | Color | `#EB9B61` |

### Collection: "Trae / Semantic" (2 modes: Dark, Light)

| Variable Name | Type | Dark Mode | Light Mode |
|---|---|---|---|
| `color/background` | Color | `neutral/950` | `neutral/50` |
| `color/surface1` | Color | `neutral/900` | `#FFFFFF` |
| `color/surface2` | Color | `neutral/800` | `neutral/100` |
| `color/surface3` | Color | `neutral/700` | `neutral/200` |
| `color/border` | Color | `neutral/900` | `neutral/100` |
| `color/border-visible` | Color | `neutral/700` | `neutral/200` |
| `color/text1` | Color | `neutral/200` | `neutral/950` |
| `color/text2` | Color | `neutral/300` | `neutral/500` |
| `color/text3` | Color | `neutral/400` | `neutral/400` |
| `color/text4` | Color | `neutral/500` | `neutral/300` |
| `color/accent` | Color | `brand/500` | `brand/600` |
| `color/accent-subtle` | Color | `brand/950` | `brand/50` |
| `color/success` | Color | `#10B981` | `#10B981` |
| `color/warning` | Color | `#EB9B61` | `#EB9B61` |
| `color/error` | Color | `#CC4B53` | `#CC4B53` |
| `color/success-bg` | Color | `#064E3B` | `#ECFDF5` |
| `color/warning-bg` | Color | `#78350F` | `#FFFBEB` |
| `color/error-bg` | Color | `#7F1D1D` | `#FEF2F2` |

### Collection: "Trae / Spacing"

| Variable | Type | Value |
|---|---|---|
| `spacing/2xs` | Number | `2` |
| `spacing/xs` | Number | `4` |
| `spacing/sm` | Number | `8` |
| `spacing/md` | Number | `16` |
| `spacing/lg` | Number | `24` |
| `spacing/xl` | Number | `32` |
| `spacing/2xl` | Number | `48` |
| `spacing/3xl` | Number | `64` |
| `spacing/4xl` | Number | `96` |

### Collection: "Trae / Radii"

| Variable | Type | Value |
|---|---|---|
| `radii/element` | Number | `4` |
| `radii/control` | Number | `6` |
| `radii/component` | Number | `8` |
| `radii/container` | Number | `12` |

### Collection: "Trae / Typography"

| Variable | Type | Value |
|---|---|---|
| `type/font-display` | String | `Inter` |
| `type/font-mono` | String | `JetBrains Mono` |
| `type/display-size` | Number | `36` |
| `type/heading-size` | Number | `24` |
| `type/subheading-size` | Number | `18` |
| `type/body-size` | Number | `14` |
| `type/body-sm-size` | Number | `13` |
| `type/caption-size` | Number | `12` |
| `type/label-size` | Number | `11` |

Use Figma's mode switching (Dark / Light columns in the Semantic color collection) for automatic theme toggling in prototypes.
