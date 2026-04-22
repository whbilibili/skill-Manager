---
name: fe-update-docs
description: 根据项目代码变更自动更新项目文档。必须更新 AGENTS.md、ARCHITECTURE.md、docs/tech-debt.md、docs/caveats.md、docs/quality-score.md；若项目存在 doc/components/、.cursor/rules/components/、CLAUDE.md 则也更新；可选输出 CHANGELOG 到 doc/CHANGELOG/。当用户请求更新文档、同步文档、或执行 /fe-update-docs 命令时触发。

metadata:
  skillhub.creator: "fanjiahao05"
  skillhub.updater: "fanjiahao05"
  skillhub.version: "V12"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "8459"
  skillhub.high_sensitive: "false"
---

# Update Docs

根据项目代码变更，自动更新项目文档的 skill。

## 工作流程

### Step 0：询问是否生成 CHANGELOG

在执行任何文档更新前，先向用户确认：

> 是否需要将本次文档变更生成 CHANGELOG 并输出到 `doc/CHANGELOG/` 目录？（Y/N）

- 用户回答 **Y**：执行完所有文档更新后，在 `doc/CHANGELOG/` 目录下生成 CHANGELOG 文件（若目录不存在则自动创建）
- 用户回答 **N**：跳过 CHANGELOG 生成，仅更新文档

---

### Step 1：分析项目变更

扫描项目结构，识别需要更新的文档内容：

```bash
# 检查近期变更文件
git diff --name-only HEAD~5

# 查看项目结构
ls -la src/ 2>/dev/null || true
ls -la docs/ 2>/dev/null || true

# 检查可选目录是否存在
ls -la doc/components/ 2>/dev/null && echo "EXISTS:doc/components" || echo "MISSING:doc/components"
ls -la .cursor/rules/components/ 2>/dev/null && echo "EXISTS:.cursor/rules/components" || echo "MISSING:.cursor/rules/components"
ls -la CLAUDE.md 2>/dev/null && echo "EXISTS:CLAUDE.md" || echo "MISSING:CLAUDE.md"
```

**重点关注：**
- `src/` - 源码结构变化
- `package.json` - 依赖变化
- `docs/` - 已有文档状态

---

### Step 2：必须更新的文档

以下文档**无论项目情况如何，都必须更新**：

#### 2.1 AGENTS.md（项目根目录）

Agent 导航地图，保持约 100 行。更新内容：
- 项目简介和技术栈
- 关键目录结构
- 常用命令
- 重要约束和注意事项入口

#### 2.2 ARCHITECTURE.md（项目根目录）

架构约束文档。更新内容：
- 目录结构（同步最新 `src/` 目录树）
- 层级约束（禁止跨层导入规则）
- 状态管理架构
- 关键模块说明

#### 2.3 docs/caveats.md

已知问题与注意事项。更新内容：
- 新发现的坑和解决方案
- 已修复的问题（标记为已解决，不删除）
- 第三方库的特殊行为

#### 2.4 docs/tech-debt.md

技术债追踪。更新内容：
- 新增的技术债条目（来自本次变更）
- 已偿还的技术债（标记为已完成）
- 优先级评估

#### 2.5 docs/quality-score.md

质量评分。更新内容：
- 基于本次变更更新各维度评分
- 记录评分变化原因

---

### Step 3：条件更新的文档

检测到对应目录/文件存在时才更新：

#### 3.1 doc/components/（若目录存在）

组件文档目录。对每个有变更的组件/服务更新对应 `.md` 文件：

```markdown
# ComponentName

简短描述

## 文件位置

\`\`\`
src/path/to/component
\`\`\`

## 功能描述

- 功能点 1
- 功能点 2

## 类型定义

\`\`\`typescript
// 接口和类型
\`\`\`

## 方法列表

\`\`\`typescript
// 公共方法和属性
\`\`\`

## 使用示例

\`\`\`typescript
// 实际使用代码
\`\`\`

## 注意事项

1. 注意点 1
2. 注意点 2
```

同步更新 `doc/components/README.md` 索引（若存在）。

#### 3.2 .cursor/rules/components/（若目录存在）

Cursor Rules 组件文档，每个核心组件对应一个 `.mdc` 文件：

```markdown
---
alwaysApply: true
---
# ComponentName 使用规范

简短描述组件的用途和职责。

## 文件位置

\`\`\`
src/path/to/component
\`\`\`

## 使用规则

1. **规则 1** - 使用时的关键规则
2. **规则 2** - 注意事项

## 禁止事项

1. ❌ 禁止的操作 1
2. ❌ 禁止的操作 2
```

**与 doc/components/ 的区别：**
- `doc/components/` - 完整 API 文档，包含所有方法和详细示例
- `.cursor/rules/components/` - 精简使用规则，重点在于"如何正确使用"

#### 3.3 README.md（若文件存在且内容需要更新）

项目主文档。仅当以下情况发生时才更新：
- 新增或删除了功能特性
- 技术栈/依赖版本有变化
- 安装或运行命令有变化
- 项目结构目录树有显著变化

不因小范围代码改动而更新 README.md。

#### 3.4 CLAUDE.md（若文件存在）

Claude AI 项目指南。更新内容：
- 项目概览
- 开发命令
- 架构概览（同步最新变更）
- 开发规范
- 关键集成点

---

### Step 4：一致性检查

确保各文档间信息一致：
- AGENTS.md 中的目录结构与 ARCHITECTURE.md 保持一致
- caveats.md 中记录的问题与代码中的注释/TODO 对应
- tech-debt.md 的条目与实际代码状态匹配

---

### Step 5：生成 CHANGELOG（若 Step 0 用户确认 Y）

在 `doc/CHANGELOG/` 目录下生成文件（目录不存在则自动创建）：

**文件命名**：`CHANGELOG-{{DATE}}.md`（如 `CHANGELOG-2026-03-30.md`）

**文件格式**：

```markdown
# CHANGELOG - {{DATE}}

## 本次变更概览

基于 git diff HEAD~N 的代码变更，本次文档更新涵盖以下内容。

## 已更新文档

### 必更文档

- **AGENTS.md**
  - [变更描述]

- **ARCHITECTURE.md**
  - [变更描述]

- **docs/caveats.md**
  - [变更描述]

- **docs/tech-debt.md**
  - [变更描述]

- **docs/quality-score.md**
  - [变更描述]

### 条件更新文档（本次触发）

- **doc/components/XxxComponent.md**（若有变更）
  - [变更描述]

- **.cursor/rules/components/XxxComponent.mdc**（若有变更）
  - [变更描述]

- **CLAUDE.md**（若有变更）
  - [变更描述]

## 代码变更摘要

- 新增：[新增的功能/组件/模块]
- 变更：[修改的功能/接口/行为]
- 移除：[删除的功能/组件]
- 修复：[修复的问题]
```

---

## 输出格式

所有文档更新完成后，输出变更摘要：

```
文档更新完成

已更新文件：
- AGENTS.md — [变更摘要]
- ARCHITECTURE.md — [变更摘要]
- docs/caveats.md — [变更摘要]
- docs/tech-debt.md — [变更摘要]
- docs/quality-score.md — [变更摘要]
[条件文档若有更新也列出]

CHANGELOG：doc/CHANGELOG/CHANGELOG-{{DATE}}.md（若生成）
```

---

## 注意事项

- **增量更新**：只更新有变化的部分，避免重写整个文档
- **代码优先**：以实际代码为准，文档描述必须与代码一致
- **中文文档**：项目文档使用中文编写
- **不删除历史**：caveats.md 和 tech-debt.md 中已解决的条目标记为完成而非删除
- **保持格式**：遵循现有文档的格式风格，不改变文档整体结构
