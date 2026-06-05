# Color Palettes — 按场景分类的配色方案

根据文档的语气和受众选择一套配色，替换 `:root` 中的 `--accent-*` 变量。

---

## 🔵 技术/研究 — 蓝紫专业

适用：技术文档、研究报告、白皮书、API 文档

```css
/* 主色 */
--accent-start: #667eea;
--accent-end:   #764ba2;
--accent-mid:   #7c6ef0;
--accent-rgb:   102, 126, 234;

/* 配套背景（浅色模式） */
--color-bg:        #f8f9ff;
--color-surface:   #ffffff;
--color-surface-2: #f0f2ff;
```

---

## 🟢 产品/商务 — 青绿现代

适用：产品介绍、方案提案、商业计划书、功能说明

```css
--accent-start: #11998e;
--accent-end:   #38ef7d;
--accent-mid:   #22c55e;
--accent-rgb:   17, 153, 142;

--color-bg:        #f0fdf4;
--color-surface:   #ffffff;
--color-surface-2: #dcfce7;
```

---

## 🟠 数据/增长 — 橙红活力

适用：数据报告、增长分析、运营复盘、KPI 展示

```css
--accent-start: #f093fb;
--accent-end:   #f5576c;
--accent-mid:   #f43f5e;
--accent-rgb:   240, 147, 251;

--color-bg:        #fff1f2;
--color-surface:   #ffffff;
--color-surface-2: #ffe4e6;
```

---

## 🌊 教程/指南 — 海蓝清晰

适用：操作教程、使用指南、入门文档、FAQ

```css
--accent-start: #4facfe;
--accent-end:   #00f2fe;
--accent-mid:   #0ea5e9;
--accent-rgb:   79, 172, 254;

--color-bg:        #f0f9ff;
--color-surface:   #ffffff;
--color-surface-2: #e0f2fe;
```

---

## 🌅 叙事/故事 — 暖橙沉浸

适用：案例故事、品牌叙事、项目复盘、人物介绍

```css
--accent-start: #f6d365;
--accent-end:   #fda085;
--accent-mid:   #fb923c;
--accent-rgb:   246, 211, 101;

--color-bg:        #fffbf5;
--color-surface:   #ffffff;
--color-surface-2: #fff7ed;
```

---

## 🌙 深色仪表盘 — 暗夜数据

适用：数据仪表盘、监控报告、技术指标展示（默认深色模式）

```css
/* 默认就是深色，不需要 data-theme 切换 */
--accent-start: #818cf8;
--accent-end:   #c084fc;
--accent-mid:   #a78bfa;
--accent-rgb:   129, 140, 248;

/* 覆盖基础令牌 */
--color-text-primary:   #f1f5f9;
--color-text-secondary: #94a3b8;
--color-text-muted:     #64748b;
--color-bg:        #0f172a;
--color-surface:   #1e293b;
--color-surface-2: #334155;
--color-border:    rgba(255, 255, 255, 0.08);
```

---

## 🎨 自定义配色规则

如果以上方案都不合适，自定义时遵守：

1. **主色调最多 2 个**（渐变起止色），不要超过 3 个强调色
2. **对比度**：文字与背景对比度 ≥ 4.5:1（WCAG AA 标准）
3. **语义一致**：绿色=正面/成功，红色=负面/警告，蓝色=信息/中性
4. **渐变方向**：Hero 区块用 135deg，进度条/装饰线用 90deg
5. **透明度叠加**：用 `rgba(var(--accent-rgb), 0.1)` 做浅色背景，保持色调统一

---

## 渐变文字效果

```css
/* 标题渐变文字 */
.hero-title {
  background: linear-gradient(135deg, var(--accent-start), var(--accent-end));
  -webkit-background-clip: text;
  -webkit-text-fill-color: transparent;
  background-clip: text;
}

/* 深色模式下渐变文字更亮 */
[data-theme="dark"] .hero-title {
  /* 渐变色自动适配，无需修改 */
  filter: brightness(1.2);
}
```
