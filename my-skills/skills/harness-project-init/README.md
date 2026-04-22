# Harness 工程初始化技能

快速搭建前后端分离项目的完整 Harness 文档体系。

## 快速开始

### 方式 1：使用 Python 脚本（推荐）

```bash
python3 init.py \
  --project-name frontend \
  --project-type frontend \
  --root-dir ./frontend \
  --tech-stack "React 18 + TypeScript"
```

### 方式 2：使用 Bash 脚本

```bash
bash init.sh frontend frontend ./frontend "React 18 + TypeScript" true
```

### 方式 3：在 CatDesk 中使用

在 CatDesk 中输入：
```
初始化一个前端工程的 harness，项目名称是 frontend，技术栈是 React 18 + TypeScript
```

## 文件说明

| 文件 | 说明 |
|------|------|
| `SKILL.md` | 技能定义和文档 |
| `init.py` | Python 初始化脚本（推荐） |
| `init.sh` | Bash 初始化脚本 |
| `README.md` | 本文件 |

## 生成的文档结构

```
project-root/
├── harness/
│   ├── feature-list.json      # 任务清单
│   ├── progress.txt           # 进度记录
│   ├── ARCHITECTURE.md        # 架构文档
│   ├── docs/
│   │   ├── caveats.md         # 踩坑档案
│   │   ├── tech-debt.md       # 技术债清单
│   │   └── CHANGELOG.md       # 变更日志
│   ├── memory/
│   │   └── MEMORY.md          # 长期记忆
│   └── .gitignore
└── .sync-state.json           # 同步检查点
```

## 参数说明

### 必需参数

- `--project-name`：项目名称（e.g., frontend）
- `--project-type`：项目类型（frontend / backend / fullstack）
- `--root-dir`：项目根目录路径

### 可选参数

- `--tech-stack`：技术栈描述（e.g., "React 18 + TypeScript"）
- `--include-examples`：是否包含示例任务（默认：true）

## 使用示例

### 示例 1：初始化前端工程

```bash
python3 init.py \
  --project-name frontend \
  --project-type frontend \
  --root-dir ./frontend \
  --tech-stack "React 18 + TypeScript + Redux"
```

### 示例 2：初始化后端工程

```bash
python3 init.py \
  --project-name backend \
  --project-type backend \
  --root-dir ./backend \
  --tech-stack "Node.js + Express + PostgreSQL"
```

### 示例 3：初始化全栈项目

```bash
python3 init.py \
  --project-name my-app \
  --project-type fullstack \
  --root-dir .
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
- **每月一次**：执行知识蒸馏

## 常见问题

### Q1：harness 文档应该放在代码仓库中吗？

**A**：不应该。harness 文档是本地分支开发的工作记录，不应该进入公共仓库。

### Q2：如何处理多个工程的协作？

**A**：使用全局 AGENTS.md 作为导航索引，每个工程有独立的 feature-list.json 和 progress.txt。

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
- [前后端分离项目的 Harness 文档体系](../../../research/harness-engineering/HARNESS_DOCS_BLUEPRINT.md)
- [维护规则和检查清单](../../../research/harness-engineering/MAINTENANCE_RULES.md)

---

**创建时间**：2026-04-20  
**维护者**：Harness Engineering Team  
**版本**：1.0.0
