---
name: doc-sync
description: >-
  Harness 文档体系全量对齐工具：对比代码现实与 AGENTS.md、ARCHITECTURE.md、PLANS.md、
  docs/caveats.md、tech-debt-tracker.md 五类文档，找出过时或缺失的条目并执行外科手术式更新。
  当用户提到同步文档、文档对齐、更新文档、AGENTS.md 对齐、文档和代码不一致、
  harness-watchdog 报告文档不一致时必须使用。建议每 5 个 Task 完成后、大型功能合并后、
  或迭代结项后定期触发。即使用户只是说"文档好像过时了"或"AGENTS.md 需要更新一下"，都应触发本技能。
  不适用于：项目初始化和架构规划（使用 backend/frontend-architect 生成文档初稿）、
  健康巡检和问题检测（使用 harness-watchdog，它只检测不修复）、
  代码审查（使用 coding-reviewer）、Bug 记录（使用 issue-triage）。
  与 harness-watchdog 的区别：watchdog 是"体检"（只报告问题），doc-sync 是"治疗"（执行修复）。
metadata:
  version: "2.1.0"
  author: "wanghong52"
  changelog: "v2.1.0 — 重新定义 active/ 为按需并行工作区（串行为主+并行可选）；更新维度 3 的 PLANS.md 检查逻辑，区分串行/并行模式；新增 active/ 与 feature-list.json plan_path 一致性检查"
---

# Doc Sync Skill

## 职责

对比代码现实与所有 harness 文档文件，找出过时或缺失的条目，执行一次**全量对齐**，让文档重新成为 Coding Agent 可以信任的导航体系。

**不修改业务代码，只更新文档。**

---

## 触发时机

以下任一情况出现时触发：
- 完成了一个大型功能模块（5+ 个 Task 完成后）
- 发现 Coding Agent 在新 Session 里仍然做了「全局扫描」（说明文档导航已不够用）
- 项目目录结构发生了重大重构
- `AGENTS.md` 上次更新距今已超过 2 周
- harness-watchdog 报告「AGENTS.md 索引与实际文件不一致」
- `docs/exec-plans/progress.txt` 裁剪后（Dead Ends 已毕业，需同步到 ARCHITECTURE.md 的废弃方案区块）
- `iteration-close` 完成后（迭代结项最佳实践：结项 + doc-sync 配套使用）

---

## 文档体系说明

本技能维护以下五类文档，每类有明确的写入责任边界：

| 文档 | 职责 | 体积约束 | 写入者 |
|------|------|---------|------|
| `AGENTS.md` | 导航索引，冷启动必读 | ≤ 120 行，只放指针 | 架构师初稿，Coding Worker 轻量追加，doc-sync 全量对齐 |
| `ARCHITECTURE.md` | 架构约束全集 | 无硬限，但条目要求精炼 | 架构师初稿，Coding Worker 追加，doc-sync 整理 |
| `docs/caveats.md` | 踩坑永久档案 | 只增不减 | issue-triage / session-handoff / iteration-close / Coding Worker |
| `docs/exec-plans/tech-debt-tracker.md` | 技术债追踪 | 按优先级维护 | 人工 + issue-triage |
| `PLANS.md` | 当前及历史执行计划索引 | ≤ 60 行 | 架构师初稿，doc-sync 更新条目状态 |

---

## 执行流程

### Step 1：读取所有基准文件

静默执行以下操作，建立完整的现状认知：

```bash
# 文档现状
cat AGENTS.md 2>/dev/null
cat ARCHITECTURE.md 2>/dev/null
cat PLANS.md 2>/dev/null
cat docs/caveats.md 2>/dev/null
cat docs/exec-plans/tech-debt-tracker.md 2>/dev/null

# 代码现状
find . -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.go" -o -name "*.java" -o -name "*.py" \) \
  -not -path "*/node_modules/*" \
  -not -path "*/.git/*" \
  -not -path "*/dist/*" \
  -not -path "*/build/*" \
  -not -path "*/.next/*" \
  | sort

# 任务历史（了解哪些功能已完成）
cat docs/exec-plans/feature-list.json 2>/dev/null

# 进度文件（Dead Ends 和 Key Decisions 来源）
cat docs/exec-plans/progress.txt 2>/dev/null

# 归档目录（了解历史迭代）
ls docs/exec-plans/completed/ 2>/dev/null

# Git 近期变更（了解最近改动了什么）
git log --oneline -20 2>/dev/null
git diff HEAD~10 --name-only 2>/dev/null || git diff --name-only 2>/dev/null
```

输出现状摘要：

```
📊 文档对齐现状：
   - AGENTS.md：[存在 / 不存在]，当前 [N] 行，上次修改：[从 git log 读取]
   - ARCHITECTURE.md：[存在 / 不存在]
   - PLANS.md：[存在 / 不存在]
   - docs/caveats.md：[存在 / 不存在，X 条踩坑记录]
   - docs/exec-plans/tech-debt-tracker.md：[存在 / 不存在]
   - 代码文件总数：X 个
   - 已完成 Task 数：X 个
   - 待检查维度：文件索引 / 架构约束 / PLANS.md / caveats / tech-debt / 验证命令
```

---

### Step 2：六维对齐检查

#### 维度 1：AGENTS.md 文件索引对齐

**目标**：AGENTS.md 只放「指针」，帮 Agent 快速定位，不放详细内容。

**检查项 A — 新增但未登记的目录/文件**：
扫描代码文件列表，找出 AGENTS.md 没有覆盖的新目录。判断标准：包含 3 个以上业务文件的目录就应该有独立索引条目。

**检查项 B — 已删除但索引仍在的条目**：
AGENTS.md 文件索引里的路径，在实际代码中已不存在。

**检查项 C — AGENTS.md 是否超过 120 行**：
如果超过，识别哪些内容可以「降级」到 `ARCHITECTURE.md`（详细架构规则）或 `docs/caveats.md`（踩坑）。

```bash
lines=$(wc -l < AGENTS.md 2>/dev/null || echo 0)
echo "AGENTS.md 当前行数: ${lines}"
[ "$lines" -gt 120 ] && echo "⚠️ 超过 120 行，需要瘦身"
```

**检查项 D — 文档中对 harness 路径的引用是否已更新**：
检查 AGENTS.md 和 ARCHITECTURE.md 中是否仍然引用旧路径（`.ai/state/`、`AGENT.md`、`docs/tech-debt.md`），如有，记录为「需更新」条目：

```bash
python3 -c "
import os, re

old_patterns = [
    ('.ai/state/', 'docs/exec-plans/'),
    ('AGENT.md', 'AGENTS.md'),
    ('docs/tech-debt.md', 'docs/exec-plans/tech-debt-tracker.md'),
    ('docs/archive/', 'docs/exec-plans/completed/'),
]

files_to_check = ['AGENTS.md', 'ARCHITECTURE.md', 'PLANS.md', 'docs/caveats.md']
found = []

for filepath in files_to_check:
    if not os.path.exists(filepath):
        continue
    content = open(filepath).read()
    for old, new in old_patterns:
        if old in content:
            count = content.count(old)
            found.append((filepath, old, new, count))

if found:
    print('⚠️  发现旧路径引用，需要更新：')
    for filepath, old, new, count in found:
        print(f'   {filepath}：\"{old}\" → \"{new}\"（出现 {count} 次）')
else:
    print('✅ 无旧路径引用，路径命名规范一致')
"
```

---

#### 维度 2：ARCHITECTURE.md 架构约束对齐

**检查项 A — 隐性约定未成文**：
从 `docs/exec-plans/progress.txt` 的 `[Key Decisions]` 中找到已做的架构决策，检查是否已写入 `ARCHITECTURE.md`。

**检查项 B — AGENTS.md 的架构约束区块是否过度膨胀**：
AGENTS.md 的「架构约束（红线）」区块应 ≤ 5 条，只放最重要的红线。超出的条目移入 `ARCHITECTURE.md` 对应区块。

**检查项 C — Dead Ends 归档同步**：
`ARCHITECTURE.md` 的「已废弃的方案」表格是否已包含 `docs/caveats.md` 中已确认为框架级 Dead End 的条目。

**检查项 D — 规范引用路径有效性**：

检查 `ARCHITECTURE.md` 的「规范引用」区块中写入的外部 Skill 规范文件路径是否仍然有效。路径失效的原因通常是：外部 Skill 升级后文件重命名、Skill 被卸载、或 catpaw 安装目录变更。

```bash
python3 -c "
import re, os

arch_file = 'ARCHITECTURE.md'
if not os.path.exists(arch_file):
    print('⚠️  ARCHITECTURE.md 不存在，跳过规范引用检查')
    exit()

content = open(arch_file).read()

# 提取规范引用区块中的路径（匹配反引号包裹的 ~/.catpaw/... 路径）
paths = re.findall(r'\`(~/.catpaw/skills/[^\`]+\.md)\`', content)

if not paths:
    print('ℹ️  ARCHITECTURE.md 中未找到规范引用区块，可能是旧版本（初始化前）项目')
    exit()

home = os.path.expanduser('~')
missing = []
for p in paths:
    abs_path = p.replace('~', home)
    if not os.path.exists(abs_path):
        missing.append(p)

if missing:
    print('❌ 以下规范文件路径已失效（对应 Skill 可能已卸载或路径变更）:')
    for p in missing:
        print(f'   {p}')
    print('建议：重新安装对应 Skill，或在 ARCHITECTURE.md 中更新路径')
else:
    print(f'✅ 规范引用路径全部有效（共 {len(paths)} 条）')
"
```

> **修复动作**：如果发现失效路径，在 Step 3 报告中列出，Step 4 执行时更新 ARCHITECTURE.md 的「规范引用」区块，将失效路径替换为正确路径，或标注「⚠️ 未安装，降级为 Karpathy 三原则」。

---

#### 维度 3：PLANS.md 执行计划索引对齐 + active/ 一致性检查

**检查项 A — active/ 与 feature-list.json 的 plan_path 一致性**：
`docs/exec-plans/active/` 是按需并行工作区，仅在多会话/worktree 并行模式下使用。检查 active/ 目录内容与 `feature-list.json` 中 `plan_path` 字段是否一致：
- 串行模式（所有 `plan_path` 为 null）：`active/` 应为空
- 并行模式（存在非 null 的 `plan_path`）：`active/` 下的目录应与 `plan_path` 引用一一对应

**检查项 B — completed 目录下的计划状态未同步**：
PLANS.md 中标注为「active」的计划，如果已归档到 `docs/exec-plans/completed/`，需要将状态更新为「completed」。

**检查项 C — PLANS.md 是否超过 60 行**：
如超过，检查是否有旧的、已完成的计划可以精简为一行摘要。

```bash
python3 -c "
import os, json

# 检查 PLANS.md
plans_file = 'PLANS.md'
if os.path.exists(plans_file):
    lines = open(plans_file).readlines()
    print(f'PLANS.md 当前 {len(lines)} 行（目标 ≤ 60 行）')
else:
    print('ℹ️  PLANS.md 不存在，跳过计划索引检查')

# 检查 active/ 与 plan_path 一致性
active_dir = 'docs/exec-plans/active'
active_plans = []
if os.path.exists(active_dir):
    active_plans = [d for d in os.listdir(active_dir)
                    if os.path.isdir(os.path.join(active_dir, d)) and not d.startswith('.')]

# 读取 feature-list.json 中的 plan_path
referenced = set()
try:
    tasks = json.load(open('docs/exec-plans/feature-list.json'))
    for t in tasks.get('tasks', []):
        pp = t.get('plan_path') or ''
        if 'active/' in pp:
            parts = pp.split('active/')[-1].split('/')
            if parts:
                referenced.add(parts[0])
except:
    pass

if not active_plans and not referenced:
    print('✅ 串行模式：active/ 为空，所有 plan_path 为 null，状态一致')
elif active_plans and referenced:
    orphans = set(active_plans) - referenced
    missing = referenced - set(active_plans)
    if orphans:
        print(f'⚠️  active/ 中有孤儿目录（无 plan_path 引用）：{list(orphans)}')
    if missing:
        print(f'⚠️  plan_path 引用了不存在的 active/ 目录：{list(missing)}')
    if not orphans and not missing:
        print(f'✅ 并行模式：active/ 目录（{len(active_plans)} 个）与 plan_path 引用完全一致')
elif active_plans and not referenced:
    print(f'⚠️  active/ 非空（{active_plans}）但所有 plan_path 为 null — 可能是上次并行模式遗留，建议清理')
elif referenced and not active_plans:
    print(f'⚠️  有 plan_path 引用（{list(referenced)}）但 active/ 为空 — 目录未创建')

# 扫描 completed 目录
completed_dir = 'docs/exec-plans/completed'
if os.path.exists(completed_dir):
    completed = [d for d in os.listdir(completed_dir)
                 if os.path.isdir(os.path.join(completed_dir, d)) and not d.startswith('.')]
    print(f'completed 目录下的归档：{len(completed)} 个')
else:
    print('ℹ️  docs/exec-plans/completed/ 不存在，跳过')
"
```

---

#### 维度 4：docs/caveats.md 完整性检查

**检查项 A — progress.txt Dead Ends 未同步**：
检查 `docs/exec-plans/progress.txt` 的 `[Dead Ends]` 区块中，是否有条目未出现在 `docs/caveats.md` 中。

**检查项 B — issues.json 规律性 Bug 未沉淀**：
检查 `docs/exec-plans/issues.json` 中，是否有同一模块出现 2 次及以上的 Bug，但 `docs/caveats.md` 中没有对应的预防记录。

**检查项 C — 已修复的坑状态更新**：
检查 `docs/caveats.md` 中标注为「活跃」的踩坑，是否已有对应的已完成 Task 修复了根因，需要更新状态为「已修复([Task ID])」。

```bash
python3 -c "
import json, os, re

# 检查 caveats.md 是否存在
if not os.path.exists('docs/caveats.md'):
    print('⚠️  docs/caveats.md 不存在，需要创建')
    exit()

# 检查 issues.json 中的规律性 Bug
issues_path = 'docs/exec-plans/issues.json'
if os.path.exists(issues_path):
    issues = json.load(open(issues_path))
    from collections import Counter
    module_counts = Counter(
        m for i in issues.get('issues', [])
        for m in i.get('affected_modules', [])
    )
    repeat_modules = {k: v for k, v in module_counts.items() if v >= 2}
    if repeat_modules:
        print('⚠️  以下模块有 2+ 个 Bug，建议检查 caveats.md 是否有对应预防记录:')
        for m, c in repeat_modules.items():
            print(f'   {m}: {c} 个 Bug')
    else:
        print('✅ 无规律性 Bug 模块')
else:
    print('ℹ️  docs/exec-plans/issues.json 不存在，跳过规律性 Bug 检查')
"
```

---

#### 维度 5：docs/exec-plans/tech-debt-tracker.md 更新

**触发条件**：以下任一情况将条目加入 tech-debt-tracker.md：
- issue-triage 分析中发现的设计缺陷（P2/P3 级，但根因是架构问题）
- Coding Worker 在实现中发现但暂时搁置的技术债
- `ARCHITECTURE.md` 的「已废弃方案」中记录的历史包袱

如果 `docs/exec-plans/tech-debt-tracker.md` 不存在，创建骨架：

```markdown
# Tech Debt Tracker — 技术债追踪

| 优先级 | 描述 | 根因 | 预计影响 | 负责人 | 状态 |
|------|------|------|---------|------|------|
```

---

#### 维度 6：验证命令有效性检查

检查 AGENTS.md 的「验证命令清单」中引用的脚本/文件是否仍然存在：

```bash
python3 -c "
import re, os
if not os.path.exists('AGENTS.md'):
    print('⚠️  AGENTS.md 不存在')
    exit()
content = open('AGENTS.md').read()
# 检查命令中引用的文件路径
file_refs = re.findall(r'(?:cat|source|bash|python3|node)\s+([\w./-]+)', content)
missing = [r for r in file_refs if not os.path.exists(r) and not r.startswith('-')]
if missing:
    print('⚠️  AGENTS.md 中验证命令引用了不存在的文件:', missing)
else:
    print('✅ 验证命令引用文件均存在')
"
```

---

### Step 3：输出对齐报告（更新前先确认）

在执行任何修改之前，先输出完整的对齐报告：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  📋 文档体系对齐报告
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

【AGENTS.md 文件索引】（当前 X 行 / 目标 ≤ 120 行）
  ✅ 无变化：X 个条目准确
  ➕ 需新增：[列出新目录及建议描述]
  ❌ 需删除：[列出已不存在的路径]
  ⬇️  需降级到 ARCHITECTURE.md：[AGENTS.md 中过于详细的架构规则]
  🔄 旧路径引用：[需要从 .ai/state/ → docs/exec-plans/ 的引用]

【ARCHITECTURE.md 架构约束】
  ➕ 需新增：[列出未成文的隐性约定]
  🗂️  需归档 Dead End：[列出应移入废弃方案区块的条目]
  🔗 规范引用路径失效：[失效路径列表] / 无失效

【PLANS.md 计划索引】（当前 X 行 / 目标 ≤ 60 行）
  ➕ 需新增：[active 目录下但未登记的计划]
  🔄 需更新状态：[已归档但 PLANS.md 仍标注为 active 的条目]

【docs/caveats.md 踩坑档案】
  ➕ 需同步：[progress.txt Dead Ends 中有但 caveats.md 没有的坑]
  🔧 需标注已修复：[已被 Task 修复但仍标注为活跃的坑]

【docs/exec-plans/tech-debt-tracker.md 技术债】
  ➕ 需新增：[发现的技术债条目]

【验证命令】
  ❌ 失效命令：[引用已不存在文件的命令]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
共发现 X 处需要更新。是否继续执行对齐？
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**等待用户确认后再执行，不要自动修改。**

---

### Step 4：执行对齐

用户确认后，对各文档进行**外科手术式更新**：

- 只修改报告中列出的条目
- 不重写整个文件
- 保留原有的格式和结构
- 不删除任何 `caveats.md` 中的历史记录（只追加或更新状态）

**AGENTS.md 瘦身规则**：
- 将详细的架构规则从 AGENTS.md 移入 `ARCHITECTURE.md` 对应区块
- AGENTS.md 只保留一行指针：「完整架构约束见 ARCHITECTURE.md」
- Dead Ends 从 AGENTS.md 移入 `docs/caveats.md`，AGENTS.md 只保留「踩坑记录见 docs/caveats.md」

**旧路径批量替换**：

如果报告发现了旧路径引用，使用 Python 精确替换（不影响文件其他内容）：

```python
import os

replacements = [
    ('.ai/state/', 'docs/exec-plans/'),
    ('AGENT.md', 'AGENTS.md'),       # 注意：只替换独立出现的 AGENT.md，不要影响 AGENTS.md 本身
    ('docs/tech-debt.md', 'docs/exec-plans/tech-debt-tracker.md'),
    ('docs/archive/', 'docs/exec-plans/completed/'),
]

files_to_fix = ['AGENTS.md', 'ARCHITECTURE.md', 'PLANS.md', 'docs/caveats.md']

for filepath in files_to_fix:
    if not os.path.exists(filepath):
        continue
    content = open(filepath).read()
    original = content
    for old, new in replacements:
        # 对于 AGENT.md → AGENTS.md，要避免把 AGENTS.md 替换成 AGENTSS.md
        if old == 'AGENT.md':
            import re
            content = re.sub(r'(?<![S])AGENT\.md', 'AGENTS.md', content)
        else:
            content = content.replace(old, new)
    if content != original:
        open(filepath, 'w').write(content)
        print(f'✅ {filepath}：旧路径引用已更新')
    else:
        print(f'ℹ️  {filepath}：无需更新')
```

---

### Step 5：提交并记录

```bash
git add AGENTS.md ARCHITECTURE.md PLANS.md docs/caveats.md docs/exec-plans/tech-debt-tracker.md
git commit -m "docs: sync harness documentation

- AGENTS.md: [X 条索引更新]
- ARCHITECTURE.md: [X 条约束更新]
- PLANS.md: [X 条计划状态更新]
- docs/caveats.md: [X 条踩坑同步]
- docs/exec-plans/tech-debt-tracker.md: [X 条技术债更新]"
```

在 `docs/exec-plans/progress.txt` 的 `[Key Decisions]` 追加：

```
[YYYY-MM-DD] 文档同步：harness 文档完成全量对齐，更新了 X 处（详见 git commit [hash]）
```

输出：

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✅ 文档体系对齐完成
     AGENTS.md：[X] 处更新（当前 [N] 行）
     ARCHITECTURE.md：[X] 处更新
     PLANS.md：[X] 处更新
     docs/caveats.md：[X] 条新增 / [X] 条状态更新
     docs/exec-plans/tech-debt-tracker.md：[X] 条新增
     所有文档现在可以作为可信导航体系使用。
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 注意事项

- **先报告，后修改**：Step 3 的确认步骤不能跳过，防止批量误改
- **caveats.md 只增不减**：已修复的坑用「已修复」标注而非删除，让未来的 Agent 知道这个坑曾经存在过
- **AGENTS.md 是导航地图，不是 API 文档**：它记录的是「在哪里写代码」的导航信息，不是接口规范
- **AGENTS.md 体积红线**：如果修改后仍超过 120 行，必须再次检查是否有内容可以降级到 ARCHITECTURE.md 或 caveats.md
- **不评价代码质量**：发现代码问题不在此处记录，使用 `issue-triage` 技能处理
- **路径检查是必做项**：v2.0.0 新增了「旧路径引用检查」（维度 1-D），每次 doc-sync 都必须执行，确保整个 harness 文档体系路径命名一致
