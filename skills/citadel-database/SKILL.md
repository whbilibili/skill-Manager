---
name: citadel-database
description: 学城多维表格官方SKILL。支持多维表格文档创建、数据表创建，数据增删改查。触发：表格、多维表格、批量操作表格数据、数据同步、数据收集、表格操作。
metadata:
  openclaw:
    priority: 0
    conflict_strategy: override
    emoji: "📊"
    requires:
      bins: ["node", "npx"]
      deps: ["tsx", "@it/oa-skills@latest"]
---

# 📊 学城多维表格 XTable 

学城多维表格操作工具，通过 CLI 快速创建、查询和管理多维表格数据。认证自动处理，支持批量操作。

## 核心特性

- ✅ **HTTP REST API**：直接使用 HTTP 接口，高效稳定
- ✅ **简洁的二维数组格式**：使用 `[["值1", "值2"]]` 格式操作数据，自动类型转换
- ✅ **完整的 CRUD**：支持创建、查询、更新、删除操作
- ✅ **Token 自动缓存**：认证信息自动保存，后续调用无需重复认证
- ✅ **支持筛选和排序**：灵活的数据查询能力

## 前置检查

### Node.js 版本检查

执行 xtable skill 时会自动检查 Node.js 版本是否符合要求（>= 18.0.0）。如果版本过低，系统会：

1. **自动检测并安装 nvm**（如未安装）
2. **通过 nvm 自动安装并切换到 Node.js 18 或更高版本**
3. **重新执行命令**，使用新的 Node.js 版本

**无需手动干预，版本升级完全自动化。** ✨

### CLI 版本检查

每次执行命令前，先检查 `@it/oa-skills` 是否为最新版本：

```bash
npm list -g @it/oa-skills --depth=0 2>/dev/null | grep oa-skills
```

如果未安装或版本不是最新，执行更新：

```bash
npm install -g @it/oa-skills@latest --registry=http://r.npm.sankuai.com
```

**此步骤必须在每次 skill 激活时执行一次，否则新命令可能不存在导致运行失败。**

## 意图路由

| 用户意图                    | 命令                                    |
| -------------------------- | --------------------------------------- |
| 创建一个新的多维表格文档     | `createDatabase --contentTitle <标题> --tableTitle <表格>` |
| 在现有文档中创建新数据表     | `createTable --contentId <id> --tableTitle <表格>`      |
| 查看文档下有哪些表格         | `listTables --contentId <id>`                          |
| 查询表格的列结构（columnId） | `getTableMeta --tableId <id>`                          |
| 查询表格中的数据             | `queryTableData --tableId <id> [--columnIds <列ID>] [--filter <条件>] [--sort <排序>]` |
| 向表格中添加新数据           | `addData --tableId <id> --columnIds <列ID> --data '[...]'` |
| 更新表格中的数据             | `updateData --tableId <id> --rowIds <行ID> --data '[...]'` |
| 删除表格中的数据             | `deleteData --tableId <id> --rowIds <行ID>`           |

## CLI 速查

所有命令格式：`oa-skills citadel-database <command> [options]`

通用选项：
- `--mis <mis>` 指定用户（可选，默认从 `~/.config/clawdgw.json` 读取）
- `--raw` 输出 JSON 到 stdout
- `--clear-cache` 清除认证缓存

| 命令                    | 必填参数                          | 可选参数                                  |
| ---------------------- | ------------------------------- | ---------------------------------------- |
| `createDatabase`       | `--contentTitle` `--tableTitle` | `--parentId` `--columnMeta` `--templateId` |
| `createTable`          | `--contentId` `--tableTitle`   | `--columnMeta` `--sourceTableId`        |
| `listTables`           | `--contentId`                  |                                          |
| `getTableMeta`         | `--tableId`                    |                                          |
| `queryTableData`       | `--tableId`                    | `--columnIds` `--filter` `--sort` `--pageSize` `--pageToken` |
| `addData`              | `--tableId` `--columnIds` `--data` |                                      |
| `updateData`           | `--tableId` `--rowIds` `--columnIds` `--data` |                |
| `deleteData`           | `--tableId` `--rowIds`         |                                          |

columnIds 格式：逗号分隔的列 ID（如 `"1,2,3"`），或 JSON 数组（如 `"[1,2,3]"`）

## CLI 使用

### 基础命令

```bash
# 查看帮助
oa-skills citadel-database --help

# 清除认证缓存
oa-skills citadel-database --clear-cache
```

### 文档和表格创建

```bash
# 创建多维表格文档
oa-skills citadel-database createDatabase \
  --contentTitle "项目管理表" \
  --tableTitle "项目列表" \
  --mis "your_mis" \
  --columnMeta '[
    {"columnName":"项目名称","columnType":1},
    {"columnName":"负责人","columnType":1},
    {"columnName":"状态","columnType":3},
    {"columnName":"进度","columnType":2}
  ]'

# 在现有文档中创建新表格
oa-skills citadel-database createTable \
  --contentId "123456" \
  --tableTitle "任务表" \
  --mis "your_mis" \
  --columnMeta '[{"columnName":"任务名","columnType":1}]'

# 查询文档下的表格列表
oa-skills citadel-database listTables \
  --contentId "123456" \
  --mis "your_mis"
```

### 元数据查询

```bash
# 查询表格元数据（列信息）
oa-skills citadel-database getTableMeta \
  --tableId "456789" \
  --mis "your_mis"
```

### 数据查询

```bash
# 基础查询 - 未指定 columnIds 时，默认返回前10列
oa-skills citadel-database queryTableData \
  --tableId "456789" \
  --mis "your_mis"

# 指定列查询
oa-skills citadel-database queryTableData \
  --tableId "456789" \
  --columnIds "1,2,3" \
  --mis "your_mis"

# 分页查询
oa-skills citadel-database queryTableData \
  --tableId "456789" \
  --columnIds "1,2,3" \
  --pageSize 50 \
  --pageToken "100" \
  --mis "your_mis"

# 带筛选条件查询
oa-skills citadel-database queryTableData \
  --tableId "456789" \
  --columnIds "1,2,3" \
  --filter '{"conjunction":"and","conditions":[{"columnId":1,"operator":"==","filterValue":["完成"]}]}' \
  --mis "your_mis"

# 带排序条件查询
oa-skills citadel-database queryTableData \
  --tableId "456789" \
  --columnIds "1,2,3" \
  --sort '[{"columnId":2,"desc":true}]' \
  --mis "your_mis"

# 完整查询 - 筛选、排序、分页
oa-skills citadel-database queryTableData \
  --tableId "456789" \
  --columnIds "1,2,3" \
  --filter '{"conjunction":"and","conditions":[{"columnId":1,"operator":"==","filterValue":["完成"]}]}' \
  --sort '[{"columnId":2,"desc":true}]' \
  --pageSize 50 \
  --pageToken "100" \
  --mis "your_mis"
```

### 数据操作（使用二维数组格式）

```bash
# 新增数据 - 使用二维数组
oa-skills citadel-database addData \
  --tableId "456789" \
  --columnIds "1,2,3" \
  --mis "your_mis" \
  --data '[
    ["任务A", 100, "进行中"],
    ["任务B", 200, "待处理"]
  ]'

# 更新数据 - 使用二维数组
oa-skills citadel-database updateData \
  --tableId "456789" \
  --rowIds "[123, 456]" \
  --columnIds "1,2" \
  --mis "your_mis" \
  --data '[
    ["任务A（更新）", 150],
    ["任务B（更新）", 250]
  ]'

# 删除数据
oa-skills citadel-database deleteData \
  --tableId "456789" \
  --rowIds "[123, 456, 789]" \
  --mis "your_mis"
```

## TypeScript SDK 使用

### 基础使用

```typescript
import { XTableClient } from "@it/oa-skills/citadel-database";

const client = new XTableClient();

// 1. 认证
await client.ensureAuth("your_mis");

// 2. 创建多维表格文档
const db = await client.createDatabase({
  contentTitle: "项目管理表",
  tableTitle: "项目列表",
  columnMeta: [
    { columnName: "项目名称", columnType: 1 },
    { columnName: "负责人", columnType: 1 },
    { columnName: "状态", columnType: 3 },
    { columnName: "进度", columnType: 2 },
  ],
});

console.log(`文档ID: ${db.contentId}`);  // number 类型
console.log(`表格ID: ${db.tableId}`);    // number 类型

// 3. 查询表格元数据
const meta = await client.getTableMeta(db.tableId);
console.log(`列信息:`, meta.columns);

// 4. 添加数据（使用二维数组格式）
await client.addData({
  tableId: db.tableId,        // number 类型
  columnIds: [1, 2, 3, 4],    // number[] 类型
  data: [
    ["用户中心重构", "张三", "进行中", 75],
    ["数据平台升级", "李四", "进行中", 60],
    ["移动端优化", "王五", "待开始", 0],
  ],
});

// 5. 查询数据
const result = await client.queryTableData({
  tableId: db.tableId,        // number 类型
  columnIds: [1, 2, 3, 4],    // number[] 类型
});

console.log(`查询到 ${result.rows?.length} 行数据`);

// 6. 更新数据（使用二维数组格式）
await client.updateData({
  tableId: db.tableId,        // number 类型
  rowIds: [100, 101],         // number[] 类型
  columnIds: [3, 4],          // number[] 类型
  data: [
    ["进行中", 80],
    ["进行中", 65],
  ],
});

// 7. 删除数据
await client.deleteData({
  tableId: db.tableId,        // number 类型
  rowIds: [102],              // number[] 类型
});
```

### 完整示例：项目管理表

```typescript
import { XTableClient } from "@it/oa-skills/citadel-database";

async function createProjectTable() {
  const client = new XTableClient();
  await client.ensureAuth("your_mis");

  // 创建表格
  const db = await client.createDatabase({
    contentTitle: "项目管理表",
    tableTitle: "项目列表",
    columnMeta: [
      { columnName: "项目名称", columnType: 1 },    // 文本
      { columnName: "负责人", columnType: 1 },      // 文本
      { columnName: "状态", columnType: 3 },        // 单选
      { columnName: "优先级", columnType: 3 },      // 单选
      { columnName: "开始日期", columnType: 7 },    // 日期
      { columnName: "截止日期", columnType: 7 },    // 日期
      { columnName: "进度", columnType: 2 },        // 数字
      { columnName: "预算(万元)", columnType: 2 },  // 数字
      { columnName: "备注", columnType: 1 },        // 文本
    ],
  });

  console.log(`✅ 表格创建成功！`);
  console.log(`🔗 链接: https://km.sankuai.com/xtable/${db.contentId}?table=${db.tableId}`);

  // 填充示例数据（使用二维数组格式）
  await client.addData({
    tableId: db.tableId,                    // number 类型
    columnIds: [1, 2, 3, 4, 5, 6, 7, 8, 9], // number[] 类型
    data: [
      ["用户中心重构", "张三", "进行中", "高", 1704067200000, 1711900800000, 75, 50, "核心系统升级"],
      ["数据平台升级", "李四", "进行中", "高", 1705276800000, 1714320000000, 60, 80, "大数据处理"],
      ["移动端优化", "王五", "待开始", "中", 1706486400000, 1717372800000, 0, 30, "用户体验提升"],
      ["API网关迁移", "赵六", "进行中", "高", 1701388800000, 1709136000000, 90, 60, "微服务架构"],
      ["日志系统改造", "钱七", "已完成", "中", 1698796800000, 1706486400000, 100, 40, "运维效率提升"],
    ],
  });

  console.log(`✅ 数据填充完成！`);
  
  return db;
}

createProjectTable();
```

## 约束

- `--mis` 参数可选，未指定时会从 `~/.config/clawdgw.json` 的 `defaultUserId` 字段读取
- 缺少关键参数时只追问必要字段（--contentId / --tableId / --columnIds），不给笼统报错
- 列 ID 格式灵活：支持逗号分隔字符串 `"1,2,3"` 或 JSON 数组 `[1,2,3]`
- 数据大小限制：单次操作最多 500 行
- 批量删除前建议先查询数据确认要删除的行 ID
- **列类型选择强制要求**：创建表格时，必须根据数据实际用途选择对应的列类型，而不是简单地全部使用文本列。如果某列类型不支持，按照降级策略使用文本列（type: 1）作为备选方案

## 暂不支持

以下能力当前 **不可用**，不要伪造执行结果：

- 表格或列的删除和修改
- 表格结构变更（添加/删除/修改列）
- 多维表格文档的删除

用户要求时明确说明"当前暂不支持"。替代方案：可通过 Web UI 手动操作或联系管理员。

## 认证

SSO CIBA 认证，首次调用需用户在大象 App 确认。Token 自动缓存。

- 认证失败 → `oa-skills citadel-database --clear-cache` 后重试
- 用户说"没法手机确认" → 解释 CIBA 必须手机确认，无法跳过

### 自动认证

首次调用会触发 CIBA 认证，需在手机上（大象 App）确认登录请求。认证信息会自动缓存到 `~/.cache/openclaw-auth/auth-cache.json`。

### 配置文件（可选）

创建 `~/.config/clawdgw.json` 配置默认用户：

```json
{
  "version": "1.0",
  "identifier": "your_identifier_uuid",
  "defaultUserId": "your_mis"
}
```

## 验证

执行完成后确认：

1. 命令退出码为 0
2. 创建类：返回了新文档/表格 ID 和链接
3. 查询类：返回了数据/列表
4. 数据操作类：返回操作结果摘要（新增/更新/删除的行数）
5. 给用户简明结论（ID、数量、链接），而非原始数据

## 多维表格链接格式

多维表格的完整链接格式为：

```
https://km.sankuai.com/xtable/{contentId}?table={tableId}&view={viewId}
```

示例：
```
https://km.sankuai.com/xtable/2750138424?table=2750248577&view=1000
```

参数说明：
- `contentId`: 多维表格文档 ID（必需）
- `tableId`: 表格 ID（可选，不指定则显示第一个表格）
- `viewId`: 视图 ID（可选，不指定则显示默认视图）

## 列类型对照表

| columnType | 类型说明 | 数据结构 | CellData 字段 | 示例 |
|------------|----------|----------|--------------|------|
| 1 | 文本 | `IRichTextNode[]` | `textCellValue` | `[{type:"text",value:"任务A"}]` |
| 2 | 数字 | `number` | `numberCellValue` | `100` |
| 3 | 单选 | `string` | `selectCellValue` | `"进行中"` |
| 4 | 人员 | `empId[]` | `peopleCellValue` | `[2015738,2015739]` |
| 5 | 多选 | `string[]` | `multipleSelectCellValue` | `["标签1","标签2"]` |
| 6 | 附件 | `string[]` (fileUrl) | - | `["https://..."]` |
| 7 | 日期 | `number` (timestamp) | `dateCellValue` | `1704067200000` |
| 8 | 货币 | `number` | `numberCellValue` | `99.99` |
| 9 | 公式 | 不可编辑 | - | 只读，不支持写入 |

## 列类型选择最佳实践

### ⭐ 创建表格时的列类型设置原则

在创建表格时（`createDatabase` 或 `createTable`），应该 **尽可能根据数据类型和列的实际用途生成对应的列类型**，而不是简单地全部使用文本列（type: 1）。这样可以：

- ✅ 确保数据的完整性和准确性
- ✅ 在 UI 上获得更好的展示效果（如日期选择器、人员选择器）
- ✅ 启用字段级别的数据验证和筛选功能
- ✅ 支持更复杂的业务逻辑（如货币符号、日期范围等）

### 列类型选择指南

| 数据用途 | 推荐类型 | 原因 | 不支持时降级方案 |
|---------|---------|------|-----------------|
| 项目/任务名称 | 1 (文本) | 长度不限，支持富文本 | - |
| 数值数据（金额、数量、百分比） | 2 (数字) 或 8 (货币) | 支持数学计算、排序、筛选 | → 降级为 1 (文本) |
| 状态、优先级、标签 | 3 (单选) 或 5 (多选) | 统一选项、数据质量高 | → 降级为 1 (文本) |
| 负责人、参与者信息 | 4 (人员) | 支持人员提及、自动映射 empId | → 降级为 1 (文本，存储 empId) |
| 截止日期、开始日期 | 7 (日期) | 支持日期选择、时间戳、日期计算 | → 降级为 1 (文本，格式 YYYY-MM-DD) |
| 文件、图片、证明材料 | 6 (附件) | 支持文件上传、在线预览 | → 降级为 1 (文本，存储 URL) |
| 通用备注、描述 | 1 (文本) | 长度可调、支持富文本 | - |

### 创建表格示例：正确的列类型配置

```typescript
// ✅ 推荐：根据数据用途选择合适的列类型
const db = await client.createDatabase({
  contentTitle: "项目管理表",
  tableTitle: "项目列表",
  columnMeta: [
    { columnName: "项目名称", columnType: 1 },      // 文本 - 项目标题
    { columnName: "项目描述", columnType: 1 },      // 文本 - 详细说明
    { columnName: "负责人", columnType: 4 },        // 人员 - 选人时自动映射 empId
    { columnName: "项目成员", columnType: 4 },      // 人员（多选）- 团队成员
    { columnName: "状态", columnType: 3 },          // 单选 - 固定选项（进行中/完成/暂停）
    { columnName: "优先级", columnType: 3 },        // 单选 - 固定选项（高/中/低）
    { columnName: "开始日期", columnType: 7 },      // 日期 - 日期选择器
    { columnName: "截止日期", columnType: 7 },     // 日期 - 日期选择器
    { columnName: "进度百分比", columnType: 2 },    // 数字 - 0-100 的整数
    { columnName: "预算(万元)", columnType: 8 },    // 货币 - 金额字段
    { columnName: "附件", columnType: 6 },          // 附件 - 上传文件
    { columnName: "备注", columnType: 1 },          // 文本 - 自由描述
  ],
});
```

### 数据类型映射参考

创建或更新数据时，请确保提供的数据与列类型相匹配：

```typescript
await client.addData({
  tableId: db.tableId,
  columnIds: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  data: [
    [
      "用户中心重构",                  // 1: 文本
      "核心功能模块升级改造",          // 2: 文本
      2015738,                        // 3: 人员（empId 数字）
      [2015738, 2015739],            // 4: 人员数组
      "进行中",                       // 5: 单选字符串
      "高",                           // 6: 单选字符串
      1704067200000,                 // 7: 日期时间戳
      1711900800000,                 // 8: 日期时间戳
      75,                            // 9: 数字（百分比）
      50.5,                          // 10: 货币数字
      "https://example.com/file.pdf", // 11: 附件 URL
      "正在进行核心功能测试"           // 12: 文本
    ]
  ]
});
```

### 降级策略（如果不支持特定列类型）

如果某个列类型在创建时不可用或不支持，按照以下优先级降级：

```
目标类型 → 降级选项 (优先级从高到低)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
4 (人员)   → 1 (文本) - 存储 empId
3 (单选)   → 1 (文本) - 存储选项文本
5 (多选)   → 1 (文本) - 用逗号/分号分隔
7 (日期)   → 1 (文本) - 格式: YYYY-MM-DD 或时间戳字符串
8 (货币)   → 2 (数字) → 1 (文本)
6 (附件)   → 1 (文本) - 存储 URL
```

**降级使用示例**（当服务端不支持人员类型时）：

```typescript
// 降级方案：用文本列存储 empId
const db = await client.createDatabase({
  contentTitle: "项目管理表",
  tableTitle: "项目列表",
  columnMeta: [
    { columnName: "项目名称", columnType: 1 },
    { columnName: "负责人", columnType: 1 },      // 降级为文本，存储 "2015738" 或 "张三"
    { columnName: "状态", columnType: 1 },        // 降级为文本，存储 "进行中"
    { columnName: "截止日期", columnType: 1 },   // 降级为文本，格式: "2024-12-31"
  ],
});
```

### IRichTextNode 结构

```typescript
interface IRichTextNode {
  value: string;           // 文本内容
  type: "text" | "link" | "mention" | "paragraph";  // 富文本类型
  empId?: number;          // @人员时的员工ID
  link?: string;           // 超链接时的URL
  marks?: unknown;         // 富文本标记（粗体、斜体等）
  openType?: string;       // 打开链接的类型
}
```

## 数据格式说明

### CellData 结构

```typescript
interface CellData {
  colId: number;                           // 列ID
  textCellValue?: TextCellValue[];        // 文本类型
  numberCellValue?: number;               // 数字类型
  selectCellValue?: string;               // 单选类型
  multipleSelectCellValue?: string[];     // 多选类型
  peopleCellValue?: string[];             // 人员类型（empId字符串数组）
  dateCellValue?: number;                 // 日期类型（毫秒时间戳）
}
```

## 筛选和排序

### 筛选条件（FilterConfig）

```typescript
interface FilterCondition {
  columnId: number | string;    // 列ID
  operator: string;             // 操作符
  filterValue: unknown[];       // 筛选值数组
}

interface FilterConfig {
  conjunction: "and" | "or";    // 逻辑关系
  conditions: FilterCondition[];  // 筛选条件数组
}
```

支持的操作符：
- `==` - 等于 (IS)
- `!=` - 不等于 (IsNot)
- `contains` - 包含 (Contains)
- `notcontains` - 不包含 (DoesNotContain)
- `>` - 大于 (IsGreater)
- `>=` - 大于等于 (IsGreaterEqual)
- `<` - 小于 (IsLess)
- `<=` - 小于等于 (IsLessEqual)
- `isnull` - 为空 (IsEmpty)
- `notnull` - 不为空 (IsNotEmpty)

示例：
```json
{
  "conjunction": "and",
  "conditions": [
    {"columnId": 1, "operator": "==", "filterValue": ["完成"]},
    {"columnId": 2, "operator": ">=", "filterValue": [50]}
  ]
}
```

TypeScript 使用示例：
```typescript
const result = await client.queryTableData({
  tableId: 456789,              // number 类型
  columnIds: [1, 2, 3],         // number[] 类型
  filter: {
    conjunction: "and",
    conditions: [
      {columnId: 1, operator: "==", filterValue: ["完成"]},
      {columnId: 2, operator: ">=", filterValue: [50]}
    ]
  },
  pageSize: 100
});
```

### 排序条件（SortCondition）

```typescript
interface SortCondition {
  columnId: number;             // 列ID（数字类型）
  desc?: boolean;               // 是否降序
}
```

示例：
```json
[
  {"columnId": 2, "desc": true}
]
```

TypeScript 使用示例：
```typescript
const result = await client.queryTableData({
  tableId: 456789,              // number 类型
  columnIds: [1, 2, 3],         // number[] 类型
  sort: [
    {columnId: 2, desc: true},  // number 类型
  ],
  pageSize: 100
});
```

## 项目结构

```text
skills/citadel-database/
└── SKILL.md          # Skill 定义

src/citadel-database/
├── types.ts          # 类型定义
├── client.ts         # XTableClient 实现（HTTP REST API）
├── cli.ts            # CLI 入口
└── index.ts          # 导出入口
```

## 最佳实践

### 0. 创建表格时选择正确的列类型

在创建表格之前，应该明确每一列的用途和数据类型，然后选择对应的列类型。这是数据质量的基础：

**✅ 正确做法**：
```typescript
const db = await client.createDatabase({
  contentTitle: "项目管理",
  tableTitle: "项目列表",
  columnMeta: [
    { columnName: "项目名称", columnType: 1 },      // 文本
    { columnName: "负责人", columnType: 4 },        // 人员（不是文本！）
    { columnName: "状态", columnType: 3 },          // 单选（不是文本！）
    { columnName: "截止日期", columnType: 7 },     // 日期（不是文本！）
    { columnName: "预算", columnType: 8 },          // 货币（不是文本！）
  ]
});
```

**❌ 错误做法**（全部使用文本列）：
```typescript
const db = await client.createDatabase({
  contentTitle: "项目管理",
  tableTitle: "项目列表",
  columnMeta: [
    { columnName: "项目名称", columnType: 1 },      // 文本
    { columnName: "负责人", columnType: 1 },        // ❌ 应该用 4 (人员)
    { columnName: "状态", columnType: 1 },          // ❌ 应该用 3 (单选)
    { columnName: "截止日期", columnType: 1 },     // ❌ 应该用 7 (日期)
    { columnName: "预算", columnType: 1 },          // ❌ 应该用 8 (货币)
  ]
});
```

**列类型选择规则**：
- 如果支持目标列类型，**必须使用对应类型**
- 如果不支持，才降级为文本（type: 1）
- 参考上面的"列类型选择最佳实践"章节获取完整指南

### 1. 使用简化的二维数组格式操作数据

**推荐**（使用简化的二维数组格式）：
```typescript
// 使用二维数组格式，系统自动根据列类型格式化数据
await client.addData({
  tableId: 123,           // number 类型
  columnIds: [1, 2, 3],   // number[] 类型
  data: [
    ["任务A", 100, "进行中"],
    ["任务B", 200, "待处理"]
  ]
});
```

这种方法的优点：
- ✅ 代码简洁，易于理解
- ✅ 自动处理数据类型转换
- ✅ 支持批量操作（最多 500 条）
- ✅ 支持人员提及和富文本（如 `"[@张三:123456]"` 和 `"[文本](url)"`）

### 2. 先查询元数据，了解列结构

```typescript
const meta = await client.getTableMeta(tableId);
console.log("列信息:", meta.columns);
// 使用正确的 columnId 和 columnType
```

### 3. 使用 Token 缓存

认证信息会自动缓存，有效期内无需重复认证。如需清除：

```bash
oa-skills citadel-database --clear-cache
```

### 4. 批量操作

```typescript
// 一次性添加多行数据（支持最多 500 条）
await client.addData({
  tableId: 123,           // number 类型
  columnIds: [1, 2, 3],   // number[] 类型
  data: Array.from({length: 100}, (_, i) => [
    `任务${i}`,
    Math.random() * 100,
    "进行中"
  ])
});
```

### 5. 错误处理

```typescript
try {
  await client.addData({
    tableId: 123,           // number 类型
    columnIds: [1, 2, 3],   // number[] 类型
    data: [["任务A", 100, "进行中"]]
  });
} catch (error) {
  console.error("操作失败:", error.message);
  // 错误信息包含 TraceID，可用于追踪问题
}
```

## 常见问题

### Q: 如何获取列ID？

A: 使用 `getTableMeta` 命令查询表格元数据，返回结果中包含每列的 `colId`。

### Q: 日期格式如何处理？

A: 日期使用毫秒时间戳格式（13位数字）。可以使用 `new Date().getTime()` 或 `Date.parse("2024-01-01")` 获取。

### Q: 如何处理人员类型？

A: 人员类型需要使用员工ID（empId），是一个数字数组。例如：`[12345, 67890]`。

### Q: 认证失败怎么办？

A: 
1. 检查是否在手机上确认了登录请求
2. 清除缓存重新认证：`oa-skills citadel-database --clear-cache`
3. 确认 MIS 账号是否有效

### Q: API 调用失败如何排查？

A: 错误信息中包含 TraceID，可以用于在日志系统中追踪问题：
```
API 错误 (400): Invalid parameter (TraceID: abc123...)
```

## Node.js 版本检查快速参考

### 检查当前版本

```bash
node --version    # 显示 Node 版本，如 v18.19.0
nvm list          # 列出已安装的 Node 版本
```

### 手动切换版本（如果有多个版本）

```bash
nvm use 18         # 切换到 Node 18
nvm use 20         # 切换到 Node 20
nvm current        # 显示当前使用的版本
```

### 清除版本检查缓存

```bash
# 如果遇到版本检查问题，可以尝试清除相关缓存
rm -rf ~/.nvm     # 完全重新安装 nvm（谨慎操作）
```

## 故障排除

如果遇到 Node 版本相关问题，按以下步骤操作：

### 1️⃣ 检查当前版本
```bash
node --version
```

### 2️⃣ 如果版本过低，手动升级
```bash
# 方法 A：通过 nvm 升级
nvm install 18
nvm use 18

# 方法 B：重新运行 citadel-database 命令（自动升级）
oa-skills citadel-database --help
```

### 3️⃣ 如果升级失败，检查网络连接
```bash
# 测试网络
curl -I https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh
```

### 4️⃣ 最后一步：手动安装 nvm
```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 18
oa-skills citadel-database --help
```

### 验证成功标志

运行 citadel-database 命令时，应该看到以下输出顺序：

1. ✓ 如果版本符合要求（>= 18）：
   ```
   ✓ Node.js 版本检查通过: v18.x.x
   🔐 正在认证用户: <mis>
   ```

2. ⚙ 如果版本过低（< 18），系统会：
   ```
   ❌ Node.js 版本过低
   当前版本: v16.x.x
   要求版本: ≥ v18.0.0
   将自动升级到 Node.js v18...
   📦 正在安装 nvm...
   📦 正在通过 nvm 安装 Node.js v18...
   （耐心等待，这可能需要几分钟）
   ✓ Node.js v18 安装并激活完成
   ✅ Node.js 升级完成！正在使用新版本重新执行命令...
   ```

## 详细文档

更多 Node 版本检查和自动升级的技术细节，请查看项目根目录的 `NODE_VERSION_CHECK_GUIDE.md`。
## 问题反馈
点击加客服群: https://x.sankuai.com/bridge/chat?gid=7041123825 

## 更新日志

### v2.2.0 (2026-03-12)
- ✅ 合并 queryTableData 和 queryTableDataWithFilter 接口
- ✅ queryTableData 现在支持可选的筛选、排序和分页参数
- ✅ 简化 API 表面，减少概念数量

### v2.1.0 (2026-03-12)
- ✅ 新增 Node 版本自动检查和升级功能
- ✅ 集成 nvm 自动管理 Node 版本
- ✅ 支持自动安装 nvm（如未安装）
- ✅ 完全自动化的版本升级流程，无需用户干预

### v2.0.0 (2026-03-11)
- ✅ 重构为 HTTP REST API 实现
- ✅ 移除 MCP SDK 依赖
- ✅ 优化认证流程
- ✅ 完善数据格式化逻辑
- ✅ 新增简化的数据操作方法

### v1.0.0
- 初始版本，基于 MCP SDK 实现

## 问题反馈
[点击加客服群](https://x.sankuai.com/bridge/chat?gid=70411238253 )