---
name: harness-watchdog
description: >-
  Harness 健康巡检工具（只读诊断，不修改文件）：自动检测 8 类 harness 熵增问题——僵尸任务、
  progress.txt 过长、孤儿工单、AGENTS.md 索引失效、verification 命令失效、文档体系缺失、
  caveats 未沉淀、并行工作区状态异常。当用户提到检查 harness 健康、harness 巡检、任务状态审计、
  有没有僵尸任务、进度文件太长了、检查工程状态时必须使用。建议每天或每次大型功能合并后定期运行。
  即使用户只是说"工程状态怎么样"或"看看有没有什么问题"，只要涉及 harness 健康检查，都应触发本技能。
  不适用于：修复文档不一致（使用 doc-sync，它负责"治疗"）、项目初始化（使用 backend/frontend-architect）、
  代码审查（使用 coding-reviewer）、Bug 分诊（使用 issue-triage）。
  与 doc-sync 的区别：watchdog 是"体检"（只输出报告），doc-sync 是"治疗"（执行修复）。
metadata:
  version: "2.1.0"
  author: "wanghong52"
  changelog: "v2.1.0 — 重新定义 active/ 为按需并行工作区（串行为主+并行可选）；更新 CHECK-8 僵尸计划检测语义，区分串行模式（active/ 应为空）和并行模式（active/ 有计划目录）"
---

# Harness Watchdog Skill

## 职责

检测 harness 的八类熵增问题，输出结构化巡检报告，并提供可直接执行的修复建议。

**不做什么**：不自动修改任何文件，所有修复操作需用户确认后执行。

---

## 巡检清单（8 项检查）

### CHECK-1：僵尸任务检测

**症状**：`feature-list.json` 中存在 `status = "in_progress"` 超过 3 天的任务。

**执行**：
```bash
python3 -c "
import json, datetime
tasks = json.load(open('docs/exec-plans/feature-list.json'))
today = datetime.date.today()
zombies = []
for t in tasks.get('tasks', []):
    if t.get('status') == 'in_progress':
        meta = t.get('metadata', {})
        start = meta.get('started_at') or meta.get('verified_at')
        if start:
            delta = (today - datetime.date.fromisoformat(start[:10])).days
            if delta > 3:
                zombies.append({'id': t['task_id'], 'days': delta})
        else:
            zombies.append({'id': t['task_id'], 'days': 'unknown(no date)'})
if zombies:
    print('⚠️  僵尸任务:', json.dumps(zombies, ensure_ascii=False))
else:
    print('✅ 无僵尸任务')
"
```

**修复建议**：将超期任务 status 回退为 `"pending"` 或推进为 `"completed"`，并更新 progress.txt。

---

### CHECK-2：progress.txt 体积检测

**症状**：`progress.txt` 超过 200 行，成为流水账而非精炼交接棒。

**执行**：
```bash
lines=$(wc -l < docs/exec-plans/progress.txt 2>/dev/null || echo 0)
if [ "$lines" -gt 200 ]; then
  echo "⚠️  progress.txt 过长（${lines} 行），需要裁剪"
  echo "   建议：保留最近 3 次 [Key Decisions]，旧条目迁移到 docs/CHANGELOG/"
else
  echo "✅ progress.txt 体积正常（${lines} 行）"
fi
```

**修复建议**：见 [裁剪流程](#progress-裁剪流程)。

---

### CHECK-3：issues.json 孤儿工单检测

**症状**：`issues.json` 中存在 `status = "promoted_to_task"` 但 `feature-list.json` 中无对应 Task 的孤儿工单。

**执行**：
```bash
python3 -c "
import json, os
if not os.path.exists('docs/exec-plans/issues.json'):
    print('ℹ️  issues.json 不存在，跳过')
    exit()
issues = json.load(open('docs/exec-plans/issues.json'))
tasks = json.load(open('docs/exec-plans/feature-list.json'))
task_sources = {t['metadata'].get('source_issue_id') for t in tasks.get('tasks', []) if t.get('metadata', {}).get('source_issue_id')}
orphans = [i['id'] for i in issues.get('issues', []) if i.get('status') == 'promoted_to_task' and i['id'] not in task_sources]
if orphans:
    print('⚠️  孤儿工单（已排期但无对应 Task）:', orphans)
else:
    print('✅ 无孤儿工单')
"
```

**修复建议**：在 `feature-list.json` 中补充对应 Task，或将孤儿工单 status 回退为 `"analyzed_and_ready"`。

---

### CHECK-4：AGENTS.md 索引一致性检测

**症状**：`AGENTS.md` 中引用的文件路径在实际目录中不存在（或新增了文档但未更新索引）。

**执行**：
```bash
python3 -c "
import re, os
if not os.path.exists('AGENTS.md'):
    print('⚠️  AGENTS.md 不存在')
    exit()
content = open('AGENTS.md').read()
refs = re.findall(r'\`@([^\`]+)\`', content)
missing, ok = [], []
for r in refs:
    r = r.lstrip('@')
    if os.path.exists(r):
        ok.append(r)
    else:
        missing.append(r)
if missing:
    print('⚠️  AGENTS.md 中引用了不存在的文件:', missing)
else:
    print(f'✅ AGENTS.md 索引一致（共 {len(ok)} 个文件引用全部有效）')
"
```

**修复建议**：更新 AGENTS.md 中的文件路径，或创建缺失的文档文件。

---

### CHECK-5：verification 命令有效性抽查

**症状**：`feature-list.json` 中的 `verification` 命令因文件移动、接口变更等原因已失效。

**执行**：从所有 `completed` 状态的 Task 中抽取 `verification` 命令，检测命令格式有效性（非空、非占位符）：

```bash
python3 -c "
import json
tasks = json.load(open('docs/exec-plans/feature-list.json'))
issues = []
for t in tasks.get('tasks', []):
    v = t.get('verification', '')
    if isinstance(v, dict):
        v = v.get('auto', '')
    if not v or ('{' in str(v) and '}' in str(v)):
        if t.get('status') == 'completed':
            issues.append({'id': t['task_id'], 'verification': str(v)[:80] or '(空)'})
if issues:
    print('⚠️  以下已完成 Task 的 verification 命令含占位符或为空（需更新为可执行命令）:')
    for i in issues:
        print(f'   [{i[\"id\"]}]: {i[\"verification\"]}')
else:
    print('✅ verification 命令格式检查通过')
"
```

---

### CHECK-6：文档体系完整性检查

**症状**：项目缺少必要的文档骨架文件，导致架构约束、安全红线、踩坑记录没有固定存档位置。

**执行**：

```bash
python3 -c "
import os

# 必须存在的核心文件（缺少会直接影响 Agent 工作质量）
required = [
    ('AGENTS.md', '导航索引（冷启动必读）', 100),
    ('ARCHITECTURE.md', '架构约束全集', None),
    ('docs/caveats.md', '踩坑永久档案', None),
    ('docs/exec-plans/tech-debt-tracker.md', '技术债追踪', None),
]

# 新体系骨架文件
scaffold = [
    ('PLANS.md', '项目长期规划 & 里程碑'),
    ('docs/QUALITY_SCORE.md', '质量评分面板'),
    ('docs/RELIABILITY.md', '可靠性 & SLO 约定'),
    ('docs/SECURITY.md', '安全约束（P0 红线）'),
    ('docs/PRODUCT_SENSE.md', '产品感知 & 用户价值'),
]

# exec-plans 目录
exec_plans_active = 'docs/exec-plans/active'
exec_plans_completed = 'docs/exec-plans/completed'

issues = []
warnings = []

print('--- 核心文件 ---')
for path, desc, max_lines in required:
    if os.path.exists(path):
        lines = len(open(path).readlines())
        print(f'✅ {path} 存在（{lines} 行）— {desc}')
        if max_lines and lines > max_lines:
            issues.append(f'⚠️  {path} 超过 {max_lines} 行（当前 {lines} 行），需要瘦身')
    else:
        issues.append(f'⚠️  {path} 不存在 — {desc}')

print()
print('--- 骨架文件（新体系） ---')
for path, desc in scaffold:
    if os.path.exists(path):
        lines = len(open(path).readlines())
        content = open(path).read()
        is_empty = '待填充' in content or lines < 10
        status = '⚠️  仍是空骨架（可填充）' if is_empty else f'✅ 已填充（{lines} 行）'
        print(f'{status} — {path} — {desc}')
    else:
        warnings.append(f'ℹ️  {path} 不存在（建议用 backend-architect / frontend-architect 技能初始化）— {desc}')

print()
print('--- exec-plans 目录 ---')
if os.path.exists(exec_plans_active):
    active_plans = [d for d in os.listdir(exec_plans_active) if not d.startswith('.')]
    print(f'✅ {exec_plans_active} 存在，当前活跃计划：{len(active_plans)} 个')
    if active_plans:
        print(f'   活跃计划：{active_plans}')
else:
    warnings.append(f'ℹ️  {exec_plans_active} 目录不存在（建议初始化时创建）')

if os.path.exists(exec_plans_completed):
    completed = [d for d in os.listdir(exec_plans_completed) if not d.startswith('.')]
    print(f'✅ {exec_plans_completed} 存在，已归档：{len(completed)} 个')
else:
    warnings.append(f'ℹ️  {exec_plans_completed} 目录不存在（iteration-close 时自动创建）')

print()
for i in issues:
    print(i)
for w in warnings:
    print(w)
if not issues and not warnings:
    print('✅ 文档体系完整')
elif not issues:
    print('✅ 核心文件完整，骨架文件待初始化（不影响当前工作）')
"
```

**修复建议**：
- 缺少 `ARCHITECTURE.md` 或 `docs/caveats.md`：调用 `frontend-architect` 或 `backend-architect` 技能，其 Step 6 会生成骨架
- 缺少骨架文件（PLANS.md 等）：调用架构师技能重新初始化，或手动创建参考 backend-architect Step 6 模板
- `AGENTS.md` 超过 100 行：调用 `doc-sync` 技能执行全量对齐和瘦身

---

### CHECK-7：caveats.md 与 issues.json 一致性检查

**症状**：`issues.json` 中存在同一模块 2 次及以上的 Bug，但 `docs/caveats.md` 中没有对应的预防记录，说明踩坑知识没有被正确沉淀。

**执行**：

```bash
python3 -c "
import json, os
from collections import Counter

if not os.path.exists('docs/exec-plans/issues.json'):
    print('ℹ️  issues.json 不存在，跳过')
    exit()

issues = json.load(open('docs/exec-plans/issues.json'))
module_counts = Counter(
    m for i in issues.get('issues', [])
    for m in i.get('affected_modules', [])
    if i.get('status') != 'resolved'
)
repeat_modules = {k: v for k, v in module_counts.items() if v >= 2}

if not repeat_modules:
    print('✅ 无规律性 Bug 模块（无模块有 2+ 个未解决 Bug）')
    exit()

caveats_content = ''
if os.path.exists('docs/caveats.md'):
    caveats_content = open('docs/caveats.md').read()

uncovered = []
for module, count in repeat_modules.items():
    if module.lower() not in caveats_content.lower():
        uncovered.append(f'{module}（{count} 个 Bug）')

if uncovered:
    print('⚠️  以下高频 Bug 模块在 caveats.md 中没有预防记录（建议使用 issue-triage 技能触发沉淀）:')
    for m in uncovered:
        print(f'   - {m}')
else:
    print('✅ 所有高频 Bug 模块均有 caveats.md 记录')
"
```

**修复建议**：对这些模块，重新触发 `issue-triage` 技能，其 Step 4.5 会自动将规律性踩坑写入 `docs/caveats.md`。

---

### CHECK-8：active/ 并行工作区状态检测

**背景**：`docs/exec-plans/active/` 是按需并行工作区，仅在用户明确开启多会话/worktree 并行开发时使用。串行模式（默认）下，该目录应为空（仅含 `.gitkeep`）。

**检测逻辑**：
1. 如果 `active/` 不为空，检查 `feature-list.json` 中是否有 `plan_path` 指向 `active/` 的任务（合法并行模式）
2. 如果有任务的 `plan_path` 指向 `active/`，检测目录是否超过 7 天未活动（僵尸并行计划）
3. 如果 `active/` 不为空但没有任何任务的 `plan_path` 引用它（孤儿目录），说明上次并行模式结束后未清理

**执行**：
```bash
python3 -c "
import os, json, datetime

active_dir = 'docs/exec-plans/active'
if not os.path.exists(active_dir):
    print('ℹ️  docs/exec-plans/active 目录不存在，跳过')
    exit()

active_plans = [d for d in os.listdir(active_dir) if os.path.isdir(os.path.join(active_dir, d)) and not d.startswith('.')]

if not active_plans:
    print('✅ active/ 目录为空（串行模式，正常状态）')
    exit()

# active/ 不为空，检查是否有 plan_path 引用
referenced = set()
try:
    tasks = json.load(open('docs/exec-plans/feature-list.json'))
    for t in tasks.get('tasks', []):
        pp = t.get('plan_path') or ''
        if 'active/' in pp:
            # 提取 active/ 后的第一段目录名
            parts = pp.split('active/')[-1].split('/')
            if parts:
                referenced.add(parts[0])
except:
    pass

today = datetime.date.today()
zombies = []
orphans = []

for plan_name in active_plans:
    plan_path = os.path.join(active_dir, plan_name)
    mtime = datetime.datetime.fromtimestamp(os.path.getmtime(plan_path)).date()
    days = (today - mtime).days
    if plan_name not in referenced:
        orphans.append(plan_name)
    elif days > 7:
        zombies.append({'name': plan_name, 'last_modified': mtime.isoformat(), 'days': days})

if orphans:
    print('⚠️  孤儿并行目录（active/ 中存在但无 plan_path 引用，可能是上次并行模式遗留）:')
    for o in orphans:
        print(f'   {o}')  

if zombies:
    print('⚠️  僵尸并行计划（有 plan_path 引用但超过 7 天未活动，建议归档）:')
    for z in zombies:
        print(f'   {z[\"name\"]}（上次修改：{z[\"last_modified\"]}，已{z[\"days\"]}天未活动）')

if not orphans and not zombies:
    print(f'✅ 当前 {len(active_plans)} 个并行计划，均有 plan_path 引用且近期活跃：{active_plans}')
"
```

**修复建议**：
- 孤儿目录：检查是否是上次并行模式结束后未清理。如任务已完成，移入 `docs/exec-plans/completed/`；如是误创建，直接删除
- 僵尸并行计划：调用 `iteration-close` 技能归档，或手动移入 `docs/exec-plans/completed/`
- 如果项目当前处于串行模式（所有 `plan_path` 为 null），`active/` 应清空为仅含 `.gitkeep`

---

## 执行顺序

收到巡检请求后，**依次执行全部 8 项检查**，然后输出综合报告。

---

## 输出格式：巡检报告

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🔍 Harness Watchdog 巡检报告
  时间：[执行时间]
  项目：[从 feature-list.json 读取的 project 字段]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CHECK-1 僵尸任务           [✅ 通过 / ⚠️ N 个问题]
CHECK-2 进度文件体积       [✅ 通过 / ⚠️ 需裁剪（XXX 行）]
CHECK-3 孤儿工单           [✅ 通过 / ⚠️ N 个孤儿]
CHECK-4 索引一致性         [✅ 通过 / ⚠️ N 个失效引用]
CHECK-5 验证命令           [✅ 通过 / ⚠️ N 个失效命令]
CHECK-6 文档体系完整性     [✅ 通过 / ⚠️ 缺少文件 / ℹ️ 骨架未初始化]
CHECK-7 caveats 一致性     [✅ 通过 / ⚠️ N 个模块未沉淀]
CHECK-8 exec-plan 僵尸计划 [✅ 通过 / ⚠️ N 个计划超期]

总计：[N] 项通过，[M] 项需要处理

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 修复建议（按优先级）：
1. [P0] ...
2. [P1] ...
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

所有发现问题后，**等待用户确认再执行修复**，绝不自动修改文件。

---

## progress 裁剪流程

当 CHECK-2 发现 progress.txt 过长时，执行以下裁剪逻辑（严格顺序）：

1. 读取 `docs/exec-plans/progress.txt` 全文
2. **Dead Ends 毕业（优先执行）**：将 `[Dead Ends]` 区块中所有条目追加到 `docs/caveats.md`（文件不存在则先创建骨架，骨架格式见 session-handoff 技能的 Step 3.5），然后从 progress.txt 清除 `[Dead Ends]` 区块
3. 提取所有 `[Key Decisions]` 区块，保留最近 3 条，旧条目追加到 `docs/CHANGELOG/CHANGELOG-[今日日期].md`
4. 重写 progress.txt，保留：最新 `[Current Focus]`、最新 `[Blockers & Solutions]`、最新 `[Next Steps]`、最近 3 条 `[Key Decisions]`
5. 更新 AGENTS.md 的「最后更新」字段（如有）

---

## 使用场景示例

- 每日站会前运行，确认 harness 健康
- 大型功能合并后运行，检查是否有遗留状态
- 新 Agent 接手工程前运行，验证交接条件满足
- 发现奇怪行为时运行，排除 harness 层面的问题
