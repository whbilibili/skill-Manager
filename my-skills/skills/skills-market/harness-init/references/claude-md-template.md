# CLAUDE.md Template

> 使用说明：用 Phase 0 检测到的值替换 `{PLACEHOLDER}`。
> 目标行数：80-100 行。超过 120 行应考虑抽取到 docs/。

---

# {PROJECT_NAME}

{PROJECT_PURPOSE_ONE_SENTENCE}

## 1. 北极星

{NORTH_STAR_BULLETS}

## 2. 架构概览

{ARCHITECTURE_SUMMARY_2_3_SENTENCES}

详细设计文档: [`docs/DESIGN.md`](docs/DESIGN.md)

## 3. 模块边界

| 模块 | 职责 | 允许依赖 |
|------|------|---------|
{MODULE_TABLE_ROWS}

## 4. 关键约束

{KEY_INVARIANTS_BULLETS}

## 5. 命令

| 动作 | 命令 | 说明 |
|------|------|------|
| 构建 | `{BUILD_CMD}` | {BUILD_DESC} |
| 测试 | `{TEST_CMD}` | {TEST_DESC} |
| 检查 | `{LINT_CMD}` | {LINT_DESC} |

## 6. 代码规范

{CODE_CONVENTIONS_BULLETS}

## 7. 决策优先级

当目标冲突时，按以下优先级决策：

{DECISION_PRIORITY_NUMBERED_LIST}

## 8. 变更检查清单

每次提交前至少满足：

- [ ] 编译通过: `{BUILD_CMD}`
- [ ] 变更一致性: 接口改动需同步检查所有调用方
- [ ] 回归重点: {REGRESSION_FOCUS}

## 9. 知识库

| 主题 | 路径 | 说明 |
|------|------|------|
| 系统设计 | [`docs/DESIGN.md`](docs/DESIGN.md) | 架构、模块、数据流 |
| 质量标准 | [`docs/QUALITY_SCORE.md`](docs/QUALITY_SCORE.md) | 代码质量指标和检查清单 |
| 可靠性 | [`docs/RELIABILITY.md`](docs/RELIABILITY.md) | SLO、错误处理、可观测性 |
| 设计文档 | [`docs/design-docs/`](docs/design-docs/) | 详细设计和架构决策 |
| 执行计划 | [`docs/exec-plans/active/`](docs/exec-plans/active/) | 当前工作计划 |
| 产品规格 | [`docs/product-specs/`](docs/product-specs/) | 产品需求和用户故事 |
| 参考资料 | [`docs/references/`](docs/references/) | 外部参考、API 文档 |
