---
name: session-handoff
description: >-
  会话级交接棒（会话级操作）：在 Agent 结束当天工作前，执行结构化交接流程——更新 progress.txt
  断点信息、同步 feature-list.json 任务状态、生成 CHANGELOG 条目，确保下一个 Session 能从断点
  无摩擦接手。当用户提到会话结束、保存进度、交接棒、end session、我要结束了、下次继续、
  保存上下文、更新进度时必须使用。即使用户只是说"今天先到这吧"或"我要去开会了"，都应触发本技能。
  不适用于：迭代级的归档和重置（使用 iteration-close，它是"这个分支做完了，归档+重置+生成结项报告"）、
  文档全量对齐（使用 doc-sync）、健康巡检（使用 harness-watchdog）。
  关键区别：session-handoff 是"今天先到这，保存断点，明天继续同一个迭代"；
  iteration-close 是"这个分支做完了，归档历史，重置状态，准备下一个迭代"。
metadata:
  version: "2.1.0"
  author: "wanghong52"
  changelog: "v2.1.0 — 对齐 active/ 按需并行工作区语义（串行为主+并行可选）；新增并行模式下交接棒需记录 active/ 工作区状态的说明"
---

# Session Handoff Skill

## 职责

在 Agent 会话结束时，执行结构化的「交接棒」流程，保证下一个 Agent（或下一个 Session 的自己）能精确地从断点继续，而无需重新扫描整个工程。

**核心原则**：进度在文件里，不在上下文里。上下文结束，文件永存。

---

## 触发时机

以下任意情况触发交接棒流程：
- 用户明确说「结束」「收尾」「保存进度」
- 用户说完成了某个功能，准备离开
- Agent 完成一个 Task 后，用户没有立即下达新任务
- 用户明确要切换工作方向

---

## 交接流程（5 步，全部执行）

### Step 1：读取当前工作状态

首先收集以下信息（从工程文件读取，不从记忆推断）：

```bash
# 读取当前 in_progress 任务
python3 -c "
import json
tasks = json.load(open('docs/exec-plans/feature-list.json'))
in_progress = [t for t in tasks.get('tasks', []) if t.get('status') == 'in_progress']
pending = [t for t in tasks.get('tasks', []) if t.get('status') == 'pending']
print('IN_PROGRESS:', [t['task_id'] for t in in_progress])
print('PENDING:', [t['task_id'] for t in pending])
"
```

然后询问用户（或从当前对话推断）：
- 当前 Task 是否已完成？（如完成 → 翻转 status = completed）
- 卡在哪个具体文件/方法？（填入 Current Focus）
- 本次会话有哪些重要技术决策？（填入 Key Decisions）

### Step 2：更新 feature-list.json

根据 Step 1 的确认，执行状态更新：

- 已完成的 Task → `"status": "completed"`，补充 `"metadata.verified": true`，`"metadata.verified_at": "[今日日期]"`
- 新发现的 Task → **不得由编码执行者自行添加**，提醒用户由架构师评估后录入
- 仍在进行中的 Task → 保持 `"in_progress"`，确认 started_at 已记录

### Step 3：更新 docs/exec-plans/progress.txt

**强制裁剪规则**：如果当前 progress.txt 超过 200 行，按以下顺序裁剪后再写入新内容：

**Dead Ends 毕业（先执行）**：
- 将 `[Dead Ends]` 中所有条目提取出来，追加到 `docs/caveats.md`（如文件不存在则创建）
- 格式为：`| [今日日期] | [Dead End 描述] | 来自 progress.txt 裁剪 | — |`
- 这些踩坑记录从 progress.txt 清除，但永久存档在 caveats.md，供未来所有 Session 查阅

**Key Decisions 归档（后执行）**：旧 Key Decisions（保留最近 3 条，其余）迁移到 `docs/CHANGELOG/CHANGELOG-[今日日期].md`

按以下模板更新（**完整替换**对应区块，不追加到末尾）：

```
### [Current Focus]
[精确到文件路径和方法名，例如：]
正在处理 platform-api/src/main/java/.../OpenClawAdminServiceImpl.java
具体卡点：listOpenClawBots() 方法中 MIS → userId 转换逻辑，第 152 行附近

### [Key Decisions]
[仅记录本次会话新增的非共识决策，例如：]
2026-04-20：选用 Redis SETNX 实现幂等锁（TTL=30s），原因是不引入额外分布式锁框架

### [Blockers & Solutions]
[预见到的下一步卡点，例如：]
- 预计卡点：getUserIdByMis() 批量接口不存在，只有单次调用版本
  备选方案：循环单次调用 + Caffeine 本地缓存，性能可接受（<50 用户/次）

### [Next Steps]
[明确到「第一条命令」级别，例如：]
1. 打开 OpenClawAdminServiceImpl.java，找到 buildUserInfoMap() 方法
2. 在方法入口添加 getMisToUserIdMap()，建立 mis→userId 映射
3. 修改后执行：mvn compile -pl platform-api -am -DskipTests -q
4. 验证：curl http://localhost:8080/api/platform/admin/openclaw/list | jq '.data.list[0].createMisAvatar'
```

### Step 3.5：docs/caveats.md 文件格式

如果 `docs/caveats.md` 不存在，先用以下骨架创建：

```markdown
# Caveats — 踩坑永久档案

本文件是项目所有已知陷阱的永久存档。每一条记录都代表某个 Agent 或人类开发者曾经踩过的真实坑。

> 写入规则：只追加，不删除。已修复的坑用「已修复」标注而非删除，让未来的 Agent 知道这个坑曾经存在。

## 踩坑记录

| 日期 | 现象描述 | 根因 | 预防方法 | 状态 |
|------|---------|------|---------|------|
```

追加新条目时，每行格式：
```
| YYYY-MM-DD | [踩坑描述，一句话说清楚现象] | [根因，精确到模块/函数] | [预防方法，具体可操作] | 活跃 / 已修复([Task ID]) |
```

---

### Step 4：生成 CHANGELOG 条目

在 `docs/CHANGELOG/CHANGELOG-[今日日期].md` 中追加本次会话的工作摘要：

```markdown
## [时间] Session 摘要

### 完成的工作
- [Task ID] [任务描述] — [关键实现点]

### 关键决策
- [决策内容]

### 规范合规性快照
- 本次会话涉及技术栈：[Java 后端 / TypeScript / React / Node.js / 其他]
- 规范文件加载情况：[已加载 / 未安装降级为 Karpathy 三原则]
- 规范违反发现并修复：[X 处，列出条目] / [无]
- 规范违反遗留（已知但未修复）：[描述，注明原因] / [无]

### 遗留问题
- [遗留点，供下次接手]
```

**规范合规性快照填写说明：**

- 「涉及技术栈」从本次修改的文件后缀推断（.java → Java 后端，.tsx/.ts → TypeScript/React）
- 「规范文件加载情况」从当前会话的 1-F 步骤执行记录中提取；若当前 Session 是架构规划（非编码），填「非编码 Session，不适用」
- 「规范违反发现并修复」是本次会话中 coding-reviewer 或 2-E 自查门控发现并已修复的问题摘要，不超过 3 条
- 「规范违反遗留」是明知违反但因时间/依赖原因未修复的条目，**必须如实填写**，不允许留空白遮掩

> **设计意图**：让下一个 Session 的接班者在读 progress.txt + CHANGELOG 时，能立刻判断「上一个 Session 遗留了哪些规范债」，而不是等 coding-reviewer 在提交时才发现。

如果今日 CHANGELOG 文件不存在，先创建再追加。

### Step 5：验证交接条件

执行以下检查，确保交接棒有效：

```bash
python3 -c "
import os, json

# 检查 1：progress.txt 是否已更新（文件修改时间应为今天）
import datetime
if os.path.exists('docs/exec-plans/progress.txt'):
    mtime = datetime.datetime.fromtimestamp(os.path.getmtime('docs/exec-plans/progress.txt')).date()
    today = datetime.date.today()
    if mtime == today:
        print('✅ progress.txt 已更新（今日）')
    else:
        print(f'⚠️  progress.txt 最后更新于 {mtime}，可能未更新')

# 检查 2：无多个 in_progress 任务（串行模式约束）
tasks = json.load(open('docs/exec-plans/feature-list.json'))
in_progress = [t['task_id'] for t in tasks['tasks'] if t.get('status') == 'in_progress']
has_parallel = any(t.get('plan_path') for t in tasks['tasks'])
if has_parallel:
    print(f'📌 并行模式：当前有 plan_path 指向 active/ 的任务，允许多个 in_progress')  
    print(f'   进行中任务：{in_progress}')
    # 检查 active/ 目录下每个并行任务的 progress.txt 是否存在
    active_dir = 'docs/exec-plans/active'
    if os.path.exists(active_dir):
        plans = [d for d in os.listdir(active_dir) if os.path.isdir(os.path.join(active_dir, d)) and not d.startswith('.')]
        for p in plans:
            local_progress = os.path.join(active_dir, p, 'progress.txt')
            if os.path.exists(local_progress):
                print(f'   ✅ {p}/progress.txt 存在')
            else:
                print(f'   ⚠️  {p}/progress.txt 不存在，并行工作区缺少独立进度文件')
else:
    if len(in_progress) > 1:
        print(f'⚠️  存在多个 in_progress 任务（串行模式下违反单任务原则）: {in_progress}')
    elif len(in_progress) == 1:
        print(f'✅ 当前进行中任务：{in_progress[0]}')
    else:
        print('ℹ️  无 in_progress 任务（所有任务均已完成或 pending）')
"
```

---

## 输出格式：交接棒报告

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🏁 Session Handoff 完成
  时间：[时间]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

✅ feature-list.json 已更新
   - 完成：[Task ID 列表]
   - 进行中：[Task ID]
   - 待开始：[N] 个任务

✅ progress.txt 已更新（[X] 行）
✅ CHANGELOG-[日期].md 已追加
[如有 Dead Ends 毕业] ✅ docs/caveats.md 新增 [N] 条踩坑记录

📋 下一个 Session 的第一步：
   cat docs/exec-plans/progress.txt
   → 直接跳到 [Next Steps] 第 1 条执行

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 快速模式

如果用户说「快速交接」或时间紧张，只执行 Step 2（任务状态）和 Step 3（progress.txt），跳过 CHANGELOG 生成。但必须明确告知用户 CHANGELOG 未生成。
