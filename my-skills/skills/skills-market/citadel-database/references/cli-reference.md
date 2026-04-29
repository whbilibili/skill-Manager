# CLI 命令参考

完整参数说明，基于 `src/citadel-database/cli.ts` 实际实现。

## 目录

- [CLI 命令参考](#cli-命令参考)
  - [目录](#目录)
  - [通用选项](#通用选项)
  - [createDatabase](#createdatabase)
  - [createTable](#createtable)
  - [copyTable](#copytable)
    - [场景说明](#场景说明)
  - [listTables](#listtables)
  - [getTableMeta](#gettablemeta)
  - [queryTableData](#querytabledata)
  - [addData](#adddata)
  - [updateData](#updatedata)
  - [deleteData](#deletedata)
  - [queryDeletedTables](#querydeletedtables)
  - [deleteTable](#deletetable)
  - [recoveryTable](#recoverytable)
  - [renameTable](#renametable)
  - [sortTable](#sorttable)
  - [addTableColumns](#addtablecolumns)
  - [updateColumnConfig](#updatecolumnconfig)
  - [copyTable](#copytable-1)
    - [使用场景](#使用场景)
    - [使用示例](#使用示例)
    - [注意事项](#注意事项)
  - [列类型说明](#列类型说明)
    - [富文本节点类型](#富文本节点类型)
  - [文件上传工作流](#文件上传工作流)
    - [⭐ 推荐方式：uploadFileAndAddData（一步完成）](#-推荐方式uploadfileandadddata一步完成)
    - [🔧 低层 API：uploadFileByS3Url + addData（分步操作）](#-低层-apiuploadfilebys3url--adddata分步操作)
  - [环境变量](#环境变量)
  - [示例工作流](#示例工作流)
    - [1. 创建完整的项目管理表格](#1-创建完整的项目管理表格)
    - [2. 数据迁移和备份](#2-数据迁移和备份)
    - [3. 附件列数据操作](#3-附件列数据操作)
    - [4. 使用 Token 认证的批量操作](#4-使用-token-认证的批量操作)
  - [getUserInfo - 获取用户信息（账号转换）](#getuserinfo---获取用户信息账号转换)
    - [功能说明](#功能说明)
    - [使用场景](#使用场景-1)
    - [参数说明](#参数说明)
    - [返回字段](#返回字段)
    - [使用示例](#使用示例-1)
      - [1. 查询单个用户信息](#1-查询单个用户信息)
      - [2. 批量查询多个用户](#2-批量查询多个用户)
      - [3. 输出原始 JSON（用于脚本处理）](#3-输出原始-json用于脚本处理)
      - [4. 与人员列配合使用（完整工作流）](#4-与人员列配合使用完整工作流)
      - [5. 批量处理（从文件读取 MIS 列表）](#5-批量处理从文件读取-mis-列表)
    - [注意事项](#注意事项-1)
    - [API 说明](#api-说明)
  - [queryUserIdentityByUid - 通过 UID 查询 MIS/empId](#queryuseridentitybyuid---通过-uid-查询-misempid)
    - [功能说明](#功能说明-1)
    - [使用场景](#使用场景-2)
    - [参数说明](#参数说明-1)
    - [返回字段](#返回字段-1)
    - [使用示例](#使用示例-2)
    - [注意事项](#注意事项-2)
  - [getTableMeta 实用技巧：jq 提取列配置](#gettablemeta-实用技巧jq-提取列配置)
    - [提取单选/多选列的可选项](#提取单选多选列的可选项)
    - [检查人员列是否支持多人](#检查人员列是否支持多人)
    - [查看数字/日期列的格式化规则](#查看数字日期列的格式化规则)
    - [获取所有列 ID 和名称（用于构造 --columnIds）](#获取所有列-id-和名称用于构造---columnids)

## 通用选项

| 选项 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `--mis <mis>` | string | 从 `~/.config/clawdgw.json` 读取 | 用户 MIS 号，用于认证 |
| `--raw` | flag | false | 输出原始 JSON 响应 |
| `--clear-cache` | flag | — | 清除认证缓存后退出，不需要指定命令 |
| `--force-ciba` | flag | false | 强制走 CIBA 认证（仅在认证异常时兜底使用，正常不需要添加） |

## createDatabase

创建多维表格文档（包含文档和第一个数据表）。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--contentTitle` | string | ❌ | — | 文档标题，可为空 |
| `--tableTitle` | string | ❌ | — | 数据表标题，可为空 |
| `--parentId` | string | ❌ | — | 父文档 ID |
| `--spaceId` | string | ❌ | — | 空间 ID |
| `--templateId` | string | ❌ | — | 模板 ID |
| `--columnMeta` | JSON | ❌ | — | 列定义 JSON 数组 |
| `--sourceContentId` | string | ❌ | — | 复制来源文档 ID |
| `--keepData` | boolean | ❌ | false | 复制时是否保留数据 |

```bash
# 创建空白多维表格
oa-skills citadel-database createDatabase \
  --contentTitle "项目管理" \
  --tableTitle "任务列表"

# 创建带列定义的表格
oa-skills citadel-database createDatabase \
  --contentTitle "项目管理" \
  --tableTitle "任务列表" \
  --columnMeta '[
    {"columnName":"项目名称","columnType":1},
    {"columnName":"负责人","columnType":1},
    {"columnName":"状态","columnType":3,"selectOptions":["待处理","进行中","已完成"]}
  ]'

# 复制已有多维表格文档（仅复制结构，不含数据）
oa-skills citadel-database createDatabase \
  --contentTitle "项目管理（副本）" \
  --sourceContentId "2750138424"

# 复制已有多维表格文档（同时保留数据）
oa-skills citadel-database createDatabase \
  --contentTitle "项目管理（副本）" \
  --sourceContentId "2750138424" \
  --keepData true
```

**输出**：文档 ID、表格 ID，以及后端实际返回的非空标题（若有）。

## createTable

在现有文档中创建新的数据表，表格标题可为空。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--contentId` | string | ✅ | — | 文档 ID |
| `--tableTitle` | string | ✅ | — | 数据表标题 |
| `--columnMeta` | JSON | ❌* | — | 列定义 JSON 数组 |
| `--columnMetaFile` | string | ❌ | — | 从文件读取 columnMeta 参数（文件包含列定义数组） |
| `--sourceTableId` | string | ❌ | — | 复制来源表格 ID |
| `--keepData` | boolean | ❌ | false | 复制时是否保留数据 |

\* `--columnMeta` 和 `--columnMetaFile` 二选一，**优先使用 `--columnMetaFile`**

```bash
# 创建新表格
oa-skills citadel-database createTable \
  --contentId "2750248577" \
  --tableTitle "任务表" \
  --columnMeta '[{"columnName":"任务名","columnType":1}]'

# 从文件读取列定义（推荐用于复杂的列结构）
cat > columns.json << 'EOF'
[
  {
    "columnName": "姓名",
    "columnType": 1
  },
  {
    "columnName": "年龄",
    "columnType": 2
  },
  {
    "columnName": "状态",
    "columnType": 3,
    "selectOptions": ["在职", "离职", "休假"]
  },
  {
    "columnName": "负责人",
    "columnType": 4
  }
]
EOF

oa-skills citadel-database createTable \
  --contentId "2750248577" \
  --tableTitle "员工信息表" \
  --columnMetaFile columns.json
```

**💡 文件参数优先级**：当同时提供 `--columnMeta` 和 `--columnMetaFile` 时，使用 `--columnMetaFile` 中的数据。

**输出**：表格 ID，以及后端实际返回的非空标题/视图 ID/表格类型（若有）。

## copyTable

复制数据表到指定目标文档或表格。底层 `type` 仅支持：`3=学城文档`、`4=多维表格`；不传 `--targetType` 时会自动识别。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--sourceTableId` | string | ✅ | — | 源表格 ID |
| `--targetParentId` | string | ✅ | — | 目标文档/表格 ID |
| `--targetType` | number | ❌ | 自动识别 | 目标类型：`3=学城文档`、`4=多维表格` |
| `--columnIds` | string/JSON | ❌ | — | 要复制的列 ID（逗号分隔或 JSON 数组） |
| `--rowIds` | string/JSON | ❌ | — | 要复制的行 ID（逗号分隔或 JSON 数组） |
| `--stepVersion` | number | ❌ | — | 步进版本号 |
| `--viewIds` | string/JSON | ❌ | [1000] | 视图 ID 列表（逗号分隔或 JSON 数组，未提供时默认为 [1000]） |

```bash
# 复制整个表格
oa-skills citadel-database copyTable \
  --sourceTableId "2750248577" \
  --targetParentId "2750138424"

# 复制指定列和行
oa-skills citadel-database copyTable \
  --sourceTableId "2750248577" \
  --targetParentId "2750138424" \
  --columnIds "1,2,3" \
  --rowIds "100,101,102"
```

**输出**：新表格 ID、标题、视图 ID、表格类型。

> 说明：不传 `--targetType` 时，CLI 会优先自动识别常见目标类型（`3=学城文档`、`4=多维表格`）；若目标是模板，请显式传 `--targetType 2` 或 `--targetType 5`。

### 场景说明

**场景 A：复制整个多维表格文档**（使用 `createDatabase`，见上方章节）

```bash
# 仅复制结构
oa-skills citadel-database createDatabase \
  --contentTitle "新文档标题" \
  --sourceContentId "<原多维表格 contentId>"

# 同时保留数据
oa-skills citadel-database createDatabase \
  --contentTitle "新文档标题" \
  --sourceContentId "<原多维表格 contentId>" \
  --keepData true
```

**场景 B：将数据表复制到学城文档**（目标是已有学城文档，需额外插入 `:::xtable`）

```bash
# 步骤 1：复制数据表到目标学城文档
oa-skills citadel-database copyTable \
  --sourceTableId "<源 tableId>" \
  --targetParentId "<目标学城文档 contentId>" \
  --targetType 3
# → 得到新 tableId

# 步骤 2：将表格嵌入到学城文档正文（citadel skill）
# CitadelMD 中使用以下语法：
# :::xtable{xtableId="<新 tableId>"}:::
oa-skills citadel updateDocumentByMd \
  --contentId "<目标学城文档 contentId>" \
  --file <citadelmd文件路径>
```

**场景 C：复制数据表到另一个多维表格文档**

```bash
oa-skills citadel-database copyTable \
  --sourceTableId "<源 tableId>" \
  --targetParentId "<目标多维表格 contentId>" \
  --targetType 4
```

## listTables

查询文档下的所有数据表。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--contentId` | string | ✅ | — | 文档 ID |

```bash
oa-skills citadel-database listTables --contentId "2750138424"
```

**输出**：表格列表（表格标题、表格 ID）。

## getTableMeta

查询表格元数据（列信息）。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--tableId` | string | ✅ | — | 表格 ID |

```bash
oa-skills citadel-database getTableMeta --tableId "2750248577"
```

**输出**：列信息列表（列名、列 ID、列类型、列配置）。

## queryTableData

查询表格数据，支持筛选、排序和分页。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--tableId` | string | ✅ | — | 表格 ID |
| `--columnIds` | string/JSON | ❌ | 前10列 | 要查询的列 ID（逗号分隔或 JSON 数组） |
| `--filter` | JSON | ❌ | — | 筛选条件 |
| `--sort` | JSON | ❌ | — | 排序配置，格式：`[{"columnId": 1, "desc": false}]`，**注意是 `desc` 字段（boolean），不是 `order` 字段** |
| `--pageSize` | number | ❌ | 100 | 每页返回的行数 |
| `--pageToken` | string | ❌ | — | 分页令牌（指定后只取该单页，不自动翻页） |
| `--max-pages` | number | ❌ | — | 最多自动翻页页数（不指定时获取全量数据） |

```bash
# 基础查询
oa-skills citadel-database queryTableData \
  --tableId "2750248577"

# 查询指定列
oa-skills citadel-database queryTableData \
  --tableId "2750248577" \
  --columnIds "1,2,3"

# 带筛选和排序
oa-skills citadel-database queryTableData \
  --tableId "2750248577" \
  --columnIds "1,2,3" \
  --filter '{"conjunction":"and","conditions":[{"columnId":1,"operator":"==","filterValue":["值"]}]}' \
  --sort '[{"columnId":2,"desc":true}]'

# 只取前 2 页（每页 100 行，最多 200 行），不获取全量数据
oa-skills citadel-database queryTableData \
  --tableId "2750248577" \
  --max-pages 2
```

**输出**：总行数、返回行数、数据行（包含 rowId 和 cellData）。

## addData

向表格添加新数据（使用二维数组格式）。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--tableId` | string | ✅ | — | 表格 ID |
| `--columnIds` | string/JSON | ✅ | — | 列 ID（逗号分隔或 JSON 数组） |
| `--data` | JSON | ✅* | — | 二维数组格式的数据 `[["值1","值2"]]` |
| `--file` | string | ❌ | — | 从文件读取 data 参数（文件包含 JSON 数组） |

\* `--data` 和 `--file` 二选一，**优先使用 `--file`**

```bash
# 添加单行数据
oa-skills citadel-database addData \
  --tableId "2750248577" \
  --columnIds "1,2,3" \
  --data '[["张三", 25, true]]'

# 添加多行数据
oa-skills citadel-database addData \
  --tableId "2750248577" \
  --columnIds "1,2,3" \
  --data '[["张三", 25, true], ["李四", 30, false]]'

# 富文本格式（超链接）
oa-skills citadel-database addData \
  --tableId "2750248577" \
  --columnIds "1" \
  --data '[[
    [
      {"type":"text","value":"查看"},
      {"type":"link","value":"文档","link":"https://km.sankuai.com/page/123"}
    ]
  ]]'

# 从文件读取大数据量（推荐用于 > 10 行的数据）
cat > data.json << 'EOF'
[
  ["员工001", 25, true, "2024-01-15"],
  ["员工002", 30, false, "2024-01-16"],
  ["员工003", 28, true, "2024-01-17"]
]
EOF

oa-skills citadel-database addData \
  --tableId "2750248577" \
  --columnIds "1,2,3,4" \
  --file data.json
```

**⚠️ 自动分页**：如果 `data` 超过 500 行，系统会自动分批处理，避免 API 请求失败。

**💡 文件参数优先级**：当同时提供 `--data` 和 `--file` 时，使用 `--file` 中的数据。

**输出**：成功状态、版本号、新增行的 rowIds。

## updateData

更新表格中的现有数据。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--tableId` | string | ✅ | — | 表格 ID |
| `--rowIds` | string/JSON | ✅* | — | 行 ID（逗号分隔或 JSON 数组） |
| `--rowIdsFile` | string | ❌ | — | 从文件读取 rowIds 参数（文件包含 JSON 数组） |
| `--columnIds` | string/JSON | ✅ | — | 列 ID（逗号分隔或 JSON 数组） |
| `--data` | JSON | ✅* | — | 二维数组格式的数据 |
| `--file` | string | ❌ | — | 从文件读取 data 参数（文件包含 JSON 数组） |

\* `--rowIds` 和 `--rowIdsFile` 二选一，`--data` 和 `--file` 二选一，**文件参数优先**

```bash
# 更新单行
oa-skills citadel-database updateData \
  --tableId "2750248577" \
  --rowIds "123456" \
  --columnIds "1,2" \
  --data '[["新值1", "新值2"]]'

# 更新多行
oa-skills citadel-database updateData \
  --tableId "2750248577" \
  --rowIds "123456,123457" \
  --columnIds "1,2" \
  --data '[["新值1", "新值2"], ["新值3", "新值4"]]'

# 从文件读取 rowIds 和 data（推荐用于大批量更新）
cat > rowIds.json << 'EOF'
["row_123", "row_124", "row_125"]
EOF

cat > update-data.json << 'EOF'
[
  ["新值1", 100],
  ["新值2", 200],
  ["新值3", 300]
]
EOF

oa-skills citadel-database updateData \
  --tableId "2750248577" \
  --columnIds "1,2" \
  --rowIdsFile rowIds.json \
  --file update-data.json
```

**⚠️ 自动分页**：如果 `data` 超过 500 行，系统会自动分批处理，避免 API 请求失败。

**💡 文件参数优先级**：
- 当同时提供 `--rowIds` 和 `--rowIdsFile` 时，使用 `--rowIdsFile`
- 当同时提供 `--data` 和 `--file` 时，使用 `--file`

**输出**：成功状态、版本号、更新行数。

## deleteData

删除表格中的数据行。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--tableId` | string | ✅ | — | 表格 ID |
| `--rowIds` | string/JSON | ✅* | — | 行 ID（逗号分隔或 JSON 数组） |
| `--rowIdsFile` | string | ❌ | — | 从文件读取 rowIds 参数（文件包含 JSON 数组） |

\* `--rowIds` 和 `--rowIdsFile` 二选一，**优先使用 `--rowIdsFile`**

```bash
# 删除单行
oa-skills citadel-database deleteData \
  --tableId "2750248577" \
  --rowIds "123456"

# 删除多行
oa-skills citadel-database deleteData \
  --tableId "2750248577" \
  --rowIds "123456,123457,123458"

# 从文件读取要删除的行 ID（推荐用于大批量删除）
cat > delete-rows.json << 'EOF'
["row_123", "row_124", "row_125", "row_126"]
EOF

oa-skills citadel-database deleteData \
  --tableId "2750248577" \
  --rowIdsFile delete-rows.json
```

**💡 文件参数优先级**：当同时提供 `--rowIds` 和 `--rowIdsFile` 时，使用 `--rowIdsFile` 中的数据。

**输出**：成功状态、版本号。

## queryDeletedTables

查询已删除的数据表和仪表盘（回收站）。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--contentId` | string | ✅ | — | 文档 ID |
| `--pageSize` | number | ❌ | 20 | 每页返回的数量 |
| `--order` | string | ❌ | desc | 排序方式（asc/desc） |

```bash
oa-skills citadel-database queryDeletedTables \
  --contentId "2750138424" \
  --pageSize 20 \
  --order desc
```

**输出**：已删除表格列表（表格标题、表格 ID、删除时间）。

## deleteTable

删除数据表或仪表盘（移至回收站）。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--tableId` | string | ✅ | — | 表格 ID |

```bash
oa-skills citadel-database deleteTable --tableId "2750248577"
```

**输出**：成功状态、表格 ID。

## recoveryTable

从回收站恢复已删除的数据表或仪表盘。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--tableId` | string | ✅ | — | 表格 ID |
| `--contentId` | string | ❌ | — | 指定恢复到的文档 ID |

```bash
# 恢复到原文档
oa-skills citadel-database recoveryTable --tableId "2750248577"

# 恢复到指定文档
oa-skills citadel-database recoveryTable \
  --tableId "2750248577" \
  --contentId "2750138424"
```

**输出**：成功状态、表格 ID。

## renameTable

重命名数据表。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--tableId` | string | ✅ | — | 表格 ID |
| `--title` | string | ✅ | — | 新的表格标题 |

```bash
oa-skills citadel-database renameTable \
  --tableId "2750248577" \
  --title "新的表格名称"
```

**输出**：成功状态、表格 ID、新标题。

## sortTable

调整数据表在文档中的位置（排序）。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--tableId` | string | ✅ | — | 表格 ID |
| `--to` | number | ✅ | — | 目标位置索引（从 1 开始） |

```bash
# 将表格移动到第 2 个位置
oa-skills citadel-database sortTable \
  --tableId "2750248577" \
  --to 2
```

**输出**：成功状态、表格 ID、新位置。

## copyTable

将一个数据表（包括结构和数据）复制到指定的目标文档或表格下。底层 `type` 仅支持：`3=学城文档`、`4=多维表格`。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--sourceTableId` | string | ✅ | — | 源多维表格 ID |
| `--targetParentId` | string | ✅ | — | 复制到的目标文档/表格 ID |
| `--targetType` | number | ❌ | 自动识别 | 目标类型：`3=学城文档`、`4=多维表格` |
| `--columnIds` | string/JSON | ❌ | 所有列 | 复制的列 ID 列表（逗号分隔或 JSON 数组） |
| `--rowIds` | string/JSON | ❌ | 所有行 | 复制的行 ID 列表（逗号分隔或 JSON 数组） |
| `--stepVersion` | number | ❌ | — | 复制那一刻的 step 版本（用于保证数据一致性） |
| `--viewIds` | string/JSON | ❌ | [1000] | 视图 ID 列表（逗号分隔或 JSON 数组） |

### 使用场景

- ✅ 复制表格到另一个文档
- ✅ 在模板和文档之间复制表格
- ✅ 选择性复制特定列和行
- ✅ 按指定的 step 版本复制（保证数据一致性）

### 使用示例

```bash
# 基础用法：复制整个表格到文档
oa-skills citadel-database copyTable \
  --sourceTableId "2750248577" \
  --targetParentId "2750138424"

# 目标是学城文档模板时，显式指定 targetType=2
oa-skills citadel-database copyTable \
  --sourceTableId "2750248577" \
  --targetParentId "2750138424" \
  --targetType 2

# 只复制特定列
oa-skills citadel-database copyTable \
  --sourceTableId "2750248577" \
  --targetParentId "2750138424" \
  --columnIds "[1,2,3]"

# 只复制特定行（viewIds 未提供时自动使用默认值 [1000]）
oa-skills citadel-database copyTable \
  --sourceTableId "2750248577" \
  --targetParentId "2750138424" \
  --rowIds "[100,101,102]"

# 复制特定列和行（带 step 版本和视图 ID）
oa-skills citadel-database copyTable \
  --sourceTableId "2750248577" \
  --targetParentId "2750138424" \
  --columnIds "[1,2,3]" \
  --rowIds "[100,101,102]" \
  --stepVersion 12345 \
  --viewIds "[1000]"
```

### 注意事项

- 如果目标是模板，必须显式传 `--targetType 2`（学城文档模板）或 `--targetType 5`（多维表格模板）；仅靠 `targetParentId` 无法稳定自动识别模板类型
- 如果目标是普通学城文档或多维表格，不传 `--targetType` 时会自动识别常见类型（`3` / `4`）

- `columnIds` 和 `rowIds` 应使用 JSON 数组格式：`"[1,2,3]"` 或逗号分隔：`"1,2,3"`
- 需要对源表格有浏览权限，对目标文档有编辑权限
- 复制后会生成新的表格 ID 和视图 ID
- 如果不指定 `columnIds`，将复制所有列；如果不指定 `rowIds`，将复制所有行
- `viewIds` 参数未提供时会自动使用默认值 `[1000]`（通常为表格的默认视图）

**输出**：成功状态、新表格 ID、新视图 ID、复制的行数。

## addTableColumns

为数据表新增列。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--tableId` | string | ✅ | — | 表格 ID |
| `--columnMetas`| JSON | ✅ | — | 新增列信息的 JSON 数组 |

### `columnMetas` 格式说明
JSON 数组，每一个元素代表一个需要新增的列，包含以下属性：
- `columnName`: string (必填) 列名,长度限制 1-100 字符
- `columnType`: number (必填) 列类型，取值范围：
  - `1`: 文本
  - `2`: 数字
  - `3`: 单选
  - `4`: 人员
  - `5`: 多选
  - `6`: 附件
  - `7`: 日期
  - `8`: 货币
  - `201`: 创建人
  - `202`: 创建时间
  - `203`: 最后修改人
  - `204`: 最后修改时间
- `columnConfig`: object (可选) 列的额外配置。根据列类型不同，支持以下配置：
  - **选项配置（单选 columnType:3、多选 columnType:5）**：`{"options": ["选项1", "选项2"]}`
  - **人员列是否支持多选（人员 columnType:4）**：`{"multiple": true}`（默认 `false`）
  - **日期格式化（日期 columnType:7）**：`{"formatter": "YYYY-MM-DD"}`
    - 可选值：`YYYY/MM/DD`, `YYYY/MM/DD HH:mm`, `YYYY-MM-DD`, `YYYY-MM-DD HH:mm`, `MM-DD`, `MM/DD/YYYY`, `DD/MM/YYYY`
  - **数字格式化（数字 columnType:2、货币 columnType :8）**：`{"formatter": "0.00"}`
    - 可选值：`""` (无格式), `"0"` (整数), `"0.0"`, `"0.00"`, `"0.000"`, `"0.0000"`, `"0,0"`, `"0,0.0"`, `"0,0.00"`, `"0,0.000"`, `"0,0.0000"`, `"0%"`, `"0.00%"`
  - **货币代码（货币 columnType:8）**：`{"currencyCode": "CNY"}`
    - `currencyCode` 可选值：`CNY`, `USD`, `EUR`, `GBP`, `AED`, `AUD`, `BHD`, `BRL`, `CAD`, `CHF`, `HKD`, `INR`, `IDR`, `JPY`, `KRW`, `KWD`, `MOP`, `MXN`, `MYR`, `OMR`, `PHP`, `PLN`, `QAR`, `RUB`, `SAR`, `SGD`, `THB`, `TRY`, `TWD`, `VND`

```bash
# 新增一个普通文本列、带选项的单选列、以及日期列和货币列
oa-skills citadel-database addTableColumns \
  --tableId "1234567890" \
  --columnMetas '[
  {"columnName": "备注", "columnType": 1}, 
  {"columnName": "状态", "columnType": 3, "columnConfig": {"options": ["未开始", "进行中"]}}, 
  {"columnName": "日期", "columnType": 7, "columnConfig": {"formatter": "YYYY-MM-DD"}}, 
  {"columnName": "金额", "columnType": 8, "columnConfig": {"currencyCode": "CNY"}}]
'
```

**输出**：成功状态、版本号、新列的 ID 列表。

## updateColumnConfig

修改数据表中已有列的配置，当前只支持修改列名，暂不支持修改列类型和列配置。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--tableId` | string | ✅ | — | 表格 ID |
| `--columnId` | string | ✅ | — | 列 ID |
| `--columnName`| string | ❌ | — | 要修改成的新列名 |

```bash
# 重命名已有列
oa-skills citadel-database updateColumnConfig \
  --tableId "1234567890" \
  --columnId "3" \
  --columnName "新状态名"
```

**输出**：成功状态、版本号。

## 列类型说明

| 类型ID | 类型名称 | 数据格式 | 说明 |
|---|---|---|---|
| 1 | 文本（富文本） | `IRichTextNode[]` | 支持纯文本、超链接、@提及、段落节点 |
| 2 | 数字 | `number` | 数值类型 |
| 3 | 单选 | `string` | 单选选项的值 |
| 4 | 人员 | `number[]` | empId 数组 |
| 5 | 多选 | `string[]` | 多选选项的值数组 |
| 6 | 附件 | `string[]` | JSON 字符串数组（每个元素为 `JSON.stringify({attachmentId, name, url, ...})`） |
| 7 | 日期 | `number` | 毫秒时间戳 |
| 8 | 货币 | `number` | 数值类型 |
| 9 | 公式 | 只读 | 不支持写入 |
| 10 | 查找引用 | 只读 | 不支持写入；查询时返回引用值的文本表示 |

### 富文本节点类型

```typescript
// 纯文本
{ type: "text", value: "文本内容" }

// 超链接
{ type: "link", value: "显示文字", link: "<链接URL>" }

// @提及（value 必须以 @ 开头）
{ type: "mention", value: "@用户名", empId: 2015739 }

// 段落（发送前会统一补成 value: " "）
{ type: "paragraph", value: " " }
```

## 文件上传工作流

向附件列添加文件有两种方式：推荐使用 `uploadFileAndAddData` 一步完成，或使用低层 API `uploadFileByS3Url` 分步操作。

### ⭐ 推荐方式：uploadFileAndAddData（一步完成）

适用场景：上传本地文件并直接写入表格，最常用。

```bash
# 前提：已知 contentId、tableId 和附件列的 columnId

# 步骤 1（可选）：查看表格元数据确认附件列 ID
oa-skills citadel-database getTableMeta --tableId "2752934848"

# 步骤 2：上传文件并写入数据（一步完成）
oa-skills citadel-database uploadFileAndAddData \
  --contentId "2752755021" \
  --tableId "2752934848" \
  --file "/path/to/document.pdf" \
  --columnIds "1,2,3" \
  --data '[["项目需求文档", null, "2024-03-09"]]'
```

**说明**：
- `--file`：本地文件路径（支持图片、PDF、Office 文档等）
- `--columnIds`：要写入数据的所有列 ID（含附件列）
- `--data`：二维数组，附件列位置传 `null` 或占位值，系统自动替换为上传后的附件信息
- 返回 `attachmentId` 和文件 URL，可直接用于后续查询

### 🔧 低层 API：uploadFileByS3Url + addData（分步操作）

适用场景：
- 文件已在 S3 存储，需要关联到多维表格
- 批量处理工作流（避免重复上传）
- 测试和调试文件上传功能

```bash
# 步骤 1: 通过 S3 URL 上传文件（fileName 可选，未提供时从 URL 自动提取）
oa-skills citadel-database uploadFileByS3Url \
  --s3Url "https://km.sankuai.com/api/file/cdn/xxx/file.pdf" \
  --fileName "document.pdf" \
  --contentId "2752755021"

# 输出: { attachmentId: 228822745910, name: "document.pdf", url: "https://..." }

# 步骤 2: 使用返回的 attachmentId 和 url 写入附件列
oa-skills citadel-database addData \
  --tableId "2752934848" \
  --columnIds "1,2" \
  --data '[[
    "项目需求文档",
    JSON.stringify({attachmentId: 228822745910, name: "document.pdf", url: "https://km.sankuai.com/api/file/cdn/xxx/228822745910"})
  ]]'
```

**注意事项**：
- `uploadFileByS3Url` 的 `--s3Url` 必须是有效的 S3 文件 URL
- 如果目标是模板，必须显式传 `--targetType 2`
- 需要对源表格有浏览权限，对目标文档有编辑权限

## 环境变量

| 变量名 | 说明 |
|---|---|
| `USER_ACCESS_TOKEN` | 用于 `${user_access_token}` 占位符的用户身份 token |
| `APP_ACCESS_TOKEN` | 用于 `${app_access_token}` 占位符的应用身份 token |
| `NO_CHECK_VERSION` | 设置为 `"true"` 时跳过 Node.js 版本检查 |

## 示例工作流

### 1. 创建完整的项目管理表格

```bash
# 步骤 1: 创建文档和表格
oa-skills citadel-database createDatabase \
  --contentTitle "项目管理系统" \
  --tableTitle "项目列表" \
  --columnMeta '[
    {"columnName":"项目名称","columnType":1},
    {"columnName":"负责人","columnType":1},
    {"columnName":"状态","columnType":3,"selectOptions":["未开始","进行中","已完成","暂停"]},
    {"columnName":"优先级","columnType":3,"selectOptions":["高","中","低"]},
    {"columnName":"进度","columnType":2},
    {"columnName":"开始日期","columnType":7},
    {"columnName":"截止日期","columnType":7}
  ]'

# 假设返回 tableId: 2750248577

# 步骤 2: 添加数据
oa-skills citadel-database addData \
  --tableId "2750248577" \
  --columnIds "1,2,3,4,5,6,7" \
  --data '[
    ["项目A", "张三", "进行中", "高", 75, 1710000000000, 1712592000000],  // 开始: 2024-03-09, 截止: 2024-04-08
    ["项目B", "李四", "未开始", "中", 0, 1710000000000, 1715088000000]  // 开始: 2024-03-09, 截止: 2024-05-07
  ]'

# 步骤 3: 查询数据
oa-skills citadel-database queryTableData \
  --tableId "2750248577" \
  --filter '{"conjunction":"and","conditions":[{"columnId":3,"operator":"==","filterValue":["进行中"]}]}'
```

### 2. 数据迁移和备份

```bash
# 步骤 1: 查询源表格数据
oa-skills citadel-database queryTableData \
  --tableId "2750248577" \
  --raw > backup.json

# 步骤 2: 复制表格结构到新文档
oa-skills citadel-database copyTable \
  --sourceTableId "2750248577" \
  --targetParentId "2750999999"

# 步骤 3: 从备份恢复数据（需要解析 backup.json 并转换格式）
```

### 3. 附件列数据操作

```bash
# 步骤 1: 创建包含附件列的表格
oa-skills citadel-database createDatabase \
  --contentTitle "文档管理" \
  --tableTitle "文档列表" \
  --columnMeta '[
    {"columnName":"文档标题","columnType":1},
    {"columnName":"附件","columnType":6},
    {"columnName":"上传日期","columnType":7}
  ]'

# 假设返回 tableId: 2750248577

# 步骤 2: 添加附件数据（单个附件）
oa-skills citadel-database addData \
  --tableId "2750248577" \
  --columnIds "1,2,3" \
  --data '[[
    "项目需求文档",
    JSON.stringify({
      attachmentId: 0,
      name: "requirements.pdf",
      url: "<文件URL>",
      size: 123456,
      mimeType: "application/pdf"
    }),
    1710000000000  // 上传日期: 2024-03-09
  ]]'

# 步骤 3: 添加多个附件
oa-skills citadel-database addData \
  --tableId "2750248577" \
  --columnIds "1,2" \
  --data '[[
    "设计稿",
    [
      JSON.stringify({
        attachmentId: 0,
        name: "design-v1.png",
        url: "<文件URL1>",
        size: 6105,
        width: 1920,
        height: 1080,
        mimeType: "image/png"
      }),
      JSON.stringify({
        attachmentId: 0,
        name: "design-v2.png",
        url: "<文件URL2>",
        size: 7200,
        width: 1920,
        height: 1080,
        mimeType: "image/png"
      })
    ]
  ]]'
```

**⚠️ 附件格式要点**：
- 每个附件必须使用 `JSON.stringify()` 序列化
- 必填字段：`attachmentId`（新建时为 0）、`name`、`url`
- 可选字段：`size`、`width`、`height`、`mimeType`
- 多个附件使用数组包裹多个 JSON 字符串

### 4. 使用 Token 认证的批量操作

```bash

# 批量查询多个表格
for tableId in 2750248577 2750248578 2750248579; do
  oa-skills citadel-database queryTableData \
    --tableId "$tableId" \
    --raw >> all_data.json
done
```

## getUserInfo - 获取用户信息（账号转换）

### 功能说明

`getUserInfo` 命令用于批量查询用户信息，支持 MIS 到 uid/empId/姓名等字段的转换。这是在操作人员列数据时必不可少的功能。

### 使用场景

- ✅ 查询用户的 empId（用于人员列数据）
- ✅ MIS 账号转换为 uid/empId
- ✅ 批量获取用户信息（姓名、头像等）
- ✅ 验证用户账号是否存在

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--misList` | string \| string[] | 是 | MIS 账号列表，支持 JSON 数组或逗号分隔格式 |

### 返回字段

每个用户的信息包含以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `uid` | string | 大象 UID |
| `mis` | string | MIS 账号 |
| `name` | string | 用户姓名 |
| `empId` | number | 员工 ID（**用于人员列数据**） |
| `avatarUrl` | string | 头像 URL（200x200） |
| `bigAvatarUrl` | string | 大头像 URL |

### 使用示例

#### 1. 查询单个用户信息

```bash
# 逗号分隔格式（推荐）
oa-skills citadel-database getUserInfo --misList 'zhangsan'

# 或 JSON 数组格式
oa-skills citadel-database getUserInfo --misList '["zhangsan"]'
```

输出示例：
```
✅ 查询成功！找到 1 个用户

👤 MIS: zhangsan
   ├─ 姓名: 张三
   ├─ UID: 1027950
   ├─ EmpID: 2015738
   ├─ 头像: <头像URL>
   └─ 大头像: <大头像URL>
```

#### 2. 批量查询多个用户

```bash
# 逗号分隔格式（推荐）
oa-skills citadel-database getUserInfo --misList 'zhangsan,lisi,wangwu'

# 或 JSON 数组格式
oa-skills citadel-database getUserInfo --misList '["zhangsan", "lisi", "wangwu"]'
```

#### 3. 输出原始 JSON（用于脚本处理）

```bash
oa-skills citadel-database getUserInfo \
  --misList '["zhangsan", "lisi"]' \
  --raw
```

输出示例：
```json
{
  "zhangsan": {
    "uid": "1027950",
    "mis": "zhangsan",
    "name": "张三",
    "avatarUrl": "<头像URL>",
    "bigAvatarUrl": "<大头像URL>",
    "empId": 2015738
  },
  "lisi": {
    "uid": "1027951",
    "mis": "lisi",
    "name": "李四",
    "avatarUrl": "<头像URL>",
    "bigAvatarUrl": "<大头像URL>",
    "empId": 2015739
  }
}
```

#### 4. 与人员列配合使用（完整工作流）

```bash
# 步骤 1: 查询 empId
RESULT=$(oa-skills citadel-database getUserInfo \
  --misList '["zhangsan", "lisi"]' \
  --raw)

# 步骤 2: 提取 empId（使用 jq）
EMP_IDS=$(echo "$RESULT" | jq -r '[.[] | .empId]')
# 输出: [2015738, 2015739]

# 步骤 3: 添加人员列数据
oa-skills citadel-database addData \
  --tableId "456789" \
  --columnIds "4" \
  --data "[[$EMP_IDS]]"
```

#### 5. 批量处理（从文件读取 MIS 列表）

```bash
# 从文件读取 MIS 列表（每行一个 MIS）
MIS_LIST=$(cat users.txt | jq -R . | jq -s .)

# 批量查询
oa-skills citadel-database getUserInfo \
  --misList "$MIS_LIST" \
  --raw > user_info.json
```

### 注意事项

1. **不存在的账号**
   - 不存在的 MIS 账号不会出现在返回结果中
   - 命令会在标准输出中提示哪些账号未找到
   - 不会导致命令失败

2. **批量查询建议**
   - 建议单次查询不超过 100 个用户
   - 对于大量用户，可以分批查询

3. **缓存机制**
   - 用户信息相对稳定，建议在应用层缓存查询结果
   - 头像 URL 可能会过期，建议定期更新

4. **人员列数据格式**
   - 人员列使用 **empId**（number 类型）
   - 必须先通过此命令获取 empId，再操作人员列
   - 示例：`[[2015738, 2015739]]` 表示一行包含两个人员

### API 说明

底层调用的是多维表格 v2 API：

```
GET /xtable/data-api/v2/users/getUsersByMis?misList=mis1,mis2
```

返回格式：
```json
{
  "success": true,
  "data": {
    "mis1": { ... },
    "mis2": { ... }
  }
}
```

## queryUserIdentityByUid - 通过 UID 查询 MIS/empId

### 功能说明

`queryUserIdentityByUid` 命令用于批量根据 UID 查询用户身份信息，返回对应的 MIS 和 empId。适用于已拿到大象 UID、需要继续操作人员列或回填账号信息的场景。

### 使用场景

- ✅ UID 转换为 MIS
- ✅ UID 转换为 empId
- ✅ 校验 UID 是否存在
- ✅ 为人员列、账号回填等场景补齐身份字段

### 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--uidList` | string \| string[] | 是 | UID 列表，支持 JSON 数组或逗号分隔格式 |

### 返回字段

每个用户的信息包含以下字段：

| 字段 | 类型 | 说明 |
|------|------|------|
| `uid` | string | 大象 UID |
| `mis` | string | MIS 账号 |
| `empId` | string | 员工 ID |

### 使用示例

```bash
# 逗号分隔格式（推荐）
oa-skills citadel-database queryUserIdentityByUid --uidList '1027950,1027951'

# 或 JSON 数组格式
oa-skills citadel-database queryUserIdentityByUid --uidList '["1027950", "1027951"]'
```

输出示例：
```
✅ 查询成功！找到 1 个用户

👤 UID: 1027950
   ├─ MIS: zhangsan
   └─ EmpID: 2015738

⚠️  以下 UID 未找到: 1027951
```

### 注意事项

1. 不存在的 UID 不会出现在返回结果中，命令会额外提示未找到的 UID。
2. 该命令底层复用共享用户转换能力，返回字段只包含身份映射所需的最小信息：`uid`、`mis`、`empId`。
3. 适合脚本模式配合 `--raw` 使用。

## getTableMeta 实用技巧：jq 提取列配置

`getTableMeta` 返回的原始 JSON 包含完整的列元数据，使用 `jq` 可以快速提取所需信息。

### 提取单选/多选列的可选项

```bash
# 获取所有单选/多选列的名称和可选项
oa-skills citadel-database getTableMeta --tableId "2750248577" --raw | \
  jq '[.columns[] | select(.columnType==3 or .columnType==5) | {columnName, columnType, options: .columnConfig.options}]'

# 输出示例：
# [
#   {
#     "columnName": "状态",
#     "columnType": 3,
#     "options": [{"label": "待处理"}, {"label": "进行中"}, {"label": "已完成"}]
#   },
#   {
#     "columnName": "标签",
#     "columnType": 5,
#     "options": [{"label": "紧急"}, {"label": "重要"}, {"label": "普通"}]
#   }
# ]
```

### 检查人员列是否支持多人

```bash
oa-skills citadel-database getTableMeta --tableId "2750248577" --raw | \
  jq '.columns[] | select(.columnType==4) | {columnName, multiple: .columnConfig.multiple}'

# 输出示例：
# {"columnName": "负责人", "multiple": true}
```

### 查看数字/日期列的格式化规则

```bash
oa-skills citadel-database getTableMeta --tableId "2750248577" --raw | \
  jq '[.columns[] | select(.columnType==2 or .columnType==7 or .columnType==8) | {columnName, columnType, formatter: .columnConfig.formatter}]'

# 输出示例：
# [
#   {"columnName": "进度", "columnType": 2, "formatter": "0.00%"},
#   {"columnName": "截止日期", "columnType": 7, "formatter": "YYYY-MM-DD"},
#   {"columnName": "预算", "columnType": 8, "formatter": "¥#,##0.00"}
# ]
```

### 获取所有列 ID 和名称（用于构造 --columnIds）

```bash
oa-skills citadel-database getTableMeta --tableId "2750248577" --raw | \
  jq '[.columns[] | {colId, columnName, columnType}]'

# 输出可用于确定 --columnIds 的值和顺序
```
