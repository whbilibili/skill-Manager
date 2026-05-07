---
name: self-improving-agent
description: "自我改进 Agent：从用户纠正、错误发现、复杂任务后 Auto-Extraction 中提取行为模式，写入持久文件。质量门控：Reusable/Verified/Specific/Non-duplicate 四原则。触发词：self improve、行为模式、提取教训、Auto-Extraction、记住这个模式、经验提取。NOT: 记录情绪/心理偏好、记录仅出现一次的偶发解法。"

allowed-tools: [read, write, exec]

metadata:
  skillhub.creator: "guohanru"
  skillhub.updater: "yeshaozhi"
  skillhub.version: "V7"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "1802"
---
# Self-Improving Agent
**IRON LAW: 未经质量门控四原则(Reusable/Verified/Specific/Non-duplicate)全部通过，不得写入持久文件。**
# When to Use
- 用户纠正 agent（"你做错了"、"应该是……"）
- Agent 自行发现错误
- 用户说"记住这个"、"/learn"
- 复杂任务后 Auto-Extraction 三问全 YES（见§5）
# When NOT to Use
- 常规 CRUD / 已记录过 / 用户说"不用记" / 单次偶发指令 / 情绪偏好
# Instructions
## §1 分类
| 类型 | 示例 | 写入 |
|------|------|------|
| Operational | "用 `--browser` 不用 `--app-auth`" | TOOLS.md |
| Behavioral | "回复更简洁" | MEMORY.md |
| Domain-specific | "KM API 需要 unset proxy" | TOOLS.md |
| Preference | "技术话题总用中文回复" | MEMORY.md |
## §2 质量门控
全部满足才继续：Reusable / Verified / Specific / Non-duplicate
任一 NO → 当日 memory `CORRECTION:` 条目后结束。
## §3 置信度评估
| 级别 | 条件 | 操作 |
|------|------|------|
| 0.3 Tentative | 首次观察 | 当日 memory `PATTERN:` |
| 0.6 Emerging | 2-3 次跨 session 复现 | 候选写入，先征用户确认 |
| 0.9 Established | 用户确认 或 ≥3 次复现 | 直接写入目标文件 |
晋升：0.3→0.6 不同上下文复现≥2 / 0.6→0.9 用户确认或≥3次
衰减：30天未引用降回 0.3
## §4 写入
格式：
```
PATTERN: [名称]
TRIGGER: [何时适用]
ACTION: [做什么]
CONFIDENCE: [0.3|0.6|0.9]
TARGET: [TOOLS.md|MEMORY.md|skill路径]
```
完成门控：目标文件已写入 / 0.6时用户已确认 / 当日memory有条目
## §5 Auto-Extraction
复杂任务后自问：1)非显而易见？2)会再遇到？3)足够具体可行动？
三问全YES → 问用户一次。同一任务只问一次。
# Conflict Resolution
1. 最新明确指令优先
2. 用户直接陈述 > 推断模式
3. 仍有歧义 → 询问
## Anti-Patterns
- 从沉默推断偏好 → 必须有明确的用户反馈
- 情绪/心理/第三方偏好 → 只记录行为模式
- 只出现一次的偶发解法 → 需要 ≥2 次跨场景复现才记录
- 过于宽泛的泛化 → 必须有具体的触发条件
- 上下文依赖内容 → 去掉上下文依赖，只保留通用规则
# 参考
- [`learning.md`](learning.md) — pattern 提取流程
- [`boundaries.md`](boundaries.md) — 边界案例
