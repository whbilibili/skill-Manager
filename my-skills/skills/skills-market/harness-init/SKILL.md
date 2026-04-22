---
name: harness-init
description: "为项目搭建最基础的 AI 智能体友好的 harness 结构。创建精简 CLAUDE.md（地图）+ docs/ 知识库目录。当用户提到：harness, 搭建harness, init harness, 项目脚手架, agent-friendly, 智能体友好, bootstrap harness, setup harness, harness engineering 时触发。"
version: 1.0.0
tag: [Harness, Scaffolding, CLAUDE.md, Agent-Friendly, Meta]

metadata:
  skillhub.creator: "xufan17"
  skillhub.updater: "xufan17"
  skillhub.version: "V1"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "20237"
  skillhub.high_sensitive: "false"
---

# Harness Init — 为项目搭建 AI 智能体友好的基础结构

## 核心理念

> 给智能体一张地图，而不是一本千页手册。—— OpenAI Harness Engineering

- **CLAUDE.md 是地图**：~100 行，精简目录索引，指向 `docs/` 深层知识
- **docs/ 是知识库**：设计文档、执行计划、产品规格、参考资料
- **架构靠约束强制执行**：linter、结构测试、分层依赖规则
- **智能体能直接验证**：build/test/lint 命令必须文档化且可执行

## 流程概览

```
Phase 0: 项目检测 (只读)
    ↓ [HARD-GATE: 用户确认]
Phase 1: CLAUDE.md (地图)
    ↓
Phase 2: docs/ 知识目录
    ↓
Phase 3: 验证与总结
```

---

## Phase 0 — 项目检测（只读）

**允许工具**: Read, Glob, Grep, Bash (只读命令: ls, wc, head, find)
**禁止工具**: Write, Edit

### 0.1 项目类型检测

按优先级扫描，命中即停：

| 文件 | 项目类型 | 进一步检测 |
|------|---------|----------|
| `pom.xml` | Java/Maven | 解析 parent: mdp-parent→MDP, xframe-starter-parent→XFrame, 其他→Spring Boot |
| `build.gradle` / `build.gradle.kts` | Java/Gradle | 检查 Spring Boot 插件 |
| `package.json` | Node.js | 检查 framework: next/nuxt/vue/react/express |
| `go.mod` | Go | 检查 main package 位置 |
| `pyproject.toml` / `setup.py` / `requirements.txt` | Python | 检查 framework: django/flask/fastapi |
| `Cargo.toml` | Rust | — |
| `Makefile` (仅此) | Generic | — |

### 0.2 Build/Test/Lint 命令提取

扫描以下来源：
- `Makefile` targets (build, test, lint, check)
- `package.json` scripts (build, test, lint, start, dev)
- `pom.xml` 推断: `mvn -DskipTests compile` / `mvn test`
- CI 配置: `.github/workflows/*.yml`, `.gitlab-ci.yml`, `Jenkinsfile`, `pipeline.yml`

输出一个表格：
```
| 动作   | 命令                      | 来源          |
|--------|--------------------------|--------------|
| build  | mvn -DskipTests compile  | pom.xml 推断  |
| test   | mvn test                 | pom.xml 推断  |
| lint   | (未检测到)                | —            |
```

### 0.3 现有 Harness 检查

检查以下项：
- `CLAUDE.md`: 是否存在？行数？是否含 Knowledge Base 段？
- `AGENTS.md`: 是否存在？（兼容 OpenAI Codex 约定）
- `docs/` 目录: 是否存在？子目录列表
- `README.md`: 是否存在？

### 0.4 项目结构扫描

- 列出顶层模块/子目录
- 对多模块项目，列出各模块及推断的职责
- 检测入口点（main class / index.js / main.go 等）
- 检测分层模式（api/application/infrastructure/starter 等）

### 0.5 输出检测报告

以结构化格式展示检测结果，每个动作标记：

```
检测报告
========
项目: {name} ({type})
框架: {framework}
模块: {module_list}

Build 命令:
  build: mvn -DskipTests compile
  test:  mvn test
  lint:  (未检测到)

Harness 状态:
  CLAUDE.md    — 存在 (287行) → [Refactor] 超过120行，建议抽取实现日志到 docs/
  docs/        — 不存在       → [Create] 创建知识目录结构
  README.md    — 存在         → [Skip] 无需修改
```

<HARD-GATE>
展示检测报告后，必须使用 AskUserQuestion 请求用户确认。
用户未确认前，禁止任何写操作。
</HARD-GATE>

---

## Phase 1 — CLAUDE.md（地图）

**允许工具**: Read, Write, Edit, Glob, Grep

根据 Phase 0 检测结果，选择以下路径之一：

### 路径 A: CLAUDE.md 不存在 → 从模板生成

1. 读取模板: `$SKILL_DIR/references/claude-md-template.md`
2. 用 Phase 0 检测到的值填充 `{placeholder}`
3. 与用户确认内容后写入项目根目录

### 路径 B: CLAUDE.md 存在且 ≤120 行 → 追加知识库索引

1. 读取现有 CLAUDE.md
2. 检查是否已有 Knowledge Base 段
3. 若无，在末尾追加：
```markdown
## 知识库索引

| 主题 | 路径 | 说明 |
|------|------|------|
| 系统设计 | `docs/DESIGN.md` | 架构、模块、数据流 |
| 质量标准 | `docs/QUALITY_SCORE.md` | 代码质量指标和检查清单 |
| 可靠性 | `docs/RELIABILITY.md` | SLO、错误处理、可观测性 |
| 设计文档 | `docs/design-docs/` | 详细设计文档 |
| 执行计划 | `docs/exec-plans/active/` | 当前工作计划 |
| 产品规格 | `docs/product-specs/` | 产品需求 |
| 参考资料 | `docs/references/` | 外部参考 |
```

### 路径 C: CLAUDE.md 存在且 >120 行 → 重构

1. 分析 CLAUDE.md 内容，识别以下类型的"膨胀段落"：
   - 实现日志 / changelog（特征：含日期、"已完成"、"待办"、接口表格）
   - 功能进度跟踪
   - 详细 API 列表
2. 提议抽取到 `docs/design-docs/implementation-log.md`
3. 展示抽取前后的对比（保留段落标题作为指针）
4. 用户确认后执行抽取
5. 追加知识库索引段（同路径 B）

**目标**: 重构后 CLAUDE.md ≤120 行，核心架构指导 + 知识库索引。

---

## Phase 2 — docs/ 知识目录

**允许工具**: Write, Bash (mkdir)

### 2.1 创建目录结构

对每个目录，若已存在则跳过：

```bash
mkdir -p docs/design-docs
mkdir -p docs/exec-plans/active
mkdir -p docs/exec-plans/completed
mkdir -p docs/product-specs
mkdir -p docs/references
```

### 2.2 生成文档

从模板生成以下文件（已存在则跳过）：

| 文件 | 模板 | 说明 |
|------|------|------|
| `docs/DESIGN.md` | `$SKILL_DIR/references/design-doc-template.md` | 系统设计总览 |
| `docs/QUALITY_SCORE.md` | `$SKILL_DIR/references/quality-score-template.md` | 质量标准 |
| `docs/RELIABILITY.md` | `$SKILL_DIR/references/reliability-template.md` | 可靠性要求 |
| `docs/design-docs/index.md` | (内联生成) | 设计文档目录 |
| `docs/product-specs/index.md` | (内联生成) | 产品规格目录 |

### 2.3 如果 Phase 1 抽取了实现日志

将抽取的内容写入 `docs/design-docs/implementation-log.md`，保留原始格式。

---

## Phase 3 — 验证与总结

**允许工具**: Read, Bash, Glob

### 3.1 结构验证

- [ ] CLAUDE.md 行数 ≤120
- [ ] CLAUDE.md 含知识库索引段
- [ ] 知识库索引中的每个路径都存在
- [ ] docs/DESIGN.md 存在且非空
- [ ] docs/QUALITY_SCORE.md 存在且非空
- [ ] docs/RELIABILITY.md 存在且非空

### 3.2 构建验证（可选）

若 Phase 0 检测到 build 命令，询问用户是否运行以确认无破坏。

### 3.3 输出总结

```
Harness 搭建完成
================
创建文件: {count}
  - docs/DESIGN.md
  - docs/QUALITY_SCORE.md
  - ...
修改文件: {count}
  - CLAUDE.md (287行 → 98行)
抽取文件: {count}
  - docs/design-docs/implementation-log.md (从 CLAUDE.md §6-6e)

建议 commit message:
  chore: init project harness — CLAUDE.md map + docs/ knowledge base
```

---

## 关键原则

1. **绝不覆盖** — 已存在的文件只追加或重构，不替换
2. **交互式确认** — 每个阶段的破坏性操作前必须用户确认
3. **内容非空** — 生成的文档用检测到的信息填充，不留空白 placeholder
4. **语言无关** — 检测逻辑覆盖 Java/Node/Python/Go/Rust，模板适配各语言
5. **最小够用** — 只创建最基础的结构，不过度设计

## 使用示例

```
用户: /harness-init
智能体: [Phase 0 检测报告]
  项目: df-app (Java/Maven/MDP)
  CLAUDE.md: 287行 → [Refactor]
  docs/: 不存在 → [Create]
  是否继续? [确认/调整]

用户: 确认

智能体: [Phase 1] CLAUDE.md 分析完成
  识别到 §6-6e 实现日志 (180行)
  建议抽取到 docs/design-docs/implementation-log.md
  重构后 CLAUDE.md 预计 107 行
  [展示对比 diff]
  是否执行? [确认/调整]

用户: 确认

智能体: [Phase 2] 创建 docs/ 结构...
  [Phase 3] 验证通过，harness 搭建完成
```
