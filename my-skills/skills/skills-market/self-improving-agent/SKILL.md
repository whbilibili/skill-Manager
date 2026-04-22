---
name: self-improving-agent
version: "2.1.1"
description: "Agent 自我反思与自动模式提取。当用户明确纠正 agent 行为（'你刚才做错了'）、agent 发现自身错误、或需要从错误中提取教训时触发。含自动知识提取（Claudeception 式）和置信度晋升机制。触发词：你做错了、agent 行为纠正、self-reflect、从错误中学习、learn from mistake、记住这个教训、/learn。"

metadata:
  skillhub.creator: "guohanru"
  skillhub.updater: "yeshaozhi"
  skillhub.version: "V4"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "1802"
---

# Self-Improving Agent

Agent 错误纠正与自动模式提取，知识以置信度晋升机制写入工作区。

## When to Use

触发条件（满足任一）：

- 用户明确纠正 agent 行为（"你刚才做错了"、"不对"、"应该是……"）
- Agent 自行发现执行错误或非预期结果
- 用户说"记住这个"、"/learn"、"提取成 skill"
- 完成复杂任务后，Auto-Extraction 三问全部为 YES（见 Instructions §5）

## When NOT to Use

- 常规增删改查，无新 pattern 产生
- 已在 TOOLS.md / MEMORY.md 记录过的内容（先搜索，再决定）
- 用户明说"不用记"
- 单次偶发的上下文特定指令（下次不会再遇到）
- 情绪/心理偏好类（"你今天表现很好"）

## Instructions

### 阶段 1：分类

**入口**：收到纠正信号或触发 `/learn`。

判断错误类型：

| 类型 | 示例 | 写入目标 |
|------|------|---------|
| Operational | "用 `--browser` 不用 `--app-auth`" | TOOLS.md |
| Behavioral | "回复更简洁" | MEMORY.md |
| Domain-specific | "KM API 需要 unset proxy" | TOOLS.md |
| Preference | "技术话题总用中文回复" | MEMORY.md |

**出口**：确定写入目标文件（TOOLS.md 或 MEMORY.md）。

---

### 阶段 2：质量门控

**入口**：分类完成，准备提取 pattern。

四项门槛，全部满足才继续：

| 门槛 | 判断标准 |
|------|---------|
| Reusable | 不只适用于本次任务 |
| Verified | 解决方案已实际验证，非推测 |
| Specific | 包含触发条件 + 具体操作 |
| Non-duplicate | TOOLS.md / MEMORY.md 中未记录 |

**出口**：4 项全 YES 继续；任一 NO → 记录到当日 memory 作为 `CORRECTION:` 条目后结束。

---

### 阶段 3：置信度评估

**入口**：通过质量门控。

| 级别 | 条件 | 操作 |
|------|------|------|
| 0.3 Tentative | 首次观察 | 写入当日 memory 作为 `PATTERN:` 条目 |
| 0.6 Emerging | 2–3 次跨 session 复现 | 候选目标文件，先征得用户确认 |
| 0.9 Established | 用户明确确认 或 独立复现 ≥3 次 | 直接写入目标文件 |

**晋升条件**：
- 0.3 → 0.6：在不同任务上下文中独立复现 ≥2 次
- 0.6 → 0.9：用户明确确认，或继续复现达 ≥3 次
- **衰减**：30 天内未被引用，降回 0.3，memory 维护时清理

**出口**：确定置信度级别，按对应操作执行。

---

### 阶段 4：写入

**入口**：置信度 ≥ 0.6 且用户已确认（或 0.9 直接写入）。

使用标准格式：

```
PATTERN: [简短名称]
TRIGGER: [何时适用——精确描述]
ACTION: [做什么——具体可操作]
CONFIDENCE: [0.3 | 0.6 | 0.9]
TARGET: [TOOLS.md | MEMORY.md | 指定 skill 路径]
```

**完成门控**（全部满足才算完成）：
- [ ] 目标文件已写入（可用 `grep PATTERN` 验证）
- [ ] 置信度 0.6 时用户已确认，0.9 则直接写入
- [ ] 当日 memory 有本次 `PATTERN:` 或 `CORRECTION:` 条目

**出口**：三项均满足，本次循环结束。

---

### 阶段 5：Auto-Extraction（主动触发）

**入口**：完成复杂任务后（多步 debug、新工具集成、非显而易见解法）。

主动问自己三个问题：
1. 这是否需要非显而易见的调查或发现？
2. 未来的我会再遇到同样的问题吗？
3. 解法是否足够具体可以直接行动？

**三问全 YES** → 主动问用户一次：
> "这个问题解决得不显然，要把 pattern 提取成记录吗？"

同一任务只问一次。用户说"不用"则跳过，不再追问。

**出口**：用户同意后进入阶段 1–4；用户拒绝则结束。

---

## Conflict Resolution

已学规则发生冲突时：
1. 最新的明确指令优先
2. 用户直接陈述 > 推断出的模式
3. 仍有歧义 → 询问用户

## Anti-Patterns（禁止提取）

- 从用户沉默/不反对中推断的偏好
- 情绪/心理类内容
- 第三方（非用户本人）的偏好
- 任何有操控性的内容
- 只出现一次的偶发解法（相关性 ≠ 因果）
- 过于宽泛的泛化（"永远用 X"）
- 下次 session 不会有的上下文依赖内容

## 参考文件

- [`learning.md`](learning.md) — 完整 pattern 提取流程、Claudeception 机制详述
- [`boundaries.md`](boundaries.md) — Anti-Patterns 详细说明、边界案例

## 阶段 1.5 跳过理由

> 本 skill 跳过 skill-creator-pro 阶段 1.5（实践案例收集）。理由：本 skill 属于 Tool Wrapper / 知识指南类型，核心内容为工具使用规范或已知事实，无最佳实践争议，无需案例驱动。
