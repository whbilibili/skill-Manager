# Birchline — Platform Mapping

## 1. HTML / CSS / WEB

### Font Loading

```html
<link rel="preconnect" href="https://fonts.googleapis.com">
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
<link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600&family=JetBrains+Mono:wght@400&display=swap" rel="stylesheet">
```

### CSS Custom Properties — Light Mode (Primary)

```css
:root {
  /* Colors */
  --background: #F8F3EA;
  --bg: var(--background);
  --surface1: #FDFAF5;
  --surface2: #F8F3EA;
  --surface3: #F0E9DA;
  --border: #F0E9DA;
  --border-visible: #E4D9C8;
  --text1: #2C2416;
  --text2: #7A6E5F;
  --text3: #A89880;
  --text4: #C8BAA4;
  --accent: #C17B3A;
  --accent-subtle: #FDF6EC;
  --success: #4A9B6A;
  --success-bg: #F0FDF4;
  --warning: #D97706;
  --warning-bg: #FFFBEB;
  --error: #DC4A4A;
  --error-bg: #FEF2F2;

  /* Fonts */
  --font-display: "DM Sans", system-ui, -apple-system, sans-serif;
  --font-body: "DM Sans", system-ui, -apple-system, sans-serif;
  --font-mono: "JetBrains Mono", "Fira Code", "Cascadia Code", monospace;

  /* Type Scale */
  --text-display: 28px;
  --text-heading: 20px;
  --text-subheading: 16px;
  --text-body: 14px;
  --text-body-sm: 13px;
  --text-caption: 11px;
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
  --radius-control: 6px;
  --radius-component: 8px;
  --radius-container: 12px;
  --radius-pill: 999px;

  /* Motion */
  --ease-fast: ease-in-out;
  --ease-medium: ease-in-out;
  --ease-slow: ease-in-out;
  --duration-fast: 120ms;
  --duration-medium: 200ms;
  --duration-slow: 300ms;

  /* Shadows (warm brown tint) */
  --shadow-1: 0 1px 3px rgba(44, 36, 22, 0.06), 0 1px 2px rgba(44, 36, 22, 0.04);
  --shadow-2: 0 4px 12px rgba(44, 36, 22, 0.08), 0 2px 4px rgba(44, 36, 22, 0.05);
  --shadow-3: 0 8px 32px rgba(44, 36, 22, 0.12), 0 4px 8px rgba(44, 36, 22, 0.06);
}
```

### Dark Mode

```css
@media (prefers-color-scheme: dark) {
  :root {
    --background: #1A1510;
    --bg: var(--background);
    --surface1: #2C2416;
    --surface2: #3D3530;
    --surface3: #5A5048;
    --border: #3D3530;
    --border-visible: #5A5048;
    --text1: #FDFAF5;
    --text2: #E4D9C8;
    --text3: #A89880;
    --text4: #7A6E5F;
    --accent: #E09A42;
    --accent-subtle: #2A1808;
    --success: #4A9B6A;
    --success-bg: #052e16;
    --warning: #D97706;
    --warning-bg: #1c1400;
    --error: #DC4A4A;
    --error-bg: #1c0000;
    --shadow-1: 0 1px 3px rgba(0, 0, 0, 0.25), 0 1px 2px rgba(0, 0, 0, 0.15);
    --shadow-2: 0 4px 12px rgba(0, 0, 0, 0.35), 0 2px 4px rgba(0, 0, 0, 0.20);
    --shadow-3: 0 8px 32px rgba(0, 0, 0, 0.45), 0 4px 8px rgba(0, 0, 0, 0.25);
  }
}

/* Class-based toggle alternative */
[data-theme="dark"] {
  --background: #1A1510;
  --bg: var(--background);
  --surface1: #2C2416;
  --surface2: #3D3530;
  --surface3: #5A5048;
  --border: #3D3530;
  --border-visible: #5A5048;
  --text1: #FDFAF5;
  --text2: #E4D9C8;
  --text3: #A89880;
  --text4: #7A6E5F;
  --accent: #E09A42;
  --accent-subtle: #2A1808;
  --success: #4A9B6A;
  --success-bg: #052e16;
  --warning: #D97706;
  --warning-bg: #1c1400;
  --error: #DC4A4A;
  --error-bg: #1c0000;
  --shadow-1: 0 1px 3px rgba(0, 0, 0, 0.25), 0 1px 2px rgba(0, 0, 0, 0.15);
  --shadow-2: 0 4px 12px rgba(0, 0, 0, 0.35), 0 2px 4px rgba(0, 0, 0, 0.20);
  --shadow-3: 0 8px 32px rgba(0, 0, 0, 0.45), 0 4px 8px rgba(0, 0, 0, 0.25);
}
```

### Component Snippets

```css
/* Slot Tag */
.slot-tag {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: var(--radius-pill);
  background: var(--accent-subtle);
  color: var(--accent);
  font-family: var(--font-mono);
  font-size: 12px;
  font-weight: 400;
  line-height: 1.5;
}

/* Plan Badge */
.plan-badge {
  display: inline-flex;
  align-items: center;
  padding: 2px 8px;
  border-radius: var(--radius-pill);
  font-family: var(--font-body);
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.04em;
}
.plan-badge--free   { background: #E8F0E0; color: #3A6B2A; }
.plan-badge--team   { background: #E0EAF5; color: #2A4A7A; }
.plan-badge--studio { background: #EDE0F5; color: #5A2A7A; }

/* Section Label */
.section-label {
  font-family: var(--font-body);
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--text3);
  margin-bottom: var(--space-sm);
}

/* Primary Button */
.btn-primary {
  height: 32px;
  padding: 0 16px;
  border-radius: var(--radius-control);
  border: none;
  background: var(--text1);
  color: var(--surface1);
  font-family: var(--font-body);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background var(--duration-fast) var(--ease-fast);
}
.btn-primary:hover { background: #3D3530; }
.btn-primary:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }
.btn-primary:disabled { opacity: 0.4; cursor: not-allowed; }

/* Secondary Button */
.btn-secondary {
  height: 32px;
  padding: 0 16px;
  border-radius: var(--radius-control);
  border: 1px solid var(--border-visible);
  background: var(--surface3);
  color: var(--text2);
  font-family: var(--font-body);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: background var(--duration-fast) var(--ease-fast);
}
.btn-secondary:hover { background: var(--surface2); }
.btn-secondary:focus-visible { outline: 2px solid var(--accent); outline-offset: 2px; }

/* Card */
.card {
  background: var(--surface1);
  border: 1px solid var(--border);
  border-radius: var(--radius-component);
  padding: var(--space-lg);
  box-shadow: var(--shadow-1);
}

/* Breadcrumb */
.breadcrumb {
  display: flex;
  align-items: center;
  gap: 6px;
  font-family: var(--font-body);
  font-size: 11px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.06em;
  color: var(--text3);
}
.breadcrumb-sep { color: var(--text3); }
.breadcrumb-current { color: var(--text2); }
```

---

## 2. SWIFTUI / iOS

### Font Registration

DM Sans and JetBrains Mono are not system fonts. Register them via `Info.plist` → `UIAppFonts` array, or use `@Font` custom font loading. For prototyping, substitute with SF Pro (body) and SF Mono (code).

### Color Extension

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB, red: Double(r)/255, green: Double(g)/255, blue: Double(b)/255, opacity: Double(a)/255)
    }
}

extension Color {
    // Light mode
    static let blBackground    = Color(hex: "F8F3EA")
    static let blSurface1      = Color(hex: "FDFAF5")
    static let blSurface2      = Color(hex: "F8F3EA")
    static let blSurface3      = Color(hex: "F0E9DA")
    static let blBorder        = Color(hex: "F0E9DA")
    static let blBorderVisible = Color(hex: "E4D9C8")
    static let blText1         = Color(hex: "2C2416")
    static let blText2         = Color(hex: "7A6E5F")
    static let blText3         = Color(hex: "A89880")
    static let blText4         = Color(hex: "C8BAA4")
    static let blAccent        = Color(hex: "C17B3A")
    static let blAccentSubtle  = Color(hex: "FDF6EC")
    static let blSuccess       = Color(hex: "4A9B6A")
    static let blWarning       = Color(hex: "D97706")
    static let blError         = Color(hex: "DC4A4A")
}
```

### Spacing & Radius Constants

```swift
enum BLSpacing {
    static let xxs: CGFloat = 2
    static let xs: CGFloat  = 4
    static let sm: CGFloat  = 8
    static let md: CGFloat  = 16
    static let lg: CGFloat  = 24
    static let xl: CGFloat  = 32
    static let xxl: CGFloat = 48
    static let xxxl: CGFloat = 64
    static let xxxxl: CGFloat = 96
}

enum BLRadius {
    static let element: CGFloat   = 4
    static let control: CGFloat   = 6
    static let component: CGFloat = 8
    static let container: CGFloat = 12
    static let pill: CGFloat      = 999
}
```

---

## 3. REACT / TAILWIND

### tailwind.config.js

```js
/** @type {import('tailwindcss').Config} */
module.exports = {
  content: ["./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        background: "var(--background)",
        surface: {
          1: "var(--surface1)",
          2: "var(--surface2)",
          3: "var(--surface3)",
        },
        border: {
          DEFAULT: "var(--border)",
          visible: "var(--border-visible)",
        },
        text: {
          1: "var(--text1)",
          2: "var(--text2)",
          3: "var(--text3)",
          4: "var(--text4)",
        },
        accent: {
          DEFAULT: "var(--accent)",
          subtle: "var(--accent-subtle)",
        },
        success: { DEFAULT: "var(--success)", bg: "var(--success-bg)" },
        warning: { DEFAULT: "var(--warning)", bg: "var(--warning-bg)" },
        error:   { DEFAULT: "var(--error)",   bg: "var(--error-bg)"   },
      },
      fontFamily: {
        display: ['"DM Sans"', "system-ui", "-apple-system", "sans-serif"],
        body:    ['"DM Sans"', "system-ui", "-apple-system", "sans-serif"],
        mono:    ['"JetBrains Mono"', '"Fira Code"', '"Cascadia Code"', "monospace"],
      },
      fontSize: {
        display:    ["28px", { lineHeight: "1.2",  letterSpacing: "-0.01em" }],
        heading:    ["20px", { lineHeight: "1.3",  letterSpacing: "-0.01em" }],
        subheading: ["16px", { lineHeight: "1.4",  letterSpacing: "0em"     }],
        body:       ["14px", { lineHeight: "1.6",  letterSpacing: "0em"     }],
        "body-sm":  ["13px", { lineHeight: "1.5",  letterSpacing: "0em"     }],
        caption:    ["11px", { lineHeight: "1.4",  letterSpacing: "0em"     }],
        label:      ["11px", { lineHeight: "1.3",  letterSpacing: "0.06em"  }],
      },
      spacing: {
        "2xs": "2px",
        xs:    "4px",
        sm:    "8px",
        md:    "16px",
        lg:    "24px",
        xl:    "32px",
        "2xl": "48px",
        "3xl": "64px",
        "4xl": "96px",
      },
      borderRadius: {
        element:   "4px",
        control:   "6px",
        component: "8px",
        container: "12px",
        pill:      "999px",
      },
      transitionTimingFunction: {
        fast:   "ease-in-out",
        medium: "ease-in-out",
        slow:   "ease-in-out",
      },
      transitionDuration: {
        fast:   "120ms",
        medium: "200ms",
        slow:   "300ms",
      },
      boxShadow: {
        1: "0 1px 3px rgba(44,36,22,0.06), 0 1px 2px rgba(44,36,22,0.04)",
        2: "0 4px 12px rgba(44,36,22,0.08), 0 2px 4px rgba(44,36,22,0.05)",
        3: "0 8px 32px rgba(44,36,22,0.12), 0 4px 8px rgba(44,36,22,0.06)",
      },
    },
  },
  plugins: [],
};
```

### Font Loading (npm)

```bash
npm install @fontsource/dm-sans @fontsource/jetbrains-mono
```

```js
import "@fontsource/dm-sans/400.css";
import "@fontsource/dm-sans/500.css";
import "@fontsource/dm-sans/600.css";
import "@fontsource/jetbrains-mono/400.css";
```
