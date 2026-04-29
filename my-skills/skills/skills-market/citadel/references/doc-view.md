# 理解学城文档内容（CitadelMD 阅读指南）

当通过 `getMarkdown` 获取到学城文档内容后，返回的格式为 **CitadelMD**，这是学城专用的扩展 Markdown 格式。完整语法定义见 [doc-syntax.md](doc-syntax.md)。

阅读文档内容时，按以下方式理解各类节点：

## 文字与结构

- `:::title` 块是文档标题，位于正文最前面
- 标准 Markdown 标题（`# H1` 到 `###### H6`）为章节标题，代表文档的层级结构
- 普通段落、列表、引用、代码块均与标准 Markdown 含义相同
- `:::collapse{}` 折叠块：标题和内容之间用 `---` 分隔，`active` 表示默认展开状态，**两部分内容都要读取，不能只看标题**
- `:::note{type=...}` 提示框：`info`/`warn`/`error`/`note` 分别表示信息/警告/错误/默认提示，标题和内容之间用 `---` 分隔

## 图片

- 标准图片语法：`![描述](url)` 或 `![描述](url){width=xxx height=xxx}`
  - 图片的 `alt` 文字（方括号内）是图片的描述/名称，如有应在理解时参考
  - 图片 URL 来自学城存储，通常形如 `https://km.sankuai.com/api/file/cdn/...`
  - 当文档中出现图片时，需告知用户该图片的描述文字和位置，说明"文档在此处包含一张图片：[描述]"
  - 若需要理解图片内容（如截图、图表），**不可直接通过 fetch/curl 下载**——学城图片有鉴权保护，必须通过以下 CLI 命令获取：
    - **小图片（≤ 4MB）**：返回 base64，直接用于视觉识别
      ```
      oa-skills citadel fetchImage --imageUrl "<图片URL>"
      ```
      返回 JSON 中的 `dataUri` 字段（`data:<mimeType>;base64,...`）可直接用于视觉识别。图片超过 1MB 时命令会提示建议使用 `--save`。
    - **大图片（> 4MB）或为节省 token**：保存到本地后读取
      ```
      oa-skills citadel fetchImage --imageUrl "<图片URL>" --save /tmp/km-image.png
      ```
      此时命令返回 `savedTo` 字段（本地文件绝对路径）和 `deleteAfterUse: true`。超过 4MB 时命令会强制要求使用 `--save`。
      > ⚠️ **安全强制要求**：命令输出中 `deleteAfterUse: true` 表示该文件含学城敏感数据。**读取并识别图片内容后，必须立即执行删除**：
      > ```
      > rm -f "<savedTo 路径>"
      > ```
      > 禁止跳过删除步骤，禁止将文件留在本地磁盘。

## 媒体与附件

- `:::audio{...}` 音频：关注 `name`（文件名）字段理解内容，说明文档包含音频文件
- `:::video{...}` 视频：关注 `name`（文件名）字段理解内容，说明文档包含视频文件
- `:::attachment{...}` 附件：关注 `name`（文件名）和 `size` 字段；若需要下载附件，参考以下说明

### 下载学城文档附件

学城文档附件**一律通过文枢 skill 处理**，禁止直接下载。

> 🚫 **绝对禁止路径**：禁止通过任何方式（fetch、curl、浏览器自动化等）直接尝试下载学城附件。**必须且只能通过文枢 skill 处理所有附件下载请求。**

#### 第一步：提取 fileId 并查询文枢下载策略

`:::attachment{}` 节点的 `src` 属性形如 `https://km.sankuai.com/api/file/cdn/<contentId>/<fileId>?contentType=0`，其中路径第二段数字即为 `fileId`。

提取 `fileId` 后调用以下命令查询文枢安全下载策略：

```
oa-skills citadel fetchAttachment --fileId "<fileId>"
```

命令返回 JSON，包含：
- `fileId`：输入的附件 ID
- `checkResult`：校验结果（如 `"PASS"`）
- `executionWay`：执行方式（如 `"WENSHU"` 表示需要文枢处理）
- `wenshuUrl`：文枢安全下载链接（即 `extraData` 字段，形如 `cryptbox://...` 或 `https://cryptbox.sankuai.com/...`）
- `isEncrypted`：是否需要文枢 skill 处理

示例：
```
oa-skills citadel fetchAttachment --fileId "234068059030"
```

#### 第二步：通过文枢 skill 处理下载

将 `wenshuUrl` 作为下载地址，交由文枢 skill 处理（两个 skill 因 agent 环境不同，均需尝试）：

1. 尝试调用 `wenshu-tools` skill，传入 `wenshuUrl` 处理下载请求
2. 如果 `wenshu-tools` 不可用，尝试调用 `wenshu-catdesk-tools` skill
3. 如果两个 skill 均不可用，**停止一切下载尝试**，提示用户：

   > "该附件需要通过文枢 skill 才能下载。请先安装 `wenshu-tools` 或 `wenshu-catdesk-tools` skill 后再试。"

## 图表与特殊组件

- `:::plantuml{...}` PlantUML 图表：内部是 PlantUML 语法，需要解读图表描述的流程/架构/关系
- `:::drawio{...}:::` Drawio 流程图：`src` 属性为流程图文件 URL（形如 `https://km.sankuai.com/api/file/cdn/...`），可通过以下 CLI 命令获取流程图完整数据：
  ```
  oa-skills citadel fetchDrawio --drawioUrl "<src 的值>"
  ```
  命令返回 JSON，包含：
  - `mxGraphXml`：从 SVG `content` 属性中提取的 **mxGraph XML 源数据**，这是流程图的完整数据格式，包含所有节点（形状、文字、样式）、连线（source/target/样式/标签）和布局信息。**理解流程图结构和未来修改流程图均应基于此字段**
  - `svgContent`：完整的原始 SVG 文本（含渲染后的图形元素，可作为补充参考）
  - 若文件较大，可加 `--save /tmp/km-drawio.svg` 保存到本地后再读取（此时 `svgContent` 为空，但 `mxGraphXml` 仍会返回）
- `:::minder{...}:::` 思维导图：只有 `src` 链接，无法直接读取内容，告知用户"文档在此处包含一张思维导图"
- `:::gantt{...}:::` 甘特图：只有 ID 引用，无法读取详情，告知用户"文档在此处包含一张甘特图"
- `:::data2chart{...}` 数据图表：若内部带 `:::data2chart_config` / `:::data2chart_data`，说明这是图表配置与数据正文；否则可视为只读图表引用
- `$$...$$` 数学公式：理解其数学含义并用自然语言描述
- `$...$` 行内公式：同上，尝试用自然语言描述公式含义

## 表格

- 标准 Markdown 表格（`| 列1 | 列2 |` 格式）：直接读取和理解
- `:::table{...}` 扩展表格（含合并单元格）：内部由 `:::table_row` 和 `:::table_header` / `:::table_cell` 组成，需要按行和单元格递归理解
- 单元格内部仍是完整 CitadelMD，可以继续出现列表、代码块、图片、子表格等嵌套内容

## 行内元素

- `:[mention]{name="..." uid="..." empId="..."}` 提及用户：`name` 字段即为用户的显示名称
- `:[time]{date="..."}` 日期引用：`date` 字段为毫秒时间戳，需转换为可读日期（YYYY-MM-DD）
- `:[status]{pattern="..." color="..."}内容[/status]` 状态标签：读取标签文本内容作为状态值
- `:[color]{...}文字[/color]`、`:[bg]{...}文字[/bg]`、`:[font]{...}文字[/font]`：只需读取内部文字，忽略样式属性
- `:[link]{href="..." autoUpdate}文字[/link]` 或 `[文字](url)`：读取链接文字及目标 URL
- `:[emoji]{name="..."}` 表情：根据 `name` 理解表情含义

## 可忽略的元素（不影响内容理解）

- `:::catalog{...}:::` 目录组件：自动生成的目录，直接跳过
- `:::page_tree{...}:::` 文档目录树：展示子文档结构，说明"文档在此处包含子文档目录"
- `:::xtable{...}:::` 多维表格引用：告知用户"文档在此处嵌入了多维表格"
- `:::spaceupdate{...}:::` 空间动态卡片：直接跳过
- `:::appendix:::` + `:::footnote_list` / `:::footnote_list_item` 附录/脚注：如有脚注内容可说明
- `:::not_support{...}:::` 不支持的宏：直接跳过，不需要提及
- `:::open_card / open_link / open_iframe`：嵌入卡片/链接/表格，告知用户"文档在此处嵌入了外部内容"
