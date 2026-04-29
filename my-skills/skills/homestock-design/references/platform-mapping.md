# HomeStock -- Platform Mapping

## 1. HTML / CSS / WEB

### Font Loading

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=Noto+Sans+SC:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap" rel="stylesheet">
```

### Icon Kit Loading

```html
<link rel="stylesheet" href="https://unpkg.com/@phosphor-icons/web@2/src/regular/style.css">
```

### CSS Custom Properties -- Light Mode (Primary)

```css
:root,
[data-theme="light"] {
  /* Colors */
  --background: #F0F2F5;
  --bg: var(--background);
  --surface1: #FFFFFF;
  --surface2: #F7F8FA;
  --surface3: #E4E7EC;
  --border: #E4E7EC;
  --border-visible: #D0D5DD;
  --text1: #101828;
  --text2: #475467;
  --text3: #667085;
  --text4: #98A2B3;
  --accent: #43A047;
  --accent-subtle: #E8F5E9;
  --success: #43A047;
  --success-bg: #E8F5E9;
  --warning: #FF9800;
  --warning-bg: #FFF8E1;
  --error: #E53935;
  --error-bg: #FEF3F2;

  /* Category colors */
  --cat-food: #43A047;
  --cat-food-bg: #E8F5E9;
  --cat-daily: #4A90D9;
  --cat-daily-bg: #E3F2FD;
  --cat-cleaning: #FF9800;
  --cat-cleaning-bg: #FFF8E1;
  --cat-personal: #E91E63;
  --cat-personal-bg: #FCE4EC;
  --cat-health: #9C27B0;
  --cat-health-bg: #F3E5F5;
  --cat-other: #7C4DFF;
  --cat-other-bg: #EDE7F6;

  /* Fonts */
  --font-display: "Noto Sans SC", "PingFang SC", -apple-system, sans-serif;
  --font-body: "Noto Sans SC", "PingFang SC", -apple-system, sans-serif;
  --font-mono: "JetBrains Mono", "SF Mono", "Menlo", monospace;

  /* Type Scale */
  --text-display: 28px;
  --text-h1: 24px;
  --text-h2: 20px;
  --text-h3: 16px;
  --text-body: 14px;
  --text-body-sm: 13px;
  --text-caption: 12px;
  --text-label: 11px;

  /* Spacing */
  --space-2xs: 2px;
  --space-xs: 4px;
  --space-sm: 8px;
  --space-md: 16px;
  --space-lg: 24px;
  --space-xl: 32px;
  --space-2xl: 48px;
  --space-3xl: 64px;
  --space-4xl: 96px;

  /* Radii */
  --radius-element: 4px;
  --radius-control: 8px;
  --radius-component: 12px;
  --radius-container: 16px;
  --radius-pill: 999px;

  /* Motion */
  --ease-fast: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-medium: cubic-bezier(0.4, 0, 0.2, 1);
  --ease-slow: cubic-bezier(0.4, 0, 0.2, 1);
  --duration-fast: 150ms;
  --duration-medium: 250ms;
  --duration-slow: 350ms;

  /* Shadows */
  --shadow-1: 0 1px 3px rgba(16,24,40,0.06), 0 1px 2px rgba(16,24,40,0.04);
  --shadow-2: 0 4px 12px rgba(16,24,40,0.08), 0 2px 4px rgba(16,24,40,0.04);
  --shadow-3: 0 12px 32px rgba(16,24,40,0.12), 0 4px 8px rgba(16,24,40,0.06);
}
```

### Dark Mode

```css
[data-theme="dark"] {
  --background: #0C111D;
  --bg: var(--background);
  --surface1: #101828;
  --surface2: #1D2939;
  --surface3: #344054;
  --border: #1D2939;
  --border-visible: #344054;
  --text1: #F7F8FA;
  --text2: #98A2B3;
  --text3: #667085;
  --text4: #475467;
  --accent: #66BB6A;
  --accent-subtle: #0A2E0E;
  --success: #43A047;
  --success-bg: #0A2E0E;
  --warning: #FF9800;
  --warning-bg: #3D2200;
  --error: #E53935;
  --error-bg: #3D0D0D;

  /* Category colors stay same in dark mode */
  --cat-food-bg: #0A2E0E;
  --cat-daily-bg: #0D1F33;
  --cat-cleaning-bg: #3D2200;
  --cat-personal-bg: #3D0D1F;
  --cat-health-bg: #2A0A33;
  --cat-other-bg: #1A0D33;

  --shadow-1: 0 1px 3px rgba(0,0,0,0.3), 0 1px 2px rgba(0,0,0,0.2);
  --shadow-2: 0 4px 12px rgba(0,0,0,0.4), 0 2px 4px rgba(0,0,0,0.2);
  --shadow-3: 0 12px 32px rgba(0,0,0,0.5), 0 4px 8px rgba(0,0,0,0.3);
}
```

---

## 2. SWIFTUI / iOS

### Color Extension

```swift
extension Color {
    // Light mode
    static let hsBackground = Color(hex: "F0F2F5")
    static let hsSurface1 = Color(hex: "FFFFFF")
    static let hsSurface2 = Color(hex: "F7F8FA")
    static let hsSurface3 = Color(hex: "E4E7EC")
    static let hsBorder = Color(hex: "E4E7EC")
    static let hsBorderVisible = Color(hex: "D0D5DD")
    static let hsText1 = Color(hex: "101828")
    static let hsText2 = Color(hex: "475467")
    static let hsText3 = Color(hex: "667085")
    static let hsText4 = Color(hex: "98A2B3")
    static let hsAccent = Color(hex: "43A047")
    static let hsAccentSubtle = Color(hex: "E8F5E9")
    static let hsSuccess = Color(hex: "43A047")
    static let hsWarning = Color(hex: "FF9800")
    static let hsError = Color(hex: "E53935")
}
```

### Font Extension

```swift
extension Font {
    static func hsDisplay(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .custom("NotoSansSC-SemiBold", size: size)
    }
    static func hsBody(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("NotoSansSC-Regular", size: size)
    }
    static func hsMono(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("JetBrainsMono-Regular", size: size)
    }

    static let hsDisplayLarge = hsDisplay(28)
    static let hsHeading = hsDisplay(24)
    static let hsSubheading = hsBody(20, weight: .semibold)
    static let hsBodyText = hsBody(14)
    static let hsBodySmall = hsBody(13)
    static let hsCaption = hsBody(12)
    static let hsLabel = hsBody(11, weight: .medium)
}
```

### Spacing and Radius Constants

```swift
enum HSSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
    static let xxxxl: CGFloat = 96
}

enum HSRadius {
    static let element: CGFloat = 4
    static let control: CGFloat = 8
    static let component: CGFloat = 12
    static let container: CGFloat = 16
    static let pill: CGFloat = 999
}
```

---

## 3. REACT / TAILWIND

### tailwind.config.js

```js
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        surface: { 1: "var(--surface1)", 2: "var(--surface2)", 3: "var(--surface3)" },
        border: { DEFAULT: "var(--border)", visible: "var(--border-visible)" },
        text: { 1: "var(--text1)", 2: "var(--text2)", 3: "var(--text3)", 4: "var(--text4)" },
        accent: { DEFAULT: "var(--accent)", subtle: "var(--accent-subtle)" },
        success: { DEFAULT: "var(--success)", bg: "var(--success-bg)" },
        warning: { DEFAULT: "var(--warning)", bg: "var(--warning-bg)" },
        error: { DEFAULT: "var(--error)", bg: "var(--error-bg)" },
      },
      fontFamily: {
        display: ['"Noto Sans SC"', '"PingFang SC"', "sans-serif"],
        body: ['"Noto Sans SC"', '"PingFang SC"', "sans-serif"],
        mono: ['"JetBrains Mono"', '"SF Mono"', "monospace"],
      },
      fontSize: {
        display: ["28px", { lineHeight: "1.2", letterSpacing: "-0.01em" }],
        h1: ["24px", { lineHeight: "1.25", letterSpacing: "-0.01em" }],
        h2: ["20px", { lineHeight: "1.3" }],
        h3: ["16px", { lineHeight: "1.4" }],
        body: ["14px", { lineHeight: "1.5" }],
        "body-sm": ["13px", { lineHeight: "1.5" }],
        caption: ["12px", { lineHeight: "1.5" }],
        label: ["11px", { lineHeight: "1.4", letterSpacing: "0.02em" }],
      },
      spacing: {
        "2xs": "2px", xs: "4px", sm: "8px", md: "16px",
        lg: "24px", xl: "32px", "2xl": "48px", "3xl": "64px", "4xl": "96px",
      },
      borderRadius: {
        element: "4px", control: "8px", component: "12px",
        container: "16px", pill: "999px",
      },
      boxShadow: {
        1: "0 1px 3px rgba(16,24,40,0.06), 0 1px 2px rgba(16,24,40,0.04)",
        2: "0 4px 12px rgba(16,24,40,0.08), 0 2px 4px rgba(16,24,40,0.04)",
        3: "0 12px 32px rgba(16,24,40,0.12), 0 4px 8px rgba(16,24,40,0.06)",
      },
    },
  },
  plugins: [],
};
```
