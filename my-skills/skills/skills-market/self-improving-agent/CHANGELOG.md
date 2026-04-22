# Changelog — self-improving-agent

## v2.0.0 — 2026-03-23 (yeshaozhi)

### 重大重构（Breaking Change）

基于原版（v1 by guohanru）完全重写，架构从「文件日志型」转为「认知模式型」。

### 新增功能

- **错误纠正分类机制**：4 类纠正类型（Operational/Behavioral/Domain-specific/Preference）自动决定写入目标（TOOLS.md vs MEMORY.md）
- **置信度晋升机制**：0.3 Tentative → 0.6 Emerging → 0.9 Established，防止低质量单次指令污染知识库；30 天未复现自动降级
- **冲突解决规则**：明确优先级——最新显式指令 > 推断模式；用户直接声明 > 惯例；存疑则追问
- **Auto-Extraction 三问 + 质量门控**（Reusable/Verified/Specific/Non-duplicate 四项必须通过）
- **Extraction Format**：标准化 PATTERN/TRIGGER/ACTION/CONFIDENCE/TARGET 五字段提取格式，并支持 /learn 命令主动触发
- **Anti-Patterns 防护**：拒绝从沉默推断偏好、情感/心理模式、第三方偏好、操控性内容、单次侥幸修复（correlation ≠ causation）
- **参考文件**：`learning.md`（完整提取流程、Claudeception 机制）、`boundaries.md`（边界说明）

### 迁移说明

原版（v1）使用 `.learnings/` 文件日志，本版直接写入 OpenClaw workspace（TOOLS.md / MEMORY.md）。

## v2.1.0 — 2026-03-23

### 新增
- `When to Use` 章节：明确 4 种触发场景（用户纠正/agent 自发现/命令触发/三问全 YES）
- `When NOT to Use` 章节：明确 5 种排除条件，防止误触发
- `Instructions` 章节：5 个编号阶段（分类→质量门控→置信度→写入→Auto-Extraction），每阶段有入口/出口条件

### 结构调整
- Promotion Rules、Auto-Extraction、/learn 命令触发逻辑合并进 Instructions 阶段 3/4/5，流程统一有编号
- 阶段 4 新增完成门控（3 项 checklist：文件写入+用户确认+当日 memory 记录）

### 修复
- 衰减规则统一为 30 天（原文中 30 days vs 3 weeks 不一致已消除）

## v2.1.1 (2026-03-28)

### 修复（skill-creator-pro 质量对齐）
- Phase 1.5 跳过理由：Tool Wrapper / 知识指南类型，跳过案例收集
- Completion Gate 添加
- evals/ 目录创建
