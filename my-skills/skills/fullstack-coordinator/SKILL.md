---
name: fullstack-coordinator
description: >-
  全栈协调器：前后端分离项目的跨工程协调中枢。在双窗口开发模式下维护全局协调层——
  跨工程缺陷流转（cross-issues.json）、接口契约变更治理（API-CONTRACT.md）、
  联调状态同步（integration-status.json）。解决"前端窗口发现的 Bug 其实是后端的"
  "接口改了前端不知道""联调时不知道后端接口是否就绪"三大痛点。
  当用户提到跨工程缺陷、缺陷转交、Bug 不是我这端的、接口契约、接口变更、
  API 变更通知、联调状态、联调对接、Mock 清理、前后端同步、全栈协调、
  初始化全栈项目、检查接口变更时必须使用。
  即使用户只是说"这个 Bug 应该是后端的问题"或"后端接口改了吗"也应触发本技能。
  不用于：单工程内部的缺陷分诊（用 issue-triage）、单工程的功能拆解（用 backend/frontend-architect）、
  需求阶段的前后端边界划分（用 fullstack-boundary-contract）、CI/CD 部署（用 fsd）。
metadata:
  version: "1.0.0"
  author: "wanghong52"
  skillhub.creator: "wanghong52"
  changelog: "初始版本：全栈协调器，含六大模式和三个协调文件"
---

# 全栈协调器（Fullstack Coordinator）

> **定位**：前后端分离双窗口开发模式下的"跨工程邮局"——不替代任何单工程技能，
> 只负责在两个独立窗口之间传递缺陷、同步契约、协调联调。
> 如同 issue-triage 是单工程内的缺陷入口，本技能是跨工程的缺陷路由器。

---

## 一、职责边界

### 本技能做什么

- 维护全局 `.agents/` 协调层的三个核心文件
- **跨工程缺陷流转**：将"归属对方工程"的 Bug 写入 cross-issues.json，对方窗口拾取
- **接口契约变更治理**：后端改接口时更新 API-CONTRACT.md 并留变更记录，前端窗口检查
- **联调状态同步**：跟踪每个接口的后端就绪 / 前端联调 / Mock 清理状态
- **全栈项目协调层初始化**：首次使用时生成 .agents/ 目录及三个协调文件骨架

### 本技能不做什么

- **不做单工程内的缺陷分诊**——根因分析是 issue-triage 的职责
- **不做需求阶段的边界划分**——那是 fullstack-boundary-contract 的职责
- **不修改任何工程内部的 harness 文件**——feature-list.json / progress.txt / ARCHITECTURE.md 由各工程自己的技能管理
- **不做 Git 分支管理**——分支策略由开发者自行决定

### 运行环境

本技能可在**任一窗口**中运行（前端窗口或后端窗口均可），它通过相对路径 `../.agents/` 访问全局协调层。前提是前后端工程位于同一父目录下：

```
my-project/           ← 父目录
├── .agents/          ← 全局协调层
├── frontend/         ← 前端窗口打开此目录
└── backend/          ← 后端窗口打开此目录
```

---

## 二、核心数据结构

### 2.1 cross-issues.json（跨工程缺陷流转）

路径：`../.agents/cross-issues.json`（相对于各工程根目录）

```json
{
  "project": "全栈项目名称",
  "updated_at": "YYYY-MM-DD",
  "transfers": [
    {
      "id": "XFER-001",
      "source_project": "frontend | backend",
      "source_issue_id": "BUG-003",
      "target_project": "backend | frontend",
      "target_issue_id": null,
      "summary": "简述缺陷及转交原因",
      "root_cause_hint": {
        "layer": "数据层 | 服务层 | 接口层 | 配置层 | 渲染层 | 状态层 | 网络层 | 构建层",
        "evidence": "具体证据（日志/截图/响应体）",
        "suggested_module": "建议排查的模块名"
      },
      "related_api": "/api/v1/users",
      "status": "pending_pickup | picked_up | resolved | rejected",
      "created_at": "YYYY-MM-DD",
      "picked_up_at": null,
      "resolved_at": null,
      "rejection_reason": null,
      "notes": ""
    }
  ]
}
```

**状态机**：
```
pending_pickup → picked_up → resolved
                           → rejected（附原因，退回源工程重新分析）
```

**关键规则**：
- `id` 格式：`XFER-{三位序号}`，全局递增
- `source_issue_id` 必须指向源工程 issues.json 中已存在的 issue
- `target_issue_id` 在对方拾取后回填（对方工程 issues.json 中新建的工单 id）
- `rejected` 状态必须附 `rejection_reason`，源工程需重新分析根因

### 2.2 API-CONTRACT.md（接口契约）

路径：`../.agents/API-CONTRACT.md`

这是前后端接口的唯一真相来源。后端窗口负责维护接口定义，前端窗口负责检查变更。

结构参考 → `references/api-contract-template.md`

核心区块：
- **接口清单表**：每个接口一行（path / method / 状态 / 后端负责 Task / 前端消费 Task / 版本号）
- **接口详情**：每个接口的 Request/Response TypeScript interface 定义
- **变更记录**：每次接口变更的版本号、日期、变更内容、变更人、影响的前端 Task

**版本控制规则**：
- 新增接口：minor 版本 +1（如 v1.2 → v1.3）
- 修改已有接口的 Response 字段：minor +1 + 在变更记录中标记 BREAKING
- 删除接口或 Required 字段：major +1（如 v1.3 → v2.0）

### 2.3 integration-status.json（联调状态同步）

路径：`../.agents/integration-status.json`

```json
{
  "project": "全栈项目名称",
  "updated_at": "YYYY-MM-DD",
  "endpoints": [
    {
      "api_path": "/api/v1/users",
      "method": "POST",
      "backend_status": "not_started | developing | deployed | verified",
      "backend_task_id": "USER-001",
      "frontend_status": "mocked | integrating | verified",
      "frontend_task_id": "FE-USER-001",
      "mock_file": "src/mocks/handlers/users.ts",
      "mock_cleanup_status": "active | pending_removal | deleted",
      "contract_version": "v1.2",
      "last_synced_at": "YYYY-MM-DD",
      "notes": ""
    }
  ]
}
```

**联调状态联动规则**：
```
后端 not_started → developing：前端继续用 Mock（mock_cleanup_status = active）
后端 developing → deployed：前端可开始联调（frontend_status → integrating）
后端 deployed → verified：后端自测通过，等待前端联调
前端 mocked → integrating：开始联调，Mock 标记为 pending_removal
前端 integrating → verified：联调通过，Mock 标记为 deleted，删除 Mock 文件
```

---

## 三、六大工作模式

进入技能后，根据用户意图判断模式。优先级：
**首次使用且无 .agents/ 目录？→ Mode 0** ；
**提到缺陷/Bug/转交？→ Mode 1/2** ；
**提到接口/契约/变更？→ Mode 3** ；
**提到联调/Mock？→ Mode 4** ；
**提到检查/同步？→ Mode 5**

---

### Mode 0：初始化全局协调层（Init）

**触发条件**：`.agents/` 目录不存在，或缺少核心协调文件
**触发词**："初始化全栈项目"、"创建协调层"

#### Step 1 — 检测项目结构

```python
import os
# 尝试找到全局 .agents/ 目录
# 从当前工作目录向上查找，最多 2 层
cwd = os.getcwd()
for parent in [os.path.join(cwd, '..'), os.path.join(cwd, '../..')]:
    agents_dir = os.path.join(parent, '.agents')
    if os.path.exists(agents_dir):
        print(f"FOUND {agents_dir}")
        break
else:
    # 检查当前目录是否有 frontend/ 和 backend/ 子目录
    if os.path.exists('frontend') and os.path.exists('backend'):
        agents_dir = os.path.join(cwd, '.agents')
        print(f"CREATE_HERE {agents_dir}")
    else:
        # 当前目录是某个子工程，在父目录创建
        agents_dir = os.path.join(cwd, '..', '.agents')
        print(f"CREATE_PARENT {agents_dir}")
```

#### Step 2 — 创建协调文件

在 `.agents/` 目录下创建三个文件的初始骨架（完整的初始化逻辑、文件模板和预填接口代码详见 `references/init-templates.md`）：
- `cross-issues.json`：`{"project": "项目名", "updated_at": "today", "transfers": []}`
- `integration-status.json`：`{"project": "项目名", "updated_at": "today", "endpoints": []}`
- `API-CONTRACT.md`：按 `references/api-contract-template.md` 生成骨架

如果前端或后端工程已有 feature-list.json，从中提取接口信息预填 integration-status.json 的 endpoints 数组（逻辑详见 `references/init-templates.md` 第 2 节）。

同时创建或更新 `AGENTS.md`，添加全栈协调说明区块（模板详见 `references/init-templates.md` 第 4 节）。

#### Step 3 — 输出确认

告知用户协调层已创建，说明三个文件的用途和两个窗口的使用方式。

---

### Mode 1：发起缺陷转交（Transfer Out）

**触发条件**：当前窗口发现的 Bug 根因不在本工程
**触发词**："这个 Bug 是后端/前端的"、"转交给后端/前端"、"缺陷转交"

#### Step 1 — 确认缺陷来源

检查当前工程的 `issues.json` 是否有该缺陷：
- 如果用户提到了具体 issue id → 直接读取
- 如果用户描述了新的 Bug → 先引用 **issue-triage** 在本地 issues.json 中创建工单并完成初步分析
- issue-triage 不可用 → 直接创建精简版工单（参考 test-architect 的降级模式）

#### Step 2 — 判断转交方向

如果 issue-triage 已完成根因分析，检查 `root_cause_analysis.most_likely`：
- 命中后端四层（数据层/服务层/接口层/配置层）且当前是前端工程 → 转交后端
- 命中前端四层（渲染层/状态层/网络层/构建层）且当前是后端工程 → 转交前端
- 无法判断 → 询问用户（最多 1 个问题）

如果用户直接指定了方向 → 跳过判断

#### Step 3 — 写入 cross-issues.json

```python
import json, os
from datetime import date

# 定位全局协调文件
agents_dir = find_agents_dir()  # 向上查找 .agents/
cross_path = os.path.join(agents_dir, 'cross-issues.json')

if os.path.exists(cross_path):
    data = json.load(open(cross_path))
else:
    data = {"project": "", "updated_at": "", "transfers": []}

# 计算下一个 XFER id
nums = [int(t["id"].split("-")[1]) for t in data["transfers"]
        if t["id"].startswith("XFER-")]
next_num = max(nums, default=0) + 1

new_transfer = {
    "id": f"XFER-{next_num:03d}",
    "source_project": current_project_type,  # "frontend" or "backend"
    "source_issue_id": issue_id,
    "target_project": target_project_type,
    "target_issue_id": None,
    "summary": summary,
    "root_cause_hint": {
        "layer": layer,
        "evidence": evidence,
        "suggested_module": module
    },
    "related_api": api_path_if_applicable,
    "status": "pending_pickup",
    "created_at": str(date.today()),
    "picked_up_at": None,
    "resolved_at": None,
    "rejection_reason": None,
    "notes": ""
}

data["transfers"].append(new_transfer)
data["updated_at"] = str(date.today())

with open(cross_path, 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
```

#### Step 4 — 更新源工程 issues.json

在源 issue 的 `notes` 字段追加：`"已转交至 {target_project}，转交单 {XFER-xxx}"`

#### Step 5 — 向用户确认

输出转交摘要，提醒用户在对方窗口中运行 Mode 2 拾取。

---

### Mode 2：拾取缺陷转交（Pick Up）

**触发条件**：当前窗口收到了来自对方工程的缺陷
**触发词**："拾取缺陷"、"检查转交"、"有没有转给我的 Bug"

也可在**每次会话启动时自动检查**——建议在各工程的 AGENTS.md 中加入启动检查指令：
`会话启动时，检查 ../.agents/cross-issues.json 是否有 target_project == 本工程 且 status == pending_pickup 的转交单`

#### Step 1 — 读取 cross-issues.json，筛选待拾取

```python
pending = [t for t in data["transfers"]
           if t["target_project"] == current_project_type
           and t["status"] == "pending_pickup"]
```

如果为空 → 告知用户"没有待处理的转交缺陷"

#### Step 2 — 逐条处理

对每条待拾取的转交单：

1. 展示 summary、root_cause_hint、related_api，让用户确认是否接受
2. **接受** → 引用 **issue-triage** 在本地 issues.json 中创建工单（将 root_cause_hint 作为初始线索）
   - issue-triage 不可用时 → 降级直接写入 issues.json
3. 回写 cross-issues.json：`target_issue_id = 新建的 issue id`，`status = "picked_up"`，`picked_up_at = today`
4. **拒绝** → 设置 `status = "rejected"`，填写 `rejection_reason`，源工程需重新分析

#### Step 3 — 更新当前工程的 progress.txt

如果 progress.txt 存在，在 `[Blockers & Solutions]` 或 `[Current Focus]` 中追加一行：
`收到跨工程缺陷转交 XFER-xxx: {summary}，已创建本地工单 BUG-xxx`

---

### Mode 3：接口契约变更（Contract Change）

**触发条件**：后端修改了接口，需要通知前端；或前端发现接口行为与契约不一致
**触发词**："接口改了"、"更新接口契约"、"API 变更"、"前端那边知道吗"

#### Step 3a — 后端窗口：登记变更

1. 用户描述接口变更（或 Agent 从 diff 中检测到接口变更）
2. 更新 `../.agents/API-CONTRACT.md` 中对应接口的定义
3. 在变更记录区块追加：

```markdown
### v{new_version} — {date}
**变更接口**：{method} {path}
**变更内容**：{具体字段变更}
**变更原因**：{原因}
**影响评估**：前端需更新 {前端 Task ID / 组件名}
**BREAKING**：{是/否}
```

4. 同步更新 `integration-status.json` 中该接口的 `contract_version`
5. 输出提醒：`前端窗口下次会话启动时会检查到此变更`

#### Step 3b — 前端窗口：检查变更

建议在前端工程的 AGENTS.md 中加入启动检查指令：

1. 读取 `../.agents/API-CONTRACT.md` 的变更记录
2. 与当前前端 feature-list.json 中的 `api_consumption` 对比
3. 如果发现不一致（response_shape 与 API-CONTRACT.md 中的 Response interface 不匹配）：
   - 输出变更详情
   - 建议更新前端的 api_consumption 和 mock_schema
   - 如果变更是 BREAKING → 在 progress.txt 的 `[Blockers & Solutions]` 中记录

---

### Mode 4：联调状态管理（Integration Sync）

**触发条件**：后端接口就绪需通知前端，或前端要清理 Mock 开始联调
**触发词**："接口已就绪"、"可以联调了"、"清理 Mock"、"联调状态"

#### Step 4a — 后端窗口：标记接口就绪

1. 确认接口已部署到测试环境并自测通过
2. 更新 `integration-status.json`：
   - `backend_status` → `"deployed"` 或 `"verified"`
   - `last_synced_at` → today
3. 输出提醒：`前端窗口可以开始联调，Mock 文件 {mock_file} 可标记为 pending_removal`

#### Step 4b — 前端窗口：开始联调

1. 读取 `integration-status.json`，找到 `backend_status` 为 `deployed` 或 `verified` 的接口
2. 对比 `frontend_status`——如果仍为 `mocked`，提示可以开始联调
3. 联调步骤：
   - 更新 `frontend_status` → `"integrating"`
   - 更新 `mock_cleanup_status` → `"pending_removal"`
   - 引用 **frontend-architect** 的 Mock 生命周期规范（如果可用）：
     在 feature-list.json 中对应 Task 的 `mock_schema.status` 也同步更新为 `"pending_removal"`
4. 联调通过后：
   - 删除 Mock 文件
   - 更新 `frontend_status` → `"verified"`
   - 更新 `mock_cleanup_status` → `"deleted"`
   - 在 `integration-status.json` 中标记 `last_synced_at`

#### Step 4c — 联调全景仪表盘

当用户问"联调进度怎么样了"，输出自然语言段落的联调状态总览：

> 当前项目共 N 个接口。后端已就绪 X 个（其中自测通过 Y 个），开发中 Z 个。
> 前端已联调通过 A 个，联调中 B 个，仍在使用 Mock C 个。
> 接下来建议优先联调 {api_path}（后端已 verified，前端仍 mocked）。

---

### Mode 5：全局健康检查（Health Check）

**触发条件**：定期检查或用户主动触发
**触发词**："检查全栈状态"、"协调层健康检查"、"全局检查"

#### 检查项

1. **缺陷转交超时**：`pending_pickup` 超过 3 天未拾取 → 告警
2. **契约不一致**：API-CONTRACT.md 的接口版本与 integration-status.json 中的 `contract_version` 不匹配 → 告警
3. **Mock 残留**：`backend_status` 已 `verified` 但 `mock_cleanup_status` 仍为 `active` → 提醒清理
4. **孤儿转交**：`source_issue_id` 在源工程 issues.json 中已 `resolved`，但 cross-issues.json 中仍为 `pending_pickup` → 提醒关闭
5. **联调阻塞**：`frontend_status` 为 `integrating` 超过 5 天 → 告警

#### 输出格式

自然语言段落描述检查结果，不用列表。如果一切正常，就说一切正常。
有问题时按严重程度排序描述，给出具体的修复建议。

---

## 四、缺陷归属速判规则

本技能内置缺陷归属判断逻辑，用于 Mode 1 的 Step 2：

```
判断链（按优先级执行，命中即停）：

1. 接口返回 HTTP 5xx → 后端（服务层/配置层）
2. 接口返回 HTTP 4xx 且请求参数符合契约 → 后端（接口层校验逻辑错误）
3. 接口返回 HTTP 4xx 且请求参数不符合契约 → 前端（网络层参数组装错误）
4. 接口返回正确但数据内容不符合 API-CONTRACT.md → 后端（数据层/服务层）
5. 接口返回正确且数据符合契约但页面渲染异常 → 前端（渲染层/状态层）
6. 接口超时或无响应 → 后端（服务层/配置层），除非网络层日志显示前端未发出请求
7. WebSocket 连接异常 → 先查后端推送服务，再查前端连接管理
8. 以上都无法判断 → 写入 cross-issues.json，status 设为 pending_pickup，notes 标记 "needs_joint_triage"
```

---

## 五、外部技能引用链

### 必要引用

**issue-triage**（Mode 1 创建源工单、Mode 2 创建目标工单）：
- 读取 `~/.catpaw/skills/issue-triage/SKILL.md` 或 `{workspace}/.catpaw/skills/issue-triage/SKILL.md`
- 成功 → 按完整分诊流程创建工单
- 失败 → 降级直接写入 issues.json（精简版）

### 可选引用

**fullstack-boundary-contract**（Mode 0 初始化时参考契约模板）：
- 成功 → 用其接口契约区块格式初始化 API-CONTRACT.md
- 失败 → 使用内置模板

**frontend-architect**（Mode 4 同步 Mock 状态）：
- 成功 → 按 Mock 生命周期规范同步 mock_schema.status
- 失败 → 只更新 integration-status.json，不触碰 feature-list.json

**backend-architect**（Mode 2 拾取后排期修复 Task）：
- 成功 → 按缺陷排期模式创建修复 Task
- 失败 → 只创建 issues.json 工单，排期由架构师后续处理

---

## 六、与各工程 AGENTS.md 的集成建议

建议在各工程的 AGENTS.md 中添加以下启动检查指令，实现"被动协调"：

```markdown
## 全栈协调（会话启动时检查）

1. 检查 ../.agents/cross-issues.json：
   - 是否有 target_project == "本工程" 且 status == "pending_pickup" 的转交单
   - 如有，提醒用户处理（可调用 fullstack-coordinator Mode 2）

2. 检查 ../.agents/API-CONTRACT.md：
   - 变更记录中是否有影响本工程且尚未处理的 BREAKING 变更
   - 如有，提醒用户更新对应的 api_consumption / backend_api

3. 检查 ../.agents/integration-status.json：
   - 是否有后端已 deployed/verified 但前端仍 mocked 的接口（前端窗口）
   - 是否有前端已 verified 但后端尚未标记的接口（后端窗口）
```

这样即使不主动调用本技能，每次会话启动时也能发现需要协调的事项。

---

## 七、文件路径发现机制

由于本技能可在任一窗口运行，需要动态定位全局 `.agents/` 目录和对方工程的目录。

### 定位 .agents/ 目录

```python
import os

def find_agents_dir():
    """从当前工作目录向上查找 .agents/ 目录，最多 3 层"""
    cwd = os.getcwd()
    for i in range(4):  # 当前目录 + 向上 3 层
        candidate = os.path.join(cwd, *(['..'] * i), '.agents')
        candidate = os.path.normpath(candidate)
        if os.path.isdir(candidate):
            return candidate
    return None
```

### 判断当前工程类型

```python
import json

def detect_project_type():
    """判断当前窗口是前端还是后端工程"""
    cwd = os.getcwd()
    dir_name = os.path.basename(cwd).lower()

    # 1. 目录名直接匹配
    if any(k in dir_name for k in ['frontend', 'fe', 'web', 'client', 'app']):
        return 'frontend'
    if any(k in dir_name for k in ['backend', 'be', 'server', 'api', 'service']):
        return 'backend'

    # 2. 特征文件检测
    if os.path.exists('package.json'):
        pkg = json.load(open('package.json'))
        deps = {**pkg.get('dependencies', {}), **pkg.get('devDependencies', {})}
        if any(k in deps for k in ['react', 'vue', 'next', 'nuxt', 'angular', '@angular/core']):
            return 'frontend'

    if any(os.path.exists(f) for f in ['pom.xml', 'go.mod', 'Cargo.toml', 'build.gradle']):
        return 'backend'

    if os.path.exists('requirements.txt') or os.path.exists('pyproject.toml'):
        # Python 可以是前端（如 Streamlit）或后端（如 FastAPI）
        return 'unknown'

    # 3. feature-list.json 特征字段检测
    fl_paths = ['docs/exec-plans/feature-list.json', 'harness/feature-list.json']
    for fl_path in fl_paths:
        if os.path.exists(fl_path):
            fl = json.load(open(fl_path))
            for task in fl.get('tasks', []):
                contracts = task.get('contracts', {})
                if 'api_consumption' in contracts or 'component_tree' in contracts:
                    return 'frontend'
                if 'database' in contracts or 'backend_api' in contracts:
                    return 'backend'

    return 'unknown'  # 需要询问用户
```

### 定位对方工程目录

```python
def find_peer_project(agents_dir, current_type):
    """从 .agents/ 的父目录中查找对方工程（确保返回的是对方类型的工程）"""
    parent = os.path.dirname(agents_dir)
    candidates = []
    for item in os.listdir(parent):
        item_path = os.path.join(parent, item)
        if not os.path.isdir(item_path) or item.startswith('.'):
            continue
        # 跳过当前工程目录
        if os.path.samefile(item_path, os.getcwd()):
            continue
        # 检查是否是一个工程（包含常见工程标识文件）
        is_project = any(
            os.path.exists(os.path.join(item_path, marker))
            for marker in ['package.json', 'pom.xml', 'go.mod', 'Cargo.toml',
                           'build.gradle', 'requirements.txt', 'pyproject.toml']
        )
        if is_project:
            candidates.append(item_path)

    # 如果已知当前工程类型，优先返回对方类型的工程
    if current_type in ('frontend', 'backend'):
        target_type = 'backend' if current_type == 'frontend' else 'frontend'
        for c in candidates:
            # 临时切换到候选目录检测类型
            saved_cwd = os.getcwd()
            try:
                os.chdir(c)
                peer_type = detect_project_type()
            finally:
                os.chdir(saved_cwd)
            if peer_type == target_type:
                return c

    # 无法确定类型时返回第一个候选
    return candidates[0] if candidates else None
```

### harness 路径适配

不同的 harness 初始化方式会产生不同的文件路径。本技能同时支持两种风格：

```python
# 风格 A：harness-project-init 创建的结构
#   {project}/harness/feature-list.json
#   {project}/harness/progress.txt

# 风格 B：frontend-architect / backend-architect 创建的结构
#   {project}/docs/exec-plans/feature-list.json
#   {project}/docs/exec-plans/progress.txt

def find_harness_file(project_dir, filename):
    """在两种 harness 路径中查找指定文件"""
    candidates = [
        os.path.join(project_dir, 'harness', filename),
        os.path.join(project_dir, 'docs', 'exec-plans', filename),
        os.path.join(project_dir, filename),  # 直接在根目录
    ]
    for c in candidates:
        if os.path.exists(c):
            return c
    return None
```

---

## 八、降级写入 issues.json

当 issue-triage 技能不可用时，Mode 1 / Mode 2 直接写入 issues.json 的精简模板：

```json
{
  "id": "BUG-{自增编号}",
  "title": "缺陷标题",
  "description": "缺陷描述",
  "reported_by": "{source_project}",
  "source": "fullstack-coordinator/{XFER-id}",
  "severity": "P0 | P1 | P2 | P3",
  "status": "open",
  "root_cause_analysis": {
    "most_likely": {
      "layer": "数据层 | 服务层 | 接口层 | 配置层 | 渲染层 | 状态层 | 网络层 | 构建层",
      "description": "从 cross-issues.json 的 root_cause_hint 中获取",
      "confidence": 0.6
    },
    "evidence": ["来自转交单的 evidence"]
  },
  "related_task_id": null,
  "impact": "对用户/功能的影响描述",
  "resolved_at": null,
  "notes": "由 fullstack-coordinator 从 {XFER-id} 创建"
}
```

该模板与 issue-triage 和 test-architect 的 issues.json schema 基本兼容——包含 `impact`、`resolved_at`、`notes` 三个关键字段。与 issue-triage 的差异在于：本模板使用 `description` 汇总描述（issue-triage 拆分为 `symptom`/`expected`/`reproduction`），`root_cause_analysis.most_likely` 为结构化对象（issue-triage 为字符串），`related_task_id` 为单值（issue-triage 的 `related_task_ids` 为数组）。这些差异不影响 JSON 解析和工单流转，目标工程拾取后可由 issue-triage 进行完整的二次分诊来补全信息。

> 💡 完整的降级模板字段说明和 ID 生成逻辑详见 `references/degraded-issue-template.md`。

---

## 九、与 test-architect 的协同

如果项目同时使用了 **test-architect** 技能进行测试：

**测试发现的跨工程缺陷**：test-architect 在 Mode 3（Execute）中发现测试失败并创建 issues.json 工单后，如果根因指向对方工程，可以调用本技能 Mode 1 发起跨工程转交。

**联调测试**：当 integration-status.json 中某接口的 `frontend_status` 和 `backend_status` 都达到 `verified`，可以作为 test-architect 的 test-plan.json 中联调用例的准入条件：

```
if endpoint.backend_status == "verified" and endpoint.frontend_status == "verified":
    # 该接口可以运行端到端联调测试
```

---

## 十、输出格式规范

所有模式的输出均遵循以下规范：

- **使用自然语言段落**描述操作结果，不使用项目列表
- **JSON 文件变更**：先输出"做了什么变更"（自然语言），再展示变更后的 JSON 片段
- **跨文件变更**：逐个文件说明，每个文件一个段落
- **提醒信息**：以 `> ⚠️` 或 `> 💡` 开头的引用块
- **不输出完整的大 JSON**——只展示变更/新增的部分