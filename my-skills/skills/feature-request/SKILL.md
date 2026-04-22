---
name: feature-request
description: >-
  增量需求架构师。将用户的新功能想法安全地追加到现有 feature-list.json，评估对已有任务的冲击，
  输出可直接交给 Coding Worker 执行的新 Task。
  当用户说"新增功能"、"加个需求"、"需求变更"、"产品要加一个"、"追加任务"、
  "有个新功能"、"改一下需求"、"需求有变化"、"新迭代需求"时必须使用本技能。
  只做增量追加和影响评估，不重新规划整个项目。
metadata:
  version: "2.1.0"
  author: "wanghong52"
  changelog: "v2.1.0 — 修复旧路径引用（.ai/state/ → docs/exec-plans/）；AGENT.md → AGENTS.md"
---

# Feature Request Skill

## 职责

将用户的新功能想法，安全地追加到现有 `feature-list.json` 中，同时评估它对已有任务的冲击，最终输出可以直接交给 Coding Worker 执行的新 Task。

**只做追加，不重新规划整个项目。**

---

## 执行流程

### Step 1：读取现场信息

首先静默读取以下文件，全面了解现有状态：

```bash
cat docs/exec-plans/feature-list.json          # 现有任务清单
cat docs/exec-plans/progress.txt 2>/dev/null   # 当前进度
cat AGENTS.md 2>/dev/null                       # 代码地图（架构约束红线）
cat ARCHITECTURE.md 2>/dev/null                 # 架构约束全集
cat docs/exec-plans/issues.json 2>/dev/null    # 现有缺陷（判断新需求是否和已有 Bug 关联）
```

读完后，输出现状摘要：

```
📊 现状摘要：
   - 总任务数：X 个（completed: X / in_progress: X / pending: X）
   - 当前正在执行：[Task ID] [描述]
   - 架构约束红线：[从 AGENTS.md / ARCHITECTURE.md 读取最重要的 2-3 条]
```

---

### Step 2：理解新需求

从用户描述中明确以下信息（能推断的就不问，**最多追问 2 个关键问题**）：

| 要素 | 说明 | 如果缺失 |
|------|------|----------|
| **功能描述** | 这个功能做什么，解决什么问题 | 必须追问 |
| **用户视角** | 用户会怎么触发/使用这个功能 | 尽量推断 |
| **优先级** | 这个迭代必须做，还是下个版本 | 默认「当前迭代」 |
| **技术方向** | 用户是否有倾向的实现方式 | 尊重用户意见，否则架构师决定 |

---

### Step 3：影响评估（关键步骤）

在生成新 Task 之前，必须评估新需求对现有任务清单的冲击：

#### 3-A：冲突检测

**① 文件冲突**：新需求涉及的文件，是否有其他 `in_progress` 或 `pending` 的 Task 也在修改？
→ 如果有，标注「⚠️ 文件竞争」，建议调整执行顺序

**② 接口冲突**：新需求是否会修改已有 API 的 `request_body` 或 `response` 结构？
→ 如果有，标注「⚠️ 接口破坏性变更」，必须同步更新相关 Task 的契约定义

**③ 状态冲突**（前端）：新需求是否需要修改已有 Zustand / Pinia Store 的结构？
→ 如果有，标注「⚠️ Store 结构变更」，列出所有依赖该 Store 的 Task

**④ 依赖顺序冲突**：新 Task 是否依赖某个还未完成的 Task？
→ 如果有，标注「⏳ 依赖 [Task ID]」，必须等待依赖 Task 完成后才能开始

**⑤ 架构约束冲突**：新需求是否违反 `ARCHITECTURE.md` 中的分层约束或标识体系规范？
→ 如果有，必须在用户确认调整方案后再继续，**不允许为了快速追加而妥协架构**

#### 3-B：输出影响报告

```
🔍 影响评估：

  ✅ 无冲突：可直接追加
  ⚠️ 发现冲突：
     - [冲突类型]：[具体说明]
     - 建议处理方式：[调整执行顺序 / 先修改已有 Task 的 contracts / 人工确认]
```

如果有破坏性冲突，**在用户确认处理方式后再继续**，不要强行追加。

---

### Step 4：拆解新 Task

**自动判断工程类型**：
- 现有任务含 `contracts.component_tree` 或 `contracts.api_consumption` → **前端工程**
- 含 `contracts.database` 或 `contracts.backend_api` → **后端工程**
- 都有 → **全栈工程**，拆成两个独立 Task（后端 Task 优先级高于前端）

**Task ID 命名规则**：从现有任务中识别模块前缀（如 `AUTH-`、`USER-`、`ORDER-`），新功能归属哪个模块就用哪个前缀，序号在该模块最大值上 +1。如果是全新模块，与用户确认前缀。

**拆解粒度要求**：
- 每个 Task 是一个**原子垂直切片**（一个完整用户操作路径）
- `files_affected` 必须精确到**具体文件名**，不允许写目录
- `verification.auto` 必须是可直接执行的命令（typecheck / curl / go test）
- 前端 Task 的 `api_consumption` 必须配套 `mock_schema`（含 `removal_condition`）

生成的新 Task 格式（沿用项目已有的 feature-list Schema）：

```json
{
  "task_id": "[MODULE-XXX]",
  "description": "[垂直切片描述，精确到具体组件/接口/方法]",
  "priority": "[1-High / 2-Medium / 3-Low]",
  "status": "pending",
  "contracts": {
    // 根据工程类型填写对应字段（参照 feature-list.json 中已有 Task 的结构）
  },
  "verification": {
    "auto": "[可直接执行的验证命令]",
    "manual": "[需人工确认的视觉验证（前端专有）]"
  },
  "metadata": {
    "files_affected": ["[精确到文件名的路径列表]"],
    "modules": ["[关联模块]"],
    "source_issue_id": null,
    "depends_on": ["[依赖的 Task ID，如有]"]
  },
  "acceptance_criteria": [
    "[可被机器验证的业务验收条件]"
  ]
}
```

---

### Step 5：更新 feature-list.json + progress.txt

将新 Task 追加到 `feature-list.json` 的 `tasks` 数组中，**根据优先级插入正确位置**（高优先级排在低优先级的 pending 任务前面）。

同时在 `progress.txt` 的 `[Key Decisions]` 追加一条记录：

```
[YYYY-MM-DD] 新增需求：[Task ID] [一句话说明功能和追加原因]
```

如果追加导致 progress.txt 超过 200 行，提醒用户使用 `session-handoff` 技能进行裁剪。

---

### Step 6：输出变更摘要

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  ✨ 需求已追加到任务清单
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 新增 Task：[Task ID] [描述]
📂 影响文件：[files_affected 列表]
🔗 依赖关系：[depends_on，如有]
📊 当前队列：[pending 任务数] 个待执行

[如有冲突处理结果，在这里说明]

📌 下一步：
   激活「Coding Worker v2」command 继续执行
   → Agent 会自动读取任务清单，按优先级执行

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## 注意事项

- **只做追加，不重新规划**：不修改已有 Task 的内容，除非影响评估发现必须调整
- **优先级排序是责任**：新需求插入队列的位置直接决定 Coding Worker 下次执行什么，必须认真判断
- **files_affected 精确到文件**：这是 Coding Worker 新 Session 快速定位代码的唯一依据，写不准确等于给下一个 Agent 挖坑
- **架构约束不可绕过**：如果新需求违反 `ARCHITECTURE.md` 中的架构约束（如直接在 page 里调用 api），必须指出并要求调整方案，不能为了快速追加而妥协架构
- **全栈功能拆成两个 Task**：前端 Task 和后端 Task 分开，后端 Task 优先级高于前端（接口先行）
- **关联已有 Bug**：如果新需求是为了修复某个 `issues.json` 中的问题，填入 `metadata.source_issue_id`
