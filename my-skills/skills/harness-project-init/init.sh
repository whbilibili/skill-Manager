#!/bin/bash

# Harness 工程初始化脚本
# 用法：bash init.sh <project_name> <project_type> <root_dir> [tech_stack] [include_examples]
# 示例：bash init.sh frontend frontend ./frontend "React 18 + TypeScript" true

set -e

# 参数
PROJECT_NAME=${1:-"frontend"}
PROJECT_TYPE=${2:-"frontend"}
ROOT_DIR=${3:-.}
TECH_STACK=${4:-""}
INCLUDE_EXAMPLES=${5:-true}

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 初始化 Harness 工程项目骨架${NC}"
echo "项目名称: $PROJECT_NAME"
echo "项目类型: $PROJECT_TYPE"
echo "根目录: $ROOT_DIR"
echo ""

# 创建目录结构
HARNESS_DIR="${ROOT_DIR}/harness"
DOCS_DIR="${HARNESS_DIR}/docs"
MEMORY_DIR="${HARNESS_DIR}/memory"

echo -e "${YELLOW}📁 创建目录结构...${NC}"
mkdir -p "$DOCS_DIR"
mkdir -p "$MEMORY_DIR"

# 创建 feature-list.json
echo -e "${YELLOW}📝 创建 feature-list.json...${NC}"
cat > "${HARNESS_DIR}/feature-list.json" << 'EOF'
{
  "version": "1.0",
  "project": "PROJECT_NAME",
  "project_type": "PROJECT_TYPE",
  "created_at": "CREATED_AT",
  "updated_at": "CREATED_AT",
  "metadata": {
    "total_tasks": 0,
    "completed_tasks": 0,
    "in_progress_tasks": 0,
    "pending_tasks": 0,
    "completion_rate": 0
  },
  "tasks": []
}
EOF

# 替换占位符
sed -i '' "s/PROJECT_NAME/$PROJECT_NAME/g" "${HARNESS_DIR}/feature-list.json"
sed -i '' "s/PROJECT_TYPE/$PROJECT_TYPE/g" "${HARNESS_DIR}/feature-list.json"
sed -i '' "s/CREATED_AT/$(date -u +%Y-%m-%dT%H:%M:%SZ)/g" "${HARNESS_DIR}/feature-list.json"

# 创建 progress.txt（交接棒式格式，兼容 session-handoff / harness-watchdog 等 skill）
echo -e "${YELLOW}📝 创建 progress.txt...${NC}"
cat > "${HARNESS_DIR}/progress.txt" << EOF
# ${PROJECT_NAME} 工程进度记录

> 本文件由 session-handoff 维护，200 行硬上限。
> Section markers 被 7 个 harness skill 解析，请勿修改标题格式。

### [Current Focus]
- 项目初始化：搭建基础框架

### [Key Decisions]
- $(date +%Y-%m-%d): 使用 harness-project-init v2.1 初始化文档体系

### [Blockers & Solutions]
（暂无）

### [Dead Ends]
（暂无）

### [Next Steps]
- [ ] 编辑 feature-list.json，添加实际任务
- [ ] 编辑 ARCHITECTURE.md，描述项目架构
- [ ] 开始编码，首个会话结束时运行 session-handoff
EOF

# 创建 ARCHITECTURE.md
echo -e "${YELLOW}📝 创建 ARCHITECTURE.md...${NC}"
cat > "${HARNESS_DIR}/ARCHITECTURE.md" << EOF
# ${PROJECT_NAME} 架构文档

**工程类型**：${PROJECT_TYPE}
**创建时间**：$(date +%Y-%m-%d)
**维护者**：架构师 / Coding Agent
**最后更新**：$(date +%Y-%m-%d)

---

## 📋 项目概述

### 项目目标
简要描述项目的目标和范围

### 技术栈
${TECH_STACK:+- 技术栈：$TECH_STACK}
- 待定

### 关键指标
- 性能目标：待定
- 可用性目标：待定
- 测试覆盖率目标：> 80%

---

## 🏗️ 模块划分

### 模块 1：[模块名]
- **职责**：待定
- **关键文件**：src/
- **依赖**：待定
- **接口**：待定

---

## 🎯 关键设计决策

### 决策 1：[决策标题]

| 项目 | 内容 |
|------|------|
| **决策时间** | $(date +%Y-%m-%d) |
| **决策者** | 架构师 |
| **选项** | 待定 |
| **最终选择** | 待定 |
| **原因** | 待定 |
| **权衡** | 待定 |

---

## 🚫 架构约束

### 禁止（红线）

❌ **禁止 1**：待定
- 原因：待定
- 替代方案：待定

### 推荐（绿线）

✅ **推荐 1**：待定
- 好处：待定

---

**维护规则**：
- 新增模块 → 更新此文档
- 架构变更 → 更新此文档
- 新增设计决策 → 更新此文档
EOF

# 创建 docs/caveats.md
echo -e "${YELLOW}📝 创建 docs/caveats.md...${NC}"
cat > "${DOCS_DIR}/caveats.md" << 'EOF'
# 踩坑档案

**工程**：PROJECT_NAME
**维护者**：Coding Agent
**最后更新**：CREATED_AT

---

> 记录开发过程中遇到的问题、解决方案和经验教训

## 问题 1：[问题标题]

### 问题描述
[简要描述问题]

### 现象
[具体现象和错误信息]

### 复现步骤
1. [步骤 1]
2. [步骤 2]

### 根本原因
[分析根本原因]

### 解决方案
[提供解决方案]

### 状态
✅ 已解决 / ⏳ 待解决 / 🔄 进行中

---

**维护规则**：
- 遇到新问题时更新
- 问题解决时更新状态
EOF

sed -i '' "s/PROJECT_NAME/$PROJECT_NAME/g" "${DOCS_DIR}/caveats.md"
sed -i '' "s/CREATED_AT/$(date +%Y-%m-%d)/g" "${DOCS_DIR}/caveats.md"

# 创建 docs/tech-debt.md
echo -e "${YELLOW}📝 创建 docs/tech-debt.md...${NC}"
cat > "${DOCS_DIR}/tech-debt.md" << 'EOF'
# 技术债清单

**工程**：PROJECT_NAME
**维护者**：Coding Agent
**最后更新**：CREATED_AT

---

> 记录需要后续改进的技术问题

## 优先级说明

| 级别 | 含义 | 处理时间 |
|------|------|---------|
| **P0** | 阻塞上线，必须立即处理 | 本周内 |
| **P1** | 影响稳定性，应该尽快处理 | 本月内 |
| **P2** | 影响体验，可以排期处理 | 本季度内 |
| **P3** | 优化建议，可以延后处理 | 待定 |

---

## 技术债列表

| ID | 描述 | 优先级 | 预计工作量 | 状态 |
|----|------|--------|-----------|------|
| TD-001 | 待定 | P2 | 待定 | pending |

---

**维护规则**：
- 发现新的技术债时更新
- 技术债状态变更时更新
- 技术债优先级调整时更新
EOF

sed -i '' "s/PROJECT_NAME/$PROJECT_NAME/g" "${DOCS_DIR}/tech-debt.md"
sed -i '' "s/CREATED_AT/$(date +%Y-%m-%d)/g" "${DOCS_DIR}/tech-debt.md"

# 创建 docs/CHANGELOG.md
echo -e "${YELLOW}📝 创建 docs/CHANGELOG.md...${NC}"
cat > "${DOCS_DIR}/CHANGELOG.md" << 'EOF'
# 变更日志

**工程**：PROJECT_NAME
**维护者**：Coding Agent
**最后更新**：CREATED_AT

---

> 记录每个版本的功能、bug 修复和已知问题

## [Unreleased]

### Added
- 待定

### Fixed
- 待定

### Changed
- 待定

### Known Issues
- 待定

---
EOF

sed -i '' "s/PROJECT_NAME/$PROJECT_NAME/g" "${DOCS_DIR}/CHANGELOG.md"
sed -i '' "s/CREATED_AT/$(date +%Y-%m-%d)/g" "${DOCS_DIR}/CHANGELOG.md"

# 创建 memory/MEMORY.md
echo -e "${YELLOW}📝 创建 memory/MEMORY.md...${NC}"
cat > "${MEMORY_DIR}/MEMORY.md" << 'EOF'
# 长期记忆

**工程**：PROJECT_NAME
**维护者**：Coding Agent
**最后更新**：CREATED_AT

---

> 蒸馏自每日工作日志的高价值条目

## 架构决策

### 待定

---
EOF

sed -i '' "s/PROJECT_NAME/$PROJECT_NAME/g" "${MEMORY_DIR}/MEMORY.md"
sed -i '' "s/CREATED_AT/$(date +%Y-%m-%d)/g" "${MEMORY_DIR}/MEMORY.md"

# 创建 .sync-state.json
echo -e "${YELLOW}📝 创建 .sync-state.json...${NC}"
cat > "${ROOT_DIR}/.sync-state.json" << EOF
{
  "version": "1.0",
  "project": "$PROJECT_NAME",
  "last_sync": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "sync_duration_seconds": 0,
  "harness_version": "1.0",
  "code_commit": "initial",
  "code_branch": "main",
  "status": "in_sync",
  "sync_checks": {},
  "statistics": {
    "total_tasks": 0,
    "completed_tasks": 0,
    "in_progress_tasks": 0,
    "pending_tasks": 0,
    "completion_rate": 0,
    "total_code_lines": 0,
    "total_commits": 0,
    "test_coverage": 0
  },
  "warnings": [],
  "next_sync_recommended": "$(date -u -v+1d +%Y-%m-%dT%H:%M:%SZ)",
  "notes": "初始化时自动生成"
}
EOF

# 创建 .gitignore
echo -e "${YELLOW}📝 创建 .gitignore...${NC}"
cat > "${HARNESS_DIR}/.gitignore" << 'EOF'
# Harness 文档不入公共仓库
# 这些文件是本地分支开发的工作记录

# 临时文件
*.tmp
*.log
.DS_Store

# IDE
.vscode/
.idea/
*.swp
*.swo

# 依赖
node_modules/
__pycache__/
.venv/
EOF

echo ""
echo -e "${GREEN}✅ Harness 文档体系初始化完成！${NC}"
echo ""
echo -e "${BLUE}📂 目录结构：${NC}"
tree -L 3 "$ROOT_DIR" 2>/dev/null || find "$ROOT_DIR" -type f | head -20
echo ""
echo -e "${BLUE}📋 下一步：${NC}"
echo "1. 编辑 ${HARNESS_DIR}/feature-list.json，添加实际任务"
echo "2. 编辑 ${HARNESS_DIR}/ARCHITECTURE.md，描述项目架构"
echo "3. 开始编码，每个会话结束时运行 session-handoff"
echo ""
