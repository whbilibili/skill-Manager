---
name: citadel
description: "学城官方Skill：学城 km/wiki/citadel/km.sankuai.com 自动化操作工具，直接调用线上接口，响应速度更快。支持读取文档信息和内容、获取模板内容、读取文档的目录、查询文档统计信息、总结文档内容、获取文档元信息（父文档ID、标题、创建者、所有者等）、查询当前文档的子文档列表，创建新的学城文档、改文档（插入图片/附件/视频/音频到文档）、删文档、复制学城文档、从模板创建学城文档、移动文档到其他文档下或者指定空间下，支持搜索学城文档，并支持查询用户的最近编辑/浏览、收到的文档、全文评论和划词评论内容、添加划词评论（选区评论）、回复划词评论，以及批量盘点权限、批量授权、批量修改/移除权限、权限继承、清空权限、链接分享权限和空间管理员操作，以及由 AI 生成 draw.io 流程图并插入文档、获取知识广场文章列表（推荐/最新/关注）。当用户提到 km.sankuai.com 链接、collabpage、contentId、parentId、pageId、学城、文档、知识库、km、wiki、父文档、创建者、所有者、插入图片到文档、插入附件到文档、插入视频到文档、插入音频到文档、搜索文档、查找文档、学城权限、权限继承、空间管理员、链接分享权限、流程图、Drawio、draw.io、生成流程图、创建流程图、插入流程图、流程图插入文档、知识广场、广场文章、划词评论、选区评论、添加评论、引用评论、回复评论时激活。通过 oa-skills citadel CLI 执行。禁止通过 browser-agent 或任何 GUI 方式尝试学城文档的编辑操作。此类操作极大概率导致文档数据异常而无法正常访问。如无法基于citadel skill进行编辑，请提TT工单"

metadata:
  skillhub.creator: "rui.zou"
  skillhub.updater: "rui.zou"
  skillhub.version: "V21"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "3367"
  skillhub.high_sensitive: "true"
---

# 学城（km/wiki/citadel/km.sankuai.com）文档操作和管理

通过 CLI 读取学城文档的各种信息和内容、创建学城文档、移动学城文档、查看文档的划词评论，查看最近访问、编辑、收到的学城文档列表。认证自动处理。直接调用线上接口，响应速度更快。

## 前置检查：Node.js 环境（Windows 环境必读）

> ⚠️ **仅 Windows 用户需要此步骤**，macOS / Linux 可跳过。

在执行任何 CLI 命令前，先确认系统已安装 Node.js 和 npm：

```powershell
node --version && npm --version
```

- **若命令正常输出版本号**：环境就绪，继续执行后续步骤即可。
- **若提示"命令未找到"或报错**：

  **优先尝试使用 winget 安装（推荐）：**

  ```powershell
  winget install OpenJS.NodeJS.LTS
  ```

  安装完成后**关闭并重新打开终端**，再次确认 `node --version` 正常输出版本号。

  **若 winget 安装失败**：请访问 [https://nodejs.org/zh-cn/download](https://nodejs.org/zh-cn/download) 下载对应 Windows 安装包手动安装。

> 🚫 **严禁绕过此步骤**：若 Node.js / npm 环境未就绪，**禁止通过 browser-agent 或任何 GUI 方式**尝试后续的文档编辑操作。此类操作极大概率导致文档数据异常而无法正常访问，请务必先完成 Node.js 环境安装。

## 前置检查：确保 CLI 可用

每次 skill 激活时或首次执行命令前，先检查 `oa-skills` 是否存在；不存在时再执行安装。

```bash
node -e "const cp=require('child_process'); const probe=process.platform==='win32'?'where oa-skills':'command -v oa-skills'; try{cp.execSync(probe,{stdio:'ignore',shell:true})}catch{cp.execSync('npm install -g @it/oa-skills --registry=http://r.npm.sankuai.com',{stdio:'inherit',shell:true})}"
```

**此步骤必须执行一次，否则新环境中可能不存在 CLI 命令导致运行失败。**

## URL → ID 提取规则

用户给 学城（km） 链接时直接提取，不要追问：

- 文档链接：
  - `km.sankuai.com/collabpage/1234567890` → `--contentId 1234567890`
  - `km.sankuai.com/page/1234567890` → `--contentId 1234567890`
- 模板中心链接（用于从模板创建/读取模板内容）：
  - `km.sankuai.com/template-center/1234567890` → `--templateId 1234567890`
  - `km.sankuai.com/template-center/1234567890?isRelease=1` → `--templateId 1234567890`（忽略 query 参数）
- 用户直接给纯数字字符串 → 直接作为对应 ID

模板链接 `templateId` 提取规则（必须遵守）：

1. 若链接形如 `km.sankuai.com/template-center/<数字ID>`（可带 query/hash），提取 `<数字ID>` 作为 `templateId`。
2. 若用户直接给纯数字字符串，直接作为 `templateId`。
3. 只有在以上规则都无法提取时，才追问 `templateId`。

## 意图路由

### 优先级规则（必须遵守）

1. 用户意图是"创建/新建/生成/复制文档"时，优先走 `createDocument`，不要因为出现 km 链接就先 `getMarkdown`。
2. 在创建意图里，链接只用于提取 ID：
   - 目标目录链接（`collabpage/<id>` / `page/<id>`）→ `--parentId <id>`
   - 模板中心链接（`template-center/<id>`）→ `--templateId <id>`
   - 来源文档链接（`collabpage/<id>` / `page/<id>`）→ `--copyFrom <id>`
3. 用户意图是"查看模板内容"时，执行 `getTemplateMarkdown`，不要走 `getMarkdown`。
4. 只有用户明确要求"阅读/查看/总结文档内容"且目标是文档正文时，才执行 `getMarkdown`。
5. **群权限管理**：如果是在大象群里创建文档，创建后需要执行两步授权：
- 为当前群授予浏览权限：`oa-skills citadel grant --url https://km.sankuai.com/collabpage/<id> --xm-group-ids <群ID> --perm "仅浏览"`
- 为群助理的管理员（mis）授予管理权限：`oa-skills citadel grant --url https://km.sankuai.com/collabpage/<id> --person <管理员mis> --perm "可管理"`
6. **创建后的授权收尾**：每次 `createDocument` 成功后，必须询问用户："文档已创建，是否需要为特定人员/群组授权？"；若当前场景是大象群，则自动执行两步授权；若是单聊或其他场景，则询问用户是否需要授权，按需执行。


### 读取学城文档 markdown（仅在阅读/总结意图下）

```bash
getMarkdown --contentId <id>
```

### 获取模板内容

当用户提供模板 ID 或模板中心链接（`template-center/<id>`）并要求查看模板内容时，执行：

```bash
getTemplateMarkdown --templateId <id>
```

示例：

- `https://km.sankuai.com/template-center/2751442505?isRelease=1` → `--templateId 2751442505`
- `getTemplateMarkdown --templateId 2751442505`

### 总结学城文档

执行 [references/doc-summary.md](references/doc-summary.md) 文件里的具体步骤，输出总结结果。

### 查看当前学城文档的子文档、文档结构和内容、parentId 下的文档目录

```bash
getChildContent --contentId <id>
```

### 创建/新建学城文档

> ⚠️ **位置默认规则（必须遵守）**：
> - 用户**未明确指定**创建位置（未给 `--parentId` 或 `--spaceId`）时，**一律不加这两个参数**，由系统自动创建在当前用户个人空间根目录。
> - **禁止**从上下文中自动猜测或沿用任何文档 ID 作为 `--parentId`。只有用户明确说"在 XXX 文档下创建"或"创建为 XXX 的子文档"时，才传 `--parentId`。

```bash
# 创建到个人空间根目录（用户未指定位置时的默认行为）
createDocument --title <标题> --content <内容>

# 创建为指定文档的子文档（用户明确指定了父文档时）
createDocument --title <标题> --content <内容> --parentId <父文档id>
```

**⚠️ 群权限提醒**：如果是在大象群里创建文档，创建后需要执行以下**两步授权**：

```bash
# 第一步：为大象群授予浏览权限
oa-skills citadel grant \
  --url "https://km.sankuai.com/collabpage/返回的contentId" \
  --xm-group-ids "群ID" \
  --perm "仅浏览"

# 第二步：为群助理的管理员（mis）授予管理权限
oa-skills citadel grant \
  --url "https://km.sankuai.com/collabpage/返回的contentId" \
  --person "管理员mis" \
  --perm "可管理"
```

📖 **权限管理详细文档**：查看 [references/permission-management.md](references/permission-management.md) 了解完整的权限管理功能、使用场景和最佳实践。

### 创建学城文档的子文档

```bash
createDocument --title <标题> --content <内容> --parentId <id>
```

**⚠️ 群权限提醒**：如果是在大象群里创建子文档，创建后需要执行两步授权：① 为当前群授予浏览权限；② 为群助理的管理员（mis）授予管理权限。详见 [references/permission-management.md](references/permission-management.md)。

### 创建学城文档后的授权收尾（必须执行）

每次 `createDocument` 成功后，必须询问用户：

"文档已创建，是否需要为特定人员/群组授权？"

若当前场景为：

- **大象群**：自动执行两步授权（群浏览权限 + 管理员可管理权限）
- **单聊/其他**：询问用户是否需要授权，按需执行

### 学城权限管理与空间管理员管理

执行 [references/permission-management.md](references/permission-management.md) 里的具体步骤。统一使用 `oa-skills citadel` 下的权限管理子命令处理以下场景：

- 盘点空间或目录权限：`audit`
- 批量授权、改权、移权：`grant` / `modify` / `revoke`
- 移除或恢复权限继承：`inherit`
- 盘点离职员工文档：`audit-resigned`
- 批量转移所有者：`transfer-owner`
- 一键清空权限：`clear-perm`
- 批量设置链接分享权限：`share-perm`
- 增加或移除空间管理员：`space-admin`

### 编辑学城文档/更新学城文档内容/插入新内容到学城文档

执行 [references/doc-update.md](references/doc-update.md) 文件里的具体步骤，进行安全的文档更新，**禁止直接操作修改 JSON 数据以及通过 GUI 方式进行编辑操作**。

> 所有内容编辑必须通过 `updateDocumentByMd` 完成。完整流程：
> 1. `getDocumentCitadelMd --contentId <id> --output doc.citadelmd` 获取当前内容
> 2. 由 AI 修改 `doc.citadelmd` 文件内容
> 3. `updateDocumentByMd --contentId <id> --file doc.citadelmd` 回传
>
> 处理编辑请求时，严格按下面的执行口令操作：
> - **先读后改**：必须先 `getDocumentCitadelMd`，禁止在未读取原文的情况下凭空生成整篇文档内容覆盖回传
> - **最小改动**：只修改用户明确要求的那几处；无关段落、宏节点、空行、顺序、样式一律保持原样
> - **不要做格式化重写**：禁止把整篇内容“重新整理”“统一格式”“批量改写”为另一种等价写法
> - **复杂表格直接改宏块**：使用 `:::table` / `:::table_row` / `:::table_header` / `:::table_cell` 宏块编辑，**不要再把表格内容写成 JSON**
> - **表格结构属性默认不动**：除非用户明确要求改布局，否则不要修改 `colspan` / `rowspan` / `colwidth` / `textAlign` / `verticalAlign` / `bgColor` / `color` / `numCell`
> - **脚注只改正文**：`:::footnote_list_item` 的正文可修改，但 `footnoteNodeId` / `nodeId` 必须保留
> - **图表配置默认保留**：块级 `data2chart` 如带 `:::data2chart_config` / `:::data2chart_data`，默认保留原内容，除非用户明确要求修改图表配置
> - **回传前自检**：确认 `:::title` 仍在第一位、块级宏闭合完整、行内宏未跨行、没有把复杂宏误删或误合并
>
> 如果用户只是“在原文基础上补充/替换一小段”，优先在原位置做局部修改，不要整段重写。

**输出**：返回编辑文档的链接，提醒用户需要刷新当前页面才能看到更新内容。

#### 修改文档标题

> ⚠️ **文档标题存储在 CitadelMD 内容的 `:::title:::` 节点中，单独传 `--title` 参数无法真正更新标题**。若 CitadelMD 文件中仍保留旧的 `:::title:::` 节点内容，正文内容会覆盖元数据，导致 `--title` 形同虚设。

> ⚠️ **`title` 与 `heading` 的关键区别**：
> - `:::title:::` 是**文档标题节点**，必须是整个文档 `doc` 的**第一个子节点**，有且只有一个
> - `# 标题` / `## 标题`（即 `heading`）是**文档正文中的标题样式**，不能代替 `title` 放在第一位

正确做法（**两处都必须改**）：

1. 获取当前文档的 CitadelMD 内容：
   ```bash
   getDocumentCitadelMd --contentId <id> --output doc.citadelmd
   ```
2. 修改文件头部 `:::title:::` 节点内的文字为新标题
3. 回传时同步传入 `--title` 参数（更新元数据层标题）：
   ```bash
   updateDocumentByMd --contentId <id> --file doc.citadelmd --title "新标题"
   ```

`:::title:::` 节点（正文层）和 `--title` 参数（元数据层）**缺一不可**，否则标题更新不完整。

### 将 AI 生成的内容（图片、附件）或本地文件（包括视频、音频）插入到学城文档

执行 [references/doc-insert.md](references/doc-insert.md) 文件里的具体步骤，将 AI 生成的图片、本地文件、本地视频或本地音频安全插入到指定学城文档。

- **插入图片**：**严禁直接将非学城图片 URL 插入文档**，必须先调用 `uploadImageToDocument` 上传，再将返回的 `imageMd` 插入 CitadelMD。
- **插入附件**：**严禁将非学城附件 URL 直接写入 CitadelMD**，必须先调用 `uploadAttachmentToDocument` 上传（仅限 PDF/Word/Excel/ZIP 等非媒体文件，**视频和音频禁止用此命令，否则 URL 无法正确转换为 CDN 格式**）。
- **插入视频**：**严禁将非学城视频 URL 直接写入 CitadelMD**，必须先调用 `uploadVideoToDocument` 上传，再将返回的 `videoMd` 插入 CitadelMD。
- **插入音频**：**严禁将非学城音频 URL 直接写入 CitadelMD**，必须先调用 `uploadAudioToDocument` 上传，再将返回的 `audioMd` 插入 CitadelMD。
- **插入内嵌多维表格**：如果是在现有学城文档里新建表格，直接调用 `oa-skills citadel-database createTable --contentId <文档ID> --tableTitle <表格名>`，这里的 `contentId` 就是目标学城文档 ID；如果是复制已有表格到学城文档，则调用 `oa-skills citadel-database copyTable --sourceTableId <源表ID> --targetParentId <文档ID> --targetType 3`。随后再沿用 `citadel` 的 `getDocumentCitadelMd` → 插入 `:::xtable{xtableId="<tableId>"}:::` → `updateDocumentByMd` 流程完成文档插入；新增节点时 `nodeId` 可省略，若文档里已存在该节点则保留原值。

**输出**：返回文档链接，提醒用户刷新页面查看插入的内容（图片/附件/视频/音频/内嵌多维表格）。

### 将多维表格内嵌到学城文档

当用户要求“在学城文档中插入/嵌入多维表格”时，按下面流程处理：

1. **先创建或复制多维表格**
   - 在现有学城文档内新建表格：调用 `oa-skills citadel-database createTable --contentId <目标文档ID> --tableTitle <表格名>`，其中 `contentId` 就是目标学城文档 ID，不需要先创建多维表格文档；返回值里的 `tableId` 仅用于后续数据读写
   - 复制已有数据表到目标学城文档：调用 `oa-skills citadel-database copyTable --sourceTableId <源表ID> --targetParentId <目标文档ID> --targetType 3`。内嵌到学城文档时固定使用 `type=3`
2. **再走学城文档插入链路**
   - `getDocumentCitadelMd --contentId <目标文档ID>`
   - 在目标位置插入 `:::xtable{xtableId="<tableId>"}:::`（新增节点时可不写 `nodeId`；若是编辑已有节点则保留原值）
   - `updateDocumentByMd --contentId <目标文档ID> --content <修改后的CitadelMD>`
3. **能力边界**
   - `citadel` 负责文档插入和内容更新
   - 多维表格的数据创建、复制、读写统一走 `oa-skills citadel-database`
   - `:::xtable` 是文档中的多维表格引用节点，不要把表格数据直接手写进 CitadelMD

### 从模板创建学城文档

当用户给的是模板中心链接（`km.sankuai.com/template-center/<id>`）时，按上面的规则提取 `templateId`（忽略 query 参数），然后执行：

```bash
createDocument --title <标题> --templateId <id>
```

示例：

- `https://km.sankuai.com/template-center/2751442505` → `--templateId 2751442505`
- `https://km.sankuai.com/template-center/2751442505?isRelease=1` → `--templateId 2751442505`

### 复制学城文档

```bash
createDocument --title <标题> --copyFrom <id>
```

### 在指定目录下复制模板创建文档（2.0 文档优先）

当用户说"先复制模板再填充内容""按模板生成"等，并且模板给的是 `km.sankuai.com/collabpage/<id>` / `km.sankuai.com/page/<id>` 链接（尤其学城文档2.0）时，默认使用复制命令，不要先读取模板内容再重建：

```bash
createDocument --title <标题> --copyFrom <模板id> --parentId <目录id>
```

示例（对应用户输入）：

- 目录：`https://km.sankuai.com/collabpage/1234567890` → `--parentId 1234567890`
- 模板：`https://km.sankuai.com/collabpage/1234567890` → `--copyFrom 1234567890`
- 命令：`createDocument --title "测试文档" --copyFrom 1234567890 --parentId 1234567890`

### 删除学城文档

```bash
deleteDocument --contentId <id>
```

### 撤销删除/恢复已删除的学城文档

```bash
restoreDocument --contentId <id>
```

### 移动学城文档

```bash
# 移动到其他文档下
moveDocument --contentId <id> --newParentId <id>
# 移动到空间根目录
moveDocument --contentId <id> --newSpaceId <id>
```

### 设置文档密级

```bash
setSecretLevel --contentId <id> --secret-level <2|3|4>
```

**密级说明**：
- `2` → C2（内部公开）
- `3` → C3（内部敏感）
- `4` → C4（内部机密）

示例：

```bash
# 将文档设置为 C3 密级
setSecretLevel --contentId 2757266357 --secret-level 3
```

### 搜索学城文档

```bash
searchContent --keyword <关键词>
```

支持分页：

```bash
# 默认每次返回 20 条（offset=0）
searchContent --keyword <关键词>

# 仅搜索标题
searchContent --keyword <关键词> --searchTitle

# 分页（第 2 页）
searchContent --keyword <关键词> --offset 20 --limit 20
```

支持指定空间范围搜索：

```bash
# 通过空间链接指定（spaceKey 格式，如 /space/citadel）
searchContent --keyword <关键词> --space-url "https://km.sankuai.com/space/citadel"

# 通过空间链接指定（spaceId 格式，如 /space/27）
searchContent --keyword <关键词> --space-url "https://km.sankuai.com/space/27"

# 通过空间 ID 直接指定
searchContent --keyword <关键词> --space-id 27
```

**如何获取空间链接**：在学城打开目标空间，浏览器地址栏的 URL 即为空间链接，支持两种格式：
- `https://km.sankuai.com/space/<spaceKey>`（如 `/space/citadel`）
- `https://km.sankuai.com/space/<spaceId>`（如 `/space/27`，纯数字）

**说明**：
- 该接口支持安全屋策略，**非安全屋模式下不会返回 C4 文档**。CLI 会在结果末尾自动提示"非安全屋模式下不会返回 C4 文档，如需查看完整结果请打开安全屋模式。"，安全屋模式下无此提示。
- 返回结果含文档 ID、标题、空间名、作者、更新时间和内容摘要。
- `--searchTitle` 仅匹配文档标题（不搜正文）；不加此参数则全文搜索。
- `--space-url` 和 `--space-id` 二选一，用于将搜索范围限定在某个空间内。

### 获取/查看用户（mis）最近编辑了什么文档

```bash
getLatestEdit --limit 10
```

### 获取/查看用户（mis）最近浏览了什么文档

```bash
getRecentlyViewed --pageSize 10
```

### 获取/查看用户（mis）别人发的/收到的学城文档

```bash
getReceivedDocs --limit 10
```

### 获取学城文档的划词评论

```bash
getDiscussionComments --contentId <id>
```

### 获取学城文档的全文评论

```bash
getFullTextComments --contentId <id>
```

### 获取学城文档的所有评论（划词评论 + 全文评论）

```bash
getAllComments --contentId <id>
```

### 对文档新增全文评论 / 回复已有全文评论

```bash
# 新增顶级全文评论（不传 --parentCommentId 或传 0）
addFullTextComment --contentId <id> --text "评论内容"

# 回复已有评论（先用 getFullTextComments 获取评论 ID，再传 --parentCommentId）
addFullTextComment --contentId <id> --text "回复内容" --parentCommentId <评论ID>
```

> ⚠️ **频次限制**：每次 AI 会话、每篇文档最多调用 1 次 `addFullTextComment`，**严禁批量循环发送评论**。如需回复，必须先 `getFullTextComments` 确认目标评论 ID，再执行一次回复。不得在未确认用户意图的情况下连续发送多条评论。

### 为文档段落/标题节点添加划词评论

当用户要求对文档特定段落或标题添加划词评论（选区评论/引用评论）时，执行两步操作（自动完成）：

**前置步骤：先获取目标节点的 nodeId 和当前 stepVersion**

```bash
# 第一步：获取文档 CitadelMD，从中确认目标段落的 nodeId 和 stepVersion
oa-skills citadel getDocumentCitadelMd --contentId <id>
```

- 输出中会有 `文档版本（stepVersion）：<数字>`
- CitadelMD 中每个节点会带有 `nodeId` 属性，例如 `:::paragraph{nodeId="abc123"}:::` → nodeId 为 `abc123`

**第二步：添加划词评论**

```bash
# 基本划词评论（对指定节点整体作为引用范围）
addDiscussionComment --contentId <id> --nodeId <nodeId> --stepVersion <版本号> --text "评论内容"

# 带 @提及
addDiscussionComment --contentId <id> --nodeId <nodeId> --stepVersion <版本号> --text "评论内容" --mention "zhangsan" --mentionNames "张三"
```

> ⚠️ **限制说明**：
> - 只支持对整个顶层块节点（段落/标题）添加划词，不支持对段落内部分文字范围划词
> - 每次 AI 会话每篇文档最多调用 1 次 `addDiscussionComment`，禁止批量循环调用
> - nodeId 和 stepVersion 必须通过 `getDocumentCitadelMd` 获取，不要猜测或伪造
> - 若 stepVersion 与服务端不一致（文档有其他人同时编辑），命令会报错，需重新获取后重试

> 📖 **完整参数说明和常见错误处理**：查看 [references/discussion-comment.md](references/discussion-comment.md)

### 回复已有划词评论

先通过 `getDiscussionComments` 获取 discussionId，再回复：

```bash
# 第一步：获取划词评论列表，找到目标 discussionId（对应 commentId 字段）
getDiscussionComments --contentId <id>

# 第二步：回复指定划词评论
replyDiscussionComment --contentId <id> --discussionId <discussionId> --text "回复内容"

# 带 @提及的回复
replyDiscussionComment --contentId <id> --discussionId <discussionId> --text "回复内容" --mention "zhangsan" --mentionNames "张三"
```

> ⚠️ **频次限制**：每次 AI 会话、每篇文档最多调用 1 次 `replyDiscussionComment`，禁止批量循环调用。

### 获取文档的统计信息（浏览量、评论数、创作时长等）

```bash
getDocumentStats --contentId <id>
```

### 获取文档元信息（父文档ID、标题、创建者、所有者、创建/编辑时间等）

```bash
getDocumentMetaInfo --contentId <id>
```

**说明**：返回文档的父文档 ID（`parentId`）、标题（`title`）、创建者（`creator`）、文档所有者（`owner`）、最后编辑者（`modifier`）、创建时间（`createTime`）、最后编辑时间（`modifyTime`）等。若 `parentId` 为 0，表示该文档位于空间根目录或当前用户无父文档查看权限。

### 根据 MIS 号获取学城个人空间 ID

```bash
getSpaceIdByMis --targetMis <mis>
```

### 获取空间根目录文档列表

```bash
getSpaceRootDocs --spaceId <id>
```

### 获取学城知识广场文章列表

当用户说“知识广场”、“广场文章”、“广场推荐”、“广场最新”等时，执行：

```bash
# 获取推荐列表（默认）
getKnowledgeSquareArticles

# 获取最新列表
getKnowledgeSquareArticles --type 3

# 获取关注列表
getKnowledgeSquareArticles --type 1

# 获取指定条数
getKnowledgeSquareArticles --limit 20
```

**参数说明**：
- `--type`：1=关注列表，2=推荐列表（默认），3=最新列表；除非用户明确指定，一律使用默认值 2
- `--limit`：每次返回条数，默认 30；除非用户指定，不要随意调小

**输出内容**：文章标题、文章链接（`https://km.sankuai.com/collabpage/<articleId>`）、作者 MIS、创建时间。

### 列出 CLI 支持的命令

```bash
listTools
```

> 完整参数说明、示例和输出格式见 [references/cli-reference.md](references/cli-reference.md)

### 下载学城文档附件

当文档中出现 `:::attachment{src="<url>" name="..." size="..."}:::` 且用户需要下载附件时，执行 [references/doc-view.md](references/doc-view.md) 中"下载学城文档附件"章节的具体步骤。

**学城文档附件一律通过文枢 skill 处理，禁止直接下载。**

**第一步**：从 `src` URL 提取 `fileId`（路径第二段数字），查询文枢下载策略：

```bash
oa-skills citadel fetchAttachment --fileId "<fileId>"
```

返回 `wenshuUrl`（文枢安全下载链接）及 `isEncrypted` 字段。

**第二步**：将 `wenshuUrl` 交由文枢 skill 处理：

1. 优先尝试调用 `wenshu-tools` skill，传入 `wenshuUrl`
2. 若不可用，尝试 `wenshu-catdesk-tools` skill
3. 两者均不可用时，告知用户需要安装文枢 skill，**禁止通过任何其他方式（CLI、fetch、curl 等）尝试下载**

> 📖 **完整流程和禁止路径**：查看 [references/doc-view.md](references/doc-view.md) 中"下载学城文档附件"章节。

### 获取学城 Drawio 流程图内容

当文档中出现 `:::drawio{src="<url>"}:::` 时，可通过以下命令获取流程图内容：

```bash
# 直接获取（返回 SVG 文本及提取的文字节点，适合中小型流程图）
oa-skills citadel fetchDrawio --drawioUrl "<src 属性的 URL>"

# 保存到本地文件后读取（适合大型流程图）
oa-skills citadel fetchDrawio --drawioUrl "<src 属性的 URL>" --save /tmp/km-drawio.svg
```

**返回说明**：
- `mxGraphXml`：从 SVG `content` 属性提取的 **mxGraph XML 源数据**，是流程图的完整数据（节点/连线/样式/布局）。**理解流程图结构和修改流程图均应基于此字段**
- `svgContent`：完整原始 SVG 文本（含渲染图形元素，可作补充参考）
- 使用 `--save` 时返回 `savedTo`（本地文件路径）和 `mxGraphXml`，`svgContent` 为空

**URL 提取方式**：从 CitadelMD 中 `:::drawio{src="<url>"}:::` 的 `src` 属性值直接获取。

示例：
```bash
oa-skills citadel fetchDrawio --drawioUrl "https://km.sankuai.com/api/file/cdn/2756933117/231968350264?contentType=0&isNewContent=false"
```

### 生成并插入 AI draw.io 流程图到学城文档

执行 [references/generate-drawio.md](references/generate-drawio.md) 文件里的具体步骤，由 AI 生成 draw.io 流程图并插入到指定学城文档。

**整体流程**：

1. AI 根据用户描述，生成 mxGraph XML（仅含 `<mxCell>` 元素列表）
2. 将 XML 写入临时文件
3. 调用 `uploadDrawioToDocument` 上传到目标文档（自动包装 SVG 格式）
4. 将返回的 `drawioMd` 插入到文档指定位置（getDocumentCitadelMd → 插入 → updateDocumentByMd）

```bash
# 上传 AI 生成的 draw.io 流程图（mxCell XML 文件）
oa-skills citadel uploadDrawioToDocument --contentId <文档ID> --file /tmp/diagram.xml

# 支持自定义画布尺寸（复杂流程图可增大）
oa-skills citadel uploadDrawioToDocument --contentId <文档ID> --file /tmp/diagram.xml --width 1200 --height 800
```

**CitadelMD drawio 语法**（上传成功后返回，直接插入文档）：

```
:::drawio{src="https://km.sankuai.com/api/file/cdn/<contentId>/<attachmentId>?contentType=0&isNewContent=false" width=800 height=600}:::
```

> 📖 **完整生成规则和 mxCell XML 示例**：查看 [references/generate-drawio.md](references/generate-drawio.md)，包含节点样式、连线路由规则、防止重叠的布局约束，以及修改已有流程图的完整流程。

**修改已有流程图**：先 `fetchDrawio` 获取 `mxGraphXml`，AI 修改后重新 `uploadDrawioToDocument`，再替换文档中的 `:::drawio{...}:::` 节点。

## 约束

- 所有文档内容编辑必须走 `updateDocumentByMd` 流程（先 `getDocumentCitadelMd` → 修改 → `updateDocumentByMd` 回传）
- 缺少关键参数时只追问必要字段（contentId / templateId / keyword / title），不给笼统报错
- 用户给了 km 链接时按 URL 规则直接提取 ID（contentId / parentId / templateId / copyFrom）执行，不要反复确认
- **创建文档时，若用户未明确指定父文档或空间，禁止从上下文中自动沿用任何文档 ID 作为 `--parentId`**；默认不传 `--parentId` / `--spaceId`，由系统创建在个人空间根目录
- **在大象群里创建文档后，必须执行两步授权**：① 为当前群授予浏览权限（`oa-skills citadel grant --url https://km.sankuai.com/collabpage/<id> --xm-group-ids <群ID> --perm "仅浏览"`）；② 为群助理的管理员（mis）授予管理权限（`oa-skills citadel grant --url https://km.sankuai.com/collabpage/<id> --person <管理员mis> --perm "可管理"`）；两步缺一不可
- **每次 `createDocument` 成功后，必须做授权收尾判断**：先询问用户"文档已创建，是否需要为特定人员/群组授权？"；如果场景是大象群，直接执行两步授权；如果是单聊或其他场景，询问用户是否需要授权并按需执行
- 在"复制模板/按模板创建"场景，禁止先 `getMarkdown` 再 `createDocument --content`；优先 `--copyFrom`（尤其学城文档2.0）
- 在"查看模板内容"场景，优先 `getTemplateMarkdown`，不要调用 `getMarkdown`
- `getRecentlyViewed` 用 `--pageNo`（从 1 开始），其他命令用 `--offset`（从 0 开始）
- **插入图片到文档时，严禁直接将非学城图片 URL 插入 CitadelMD**；必须先调用 `uploadImageToDocument` 将图片上传到目标文档，再将返回的 `imageMd`（学城图片 CitadelMD 语法）插入文档
- **插入附件到文档时，严禁将非学城附件 URL 直接写入 CitadelMD**；必须先调用 `uploadAttachmentToDocument` 将本地文件上传到目标文档，再将返回的 `attachmentMd`（学城附件 CitadelMD 语法）插入文档。**`uploadAttachmentToDocument` 仅限 PDF、Word、Excel、ZIP 等非媒体文件；视频必须用 `uploadVideoToDocument`，音频必须用 `uploadAudioToDocument`，绝对不可混用**
- **插入视频到文档时，严禁将非学城视频 URL 直接写入 CitadelMD**；必须先调用 `uploadVideoToDocument` 将本地视频上传到目标文档，再将返回的 `videoMd`（学城视频 CitadelMD 语法）插入文档
- **插入音频到文档时，严禁将非学城音频 URL 直接写入 CitadelMD**；必须先调用 `uploadAudioToDocument` 将本地音频上传到目标文档，再将返回的 `audioMd`（学城音频 CitadelMD 语法）插入文档
- **插入内嵌多维表格时，如果是在学城文档内新建表格，不需要先创建多维表格文档**；直接使用 `createTable --contentId <文档ID>` 即可。若是复制到学城文档再插入，固定使用 `copyTable --targetType 3`。然后使用 `getDocumentCitadelMd` + `updateDocumentByMd` 插入 `:::xtable{xtableId="<tableId>"}:::`，不要直接伪造表格数据节点；`nodeId` 的处理遵循 `doc-syntax.md`：已有值保留，新增时可省略
- **生成或编辑文档内容时，`:::title:::` 节点必须是文档的第一个节点，有且只有一个**；`title` 是文档标题节点，与 `heading`（正文中的章节标题样式）完全不同，不可混用。
- **编辑复杂表格时，优先改 `:::table_cell` / `:::table_header` 宏块内部正文，不要把表格还原或重写成 JSON**
- **`addFullTextComment` 频次限制**：每次 AI 会话、每篇文档最多调用 1 次 `addFullTextComment`，禁止在循环或批量流程中重复调用；如需回复某条评论，先用 `getFullTextComments` 获取目标评论 ID，确认 `--parentCommentId` 正确后再发送
- **`addDiscussionComment` 频次限制**：每次 AI 会话、每篇文档最多调用 1 次 `addDiscussionComment`，禁止批量循环添加划词评论；`nodeId` 和 `stepVersion` 必须通过 `getDocumentCitadelMd` 实时获取，不要猜测或复用旧值
- **`replyDiscussionComment` 频次限制**：每次 AI 会话、每篇文档最多调用 1 次 `replyDiscussionComment`；`discussionId` 和 `quoteId` 必须通过 `getDiscussionComments` 获取，确认正确后再发送

## 暂不支持

以下能力当前 **不可用**，不要伪造执行结果：


- 若用户要求"复制后再填充内容"，先按 `--copyFrom` 创建，再说明当前不支持自动编辑已创建文档。
- 替代方案：先用 `getMarkdown` 读取内容，在本地生成修改建议。

## 认证

根据运行环境选择合适的策略，优先 SSO 无感登录。Token 自动缓存。

认证失败 → `oa-skills citadel --clear-cache` 后重试
- 如需强制走 CIBA 认证，可额外添加 `--force-ciba`（仅在认证异常时兜底使用，正常不需要添加）

## 验证

执行完成后确认：

1. 命令退出码为 0
2. 读取类：返回了文档内容/列表
3. 创建类：返回了新文档 contentId 和链接
4. 给用户简明结论（标题、ID、数量），而非原始数据

## skill使用问题反馈

如果遇到skill的使用问题，请提[TT|https://tt.sankuai.com/public/create?cid=17&tid=357&iid=46802]进行反馈
