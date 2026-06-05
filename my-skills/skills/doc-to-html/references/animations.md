# Animations — 完整动画代码库

将以下 CSS 放入 `<style>` 中，JS 放入 `<script>` 中。

---

## 1. 滚动进入动画（IntersectionObserver）

### CSS 动画类

```css
/* ── 基础类（所有需要动画的元素都加这个） ── */
.animate-on-scroll {
  opacity: 0;
  transition: opacity 0.6s ease, transform 0.6s ease;
}
.animate-on-scroll.visible {
  opacity: 1;
  transform: none !important;
}

/* ── 动画变体（配合 .animate-on-scroll 使用） ── */
.fade-up    { transform: translateY(32px); }
.fade-down  { transform: translateY(-32px); }
.fade-left  { transform: translateX(-48px); }
.fade-right { transform: translateX(48px); }
.scale-in   { transform: scale(0.88); }
.rotate-in  { transform: rotate(-4deg) scale(0.92); }
.blur-in    { filter: blur(8px); transform: translateY(16px); }

/* ── 级联延迟（用于卡片组，父元素加 .stagger） ── */
.stagger > *:nth-child(1)  { transition-delay: 0.00s; }
.stagger > *:nth-child(2)  { transition-delay: 0.08s; }
.stagger > *:nth-child(3)  { transition-delay: 0.16s; }
.stagger > *:nth-child(4)  { transition-delay: 0.24s; }
.stagger > *:nth-child(5)  { transition-delay: 0.32s; }
.stagger > *:nth-child(6)  { transition-delay: 0.40s; }
.stagger > *:nth-child(7)  { transition-delay: 0.48s; }
.stagger > *:nth-child(8)  { transition-delay: 0.56s; }

/* ── 减少运动偏好回退 ── */
@media (prefers-reduced-motion: reduce) {
  .animate-on-scroll {
    opacity: 1 !important;
    transform: none !important;
    transition: none !important;
    filter: none !important;
  }
}
```

### JS 初始化

```javascript
(function initScrollAnimations() {
  const prefersReducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)'
  ).matches;

  if (prefersReducedMotion) {
    document.querySelectorAll('.animate-on-scroll')
      .forEach(el => el.classList.add('visible'));
    return;
  }

  const observer = new IntersectionObserver(
    (entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.add('visible');
          observer.unobserve(entry.target); // 一次性，节省性能
        }
      });
    },
    {
      threshold: 0.1,
      rootMargin: '0px 0px -60px 0px' // 提前 60px 触发，更自然
    }
  );

  document.querySelectorAll('.animate-on-scroll')
    .forEach(el => observer.observe(el));
})();
```

**使用示例：**
```html
<!-- 单个元素 -->
<div class="animate-on-scroll fade-up">内容</div>

<!-- 卡片组（级联动画） -->
<div class="stagger">
  <div class="animate-on-scroll fade-up">卡片 1</div>
  <div class="animate-on-scroll fade-up">卡片 2</div>
  <div class="animate-on-scroll fade-up">卡片 3</div>
</div>
```

---

## 2. 数字计数动画

### CSS

```css
.counter-wrapper {
  /* 防止数字跳动时布局抖动 */
  font-variant-numeric: tabular-nums;
  min-width: 3ch;
  display: inline-block;
}
```

### JS

```javascript
(function initCounters() {
  const prefersReducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)'
  ).matches;

  function animateCounter(el) {
    const target = parseFloat(el.dataset.target);
    const decimals = el.dataset.decimals ? parseInt(el.dataset.decimals) : 0;
    const duration = 1800;
    const startTime = performance.now();

    function easeOutCubic(t) {
      return 1 - Math.pow(1 - t, 3);
    }

    function update(currentTime) {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const eased = easeOutCubic(progress);
      const current = eased * target;
      el.textContent = decimals > 0
        ? current.toFixed(decimals)
        : Math.floor(current).toLocaleString();
      if (progress < 1) requestAnimationFrame(update);
    }

    if (prefersReducedMotion) {
      el.textContent = decimals > 0
        ? target.toFixed(decimals)
        : target.toLocaleString();
    } else {
      requestAnimationFrame(update);
    }
  }

  const counterObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          animateCounter(entry.target);
          counterObserver.unobserve(entry.target);
        }
      });
    },
    { threshold: 0.5 }
  );

  document.querySelectorAll('.counter')
    .forEach(el => counterObserver.observe(el));
})();
```

**使用示例：**
```html
<!-- 整数 -->
<span class="counter" data-target="12500">0</span>

<!-- 带千分位 -->
<span class="counter" data-target="1234567">0</span>

<!-- 小数 -->
<span class="counter" data-target="98.6" data-decimals="1">0</span>
```

---

## 3. Sticky Scrollytelling（左文字右图形）

### CSS

```css
.scrolly-section {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: var(--space-12);
  align-items: start;
  position: relative;
}

.scrolly-text {
  /* 文字列正常流动 */
}

.scrolly-graphic {
  position: relative;
}

.scrolly-sticky {
  position: sticky;
  top: calc(50vh - 200px); /* 垂直居中 */
  height: 400px;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* 每个文字步骤 */
.scrolly-step {
  min-height: 70vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: var(--space-8) 0;
  opacity: 0.35;
  transition: opacity 0.4s ease;
}

.scrolly-step.is-active {
  opacity: 1;
}

/* 视觉面板（右侧图形） */
.visual-panel {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  transform: scale(0.95);
  transition: opacity 0.5s ease, transform 0.5s ease;
  pointer-events: none;
}

.visual-panel.is-active {
  opacity: 1;
  transform: scale(1);
  pointer-events: auto;
}

/* 移动端：改为垂直堆叠 */
@media (max-width: 768px) {
  .scrolly-section {
    grid-template-columns: 1fr;
  }
  .scrolly-graphic {
    display: none; /* 移动端隐藏右侧图形，或改为内嵌 */
  }
  .scrolly-step {
    min-height: auto;
    opacity: 1;
    padding: var(--space-6) 0;
  }
}
```

### JS

```javascript
(function initScrollytelling() {
  const steps = document.querySelectorAll('.scrolly-step');
  const visuals = document.querySelectorAll('.visual-panel');
  if (!steps.length) return;

  const stepObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach(entry => {
        if (!entry.isIntersecting) return;
        const stepIndex = entry.target.dataset.step;

        // 更新文字步骤高亮
        steps.forEach(s => s.classList.remove('is-active'));
        entry.target.classList.add('is-active');

        // 切换对应视觉面板
        visuals.forEach(v => {
          const isMatch = v.dataset.visual === stepIndex;
          v.classList.toggle('is-active', isMatch);
        });
      });
    },
    {
      threshold: 0.5,
      rootMargin: '-20% 0px -20% 0px' // 中间 60% 视口触发
    }
  );

  steps.forEach(step => stepObserver.observe(step));
})();
```

**使用示例：**
```html
<section class="scrolly-section">
  <!-- 左侧：文字步骤 -->
  <div class="scrolly-text">
    <div class="scrolly-step" data-step="0">
      <h3>第一步：分析现状</h3>
      <p>描述文字...</p>
    </div>
    <div class="scrolly-step" data-step="1">
      <h3>第二步：制定方案</h3>
      <p>描述文字...</p>
    </div>
    <div class="scrolly-step" data-step="2">
      <h3>第三步：执行落地</h3>
      <p>描述文字...</p>
    </div>
  </div>

  <!-- 右侧：粘性图形 -->
  <div class="scrolly-graphic">
    <div class="scrolly-sticky">
      <div class="visual-panel is-active" data-visual="0">
        <!-- 步骤 0 的图形/图表 -->
        <div style="...">图形内容</div>
      </div>
      <div class="visual-panel" data-visual="1">
        <!-- 步骤 1 的图形 -->
      </div>
      <div class="visual-panel" data-visual="2">
        <!-- 步骤 2 的图形 -->
      </div>
    </div>
  </div>
</section>
```

---

## 4. 深色/浅色模式切换

### CSS（切换按钮）

```css
.theme-toggle {
  position: fixed;
  top: var(--space-4);
  right: var(--space-4);
  z-index: 1000;
  width: 40px;
  height: 40px;
  border-radius: var(--radius-full);
  border: 1px solid var(--color-border);
  background: var(--color-surface);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.1rem;
  transition: background var(--transition-base),
              border-color var(--transition-base),
              transform var(--transition-spring);
  box-shadow: var(--shadow-md);
}

.theme-toggle:hover {
  transform: scale(1.1);
}

/* 图标切换 */
.theme-toggle .icon-light { display: block; }
.theme-toggle .icon-dark  { display: none; }
[data-theme="dark"] .theme-toggle .icon-light { display: none; }
[data-theme="dark"] .theme-toggle .icon-dark  { display: block; }
```

### JS

```javascript
(function initThemeToggle() {
  const toggle = document.getElementById('theme-toggle');
  if (!toggle) return;

  // 读取系统偏好
  const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
  const saved = localStorage.getItem('theme');
  const initial = saved || (prefersDark ? 'dark' : 'light');
  document.documentElement.dataset.theme = initial;

  toggle.addEventListener('click', () => {
    const isDark = document.documentElement.dataset.theme === 'dark';
    const next = isDark ? 'light' : 'dark';
    document.documentElement.dataset.theme = next;
    localStorage.setItem('theme', next);
  });
})();
```

### HTML

```html
<button id="theme-toggle" class="theme-toggle" aria-label="切换深色/浅色模式">
  <span class="icon-light">☀️</span>
  <span class="icon-dark">🌙</span>
</button>
```

---

## 5. 锚点导航（长文档目录）

### CSS

```css
.toc {
  position: fixed;
  left: var(--space-6);
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  flex-direction: column;
  gap: var(--space-2);
  z-index: 100;
}

.toc-dot {
  width: 8px;
  height: 8px;
  border-radius: var(--radius-full);
  background: var(--color-border-strong);
  cursor: pointer;
  transition: all var(--transition-base);
  position: relative;
}

.toc-dot::after {
  content: attr(data-label);
  position: absolute;
  left: 16px;
  top: 50%;
  transform: translateY(-50%);
  white-space: nowrap;
  font-size: var(--text-xs);
  color: var(--color-text-secondary);
  opacity: 0;
  transition: opacity var(--transition-base);
  pointer-events: none;
}

.toc-dot:hover::after,
.toc-dot.active::after {
  opacity: 1;
}

.toc-dot.active {
  background: var(--accent-mid);
  transform: scale(1.5);
}

/* 移动端隐藏 */
@media (max-width: 1200px) {
  .toc { display: none; }
}
```

### JS

```javascript
(function initTOC() {
  const dots = document.querySelectorAll('.toc-dot');
  const sections = document.querySelectorAll('section[id]');
  if (!dots.length || !sections.length) return;

  // 点击跳转
  dots.forEach(dot => {
    dot.addEventListener('click', () => {
      const target = document.getElementById(dot.dataset.target);
      if (target) target.scrollIntoView({ behavior: 'smooth' });
    });
  });

  // 滚动高亮
  const sectionObserver = new IntersectionObserver(
    (entries) => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          const id = entry.target.id;
          dots.forEach(dot => {
            dot.classList.toggle('active', dot.dataset.target === id);
          });
        }
      });
    },
    { threshold: 0.4 }
  );

  sections.forEach(s => sectionObserver.observe(s));
})();
```

### HTML

```html
<!-- 目录导航 -->
<nav class="toc" aria-label="页面目录">
  <div class="toc-dot active" data-target="overview" data-label="概览"></div>
  <div class="toc-dot" data-target="process" data-label="流程"></div>
  <div class="toc-dot" data-target="data" data-label="数据"></div>
  <div class="toc-dot" data-target="conclusion" data-label="结论"></div>
</nav>

<!-- 对应的 section -->
<section id="overview">...</section>
<section id="process">...</section>
```

---

## 6. 标签页（Tabs）

### CSS

```css
.tabs {
  border-bottom: 1px solid var(--color-border);
  display: flex;
  gap: 0;
  margin-bottom: var(--space-8);
}

.tab-btn {
  padding: var(--space-3) var(--space-6);
  border: none;
  background: none;
  cursor: pointer;
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--color-text-muted);
  border-bottom: 2px solid transparent;
  margin-bottom: -1px;
  transition: color var(--transition-base), border-color var(--transition-base);
  font-family: var(--font-sans);
}

.tab-btn:hover {
  color: var(--color-text-primary);
}

.tab-btn.active {
  color: var(--accent-mid);
  border-bottom-color: var(--accent-mid);
}

.tab-panel {
  display: none;
  animation: fadeIn 0.3s ease;
}

.tab-panel.active {
  display: block;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(8px); }
  to   { opacity: 1; transform: translateY(0); }
}
```

### JS

```javascript
(function initTabs() {
  document.querySelectorAll('.tabs').forEach(tabGroup => {
    const buttons = tabGroup.querySelectorAll('.tab-btn');
    const panels = tabGroup.closest('.tabs-container')
      ?.querySelectorAll('.tab-panel') || [];

    buttons.forEach((btn, i) => {
      btn.addEventListener('click', () => {
        buttons.forEach(b => b.classList.remove('active'));
        panels.forEach(p => p.classList.remove('active'));
        btn.classList.add('active');
        if (panels[i]) panels[i].classList.add('active');
      });
    });
  });
})();
```

### HTML

```html
<div class="tabs-container">
  <div class="tabs">
    <button class="tab-btn active">方案 A</button>
    <button class="tab-btn">方案 B</button>
    <button class="tab-btn">方案 C</button>
  </div>
  <div class="tab-panel active">方案 A 的内容...</div>
  <div class="tab-panel">方案 B 的内容...</div>
  <div class="tab-panel">方案 C 的内容...</div>
</div>
```

---

## 7. 手风琴（Accordion）

### CSS

```css
.accordion-item {
  border: 1px solid var(--color-border);
  border-radius: var(--radius-md);
  overflow: hidden;
  margin-bottom: var(--space-3);
}

.accordion-header {
  width: 100%;
  padding: var(--space-5) var(--space-6);
  background: var(--color-surface);
  border: none;
  cursor: pointer;
  display: flex;
  justify-content: space-between;
  align-items: center;
  font-size: var(--text-base);
  font-weight: 500;
  color: var(--color-text-primary);
  text-align: left;
  transition: background var(--transition-base);
  font-family: var(--font-sans);
}

.accordion-header:hover {
  background: var(--color-surface-2);
}

.accordion-icon {
  transition: transform var(--transition-base);
  flex-shrink: 0;
  margin-left: var(--space-4);
}

.accordion-item.open .accordion-icon {
  transform: rotate(180deg);
}

.accordion-body {
  max-height: 0;
  overflow: hidden;
  transition: max-height 0.35s ease, padding 0.35s ease;
  padding: 0 var(--space-6);
  background: var(--color-surface);
  color: var(--color-text-secondary);
  line-height: var(--leading-relaxed);
}

.accordion-item.open .accordion-body {
  max-height: 600px;
  padding: var(--space-5) var(--space-6);
}
```

### JS

```javascript
(function initAccordion() {
  document.querySelectorAll('.accordion-header').forEach(header => {
    header.addEventListener('click', () => {
      const item = header.closest('.accordion-item');
      const isOpen = item.classList.contains('open');
      // 可选：关闭其他项
      // item.closest('.accordion')?.querySelectorAll('.accordion-item')
      //   .forEach(i => i.classList.remove('open'));
      item.classList.toggle('open', !isOpen);
    });
  });
})();
```

### HTML

```html
<div class="accordion">
  <div class="accordion-item">
    <button class="accordion-header">
      问题一：这是什么？
      <span class="accordion-icon">▼</span>
    </button>
    <div class="accordion-body">
      详细解答内容...
    </div>
  </div>
  <div class="accordion-item">
    <button class="accordion-header">
      问题二：如何使用？
      <span class="accordion-icon">▼</span>
    </button>
    <div class="accordion-body">
      使用说明...
    </div>
  </div>
</div>
```
