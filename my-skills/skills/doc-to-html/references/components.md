# Components — 完整组件代码库

每个组件包含完整的 HTML + CSS。JS 动画部分见 `animations.md`。

---

## 1. Hero 区块

适用：所有文档的开头，展示标题、副标题、核心摘要。

```html
<section class="hero" id="hero">
  <div class="container">
    <div class="hero-badge animate-on-scroll fade-up">文档类型标签</div>
    <h1 class="hero-title animate-on-scroll fade-up">
      文档主标题
    </h1>
    <p class="hero-subtitle animate-on-scroll fade-up">
      一句话概括文档核心内容，不超过两行。
    </p>
    <div class="hero-meta animate-on-scroll fade-up">
      <span>作者 · 日期 · 阅读时间</span>
    </div>
  </div>
</section>
```

```css
.hero {
  padding: var(--space-24) 0 var(--space-16);
  text-align: center;
  position: relative;
  overflow: hidden;
}

/* 背景装饰（可选） */
.hero::before {
  content: '';
  position: absolute;
  top: -50%;
  left: 50%;
  transform: translateX(-50%);
  width: 800px;
  height: 800px;
  background: radial-gradient(
    circle,
    rgba(var(--accent-rgb), 0.08) 0%,
    transparent 70%
  );
  pointer-events: none;
}

.hero-badge {
  display: inline-block;
  padding: var(--space-1) var(--space-4);
  background: rgba(var(--accent-rgb), 0.1);
  color: var(--accent-mid);
  border-radius: var(--radius-full);
  font-size: var(--text-sm);
  font-weight: 600;
  letter-spacing: 0.05em;
  text-transform: uppercase;
  margin-bottom: var(--space-6);
}

.hero-title {
  font-size: clamp(var(--text-3xl), 5vw, var(--text-6xl));
  font-weight: 800;
  line-height: var(--leading-tight);
  letter-spacing: -0.02em;
  margin-bottom: var(--space-6);
  /* 渐变文字（可选） */
  background: linear-gradient(135deg, var(--color-text-primary) 0%, var(--accent-mid) 100%);
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

.hero-subtitle {
  font-size: var(--text-xl);
  color: var(--color-text-secondary);
  max-width: 600px;
  margin: 0 auto var(--space-8);
  line-height: var(--leading-relaxed);
}

.hero-meta {
  font-size: var(--text-sm);
  color: var(--color-text-muted);
}
```

---

## 2. Stat Cards（数据展示）

适用：数据型内容，展示核心指标。

```html
<div class="stats-grid stagger">
  <div class="stat-card animate-on-scroll scale-in">
    <div class="stat-value">
      <span class="counter" data-target="400">0</span>
      <span class="stat-unit">%</span>
    </div>
    <div class="stat-label">停留时间提升</div>
    <div class="stat-desc">相比纯文字内容</div>
  </div>
  <!-- 重复更多卡片 -->
</div>
```

```css
.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: var(--space-5);
}

.stat-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: var(--space-8) var(--space-6);
  text-align: center;
  border: 1px solid var(--color-border);
  box-shadow: var(--shadow-sm);
  transition: transform var(--transition-base), box-shadow var(--transition-base);
  position: relative;
  overflow: hidden;
}

.stat-card::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0;
  height: 3px;
  background: linear-gradient(90deg, var(--accent-start), var(--accent-end));
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
}

.stat-value {
  font-size: var(--text-5xl);
  font-weight: 800;
  line-height: 1;
  background: linear-gradient(135deg, var(--accent-start), var(--accent-end));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
  margin-bottom: var(--space-3);
  font-variant-numeric: tabular-nums;
}

.stat-unit {
  font-size: var(--text-3xl);
}

.stat-label {
  font-weight: 600;
  color: var(--color-text-primary);
  font-size: var(--text-base);
  margin-bottom: var(--space-1);
}

.stat-desc {
  font-size: var(--text-sm);
  color: var(--color-text-muted);
}
```

---

## 3. Step Cards（流程步骤）

适用：流程型内容，展示操作步骤或阶段。

```html
<div class="steps-grid stagger">
  <div class="step-card animate-on-scroll fade-up">
    <div class="step-number">01</div>
    <div class="step-icon">🔍</div>
    <h3 class="step-title">分析现状</h3>
    <p class="step-desc">详细描述这个步骤的内容和目标。</p>
  </div>
  <div class="step-card animate-on-scroll fade-up">
    <div class="step-number">02</div>
    <div class="step-icon">📋</div>
    <h3 class="step-title">制定方案</h3>
    <p class="step-desc">详细描述这个步骤的内容和目标。</p>
  </div>
  <!-- 更多步骤 -->
</div>
```

```css
.steps-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(240px, 1fr));
  gap: var(--space-5);
}

.step-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: var(--space-8);
  border: 1px solid var(--color-border);
  box-shadow: var(--shadow-sm);
  position: relative;
  overflow: hidden;
  transition: transform var(--transition-base), box-shadow var(--transition-base);
}

.step-card::before {
  content: '';
  position: absolute;
  top: 0; left: 0; right: 0;
  height: 4px;
  background: linear-gradient(90deg, var(--accent-start), var(--accent-end));
}

.step-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
}

.step-number {
  font-size: 4rem;
  font-weight: 900;
  line-height: 1;
  color: var(--accent-mid);
  opacity: 0.12;
  position: absolute;
  top: var(--space-4);
  right: var(--space-5);
  font-variant-numeric: tabular-nums;
  letter-spacing: -0.04em;
}

.step-icon {
  font-size: 2rem;
  margin-bottom: var(--space-4);
  display: block;
}

.step-title {
  font-size: var(--text-lg);
  font-weight: 700;
  color: var(--color-text-primary);
  margin-bottom: var(--space-3);
}

.step-desc {
  font-size: var(--text-sm);
  color: var(--color-text-secondary);
  line-height: var(--leading-relaxed);
}

/* 步骤连接线（可选，用于水平布局） */
.steps-grid.with-connector .step-card:not(:last-child)::after {
  content: '→';
  position: absolute;
  right: calc(-1 * var(--space-5) - 0.5rem);
  top: 50%;
  transform: translateY(-50%);
  color: var(--color-text-muted);
  font-size: var(--text-xl);
  z-index: 1;
}
```

---

## 4. Timeline（时间轴）

适用：时间线型内容，展示历史事件或里程碑。

```html
<div class="timeline">
  <div class="timeline-item animate-on-scroll fade-left">
    <div class="timeline-marker">
      <div class="timeline-dot"></div>
    </div>
    <div class="timeline-content">
      <span class="timeline-date">2024 Q1</span>
      <h3 class="timeline-title">里程碑标题</h3>
      <p class="timeline-desc">事件描述，可以包含多行文字。</p>
    </div>
  </div>
  <!-- 更多时间节点 -->
</div>
```

```css
.timeline {
  position: relative;
  padding-left: var(--space-10);
}

/* 垂直线 */
.timeline::before {
  content: '';
  position: absolute;
  left: calc(var(--space-4) - 1px);
  top: var(--space-2);
  bottom: var(--space-2);
  width: 2px;
  background: linear-gradient(
    to bottom,
    var(--accent-mid) 0%,
    rgba(var(--accent-rgb), 0.15) 100%
  );
}

.timeline-item {
  position: relative;
  margin-bottom: var(--space-10);
}

.timeline-item:last-child {
  margin-bottom: 0;
}

.timeline-marker {
  position: absolute;
  left: calc(-1 * var(--space-10) + var(--space-4) - 6px);
  top: var(--space-1);
}

.timeline-dot {
  width: 14px;
  height: 14px;
  border-radius: var(--radius-full);
  background: var(--accent-mid);
  border: 3px solid var(--color-bg);
  box-shadow: 0 0 0 3px rgba(var(--accent-rgb), 0.2);
  transition: transform var(--transition-base), box-shadow var(--transition-base);
}

.timeline-item:hover .timeline-dot {
  transform: scale(1.3);
  box-shadow: 0 0 0 5px rgba(var(--accent-rgb), 0.15);
}

.timeline-content {
  background: var(--color-surface);
  border-radius: var(--radius-md);
  padding: var(--space-6);
  border: 1px solid var(--color-border);
  box-shadow: var(--shadow-sm);
  transition: box-shadow var(--transition-base);
}

.timeline-item:hover .timeline-content {
  box-shadow: var(--shadow-md);
}

.timeline-date {
  display: inline-block;
  font-size: var(--text-xs);
  font-weight: 700;
  color: var(--accent-mid);
  text-transform: uppercase;
  letter-spacing: 0.08em;
  margin-bottom: var(--space-2);
  background: rgba(var(--accent-rgb), 0.1);
  padding: 2px var(--space-2);
  border-radius: var(--radius-sm);
}

.timeline-title {
  font-size: var(--text-lg);
  font-weight: 700;
  color: var(--color-text-primary);
  margin-bottom: var(--space-2);
}

.timeline-desc {
  font-size: var(--text-sm);
  color: var(--color-text-secondary);
  line-height: var(--leading-relaxed);
}
```

---

## 5. Comparison Table（对比表格）

适用：对比型内容，多维度比较多个方案。

```html
<div class="table-wrapper animate-on-scroll fade-up">
  <table class="comparison-table">
    <thead>
      <tr>
        <th>对比维度</th>
        <th>方案 A</th>
        <th class="highlight-col">方案 B（推荐）</th>
        <th>方案 C</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td class="dimension">成本</td>
        <td>高</td>
        <td class="highlight-col">中</td>
        <td>低</td>
      </tr>
      <tr>
        <td class="dimension">效果</td>
        <td>一般</td>
        <td class="highlight-col">优秀 ✓</td>
        <td>较差</td>
      </tr>
    </tbody>
  </table>
</div>
```

```css
.table-wrapper {
  overflow-x: auto;
  border-radius: var(--radius-lg);
  box-shadow: var(--shadow-md);
}

.comparison-table {
  width: 100%;
  border-collapse: collapse;
  background: var(--color-surface);
  font-size: var(--text-sm);
}

.comparison-table th {
  padding: var(--space-4) var(--space-6);
  background: var(--color-surface-2);
  font-weight: 600;
  text-align: left;
  color: var(--color-text-secondary);
  font-size: var(--text-xs);
  letter-spacing: 0.05em;
  text-transform: uppercase;
  border-bottom: 1px solid var(--color-border);
}

.comparison-table th.highlight-col {
  background: linear-gradient(135deg, var(--accent-start), var(--accent-end));
  color: white;
}

.comparison-table td {
  padding: var(--space-4) var(--space-6);
  border-bottom: 1px solid var(--color-border);
  color: var(--color-text-primary);
  vertical-align: middle;
}

.comparison-table td.dimension {
  font-weight: 600;
  color: var(--color-text-secondary);
  background: var(--color-surface-2);
}

.comparison-table td.highlight-col {
  background: rgba(var(--accent-rgb), 0.05);
  font-weight: 500;
  color: var(--accent-mid);
}

.comparison-table tr:last-child td {
  border-bottom: none;
}

.comparison-table tr:hover td:not(.dimension) {
  background: var(--color-surface-2);
}

.comparison-table tr:hover td.highlight-col {
  background: rgba(var(--accent-rgb), 0.1);
}
```

---

## 6. Feature Cards Grid（概念/功能展示）

适用：概念型内容，展示多个并列的特性或概念。

```html
<div class="features-grid stagger">
  <div class="feature-card animate-on-scroll fade-up">
    <div class="feature-icon-wrap">
      <span class="feature-icon">⚡</span>
    </div>
    <h3 class="feature-title">特性名称</h3>
    <p class="feature-desc">特性的详细描述，说明它的价值和作用。</p>
  </div>
  <!-- 更多卡片 -->
</div>
```

```css
.features-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
  gap: var(--space-5);
}

.feature-card {
  background: var(--color-surface);
  border-radius: var(--radius-lg);
  padding: var(--space-8);
  border: 1px solid var(--color-border);
  box-shadow: var(--shadow-sm);
  transition: transform var(--transition-base),
              box-shadow var(--transition-base),
              border-color var(--transition-base);
}

.feature-card:hover {
  transform: translateY(-4px);
  box-shadow: var(--shadow-lg);
  border-color: rgba(var(--accent-rgb), 0.3);
}

.feature-icon-wrap {
  width: 52px;
  height: 52px;
  border-radius: var(--radius-md);
  background: rgba(var(--accent-rgb), 0.1);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: var(--space-5);
  transition: background var(--transition-base);
}

.feature-card:hover .feature-icon-wrap {
  background: rgba(var(--accent-rgb), 0.18);
}

.feature-icon {
  font-size: 1.5rem;
}

.feature-title {
  font-size: var(--text-lg);
  font-weight: 700;
  color: var(--color-text-primary);
  margin-bottom: var(--space-3);
}

.feature-desc {
  font-size: var(--text-sm);
  color: var(--color-text-secondary);
  line-height: var(--leading-relaxed);
}
```

---

## 7. Callout Box（重点提示）

适用：突出显示关键结论、警告、提示。

```html
<!-- 信息型 -->
<div class="callout callout-info animate-on-scroll fade-up">
  <div class="callout-icon">💡</div>
  <div class="callout-content">
    <strong>关键洞察</strong>
    <p>这里是需要特别强调的内容。</p>
  </div>
</div>

<!-- 成功型 -->
<div class="callout callout-success animate-on-scroll fade-up">
  <div class="callout-icon">✅</div>
  <div class="callout-content">
    <strong>核心结论</strong>
    <p>这里是正面的结论或成果。</p>
  </div>
</div>

<!-- 警告型 -->
<div class="callout callout-warning animate-on-scroll fade-up">
  <div class="callout-icon">⚠️</div>
  <div class="callout-content">
    <strong>注意事项</strong>
    <p>这里是需要注意的风险或限制。</p>
  </div>
</div>
```

```css
.callout {
  display: flex;
  gap: var(--space-4);
  padding: var(--space-5) var(--space-6);
  border-radius: var(--radius-md);
  border-left: 4px solid;
  margin: var(--space-6) 0;
}

.callout-info {
  background: rgba(var(--accent-rgb), 0.06);
  border-left-color: var(--accent-mid);
}

.callout-success {
  background: rgba(34, 197, 94, 0.06);
  border-left-color: #22c55e;
}

.callout-warning {
  background: rgba(245, 158, 11, 0.06);
  border-left-color: #f59e0b;
}

.callout-icon {
  font-size: 1.25rem;
  flex-shrink: 0;
  margin-top: 2px;
}

.callout-content strong {
  display: block;
  font-weight: 700;
  color: var(--color-text-primary);
  margin-bottom: var(--space-1);
}

.callout-content p {
  font-size: var(--text-sm);
  color: var(--color-text-secondary);
  line-height: var(--leading-relaxed);
  margin: 0;
}
```

---

## 8. Section Header（区块标题）

适用：每个内容区块的标题，保持视觉一致性。

```html
<div class="section-header animate-on-scroll fade-up">
  <span class="section-label">第二部分</span>
  <h2 class="section-title">区块主标题</h2>
  <p class="section-subtitle">区块的简短描述，说明这部分内容的核心。</p>
</div>
```

```css
.section-header {
  text-align: center;
  margin-bottom: var(--space-12);
}

.section-label {
  display: inline-block;
  font-size: var(--text-xs);
  font-weight: 700;
  color: var(--accent-mid);
  text-transform: uppercase;
  letter-spacing: 0.1em;
  margin-bottom: var(--space-3);
  background: rgba(var(--accent-rgb), 0.1);
  padding: var(--space-1) var(--space-3);
  border-radius: var(--radius-full);
}

.section-title {
  font-size: clamp(var(--text-2xl), 3vw, var(--text-4xl));
  font-weight: 800;
  color: var(--color-text-primary);
  letter-spacing: -0.02em;
  line-height: var(--leading-tight);
  margin-bottom: var(--space-4);
}

.section-subtitle {
  font-size: var(--text-lg);
  color: var(--color-text-secondary);
  max-width: 560px;
  margin: 0 auto;
  line-height: var(--leading-relaxed);
}
```

---

## 9. Quote / Highlight（引用/金句）

适用：突出显示重要引用、金句、核心观点。

```html
<blockquote class="highlight-quote animate-on-scroll scale-in">
  <p>"这里是需要突出显示的核心观点或引用内容，通常是文档中最重要的一句话。"</p>
  <cite>— 来源或作者</cite>
</blockquote>
```

```css
.highlight-quote {
  position: relative;
  padding: var(--space-8) var(--space-10);
  margin: var(--space-10) 0;
  background: linear-gradient(
    135deg,
    rgba(var(--accent-rgb), 0.06) 0%,
    rgba(var(--accent-rgb), 0.02) 100%
  );
  border-radius: var(--radius-lg);
  border: 1px solid rgba(var(--accent-rgb), 0.15);
}

.highlight-quote::before {
  content: '"';
  position: absolute;
  top: -0.2em;
  left: var(--space-6);
  font-size: 6rem;
  line-height: 1;
  color: var(--accent-mid);
  opacity: 0.2;
  font-family: Georgia, serif;
}

.highlight-quote p {
  font-size: var(--text-xl);
  font-weight: 500;
  color: var(--color-text-primary);
  line-height: var(--leading-relaxed);
  font-style: italic;
  margin-bottom: var(--space-4);
}

.highlight-quote cite {
  font-size: var(--text-sm);
  color: var(--color-text-muted);
  font-style: normal;
  font-weight: 600;
}
```

---

## 10. 页脚（Footer）

```html
<footer class="footer">
  <div class="container">
    <p class="footer-text">文档标题 · 生成于 [日期]</p>
  </div>
</footer>
```

```css
.footer {
  padding: var(--space-10) 0;
  border-top: 1px solid var(--color-border);
  margin-top: var(--space-24);
}

.footer-text {
  text-align: center;
  font-size: var(--text-sm);
  color: var(--color-text-muted);
}
```
