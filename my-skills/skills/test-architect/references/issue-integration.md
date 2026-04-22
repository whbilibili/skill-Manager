# 缺陷工单集成协议

本文档定义测试失败时如何与 issues.json 集成，包括引用 issue-triage 技能和降级方案。

---

## 触发条件

当测试用例的 result 为 `fail` 或 `error` 时，自动触发缺陷创建流程。

以下情况不触发：
- result 为 `skip`（主动跳过）
- result 为 `pending`（未执行）
- result 为 `pass`（通过）
- 已有 `created_issue_id`（已经创建过工单，避免重复）

---

## 方案一：引用 issue-triage 技能（推荐）

### Step 1 — 尝试读取技能

按优先级尝试读取：
1. `{workspace}/.catpaw/skills/issue-triage/SKILL.md`（项目级优先）
2. `~/.catpaw/skills/issue-triage/SKILL.md`（个人级）

### Step 2 — 组织输入信息

按 issue-triage 的输入要求，提供以下上下文：

```
缺陷描述：
- 测试套件 {suite_id}: {suite.title} 的用例 {case_id}: {case.title} 执行失败
- 测试类型: {suite.type}
- 测试优先级: {suite.priority}

现象：
- 预期: {case.expected_output}
- 实际: {case.actual_output}

复现步骤：
- 执行命令: {suite.verification_command}
- 或手动操作: {case.input 的描述}

影响范围：
- 模块: {suite.metadata.modules}
- 文件: {suite.metadata.files_affected}
- 关联 Task: {suite.related_task_ids}
```

### Step 3 — 调用 issue-triage

按 issue-triage 的流程执行，它会：
1. 在 issues.json 中创建工单
2. 进行根因分析（前端四层 / 后端四层）
3. 推进到 `analyzed_and_ready` 状态

### Step 4 — 回写关联

将 issue-triage 创建的 issue id 回写到：
- `test_case.created_issue_id`
- `test_suite.related_issue_ids[]`

---

## 方案二：降级直接写入 issues.json

当 issue-triage 技能不可用时使用此方案。

### Step 1 — 确认 issues.json 存在

```python
import json, os

issues_path = "docs/exec-plans/issues.json"
if os.path.exists(issues_path):
    data = json.load(open(issues_path))
else:
    # 创建初始结构
    data = {"project": project_name, "issues": []}
```

### Step 2 — 计算下一个 issue id

```python
existing_ids = [i["id"] for i in data["issues"]]
# 提取所有 BUG-xxx 的数字部分
nums = [int(id.split("-")[1]) for id in existing_ids
        if id.startswith("BUG-") and id.split("-")[1].isdigit()]
next_num = max(nums, default=0) + 1
new_id = f"BUG-{next_num:03d}"
```

### Step 3 — 创建精简版工单

```json
{
  "id": "{new_id}",
  "title": "测试失败: {case.title}",
  "status": "analyzing",
  "severity": "{suite.priority}",
  "reported_at": "{today YYYY-MM-DD}",
  "reported_by": "test-architect",
  "symptom": "预期: {case.expected_output}, 实际: {case.actual_output}",
  "expected": "{case.expected_output 的 JSON 字符串}",
  "reproduction": "执行 {suite.verification_command} 或按输入 {case.input} 手动操作",
  "impact": "影响模块 {suite.metadata.modules}，关联功能 {suite.related_task_ids}",
  "root_cause_analysis": {
    "candidates": [],
    "most_likely": "待 issue-triage 深度分析",
    "evidence": "{case.failure_reason 或 actual_output}",
    "fix_direction": "待分析"
  },
  "affected_modules": ["{suite.metadata.modules 的元素}"],
  "related_task_ids": ["{suite.related_task_ids 的元素}"],
  "resolved_at": null,
  "notes": "由 test-architect 自动创建（降级模式，未经 issue-triage 深度分析）"
}
```

### Step 4 — 写入并回写关联

```python
data["issues"].append(new_issue)
with open(issues_path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

# 回写到 test-plan.json
case["created_issue_id"] = new_id
suite["related_issue_ids"].append(new_id)
```

---

## 去重规则

同一个测试用例多次执行失败时，不应重复创建工单：

1. 执行前检查 `case.created_issue_id` 是否已有值
2. 如果已有值，检查 issues.json 中该 issue 的状态：
   - `analyzing` / `analyzed_and_ready` → 不创建新工单，在 notes 中追加"复现确认"
   - `promoted_to_task` → 不创建新工单（已排期修复中）
   - `resolved` → 创建新工单（回归失败，标记为 regression failure）
   - `wont_fix` → 不创建新工单，标记 case 为 skip

---

## 严重程度继承规则

测试用例创建的缺陷工单的 severity 继承自 test suite 的 priority，但可升级：

| 测试 priority | 默认 severity | 升级条件 |
|--------------|--------------|---------|
| P0 | P0 | — |
| P1 | P1 | 数据丢失/安全漏洞 → 升级为 P0 |
| P2 | P2 | 影响核心流程 → 升级为 P1 |
| P3 | P3 | — |

升级判断依据：
- actual_output 中出现 500 / Internal Server Error → 至少 P1
- actual_output 中出现数据不一致（增删改后查询不到/查到脏数据）→ P0
- 安全相关测试（注入、越权）失败 → P0
