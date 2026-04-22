# 跨会话断点续传协议

本文档定义测试执行跨会话断点续传的完整协议，确保任何会话都能从上次断点无缝继续。

---

## 核心原则

**进度在文件里，不在上下文里。** 这是整个 harness 体系的核心设计理念。
测试执行的所有状态都持久化在 test-plan.json 和 test-progress.txt 中，
Agent 不应依赖对话上下文记忆测试进度。

---

## 断点保存时机

### 强制保存

以下场景必须立即保存断点：

1. **每个 suite 执行完毕后**：无论结果如何，立即更新 test-plan.json 中该 suite 的状态
2. **用户说"结束/暂停/保存"**：立即保存当前进度到两个文件
3. **发现阻塞问题时**：标记 blocked 并保存，记录阻塞原因到 test-progress.txt
4. **创建缺陷工单后**：回写 issue id 到 test-plan.json

### 建议保存

以下场景建议保存（可合并）：

1. 每执行完 3 个 suite 后做一次完整保存
2. 单个 suite 内执行超过 10 个 case 时，中间做一次保存

---

## 断点恢复流程

新会话开始时按以下顺序恢复状态：

### Step 1 — 读取 test-progress.txt

快速获取概览：当前断点位置、已知阻塞、下一步计划。
这是给 Agent 的"快速回忆"，不需要完整解析。

### Step 2 — 读取 test-plan.json

获取精确状态：每个 suite 和 case 的 status/result。
按以下优先级确定下一个要执行的 suite：

```
优先级排序:
1. status == "failing" 且有 pending cases（上次中断的 suite，优先完成）
2. status == "planned" or "generated"，按 priority P0 > P1 > P2 > P3
3. status == "blocked" 且阻塞原因已解决（重试）
```

### Step 3 — 校验一致性

```python
import json
tp = json.load(open("docs/exec-plans/test-plan.json"))

# 校验 execution_summary 与实际数据一致
actual_passed = sum(1 for s in tp["test_suites"]
                    for c in s["test_cases"] if c["result"] == "pass")
actual_failed = sum(1 for s in tp["test_suites"]
                    for c in s["test_cases"] if c["result"] in ("fail", "error"))

summary = tp["execution_summary"]
if summary["passed"] != actual_passed or summary["failed"] != actual_failed:
    print("WARNING execution_summary 不一致，正在修正...")
    # 重新计算并更新 summary
```

### Step 4 — 向用户报告恢复状态

输出格式（自然语言段落）：

> 已从断点恢复测试进度。上次会话执行到 TEST-{xxx}，
> 当前总体进度：{passed}/{total} suites 通过，{failed} 个失败，{remaining} 个待执行。
> {如有 blocked} 有 {blocked_count} 个被阻塞的套件，阻塞原因：{reasons}。
> 接下来将从 TEST-{next} 继续执行。

---

## test-progress.txt 更新协议

### 完整替换而非追加

每次更新都完整替换四个区块的全部内容，不在末尾追加。
这与 progress.txt 的管理方式一致，防止文件无限增长。

### 四个区块的内容规范

**[Test Execution Focus]**：
- 当前正在执行的 suite id 和标题
- 如果在 suite 内部中断，记录到具体的 case id
- 总体进度数字（passed / failed / blocked / remaining）

**[Test Findings]**：
- 保留最近 5 条关键发现
- 格式：`[日期] suite_id 发现 severity 缺陷: 简要描述 → issue_id`
- 超过 5 条时，旧条目在下次生成测试报告时自动归档

**[Blockers]**：
- 阻塞测试继续的外部因素
- 每条 blocker 附带"解决方案"或"需要谁来解决"

**[Next Test Steps]**：
- 下一个会话应该做什么（指令级清晰）
- 如果所有测试完成，写"生成测试报告（Mode 5）"

### 200 行上限

超过 200 行时，按以下优先级裁剪：
1. [Test Findings] 只保留最近 3 条
2. [Blockers] 移除已解决的 blocker
3. [Next Test Steps] 只保留下一步

---

## 与 session-handoff 的协作协议

当 session-handoff 技能被触发时（用户说"保存进度/结束/交接"）：

1. session-handoff 应该读取 test-progress.txt 的 [Test Execution Focus]
2. 将测试进度摘要写入 progress.txt 的 [Current Focus] 区块
3. 将测试发现写入 CHANGELOG 的"完成的工作"部分
4. 如果有 P0/P1 缺陷未修复，写入 progress.txt 的 [Blockers & Solutions]

注意：session-handoff 不负责更新 test-plan.json 和 test-progress.txt，
这两个文件始终由 test-architect 技能自己维护。
