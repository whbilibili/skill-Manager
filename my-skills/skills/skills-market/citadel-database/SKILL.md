---
name: citadel-database
description: "学城多维表格操作工具。支持:文档/表格创建与管理、数据增删改查、批量操作、筛选排序、文件上传、账号转换。当用户需要操作多维表格、批量处理表格数据、数据同步、数据收集、表格自动化时使用。触发词:表格、多维表格、XTable、批量操作、数据导入。"

metadata:
  skillhub.creator: "zhangshufei02"
  skillhub.updater: "zhangshufei02"
  skillhub.version: "V14"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "3859"
  skillhub.high_sensitive: "true"
---

# 📊 学城多维表格 XTable 

学城多维表格操作工具，通过 CLI 快速创建、查询和管理多维表格数据。认证自动处理，支持批量操作。

## 核心特性

- ✅ **HTTP REST API**:直接使用 HTTP 接口,高效稳定
- ✅ **简洁的二维数组格式**:使用 `[["值1", "值2"]]` 格式操作数据,自动类型转换
- ✅ **完整的 CRUD**:支持创建、查询、更新、删除操作
- ✅ **Token 自动缓存**:认证信息自动保存,后续调用无需重复认证
- ✅ **支持筛选和排序**:灵活的数据查询能力

## 目录

- [📊 学城多维表格 XTable](#-学城多维表格-xtable)
  - [核心特性](#核心特性)
  - [目录](#目录)
  - [前置检查](#前置检查)
    - [Node.js 版本检查](#nodejs-版本检查)
    - [CLI 可用性检查](#cli-可用性检查)
  - [意图路由](#意图路由)
  - [CLI 速查](#cli-速查)
  - [典型工作流](#典型工作流)
    - [📝 文档级别操作（使用 citadel 命令）](#-文档级别操作使用-citadel-命令)
  - [在学城文档内插入多维表格（标准流程）](#在学城文档内插入多维表格标准流程)
    - [创建多维文档后的授权收尾](#创建多维文档后的授权收尾)
  - [复制数据表](#复制数据表)
  - [账号转换（MIS ↔ empId ↔ UID）](#账号转换mis--empid--uid)
  - [列类型速查](#列类型速查)
  - [约束](#约束)
  - [暂不支持](#暂不支持)
  - [认证](#认证)
  - [安全屋](#安全屋)
  - [多维表格链接格式](#多维表格链接格式)
  - [最佳实践](#最佳实践)
  - [常见问题](#常见问题)
  - [问题反馈](#问题反馈)

## 前置检查

### Node.js 版本检查

执行 xtable skill 时会自动检查 Node.js 版本是否符合要求（>= 18.0.0）。如果版本过低，系统会：

1. **自动检测并安装 nvm**（如未安装）
2. **通过 nvm 自动安装并切换到 Node.js 18 或更高版本**
3. **重新执行命令**，使用新的 Node.js 版本

**无需手动干预，版本升级完全自动化。** ✨

### CLI 可用性检查

每次 skill 激活时或首次执行命令前，先检查 `oa-skills` 是否存在；不存在时再执行安装。

```bash
node -e "const cp=require('child_process'); const probe=process.platform==='win32'?'where oa-skills':'command -v oa-skills'; try{cp.execSync(probe,{stdio:'ignore',shell:true})}catch{cp.execSync('npm install -g @it/oa-skills --registry=http://r.npm.sankuai.com',{stdio:'inherit',shell:true})}"
```

**此步骤必须执行一次，否则新环境中可能不存在 CLI 命令导致运行失败。**

## 意图路由

### 用户贴入多维表格链接时的处理规则（必须遵守）

当用户**仅贴入多维表格链接**（`km.sankuai.com/xtable/...`）而**未附带明确操作指令**时，禁止自动拉取数据，按以下步骤处理：

1. 从链接提取 `contentId`（路径中的数字）、`tableId`（`?table=` 参数，可能没有）
2. 若链接只有 `contentId` 无 `tableId`，先执行 `listTables --contentId <id>` 获取表格列表
3. 执行 `getTableMeta --tableId <id>` 读取表格结构（列名、列类型、列ID等）
4. **将表格结构以简明方式展示给用户，然后停下来，询问用户想对这个表格做什么**（例如：查询数据、筛选分析、添加数据、更新数据等）
5. **收到用户的明确指令后**，再按需执行后续操作

> ⚠️ **禁止行为**：不得在仅收到链接时自动执行 `queryTableData` 拉取数据。只有用户明确说"查询数据""分析数据""拉取所有数据"等指令后才能拉取。

**⚠️ 群权限提醒**：如果是在大象群里创建多维表格，创建后需要执行以下**两步授权**：① 使用 `oa-skills citadel grant --pageId <id> --xm-group-ids <群ID> --perm "仅浏览"` 为当前群授予浏览权限；② 使用 `oa-skills citadel grant --pageId <id> --person <管理员mis> --perm "可管理"` 为群助理的管理员授予管理权限。

| 用户意图                    | 命令                                    |
| -------------------------- | --------------------------------------- |
| 创建一个新的多维表格文档     | `createDatabase [--contentTitle <标题>] [--tableTitle <表格>]` <br/>💡 标题可为空；不指定 `--parentId` 时创建在用户自己空间下，无需 `--mis` 参数 |
| 在现有文档中创建新数据表     | `createTable --contentId <id> [--tableTitle "任务表"] --columnMeta '[{"columnName":"任务名","columnType":1}]'` |
| 复制数据表到指定文档/表格    | `copyTable --sourceTableId <源ID> --targetParentId <目标ID> [--targetType <3\|4>]` |
| 查看文档下有哪些表格         | `listTables --contentId <id>`                 |
| 查询表格的列结构（columnId） | `getTableMeta --tableId <id>`                          |
| 查询表格中的数据             | `queryTableData --tableId <id> [--columnIds <列ID>] [--filter <条件>] [--sort <排序>]` |
| 向表格中添加新数据           | `addData --tableId <id> --columnIds <列ID> --data '[...]'` |
| 更新表格中的数据             | `updateData --tableId <id> --rowIds <行ID> --data '[...]'` |
| 删除表格中的数据             | `deleteData --tableId <id> --rowIds "123456,123457"` |
| 重命名数据表                 | `renameTable --tableId <id> --title "新表格名称"`    |
| 数据表排序                   | `sortTable --tableId <id> --to 2`                    |
| **查询用户信息（账号转换）** | `getUserInfo --misList 'mis1,mis2'`                     |
| **通过 UID 查询 MIS/empId** | `queryUserIdentityByUid --uidList 'uid1,uid2'`         |
| **上传本地文件到表格**       | `uploadFile --contentId <id> --tableId <id> --file <路径>` |
| **上传文件并添加到附件列** ⭐ | `uploadFileAndAddData --contentId <id> --tableId <id> --file <路径> --columnIds <列ID> --data '[...]'` |
| 通过 S3 URL 上传文件 🔧      | `uploadFileByS3Url --s3Url <S3地址> [--fileName <文件名>] --contentId <id>` |
| 在学城文档内插入多维表格     | `依次执行：createTable → addData → updateDocumentByMd` |

**图例说明**：⭐ 推荐使用 | 🔧 低层 API（调试/特殊集成用）

## CLI 速查

**命令格式**：`oa-skills citadel-database <command> [options]`  
**通用选项**：`--mis <mis>` | `--raw` | `--clear-cache` | `--force-ciba`（仅在认证异常时兜底使用，正常不需要添加）

📖 执行具体命令前，加载 `{baseDir}/references/cli-reference.md` 获取完整参数、示例和工作流

## 典型工作流

```
1. 准备阶段 → 2. 权限管理 → 3. 数据操作 → 4. 验证结果
```

**阶段 1: 准备** — `getTableMeta` 获取列 ID、列类型、列配置

**阶段 2: 权限管理**（大象群建文档时必需）— 使用 `oa-skills citadel` 两步授权（群浏览权限 + 管理员管理权限）

**阶段 3: 数据操作** — `addData` / `updateData` / `queryTableData` / `deleteData`

**阶段 4: 验证** — `queryTableData` 确认修改成功

### 📝 文档级别操作（使用 citadel 命令）

对于文档级别操作（删除/恢复/移动文档、获取评论、权限管理），请使用 `oa-skills citadel` 命令。禁止自己猜测 citadel skill 支持的命令，需要通过 `--help` 参数查看。

## 在学城文档内插入多维表格（标准流程）

当用户需要"创建一篇文档，文档内插入多维表格"时，必须严格按以下 4 步执行：

1. **建普通学城文档**（`citadel` skill）
   ```bash
   oa-skills citadel createDocument --title <标题> --content "<文档初始内容（可为空字符串）>"
   # → 得到 docContentId
   # ⚠️ --content 为必填参数（可传空字符串 ""），不传会报错
   ```

2. **直接在这篇学城文档内建数据表**（在此定义列结构）
   ```bash
   oa-skills citadel-database createTable \
     --contentId <docContentId> \
     --tableTitle <表格名> \
     --columnMeta '[{"columnName":"列名","columnType":1}]'
   # → 得到 tableId
   ```

3. **写入数据**
   ```bash
   oa-skills citadel-database addData \
     --tableId <tableId> \
     --columnIds "1,2,3" \
     --data '[...]'
   ```

4. **将多维表格嵌入学城文档**（`citadel` skill）
   ```bash
   # CitadelMD 中使用以下语法嵌入（新增节点时可省略 nodeId）：
   :::xtable{xtableId="<tableId>"}:::

   oa-skills citadel updateDocumentByMd \
     --contentId <docContentId> \
     --file <citadelmd文件路径>
   ```

**⚠️ 注意事项：**

- 在学城文档内插入多维表格时，**不需要**先创建多维表格文档，直接调用 `createTable` 即可
- `createTable` 的 `--contentId` 就是这篇学城文档 ID（`docContentId`）
- `addData` 使用的是返回的 `tableId`，不是 `contentId`
- `:::xtable` 的属性名是 `xtableId`，这里传的是数据表 ID（`tableId`），不是学城文档 ID（`docContentId`）
- `nodeId` 逻辑遵循 `citadel/references/doc-syntax.md`：编辑已有 `:::xtable` 节点时保留原值；新增节点时可以省略，由转换器自动生成

### 创建多维文档后的授权收尾

每次 `createDatabase` 成功后，必须询问用户是否需要授权。若场景为**大象群**，自动执行两步授权。当用户需要为文档授权、改权、移权、管理权限继承时，加载 `{baseDir}/references/permission-management.md`。

## 复制数据表

将数据表复制到指定目标文档或表格。底层 `type` 仅支持：`3=学城文档`、`4=多维表格`；不传 `--targetType` 时会自动识别。详细参数见 `{baseDir}/references/cli-reference.md`。

## 账号转换（MIS ↔ empId ↔ UID）

| 命令 | 用途 | 输入格式 |
|------|------|----------|
| `getUserInfo --misList 'mis1,mis2'` | MIS → uid/empId/姓名 | 逗号分隔或 JSON 数组 |
| `queryUserIdentityByUid --uidList 'uid1,uid2'` | UID → mis/empId | 逗号分隔或 JSON 数组 |

详细参数和示例见 `{baseDir}/references/cli-reference.md` 的 getUserInfo / queryUserIdentityByUid 章节。

## 列类型速查

| columnType | 类型 | 数据结构 | 示例 |
|------------|------|----------|------|
| 1 | 文本 | `IRichTextNode[]` | `[{type:"text",value:"任务A"}]` |
| 2 | 数字 | `number` | `100` |
| 3 | 单选 | `string` | `"进行中"` |
| 4 | 人员 | `empId[]` | `[2015738,2015739]` |
| 5 | 多选 | `string[]` | `["标签1","标签2"]` |
| 6 | 附件 | `string[]` (JSON) | `[JSON.stringify({attachmentId:0,name:"f.png",url:"…"})]` |
| 7 | 日期 | `number` (timestamp ms) | `1704067200000` (2024-01-01) |
| 8 | 货币 | `number` | `99.99` |
| 9 | 公式 | 只读 | 不支持写入 |
| 10 | 查找引用 | 只读 | 不支持写入 |

```bash
# 逗号分隔格式（推荐）
oa-skills citadel-database getUserInfo --misList 'zhangsan,lisi'
# 或 JSON 数组格式
oa-skills citadel-database getUserInfo --misList '["zhangsan", "lisi"]'
```

**📖 完整数据格式文档**：操作文本/附件/日期/人员列、构造筛选/排序条件时，加载 `{baseDir}/references/data-format.md`（富文本节点、附件格式、筛选/排序语法、列配置、常见错误）

## 约束

- `--mis` 参数可选，未指定时从 `~/.config/clawdgw.json` 读取
- 缺少关键参数时只追问必要字段（--contentId / --tableId / --columnIds），不给笼统报错
- 列 ID 格式灵活：支持逗号分隔 `"1,2,3"` 或 JSON 数组 `[1,2,3]`
- **列类型严格校验**：必须按列类型表传入正确格式，否则 API 报错
- **数据量限制**：单次操作最多 500 行；批量写建议每批 ≤100 行，超 500 行自动分批
- **列类型选择强制要求**：创建表格时必须根据数据用途选对应列类型，不要全部用文本列
- **筛选语法**：`operator` 只使用"筛选和排序"章节列出的枚举值；`filterValue` 始终传 `string[]`，`isnull`/`notnull` 传 `[]`
- **风控要求**：不得在输出中包含内部 IP、Token、敏感密钥

## 暂不支持

- 列的删除和修改
- 表格结构变更（添加/删除/修改列）

用户要求时明确说明"当前暂不支持"。替代方案：可通过 Web UI 手动操作。

## 认证

根据运行环境选择合适的策略，优先 SSO 无感登录。Token 自动缓存。认证失败时执行 `oa-skills citadel-database --clear-cache` 后重试。详细说明见 `{baseDir}/references/cli-reference.md`。

## 安全屋

读写 C4 级别的多维表格数据需要在安全屋模式下运行。

**使用方式**：在 大象助理 中开启安全屋模式，之后正常执行命令即可，无需额外参数。

**错误提示**：若未开启安全屋，操作 C4 数据时可能收到如下提示：

> 当前数据返回不完整，请打开安全屋模式查看完整数据返回。

遇到此提示时，在 大象助理 中开启安全屋后重新执行命令。

## 多维表格链接格式

**线上环境**：
```
https://km.sankuai.com/xtable/{contentId}?table={tableId}&view={viewId}
```

**测试环境**（`--access-env test`）：
```
https://km.it.test.sankuai.com/xtable/{contentId}?table={tableId}&view={viewId}
```

参数说明：`contentId`（文档 ID，必需）、`tableId`（表格 ID，可选）、`viewId`（视图 ID，可选）

## 最佳实践

1. **先查询元数据**：使用 `getTableMeta` 获取列 ID、列类型、列配置后再操作数据
   - 从 `columnConfig.options` 获取单选/多选的有效选项
   - 检查 `columnConfig.multiple` 确认人员列是否支持多选
2. **数据格式准备**：单选/多选用 `options.label`；人员列用 empId；日期/数字直接用原始类型（`formatter` 只影响 UI 展示）
3. **群场景建表后补权限**：在大象群创建文档后立即执行两步授权
4. **错误排查**：检查错误信息中的 TraceID 用于问题追踪

## 常见问题

**Q: 如何获取列ID？**  
A: `getTableMeta` 查询表格元数据。

**Q: 日期格式如何处理？**  
A: 日期使用毫秒时间戳（13位数字），如 `1704067200000`（对应 2024-01-01）。可通过 `new Date("2024-01-01").getTime()` 转换。`formatter` 只影响 UI 展示，不影响读写。

**Q: 如何处理人员类型？**  
A: 人员类型使用 empId 数字数组，用 `getUserInfo` 命令转换 MIS → empId。

**Q: 单选/多选需要提前创建选项吗？**  
A: 不需要，系统自动创建。用 `getTableMeta` 查看现有选项。

**Q: 如何删除多维表格文档？**  
A: `oa-skills citadel deleteDocument --contentId <id>`（文档级操作由 citadel skill 负责）。

**Q: 认证失败怎么办？**  
A: `oa-skills citadel-database --clear-cache`。

## 问题反馈
点击 https://applink.neixin.cn/profile?gid=70411238253 加入学城多维表格官方 Skill 客服群大象群
