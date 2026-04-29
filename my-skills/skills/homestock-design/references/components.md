# HomeStock — Components

## 1. BUTTONS

### Variants

| Variant | Background | Text | Border | Radius | Height |
|---------|-----------|------|--------|--------|--------|
| Primary | `var(--accent)` | `#FFFFFF` | none | 8px | 40px |
| Secondary | `var(--surface1)` | `var(--text1)` | `1px solid var(--border-visible)` | 8px | 40px |
| Ghost | transparent | `var(--accent)` | `1px solid var(--accent)` | 8px | 36px |
| Destructive | `var(--error)` | `#FFFFFF` | none | 8px | 40px |

### Specs

| Property | Value |
|----------|-------|
| Height (large) | 40px |
| Height (small) | 32px |
| Padding (large) | 10px 20px |
| Padding (small) | 6px 16px |
| Font | "Noto Sans SC" 500, 14px |
| Min touch target | 44px |

### States

| State | Change |
|-------|--------|
| **Hover** | Primary: background `#388E3C`. Secondary: background `var(--surface2)`. Ghost: background `var(--accent-subtle)` |
| **Active / Pressed** | Primary: background `#2E7D32`. Others: darken one step |
| **Disabled** | Opacity 0.4, no interaction |
| **Focus** | `0 0 0 3px var(--accent-subtle)` ring |

---

## 2. CARDS / SURFACES

### Standard Card
- Background: `var(--surface1)` (#FFFFFF)
- Border: none (shadow-defined) or `1px solid var(--border)` in dark mode
- Radius: 12px
- Padding: 20px 24px
- Shadow: `0 1px 3px rgba(16,24,40,0.06), 0 1px 2px rgba(16,24,40,0.04)`

### Stat Card (signature component)
- Background: `var(--surface1)`
- Radius: 12px
- Padding: 20px
- Layout: 48px icon container (left) + text block (right)
- Icon container: 48px × 48px, radius 12px, filled with category tint color
- Title: `--caption`, `--text3`
- Value: `--display`, `--text1`, font-weight 600, mono font
- Change: `--caption`, semantic color (green up / red down)

### List Card
- Background: `var(--surface1)`
- Radius: 12px
- Padding: 20px 24px
- Header: card title (`--h2`, `--text1`) + "查看全部 >" link (`--caption`, `--accent`)
- Content: vertical stack of list rows

### Content Layout
- Title: `--h2`, `--text1`
- Description: `--body-sm`, `--text2`
- Metadata: `--caption`, `--text3`
- Internal spacing between elements: `--space-sm` (8px)
- Press state: background `var(--surface2)` transition 150ms

---

## 3. INPUTS

### Text Field

| Property | Value |
|----------|-------|
| Height | 40px |
| Background | `var(--surface1)` |
| Border (default) | `1px solid var(--border-visible)` |
| Border (focus) | `1px solid var(--accent)` |
| Border (error) | `1px solid var(--error)` |
| Radius | 8px |
| Padding | 10px 12px |
| Font | "Noto Sans SC", `--body` |
| Placeholder color | `--text3` |

### Search Bar (signature component)
- Height: 40px
- Radius: 999px (pill)
- Background: `var(--surface2)`
- Border: none
- Left icon: search icon in `--text3`
- Placeholder: "搜索物资、分类或位置..."
- Focus: border `1px solid var(--accent)`, background `var(--surface1)`

### States

| State | Treatment |
|-------|-----------|
| **Default** | `1px solid var(--border-visible)` |
| **Focus** | `1px solid var(--accent)`. Box-shadow: `0 0 0 3px var(--accent-subtle)` |
| **Error** | `1px solid var(--error)`. Error text below in `--error`, `--caption` |
| **Disabled** | Opacity 0.4, no interaction |

---

## 4. LISTS / DATA ROWS

### Standard Row (inventory, usage, expiry)

| Property | Value |
|----------|-------|
| Min height | 56px |
| Padding | 12px 0 |
| Divider | `1px solid var(--border)` between rows |
| Layout | 40px image/icon (left) + text block (center) + status/action (right) |

### Inventory Alert Row
- Image: 40px × 40px, radius 8px, product thumbnail
- Line 1: product name in `--body`, `--text1`, weight 500
- Line 2: category label in `--body-sm`, `--text3`
- Right block: "剩余 N 件" in `--body-sm`, `--error` (red) + "去补货" ghost button

### Usage Record Row
- Image: 40px × 40px, radius 8px, product thumbnail
- Line 1: product name in `--body`, `--text1`
- Line 2: category in `--body-sm`, `--text3`
- Center: "-1 盒" quantity in `--body`, `--text1`, mono font
- Right: timestamp in `--caption`, `--text3` + user name

### Expiry Row
- Image: 40px × 40px product thumbnail
- Line 1: product name + category
- Center: expiry date in `--body-sm`, `--text2`
- Right: "剩余N天" badge in `--error` or `--warning`

### Interaction States

| State | Treatment |
|-------|-----------|
| **Default** | Transparent background |
| **Pressed** | Background `var(--surface2)` |
| **Selected** | Background `var(--accent-subtle)`, left accent bar 3px |

---

## 5. NAVIGATION / SIDEBAR

### Sidebar Navigation

| Property | Value |
|----------|-------|
| Width | 220px |
| Background | `var(--surface1)` |
| Border-right | `1px solid var(--border)` |
| Logo area | Brand logo + text, padding 20px |
| Item height | 40px |
| Item padding | 10px 16px |
| Item radius | 8px |
| Item font | "Noto Sans SC" 500, 14px |
| Icon size | 20px, in `--text3` (inactive) or `--accent` (active) |

### Nav Item States

| State | Background | Text | Icon |
|-------|-----------|------|------|
| **Default** | transparent | `--text2` | `--text3` |
| **Hover** | `var(--surface2)` | `--text1` | `--text2` |
| **Active** | `var(--accent-subtle)` | `--accent` | `--accent` |

### Sidebar Sections
- Sections separated by a 1px `var(--border)` divider with 12px vertical margin
- Section labels: `--label`, `--text3`, uppercase-excluded (Chinese), margin-bottom 8px
- Collapse arrow: 16px chevron, transitions 150ms rotation

---

## 6. TABS

| Property | Value |
|----------|-------|
| Container height | 44px |
| Tab padding | 0 16px |
| Font | "Noto Sans SC" 500, 14px |
| Inactive text | `--text3` |
| Active text | `--accent` |
| Indicator | 2px solid `--accent`, bottom, width = text width, transition 250ms |
| Background | transparent |

---

## 7. CATEGORY TAGS / BADGES

### Category Tag

| Property | Value |
|----------|-------|
| Height | 24px |
| Padding | 4px 10px |
| Radius | 999px (pill) |
| Font | "Noto Sans SC" 500, 12px |
| Background | category tint color (e.g. `--cat-food-bg`) |
| Text color | category full color (e.g. `--cat-food`) |

### Category Color Map

| Category | Full Color | Tint Background |
|----------|-----------|----------------|
| 食品 (Food) | `#43A047` | `#E8F5E9` |
| 日用 (Daily) | `#4A90D9` | `#E3F2FD` |
| 清洁 (Cleaning) | `#FF9800` | `#FFF8E1` |
| 个护 (Personal) | `#E91E63` | `#FCE4EC` |
| 健康 (Health) | `#9C27B0` | `#F3E5F5` |
| 其他 (Other) | `#7C4DFF` | `#EDE7F6` |

### Numeric Badge (count indicator)

| Property | Value |
|----------|-------|
| Min-width | 20px |
| Height | 20px |
| Radius | 999px |
| Background | `--accent` (active) or `--text4` (inactive) |
| Text | `#FFFFFF`, 11px, weight 600, center-aligned |

---

## 8. STATUS INDICATORS

### Expiry Status

| Status | Text | Color | Background |
|--------|------|-------|-----------|
| Expired | 已过期 | `--error` | `--error-bg` |
| Expiring (< 7 days) | 即将过期 | `--warning` | `--warning-bg` |
| Normal | 正常 | `--success` | `--success-bg` |

### Stock Level

| Level | Text | Color |
|-------|------|-------|
| Out of stock | 缺货 | `--error` |
| Low stock | 库存不足 | `--warning` |
| In stock | 充足 | `--success` |

### Change Indicator
- Positive: `+12%` in `--success`, `--caption` size, with up-arrow icon
- Negative: `-8%` in `--error`, `--caption` size, with down-arrow icon
- Neutral: `0%` in `--text3`

---

## 9. MODAL / DIALOG

| Property | Value |
|----------|-------|
| Overlay | `rgba(16,24,40,0.5)` |
| Container width | 480px (small), 640px (medium), 800px (large) |
| Background | `var(--surface1)` |
| Radius | 16px |
| Shadow | `--shadow-3` |
| Padding | 24px |
| Header | `--h2` title + close icon button (24px) top-right |
| Footer | right-aligned buttons with 12px gap |
| Animation | fade-in + scale from 0.95 to 1, 250ms `--ease-medium` |

---

## 10. DROPDOWN / SELECT

| Property | Value |
|----------|-------|
| Trigger | same specs as text field (40px height, 8px radius) |
| Right icon | chevron-down, 16px, `--text3` |
| Dropdown panel | `var(--surface1)`, `--shadow-2`, radius 12px, max-height 320px |
| Option height | 40px |
| Option padding | 10px 12px |
| Option hover | `var(--surface2)` |
| Option selected | `var(--accent-subtle)`, checkmark icon in `--accent` |
| Animation | slide-down + fade, 150ms |

---

## 11. TOOLTIP

| Property | Value |
|----------|-------|
| Background | `var(--text1)` (dark on light, light on dark) |
| Text | `#FFFFFF` (light mode) |
| Font | `--caption` |
| Padding | 6px 10px |
| Radius | 6px |
| Max-width | 240px |
| Arrow | 6px CSS triangle |
| Delay | 300ms show, 0ms hide |

---

## 12. PROGRESS / METER

### Progress Bar
- Height: 8px
- Radius: 4px (pill)
- Track: `var(--surface3)`
- Fill: `var(--accent)` (normal), `--warning` (medium), `--error` (critical)
- Animation: width transition 350ms `--ease-slow`

### Circular Progress (for stat cards)
- Size: 48px
- Stroke: 4px
- Track: `var(--surface3)`
- Fill: same color rules as progress bar
- Center text: percentage in `--body-sm`, `--text1`, mono font

---

## 13. TABLE

| Property | Value |
|----------|-------|
| Container | `var(--surface1)`, radius 12px, `--shadow-1` |
| Header row | background `var(--surface2)`, height 44px |
| Header text | `--body-sm`, `--text3`, weight 500 |
| Body row | height 56px, border-bottom `1px solid var(--border)` |
| Body text | `--body`, `--text1` |
| Hover row | background `var(--surface2)` |
| Selected row | background `var(--accent-subtle)` |
| Padding per cell | 12px 16px |

---

## 14. TOGGLE / SWITCH

| Property | Value |
|----------|-------|
| Track width | 44px |
| Track height | 24px |
| Track radius | 12px |
| Track (off) | `var(--surface3)` |
| Track (on) | `var(--accent)` |
| Thumb | 20px circle, `#FFFFFF`, `--shadow-1` |
| Thumb travel | 20px |
| Animation | 200ms `--ease-fast` |

---

## 15. CHECKBOX / RADIO

### Checkbox
- Size: 20px
- Radius: 4px
- Border (unchecked): `2px solid var(--border-visible)`
- Background (checked): `var(--accent)`
- Check icon: 12px, white, Phosphor check-bold
- Focus ring: `0 0 0 3px var(--accent-subtle)`

### Radio
- Size: 20px
- Radius: 50%
- Border (unselected): `2px solid var(--border-visible)`
- Fill (selected): `var(--accent)` outer, white inner dot 8px

---

## 16. AVATAR

| Size | Dimensions | Radius | Font |
|------|-----------|--------|------|
| Small | 28px | 8px | 11px |
| Medium | 36px | 10px | 13px |
| Large | 48px | 12px | 16px |

- Background: category color or `var(--accent-subtle)`
- Text: first character of name, white or accent
- Image: cover-fit, same radius
- Badge position: bottom-right, 25% size of avatar

---

## 17. ICON CONTAINERS (signature component)

Icons in HomeStock always appear inside a tinted background square.

| Property | Value |
|----------|-------|
| Container size | 40px (list), 48px (stat card), 56px (hero) |
| Radius | 12px |
| Background | 10% tint of semantic/category color |
| Icon size | 20px (40px container), 24px (48px container), 28px (56px container) |
| Icon color | full-saturation semantic/category color |
| Icon kit | Phosphor regular weight |

---

## 18. EMPTY STATE

| Property | Value |
|----------|-------|
| Illustration | 120px line illustration or Phosphor icon at 64px, `--text4` |
| Title | `--h3`, `--text2`, center-aligned |
| Description | `--body-sm`, `--text3`, center-aligned, max-width 320px |
| CTA | Primary button or text link |
| Vertical spacing | 16px between elements |

---

## 19. LOADING / SPINNER

- Single centered spinner, never skeleton screens
- Spinner: 32px, `--accent` for the arc, `--surface3` for the track
- Stroke: 3px
- Animation: `rotate 0.8s linear infinite`
- Full-page: centered vertically and horizontally with `--text3` "加载中..." text below

---

## 20. ALERT / BANNER

| Variant | Background | Border-left | Icon color | Text color |
|---------|-----------|-------------|-----------|-----------|
| Success | `--success-bg` | 3px `--success` | `--success` | `--text1` |
| Warning | `--warning-bg` | 3px `--warning` | `--warning` | `--text1` |
| Error | `--error-bg` | 3px `--error` | `--error` | `--text1` |
| Info | `var(--accent-subtle)` | 3px `var(--accent)` | `var(--accent)` | `--text1` |

Specs: height auto (min 48px), padding 12px 16px, radius 8px, icon 20px left, close button 16px right.

---

## 21. CHART / DATA VISUALIZATION

### Color Sequence (for pie/bar/line)
1. `#43A047` (green -- primary)
2. `#4A90D9` (blue)
3. `#FF9800` (orange)
4. `#E91E63` (pink)
5. `#9C27B0` (purple)
6. `#7C4DFF` (violet)

### Shared Chart Rules
- Background: transparent (sits on card white)
- Grid lines: `var(--border)`, 1px, dashed
- Axis labels: `--caption`, `--text3`
- Value labels: `--body-sm`, `--text1`, mono font
- Tooltip: same as component tooltip spec (Section 11)
- Legend: horizontal, below chart, dot (8px circle) + label (`--caption`, `--text2`)

---

## 22. BREADCRUMB

| Property | Value |
|----------|-------|
| Font | `--body-sm` |
| Link color | `--text3` |
| Active/current | `--text1`, weight 500 |
| Separator | `/` or chevron-right 12px, `--text4` |
| Spacing | 8px between items |

---

## 23. PAGINATION

| Property | Value |
|----------|-------|
| Button size | 32px x 32px |
| Radius | 8px |
| Default background | transparent |
| Hover background | `var(--surface2)` |
| Active background | `var(--accent)` |
| Active text | `#FFFFFF` |
| Font | `--body-sm`, weight 500 |
| Gap | 4px |

---

## 24. SKELETON (not used -- see Loading)

HomeStock does NOT use skeleton screens. See Section 19 (Loading / Spinner) instead. This is an intentional design decision documented in the anti-patterns.

---

## 25. TOAST / NOTIFICATION

Toasts appear as **top-center** banners, never bottom-right (see anti-patterns).

| Property | Value |
|----------|-------|
| Position | top center, 24px from top |
| Width | auto, max 480px |
| Background | `var(--surface1)` |
| Shadow | `--shadow-2` |
| Radius | 12px |
| Padding | 12px 16px |
| Icon | 20px, semantic color |
| Text | `--body`, `--text1` |
| Close | icon button 16px, `--text3` |
| Animation | slide-down + fade, 250ms in, 150ms out |
| Auto-dismiss | 4 seconds |

---

## 26. ACCORDION / COLLAPSIBLE

| Property | Value |
|----------|-------|
| Header height | 48px |
| Header padding | 12px 16px |
| Header font | `--body`, `--text1`, weight 500 |
| Chevron | 16px, `--text3`, rotates 180deg when open |
| Content padding | 0 16px 16px 16px |
| Divider | `1px solid var(--border)` between items |
| Animation | height auto + fade, 250ms `--ease-medium` |