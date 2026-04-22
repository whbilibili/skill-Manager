---
name: issue-triage
description: >-
  缺陷分诊工具：将用户描述的 Bug 或异常转化为 issues.json 中的结构化工单，完成根因分析后推进到
  analyzed_and_ready 状态，供架构师排期。同时支持前端（渲染层/状态层/网络层/构建层）和后端
  （数据层/服务层/接口层/配置层）的根因分析。这是缺陷从"发现"到"排期"的必经入口。
  当用户提到发现 bug、接口异常、报错了、功能不符合预期、页面白屏、组件不渲染、接口返回 null、
  状态没更新、帮我记录这个问题时必须使用。即使用户只是说"这里好像不对"或"数据怎么是空的"，
  只要在描述一个可能的缺陷现象，都应触发本技能。
  不适用于：代码质量审查（使用 coding-reviewer，它审查代码变更而非运行时缺陷）、
  缺陷排期和任务规划（使用 backend/frontend-architect 的缺陷排期模式，本技能只做分诊不做排期）、
  文档不一致问题（使用 doc-sync）、harness 状态异常（使用 harness-watchdog）。
metadata:
  version: "2.1.0"
  author: "wanghong52"
  changelog: "v2.1.0 — 修复旧路径引用（.ai/state/ → docs/exec-plans/）；对齐 v2.0.0 目录体系"
---

# Issue Triage Skill

## 职责

将用户描述的 Bug、接口异常或功能偏差，转化为 `issues.json` 中的结构化工单，并完成初步根因分析，使工单达到「可排期」状态。

**这是缺陷从「发现」到「排期」之间的必经入口**，保证每一个 Bug 都有明确的根因分析，而不是让 Coding Agent 在没有方向的情况下瞎改。

---

## 工单生命周期

```
用户描述 Bug
    ↓
issue-triage 写入 issues.json（status: analyzing）
    ↓
根因分析（确定模块、字段、SQL 或逻辑错误）
    ↓
issues.json（status: analyzed_and_ready）
    ↓
架构师调用 backend-architect 排期
    ↓
issues.json（status: promoted_to_task）+ feature-list.json 新增 Task
    ↓
Coding Agent 执行修复
    ↓
issues.json（status: resolved）
```

---

## 执行流程

### Step 1：收集缺陷信息

从用户描述中提取或追问以下要素（尽量从对话中推断，减少用户负担）：

| 要素 | 说明 | 示例 |
|------|------|------|
| **现象** | 用户看到了什么 | 「接口返回 null」「total 始终为 0」 |
| **期望** | 用户期望看到什么 | 「应该返回头像 URL」 |
| **复现步骤** | 如何触发该问题 | 「调用 /list 接口时传入 createMis=xxx」 |
| **影响范围** | 是所有用户还是特定条件 | 「所有有头像的用户」 |
| **触发时间** | 何时开始出现 | 「今天合并后」 |

如果用户描述不完整，**最多追问 2 个最关键的问题**，然后用「待确认」填充其余字段，不要让用户填写表单。

### Step 2：初步根因分析

首先，**自动判断工程类型**：

- 如果 `docs/exec-plans/feature-list.json` 中存在 `contracts.api_consumption` 或 `contracts.component_tree` 字段 → **前端工程**
- 如果存在 `contracts.database` 或 `contracts.backend_api` 字段 → **后端工程**
- 如果无法判断，检查工程根目录是否有 `package.json` 且含 `react/vue/next` → **前端工程**
- 默认回退到**后端分析维度**

根据工程类型，采用对应的分析维度：

---

#### 前端工程根因分析维度

1. **渲染层**：组件未正确渲染？React re-render 过多？虚拟 DOM diff 异常？条件渲染逻辑错误？`key` 属性缺失导致列表状态错误？
2. **状态层**：Zustand/Redux Store 状态污染？selector 返回新对象引发无限渲染（需 `shallow` 比较）？`useEffect` 依赖数组遗漏导致闭包过期或无限循环？React Query 缓存未失效？
3. **网络层**：MSW Mock handler 未清理导致真实接口被拦截？请求竞态（Race Condition）？CORS 配置错误？API 响应字段与 `response_shape` 不一致？
4. **构建层**：环境变量 `VITE_` / `NEXT_PUBLIC_` 前缀错误？`tsconfig.json` 路径别名配置错误？Tree-shaking 导致模块缺失？CSS Module 类名哈希冲突？

**前端验证方法**：执行 `npm run typecheck`、打开浏览器 DevTools 查看 Console/Network、检查 React DevTools 渲染次数

---

#### 后端工程根因分析维度

1. **数据层**：SQL 条件错误？字段映射错误？JOIN 逻辑有问题？索引未命中？
2. **服务层**：标识体系混用（如 MIS 号 vs userId）？NPE？缓存穿透？事务边界不正确？
3. **接口层**：DTO/VO 字段遗漏？序列化问题？权限校验缺失？
4. **环境/配置**：驱动版本兼容？枚举值不一致？配置中心未同步？

**后端验证方法**：执行对应 `curl` 命令或 SQL 查询验证

---

分析后给出：
- **可能根因**（1-3 个候选）
- **确认根因的方法**（执行什么命令/查询可以验证）
- **修复方向**（大致方案，不是完整实现）

### Step 3：写入 issues.json

如果 `docs/exec-plans/issues.json` 不存在，先初始化：

```json
{
  "project": "[从 feature-list.json 读取]",
  "issues": []
}
```

然后追加新工单：

```json
{
  "id": "BUG-[三位序号，如 BUG-001]",
  "title": "[简短标题，动词开头，如：容器列表 createMisAvatar 字段始终为 null]",
  "status": "analyzing",
  "severity": "[P0/P1/P2/P3]",
  "reported_at": "[今日日期 YYYY-MM-DD]",
  "reported_by": "user",
  "symptom": "[现象描述]",
  "expected": "[期望行为]",
  "reproduction": "[复现步骤]",
  "impact": "[影响范围]",
  "root_cause_analysis": {
    "candidates": ["[候选根因 1]", "[候选根因 2]"],
    "most_likely": "[最可能的根因]",
    "evidence": "[支撑证据或验证命令]",
    "fix_direction": "[修复方向]"
  },
  "affected_modules": ["[模块名]"],
  "related_task_ids": [],
  "notes": ""
}
```

写入后立即将 status 更新为 `"analyzed_and_ready"`（如果根因分析已充分）或 `"analyzing"`（如果需要更多信息）。

### Step 4：严重性评级

| 级别 | 标准 | 示例 |
|------|------|------|
| **P0** | 核心功能完全不可用，影响所有用户 | 服务启动失败、核心接口 500 |
| **P1** | 核心功能受损，影响大部分用户 | 列表接口数据错误、鉴权失效 |
| **P2** | 功能降级，有可接受的 Workaround | 某字段为 null 但不影响主流程 |
| **P3** | 体验问题或优化项 | 字段格式不统一、日志缺失 |

### Step 4.5：规律性踩坑沉淀（选择性执行）

**执行条件**：满足以下任意一条时，将本次 Bug 根因追加到 `docs/caveats.md`：
1. 同一模块/文件在 `issues.json` 中已出现过相同现象（第 2 次及以上）
2. 根因分析指向**架构约束违反**（如跨层调用、标识体系混用、Mock 未清理等）
3. 根因属于框架级陷阱（`useEffect` 依赖数组、Zustand selector、MSW 未初始化等）

**执行步骤**：

```bash
# 检查同模块历史记录
python3 -c "
import json, os, sys
if not os.path.exists('docs/exec-plans/issues.json'):
    sys.exit(0)
issues = json.load(open('docs/exec-plans/issues.json'))
current_modules = [模块名列表]  # 从本次 Bug 的 affected_modules 获取
related = [i for i in issues.get('issues', [])
           if any(m in i.get('affected_modules', []) for m in current_modules)
           and i['status'] != 'resolved']
print(f'同模块历史缺陷数（含本次）: {len(related)}')
"
```

如果满足条件，追加到 `docs/caveats.md`（文件不存在则创建，骨架格式见 session-handoff 技能的 Step 3.5）：

```
| [今日日期] | [现象描述，一句话] | [根因，精确到模块或函数] | [预防方法] | 活跃 / 关联 [BUG-XXX] |
```

> 📌 写入后在工单的 `notes` 字段追加：`"已归档至 docs/caveats.md"`，避免重复写入。

---

### Step 5：输出工单摘要

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🐛 缺陷工单已创建：[BUG-XXX]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 标题：[标题]
🔴 严重性：[P0/P1/P2/P3]
📊 状态：analyzed_and_ready（可排期）

🔍 根因分析：
   最可能：[最可能根因]
   修复方向：[修复方向]
   验证命令：[验证根因的命令]

📌 下一步：
   告知架构师安排排期
   → 后端工程：使用 backend-architect 技能的缺陷排期模式
   → 前端工程：使用 frontend-architect 技能的缺陷排期模式

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## issues.json 完整 Schema

```json
{
  "project": "string",
  "issues": [
    {
      "id": "BUG-001",
      "title": "string（动词开头）",
      "status": "analyzing | analyzed_and_ready | promoted_to_task | resolved | wont_fix",
      "severity": "P0 | P1 | P2 | P3",
      "reported_at": "YYYY-MM-DD",
      "reported_by": "string",
      "symptom": "string（现象）",
      "expected": "string（期望）",
      "reproduction": "string（复现步骤）",
      "impact": "string（影响范围）",
      "root_cause_analysis": {
        "candidates": ["string"],
        "most_likely": "string",
        "evidence": "string（验证命令或日志）",
        "fix_direction": "string"
      },
      "affected_modules": ["string"],
      "related_task_ids": ["string（排期后填入）"],
      "resolved_at": "YYYY-MM-DD（解决后填入）",
      "notes": "string（补充说明）"
    }
  ]
}
```

---

## 注意事项

- **不要自动修复**：issue-triage 只负责分析和记录，不修改业务代码
- **根因优先于现象**：工单价值在于根因分析，现象描述只是触发点
- **BUG ID 连续**：新工单 ID 从现有最大 ID + 1 递增，保持全局唯一
- **caveats.md 优先**：如果 `docs/caveats.md` 中已有相同现象的记录，直接引用而不是重复分析
- **前端 Mock 残留快速判断**：如果现象是「接口返回的数据是假数据」或「真实接口没有被调用」，第一优先级检查 `src/mocks/handlers/` 中是否有未清理的 handler 文件，这是前端最高频的 P2 级缺陷
- **前端无限渲染快速判断**：如果现象是「页面卡死」或「请求被连续发送 N 次」，第一优先级检查 `useEffect` 依赖数组和 Zustand selector 是否缺少 `shallow` 比较
