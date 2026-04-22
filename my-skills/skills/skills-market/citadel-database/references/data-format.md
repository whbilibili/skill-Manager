# 数据格式参考

多维表格数据格式说明，包含列类型、单元格数据结构和转换规则。

## 目录

- [数据格式参考](#数据格式参考)
  - [目录](#目录)
  - [列类型 (ColumnType)](#列类型-columntype)
  - [列配置 (columnConfig) 说明](#列配置-columnconfig-说明)
    - [TypeScript 类型定义](#typescript-类型定义)
    - [按列类型分类的配置说明](#按列类型分类的配置说明)
      - [formatter 格式规则](#formatter-格式规则)
    - [使用示例](#使用示例)
  - [富文本格式 (TextCellValue)](#富文本格式-textcellvalue)
    - [节点类型](#节点类型)
      - [1. 纯文本节点](#1-纯文本节点)
      - [2. 超链接节点](#2-超链接节点)
      - [3. @提及节点](#3-提及节点)
      - [4. 段落节点](#4-段落节点)
      - [5. 混合格式](#5-混合格式)
    - [自动转换规则](#自动转换规则)
  - [二维数组格式](#二维数组格式)
    - [基本结构](#基本结构)
    - [列对应关系](#列对应关系)
    - [类型示例](#类型示例)
      - [1. 文本列 (columnType: 1)](#1-文本列-columntype-1)
      - [2. 数字列 (columnType: 2)](#2-数字列-columntype-2)
      - [3. 单选列 (columnType: 3)](#3-单选列-columntype-3)
      - [4. 人员列 (columnType: 4)](#4-人员列-columntype-4)
      - [5. 多选列 (columnType: 5)](#5-多选列-columntype-5)
      - [6. 附件列 (columnType: 6)](#6-附件列-columntype-6)
      - [7. 日期列 (columnType: 7)](#7-日期列-columntype-7)
      - [8. 货币列 (columnType: 8)](#8-货币列-columntype-8)
  - [查询响应格式](#查询响应格式)
    - [QueryTableDataResponse](#querytabledataresponse)
    - [TableMetaResponse](#tablemetaresponse)
  - [筛选条件格式 (FilterConfig)](#筛选条件格式-filterconfig)
    - [支持的操作符](#支持的操作符)
    - [筛选示例](#筛选示例)
  - [排序配置格式 (SortConfig)](#排序配置格式-sortconfig)
    - [排序示例](#排序示例)
  - [常见错误和解决方案](#常见错误和解决方案)
    - [1. 列类型不匹配](#1-列类型不匹配)
    - [2. empId 类型错误](#2-empid-类型错误)
    - [3. 富文本嵌套层级](#3-富文本嵌套层级)
    - [4. 二维数组结构](#4-二维数组结构)
    - [5. 日期格式](#5-日期格式)
  - [数据转换工具函数](#数据转换工具函数)
    - [JavaScript/TypeScript](#javascripttypescript)
    - [Bash](#bash)
  - [批量操作模式](#批量操作模式)
    - [批量新增](#批量新增)
    - [批量更新](#批量更新)
  - [API 响应示例](#api-响应示例)
    - [成功响应](#成功响应)
    - [错误响应](#错误响应)
    - [数据查询响应（完整示例）](#数据查询响应完整示例)

## 列类型 (ColumnType)

| 类型ID | 类型名称 | TypeScript 类型 | API 字段名 | 输入格式 | 说明 |
|---|---|---|---|---|---|
| 1 | 文本（富文本） | `IRichTextNode[]` | `textCellValue` | 字符串或节点数组 | 支持纯文本、超链接、@提及、段落节点 |
| 2 | 数字 | `number` | `numberCellValue` | `number` | 数值类型 |
| 3 | 单选 | `string` | `selectCellValue` | `string` | 单选选项的值 |
| 4 | 人员 | `number[]` | `peopleCellValue` | `number[]` 或 `string[]` | empId 数组 |
| 5 | 多选 | `string[]` | `multipleSelectCellValue` | `string[]` | 多选选项的值数组 |
| 6 | 附件 | `string[]` | `fileCellValue` | `string[]` (JSON 字符串) | 附件 JSON 字符串数组 |
| 7 | 日期 | `number` | `dateCellValue` | `number` | 毫秒时间戳 |
| 8 | 货币 | `number` | `numberCellValue` | `number` | 数值类型 |
| 9 | 公式 | 只读 | - | - | 不支持写入 |
| 10 | 查找引用 | 只读 | - | - | 不支持写入；查询时返回引用值的文本表示 |

## 列配置 (columnConfig) 说明

`getTableMeta` 返回的每列元数据中包含 `columnConfig` 字段，描述列的配置属性。不同 columnType 支持不同的配置项。

### TypeScript 类型定义

```typescript
interface ColumnConfig {
  /** 公共属性：列的默认值，适用于单选、多选、人员等类型 */
  defaultValue?: any;

  /** 选项配置（单选 type:3、多选 type:5）：可选项列表 */
  options?: Array<{
    id: string;       // 选项 ID
    label: string;    // 选项显示名称（数据中实际使用的值）
    color?: string;   // 选项颜色代码
  }>;

  /** 人员配置（人员 type:4）：是否支持多人选择 */
  multiple?: boolean;  // true=多人, false=单人

  /** 格式化配置（数字 type:2、日期 type:7、货币 type:8）：UI 展示格式规则 */
  formatter?: string;
}
```

### 按列类型分类的配置说明

**公共属性 — `defaultValue`**
- 适用类型：单选(3)、多选(5)、人员(4)
- 说明：列的默认值，新建行时自动填充
- 示例：单选列设置 `defaultValue: "待处理"` 则新行自动选中"待处理"

**选项配置 — `options`**（单选 type:3、多选 type:5）
- 说明：可选项列表，每项包含 `id`、`label`、`color`
- 写入数据时传的值必须匹配 `label`
- 写入时可传 `--allowCreateOptions <true|false>`：
  - 默认 `true`：值不在 options 中时自动新建选项
  - 传 `false`：值必须已存在于 options 中，否则报错

**人员配置 — `multiple`**（人员 type:4）
- 说明：是否支持多人选择
- `true`：人员列接受 empId 数组，如 `[2015738, 2015739]`
- `false`：人员列只接受单个 empId，如 `2015738`

**格式化配置 — `formatter`**（数字 type:2、日期 type:7、货币 type:8）
- ⚠️ **重要：formatter 只影响 UI 展示，不影响数据读写**
- 数据传输时仍使用原始类型：数字传数字、日期传时间戳
- 业务侧可根据 formatter 决定展示方式，但不需要按格式转换数据后再提交

#### formatter 格式规则

| 列类型 | formatter 示例 | 说明 |
|--------|----------------|------|
| 数字 (type:2) | `"0.00"` | 2 位小数 |
| 数字 (type:2) | `"0,0.00%"` | 百分比 + 千分位 + 2位小数（numerify 格式） |
| 数字 (type:2) | `"#,##0"` | 千分位整数 |
| 日期 (type:7) | `"YYYY-MM-DD"` | 日期（moment.js 格式） |
| 日期 (type:7) | `"YYYY/MM/DD HH:mm"` | 日期+时间 |
| 货币 (type:8) | `"¥#,##0.00"` | 人民币格式 |
| 货币 (type:8) | `"$0.00"` | 美元格式 |

### 使用示例

```bash
# 查看"状态"列的选项配置
oa-skills citadel-database getTableMeta --tableId "2750248577" --raw | \
  jq '.columns[] | select(.columnName=="状态") | {columnName, columnType, columnConfig}'

# 输出示例：
# {
#   "columnName": "状态",
#   "columnType": 3,
#   "columnConfig": {
#     "defaultValue": "待处理",
#     "options": [
#       {"id": "opt1", "label": "待处理", "color": "#999"},
#       {"id": "opt2", "label": "进行中", "color": "#1890ff"},
#       {"id": "opt3", "label": "已完成", "color": "#52c41a"}
#     ]
#   }
# }

# 查看所有单选/多选列的可选项
oa-skills citadel-database getTableMeta --tableId "2750248577" --raw | \
  jq '[.columns[] | select(.columnType==3 or .columnType==5) | {columnName, columnType, options: .columnConfig.options}]'

# 查看人员列是否支持多人
oa-skills citadel-database getTableMeta --tableId "2750248577" --raw | \
  jq '.columns[] | select(.columnType==4) | {columnName, multiple: .columnConfig.multiple}'

# 查看数字/日期列的格式化规则
oa-skills citadel-database getTableMeta --tableId "2750248577" --raw | \
  jq '[.columns[] | select(.columnType==2 or .columnType==7 or .columnType==8) | {columnName, columnType, formatter: .columnConfig.formatter}]'
```

## 富文本格式 (TextCellValue)

文本列（columnType: 1）支持富文本节点数组 `IRichTextNode[]`。

### 节点类型

#### 1. 纯文本节点

```typescript
{
  type: "text",
  value: "纯文本内容"
}
```

**示例**：
```json
[
  { "type": "text", "value": "Hello World" }
]
```

#### 2. 超链接节点

```typescript
{
  type: "link",
  value: "显示文字",
  link: "<链接URL>"
}
```

**示例**：
```json
[
  { "type": "text", "value": "访问 " },
  { "type": "link", "value": "美团官网", "link": "https://meituan.com" }
]
```

#### 3. @提及节点

```typescript
{
  type: "mention",
  value: "@用户名",  // value 必须以 @ 开头
  empId: 2015739   // 必须是 number 类型
}
```

**示例**：
```json
[
  { "type": "text", "value": "负责人：" },
  { "type": "mention", "value": "@张三", "empId": 2015739 }
]
```

#### 4. 段落节点

```typescript
{
  type: "paragraph",
  value: " "
}
```

说明：
- `paragraph` 节点发送前会统一补成 `value: " "`
- 如果传了其他 `value`，CLI 会在发送前规范化为单个空格

**示例**：
```json
[
  { "type": "text", "value": "第一段" },
  { "type": "paragraph", "value": " " },
  { "type": "text", "value": "第二段" }
]
```

#### 5. 混合格式

```json
[
  { "type": "text", "value": "请 " },
  { "type": "mention", "value": "@张三", "empId": 2015739 },
  { "type": "text", "value": " 查看 " },
  { "type": "link", "value": "项目文档", "link": "https://km.sankuai.com/page/123" },
  { "type": "text", "value": " 并在本周五前完成" }
]
```

### 自动转换规则

CLI 会自动将简单字符串转换为富文本格式：

```bash
# 输入：简单字符串
--data '[["任务A"]]'

# 自动转换为：
[{"type": "text", "value": "任务A"}]
```

如需使用超链接、@提及或段落节点，必须手动构造富文本节点数组。

## 二维数组格式

### 基本结构

所有数据操作（addData、updateData）都使用**二维数组**格式：

```typescript
[
  ["行1列1", "行1列2", "行1列3"],  // 第1行
  ["行2列1", "行2列2", "行2列3"]   // 第2行
]
```

### 列对应关系

数据列的顺序必须与 `--columnIds` 参数指定的列 ID 顺序一致：

```bash
--columnIds "1,2,3"
--data '[["值1", "值2", "值3"]]'
       # ↑对应列1  ↑对应列2  ↑对应列3
```

### 类型示例

#### 1. 文本列 (columnType: 1)

```json
// 简单文本
[["简单文本"]]

// 富文本（超链接）
[[[
  {"type":"text","value":"查看"},
  {"type":"link","value":"文档","link":"https://km.sankuai.com/page/123"}
]]]

// 富文本（段落）
[[[
  {"type":"text","value":"第一段"},
  {"type":"paragraph", "value": " "},
  {"type":"text","value":"第二段"}
]]]

// 富文本（@提及）
[[[
  {"type":"text","value":"负责人："},
  {"type":"mention","value":"@张三","empId":2015739}
]]]
```

#### 2. 数字列 (columnType: 2)

```json
[[100]]           // 整数
[[3.14]]          // 浮点数
[[0]]             // 零
[[-50]]           // 负数
```

#### 3. 单选列 (columnType: 3)

```json
[["待处理"]]      // 必须是已定义的选项值
[["进行中"]]
[["已完成"]]
```

**注意**：值必须精确匹配 `selectOptions` 中定义的选项。

#### 4. 人员列 (columnType: 4)

```json
[[2015739]]                 // 单人（数字）
[["2015739"]]               // 单人（字符串）
[[2015739, 2015740]]        // 多人（数字数组）
[["2015739", "2015740"]]    // 多人（字符串数组）
```

#### 5. 多选列 (columnType: 5)

```json
[["选项1"]]                  // 单选
[["选项1", "选项2"]]         // 多选
[[[]]]                       // 空值
```

#### 6. 附件列 (columnType: 6)

附件列使用 **JSON 字符串数组**格式，每个附件必须序列化为 JSON 字符串。

**附件对象结构**：
```typescript
interface FileAttachment {
  attachmentId: number;  // 必填：附件 ID（新建时设为 0）
  name: string;          // 必填：文件名
  url: string;           // 必填：文件 URL
  size?: number;         // 可选：文件大小（字节）
  width?: number;        // 可选：图片宽度
  height?: number;       // 可选：图片高度
  mimeType?: string;     // 可选：MIME 类型
}
```

**示例**：

```json
// 单个附件
[[
  JSON.stringify({
    attachmentId: 0,
    name: "logo.png",
    url: "<文件URL>",
    size: 6105,
    width: 300,
    height: 300,
    mimeType: "image/png"
  })
]]

// 多个附件
[[
  [
    JSON.stringify({
      attachmentId: 0,
      name: "file1.png",
      url: "<文件URL1>",
      size: 6105,
      mimeType: "image/png"
    }),
    JSON.stringify({
      attachmentId: 0,
      name: "file2.jpg",
      url: "<文件URL2>",
      size: 7475,
      mimeType: "image/jpeg"
    })
  ]
]]

// 最简格式（仅必填字段）
[[
  JSON.stringify({
    attachmentId: 0,
    name: "document.pdf",
    url: "<文件URL>"
  })
]]
```

**⚠️ 重要提示**：
- 必须使用 `JSON.stringify()` 将附件对象序列化为字符串
- `attachmentId`、`name`、`url` 三个字段必填
- 新建附件时 `attachmentId` 设为 0
- 其他字段可选，但建议提供以获得更好的展示效果

**CLI 示例**：
```bash
# 添加单个附件
oa-skills citadel-database addData \
  --tableId "456789" \
  --columnIds "1,2" \
  --data '[[
    "任务A",
    JSON.stringify({
      attachmentId: 0,
      name: "logo.png",
      url: "<文件URL>",
      mimeType: "image/png"
    })
  ]]'

# 添加多个附件
oa-skills citadel-database addData \
  --tableId "456789" \
  --columnIds "3" \
  --data '[[
    [
      JSON.stringify({attachmentId: 0, name: "file1.png", url: "<文件URL1>"}),
      JSON.stringify({attachmentId: 0, name: "file2.jpg", url: "<文件URL2>"})
    ]
  ]]'
```

#### 7. 日期列 (columnType: 7)

```json
[[1710000000000]]   // 毫秒时间戳 (2024-03-09)
[[0]]               // 空日期
```

**转换示例**：
```javascript
// JavaScript Date 转时间戳
const timestamp = new Date("2024-03-09").getTime();  // 1710000000000
```

#### 8. 货币列 (columnType: 8)

```json
[[100.50]]          // 金额（数值）
[[0]]               // 零
[[-50.25]]          // 负数（退款等场景）
```

## 查询响应格式

### QueryTableDataResponse

```typescript
{
  rows: [
    {
      rowId: 184484716,              // 行 ID
      cellData: [                     // 单元格数据数组
        {
          colId: 1,                   // 列 ID
          textCellValue: [            // 文本列数据
            { type: "text", value: "任务A" }
          ]
        },
        {
          colId: 2,
          numberCellValue: 100        // 数字列数据
        },
        {
          colId: 3,
          selectCellValue: "进行中"   // 单选列数据
        }
      ],
      createdBy: 2015738,             // 创建人 empId
      createdTime: 1773884148000,     // 创建时间: 2026-03-19
      lastModifiedBy: 2015738,        // 最后修改人 empId
      lastModifiedTime: 1773884148000 // 最后修改时间: 2026-03-19
    }
  ],
  total: 1                            // 总行数
}
```

### TableMetaResponse

```typescript
{
  columns: [
    {
      colId: 1,                       // 列 ID
      columnName: "任务名称",         // 列名
      columnType: 1,                  // 列类型
      selectOptions?: string[]        // 单选/多选的选项列表（可选）
    }
  ]
}
```

## 筛选条件格式 (FilterConfig)

```typescript
{
  conjunction: "and" | "or",          // 条件连接方式
  conditions: [
    {
      columnId: 1,                      // 列 ID
      operator: "==",                 // 操作符
      filterValue: ["值"]             // 筛选值（始终为 string[]）
    }
  ],
  children: [                           // 可选：继续嵌套一层筛选组
    {
      conjunction: "or",
      conditions: [
        {
          columnId: 2,
          operator: ">",
          filterValue: ["100"]
        }
      ]
    }
  ]
}
```

### 支持的操作符

| 操作符 | 说明 |
|---|---|
| `>` | 大于 |
| `>=` | 大于等于 |
| `<` | 小于 |
| `<=` | 小于等于 |
| `==` | 等于 |
| `!=` | 不等于 |
| `isnull` | 为空 |
| `notnull` | 不为空 |
| `contains` | 包含 |
| `notcontains` | 不包含 |

**注意：并不是所有列类型都支持所有操作符，必须按列类型选择。**

| 列类型 | 支持的操作符 | `filterValue` 校验 |
|---|---|---|
| 文本 | `==` `!=` `contains` `notcontains` `isnull` `notnull` | 最多 1 个元素 |
| 数字 / 货币 | `==` `!=` `>` `>=` `<` `<=` `isnull` `notnull` | 最多 1 个元素；若有值需可转成 float |
| 单选 / 多选 | `==` `!=` `contains` `notcontains` `isnull` `notnull` | 可多个元素 |
| 人员 / 创建人 / 修改人 | `==` `!=` `contains` `notcontains` `isnull` `notnull` | 可多个元素；所有值都需可转成 int |
| 附件 | `isnull` `notnull` | 不消费 `filterValue`，传 `[]` |
| 日期 / 创建时间 / 修改时间 | `==` `!=` `>` `<` `isnull` `notnull` | 最多 1 个元素；需符合接口支持的日期格式 |
| 公式 | `==` `!=` `>` `>=` `<` `<=` `contains` `notcontains` `isnull` `notnull` | 最多 1 个元素 |

### 筛选示例

```bash
# 1. 单条件筛选（状态等于"进行中"）
--filter '{"conjunction":"and","conditions":[{"columnId":3,"operator":"==","filterValue":["进行中"]}]}'

# 2. 多条件筛选（AND）
--filter '{"conjunction":"and","conditions":[
  {"columnId":3,"operator":"==","filterValue":["进行中"]},
  {"columnId":2,"operator":">","filterValue":["50"]}
]}'

# 3. 多条件筛选（OR）
--filter '{"conjunction":"or","conditions":[
  {"columnId":3,"operator":"==","filterValue":["待处理"]},
  {"columnId":3,"operator":"==","filterValue":["进行中"]}
]}'

# 4. 文本包含筛选
--filter '{"conjunction":"and","conditions":[{"columnId":1,"operator":"contains","filterValue":["项目"]}]}'

# 5. 日期范围筛选（日期列使用 > / <，值传字符串）
--filter '{"conjunction":"and","conditions":[
  {"columnId":7,"operator":">","filterValue":["2025-06-01"]},
  {"columnId":7,"operator":"<","filterValue":["2025-07-01"]}
]}'

# 6. 空值筛选（isnull / notnull 必须传空数组）
--filter '{"conjunction":"and","conditions":[{"columnId":1,"operator":"isnull","filterValue":[]}]}'

# 7. 非空筛选
--filter '{"conjunction":"and","conditions":[{"columnId":1,"operator":"notnull","filterValue":[]}]}'

# 8. 不包含筛选
--filter '{"conjunction":"and","conditions":[{"columnId":1,"operator":"notcontains","filterValue":["项目"]}]}'

# 9. 嵌套一层 children
--filter '{"conjunction":"and","conditions":[{"columnId":1,"operator":"!=","filterValue":["哈哈1"]}],"children":[{"conjunction":"or","conditions":[{"columnId":2,"operator":">","filterValue":["123"]},{"columnId":3,"operator":"notnull","filterValue":[]}]}]}'
```

## 排序配置格式 (SortConfig)

```typescript
[
  {
    columnId: 2,          // 列 ID
    desc: true            // true=降序, false=升序
  }
]
```

### 排序示例

```bash
# 1. 单列排序（按进度降序）
--sort '[{"columnId":4,"desc":true}]'

# 2. 多列排序（先按状态升序，再按进度降序）
--sort '[{"columnId":3,"desc":false},{"columnId":4,"desc":true}]'
```

## 常见错误和解决方案

### 1. 列类型不匹配

**错误**：将字符串传给数字列
```json
// ❌ 错误
[["100"]]  // 数字列接收字符串

// ✅ 正确
[[100]]    // 数字列接收数字
```

### 2. empId 类型错误

**错误**：empId 使用字符串类型
```json
// ❌ 错误（在富文本中）
{"type":"mention","value":"@张三","empId":"2015739"}

// ✅ 正确
{"type":"mention","value":"@张三","empId":2015739}
```

### 3. 富文本嵌套层级

**错误**：富文本数据嵌套层级错误
```json
// ❌ 错误（缺少外层数组）
{"type":"text","value":"文本"}

// ✅ 正确
[{"type":"text","value":"文本"}]
```

### 4. 二维数组结构

**错误**：一维数组而非二维数组
```json
// ❌ 错误
["值1", "值2"]

// ✅ 正确（单行数据也要用二维数组）
[["值1", "值2"]]
```

### 5. 日期格式

**错误**：使用日期字符串而非时间戳
```json
// ❌ 错误
[["2024-03-09"]]

// ✅ 正确（使用毫秒时间戳）
[[1710000000000]]  // 2024-03-09
```

## 数据转换工具函数

### JavaScript/TypeScript

```typescript
// 日期转时间戳
function dateToTimestamp(dateStr: string): number {
  return new Date(dateStr).getTime();
}

// 字符串转富文本
function textToRichText(text: string): IRichTextNode[] {
  return [{ type: "text", value: text }];
}

// 创建超链接富文本
function createLink(text: string, url: string): IRichTextNode[] {
  return [
    { type: "text", value: "查看" },
    { type: "link", value: text, link: url }
  ];
}

// empId 数组转换
function parseEmpIds(input: string | number | (string | number)[]): number[] {
  if (Array.isArray(input)) {
    return input.map(id => typeof id === 'string' ? parseInt(id) : id);
  }
  return [typeof input === 'string' ? parseInt(input) : input];
}
```

### Bash

```bash
# 获取当前时间戳（毫秒）
timestamp=$(date +%s)000

# 格式化 JSON 数据
data=$(cat <<EOF
[
  ["项目A", "张三", "进行中", 75],
  ["项目B", "李四", "待处理", 0]
]
EOF
)

# 转义 JSON 用于命令行
escaped_data=$(echo "$data" | jq -c .)
```

## 批量操作模式

### 批量新增

```bash
# 准备数据文件 data.json
cat > data.json <<EOF
[
  ["项目A", "张三", "进行中", 75, 1710000000000],   // 日期: 2024-03-09
  ["项目B", "李四", "待处理", 0, 1710086400000],    // 日期: 2024-03-10
  ["项目C", "王五", "已完成", 100, 1709827200000]   // 日期: 2024-03-07
]
EOF

# 批量新增
oa-skills citadel-database addData \
  --tableId "2750248577" \
  --columnIds "1,2,3,4,5" \
  --data "$(cat data.json)"
```

### 批量更新

```bash
# 1. 查询需要更新的行
oa-skills citadel-database queryTableData \
  --tableId "2750248577" \
  --filter '{"conjunction":"and","conditions":[{"columnId":3,"operator":"==","filterValue":["待处理"]}]}' \
  --raw > rows_to_update.json

# 2. 提取 rowIds（使用 jq）
rowIds=$(jq -r '.rows[].rowId' rows_to_update.json | tr '\n' ',' | sed 's/,$//')

# 3. 批量更新状态
oa-skills citadel-database updateData \
  --tableId "2750248577" \
  --rowIds "$rowIds" \
  --columnIds "3" \
  --data '[["进行中"]]'  # 所有行都更新为"进行中"
```

## API 响应示例

### 成功响应

```json
{
  "success": true,
  "stepVersion": 5
}
```

### 错误响应

```json
{
  "code": 400,
  "message": "列ID 999 不存在于表格元数据中。可用的列ID: 1, 2, 3, 4, 5"
}
```

### 数据查询响应（完整示例）

```json
{
  "rows": [
    {
      "rowId": 184484716,
      "cellData": [
        {
          "colId": 1,
          "textCellValue": [
            { "type": "text", "value": "查看" },
            { "type": "link", "value": "项目文档", "link": "https://km.sankuai.com/page/123" }
          ]
        },
        {
          "colId": 2,
          "textCellValue": [
            { "type": "mention", "value": "@张三", "empId": 2015739 }
          ]
        },
        {
          "colId": 3,
          "selectCellValue": "进行中"
        },
        {
          "colId": 4,
          "numberCellValue": 75
        },
        {
          "colId": 5,
          "dateCellValue": 1710000000000  // 2024-03-09
        }
      ],
      "createdBy": 2015738,
      "createdTime": 1773884148000,     // 2026-03-19
      "lastModifiedBy": 2015738,
      "lastModifiedTime": 1773884148000  // 2026-03-19
    }
  ],
  "total": 1,
  "pageToken": "next_page_token_here"
}
```
