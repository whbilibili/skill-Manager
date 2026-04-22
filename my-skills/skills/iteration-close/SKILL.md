---
name: iteration-close
description: >-
  迭代结项工具（迭代级操作）：在一个 feature/fix branch 的开发工作全部完成后，执行完整的结项流程——
  归档任务清单和进度记录到 completed/、清理并重置工作状态文件、生成结项报告（CHANGELOG）、
  让 harness 恢复到可以开始下一件事的干净基线状态。当用户提到结项、分支做完了、归档迭代、
  分支收尾、功能做完了、迭代关闭、合并前收尾、iteration close 时必须使用。
  即使用户只是说"这个需求做完了，接下来干什么"或"准备开始新功能了"，都应触发本技能。
  不适用于：会话级的进度保存（使用 session-handoff，它是"今天下班了明天继续"，不归档不重置）、
  文档对齐（使用 doc-sync）、健康巡检（使用 harness-watchdog）。
  关键区别：iteration-close 是"这个分支做完了，归档+重置"；session-handoff 是"今天先到这，保存断点"。
metadata:
  version: "2.1.0"
  author: "wanghong52"
  changelog: "v2.1.0 — 重新定义 active/ 为按需并行工作区（串行为主+并行可选）；更新 4-C 归档逻辑，区分串行/并行模式下的 active/ 处理"
---

# 迭代结项技能（Iteration Close）

## 职责

在一个 feature branch 或 fix branch 的开发工作完成后，执行完整的结项流程，让工程 harness 从「进行中的迭代状态」恢复到「干净的项目基线状态」，为下一次迭代的启动扫清障碍。

**核心原则**：归档历史，重置现在，保留积累。

- **归档历史**：本次迭代的任务清单、进度记录完整保存，不丢失
- **重置现在**：工作状态文件回到最小骨架，不带入历史噪音
- **保留积累**：跨迭代有价值的知识（架构约束、踩坑记录）继续沉淀，不清除

---

## 与其他技能的边界

| 技能 | 层次 | 触发时机 |
|------|------|---------|
| `session-handoff` | 会话级 | 今天的工作结束，明天继续同一个迭代 |
| `iteration-close` | 迭代级 | 这个 branch 的所有任务完成，准备合并或开始新方向 |
| `doc-sync` | 文档级 | 文档和代码出现偏差，需要局部对齐 |

---

## 执行流程（6 步，Step 2 和 Step 3 需用户参与，其余自动执行）

### Step 1：读取现场状态

静默读取所有相关文件，建立完整的现状认知：

```bash
# 当前分支名（辅助生成迭代名候选）
git branch --show-current 2>/dev/null || echo "（无 git 仓库）"

# 任务完成情况
python3 -c "
import json, os

if not os.path.exists('docs/exec-plans/feature-list.json'):
    print('⚠️  feature-list.json 不存在，无法执行结项')
    exit(1)

tasks = json.load(open('docs/exec-plans/feature-list.json'))
all_tasks = tasks.get('tasks', [])
by_status = {}
for t in all_tasks:
    s = t.get('status', 'unknown')
    by_status.setdefault(s, []).append(t)

print(f'项目：{tasks.get(\"project\", \"未知\")}')
print(f'总任务数：{len(all_tasks)}')
for status, items in sorted(by_status.items()):
    label = {
        'completed': '✅ 已完成',
        'in_progress': '🔄 进行中',
        'pending': '⏳ 待开始',
        'wont_do': '🚫 不做了',
    }.get(status, f'❓ {status}')
    ids = [t[\"task_id\"] for t in items]
    print(f'  {label}：{len(items)} 个 — {ids}')
"

# 未解决的 Bug
python3 -c "
import json, os
if not os.path.exists('docs/exec-plans/issues.json'):
    print('issues.json：不存在（跳过）')
    exit()
issues = json.load(open('docs/exec-plans/issues.json'))
open_issues = [i for i in issues.get('issues', [])
               if i.get('status') not in ('resolved', 'wont_fix')]
if open_issues:
    print(f'未关闭 Bug：{len(open_issues)} 个')
    for i in open_issues:
        print(f'  [{i[\"id\"]}] {i[\"severity\"]} — {i[\"title\"]}')
else:
    print('未关闭 Bug：无')
"

# AGENTS.md 行数
[ -f AGENTS.md ] && echo "AGENTS.md：$(wc -l < AGENTS.md) 行" || echo "AGENTS.md：不存在"

# progress.txt 行数
[ -f docs/exec-plans/progress.txt ] && echo "progress.txt：$(wc -l < docs/exec-plans/progress.txt) 行" || echo "progress.txt：不存在"
```

输出现状摘要后，进入 Step 2 的用户确认环节。

---

### Step 2：确认迭代名称和未完成任务处理

这是第一个需要用户参与的步骤。

**2-A：生成迭代名候选词**

从以下信息中提炼 2-3 个候选名称（2-5 个汉字的功能动词短语，直观、易检索）：
- `feature-list.json` 的 `project` 字段
- 所有 `completed` 任务的 `description` 字段（提取核心名词/动词）
- 当前 git branch name（作为线索，不直接使用）

输出交互提示：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📋 结项确认 — Step 1/2：迭代命名
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

当前分支：[git branch name]
已完成任务：[N] 个 / 总任务：[M] 个

建议迭代名称（归档文件将命名为「[名称].YYYY-MM-DD」）：
  [1] [候选名称 1]
  [2] [候选名称 2]
  [3] [候选名称 3]
  [4] 手动输入

请选择或直接输入迭代名称：
```

等待用户输入后，确定最终的 `[迭代名]`（如 `用户权限管理`），后续所有归档文件以此命名。

**2-B：处理未完成任务**

如果存在 `pending` 或 `in_progress` 状态的任务，输出：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📋 结项确认 — Step 2/2：未完成任务处理
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

以下任务未完成，请逐一确认处理方式：

  [AUTH-007] 角色批量导入功能（pending）
    → [A] 标记为 wont_do（本次迭代取消）
    → [B] 带入下一迭代（写入新的 feature-list.json）
    → [C] 保持 pending（仅归档，不带入）
```

等待用户逐一确认。选择 B 的任务，在 Step 5 重置时会被写入新的 feature-list.json。

如果所有任务都是 `completed` 或 `wont_do`，跳过此环节直接进入 Step 3。

---

### Step 3：处理未关闭的 Bug

如果 `docs/exec-plans/issues.json` 中存在未关闭的 Bug（status ≠ `resolved` / `wont_fix`），询问用户：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🐛 未关闭 Bug 处理
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  [BUG-003] P2 — 订单列表翻页后筛选条件丢失（analyzed_and_ready）
    → [A] 带入下一迭代（保留在新 issues.json）
    → [B] 标记为 wont_fix（本次迭代不修）
    → [C] 先关闭再结项（需要先去修复这个 Bug）
```

选择 A 的 Bug 在 Step 5 重置时写入新的 issues.json。
选择 B 的在归档快照里标注 `wont_fix`，不带入。
选择 C 的中止结项流程，提示用户先完成修复再触发结项。

如果没有未关闭的 Bug，跳过此步骤。

---

### Step 4：执行归档

用户确认完成后，自动执行归档操作。

**4-A：归档 feature-list.json**

```bash
# 创建归档目录（如不存在）
mkdir -p docs/exec-plans/completed

# 归档当前任务清单
cp docs/exec-plans/feature-list.json "docs/exec-plans/completed/feature-list.[迭代名].[今日日期].json"

echo "✅ 任务清单已归档：docs/exec-plans/completed/feature-list.[迭代名].[今日日期].json"
```

**4-B：归档 issues.json（如存在）**

```bash
cp docs/exec-plans/issues.json "docs/exec-plans/completed/issues.[迭代名].[今日日期].json" 2>/dev/null && \
  echo "✅ Bug 清单已归档：docs/exec-plans/completed/issues.[迭代名].[今日日期].json" || \
  echo "ℹ️  issues.json 不存在，跳过"
```

**4-C：归档 exec-plans/active/ 下的并行工作区（如有）**

> `active/` 仅在并行模式下使用。串行模式下 `active/` 应为空，此步骤将直接跳过。
> 如果 `active/` 不为空，说明本次迭代使用了并行模式，需要将所有并行工作区归档。

```bash
python3 -c "
import os, shutil, datetime

active_dir = 'docs/exec-plans/active'
completed_dir = 'docs/exec-plans/completed'
os.makedirs(completed_dir, exist_ok=True)

if not os.path.exists(active_dir):
    print('ℹ️  active 目录不存在，跳过')
    exit()

plans = [d for d in os.listdir(active_dir) if os.path.isdir(os.path.join(active_dir, d)) and not d.startswith('.')]
if not plans:
    print('✅ active/ 为空（串行模式，无并行工作区需要归档）')
    exit()

today = datetime.date.today().isoformat()
for plan in plans:
    src = os.path.join(active_dir, plan)
    dst = os.path.join(completed_dir, f'{plan}.{today}')
    shutil.move(src, dst)
    print(f'✅ 并行工作区已归档：{src} → {dst}')

print(f'📌 共归档 {len(plans)} 个并行工作区，active/ 已恢复为空')
"
```

**4-D：Dead Ends 强制毕业**

检查 `docs/exec-plans/progress.txt` 中是否还有未毕业到 `docs/caveats.md` 的 Dead Ends，如有，强制执行毕业（追加到 caveats.md，格式见 session-handoff 技能的 Step 3.5）。

```bash
python3 -c "
import re, os, datetime

if not os.path.exists('docs/exec-plans/progress.txt'):
    print('ℹ️  progress.txt 不存在，跳过 Dead Ends 检查')
    exit()

content = open('docs/exec-plans/progress.txt').read()
match = re.search(r'### \[Dead Ends\](.*?)(?=### \[|\$)', content, re.DOTALL)
if not match or not match.group(1).strip():
    print('✅ 无 Dead Ends 需要毕业')
    exit()

dead_ends_block = match.group(1).strip().splitlines()
entries = [line.strip('- ').strip() for line in dead_ends_block if line.strip().startswith(('- ', '例：', '例:'))]
valid_entries = [e for e in entries if e and not e.startswith('例')]

if not valid_entries:
    print('✅ Dead Ends 区块无有效条目，跳过')
    exit()

today = datetime.date.today().isoformat()
os.makedirs('docs', exist_ok=True)

if not os.path.exists('docs/caveats.md'):
    with open('docs/caveats.md', 'w') as f:
        f.write('# Caveats — 踩坑永久档案\n\n本文件是项目所有已知陷阱的永久存档。\n\n> 写入规则：只追加，不删除。已修复的坑用「已修复」标注而非删除。\n\n## 踩坑记录\n\n| 日期 | 现象描述 | 根因 | 预防方法 | 状态 |\n|------|---------|------|---------|------|\n')

with open('docs/caveats.md', 'a') as f:
    for entry in valid_entries:
        f.write(f'| {today} | {entry} | 来自迭代结项 Dead Ends 毕业 | — | 活跃 |\n')

print(f'✅ {len(valid_entries)} 条 Dead Ends 已毕业到 docs/caveats.md')
"
```

**4-E：生成结项报告（CHANGELOG）**

在 `docs/CHANGELOG/` 下生成本次迭代的结项报告：

```bash
mkdir -p docs/CHANGELOG
```

报告内容模板：

```markdown
# [迭代名] 结项报告

- **日期**：[今日日期]
- **分支**：[git branch name]
- **周期**：[feature-list.json 的 created_at] → [今日日期]

---

## 交付清单

### 已完成（[N] 个）
| Task ID | 描述 | 验证方式 |
|---------|------|---------|
| [AUTH-001] | [描述] | [verification.auto] |

### 未完成（[M] 个）
| Task ID | 描述 | 处理方式 |
|---------|------|---------|
| [AUTH-007] | [描述] | wont_do / 带入下一迭代 |

---

## 本次迭代关键架构决策

（从 progress.txt 的 [Key Decisions] 区块提炼，保留有长期价值的决策）

- [YYYY-MM-DD] [决策描述]

---

## 遗留问题

### 未修复 Bug（带入下一迭代）
| Bug ID | 严重性 | 标题 |
|--------|--------|------|
| [BUG-003] | P2 | [标题] |

### 技术债（如有）
- [描述]

---

## 踩坑沉淀

本次迭代新增踩坑记录 [N] 条，已归档至 `docs/caveats.md`。
摘要：
- [踩坑简述]

---

## 归档文件

- 任务清单：`docs/exec-plans/completed/feature-list.[迭代名].[日期].json`
- Bug 清单：`docs/exec-plans/completed/issues.[迭代名].[日期].json`（如有）
- exec-plans：`docs/exec-plans/completed/[task-name].[日期]/`（如有）
```

---

### Step 5：执行重置

归档完成后，将工作状态文件恢复到「可以开始下一件事」的干净状态。

**5-A：重置 feature-list.json**

```python
import json, datetime

old = json.load(open('docs/exec-plans/feature-list.json'))

# 带入下一迭代的任务（用户在 Step 2 中选择 B 的）
carry_over_tasks = [
    # 由 Step 2 的交互结果决定
]

new_content = {
    "project": old.get("project", ""),
    "prd": old.get("prd", ""),
    "previous_iterations": old.get("previous_iterations", []) + [
        f"docs/exec-plans/completed/feature-list.[迭代名].[今日日期].json"
    ],
    "created_at": datetime.date.today().isoformat(),
    "tasks": carry_over_tasks  # 空列表，或带入的任务（status 重置为 pending）
}

json.dump(new_content, open('docs/exec-plans/feature-list.json', 'w'),
          ensure_ascii=False, indent=2)
print("✅ feature-list.json 已重置")
```

带入的任务 status 重置为 `"pending"`，`metadata.started_at` 和 `metadata.verified_at` 清空，作为全新任务进入下一迭代。

**5-B：重置 issues.json（如有带入的 Bug）**

```python
import json, os

carry_over_bugs = [
    # 用户在 Step 3 中选择 A 的 Bug
]

old = json.load(open('docs/exec-plans/issues.json')) if os.path.exists('docs/exec-plans/issues.json') else {}

new_content = {
    "project": old.get("project", ""),
    "previous_iterations": old.get("previous_iterations", []) + [
        f"docs/exec-plans/completed/issues.[迭代名].[今日日期].json"
    ],
    "issues": carry_over_bugs
}

json.dump(new_content, open('docs/exec-plans/issues.json', 'w'),
          ensure_ascii=False, indent=2)
msg = f"保留 {len(carry_over_bugs)} 个未关闭 Bug" if carry_over_bugs else "无遗留 Bug"
print(f"✅ issues.json 已重置（{msg}）")
```

**5-C：清空 progress.txt**

```bash
# 清空内容，保留文件（空文件 = 等待下一个架构师 Skill 写入新起点）
> docs/exec-plans/progress.txt
echo "✅ progress.txt 已清空"
```

**5-D：AGENTS.md 瘦身建议（输出建议，等用户确认）**

扫描 AGENTS.md，识别「迭代内」的噪音内容，以列表形式展示，**不自动修改**：

```bash
python3 -c "
import re, os

if not os.path.exists('AGENTS.md'):
    print('ℹ️  AGENTS.md 不存在，跳过')
    exit()

content = open('AGENTS.md').read()
lines = content.splitlines()
total = len(lines)
print(f'AGENTS.md 当前 {total} 行（目标：结项后 ≤ 60 行）')
print()

patterns = [
    (r'(verification|验证命令|curl|mvn test|go test|npm run)', '验证命令（可移入 CHANGELOG）'),
    (r'(completed|已完成|✅.*Task)', '已完成任务的详细说明（可移入 CHANGELOG）'),
    (r'(Dead End|dead end|无效路径)', 'Dead Ends（应已毕业到 docs/caveats.md）'),
    (r'(架构约束|红线).{0,50}(禁止|必须|不允许)', '详细架构规则（可降级到 ARCHITECTURE.md）'),
]

suggestions = []
for i, line in enumerate(lines, 1):
    for pattern, reason in patterns:
        if re.search(pattern, line, re.IGNORECASE):
            suggestions.append((i, line.strip()[:60], reason))
            break

if suggestions:
    print('建议检查以下行（共 {} 处），确认是否需要降级或删除：'.format(len(suggestions)))
    for lineno, preview, reason in suggestions[:15]:
        print(f'  第 {lineno:3d} 行：{preview}')
        print(f'           → {reason}')
        print()
    if len(suggestions) > 15:
        print(f'  ...以及另外 {len(suggestions) - 15} 处，建议使用 doc-sync 技能做完整瘦身')
else:
    print('✅ AGENTS.md 无明显噪音内容，可直接使用')
"
```

输出建议后，询问用户：「是否现在调用 doc-sync 技能对 AGENTS.md 进行全量对齐和瘦身？（推荐）」

---

### Step 6：验证 + 输出下一迭代起点指引

执行最终验证，确认结项操作全部完成：

```bash
python3 -c "
import json, os

checks = []

# 检查归档文件是否存在
archive_file = 'docs/exec-plans/completed/feature-list.[迭代名].[今日日期].json'
if os.path.exists(archive_file):
    tasks = json.load(open(archive_file))
    checks.append(('✅', f'任务清单已归档（{len(tasks.get(\"tasks\", []))} 个任务）'))
else:
    checks.append(('❌', '任务清单归档文件不存在'))

# 检查 feature-list.json 已重置
current = json.load(open('docs/exec-plans/feature-list.json'))
if len(current.get('tasks', [])) == 0 or all(t.get('status') == 'pending' for t in current.get('tasks', [])):
    checks.append(('✅', f'feature-list.json 已重置（{len(current.get(\"tasks\", []))} 个带入任务）'))
else:
    checks.append(('⚠️', 'feature-list.json 中仍有非 pending 任务，请检查'))

# 检查 progress.txt 已清空
if os.path.exists('docs/exec-plans/progress.txt'):
    size = os.path.getsize('docs/exec-plans/progress.txt')
    if size == 0:
        checks.append(('✅', 'progress.txt 已清空'))
    else:
        checks.append(('⚠️', f'progress.txt 未清空（{size} 字节）'))

for icon, msg in checks:
    print(f'{icon} {msg}')
"
```

输出最终结项报告：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🎉 迭代结项完成：[迭代名]
  时间：[今日日期]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📦 归档
   任务清单 → docs/exec-plans/completed/feature-list.[迭代名].[日期].json
   Bug 清单 → docs/exec-plans/completed/issues.[迭代名].[日期].json（如有）
   exec-plans → docs/exec-plans/completed/[task-name].[日期]/（如有）
   结项报告 → docs/CHANGELOG/[迭代名].[日期].md

🔄 重置
   feature-list.json → 空白（[N] 个任务带入下一迭代）
   progress.txt      → 已清空
   issues.json       → [M] 个 Bug 带入下一迭代

📚 持续积累（未动）
   ARCHITECTURE.md  → 跨迭代架构约束继续有效
   docs/caveats.md  → [本次新增 X 条] 踩坑记录持续积累

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🚀 下一迭代的起点：

   1. （如需合并代码）执行 git 合并操作
   2. 启动新迭代规划：
      → 后端项目：触发「后端架构师」技能，说「新迭代需求：[需求描述]」
      → 前端项目：触发「前端架构师」技能，说「新迭代需求：[需求描述]」
   3. 架构师技能会读取 previous_iterations 字段，
      了解历史迭代背景，生成新的 feature-list.json

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 结项产物清单（完整版）

| 产物 | 操作 | 结果 |
|------|------|------|
| `docs/exec-plans/completed/feature-list.[名].[日期].json` | 新建（归档） | 本次迭代任务完整历史 |
| `docs/exec-plans/completed/issues.[名].[日期].json` | 新建（归档，如有） | 本次迭代 Bug 完整历史 |
| `docs/exec-plans/completed/[task-name].[日期]/` | 移入（归档，如有） | 并行工作区执行计划（仅并行模式下存在） |
| `docs/CHANGELOG/[名].[日期].md` | 新建 | 结项报告 |
| `docs/exec-plans/feature-list.json` | 重置为最小骨架 | 只含 project / previous_iterations / 带入任务 |
| `docs/exec-plans/issues.json` | 重置（只保留带入 Bug） | 干净的 Bug 池 |
| `docs/exec-plans/progress.txt` | 清空 | 空文件，等待下一个架构师写入 |
| `AGENTS.md` | 输出瘦身建议（不自动改） | 由用户确认后 doc-sync 执行 |
| `ARCHITECTURE.md` | 不动 | 跨迭代积累，永续有效 |
| `docs/caveats.md` | 仅追加（Dead Ends 强制毕业） | 跨迭代积累，永续有效 |
| `docs/exec-plans/tech-debt-tracker.md` | 不动 | 跨迭代积累，永续有效 |

---

## 注意事项

- **结项不等于代码合并**：本技能只处理 harness 文档状态，不执行 git 操作。代码合并由你在结项前后自行决定。
- **Step 2 和 Step 3 不能跳过**：未完成任务和未关闭 Bug 的处理方式必须由你明确确认，不允许 Skill 自动猜测。
- **AGENTS.md 瘦身是建议，不是强制**：Step 5-D 只输出建议，由你决定是否立即执行。如果 AGENTS.md 本来就很精简（≤ 60 行），可以直接跳过。
- **previous_iterations 字段是下一迭代的记忆**：架构师技能初始化新迭代时会读取这个字段，了解历史背景。
- **结项后立即触发 doc-sync 是最佳实践**：结项 + doc-sync 的组合，能让工程 harness 恢复到最干净的基线状态。
