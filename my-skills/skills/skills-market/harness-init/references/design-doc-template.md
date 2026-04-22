# docs/DESIGN.md Template

> 使用说明：用 Phase 0 检测到的值替换 `{PLACEHOLDER}`。
> 本文档是系统设计的"深层知识"，CLAUDE.md 的知识库索引指向这里。

---

# {PROJECT_NAME} — 系统设计

## 目的

{PROJECT_PURPOSE_DETAILED}

## 架构图

```
{ASCII_ARCHITECTURE_DIAGRAM}
```

> 图例说明：{DIAGRAM_LEGEND}

## 模块详述

{FOR_EACH_MODULE}
### {MODULE_NAME}

- **职责**: {MODULE_RESPONSIBILITY}
- **包路径**: `{MODULE_PACKAGE}`
- **入口点**: `{MODULE_ENTRY_POINT}`
- **关键类**:
  - `{CLASS_1}` — {CLASS_1_DESC}
  - `{CLASS_2}` — {CLASS_2_DESC}
- **依赖**: {MODULE_DEPENDENCIES}
{END_FOR_EACH}

## 数据流

### 主链路

```
{PRIMARY_DATA_FLOW_DIAGRAM}
```

{PRIMARY_FLOW_DESCRIPTION}

### 辅助链路

{SECONDARY_FLOWS_IF_ANY}

## 技术选型

| 关注点 | 选择 | 理由 |
|--------|------|------|
| {CONCERN_1} | {CHOICE_1} | {REASON_1} |
| {CONCERN_2} | {CHOICE_2} | {REASON_2} |

## 关注点映射（Where to Look）

| 我想了解... | 去看... |
|------------|--------|
| 请求入口 | `{ENTRY_POINT_PATH}` |
| 业务逻辑 | `{BUSINESS_LOGIC_PATH}` |
| 数据访问 | `{DATA_ACCESS_PATH}` |
| 外部依赖 | `{EXTERNAL_DEPS_PATH}` |
| 配置 | `{CONFIG_PATH}` |
| 测试 | `{TEST_PATH}` |

## 决策日志

| 日期 | 决策 | 背景 | 替代方案 |
|------|------|------|---------|
| {DATE} | {DECISION} | {CONTEXT} | {ALTERNATIVES} |
