# Comment Templates — AI-CR

## 行内评论模板（P0/P1，Step 7A）

> ⚠️ **强制要求**：末尾必须加采纳反馈引导。

```
🔴 P0 / 🟠 P1：{问题标题}

{问题描述}

风险：{后果描述}

修复建议：
{代码示例（如有）}

---
💬 请回复告诉我你的判断：✅已采纳 / ⚠️规则太严 / ⏭暂不修复 / ❌误报
```

---

## 全局评论模板（P2/P3 + 摘要，Step 7B）

> ⚠️ **强制要求**：每条 P2/P3 问题末尾都必须加采纳反馈引导，格式与 P0/P1 行内评论统一。

```markdown
## 🤖 AI Code Review 结果

> 本 Review 由 AI-CR（AI 代码审查）自动生成，仅供参考，请结合业务实际情况判断。
> P0/P1 问题已作为行内评论标注在对应代码行。

**发现汇总：** P0: {x} | P1: {x} | P2: {x} | P3: {x}

**Review 结论：** {conclusion}

---

### P2 — 代码规范 🟡

**🟡 P2-01: {问题标题}**
文件: `{file}:{line}`
{问题描述}
💬 请回复告诉我你的判断：✅已采纳 / ⚠️规则太严 / ⏭暂不修复 / ❌误报

**🟡 P2-02: {问题标题}**
文件: `{file}:{line}`
{问题描述}
💬 请回复告诉我你的判断：✅已采纳 / ⚠️规则太严 / ⏭暂不修复 / ❌误报

### P3 — 优化建议 🔵

**🔵 P3-01: {问题标题}**
文件: `{file}:{line}`
{问题描述}
💬 请回复告诉我你的判断：✅已采纳 / ⚠️规则太严 / ⏭暂不修复 / ❌误报

---

📄 详细 Review 文档：{kmUrl（如有）}
```

---

## 大象群聊推送模板（Step 8）

```
【AI-CR】{conclusion} | {org}/{repo} PR #{id}

功能：{title}
提交人：{authorName}（{submitter_mis}）
触发人：{triggerName}（{triggerMis}）
涉及文件：{fileCount} 个（+{additions} / -{deletions}）

发现：P0: {p0} | P1: {p1} | P2: {p2} | P3: {p3}

{top_issues_text}
📄 详细文档：{kmUrl}
🔗 PR 链接：{prUrl}
```

> 说明：
> - `{triggerName}（{triggerMis}）`：触发本次 CR 的人（通常是 code reviewer / 木子），格式与提交人一致：姓名（mis）。triggerMis 从当前 session 的操作者 mis 获取，triggerName 通过 `code_cli.py user-info {triggerMis}` 或同名映射获取
> - `{top_issues_text}`：若有 P0/P1，逐条列出（每条一行，格式 `• P1-01 问题标题`）；全通过则写 `✨ 未发现 P0/P1 问题`
> - 多仓库联合 CR：每个 PR 各列一行链接，结论取最高级别（有 P0 就是 P0）
> - 消息纯文本，不 @ 任何人（群广播模式）

---

## 学城 CR 文档结构模板（Step 3）

```markdown
# PR #{id} Code Review：{标题}

## 一、PR 概述
仓库、编号、标题、提交人、分支、文件数、行数变化

## 二、变更文件清单
| 文件名 | 变更类型 | +行数 | -行数 |

## 三、Review 发现
### P0 — 零容忍异常 🔴
[P0-1] {异常类型} — {概括}
文件：{路径} L{行号}（diff中的 dstN，即新文件行号；若为新增行则 srcN 为空）
问题：{描述}
风险：{后果}
修复建议：{代码}

### P1 — 稳定性风险 🟠
...
### P2 — 代码规范 🟡
...
### P3 — 优化建议 🔵
...

> ⚠️ 学城文档中不要包含「反馈：✅ 已采纳 | ⚠️ 规则太严 | ⏭ 暂不修复 | ❌ 误报」这行，反馈引导只写在 PR 行内评论中。

## 四、总体评价
优点 + 需关注问题 + Review 结论（四选一：✅通过 / 💚通过有建议 / 🟠需修复 / 🔴需重新设计）
发现汇总：P0: X | P1: X | P2: X | P3: X

## 五、与 CatPaw 对比

> 如果 PR 评论区已有 CatPaw 结果，提取其发现并做差异对比。

| 维度 | CatPaw | AI-CR | 差异说明 |
|------|--------|-------|---------|
| P0 | {catpaw_p0} | {ai_cr_p0} | {diff} |
| P1 | {catpaw_p1} | {ai_cr_p1} | {diff} |
| P2 | {catpaw_p2} | {ai_cr_p2} | {diff} |
| P3 | {catpaw_p3} | {ai_cr_p3} | {diff} |
| 结论 | {catpaw_conclusion} | {ai_cr_conclusion} | |

**AI-CR 独有发现：**
- {列出 AI-CR 发现但 CatPaw 未发现的问题}

**CatPaw 独有发现：**
- {列出 CatPaw 发现但 AI-CR 未发现的问题}
```

---

## 采纳率章节模板（Step 7，第二轮 CR 追加）

```markdown
## 六、上轮 CR 采纳情况

| 指标 | 值 |
|------|-----|
| 总发现数 | {total} |
| ✅ 已采纳 | {adopted} ({adopted_rate}%) |
| ⚠️ 规则太严 | {too_strict} ({strict_rate}%) |
| ⏭ 暂不修复 | {deferred} ({defer_rate}%) |
| ❌ 误报 | {false_positive} ({fp_rate}%) |
| 未反馈 | {no_feedback} |

**按层级：**
| 层级 | 采纳 | 规则太严 | 暂不修复 | 误报 |
|------|------|---------|---------|------|
| P0 | {x} | {x} | {x} | {x} |
| P1 | {x} | {x} | {x} | {x} |
| P2 | {x} | {x} | {x} | {x} |
| P3 | {x} | {x} | {x} | {x} |
```
