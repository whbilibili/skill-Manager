---
name: citadel
description: "学城官方Skill：学城 km/wiki/citadel/km.sankuai.com 自动化操作工具，直接调用线上接口，响应速度更快。支持读取文档信息和内容、获取模板内容、读取文档的目录、查询文档统计信息、总结文档内容、获取文档元信息（父文档ID、标题、创建者、所有者等）、查询当前文档的子文档列表，创建新的学城文档、改文档（插入图片/附件/视频/音频到文档）、删文档、复制学城文档、从模板创建学城文档、移动文档到其他文档下或者指定空间下，支持搜索学城文档，并支持查询用户的最近编辑/浏览、收到的文档、被@的文档、评论过的文档、全文评论和划词评论内容、添加划词评论、回复划词评论，以及批量盘点权限、批量授权、批量修改/移除权限、权限继承、清空权限、链接分享权限和空间管理员操作，以及由 AI 生成 draw.io 流程图并插入文档、获取知识广场文章列表（推荐/最新/关注），支持获取文档历史版本列表、查看历史版本文档内容、还原文档到指定历史版本，以及读取文档内嵌数据图表的具体数据、在文档中新建数据图表、编辑已有数据图表的数据和配置（图表类型、标题）。当用户提到 km.sankuai.com 链接、collabpage、contentId、parentId、pageId、学城、文档、知识库、km、wiki、父文档、创建者、所有者、插入图片到文档、插入附件到文档、插入视频到文档、插入音频到文档、搜索文档、查找文档、学城权限、权限继承、空间管理员、链接分享权限、流程图、Drawio、draw.io、生成流程图、创建流程图、插入流程图、流程图插入文档、知识广场、广场文章、被@的文档、@我、评论过的文档、划词评论、选区评论、添加评论、引用评论、回复评论、历史版本、版本记录、修改历史、恢复文档、还原文档、回滚版本、数据图表、图表数据、chartId、读取图表、获取图表数据、新建图表、创建图表、插入图表、编辑图表、修改图表数据、更新图表、图表类型、折线图、柱状图、饼图、面积图时激活。通过 oa-skills citadel CLI 执行。禁止通过 browser-agent 或任何 GUI 方式尝试学城文档的编辑操作。此类操作极大概率导致文档数据异常而无法正常访问。如无法基于citadel skill进行编辑，请提TT工单"

metadata:
  skillhub.creator: "rui.zou"
  skillhub.updater: "rui.zou"
  skillhub.version: "V38"
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

## 用户偏好记忆

citadel skill 在用户本地维护一个独立的记忆文件，用于跨会话保留用户习惯。记忆文件的格式规范和建议场景见 [references/user-memory.md](references/user-memory.md)。

**记忆文件路径**：`~/.cache/oa-skills/citadel-memory.md`

### 读取

每次 skill 激活时执行：

```bash
node -e "const fs=require('fs'),os=require('os'),path=require('path');const f=path.join(os.homedir(),'.cache','oa-skills','citadel-memory.md');try{process.stdout.write(fs.readFileSync(f,'utf8'))}catch{}"
```

- 若文件存在：将内容加载到上下文，后续操作按需查阅对应章节。
- 若文件不存在：按无偏好状态继续执行，**不要主动创建**，等到用户首次触发写入时再创建。

### 写入

当用户说出以下任意触发词时，执行记忆写入：

**写入触发词（以下任意一类均触发）**：
- 记住偏好：「记住这个」「以后都这样」「记住我的习惯」「记住我的偏好」「记下来」「下次自动...」
- 记住位置：「以后都放这里」「记住这个目录」「默认创建在 XXX 下」
- 记住模板：「记住这个模板」「这个模板叫做 XX」「以后用 XX 模板」
- 记住密级：「以后默认设为 CX」「记住我通常用 CX」「默认密级是 CX」
- 清除偏好：「取消默认」「清除记忆」「忘掉这个」「不用记住了」「删除 XX 模板」

**写入流程**：

1. 若文件不存在，先按 [references/user-memory.md](references/user-memory.md) 中的"初始模板"创建文件（目录不存在时自动创建）：
   ```bash
   node -e "const fs=require('fs'),os=require('os'),path=require('path');const d=path.join(os.homedir(),'.cache','oa-skills');fs.mkdirSync(d,{recursive:true})"
   ```
   然后用 AI 将初始模板内容写入 `~/.cache/oa-skills/citadel-memory.md`（实际路径见 Node.js 的 `os.homedir()` 返回值）。
2. 用 AI 编辑 `~/.cache/oa-skills/citadel-memory.md` 中对应章节，写入格式参照 [references/user-memory.md](references/user-memory.md) 中对应场景的格式说明。
3. 只修改目标章节，其他章节保持不变。
4. 写入完成后告知用户："已记住你的偏好，下次操作时自动应用。"

### 使用

记忆文件加载后，执行相关操作时按需查阅对应章节：

- **创建文档，用户未指定位置时**：查阅 `## 创建文档默认位置`，有值则询问用户是否沿用。
- **用户说"用我的[别名]模板"时**：查阅 `## 常用文档模板`，匹配别名后直接使用对应 templateId。
- **`createDocument` 成功后的收尾**：查阅 `## 文档默认密级`，有值则询问用户是否设置密级。

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

1. 用户意图是"创建/新建/生成/复制文档"时，优先走 `createDocument`，不要因为出现 km 链接就先 `getSimpleMarkdown`。
2. 在创建意图里，链接只用于提取 ID：
   - 目标目录链接（`collabpage/<id>` / `page/<id>`）→ `--parentId <id>`
   - 模板中心链接（`template-center/<id>`）→ `--templateId <id>`
   - 来源文档链接（`collabpage/<id>` / `page/<id>`）→ `--copyFrom <id>`
3. 用户意图是"查看模板内容"时，执行 `getTemplateSimpleMarkdown`，不要走 `getSimpleMarkdown`。
   - 但如果用户意图是"基于模板修改内容再创建文档"（如"按模板改好内容后创建"、"基于模板填写后生成"），应使用 `getTemplateXml` 获取完整 XML，AI 修改后通过 `createDocument --file` 创建；不要用 `getTemplateSimpleMarkdown`（简化版会丢失 nodeId 等关键信息）。
4. 只有用户明确要求"阅读/查看/总结文档内容"且目标是文档正文时，才执行 `getSimpleMarkdown`。
5. **群权限管理**：如果是在大象群里创建文档，创建后需要执行两步授权：
- 为当前群授予浏览权限：`oa-skills citadel grant --url https://km.sankuai.com/collabpage/<id> --xm-group-ids <群ID> --perm "仅浏览"`
- 为群助理的管理员（mis）授予管理权限：`oa-skills citadel grant --url https://km.sankuai.com/collabpage/<id> --person <管理员mis> --perm "可管理"`
6. **创建后的授权收尾**：每次 `createDocument` 成功后，必须询问用户："文档已创建，是否需要为特定人员/群组授权？"；若当前场景是大象群，则自动执行两步授权；若是单聊或其他场景，则询问用户是否需要授权，按需执行。


### 读取学城文档 markdown（仅在阅读/总结意图下）

```bash
getSimpleMarkdown --contentId <id>
```

> **说明**：`getSimpleMarkdown` 为当前推荐命令，输出简化版 Markdown，token 消耗更低，适合阅读和总结。
> 命令**仅供阅读**，不可直接用于创建或更新文档。

### 获取模板内容

根据使用意图选择命令：

```bash
# 仅阅读/理解模板结构（推荐，token 消耗更低，不可用于编辑回传）
getTemplateSimpleMarkdown --templateId <id>

# 基于模板修改内容再创建文档（完整 XML，保留 nodeId，可编辑后通过 createDocument --file 创建）
getTemplateXml --templateId <id>
```

**选择规则**：
- 用户只是"查看/了解模板"→ 用 `getTemplateSimpleMarkdown`
- 用户要"按模板修改内容后创建文档" → 用 `getTemplateXml`，AI 修改 XML 后写入临时文件，再 `createDocument --file /tmp/new-doc.xml`

示例：

- `https://km.sankuai.com/template-center/2751442505?isRelease=1` → `--templateId 2751442505`
- `getTemplateSimpleMarkdown --templateId 2751442505`
- `getTemplateXml --templateId 2751442505`

### 获取协作文档模板列表

当用户说"我的模板"、"个人模板"、"分享给我的模板"、"公共模板"、"查看模板列表"时，执行：

```bash
# 查看我创建的模板（默认）
listPersonalTemplates

# 查看分享给我的模板
listPersonalTemplates --type shared

# 查看公共模板
listPersonalTemplates --type public

# 分页
listPersonalTemplates --type personal --pageNo 2 --pageSize 16
```

**参数说明**：
- `--type`：`personal`=我创建的（默认），`shared`=分享给我的，`public`=公共模板
- `--pageNo`：页码，从 1 开始，默认 1
- `--pageSize`：每页数量，默认 16

**输出内容**：模板总数、模板 ID（`templateId`）、模板标题、创建者、修改者、创建/修改时间。获得 `templateId` 后可传给 `getTemplateSimpleMarkdown` 或 `getTemplateXml` 查看模板内容，或传给 `createDocument --templateId` 基于模板创建文档。

### 总结学城文档

执行 [references/doc-summary.md](references/doc-summary.md) 文件里的具体步骤，输出总结结果。

### 查看当前学城文档的子文档、文档结构和内容、parentId 下的文档目录

```bash
getChildContent --contentId <id>
```

### 创建/新建学城文档

> ⚠️ **创建文档前的 XML 合规要求**（必读，违反会导致创建的文档内容为空或数据丢失）：
> 1. **根标签只能是 `<km-doc>`**，禁止使用 `<doc>`、`<document>`、`<body>` 等任何其他标签
> 2. **`<km-title>` 必须是第一个子节点，有且只有一个**
> 3. **`<km-markdown>` / `<km-html>` / `<km-plantuml>` 内容必须用 `<![CDATA[...]]>` 包裹**
> 4. **禁止使用 `<div>`、`<section>`、`<thead>`、`<tbody>` 等 HTML 布局标签**（会被静默丢弃）
> 5. 详见 [references/doc-xml-syntax.md](references/doc-xml-syntax.md) 末尾的「AI 生成前的自检清单」

> ⚠️ **位置默认规则（必须遵守）**：
> - 用户**未明确指定**创建位置（未给 `--parentId` 或 `--spaceId`）时，**一律不加这两个参数**，由系统自动创建在当前用户个人空间根目录。
> - **禁止**从上下文中自动猜测或沿用任何文档 ID 作为 `--parentId`。只有用户明确说"在 XXX 文档下创建"或"创建为 XXX 的子文档"时，才传 `--parentId`。

> 📝 **内容传递方式（优先使用文件方式）**：
> - **文档内容较多时（超过几段正文），必须优先将内容写入本地文件，再通过 `--file` 参数传入**，避免在命令行中直接输出大段内容导致 AI 输出过大。
> - 只有内容极短（单行标题、简短说明等）且用户无额外需求时，才可直接用 `--content` 参数内联传入。
> - 使用文件方式时，先将内容写入临时文件（如 `/tmp/new-doc.xml`），再传 `--file`。

```bash
# 【推荐】将文档内容写入本地文件后创建（文档较长时必须使用此方式）
createDocument --title <标题> --file /tmp/new-doc.xml

# 【推荐】创建为指定文档的子文档（用户明确指定了父文档时）
createDocument --title <标题> --file /tmp/new-doc.xml --parentId <父文档id>

# 仅适用于内容极短的场景（几个词/单行，慎用）
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

`createDocument` 的 `--file` / `--content` 参数自动识别格式，**优先使用原始 Markdown 文件传入**，无需转换为 XML。

#### 场景一：用户已有 Markdown 文件（最常见，直接 --file 传入）

> ✅ **原生 Markdown（`.md`）文件可直接传给 `--file`**，系统会自动将 Markdown 转为学城文档格式。
> 不要把 MD 内容套进 `<km-markdown>` 再包成 XML——那样做反而更容易出错。

```bash
# 用户已有 /tmp/report.md，直接创建学城文档
oa-skills citadel createDocument --title "技术方案" --file /tmp/report.md --parentId <id>

# 无父文档时（创建到个人空间）
oa-skills citadel createDocument --title "技术方案" --file /tmp/report.md
```

`--file` 支持的格式（自动识别，无需手动指定）：
- **原生 Markdown**（`.md`）：直接支持，内容按标准 Markdown 语法解析
- **CitadelXML**（`.xml`）：含 `<km-doc>` 根节点的学城扩展 XML
- **CitadelMD**（`.citadelmd`）：含学城专属宏语法的 Markdown 变体
- **ProseMirror JSON**（`.json`）：文档底层 JSON

#### 场景二：内容极短，内联传入

```bash
# 少量内容可直接用 --content 内联（支持 Markdown）
oa-skills citadel createDocument --title "会议纪要" --content "# 主要结论\n- 下周启动" --parentId <id>
```

#### 场景三：需要学城专属节点时，才使用 CitadelXML

仅当文档需要折叠块、高亮提示框、脑图、draw.io 流程图等学城专属节点时，才需要 CitadelXML 格式。

> ⚠️ **使用 CitadelXML 时的合规要求**（违反会导致内容为空或数据丢失）：
> 1. **根标签只能是 `<km-doc>`**，禁止其他任何前缀
> 2. **`<km-title>` 必须是第一个子节点，有且只有一个**
> 3. **`<km-markdown>` / `<km-html>` / `<km-plantuml>` 内容必须用 `<![CDATA[...]]>` 包裹**
> 4. **禁止使用 `<div>`、`<section>`、`<thead>`、`<tbody>` 等 HTML 布局标签**（会被静默丢弃）
> 5. **禁止用 `<km-markdown>` 来包裹普通 Markdown 内容**——普通 Markdown 直接用 `--file report.md` 传入即可，`<km-markdown>` 仅适用于无法用标准节点表达的 LaTeX / 特殊语法片段
> 6. 详见 [references/doc-xml-syntax.md](references/doc-xml-syntax.md) 末尾的「AI 生成前的自检清单」

```bash
# 仅需学城专属节点时才用 XML 文件
oa-skills citadel createDocument --title "新文档" --file /tmp/new-doc.xml --parentId <id>
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
  - `--status` 为数字：`1` 开启，`0` 关闭（**不是** `open`/`close`）
  - `--perm` 为数字：`0`=可浏览评论，`1`=可编辑，`5`=仅浏览（**不是**中文文字）
  - 示例：`oa-skills citadel share-perm --url "https://km.sankuai.com/collabpage/<id>" --status 1 --perm 5`
- 增加或移除空间管理员：`space-admin`

### 编辑学城文档/更新学城文档内容/插入新内容到学城文档

执行 [references/doc-update.md](references/doc-update.md) 文件里的具体步骤，进行安全的文档更新，**禁止直接操作修改 JSON 数据以及通过 GUI 方式进行编辑操作**。

> ⚠️ **编辑前的 XML 合规要求**（每次修改 XML 文件后、执行 `updateDocumentByXml` 前必须自检）：
> 1. **保留原有根标签 `<km-doc>`**，不要改写为任何其他形式
> 2. **保留原有 `<km-title>` 节点，位置不变**；只修改内容，不要删除或移位
> 3. **不要引入 `<div>`、`<section>`、`<thead>`、`<tbody>` 等禁止标签**
> 4. **不要新造不存在于规范的 `km-*` 标签**（如 `<km-heading>`、`<km-paragraph>`、`<km-code-block>`）
> 5. **`<km-markdown>` / `<km-html>` / `<km-plantuml>` 内容必须保留 `<![CDATA[...]]>` 包裹**
> 6. 详见 [references/doc-xml-syntax.md](references/doc-xml-syntax.md) 末尾的「AI 生成前的自检清单」

> **所有内容编辑统一走 XML 路径，必须使用本地文件传入，禁止在命令行内联大段内容**：
>
> ```bash
> # 第一步：获取文档 XML，保存到本地文件
> oa-skills citadel getDocumentXml --contentId <id> --output /tmp/doc.xml
>
> # 第二步：AI 编辑本地 /tmp/doc.xml 文件（语法见 references/doc-xml-syntax.md）
>
> # 第三步：通过文件回传（--file 方式，禁止内联传入内容）
> oa-skills citadel updateDocumentByXml --contentId <id> --file /tmp/doc.xml --step-version <stepVersion>
> ```
>
> 📝 **文件方式是硬性要求**：
> - **文档内容超过几行时，必须通过 `--output` 保存到本地文件，AI 编辑后再通过 `--file` 传入**
> - **禁止**将修改后的大段 XML 内容直接拼接在命令行参数里执行，会导致 AI 输出过大、shell 截断等问题
> - 临时文件路径建议使用 `/tmp/doc-<contentId>.xml`
>
> 处理编辑请求时，必须严格遵守以下通用原则：
> - **每次编辑必须重新拉取最新内容**：每一轮编辑请求都必须重新执行获取命令，**禁止基于对话记忆或上一次拉取的内容直接发起覆盖写入**。用户在 AI 两次编辑之间可能手动修改了文档，若 AI 以"记忆中的旧内容"为基础写回，会覆盖用户手动编辑的内容，造成数据丢失。
> - **先读后改**：必须先获取文档内容，禁止在未读取原文的情况下凭空生成整篇文档内容覆盖回传
> - **最小改动**：只修改用户明确要求的那几处；无关节点、属性、顺序、样式一律保持原样
> - **不要做格式化重写**：禁止把整篇内容"重新整理""统一格式""批量改写"为另一种等价写法
> - **保留所有已有节点的 nodeId**：已有节点的 `nodeId` 属性必须保留；新增节点可省略
> - **如果用户只是补充/替换一小段**，优先在原位置做局部修改，不要整段重写
>
> 详细编辑规则见 [references/doc-xml-syntax.md](references/doc-xml-syntax.md)（标签语法、宏节点规则、自检清单）

**输出**：返回编辑文档的链接，提醒用户需要刷新当前页面才能看到更新内容。

#### 修改文档标题

> ⚠️ **文档标题存储在文档内容的标题节点中，单独传 `--title` 参数无法真正更新标题**，必须同时修改内容文件中的标题节点。

正确做法（**两处都必须改**）：

1. 获取文档 XML 并保存到本地：
   ```bash
   oa-skills citadel getDocumentXml --contentId <id> --output /tmp/doc.xml
   ```
2. 修改 `/tmp/doc.xml` 中 `<km-title>` 标签内的文字为新标题
3. 通过文件回传，同步传入 `--title` 参数：
   ```bash
   oa-skills citadel updateDocumentByXml --contentId <id> --file /tmp/doc.xml --step-version <stepVersion> --title "新标题"
   ```

标题节点（正文层）和 `--title` 参数（元数据层）**缺一不可**，否则标题更新不完整。

### 将 AI 生成的内容（图片、附件）或本地文件（包括视频、音频）插入到学城文档

执行 [references/doc-insert.md](references/doc-insert.md) 文件里的具体步骤，将 AI 生成的图片、本地文件、本地视频或本地音频安全插入到指定学城文档。

- **插入图片**：**严禁直接将非学城图片 URL 插入文档**，必须先调用 `uploadImageToDocument` 上传，再将返回的图片 XML 节点插入文档。
- **插入附件**：**严禁将非学城附件 URL 直接写入文档**，必须先调用 `uploadAttachmentToDocument` 上传（仅限 PDF/Word/Excel/ZIP 等非媒体文件，**视频和音频禁止用此命令，否则 URL 无法正确转换为 CDN 格式**）。
- **插入视频**：**严禁将非学城视频 URL 直接写入文档**，必须先调用 `uploadVideoToDocument` 上传，再将返回的视频 XML 节点插入文档。
- **插入音频**：**严禁将非学城音频 URL 直接写入文档**，必须先调用 `uploadAudioToDocument` 上传，再将返回的音频 XML 节点插入文档。
- **插入内嵌多维表格**：如果是在现有学城文档里新建表格，直接调用 `oa-skills citadel-database createTable --contentId <文档ID> --tableTitle <表格名>`，这里的 `contentId` 就是目标学城文档 ID；如果是复制已有表格到学城文档，则调用 `oa-skills citadel-database copyTable --sourceTableId <源表ID> --targetParentId <文档ID> --targetType 3`。随后再沿用 `getDocumentXml` → 插入 `<km-xtable xtableId="<tableId>" />` → `updateDocumentByXml` 流程完成文档插入；新增节点时 `nodeId` 可省略，若文档里已存在该节点则保留原值。

**输出**：返回文档链接，提醒用户刷新页面查看插入的内容（图片/附件/视频/音频/内嵌多维表格）。

### 将多维表格内嵌到学城文档

当用户要求"在学城文档中插入/嵌入多维表格"时，按下面流程处理：

1. **先创建或复制多维表格**
   - 在现有学城文档内新建表格：调用 `oa-skills citadel-database createTable --contentId <目标文档ID> --tableTitle <表格名>`，其中 `contentId` 就是目标学城文档 ID，不需要先创建多维表格文档；返回值里的 `tableId` 仅用于后续数据读写
   - 复制已有数据表到目标学城文档：调用 `oa-skills citadel-database copyTable --sourceTableId <源表ID> --targetParentId <目标文档ID> --targetType 3`。内嵌到学城文档时固定使用 `type=3`
2. **再走学城文档插入链路**
   - `getDocumentXml --contentId <目标文档ID> --output doc.xml`
   - 在目标位置插入 `<km-xtable xtableId="<tableId>" />`（新增节点时可不写 `nodeId`；若是编辑已有节点则保留原值）
   - `updateDocumentByXml --contentId <目标文档ID> --file doc.xml --step-version <stepVersion>`
3. **能力边界**
   - `citadel` 负责文档插入和内容更新
   - 多维表格的数据创建、复制、读写统一走 `oa-skills citadel-database`
   - `<km-xtable>` 是文档中的多维表格引用节点，不要把表格数据直接手写进文档

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

支持指定空间或者指定文档范围搜索：

```bash
# 通过空间链接指定（spaceKey 格式，如 /space/citadel）
searchContent --keyword <关键词> --space-url "https://km.sankuai.com/space/citadel"

# 通过空间链接指定（spaceId 格式，如 /space/27）
searchContent --keyword <关键词> --space-url "https://km.sankuai.com/space/27"

# 通过空间 ID 直接指定
searchContent --keyword <关键词> --space-id 27

# 通过文档链接指定搜索范围（含空间最多 5 个，逗号分隔）
searchContent --keyword <关键词> --parent-urls "https://km.sankuai.com/collabpage/1346135471,https://km.sankuai.com/collabpage/1343126899"

# 通过文档 ID 指定搜索范围（含空间最多 5 个，逗号分隔）
searchContent --keyword <关键词> --parent-ids "1346135471,1343126899"
```

**如何获取空间链接**：在学城打开目标空间，浏览器地址栏的 URL 即为空间链接，支持两种格式：
- `https://km.sankuai.com/space/<spaceKey>`（如 `/space/citadel`）
- `https://km.sankuai.com/space/<spaceId>`（如 `/space/27`，纯数字）

**说明**：
- 该接口支持安全屋策略，**非安全屋模式下不会返回 C4 文档**。CLI 会在结果末尾自动提示"非安全屋模式下不会返回 C4 文档，如需查看完整结果请打开安全屋模式。"，安全屋模式下无此提示。
- 返回结果含文档 ID、标题、空间名、作者、更新时间和内容摘要。
- `--searchTitle` 仅匹配文档标题（不搜正文）；不加此参数则全文搜索。
- `--space-url` 和 `--space-id` 二选一，用于将搜索范围限定在某个空间内。
- `--parent-ids` 和 `--parent-urls` 二选一，用于将搜索范围限定在指定文档内，含空间最多 5 个，会自动通过文档元信息接口获取标题后传入搜索接口。

### 获取/查看用户（mis）最近编辑了什么文档

```bash
getLatestEdit --limit 10
```

**说明**：
- 返回的是当前用户最近编辑的文档列表。虽然文档的最后编辑人可能不是当前用户（当前用户编辑后可能还有其他用户继续编辑），但该列表本身就是当前用户最近编辑的文档列表，**无需对返回结果进行二次筛选**。

### 获取/查看用户（mis）最近浏览了什么文档

```bash
getRecentlyViewed --pageSize 10
```

### 获取/查看用户（mis）别人发的/收到的学城文档

```bash
getReceivedDocs --limit 10
```

### 获取用户被@的文档列表

```bash
getMentionedDocs --limit 10
```

### 获取我评论过的文档列表

```bash
getCommentedDocs --limit 10
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

### 删除全文评论

当用户要求删除某条全文评论时：

**⚠️ 高风险操作，必须满足以下前置条件才能执行**：
1. **必须先获得用户明确确认**：展示将要删除的评论内容（ID + 内容），请用户确认后再执行。
2. **单次只能删除一条**：不支持批量删除，禁止循环调用。
3. **不可撤销**：删除后无法恢复，执行后告知用户此限制。

**操作步骤**：

```bash
# 第一步：获取评论列表，确认要删除的评论 ID 和内容
getFullTextComments --contentId <id>

# 第二步：向用户展示目标评论内容并请求确认，确认后执行删除
deleteFullTextComment --contentId <id> --commentId <评论ID>
```

> ⚠️ **停止条件**：若用户未明确确认、或意图不清晰，**禁止执行删除**。

### 删除划词评论（主评论或回复）

当用户要求删除某条划词评论或划词评论下的回复时：

**⚠️ 高风险操作，必须满足以下前置条件才能执行**：
1. **必须先获得用户明确确认**：展示将要删除的评论内容（ID + 内容），请用户确认后再执行。
2. **单次只能删除一条**：不支持批量删除，禁止循环调用。
3. **不可撤销**：删除后无法恢复，执行后告知用户此限制。

**参数说明**：
- `discussionId`：对应 `getDiscussionComments` 返回列表中的 `commentId` 字段（顶层 discussion 的 ID）
- `commentId`：要删除的具体评论 ID（删除主评论时与 discussionId 相同，删除回复时为 replies[].commentId）
- `quoteId`：删除主评论时传空字符串 `""`，删除回复时传 `replies[].quoteId`

**操作步骤**：

```bash
# 第一步：获取划词评论列表，确认要删除的评论内容
# 返回结果中：commentId = discussionId，replies[].commentId = 回复评论 ID
getDiscussionComments --contentId <id>

# 第二步：展示评论内容并请用户确认，确认后执行删除

# 删除主评论（quoteId 传空）
deleteDiscussionComment --contentId <id> --discussionId <discussionId> --commentId <commentId> --quoteId ""

# 删除回复（quoteId 从 replies[].quoteId 获取）
deleteDiscussionComment --contentId <id> --discussionId <discussionId> --commentId <回复ID> --quoteId <quoteId>
```

> ⚠️ **停止条件**：若用户未明确确认、或意图不清晰，**禁止执行删除**。

### 为文档段落/标题节点添加划词评论

当用户要求对文档特定段落或标题添加划词评论（选区评论/引用评论）时，执行两步操作（自动完成）：

**前置步骤：先获取目标节点的 nodeId 和当前 stepVersion**

```bash
# 第一步：获取文档 XML，从中确认目标段落的 nodeId 和 stepVersion
oa-skills citadel getDocumentXml --contentId <id>
```

- 输出中会有 `文档版本（stepVersion）：<数字>`
- XML 中每个节点会带有 `nodeId` 属性，例如 `<p nodeId="abc123">` → nodeId 为 `abc123`

**第二步：添加划词评论**

```bash
# 基本划词评论（对指定节点整体作为引用范围）
addDiscussionComment --contentId <id> --nodeId <nodeId> --stepVersion <版本号> --text "评论内容"

# 带 @提及
addDiscussionComment --contentId <id> --nodeId <nodeId> --stepVersion <版本号> --text "评论内容" --mention "zhangsan" --mentionNames "张三"
```

> ⚠️ **限制说明**：
> - 只支持对整个块节点添加划词（整节点作为引用范围），不支持对节点内部分文字范围划词
> - 每次 AI 会话每篇文档最多调用 1 次 `addDiscussionComment`，禁止批量循环调用
> - nodeId 和 stepVersion 必须通过 `getDocumentXml` 获取，不要猜测或伪造
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

当用户说"知识广场"、"广场文章"、"广场推荐"、"广场最新"等时，执行：

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

### 查看/还原文档历史版本

```bash
# Step 1：获取历史版本列表（最多 200 条，按时间降序；返回 stepVersion、title、editors 等）
oa-skills citadel getDocumentVersions --contentId <id>

# Step 2：获取目标版本的 CitadelXML 并保存（--stepVersion 取上一步返回的 stepVersion 字段，非 version 字段）
oa-skills citadel getDocumentVersionXml --contentId <id> --stepVersion <stepVersion> --output /tmp/restore.xml

# Step 3：还原文档（覆写当前内容，执行前先与用户确认目标版本）
oa-skills citadel updateDocumentByXml --contentId <id> --file /tmp/restore.xml
```

> 完整参数说明见 [references/cli-reference.md](references/cli-reference.md)

### 列出 CLI 支持的命令

```bash
listTools
```

> 完整参数说明、示例和输出格式见 [references/cli-reference.md](references/cli-reference.md)

### 下载或读取学城文档附件

**学城文档附件一律通过文枢 skill 处理，禁止直接下载。** 完整流程见 [references/doc-view.md](references/doc-view.md) 中"场景 A：下载"和"场景 B：读取内容"章节。以下为摘要：

#### 场景 A：下载附件（保存到本地）

**A-1** 从附件节点 URL（`> 📎 **附件**（大小）：[文件名](url)`）中提取 `fileId`（`?` 前最后一段数字）。

**A-2** 查询文枢策略，取得 `wenshuUrl`：

```bash
oa-skills citadel fetchAttachment --fileId "<fileId>"
```

若 `checkResult` 不为 `"PASS"`，立即停止并告知用户无权下载。

**A-3** 将 `wenshuUrl` 传入文枢 skill 下载（优先 `wenshu-tools`，不可用则 `wenshu-catdesk-tools`；两者均不可用则停止并提示用户安装文枢 skill，**禁止其他任何下载方式**）。文枢 skill 成功后返回本地文件路径。

#### 场景 B：读取附件内容（AI 解析文字）

在完成场景 A 下载后继续：

**B-1** 按场景 A 完成下载，取得本地文件路径。

**B-2** 根据文件类型解析：PDF → `pdf` skill；Word → `docx` skill；Excel/CSV → `xlsx` skill；纯文本 → `read_file`。

**B-3** 解析完成后**必须立即删除**本地临时文件：

```bash
rm -f "<B-1 返回的本地文件路径>"
```

> ⚠️ 学城附件属于内部敏感数据，即使 B-2 解析失败，也必须执行清理，禁止将临时文件长期留存本地。

### 读取文档内嵌数据图表的数据

当文档包含数据图表时，`getSimpleMarkdown` 输出中会显示占位行：
`> 📈 **数据图表**（id: <chartId>）`

通过以下命令获取该图表的完整表格数据和配置：

```bash
getChartData --contentId <文档ID> --chartId <chartId>
```

返回：
- `chartData.head`：列头定义（name/key/type）
- `chartData.body`：二维数据行
- `config`：图表配置（type/title/dataConfig 等）
- `config.dataConfig.source_id`：数据源 ID（编辑时必须）

### 在文档中新建数据图表

执行 [references/chart-insert.md](references/chart-insert.md) 中的完整步骤。

**整体流程**：

1. AI 准备表格数据（二维 JSON 数组，第 0 行为列名）
2. 写入本地临时文件（`/tmp/chart-data.json`）
3. 调用 `createAndInsertChart` 创建并发布图表，获取 `chartXml`
4. 通过 `getDocumentXml` → 在合适位置插入 `chartXml` → `updateDocumentByXml` 完成文档插入

```bash
# Step 1：将数据写入临时文件
# /tmp/chart-data.json 内容示例：
# [["月份","销量","利润"],["1月",100,20],["2月",150,35]]

# Step 2：创建图表并获取 chartXml
oa-skills citadel createAndInsertChart \
  --contentId <文档ID> \
  --title "月度销售趋势" \
  --type line \
  --data-file /tmp/chart-data.json

# Step 3：将返回的 chartXml 节点插入文档
# chartXml 形如：<km-data2chart chartId="xxxxxxxxxxxxxxxxxxxxxx" />
oa-skills citadel getDocumentXml --contentId <文档ID> --output /tmp/doc.xml
# AI 编辑 /tmp/doc.xml，在合适位置插入 chartXml
oa-skills citadel updateDocumentByXml --contentId <文档ID> --file /tmp/doc.xml --step-version <stepVersion>
```

**支持的图表类型**（`--type` 参数值）：

| 类型值 | 名称 | 数据要求 |
|--------|------|----------|
| `line` | 折线图 | 1维度 + 多数值 |
| `bar` | 柱状图 | 1维度 + 多数值 |
| `area` | 面积图 | 1维度 + 多数值 |
| `stack` | 堆叠图 | 1维度 + 多数值 |
| `rotatingBar` | 条形图 | 1维度 + 多数值 |
| `scatter` | 散点图 | 1维度 + 多数值 |
| `pie` | 饼图 | 1维度 + 1数值 |
| `ring` | 环图 | 1维度 + 1数值 |
| `funnel` | 漏斗图 | 1维度 + 1数值 |
| `nightingale` | 南丁格尔图 | 1维度 + 1数值 |
| `line,bar` | 折线+柱状混合图 | 1维度 + 多数值，逗号分隔传入 |

**混合图表示例**：

```bash
# 折线+柱状混合图（第一列数值显示为折线，第二列显示为柱状）
oa-skills citadel createAndInsertChart \
  --contentId <文档ID> \
  --title "销量与增长率" \
  --type line,bar \
  --data-file /tmp/chart-data.json \
  --sub-types "line,bar"
```

> 📖 **完整参数说明、各图表类型 config 示例和常见问题**：查看 [references/chart-insert.md](references/chart-insert.md)

### 编辑已有数据图表的数据

当需要更新文档内已有图表的表格数据时：

```bash
# Step 1：先读取图表，获取 chartId 和 config.dataConfig.source_id
oa-skills citadel getChartData --contentId <文档ID> --chartId <chartId>

# Step 2：准备新数据（写入本地文件）
# 示例：/tmp/new-data.json = [["月份","销量"],["1月",200],["2月",300]]

# Step 3：更新数据（AI 自动判断列结构是否变化，选择合适接口）
oa-skills citadel updateChartData \
  --contentId <文档ID> \
  --chartId <chartId> \
  --source-id <config.dataConfig.source_id> \
  --data-file /tmp/new-data.json
```

可选：同步更新标题或图表类型：

```bash
oa-skills citadel updateChartData \
  --contentId <文档ID> \
  --chartId <chartId> \
  --source-id <sourceId> \
  --data-file /tmp/new-data.json \
  --title "新标题" \
  --type bar
```

### 编辑已有数据图表的配置（图表类型/标题）

当只需修改图表类型或标题，不变更底层数据时：

```bash
# 只改图表类型（折线图 → 柱状图）
oa-skills citadel updateChartConfig \
  --contentId <文档ID> \
  --chartId <chartId> \
  --type bar

# 同时改标题和类型
oa-skills citadel updateChartConfig \
  --contentId <文档ID> \
  --chartId <chartId> \
  --title "新图表标题" \
  --type pie

# 改为混合图（折线+柱状），同时指定各数值列的子类型
oa-skills citadel updateChartConfig \
  --contentId <文档ID> \
  --chartId <chartId> \
  --type line,bar \
  --sub-types "line,bar"
```

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

**URL 提取方式**：从文档 XML 中 `<km-drawio src="<url>">` 的 `src` 属性值直接获取。

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
4. 将返回的 `drawioMd` 插入到文档指定位置（`getDocumentXml` → 插入 → `updateDocumentByXml`）

```bash
# 上传 AI 生成的 draw.io 流程图（mxCell XML 文件）
oa-skills citadel uploadDrawioToDocument --contentId <文档ID> --file /tmp/diagram.xml

# 支持自定义画布尺寸（复杂流程图可增大）
oa-skills citadel uploadDrawioToDocument --contentId <文档ID> --file /tmp/diagram.xml --width 1200 --height 800
```

> 📖 **完整生成规则和 mxCell XML 示例**：查看 [references/generate-drawio.md](references/generate-drawio.md)，包含节点样式、连线路由规则、防止重叠的布局约束，以及修改已有流程图的完整流程。

**修改已有流程图**：先 `fetchDrawio` 获取 `mxGraphXml`，AI 修改后重新 `uploadDrawioToDocument`，再通过 `getDocumentXml` → `updateDocumentByXml` 替换文档中的 drawio 节点。

## 约束

- 所有文档内容编辑统一走 XML 路径：`getDocumentXml` → 修改 → `updateDocumentByXml`
- **`getSimpleMarkdown` 仅供阅读和总结，禁止用其返回内容直接创建文档（createDocument --content）或更新文档（updateDocumentByXml）**，会丢失合并表格、宏节点、nodeId 等关键信息，导致文档损坏
- 缺少关键参数时只追问必要字段（contentId / templateId / keyword / title），不给笼统报错
- 用户给了 km 链接时按 URL 规则直接提取 ID（contentId / parentId / templateId / copyFrom）执行，不要反复确认
- **创建文档时，若用户未明确指定父文档或空间，禁止从上下文中自动沿用任何文档 ID 作为 `--parentId`**；默认不传 `--parentId` / `--spaceId`，由系统创建在个人空间根目录
- **创建/编辑文档内容时，必须使用 `--file` 参数传入本地文件，禁止将大段内容直接内联在命令行参数里**；只有内容极短（单行、几个词）时才允许内联；文档内容应先写入临时文件（如 `/tmp/new-doc.xml`），再执行 `createDocument --file` / `updateDocumentByXml --file` 命令；编辑时先用 `--output` 保存到本地文件，AI 修改后再用 `--file` 回传
- **在大象群里创建文档后，必须执行两步授权**：① 为当前群授予浏览权限（`oa-skills citadel grant --url https://km.sankuai.com/collabpage/<id> --xm-group-ids <群ID> --perm "仅浏览"`）；② 为群助理的管理员（mis）授予管理权限（`oa-skills citadel grant --url https://km.sankuai.com/collabpage/<id> --person <管理员mis> --perm "可管理"`）；两步缺一不可
- **每次 `createDocument` 成功后，必须做授权收尾判断**：先询问用户"文档已创建，是否需要为特定人员/群组授权？"；如果场景是大象群，直接执行两步授权；如果是单聊或其他场景，询问用户是否需要授权并按需执行
- 在"复制模板/按模板创建"场景，禁止先 `getSimpleMarkdown` 再 `createDocument --content`；优先 `--copyFrom`（尤其学城文档2.0）
- 在"查看模板内容"场景，优先 `getTemplateSimpleMarkdown`，不要调用 `getSimpleMarkdown`；在"基于模板修改内容后创建文档"场景，使用 `getTemplateXml`，不要用简化版（会丢失 nodeId 等关键信息）
- `getRecentlyViewed` 用 `--pageNo`（从 1 开始），其他命令用 `--offset`（从 0 开始）
- **插入图片到文档时，严禁直接将非学城图片 URL 插入文档**；必须先调用 `uploadImageToDocument` 将图片上传到目标文档，再将返回的图片 XML 节点插入文档
- **插入附件到文档时，严禁将非学城附件 URL 直接写入文档**；必须先调用 `uploadAttachmentToDocument` 将本地文件上传到目标文档，再将返回的附件 XML 节点插入文档。**`uploadAttachmentToDocument` 仅限 PDF、Word、Excel、ZIP 等非媒体文件；视频必须用 `uploadVideoToDocument`，音频必须用 `uploadAudioToDocument`，绝对不可混用**
- **插入视频到文档时，严禁将非学城视频 URL 直接写入文档**；必须先调用 `uploadVideoToDocument` 将本地视频上传到目标文档，再将返回的视频 XML 节点插入文档
- **插入音频到文档时，严禁将非学城音频 URL 直接写入文档**；必须先调用 `uploadAudioToDocument` 将本地音频上传到目标文档，再将返回的音频 XML 节点插入文档
- **插入内嵌多维表格时，如果是在学城文档内新建表格，不需要先创建多维表格文档**；直接使用 `createTable --contentId <文档ID>` 即可。若是复制到学城文档再插入，固定使用 `copyTable --targetType 3`。然后使用 `getDocumentXml` + `updateDocumentByXml` 将多维表格节点插入文档（XML 用 `<km-xtable xtableId="<tableId>" />`），不要直接伪造表格数据节点；新增节点时 `nodeId` 可省略，已有值保留
- **生成或编辑文档内容时，文档标题节点必须是文档的第一个节点，有且只有一个**（XML 路径为 `<km-title>`）；标题节点与 `heading`（正文中的章节标题样式）完全不同，不可混用
- **编辑复杂表格时，优先在原格式内做局部修改，不要把表格还原或重写成 JSON**（XML 路径直接改 `<tr>`/`<td>`/`<th>` 内容）
- **`addFullTextComment` 频次限制**：每次 AI 会话、每篇文档最多调用 1 次 `addFullTextComment`，禁止在循环或批量流程中重复调用；如需回复某条评论，先用 `getFullTextComments` 获取目标评论 ID，确认 `--parentCommentId` 正确后再发送
- **`addDiscussionComment` 频次限制**：每次 AI 会话、每篇文档最多调用 1 次 `addDiscussionComment`，禁止批量循环添加划词评论；`nodeId` 和 `stepVersion` 必须通过 `getDocumentXml` 实时获取，不要猜测或复用旧值
- **`replyDiscussionComment` 频次限制**：每次 AI 会话、每篇文档最多调用 1 次 `replyDiscussionComment`；`discussionId` 和 `quoteId` 必须通过 `getDiscussionComments` 获取，确认正确后再发送
- **`deleteFullTextComment` 高风险限制**：删除全文评论不可撤销，**必须先 `getFullTextComments` 获取评论内容，向用户展示后，获得明确确认再执行**；单次只能删除一条，禁止循环批量删除；若用户意图不明确，必须停止并追问
- **`deleteDiscussionComment` 高风险限制**：删除划词评论不可撤销，**必须先 `getDiscussionComments` 获取评论内容，向用户展示后，获得明确确认再执行**；单次只能删除一条，禁止循环批量删除；删除主评论时 `--quoteId` 传空字符串，删除回复时传 `replies[].quoteId`；若用户意图不明确，必须停止并追问
- **新建图表时，chartXml 不会自动插入文档**：`createAndInsertChart` 返回 `chartXml`（`<km-data2chart chartId="..." />`），AI 必须额外执行 `getDocumentXml` → 插入节点 → `updateDocumentByXml` 三步，才能将图表显示在文档中
- **编辑图表数据时，`source-id` 必须从 `getChartData` 的 `config.dataConfig.source_id` 字段获取**，不要猜测或伪造；未先调用 `getChartData` 就调用 `updateChartData` 属于违规操作
- **`updateChartConfig` 只改图表类型/标题，不涉及数据变更**；若用户同时要改数据和类型，应使用 `updateChartData`（支持可选的 `--type` 参数）
- **数据格式必须为二维 JSON 数组**，第 0 行为列名（字符串），后续行为数据行；数值列值可以是数字或数字字符串；禁止传入 CSV 文本或其他格式
- **混合图表 `--type` 传逗号分隔值**（如 `line,bar`）；`--sub-types` 按数值列顺序指定每列子类型（如 `line,bar`），数量必须与数值列数一致或省略

## 暂不支持

以下能力当前 **不可用**，不要伪造执行结果：


- 若用户要求"复制后再填充内容"，先按 `--copyFrom` 创建，再说明当前不支持自动编辑已创建文档。
- 替代方案：先用 `getSimpleMarkdown` 阅读文档内容，再对指定部分用 `getDocumentXml` + `updateDocumentByXml` 编辑。

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
