---
name: harness-project-init
description: "初始化 Harness 工程项目骨架。用于快速搭建前后端分离项目的完整 Harness 文档体系，包括全局文档、工程文档、会话文档和维护规则。当用户提到'初始化 harness'、'搭建 harness'、'harness 项目初始化'、'创建 harness 工程'、'harness 脚手架'、'harness 骨架'时使用。支持前端和后端工程，自动生成 feature-list.json、progress.txt、ARCHITECTURE.md 等完整文档体系。"
version: 2.1.0
compatibility:
  - tools: ["read_file", "write", "run_terminal_cmd", "AskQuestion"]
  - requires: "bash, jq (optional)"
---

# Harness 工程初始化技能

> 快速搭建前后端分离项目的完整 Harness 文档体系

## 功能概述

这个技能帮助你快速初始化一个 Harness 工程项目，包括：

- ✅ 全局文档体系（AGENTS.md、API-CONTRACT.md 等）
- ✅ 工程级文档（feature-list.json、progress.txt、ARCHITECTURE.md 等）
- ✅ progress.txt 采用交接棒式格式（`### [Current Focus]` / `### [Key Decisions]` / `### [Next Steps]` 等），兼容 session-handoff、harness-watchdog 等 7 个下游 skill
- ✅ serial 模式为默认（全局 feature-list.json + progress.txt）；parallel 模式按需启用（active/[task-name]/）
- ✅ 同步检查点（防止文档-代码脱节）
- ✅ 维护规则和检查清单

## 使用场景

### 场景 1：新建前后端分离项目

```
用户：我要开始一个新项目，需要初始化 harness
Agent：
1. 询问项目名称、类型（前端/后端/全栈）
2. 询问项目目录结构
3. 生成完整的 harness 文档体系
4. 输出初始化完成报告
```

### 场景 2：为现有项目补充 harness 文档

```
用户：我的项目已经有代码了，现在要加 harness 文档
Agent：
1. 扫描现有项目结构
2. 生成对应的 harness 文档
3. 帮助同步代码和文档
```

### 场景 3：初始化多个工程（前端 + 后端）

```
用户：我要初始化一个前后端分离的项目
Agent：
1. 创建全局 harness 文档（A/.agents/）
2. 初始化前端工程 harness（B/harness/）
3. 初始化后端工程 harness（C/harness/）
4. 生成完整的项目骨架
```

## 工作流程

```
用户请求
  ↓
收集项目信息（名称、类型、目录结构）
  ↓
生成全局文档（如果是多工程项目）
  ↓
生成工程级文档
  ↓
生成会话文档模板
  ↓
生成同步检查点
  ↓
输出初始化报告
```

## 输入参数

### 必需参数

| 参数 | 类型 | 说明 |
|------|------|------|
| `project_name` | string | 项目名称（e.g., "my-app"） |
| `project_type` | enum | 项目类型：frontend / backend / fullstack |
| `root_dir` | string | 项目根目录路径 |

### 可选参数

| 参数 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `include_global_docs` | boolean | true | 是否生成全局文档 |
| `include_examples` | boolean | true | 是否包含示例任务 |
| `tech_stack` | string | "" | 技术栈描述（e.g., "React 18 + TypeScript"） |
| `team_size` | number | 1 | 团队规模 |

## 输出结构

### 全局文档（A/.agents/）

```
A/
├── AGENTS.md                 # 全局路由索引
├── PLANS.md                  # 全局计划
├── docs/
│   ├── API-CONTRACT.md       # 前后端接口契约
│   ├── DEPLOYMENT.md         # 部署流程
│   └── SECURITY.md           # 安全规则
└── .gitignore
```

### 工程文档（B/harness/ 或 C/harness/）

```
B/harness/
├── feature-list.json         # 任务清单
├── progress.txt              # 进度记录
├── ARCHITECTURE.md           # 架构文档
├── docs/
│   ├── caveats.md            # 踩坑档案
│   ├── tech-debt.md          # 技术债清单
│   └── CHANGELOG.md          # 变更日志
├── memory/
│   └── MEMORY.md             # 长期记忆
└── .gitignore
```

### 同步检查点

```
B/.sync-state.json            # 同步检查点
```

## 命令行用法

```bash
# 初始化前端工程
harness-project-init \
  --project-name "my-app" \
  --project-type "frontend" \
  --root-dir "./frontend"

# 初始化后端工程
harness-project-init \
  --project-name "my-api" \
  --project-type "backend" \
  --root-dir "./backend" \
  --tech-stack "Node.js + Express"

# 初始化全栈项目
harness-project-init \
  --project-name "my-fullstack" \
  --project-type "fullstack" \
  --root-dir "." \
  --include-global-docs true
```

## 示例

### 示例 1：初始化前端工程

```bash
harness-project-init \
  --project-name "frontend" \
  --project-type "frontend" \
  --root-dir "./frontend" \
  --tech-stack "React 18 + TypeScript + Redux"
```

**输出**：
```
✅ Harness 文档体系初始化完成！

📂 目录结构：
frontend/harness/
├── feature-list.json (10 个示例任务)
├── progress.txt (初始进度记录)
├── ARCHITECTURE.md (架构模板)
├── docs/
│   ├── caveats.md (踩坑档案)
│   ├── tech-debt.md (技术债清单)
│   └── CHANGELOG.md (变更日志)
└── memory/
    └── MEMORY.md (长期记忆)

📋 下一步：
1. 编辑 feature-list.json，添加实际任务
2. 编辑 ARCHITECTURE.md，描述项目架构
3. 开始编码，每个会话结束时运行 session-handoff
```

### 示例 2：初始化全栈项目

```bash
harness-project-init \
  --project-name "my-app" \
  --project-type "fullstack" \
  --root-dir "."
```

**输出**：
```
✅ Harness 文档体系初始化完成！

📂 全局文档：
./.agents/
├── AGENTS.md (全局路由索引)
├── PLANS.md (全局计划)
└── docs/
    ├── API-CONTRACT.md (接口契约)
    ├── DEPLOYMENT.md (部署流程)
    └── SECURITY.md (安全规则)

📂 前端工程：
./frontend/harness/
├── feature-list.json
├── progress.txt
├── ARCHITECTURE.md
└── ...

📂 后端工程：
./backend/harness/
├── feature-list.json
├── progress.txt
├── ARCHITECTURE.md
└── ...

📋 下一步：
1. 编辑 .agents/AGENTS.md，更新工程导航
2. 编辑 .agents/docs/API-CONTRACT.md，定义接口
3. 分别初始化前后端工程
```

## 最佳实践

### 1. 项目初始化顺序

```
1. 创建项目根目录
2. 运行 harness-project-init 初始化文档体系
3. 创建代码仓库（git init）
4. 配置 .gitignore（防止 harness 文档进入公共仓库）
5. 开始编码
```

### 2. 多工程协作

```
A/（项目根目录）
├── .agents/（全局 harness 文档）
├── frontend/（前端工程）
│   ├── harness/（前端 harness 文档）
│   └── code-repo/（前端代码仓库）
└── backend/（后端工程）
    ├── harness/（后端 harness 文档）
    └── code-repo/（后端代码仓库）
```

### 3. 防止文档污染

在 `code-repo/.gitignore` 中添加：
```gitignore
../harness/
../.sync-state.json
```

### 4. 定期维护

- **每个会话结束**：运行 `session-handoff`
- **每周一次**：运行 `harness-watchdog` 进行健康巡检
- **每月一次**：执行知识蒸馏（memory/YYYY-MM-DD.md → memory/MEMORY.md）

## 常见问题

### Q1：harness 文档应该放在代码仓库中吗？

**A**：不应该。harness 文档是本地分支开发的工作记录，不应该进入公共仓库。建议：
- 将 harness 文档放在项目根目录下的独立目录
- 在代码仓库的 .gitignore 中排除 harness 文档
- 使用 .sync-state.json 防止文档-代码脱节

### Q2：如何处理多个工程的协作？

**A**：使用全局 AGENTS.md 作为导航索引：
- 全局 AGENTS.md 指向所有工程的 harness 文档
- 每个工程有独立的 feature-list.json 和 progress.txt
- 通过 API-CONTRACT.md 定义前后端接口

### Q3：如何迁移现有项目到 harness？

**A**：
1. 运行 `harness-project-init` 生成文档体系
2. 手动填充 feature-list.json（根据现有代码）
3. 更新 progress.txt（记录已完成的工作）
4. 运行 `session-handoff` 生成同步检查点

## 相关技能

- `session-handoff` - 会话结束时的交接棒
- `harness-watchdog` - 定期健康巡检
- `issue-triage` - 缺陷分诊

## 参考文档

- [Harness Engineering 驾驭工程实战手册](https://km.sankuai.com/harness-engineering)
- [前后端分离项目的 Harness 文档体系](./docs/HARNESS_DOCS_BLUEPRINT.md)
- [维护规则和检查清单](./docs/MAINTENANCE_RULES.md)

---

**创建时间**：2026-04-20  
**维护者**：Harness Engineering Team  
**版本**：2.1.0
