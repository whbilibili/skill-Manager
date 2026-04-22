# Trae — Components

> Design language: "Terminal cursor on a cold-blue stage." Components feel like developer tooling — dense, information-rich. Use `JetBrains Mono` for code and metrics, `Inter` for UI text. Primary mode is dark.

---

## 1. BUTTONS

### Variants

| Variant | Background | Text | Border | Radius | Height |
|---------|-----------|------|--------|--------|--------|
| Primary | `#10B981` | `#FFFFFF` | none | 6px | 36px |
| Secondary | `#262A37` | `#C9D1D9` | 1px solid #363B4E | 6px | 36px |
| Ghost | transparent | `#C9D1D9` | none | 6px | 32px |
| Destructive | `#CC4B53` | `#FFFFFF` | none | 6px | 36px |

### Specs

| Property | Value |
|----------|-------|
| Height (large) | 36px |
| Height (small) | 28px |
| Padding (large) | 10px 20px |
| Padding (small) | 6px 14px |
| Font | `Inter` 500, 14px |
| Min touch target | 44px |

### States

| State | Change |
|-------|--------|
| **Hover** | Primary → `#059669`; Secondary → `#2A2E3E`; Ghost → `#2A2E3E` bg |
| **Active / Pressed** | scale(0.98), brightness 0.9 |
| **Disabled** | Opacity 0.4, no pointer events |
| **Focus** | 2px solid `#10B981` outline, 2px offset |

### HTML Structure

```html
<button class="btn btn--primary" type="button">
  <span class="btn__label">Label</span>
</button>
```

### CSS (semantic tokens)

```css
.btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--space-xs);           /* 4px */
  height: 36px;
  padding: 10px 20px;
  border-radius: var(--radii-control);  /* 6px */
  font-family: var(--font-body);  /* Inter */
  font-size: 14px;
  font-weight: 500;
  cursor: pointer;
  transition: background var(--duration-fast) var(--easing),
              transform var(--duration-fast) var(--easing);
  border: none;
}
.btn--primary {
  background: var(--accent);      /* #10B981 */
  color: #FFFFFF;
}
.btn--primary:hover { background: var(--accent-hover); }  /* #059669 */
.btn--secondary {
  background: var(--surface1);    /* #262A37 */
  color: var(--text1);            /* #C9D1D9 */
  border: 1px solid var(--border-visible);  /* #363B4E */
}
.btn--secondary:hover { background: var(--surface2); }  /* #2A2E3E */
.btn--ghost {
  background: transparent;
  color: var(--text1);
  padding: 10px 16px;
  font-weight: 400;
}
.btn--ghost:hover { background: var(--surface2); }
.btn--destructive {
  background: var(--error);       /* #CC4B53 */
  color: #FFFFFF;
}
.btn:active { transform: scale(0.98); filter: brightness(0.9); }
.btn:disabled { opacity: 0.4; pointer-events: none; }
.btn:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
```

---

## 2. CARDS / SURFACES

### Standard Card
- Background: `--surface1` (`#262A37`)
- Border: 1px solid `--border` (`#262A37`)
- Radius: 8px (component)
- Padding: 16px
- Shadow: none (dark) / `0 1px 3px rgba(0,0,0,0.08)` (light)

### Featured Card
- Background: `--surface1` + 1px left border in `--accent` (`#10B981`)
- Radius: 8px
- Shadow: `0 4px 12px rgba(0,0,0,0.4)` (dark) / `0 4px 12px rgba(0,0,0,0.12)` (light)

### Compact Card
- Radius: 6px
- Padding: 12px
- Same background and border as standard

### Content Layout
- Title: `--subheading` (14px / 600), `--text1`
- Description: `--body-sm` (13px), `--text2`
- Metadata: `--caption` (12px), `--text3`
- Internal spacing: `--space-sm` (8px)
- Press state: `--surface2` background on press

### HTML Structure

```html
<div class="card">
  <div class="card__header">
    <h3 class="card__title">Title</h3>
    <span class="card__meta">meta</span>
  </div>
  <div class="card__body">
    <p class="card__description">Description text.</p>
  </div>
</div>
```

### CSS (semantic tokens)

```css
.card {
  background: var(--surface1);
  border: 1px solid var(--border);
  border-radius: var(--radii-component);  /* 8px */
  padding: var(--space-md);               /* 16px */
}
.card--featured {
  border-left: 2px solid var(--accent);
  box-shadow: var(--elevation-2);
}
.card--compact {
  border-radius: var(--radii-control);    /* 6px */
  padding: var(--space-sm) var(--space-md); /* 8px 16px */
}
.card__title {
  font-family: var(--font-body);
  font-size: 14px;
  font-weight: 600;
  color: var(--text1);
}
.card__description { font-size: 13px; color: var(--text2); }
.card__meta { font-size: 12px; color: var(--text3); }
```

---

## 3. INPUTS

### Text Field

| Property | Value |
|----------|-------|
| Height | 36px |
| Background | `--background` (`#171B26`) |
| Border (default) | 1px solid `--border` (`#262A37`) |
| Border (focus) | 1px solid `--accent` (`#10B981`) |
| Border (error) | 1px solid `--error` (`#CC4B53`) |
| Radius | 6px |
| Padding | 8px 12px |
| Font | `Inter`, `--body` (14px) |
| Placeholder color | `--text3` (`#737780`) |

### Label
- Position: above field, 6px gap
- Font: `Inter`, `--body-sm` (13px), `--text2`

### States

| State | Treatment |
|-------|-----------|
| **Default** | 1px solid `--border` |
| **Focus** | 1px solid `--accent`. Subtle `0 0 0 2px rgba(16,185,129,0.15)` glow |
| **Error** | 1px solid `--error`. Error text below in `--error`, `--caption` |
| **Disabled** | Opacity 0.4, no interaction |

### Multiline
- Same styling as text field, min-height 100px, auto-grows

### HTML Structure

```html
<div class="input-group">
  <label class="input-group__label" for="field">Label</label>
  <input class="input" id="field" type="text" placeholder="Placeholder…" />
  <span class="input-group__error">Error message</span>
</div>
```

### CSS (semantic tokens)

```css
.input {
  width: 100%;
  height: 36px;
  background: var(--background);         /* #171B26 */
  border: 1px solid var(--border);       /* #262A37 */
  border-radius: var(--radii-control);   /* 6px */
  padding: 8px 12px;
  font-family: var(--font-body);
  font-size: 14px;
  color: var(--text1);
  transition: border-color var(--duration-fast) var(--easing),
              box-shadow var(--duration-fast) var(--easing);
}
.input::placeholder { color: var(--text3); }
.input:focus {
  border-color: var(--accent);
  box-shadow: 0 0 0 2px rgba(16,185,129,0.15);
  outline: none;
}
.input--error { border-color: var(--error); }
.input:disabled { opacity: 0.4; pointer-events: none; }
.input-group__label {
  display: block;
  margin-bottom: 6px;
  font-size: 13px;
  color: var(--text2);
}
.input-group__error {
  display: block;
  margin-top: 4px;
  font-size: 12px;
  color: var(--error);
}
```

---

## 4. TAGS / CHIPS

| Property | Value |
|----------|-------|
| Height | auto (inline) |
| Padding | 4px 10px |
| Radius | 4px (element) |
| Font | `Inter`, 12px, 500 |
| Background | `--surface2` (`#2A2E3E`) |
| Text color | `--text1` (`#C9D1D9`) |
| Border | none |

### Selected State
- Background: `--accent-subtle` (`#022C22`)
- Text: `--accent` (`#10B981`)
- Border: 1px solid `--accent`

### Status Variants
Use status colors for semantic tags: `--success` bg `#022C22` + text `#10B981`, `--warning` bg `rgba(235,155,97,0.12)` + text `#EB9B61`, `--error` bg `rgba(204,75,83,0.12)` + text `#CC4B53`.

### HTML Structure

```html
<span class="tag">Default</span>
<span class="tag tag--selected">Selected</span>
<span class="tag tag--success">Passing</span>
<span class="tag tag--error">Failed</span>
```

### CSS (semantic tokens)

```css
.tag {
  display: inline-flex;
  align-items: center;
  padding: 4px 10px;
  border-radius: var(--radii-element);   /* 4px */
  font-family: var(--font-body);
  font-size: 12px;
  font-weight: 500;
  background: var(--surface2);           /* #2A2E3E */
  color: var(--text1);
  white-space: nowrap;
}
.tag--selected {
  background: var(--accent-subtle);
  color: var(--accent);
  border: 1px solid var(--accent);
}
.tag--success { background: rgba(16,185,129,0.1); color: var(--success); }
.tag--warning { background: rgba(235,155,97,0.1); color: var(--warning); }
.tag--error   { background: rgba(204,75,83,0.1);  color: var(--error); }
```

---

## 5. TOGGLE / SWITCH

### Specs

| Property | Value |
|----------|-------|
| Track width | 36px |
| Track height | 20px |
| Track radius | 10px (pill) |
| Thumb size | 16px |
| Thumb radius | 50% |
| Thumb offset (from edge) | 2px |
| Label position | right of track |
| Label gap | 8px |
| Label font | `Inter`, `--body` (14px), `--text1` |

### States

| State | Track Background | Thumb |
|-------|-----------------|-------|
| **Off (default)** | `--surface3` (`#363B4E`) | `#C9D1D9` |
| **On** | `--accent` (`#10B981`) | `#FFFFFF` |
| **Hover** | Brightness +0.1 on track | — |
| **Disabled** | Opacity 0.4, no interaction | — |
| **Focus** | 2px solid `--accent` outline, 2px offset | — |

### HTML Structure

```html
<label class="toggle">
  <input class="toggle__input" type="checkbox" />
  <span class="toggle__track">
    <span class="toggle__thumb"></span>
  </span>
  <span class="toggle__label">Enable AI assist</span>
</label>
```

### CSS (semantic tokens)

```css
.toggle { display: inline-flex; align-items: center; gap: 8px; cursor: pointer; }
.toggle__input { position: absolute; opacity: 0; width: 0; height: 0; }
.toggle__track {
  position: relative;
  width: 36px;
  height: 20px;
  background: var(--surface3);           /* #363B4E */
  border-radius: 10px;
  transition: background var(--duration-fast) var(--easing);
}
.toggle__thumb {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 16px;
  height: 16px;
  border-radius: 50%;
  background: var(--text1);              /* #C9D1D9 */
  transition: transform var(--duration-fast) var(--easing),
              background var(--duration-fast) var(--easing);
}
.toggle__input:checked + .toggle__track { background: var(--accent); }
.toggle__input:checked + .toggle__track .toggle__thumb {
  transform: translateX(16px);
  background: #FFFFFF;
}
.toggle__input:disabled + .toggle__track { opacity: 0.4; pointer-events: none; }
.toggle__input:focus-visible + .toggle__track {
  outline: 2px solid var(--accent);
  outline-offset: 2px;
}
.toggle__label { font-family: var(--font-body); font-size: 14px; color: var(--text1); }
```

---

## 6. SIDEBAR PANEL

> IDE left/right panel (file explorer, AI chat, extensions).

| Property | Value |
|----------|-------|
| Width | 260px default, resizable |
| Background | `--background` (`#171B26`) |
| Border (right/left) | 1px solid `--border` (`#262A37`) |
| Header height | 36px |
| Header font | `Inter`, 11px, 600, uppercase, `--text3` |
| Header padding | 0 12px |
| Section gap | 0 (flush) |

### States

| State | Treatment |
|-------|-----------|
| **Default** | Full panel visible |
| **Collapsed** | 48px activity-bar strip with icons only |
| **Hover (resize handle)** | 2px wide `--accent` bar |
| **Focused section** | `--accent` left-border 2px on active activity-bar icon |

### HTML Structure

```html
<aside class="sidebar">
  <div class="sidebar__header">
    <span class="sidebar__title">EXPLORER</span>
    <button class="btn btn--ghost sidebar__action"><i class="icon icon-ellipsis"></i></button>
  </div>
  <div class="sidebar__content">
    <!-- file tree, panels, etc. -->
  </div>
</aside>
```

### CSS (semantic tokens)

```css
.sidebar {
  width: 260px;
  min-width: 180px;
  background: var(--background);
  border-right: 1px solid var(--border);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.sidebar__header {
  height: 36px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 12px;
  flex-shrink: 0;
}
.sidebar__title {
  font-family: var(--font-body);
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--text3);
}
.sidebar__content { flex: 1; overflow-y: auto; }
```

---

## 7. TAB BAR (Editor Tabs)

> Horizontal tab strip above the editor pane.

| Property | Value |
|----------|-------|
| Height | 36px |
| Background | `--background` (`#171B26`) |
| Border (bottom) | 1px solid `--border` (`#262A37`) |
| Tab padding | 0 12px |
| Tab font | `Inter`, 13px, 400 |
| Close icon | 14px, `--text3`, visible on hover |

### Tab States

| State | Treatment |
|-------|-----------|
| **Active** | `--surface1` bg (`#262A37`), `--text1` text, top 2px `--accent` border |
| **Inactive** | `transparent` bg, `--text3` text |
| **Hover** | `--surface2` bg (`#2A2E3E`), close icon appears |
| **Modified (unsaved)** | dot indicator in `--text2` next to filename |

### HTML Structure

```html
<div class="tab-bar" role="tablist">
  <div class="tab tab--active" role="tab" aria-selected="true">
    <i class="tab__icon icon icon-file-code"></i>
    <span class="tab__label">main.tsx</span>
    <button class="tab__close"><i class="icon icon-x"></i></button>
  </div>
  <div class="tab" role="tab">
    <span class="tab__label">utils.ts</span>
    <span class="tab__modified"></span>
  </div>
</div>
```

### CSS (semantic tokens)

```css
.tab-bar {
  display: flex;
  height: 36px;
  background: var(--background);
  border-bottom: 1px solid var(--border);
  overflow-x: auto;
  flex-shrink: 0;
}
.tab {
  display: inline-flex;
  align-items: center;
  gap: var(--space-xs);         /* 4px */
  padding: 0 12px;
  font-family: var(--font-body);
  font-size: 13px;
  color: var(--text3);
  cursor: pointer;
  border-top: 2px solid transparent;
  white-space: nowrap;
  transition: background var(--duration-fast) var(--easing);
}
.tab--active {
  background: var(--surface1);
  color: var(--text1);
  border-top-color: var(--accent);
}
.tab:hover { background: var(--surface2); }
.tab__close {
  display: none;
  background: none; border: none; padding: 2px;
  color: var(--text3); cursor: pointer;
}
.tab:hover .tab__close { display: inline-flex; }
.tab__close:hover { color: var(--text1); }
.tab__modified {
  width: 6px; height: 6px;
  border-radius: 50%;
  background: var(--text2);
}
```

---

## 8. STATUS BAR

> Fixed bar at the bottom of the IDE window.

| Property | Value |
|----------|-------|
| Height | 24px |
| Background | `--accent` (`#10B981`) for connected state; `--surface1` for neutral |
| Font | `JetBrains Mono`, 11px, `--text1` (or white on accent bg) |
| Padding | 0 8px |
| Border (top) | none |
| Item gap | 12px |

### Variants

| Variant | Background | Text |
|---------|-----------|------|
| **Connected / AI active** | `#10B981` (accent) | `#FFFFFF` |
| **Neutral** | `--surface1` (`#262A37`) | `--text2` |
| **Error** | `--error` (`#CC4B53`) | `#FFFFFF` |
| **Warning** | `--warning` (`#EB9B61`) | `#171B26` |

### HTML Structure

```html
<footer class="status-bar status-bar--connected">
  <div class="status-bar__left">
    <span class="status-bar__item"><i class="icon icon-git-branch"></i> main</span>
    <span class="status-bar__item">0 errors</span>
  </div>
  <div class="status-bar__right">
    <span class="status-bar__item">Ln 42, Col 8</span>
    <span class="status-bar__item">UTF-8</span>
    <span class="status-bar__item">TypeScript</span>
  </div>
</footer>
```

### CSS (semantic tokens)

```css
.status-bar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 24px;
  padding: 0 8px;
  font-family: var(--font-mono);   /* JetBrains Mono */
  font-size: 11px;
  flex-shrink: 0;
}
.status-bar--neutral { background: var(--surface1); color: var(--text2); }
.status-bar--connected { background: var(--accent); color: #FFFFFF; }
.status-bar--error { background: var(--error); color: #FFFFFF; }
.status-bar__left, .status-bar__right { display: flex; align-items: center; gap: 12px; }
.status-bar__item {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  cursor: pointer;
  white-space: nowrap;
}
.status-bar__item:hover { opacity: 0.8; }
```

---

## 9. COMMAND PALETTE

> Global fuzzy-search overlay triggered by `Cmd+Shift+P`.

| Property | Value |
|----------|-------|
| Max width | 560px |
| Background | `--surface1` (`#262A37`) |
| Radius | 12px (container) |
| Shadow | `0 8px 24px rgba(0,0,0,0.5)` |
| Backdrop | `rgba(0,0,0,0.5)` |
| Input height | 40px |
| Input font | `JetBrains Mono`, 14px |
| Input bg | `--background` (`#171B26`) |
| Result row height | 32px |
| Result font | `Inter`, 13px |
| Highlight color | `--accent` on matched chars |

### States

| State | Treatment |
|-------|-----------|
| **Default** | Input focused, empty results |
| **With results** | List below input, first item selected |
| **Selected row** | `--surface2` bg (`#2A2E3E`), `--text1` text |
| **Hover row** | `--surface2` bg |
| **No results** | `--text3` centered "No results found" |

### HTML Structure

```html
<div class="command-palette-backdrop">
  <div class="command-palette" role="dialog">
    <div class="command-palette__input-wrap">
      <i class="icon icon-search command-palette__icon"></i>
      <input class="command-palette__input" type="text" placeholder="Type a command…" autofocus />
    </div>
    <ul class="command-palette__results" role="listbox">
      <li class="command-palette__item command-palette__item--selected" role="option">
        <span class="command-palette__item-label">Toggle Terminal</span>
        <span class="command-palette__item-shortcut">⌃`</span>
      </li>
      <li class="command-palette__item" role="option">
        <span class="command-palette__item-label">Format Document</span>
        <span class="command-palette__item-shortcut">⇧⌥F</span>
      </li>
    </ul>
  </div>
</div>
```

### CSS (semantic tokens)

```css
.command-palette-backdrop {
  position: fixed; inset: 0;
  background: rgba(0,0,0,0.5);
  display: flex;
  justify-content: center;
  padding-top: 20vh;
  z-index: 1000;
}
.command-palette {
  width: 100%;
  max-width: 560px;
  background: var(--surface1);
  border-radius: var(--radii-container);  /* 12px */
  box-shadow: var(--elevation-3);
  overflow: hidden;
}
.command-palette__input-wrap {
  display: flex;
  align-items: center;
  padding: 0 12px;
  border-bottom: 1px solid var(--border);
}
.command-palette__icon { color: var(--text3); margin-right: 8px; }
.command-palette__input {
  flex: 1;
  height: 40px;
  background: transparent;
  border: none;
  font-family: var(--font-mono);
  font-size: 14px;
  color: var(--text1);
  outline: none;
}
.command-palette__input::placeholder { color: var(--text3); }
.command-palette__results { list-style: none; padding: 4px 0; margin: 0; max-height: 320px; overflow-y: auto; }
.command-palette__item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 32px;
  padding: 0 12px;
  font-family: var(--font-body);
  font-size: 13px;
  color: var(--text2);
  cursor: pointer;
}
.command-palette__item:hover,
.command-palette__item--selected {
  background: var(--surface2);
  color: var(--text1);
}
.command-palette__item-shortcut {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text3);
}
```

---

## 10. INLINE CHAT BUBBLE

> AI conversation panel inlined in the editor or as a side panel.

| Property | Value |
|----------|-------|
| Background (user) | `--surface2` (`#2A2E3E`) |
| Background (AI) | `--surface1` (`#262A37`) with left 2px `--accent` border |
| Radius | 8px (component) |
| Padding | 12px 16px |
| Max width | 100% of panel |
| Code block bg | `--background` (`#171B26`) |
| Code block font | `JetBrains Mono`, 13px |
| Body font | `Inter`, 14px, `--text1` |
| Timestamp font | `JetBrains Mono`, 11px, `--text3` |

### States

| State | Treatment |
|-------|-----------|
| **Default** | Static message bubble |
| **Streaming** | Pulsing `--accent` cursor at end of AI text |
| **Hover** | Copy/retry action icons appear at top-right, `--text3` |
| **Error** | `--error` left border, retry button visible |

### HTML Structure

```html
<div class="chat-bubble chat-bubble--user">
  <p class="chat-bubble__text">How do I optimize this function?</p>
  <span class="chat-bubble__time">12:34</span>
</div>
<div class="chat-bubble chat-bubble--ai">
  <p class="chat-bubble__text">Here's a refactored version using memoization:</p>
  <pre class="chat-bubble__code"><code>const memo = useMemo(() => compute(data), [data]);</code></pre>
  <div class="chat-bubble__actions">
    <button class="btn btn--ghost btn--sm"><i class="icon icon-copy"></i></button>
    <button class="btn btn--ghost btn--sm"><i class="icon icon-refresh-cw"></i></button>
  </div>
</div>
```

### CSS (semantic tokens)

```css
.chat-bubble {
  padding: 12px 16px;
  border-radius: var(--radii-component);  /* 8px */
  font-family: var(--font-body);
  font-size: 14px;
  color: var(--text1);
  line-height: 1.5;
  position: relative;
}
.chat-bubble--user { background: var(--surface2); }
.chat-bubble--ai {
  background: var(--surface1);
  border-left: 2px solid var(--accent);
}
.chat-bubble--ai.chat-bubble--error { border-left-color: var(--error); }
.chat-bubble__code {
  background: var(--background);
  border-radius: var(--radii-control);
  padding: 12px;
  font-family: var(--font-mono);
  font-size: 13px;
  overflow-x: auto;
  margin: 8px 0;
}
.chat-bubble__time {
  font-family: var(--font-mono);
  font-size: 11px;
  color: var(--text3);
}
.chat-bubble__actions {
  display: none;
  position: absolute;
  top: 8px;
  right: 8px;
  gap: 4px;
}
.chat-bubble:hover .chat-bubble__actions { display: flex; }
```

---

## 11. FILE TREE ITEM

> Tree-view rows in the sidebar explorer.

| Property | Value |
|----------|-------|
| Row height | 24px |
| Indent per level | 16px |
| Icon size | 16px |
| Icon gap | 6px |
| Font | `Inter`, 13px, 400, `--text1` |
| Padding | 0 8px |
| Expand chevron | 12px, `--text3` |

### States

| State | Treatment |
|-------|-----------|
| **Default** | Transparent bg |
| **Hover** | `--surface2` bg (`#2A2E3E`) |
| **Selected** | `--surface2` bg, `--text1`, left 2px `--accent` |
| **Active (focused)** | `--accent-subtle` bg (`#022C22`), `--accent` text |
| **Disabled** | Opacity 0.4 |
| **Modified** | Filename in `--warning` (`#EB9B61`) |
| **Untracked** | Filename in `--accent` (`#10B981`) |

---

## 17. BREADCRUMB

### Specs

| Property | Value |
|----------|-------|
| Font | `Inter`, `--body-sm` (12px) |
| Link color | `--text2` (`#9599A6`) |
| Link hover | `--text1` (`#C9D1D9`), underline |
| Separator glyph | `/` (forward slash — IDE convention) |
| Separator color | `--text3` (`#737780`) |
| Separator spacing | 6px each side |
| Current page | `--text1`, font-weight 500, no link |

### HTML

```html
<nav class="trae-breadcrumb" aria-label="Breadcrumb">
  <ol>
    <li><a href="#">src</a></li>
    <li aria-hidden="true">/</li>
    <li><a href="#">components</a></li>
    <li aria-hidden="true">/</li>
    <li aria-current="page">Button.tsx</li>
  </ol>
</nav>
```

### CSS

```css
.trae-breadcrumb ol {
  display: flex;
  align-items: center;
  gap: 0;
  list-style: none;
  margin: 0;
  padding: 0;
  font-family: 'JetBrains Mono', monospace;
  font-size: 12px;
}
.trae-breadcrumb a {
  color: var(--text2);
  text-decoration: none;
  padding: 2px 0;
}
.trae-breadcrumb a:hover { color: var(--text1); text-decoration: underline; }
.trae-breadcrumb li[aria-hidden] {
  color: var(--text3);
  margin: 0 6px;
  user-select: none;
}
.trae-breadcrumb [aria-current="page"] {
  color: var(--text1);
  font-weight: 500;
}
```

---

## 18. TOOLTIP

### Specs

| Property | Value |
|----------|-------|
| Background | `--surface3` (`#363B4E`) |
| Text color | `--text1` (`#C9D1D9`) |
| Font | `Inter`, 12px |
| Radius | 4px |
| Padding | 4px 8px |
| Max width | 240px |
| Arrow | 6px CSS triangle, same color as bg |
| Delay (show) | 400ms |
| Delay (hide) | 0ms |
| Placement | top-center preferred, auto-flip |
| Shadow | `0 4px 12px rgba(0,0,0,0.4)` |

### HTML

```html
<div class="trae-tooltip" role="tooltip">
  <span class="trae-tooltip__text">Open Settings (⌘,)</span>
  <span class="trae-tooltip__arrow"></span>
</div>
```

### CSS

```css
.trae-tooltip {
  position: absolute;
  background: var(--surface3);
  color: var(--text1);
  font-family: 'Inter', sans-serif;
  font-size: 12px;
  line-height: 1.4;
  padding: 4px 8px;
  border-radius: 4px;
  max-width: 240px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.4);
  pointer-events: none;
  z-index: 9999;
}
.trae-tooltip__arrow {
  position: absolute;
  bottom: -5px;
  left: 50%;
  transform: translateX(-50%);
  border-left: 6px solid transparent;
  border-right: 6px solid transparent;
  border-top: 6px solid var(--surface3);
}
```

### Keyboard Shortcut Variant

For tooltips that include keybindings, render the shortcut in a `<kbd>` element with mono font:

```css
.trae-tooltip kbd {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  color: var(--text2);
  margin-left: 8px;
}
```

---

## 19. INLINE CHAT BUBBLE

The AI response surface embedded within the editor canvas.

### Specs

| Property | Value |
|----------|-------|
| Background | `--surface1` (`#262A37`) |
| Border | 1px solid `--border-visible` (`#363B4E`) |
| Left accent | 2px solid `--accent` (`#10B981`) |
| Radius | 8px |
| Padding | 12px 16px |
| Max width | 560px |
| Font (response) | `Inter`, 13px, `--text1` |
| Font (code) | `JetBrains Mono`, 13px |
| Shadow | `0 4px 12px rgba(0,0,0,0.4)` |

### HTML

```html
<div class="trae-chat-bubble">
  <div class="trae-chat-bubble__indicator">
    <span class="trae-chat-bubble__icon">✦</span>
    <span class="trae-chat-bubble__label">Trae</span>
  </div>
  <div class="trae-chat-bubble__body">
    <p>Here's the refactored function:</p>
    <pre><code>function calculate(a: number, b: number): number {
  return a + b;
}</code></pre>
  </div>
  <div class="trae-chat-bubble__actions">
    <button class="trae-btn trae-btn--primary trae-btn--sm">Accept</button>
    <button class="trae-btn trae-btn--ghost trae-btn--sm">Dismiss</button>
  </div>
</div>
```

### CSS

```css
.trae-chat-bubble {
  background: var(--surface1);
  border: 1px solid var(--border-visible);
  border-left: 2px solid var(--accent);
  border-radius: 8px;
  padding: 12px 16px;
  max-width: 560px;
  box-shadow: 0 4px 12px rgba(0,0,0,0.4);
  font-family: 'Inter', sans-serif;
  font-size: 13px;
  color: var(--text1);
}
.trae-chat-bubble__indicator {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-bottom: 8px;
  font-size: 12px;
  color: var(--accent);
  font-weight: 500;
}
.trae-chat-bubble__icon { font-size: 14px; }
.trae-chat-bubble__body pre {
  background: var(--background);
  border-radius: 4px;
  padding: 8px 12px;
  margin: 8px 0;
  overflow-x: auto;
}
.trae-chat-bubble__body code {
  font-family: 'JetBrains Mono', monospace;
  font-size: 13px;
  line-height: 1.5;
}
.trae-chat-bubble__actions {
  display: flex;
  gap: 8px;
  margin-top: 12px;
}
```

### States

| State | Treatment |
|-------|----------|
| **Streaming** | Body text appears token-by-token; pulsing `--accent` dot in indicator |
| **Complete** | Action buttons fade in (180ms ease-out) |
| **Collapsed** | Single-line preview, click to expand |

---

## 20. COMMAND PALETTE

The ⌘K / ⌘⇧P overlay for command search.

### Specs

| Property | Value |
|----------|-------|
| Background | `--surface1` (`#262A37`) |
| Border | 1px solid `--border-visible` (`#363B4E`) |
| Radius | 12px |
| Shadow | `0 8px 24px rgba(0,0,0,0.5)` |
| Width | 560px |
| Max height | 400px |
| Backdrop | `rgba(23,27,38,0.6)` blur(4px) |
| Input height | 44px |
| Input font | `Inter`, 15px, `--text1` |
| Item height | 36px |
| Item font | `Inter`, 13px |
| Item shortcut font | `JetBrains Mono`, 11px, `--text3` |

### HTML

```html
<div class="trae-palette-backdrop">
  <div class="trae-palette" role="dialog" aria-label="Command Palette">
    <div class="trae-palette__input-wrap">
      <span class="trae-palette__icon">⌘</span>
      <input class="trae-palette__input" type="text" placeholder="Type a command…" autofocus />
    </div>
    <ul class="trae-palette__list" role="listbox">
      <li class="trae-palette__item trae-palette__item--active" role="option">
        <span class="trae-palette__item-label">Open File</span>
        <kbd class="trae-palette__item-shortcut">⌘P</kbd>
      </li>
      <li class="trae-palette__item" role="option">
        <span class="trae-palette__item-label">Toggle Terminal</span>
        <kbd class="trae-palette__item-shortcut">⌘`</kbd>
      </li>
    </ul>
  </div>
</div>
```

### CSS

```css
.trae-palette-backdrop {
  position: fixed;
  inset: 0;
  background: rgba(23,27,38,0.6);
  backdrop-filter: blur(4px);
  display: flex;
  justify-content: center;
  padding-top: 20vh;
  z-index: 9999;
}
.trae-palette {
  background: var(--surface1);
  border: 1px solid var(--border-visible);
  border-radius: 12px;
  width: 560px;
  max-height: 400px;
  box-shadow: 0 8px 24px rgba(0,0,0,0.5);
  display: flex;
  flex-direction: column;
  overflow: hidden;
}
.trae-palette__input-wrap {
  display: flex;
  align-items: center;
  padding: 0 16px;
  height: 44px;
  border-bottom: 1px solid var(--border-visible);
  gap: 8px;
}
.trae-palette__icon { color: var(--text3); font-size: 14px; }
.trae-palette__input {
  flex: 1;
  background: transparent;
  border: none;
  outline: none;
  color: var(--text1);
  font-family: 'Inter', sans-serif;
  font-size: 15px;
}
.trae-palette__input::placeholder { color: var(--text3); }
.trae-palette__list {
  list-style: none;
  margin: 0;
  padding: 4px;
  overflow-y: auto;
}
.trae-palette__item {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 36px;
  padding: 0 12px;
  border-radius: 6px;
  cursor: pointer;
  color: var(--text1);
  font-family: 'Inter', sans-serif;
  font-size: 13px;
}
.trae-palette__item:hover,
.trae-palette__item--active {
  background: var(--surface2);
}
.trae-palette__item-shortcut {
  font-family: 'JetBrains Mono', monospace;
  font-size: 11px;
  color: var(--text3);
}
```

### States

| State | Treatment |
|-------|----------|
| **Default** | First item pre-selected |
| **Hover** | `--surface2` background |
| **Active (keyboard)** | `--surface2` background, 2px left `--accent` border |
| **No results** | Centered `--text3` message: "No matching commands" |

---

## 21. STATUS BAR

The bottom bar showing branch, errors, encoding, language mode.

### Specs

| Property | Value |
|----------|-------|
| Height | 24px |
| Background | `--background` (`#171B26`) |
| Border top | 1px solid `--border` (`#262A37`) |
| Font | `Inter`, 11px, `--text3` |
| Item padding | 0 8px |
| Item gap | 0 (items are flush) |
| Hover background | `rgba(255,255,255,0.06)` |
| Icon size | 14px |

### HTML

```html
<footer class="trae-statusbar">
  <div class="trae-statusbar__left">
    <button class="trae-statusbar__item">
      <span class="icon icon-git-branch"></span>
      <span>main</span>
    </button>
    <button class="trae-statusbar__item trae-statusbar__item--error">
      <span class="icon icon-circle-x"></span>
      <span>2</span>
    </button>
    <button class="trae-statusbar__item trae-statusbar__item--warning">
      <span class="icon icon-alert-triangle"></span>
      <span>5</span>
    </button>
  </div>
  <div class="trae-statusbar__right">
    <button class="trae-statusbar__item">Ln 42, Col 18</button>
    <button class="trae-statusbar__item">UTF-8</button>
    <button class="trae-statusbar__item">TypeScript</button>
    <button class="trae-statusbar__item trae-statusbar__item--accent">
      <span class="icon icon-sparkles"></span>
      <span>Trae AI</span>
    </button>
  </div>
</footer>
```

### CSS

```css
.trae-statusbar {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 24px;
  background: var(--background);
  border-top: 1px solid var(--border);
  font-family: 'Inter', sans-serif;
  font-size: 11px;
  color: var(--text3);
  padding: 0;
  user-select: none;
}
.trae-statusbar__left,
.trae-statusbar__right {
  display: flex;
  align-items: center;
  height: 100%;
}
.trae-statusbar__item {
  display: flex;
  align-items: center;
  gap: 4px;
  padding: 0 8px;
  height: 100%;
  background: none;
  border: none;
  color: inherit;
  font: inherit;
  cursor: pointer;
}
.trae-statusbar__item:hover { background: rgba(255,255,255,0.06); }
.trae-statusbar__item--error { color: var(--error); }
.trae-statusbar__item--warning { color: var(--warning); }
.trae-statusbar__item--accent { color: var(--accent); }
```

---

## 22. TOGGLE / SWITCH

### Specs

| Property | Value |
|----------|-------|
| Track width | 36px |
| Track height | 20px |
| Track radius | 10px (pill) |
| Thumb size | 16px |
| Thumb radius | 50% (circle) |
| Thumb offset (from edge) | 2px |
| Label position | right of track |
| Label gap | 8px |
| Label font | `Inter`, 14px, `--text1` |

### States

| State | Track Background | Thumb |
|-------|-----------------|-------|
| **Off (default)** | `--surface3` (`#363B4E`) | `#FFFFFF` |
| **On** | `--accent` (`#10B981`) | `#FFFFFF` |
| **Hover** | Track lightens 8% | — |
| **Disabled** | Opacity 0.4, no interaction | — |
| **Focus** | `0 0 0 2px var(--accent)` ring | — |

### HTML

```html
<label class="trae-toggle">
  <input type="checkbox" class="trae-toggle__input" />
  <span class="trae-toggle__track">
    <span class="trae-toggle__thumb"></span>
  </span>
  <span class="trae-toggle__label">Enable AI suggestions</span>
</label>
```

### CSS

```css
.trae-toggle {
  display: inline-flex;
  align-items: center;
  gap: 8px;
  cursor: pointer;
  font-family: 'Inter', sans-serif;
  font-size: 14px;
  color: var(--text1);
}
.trae-toggle__input { position: absolute; opacity: 0; width: 0; height: 0; }
.trae-toggle__track {
  position: relative;
  width: 36px;
  height: 20px;
  background: var(--surface3);
  border-radius: 10px;
  transition: background 120ms ease-out;
}
.trae-toggle__thumb {
  position: absolute;
  top: 2px;
  left: 2px;
  width: 16px;
  height: 16px;
  background: #FFFFFF;
  border-radius: 50%;
  transition: transform 120ms ease-out;
}
.trae-toggle__input:checked + .trae-toggle__track {
  background: var(--accent);
}
.trae-toggle__input:checked + .trae-toggle__track .trae-toggle__thumb {
  transform: translateX(16px);
}
.trae-toggle:hover .trae-toggle__track {
  filter: brightness(1.08);
}
.trae-toggle__input:focus-visible + .trae-toggle__track {
  box-shadow: 0 0 0 2px var(--accent);
}
.trae-toggle__input:disabled + .trae-toggle__track {
  opacity: 0.4;
  pointer-events: none;
}
```

---

## 23. ALERT / BANNER

### Specs

| Property | Value |
|----------|-------|
| Radius | 8px |
| Padding | 12px 16px |
| Icon size | 16px |
| Icon gap | 8px |
| Font (title) | `Inter`, 13px, weight 500 |
| Font (description) | `Inter`, 13px, `--text2` |
| Dismiss button | 16px ghost icon button, top-right |
| Layout | `flex-row`, icon + content + dismiss |

### Semantic Variants

| Variant | Background | Border | Icon color | Text color |
|---------|-----------|--------|-----------|------------|
| Info | `rgba(56,123,255,0.08)` | 1px solid `rgba(56,123,255,0.2)` | `#387BFF` | `--text1` |
| Success | `rgba(16,185,129,0.08)` | 1px solid `rgba(16,185,129,0.2)` | `--success` | `--text1` |
| Warning | `rgba(235,155,97,0.08)` | 1px solid `rgba(235,155,97,0.2)` | `--warning` | `--text1` |
| Error | `rgba(204,75,83,0.08)` | 1px solid `rgba(204,75,83,0.2)` | `--error` | `--text1` |

---

## 24. PROGRESS BAR

### Specs

| Property | Value |
|----------|-------|
| Height | 4px |
| Track radius | 2px |
| Track background | `--surface3` (`#363B4E`) |
| Fill color | `--accent` (`#10B981`) |
| Fill radius | 2px |
| Label position | above bar, right-aligned |
| Label font | `JetBrains Mono`, 11px, `--text3` |
| Indeterminate animation | 1.5s ease-in-out infinite shimmer left-to-right |

### Semantic Fill Colors

| Variant | Fill |
|---------|------|
| Default | `--accent` |
| Success | `--success` |
| Warning | `--warning` |
| Error | `--error` |

---

## 25. SKELETON

### Specs

| Property | Value |
|----------|-------|
| Background | `--surface2` (`#2A2E3E`) |
| Shimmer color | `--surface3` (`#363B4E`) |
| Radius | Match target component radius |
| Animation | linear shimmer sweep, left to right |
| Animation duration | 1500ms |

---

## STATE PATTERNS

These patterns apply globally across all components.

### Empty State
- Layout: centered, generous top padding (80px+)
- Icon: 48px outline icon in `--text3`
- Headline: `Inter` 16px weight 500, `--text2`
- Description: `Inter` 14px, `--text3`, max 2 lines
- CTA: primary button, 16px below description

### Loading
- Inline: 16px spinner in `--accent`
- Full screen: centered spinner + "Loading…" in `--text3`
- Content appearance: fade-in 180ms ease-out

### Error
- Inline (field): `--error` text in 12px below element
- Screen-level: centered icon + message + retry button
- Tone: factual and helpful — "Something went wrong. Try again."

### Disabled
- Opacity 0.4, `pointer-events: none`, maintains layout
- Borders fade to `--border` default
- No hover/focus states

---

## IMPLEMENTATION NOTES

### Semantic Token CSS Custom Properties

All components reference these custom properties. Apply them at `:root` or on a `.trae-dark` / `.trae-light` scope:

```css
.trae-dark {
  --background: #171B26;
  --surface1: #262A37;
  --surface2: #2A2E3E;
  --surface3: #363B4E;
  --border: #262A37;
  --border-visible: #363B4E;
  --text1: #C9D1D9;
  --text2: #9599A6;
  --text3: #737780;
  --text4: #5C6373;
  --accent: #10B981;
  --accent-subtle: #022C22;
  --success: #10B981;
  --warning: #EB9B61;
  --error: #CC4B53;
}
```

### Font Stack

```css
--font-body: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
--font-mono: 'JetBrains Mono', 'Fira Code', 'Cascadia Code', monospace;
```

### Motion

All transitions use `ease-out` easing. Duration tiers: 120ms (fast — hover, toggle), 180ms (normal — fade-in, expand), 300ms (slow — modals, overlays). The personality is **mechanical** — no bounces, no spring physics, just crisp state changes.
