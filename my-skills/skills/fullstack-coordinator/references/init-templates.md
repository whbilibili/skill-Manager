# 初始化文件模板

> 用于 fullstack-coordinator Mode 0（Init）创建全局协调层的三个文件。

---

## 1. cross-issues.json 初始骨架

```json
{
  "project": "{项目名称}",
  "updated_at": "{YYYY-MM-DD}",
  "transfers": []
}
```

### 创建逻辑

```python
import json, os
from datetime import date

def init_cross_issues(agents_dir, project_name):
    path = os.path.join(agents_dir, 'cross-issues.json')
    if os.path.exists(path):
        print(f"SKIP: {path} already exists")
        return
    data = {
        "project": project_name,
        "updated_at": str(date.today()),
        "transfers": []
    }
    with open(path, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"CREATED: {path}")
```

---

## 2. integration-status.json 初始骨架

```json
{
  "project": "{项目名称}",
  "updated_at": "{YYYY-MM-DD}",
  "endpoints": []
}
```

### 创建逻辑

```python
def init_integration_status(agents_dir, project_name):
    path = os.path.join(agents_dir, 'integration-status.json')
    if os.path.exists(path):
        print(f"SKIP: {path} already exists")
        return
    data = {
        "project": project_name,
        "updated_at": str(date.today()),
        "endpoints": []
    }
    with open(path, 'w') as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
    print(f"CREATED: {path}")
```

### 从 feature-list.json 预填接口

如果前端或后端工程已有 feature-list.json，可以从中提取接口信息预填 endpoints：

```python
def prefill_from_feature_list(agents_dir, fe_dir, be_dir):
    """从前后端的 feature-list.json 中提取接口，预填 integration-status.json"""
    status_path = os.path.join(agents_dir, 'integration-status.json')
    status_data = json.load(open(status_path))

    endpoints = {}

    # 从后端 feature-list.json 提取
    be_fl = find_harness_file(be_dir, 'feature-list.json')
    if be_fl:
        be_data = json.load(open(be_fl))
        for task in be_data.get('tasks', []):
            contracts = task.get('contracts', {})
            backend_api = contracts.get('backend_api', {})
            if isinstance(backend_api, dict):
                path = backend_api.get('path', '')
                method = backend_api.get('method', 'GET')
                if path:
                    key = f"{method} {path}"
                    endpoints[key] = {
                        "api_path": path,
                        "method": method,
                        "backend_status": "not_started",
                        "backend_task_id": task.get('id', ''),
                        "frontend_status": "mocked",
                        "frontend_task_id": "",
                        "mock_file": "",
                        "mock_cleanup_status": "active",
                        "contract_version": "v1.0",
                        "last_synced_at": str(date.today()),
                        "notes": ""
                    }

    # 从前端 feature-list.json 提取并补充
    fe_fl = find_harness_file(fe_dir, 'feature-list.json')
    if fe_fl:
        fe_data = json.load(open(fe_fl))
        for task in fe_data.get('tasks', []):
            contracts = task.get('contracts', {})
            api_consumption = contracts.get('api_consumption', [])
            if isinstance(api_consumption, list):
                for api in api_consumption:
                    path = api.get('endpoint', '')
                    method = api.get('method', 'GET')
                    if path:
                        key = f"{method} {path}"
                        if key in endpoints:
                            # 补充前端 task id 和 mock 文件
                            endpoints[key]["frontend_task_id"] = task.get('id', '')
                            mock_schema = contracts.get('mock_schema', {})
                            if isinstance(mock_schema, dict):
                                endpoints[key]["mock_file"] = mock_schema.get('file', '')
                        else:
                            # 前端有但后端没有的接口——可能后端还未拆解
                            endpoints[key] = {
                                "api_path": path,
                                "method": method,
                                "backend_status": "not_started",
                                "backend_task_id": "",
                                "frontend_status": "mocked",
                                "frontend_task_id": task.get('id', ''),
                                "mock_file": "",
                                "mock_cleanup_status": "active",
                                "contract_version": "v1.0",
                                "last_synced_at": str(date.today()),
                                "notes": "后端尚未拆解此接口"
                            }

    status_data["endpoints"] = list(endpoints.values())
    status_data["updated_at"] = str(date.today())

    with open(status_path, 'w') as f:
        json.dump(status_data, f, indent=2, ensure_ascii=False)
```

---

## 3. API-CONTRACT.md 初始骨架

详见 `references/api-contract-template.md` —— Mode 0 使用该模板生成 API-CONTRACT.md。

生成逻辑：

```python
def init_api_contract(agents_dir, project_name):
    path = os.path.join(agents_dir, 'API-CONTRACT.md')
    if os.path.exists(path):
        print(f"SKIP: {path} already exists")
        return

    # 尝试加载 fullstack-boundary-contract 的模板格式
    # 降级：使用内置模板
    template = f"""# API 接口契约 — {project_name}

> 本文件是前后端接口的唯一真相来源（Single Source of Truth）。
> 后端窗口负责维护接口定义和登记变更，前端窗口负责检查变更并同步。
> 全局版本：v1.0    最后更新：{date.today()}

---

## 一、接口清单

| # | Path | Method | 后端状态 | 前端状态 | 后端 Task | 前端 Task | 版本 |
|---|------|--------|----------|----------|-----------|-----------|------|
| - | - | - | - | - | - | - | - |

---

## 二、接口详情

> 逐个接口在此补充 Request / Response TypeScript interface。

---

## 三、变更记录

### v1.0 — {date.today()}
**变更接口**：全部接口
**变更内容**：初始版本
**变更原因**：项目初始化
**影响评估**：无
**BREAKING**：否

---

## 四、数据类型公共定义

> 多个接口复用的类型定义放在这里。
"""
    with open(path, 'w') as f:
        f.write(template)
    print(f"CREATED: {path}")
```

---

## 4. AGENTS.md 全栈协调区块

在 `.agents/AGENTS.md` 中追加的区块（如果文件不存在则创建）：

```markdown
## 全栈协调层

本项目采用前后端分离的双窗口开发模式，通过 `.agents/` 全局协调层进行跨工程协调。

### 协调文件说明

- **cross-issues.json**：跨工程缺陷流转。当一个窗口发现的 Bug 归属对方工程时，通过此文件转交。
- **API-CONTRACT.md**：前后端接口契约。后端负责维护接口定义，前端负责检查变更。
- **integration-status.json**：联调状态同步。跟踪每个接口的开发/联调/Mock 清理状态。

### 会话启动检查

每次在任一工程窗口启动新会话时，应检查：

1. cross-issues.json 中是否有待本工程拾取的缺陷转交
2. API-CONTRACT.md 中是否有影响本工程的 BREAKING 变更
3. integration-status.json 中是否有可以开始联调的接口

使用 `fullstack-coordinator` 技能来处理这些跨工程协调事项。
```

---

## 5. 完整初始化流程

```python
def init_coordination_layer(project_name):
    """完整的 Mode 0 初始化流程"""
    agents_dir = find_agents_dir()
    if agents_dir is None:
        # 需要创建
        agents_dir = create_agents_dir()  # 参考 SKILL.md Mode 0 Step 1

    os.makedirs(agents_dir, exist_ok=True)

    init_cross_issues(agents_dir, project_name)
    init_integration_status(agents_dir, project_name)
    init_api_contract(agents_dir, project_name)

    # 尝试从已有 feature-list.json 预填接口
    parent = os.path.dirname(agents_dir)
    fe_dir = find_frontend_dir(parent)
    be_dir = find_backend_dir(parent)
    if fe_dir or be_dir:
        prefill_from_feature_list(agents_dir, fe_dir, be_dir)

    # 更新 AGENTS.md
    update_agents_md(agents_dir)

    print(f"✅ 全栈协调层初始化完成: {agents_dir}")
```
