# 缺陷洞察参考手册（AIDI 平台）

> 所有操作遵循 SKILL.md 核心规则。

## 目录

- [能力范围](#能力范围)
- [CLI 命令速查](#cli-命令速查)
- [意图路由](#意图路由)
- [约束](#约束)
- [常用工作流](#常用工作流)

---

## 能力范围

通过 `fsd defect` 命令组查询 AIDI 平台的缺陷上下文、缺陷列表、需求信息、修复报告及关联用例。

> ⚠️ **与 `fsd defect list` 区分**：`fsd defect list` 走 teammetric 平台（按测试计划维度），本文件所有命令走 AIDI 平台（按 operator/需求/测试计划多维度查询）

---

## CLI 命令速查

```bash
# 查询单条缺陷完整上下文（含设备信息、截图解析、代码提交等）
fsd defect context --defect-id <onesId>

# 按 operator/时间/需求/测试计划 查询缺陷列表
fsd defect query --operator <mis> --start-time "2026-01-01 00:00:00" --end-time "2026-01-31 23:59:59"
fsd defect query --operator <mis> --req-id <reqId>
fsd defect query --operator <mis> --test-plan-id <testPlanId>

# 查询需求扩展信息（含需求文档、技术文档链接）
fsd defect req-extend --req-id <reqId>

# 查询需求质量洞察报告
fsd defect req-insight --req-id <reqId>

# 查询单条缺陷修复分析报告
fsd defect fix-report --defect-id <onesId>

# 按需求 ID 批量查询缺陷修复报告列表
fsd defect fix-reports --req-id <reqId> --page-num 1 --page-size 20

# 根据缺陷 ID 列表查询关联测试用例
fsd defect cases-by-defect --defect-ids <id1> <id2> <id3>
```

---

## 参数说明

### `fsd defect context`

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--defect-id` | string | 是 | 缺陷 ONES ID |

### `fsd defect query`

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--operator` | string | 是 | 当前用户 MIS（只能查自己的缺陷） |
| `--start-time` | string | 条件 | 格式 `yyyy-MM-dd HH:mm:ss` |
| `--end-time` | string | 条件 | 格式 `yyyy-MM-dd HH:mm:ss` |
| `--req-id` | string | 条件 | 需求 ID（与 `--test-plan-id` 互斥） |
| `--test-plan-id` | string | 条件 | 测试计划 ID（与 `--req-id` 互斥） |
| `--page-num` | string | 否 | 页码，默认 1 |
| `--page-size` | string | 否 | 分页大小，默认 20 |

> `--start-time`/`--end-time`、`--req-id`、`--test-plan-id` 至少提供其中一组

### `fsd defect fix-reports`

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--req-id` | string | 是 | 需求 ID |
| `--page-num` | string | 否 | 页码，默认 1 |
| `--page-size` | string | 否 | 分页大小，默认 20 |

### `fsd defect cases-by-defect`

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--defect-ids` | string | 是 | 缺陷 ID 列表，空格分隔（`<id1> <id2> ...`） |

---

## 意图路由

| 用户描述 | 命令 |
|----------|------|
| 查缺陷详情/上下文 | `fsd defect context --defect-id` |
| 查我的缺陷列表（时间范围） | `fsd defect query --operator --start-time --end-time` |
| 查需求关联缺陷 | `fsd defect query --operator --req-id` |
| 查测试计划关联缺陷（AIDI 维度） | `fsd defect query --operator --test-plan-id` |
| 查需求文档/技术文档链接 | `fsd defect req-extend --req-id` |
| 查需求质量/洞察报告 | `fsd defect req-insight --req-id` |
| 查缺陷修复分析（单条） | `fsd defect fix-report --defect-id` |
| 查需求下所有缺陷的修复报告 | `fsd defect fix-reports --req-id` |
| 查缺陷关联的测试用例 | `fsd defect cases-by-defect --defect-ids` |

---

## 约束

- `fsd defect query` 的 `--operator` **只能填写当前用户自己的 MIS**，不允许查询他人缺陷
- `--req-id` 与 `--test-plan-id` 互斥，不能同时使用
- 需求 ID 的字段可能命名为：`parentId`、`onesId`、`reqId`、`issueId`，取数字值传入即可
- 缺少必填参数时只追问必要字段，不给笼统报错

---

## 常用工作流

### 分析需求缺陷特性

```bash
# 第一步：查询需求关联缺陷
fsd defect query --operator <mis> --req-id <reqId>

# 第二步：按需深入分析（fixInsight/desSummary/rootReason 等字段）
fsd defect fix-reports --req-id <reqId>
```

### 分析测试计划缺陷特性

```bash
fsd defect query --operator <mis> --test-plan-id <testPlanId>
```

### 查询缺陷完整上下文

```bash
# 第一步：查缺陷上下文
fsd defect context --defect-id <onesId>

# 第二步：查关联需求信息（可选）
fsd defect req-extend --req-id <reqId>
```

### 分析需求质量

```bash
# 优先查洞察报告
fsd defect req-insight --req-id <reqId>

# 报告为空时回退到缺陷数据分析
fsd defect query --operator <mis> --req-id <reqId>
```

### 查缺陷关联用例

```bash
fsd defect cases-by-defect --defect-ids 93936671 93936672 93936673
```

---

## 返回数据关键字段说明

### `fsd defect query` 返回（data.list）

| 字段 | 说明 |
|------|------|
| `onesId` | 缺陷 ONES ID |
| `issueName` | 缺陷标题 |
| `state` | 状态 |
| `assigned` | 处理人 MIS |
| `fixInsight` | 修复分析摘要（可用于特性分析） |
| `desSummary` | 缺陷简述 |
| `rootReason` | 根因分类 |

> 给用户展示时只提炼关键字段（数量、状态分布、关键缺陷），不直接输出原始 JSON
