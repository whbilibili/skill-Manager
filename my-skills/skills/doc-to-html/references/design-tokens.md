# Design Tokens — CSS 自定义属性系统

将以下代码放入 HTML 的 `<style>` 标签开头。根据选定的风格调整主色调变量。

```css
/* ============================================================
   设计令牌系统 — 所有样式值通过变量管理，禁止魔法数字
   ============================================================ */
:root {
  /* ── 主色调（从 color-palettes.md 选择一套） ── */
  --accent-start:   #667eea;
  --accent-end:     #764ba2;
  --accent-mid:     #7c6ef0;
  --accent-rgb:     102, 126, 234;

  /* ── 文字色 ── */
  --color-text-primary:   #0f0f23;
  --color-text-secondary: #4a4a6a;
  --color-text-muted:     #8888aa;
  --color-text-inverse:   #ffffff;

  /* ── 背景色 ── */
  --color-bg:        #fafafa;
  --color-surface:   #ffffff;
  --color-surface-2: #f4f4f8;
  --color-surface-3: #ededf5;

  /* ── 边框 ── */
  --color-border:       rgba(0, 0, 40, 0.08);
  --color-border-strong: rgba(0, 0, 40, 0.16);

  /* ── 间距（8px 基础单位） ── */
  --space-1:  0.25rem;   /*  4px */
  --space-2:  0.5rem;    /*  8px */
  --space-3:  0.75rem;   /* 12px */
  --space-4:  1rem;      /* 16px */
  --space-5:  1.25rem;   /* 20px */
  --space-6:  1.5rem;    /* 24px */
  --space-8:  2rem;      /* 32px */
  --space-10: 2.5rem;    /* 40px */
  --space-12: 3rem;      /* 48px */
  --space-16: 4rem;      /* 64px */
  --space-20: 5rem;      /* 80px */
  --space-24: 6rem;      /* 96px */

  /* ── 圆角 ── */
  --radius-sm:   6px;
  --radius-md:   12px;
  --radius-lg:   20px;
  --radius-xl:   32px;
  --radius-full: 9999px;

  /* ── 阴影 ── */
  --shadow-xs: 0 1px 2px rgba(0, 0, 20, 0.04);
  --shadow-sm: 0 1px 3px rgba(0, 0, 20, 0.04), 0 1px 2px rgba(0, 0, 20, 0.06);
  --shadow-md: 0 4px 12px rgba(0, 0, 20, 0.06), 0 2px 4px rgba(0, 0, 20, 0.04);
  --shadow-lg: 0 8px 32px rgba(0, 0, 20, 0.08), 0 4px 8px rgba(0, 0, 20, 0.04);
  --shadow-xl: 0 20px 60px rgba(0, 0, 20, 0.12), 0 8px 16px rgba(0, 0, 20, 0.06);

  /* ── 字体 ── */
  --font-sans: 'Inter', -apple-system, BlinkMacSystemFont,
               'Segoe UI', 'PingFang SC', 'Hiragino Sans GB',
               'Microsoft YaHei', sans-serif;
  --font-mono: 'JetBrains Mono', 'Fira Code', 'Cascadia Code',
               'Courier New', monospace;

  /* ── 字号 ── */
  --text-xs:   0.75rem;    /* 12px */
  --text-sm:   0.875rem;   /* 14px */
  --text-base: 1rem;       /* 16px */
  --text-lg:   1.125rem;   /* 18px */
  --text-xl:   1.25rem;    /* 20px */
  --text-2xl:  1.5rem;     /* 24px */
  --text-3xl:  1.875rem;   /* 30px */
  --text-4xl:  2.25rem;    /* 36px */
  --text-5xl:  3rem;       /* 48px */
  --text-6xl:  3.75rem;    /* 60px */

  /* ── 行高 ── */
  --leading-tight:  1.25;
  --leading-snug:   1.375;
  --leading-normal: 1.5;
  --leading-relaxed: 1.625;
  --leading-loose:  2;

  /* ── 过渡 ── */
  --transition-fast:   150ms ease;
  --transition-base:   250ms ease;
  --transition-slow:   400ms ease;
  --transition-spring: 300ms cubic-bezier(0.34, 1.56, 0.64, 1);

  /* ── 布局 ── */
  --container-sm:  640px;
  --container-md:  768px;
  --container-lg:  1024px;
  --container-xl:  1200px;
  --container-2xl: 1400px;
}

/* ── 深色模式 ── */
[data-theme="dark"] {
  --color-text-primary:   #e8e8f0;
  --color-text-secondary: #9898b8;
  --color-text-muted:     #5a5a7a;
  --color-bg:        #0f0f23;
  --color-surface:   #1a1a2e;
  --color-surface-2: #16213e;
  --color-surface-3: #1e2a45;
  --color-border:       rgba(255, 255, 255, 0.08);
  --color-border-strong: rgba(255, 255, 255, 0.16);
  --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.3);
  --shadow-md: 0 4px 12px rgba(0, 0, 0, 0.4);
  --shadow-lg: 0 8px 32px rgba(0, 0, 0, 0.5);
}

/* ── 基础重置 ── */
*, *::before, *::after {
  box-sizing: border-box;
  margin: 0;
  padding: 0;
}

html {
  scroll-behavior: smooth;
  font-size: 16px;
}

body {
  font-family: var(--font-sans);
  font-size: var(--text-base);
  line-height: var(--leading-relaxed);
  color: var(--color-text-primary);
  background: var(--color-bg);
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  text-rendering: optimizeLegibility;
}

/* ── 布局工具类 ── */
.container {
  max-width: var(--container-xl);
  margin: 0 auto;
  padding: 0 var(--space-6);
}

.container-narrow {
  max-width: var(--container-md);
  margin: 0 auto;
  padding: 0 var(--space-6);
}

.section {
  padding: var(--space-24) 0;
}

.section-sm {
  padding: var(--space-16) 0;
}

/* ── 文字渐变工具类 ── */
.text-gradient {
  background: linear-gradient(135deg, var(--accent-start), var(--accent-end));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

/* ── 渐变背景工具类 ── */
.bg-gradient {
  background: linear-gradient(135deg, var(--accent-start), var(--accent-end));
}

/* ── 阅读进度条（纯 CSS，无需 JS） ── */
.progress-bar {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  height: 3px;
  z-index: 9999;
  background: linear-gradient(90deg, var(--accent-start), var(--accent-end));
  transform-origin: left center;
  transform: scaleX(0);
  animation: scroll-progress linear both;
  animation-timeline: scroll(root block);
}

@keyframes scroll-progress {
  from { transform: scaleX(0); }
  to   { transform: scaleX(1); }
}

/* ── 焦点样式（无障碍） ── */
:focus-visible {
  outline: 2px solid var(--accent-mid);
  outline-offset: 3px;
  border-radius: var(--radius-sm);
}

/* ── 减少运动偏好回退 ── */
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
  .progress-bar {
    animation: none;
    transform: scaleX(1);
  }
}

/* ── 响应式断点 ── */
/* Mobile: < 640px */
/* Tablet: 640px - 1024px */
/* Desktop: > 1024px */
@media (max-width: 640px) {
  .container, .container-narrow {
    padding: 0 var(--space-4);
  }
  .section {
    padding: var(--space-16) 0;
  }
}
```
