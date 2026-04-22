> ❌ **严禁调用 `updateDocument`**：该命令会将 Markdown 文本直接追加写入文档后端，导致文档出现重复 title、结构错乱，且**无法自动回滚**。所有文档内容编辑必须且只能通过下方的 `updateDocumentByMd` 流程完成。

# 编辑/更新/插入新内容到学城文档指南

编辑/更新/插入新内容到学城文档是一个高危操作。学城文档的底层数据是基于 ProseMirror 生成的 JSON 结构，其中可能包含大量 Markdown 语法无法描述的特殊定制宏（如：包含合并单元格的表格，表格嵌套表格，特定的卡片、嵌入的第三方组件、文字颜色/背景色/对齐方式、展开卡片等）。

## 强势使用方式：CitadelMD 安全更新（零数据丢失）

**CitadelMD** 是一种基于 ProseMirror JSON 的扩展 Markdown 格式，通过 `:::tag{attrs}` 语法完整编码所有自定义宏节点，**100% 保留文档结构**，不会产生任何数据丢失。

### 完整工作流

#### 第一步：获取文档的 CitadelMD 内容

```bash
# 直接打印到终端
oa-skills citadel getDocumentCitadelMd --contentId <id>

# 保存到文件（推荐，便于编辑）
oa-skills citadel getDocumentCitadelMd --contentId <id> --output doc.citadelmd
```

#### 第二步：修改 CitadelMD 内容

直接编辑 `.citadelmd` 文件，或者由 AI 对内容进行增、删、改操作。

CitadelMD 是学城专用的扩展 Markdown 格式，完整语法见 [doc-syntax.md](doc-syntax.md)。

**高频场景示例：向已有扩展表格末尾追加新行**

完整表格的 CitadelMD 大致结构如下，追加新行时，将新的 `:::table_row` 块插入到**最后一个 `:::` （表格闭合标记）之前**：

```
:::table{borderColor="#dddddd" borderStyle="solid" borderWidth=1 responsive=false}
:::table_row
:::table_header{colwidth="80"}
序号
:::
:::table_header{colwidth="200"}
内容
:::
:::
:::table_row
:::table_cell{colwidth="80"}
1
:::
:::table_cell{colwidth="200"}
原有内容
:::
:::
←—— 在这个闭合 ::: 之前插入新的 :::table_row 块
:::table_row
:::table_cell{colwidth="80"}
2
:::
:::table_cell{colwidth="200"}
:[color]{#FF4A47}新增内容[/color]
:::
:::
:::   ←—— 这是表格的闭合标记
```

> ⚠️ **不要新开一个独立的 `:::table` 块**来表示新增的行——这会在文档里生成两张独立的表格。应将新 `:::table_row` 插入到现有表格闭合 `:::` 前。

#### 推荐给模型的执行指令

处理文档编辑时，优先遵循下面这段口令：

1. 先读取原始 CitadelMD，再在原文上做**最小改动**
2. 只改用户明确要求的内容，不重排、不润色、不统一格式、不改无关节点
3. 保留所有不理解的宏节点，宁可原样保留，也不要猜测后重写
4. 复杂表格直接编辑 `:::table_row` / `:::table_header` / `:::table_cell` 宏块内部内容；单元格内容必须是 **CitadelMD 文本**（普通段落、行内宏、居中宏等），**绝对不能把单元格内容写成 JSON 字符串或放进 `text` 节点**
5. 默认不改表格结构属性、脚注 ID、图表配置、资源 ID、嵌入卡片参数
6. 回传前检查：`:::title` 仍在首位且内容为**纯文本**、宏块全部闭合、行内宏未跨行、没有把局部修改扩散到整篇文档
7. `:::note` / `:::collapse` / 代码块的标题必须是**一行普通文本**；正文放在各自的 content 区，不要把多段正文塞进标题
8. `:::note` 如果写了标题，默认按“展示标题”处理；不要生成“有标题但隐藏标题”的结构

---

### 编辑注意事项

1. **保留所有宏节点**：任何 `:::tag{...}:::` 或 `:[tag]{...}` 节点，若不需要修改则原样保留
2. **不要修改资源标识**：`gantt`、`drawio`、`minder`、`xtable`、`open_link`、`open_iframe` 等节点的 `id` / `nodeId` / `src` / `attachmentId` 等标识默认必须保留
3. **扩展表格按宏块编辑**：复杂表格使用 `:::table` → `:::table_row` → `:::table_header` / `:::table_cell` 结构，直接修改单元格块内正文即可
4. **不要随意改表格结构属性**：除非用户明确要求调整布局，否则保留 `colspan` / `rowspan` / `colwidth` / `textAlign` / `verticalAlign` / `bgColor` / `color` / `numCell`
5. **空单元格保留为空块**：允许 `:::table_cell{...}` 与结束 `:::` 之间没有正文，转换时会自动补空 paragraph
6. **新增表格时第一行必须是表头行**：优先使用 `:::table_header`，不要首行全部写成 `:::table_cell`
7. **脚注列表按宏块编辑**：`:::footnote_list_item` 的正文可改，但 `footnoteNodeId` / `nodeId` 必须原样保留
8. **块级 data2chart 配置按子宏保留**：`:::data2chart_config` / `:::data2chart_data` 内部内容可按原文保留，不要擅自重写结构
9. **空行分隔块**：不同的块元素之间需要有空行分隔，列表项之间不加空行
10. **行内宏不换行**：所有 `:[tag]{...}` 行内宏必须写在同一行内，不能跨行
11. **不要扩大修改范围**：如果用户只要求替换一句话、一个标题、某个表格单元格，就不要把整段甚至整篇重新生成
12. **不要把等价语法来回转换**：例如不要把现有复杂表格改写成另一种表述，不要把现有宏节点改成纯文本占位
13. **宏标题只写首行**：`:::note` / `:::collapse` 标题和代码块 `title` 只写一行；其余说明、正文、补充段落写到 `---` 后或代码内容区
14. **`:::title` 只能是纯文本**：文档标题节点 `:::title` 的内容只能是普通文字，**不能**使用加粗（`**`）、斜体（`*`）、下划线（`__`）、删除线（`~~`）等 marks 语法，也不能包含行内宏（`:[tag]{...}`）；写成 `:::title\n**我的文档**\n:::` 会被自动降级为纯文本，marks 将被剥除

### 结构约束速查（违反将导致 API code=2600001 报错）

以下规则由转换器在提交前自动校验，AI 生成的 CitadelMD 必须遵守这些约束，否则文档无法保存。

#### 文档顶层结构（doc）

| 约束 | 规则 |
|------|------|
| `:::title` 必须存在 | 每篇文档必须有且只有一个 `:::title` 节点 |
| `:::title` 必须在首位 | `:::title` 必须是文档的第一个块节点，前面不能有任何其他内容 |
| `:::title` 内容为纯文本 | `:::title` 里只能有普通文字，**禁止**使用 `**加粗**`、`*斜体*`、`__下划线__`、`~~删除线~~` 或行内宏 `:[tag]{...}` |
| `:::title` 后必须有内容 | `:::title` 之后至少要有一个正文块（paragraph/heading 等）|
| `:::appendix` 最多一个 | 如果存在 `:::appendix`，全文只能出现一次；多余的会被自动丢弃 |
| `:::footnote_list` 最多一个且必须在最后 | 脚注列表只能出现一次，且必须是文档最后一个块节点；若在中间，会被自动移到末尾 |
| doc 直接子节点类型受限 | doc 下只能放 block 节点（paragraph/heading/table/list 等）、xtable、appendix、footnote_list；**禁止**把 `table_row` 直接放在 doc 下 |

#### 行内与文本节点

| 约束 | 规则 |
|------|------|
| `text` 节点不能为空字符串 | `text` 节点的 `text` 字段不能是 `""`；空段落请直接省略 `content` 字段，不要写 `text: ""` |
| `text` 节点不能有 `content` 字段 | `text` 节点是叶子节点，不应该有 `content` 字段 |
| `paragraph`/`heading` 只能包含行内节点 | 两者的子节点只能是 text/hard_break/mention/link/time/status/emoji/latex_inline/footnote/image/data2chart/open_link/plantuml/drawio/minder，**禁止**嵌套 paragraph 或其他 block |

#### 媒体与资源节点（必填字段）

| 节点 | 必填字段 | 说明 |
|------|----------|------|
| `image` | `src`（非空字符串）、`name`（字符串，可为空） | 图片 URL 和名称均不能缺失；`name` 可以是空字符串 `""` 但不能为 `null`/`undefined` |
| `audio` | `url`（非空字符串） | 音频 URL 不能为空 |
| `video` | `url`（非空字符串） | 视频 URL 不能为空 |
| `attachment` | `src`（非空字符串） | 附件 URL 不能为空 |

#### 行内特殊节点（必填字段）

| 节点 | 必填字段 | 说明 |
|------|----------|------|
| `mention` | `uid`（非空字符串） | @用户的 uid 不能为空 |
| `link` | `href`（非空字符串） | 链接 URL 不能为空 |
| `time` | `date`（非零数字 或 非空字符串） | 毫秒时间戳或 `"YYYY-MM-DD"` 格式字符串 |
| `emoji` | `name`（非空字符串） | emoji 名称不能为空 |

#### 块级结构节点

| 节点 | 约束 |
|------|------|
| `heading` | `attrs.level` 必须是 **1-6 的整数**，缺失或超范围会报错 |
| `table_cell`/`table_header` | `attrs.colwidth` 必须是**数组或 null**，不能是其他类型（如字符串或数字） |
| `catalog` | `attrs.style` 只能是 `none`/`number`/`circle`/`rect`/`point` 之一（或不填） |
| `note` | `attrs.type` 只能是 `info`/`note`/`warning`/`tip` 之一（或不填） |
| `code_block` | `attrs.title` 不能包含换行符，必须是一行普通文本 |
| `note_title`/`collapse_title` | 只能包含一行标题文字，不能换行；正文必须放到各自的 content 节点中 |

#### 复杂宏节点（必填字段）

| 节点 | 必填字段 | 说明 |
|------|----------|------|
| `gantt` | `id`（非空字符串） | 甘特图唯一标识，不能为空；**禁止**新建 `id` 或修改现有 `id` |
| `drawio` | `src` 或 `mss` 至少一个非空 | 图形数据存储地址；**禁止**清空这两个字段 |
| `minder` | `src`（非空字符串） | 脑图数据地址不能为空；**禁止**修改 `src` |
| `open_card` | `url`（非空字符串） | 卡片嵌入链接不能为空 |
| `open_iframe` | `src`、`nodeId`、`attachmentId` **三者不能同时为空** | 可以只有 `nodeId`+`attachmentId`（如 WPS Excel 等内嵌文档），但不能三个都空 |
| `data2chart` | `id`（非空字符串） | 图表唯一标识不能为空；**禁止**修改 `id` |

#### 容器节点结构约束

| 父节点 | 子节点要求 |
|--------|-----------|
| `table` | 只能包含 `table_row`；**禁止** `table_cell`/`table_header` 直接出现在 `table` 下 |
| `table_row` | 只能包含 `table_cell` 或 `table_header` |
| `table_cell`/`table_header` | 只能包含 block 节点（paragraph/heading/table/bullet_list 等） |
| `bullet_list`/`ordered_list` | 只能包含 `list_item` 或 `task_item` |
| `task_list` | 只能包含 `task_item` 或 `list_item` |
| `list_item`/`task_item` | 只能包含 block 节点或 xtable |
| `blockquote`/`collapse_content`/`note_content` | 只能包含 block 节点（`content` 不能为空，至少一个子节点） |
| `collapse` | 必须包含且只包含 `collapse_title` 和 `collapse_content` |
| `note` | 必须包含且只包含 `note_title` 和 `note_content` |
| `title` | 只能有**恰好一个** `text` 子节点，且该节点**不能携带任何 marks** |
| `footnote_list` | 只能包含 `footnote_list_item` |
| `footnote_list_item` | 只能包含 `paragraph`（至少一个，不能为空） |
| `bullet_list`/`ordered_list`/`task_list`/`blockquote` | `content` **不能为空**，至少有一个子节点 |

#### marks（文字样式）约束

| 约束 | 规则 |
|------|------|
| marks 类型必须合法 | 只支持 `strong`/`em`/`underline`/`strikethrough`/`code`/`color`/`backgroundcolor`/`font`/`sub`/`sup`/`quote` |
| `color`/`backgroundcolor` mark | 必须携带 `attrs.color` 字段 |
| `font` mark | 必须携带 `attrs.dataSize` 字段（字号数字） |
| `quote` mark | 必须携带 `attrs.quoteId` 字段 |

### 常见禁令

- **禁止** 直接编辑底层 JSON 字符串
- **禁止** 在不了解宏含义时删除或改写宏节点
- **禁止** 为了“更整洁”而重排整篇文档
- **禁止** 把复杂表格、脚注列表或图表配置重新写回 JSON 片段
- **禁止** 把表格内容（包括单元格文字、行内宏、居中布局）写成 JSON 字符串塞进 `paragraph.content[].text` 的 `text` 字段——这会导致表格结构完全丢失
- **禁止** 自造任何非标准分隔符（如 `::::::table`、`---json---` 等）来拼接不同格式的内容

#### 第三步：回传更新

```bash
# 从文件更新
oa-skills citadel updateDocumentByMd --contentId <id> --file doc.citadelmd

# 同时更新标题
oa-skills citadel updateDocumentByMd --contentId <id> --file doc.citadelmd --title "新标题"
```

#### 调试：查看 CitadelMD 转换为 JSON 的结果

如需验证转换是否正确，可以先转换为 JSON 检查：

```bash
oa-skills citadel convertMdToJson --file doc.citadelmd --output doc.json
```

---

## 总结

| 方式 | 命令 | 数据安全 | 推荐 |
|------|------|----------|------|
| CitadelMD 更新 | `updateDocumentByMd` | ✅ 完全安全 | ✅ 推荐 |

**优先使用 CitadelMD 方式进行文档更新。保护用户的数据完整性是第一原则。**

**输出** 完成编辑后返回用户文档链接，让用户可以直接点击查看文档变更的内容
