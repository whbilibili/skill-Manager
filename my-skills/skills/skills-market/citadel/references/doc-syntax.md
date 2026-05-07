# CitadelMD 语法参考

**CitadelMD** 是学城文档专用的扩展 Markdown 格式，基于 ProseMirror JSON 双向转换。通过 `:::tag{attrs}` 语法完整编码所有自定义宏节点，**100% 保留文档结构**。

AI 读取或编辑学城文档时，文档内容均以 CitadelMD 格式呈现，需要理解并遵循以下语法规则。

---

## 标准 Markdown（普通内容直接使用）

```
# 一级标题
## 二级标题
### 三级标题（支持 H1-H6）

普通段落文字。连续行会合并为同一段落。

---   （分割线）

> 这是一段引用文字

- 无序列表项 1
- 无序列表项 2

1. 有序列表项 1
2. 有序列表项 2

- [x] 已完成的任务
- [ ] 未完成的任务

​```typescript
const hello = 'world';
console.log(hello);
​```
（代码块支持语言标识，如 python / java / bash / typescript 等）

| 姓名 | 部门 |
| --- | --- |
| 张三 | 研发部 |
（标准表格，无合并单元格）

![图片描述](https://example.com/image.png)
![图片描述](https://example.com/image.png){width=300 height=200}
（图片可附加尺寸属性）
```

> 代码块约束：
> - `title` 若使用，必须是一行普通文本；代码正文必须放在代码块内容区，不能塞进标题里
> - `language` **不能为 `null`**，未指定时使用 `Plain Text`
> - `theme` **不能为 `null`**，未指定时使用默认值 `xq-light`
> - ⚠️ **`language` 大小写必须严格匹配**，例如必须写 `Mermaid` 而非 `mermaid`，`Plain Text` 而非 `plain text`，`JavaScript` 而非 `javascript`
> - 支持的 `language` 枚举值：
>   `Plain Text`、`JavaScript`、`Java`、`JSON`、`Shell`、`HTML`、`PlantUML`、`Mermaid`、
>   `C`、`C++`、`C#`、`CSS`、`Dart`、`Elm`、`Go`、`Groovy`、`HTTP`、`JSX`、`Kotlin`、
>   `LaTeX`、`Lua`、`Markdown`、`Nginx`、`Objective-C`、`Perl`、`PHP`、`PowerShell`、
>   `Python`、`R`、`Ruby`、`Sass`、`Scala`、`SQL`、`Stylus`、`TypeScript`、`Swift`、
>   `Vue.js Component`、`XML`、`YAML`、`Mindmap`

---

## 文字样式（Marks）

```
**加粗文字**
*斜体文字*
__下划线文字__
~~删除线文字~~
`行内代码`
^上标^
~下标~

:[color]{#ff0000}红色文字[/color]
:[color]{#0066cc}蓝色文字[/color]
:[bg]{#ffff00}黄色背景[/bg]
:[font]{size=20}大号字体[/font]
:[font]{size=12}小号字体[/font]
```

> 颜色值支持十六进制（`#rrggbb`）或 CSS 颜色名。字体大小单位为 px（整数）。

---

## 行内宏节点

```
:[mention]{name="张三" uid="zhangsan" empId="123456"}
（@提及用户，name=显示名、uid=MIS号、empId=工号）

:[time]{date="1742220000000"}
:[time]{date="1742220000000" showTime}
（日期/时间引用，date 传入毫秒时间戳；showTime 表示同时显示具体时间，省略则只显示日期）

:[status]{pattern="default" color=""}待处理[/status]
:[status]{pattern="success" color="green"}已完成[/status]
:[status]{pattern="warning" color="orange"}进行中[/status]
:[status]{pattern="error" color="red"}已取消[/status]
（状态标签，pattern 取值：default / success / warning / error / fill）

:[emoji]{name="smile"}
:[emoji]{name="thumbsup"}
（表情符号，name 为表情标识符）

$E = mc^2$
（行内 LaTeX 公式）

:[link]{href="https://km.sankuai.com" autoUpdate}学城首页[/link]
（自动更新标题的链接，普通链接直接用标准 Markdown：[文字](url)）

:[data2chart]{id="f91521b14fa7d8fe52eb" pageId="2752474861"}
（数据图表行内引用，id 和 pageId 必须保留原值）

:[footnote]{id="96ef140e-f997-4981-a9bb-037d2f0e1d39" annotate=""}
（脚注锚点，id 必须保留原值，annotate 为注释文字）
```

---

## 块级宏节点

### 段落对齐与缩进（paragraph）

```
:::paragraph{align=right indent=0}
右对齐段落
:::

:::paragraph{align=center indent=0}
居中对齐段落
:::

:::paragraph{align=justify indent=0}
两端对齐段落
:::

:::paragraph{align=left indent=1}
缩进段落（indent 为缩进级别，0=无缩进）
:::
```

> `align` 取值：`left`（左对齐，默认，可省略此块）、`right`（右对齐）、`center`（居中）、`justify`（两端对齐）。

### 展开宏（collapse）

```
:::collapse{active}
展开宏标题
---
展开宏内容，可以包含任意 Markdown。

支持多段落、列表等。
:::

:::collapse{}
默认收起（不带 active）
---
点击才能看到的内容
:::
```

> `active` 表示默认展开，去掉则默认折叠。标题和内容之间用 `---` 分隔。
> 标题只能写一行；如果需要补充说明或正文，请写到 `---` 后的 `collapse_content` 中。

### 文档标题（title）

```
:::title
文档标题文字
:::
```

> ⚠️ **重要约束**：
> - `title` 是文档标题节点，**不同于** `heading`（内容标题样式）
> - 每篇文档 **有且只有一个** `title` 节点
> - `title` **必须是 `doc` 根节点下的第一个子节点**，不能放在其他位置
> - 生成或编辑文档时，若缺少 `title` 或将 `heading` 放在第一位，后端会报错：`child is not right type. childType:heading, annotationType:title`

### 样式宏（note）

```
:::note{type=info}
信息提示标题
---
这里是提示内容。
:::

:::note{type=note}
警示标题
---
警示内容。
:::

:::note{type=warning}
注意标题
---
注意内容。
:::

:::note{type=tip}
提示标题
---
提示内容。
:::
```

> `type` 取值：
> - `info`（信息，蓝色）
> - `note`（警示，黄色）
> - `warning`（注意，红色）
> - `tip`（提示，绿色）
>
> 额外约束：
> - `note` 标题只能写一行；正文内容必须写到 `---` 后的 `note_content` 中
> - 只要写了标题，就默认展示标题，不要生成“有标题但隐藏标题”的结构

### 公式宏（latex_block）

```
$$
\sum_{i=1}^{n} i = \frac{n(n+1)}{2}
$$
```

### PlantUML 图表

```
:::plantuml{width=400 height=300}
@startuml
A -> B : 请求
B -> A : 响应
@enduml
:::
```

### Drawio 流程图

```
:::drawio{src="https://km.sankuai.com/api/file/cdn/xxx" width=554 height=387}:::
```

> `src` 为图文件地址，必须保留原值。⚠️ 不要手动修改 Drawio 内容。

### 思维导图（minder）

```
:::minder{src="https://km.sankuai.com/api/file/cdn/xxx" width=800 height=80}:::
```

> `src` 为图文件地址，必须保留原值。⚠️ 不要手动修改思维导图内容。

### 图片（image）

```
![图片描述](https://km.sankuai.com/api/file/cdn/xxx)
![图片描述](https://km.sankuai.com/api/file/cdn/xxx){width=600 height=400}
![图片描述](https://km.sankuai.com/api/file/cdn/xxx){width=600 height=400 link="https://example.com" border=true isFullWidth=true}
```

> 图片属性说明：
> - `width` / `height`：图片尺寸（px），0 表示未设置
> - `link`：图片点击跳转链接（可选）
> - `border`：是否显示边框（true/false）
> - `isFullWidth`：是否全宽显示（true/false）
> - `small`：缩略图 URL（学城内部字段，保留原值）
> - `mss`：MSS 存储 ID（学城内部字段，保留原值）
> - `quoteId`：划词评论 ID（学城内部字段，保留原值）

### 附件（attachment）

```
:::attachment{src="https://km.sankuai.com/file/xxx" name="文档.pdf" size="1.2MB"}:::
```

### 音频（audio）

```
:::audio{url="https://km.sankuai.com/api/file/cdn/xxx" name="录音.mp3" size="862.55KB" align="left"}:::
```

### 视频（video）

```
:::video{url="https://km.sankuai.com/api/file/cdn/xxx" name="视频.mp4" size="21.15MB" width=640 height=360 align="left"}:::
```

> 注意：`audio` 和 `video` 使用 `url=` 而非 `src=`，必须保留原值。

### 原始 Markdown 宏（markdown raw）

```
:::markdown
**这里是原始 Markdown 内容**，会以 Markdown 宏节点嵌入文档
:::
```

### 原始 HTML 宏（html raw）

```
:::html
<div class="custom">自定义 HTML 内容</div>
:::
```

### 含合并单元格的表格（table extended）

以下情况**必须**使用扩展表格格式，不能用标准 `| col | col |` 表格：
- 单元格需要合并（colspan / rowspan > 1）
- 单元格内容需要居中 / 右对齐 / 有缩进（含 `:::paragraph{align=center ...}`）
- 单元格内含行内宏（`:[color]{...}text[/color]`、`:[status]{...}text[/status]` 等）
- 单元格内含多段文字、列表、代码块、图片等复杂结构
- 单元格文字包含 `|` 字符

```
:::table{borderColor="#dddddd" borderStyle="solid" borderWidth=1 responsive=false}
:::table_row
:::table_header{colspan=2 colwidth="120,120"}
合并两列的标题
:::
:::table_header{colwidth="120"}
第三列
:::
:::
:::table_row
:::table_cell{colwidth="120"}
A
:::
:::table_cell{colwidth="120"}
B
:::
:::table_cell{colwidth="120"}
C
:::
:::
:::
```

**单元格内含行内颜色/样式的示例（高频场景）：**

```
:::table{borderColor="#dddddd" borderStyle="solid" borderWidth=1 responsive=false}
:::table_row
:::table_header{colwidth="80"}
序号
:::
:::table_header{colwidth="200"}
事件
:::
:::table_header{colwidth="120"}
更新日期
:::
:::table_header{colwidth="120"}
事件强度
:::
:::
:::table_row
:::table_cell{colwidth="80"}
1
:::
:::table_cell{colwidth="200"}
:[color]{#FF4A47}**外卖补贴大战被监管叫停**[/color]

具体说明内容写在这里。
:::
:::table_cell{colwidth="120"}
:::paragraph{align=center indent=0}
2026.04.01
:::
:::
:::table_cell{colwidth="120"}
:[color]{#FF4A47}🔴 高强度[/color]
:::
:::
:::
```

> 扩展表格完全使用 CitadelMD 宏块表达：
> - `:::table_row` 表示一行
> - `:::table_header` / `:::table_cell` 表示单元格
> - `colspan` / `rowspan` / `colwidth` / `textAlign` / `verticalAlign` / `bgColor` / `color` / `numCell` 都写在单元格 attrs 中
> - `colwidth` 写在各自单元格上，表示**该列的宽度**（单值，如 `colwidth="120"`）；仅在合并列（colspan > 1）时写多个值并用逗号分隔（如 `colwidth="120,120"`）
> - 单元格内部支持完整 CitadelMD，可继续嵌套列表、代码块、图片、行内宏、子表格等
> - 单元格内需要居中时，使用 `:::paragraph{align=center indent=0}` 包裹文字内容
> - ⚠️ **严禁**把单元格内容写成 JSON 字符串或放入 `text` 节点——单元格内容必须是 CitadelMD 文本块
> - 编辑内容时优先修改单元格块内正文，不要随意改动 `colspan` / `rowspan` 等结构属性

### 数据图表（data2chart block）

```
:::data2chart{id="chart-001" pageId="2752474861" chartId="inner-01" height=400 width=600}
:::data2chart_config
{"series":[1,2,3]}
:::
:::data2chart_data
{"rows":[{"name":"foo"}]}
:::
:::
```

> `config` 和 `chartData` 使用独立宏块承载原始内容；若文档里只有 `:::data2chart{...}:::` 自闭合形式，表示该节点没有额外配置正文。

### 目录（catalog）

```
:::catalog{style=none}:::
:::catalog{style=number}:::
:::catalog{style=circle}:::
```

> `style` 取值：`none`（无序号）、`number`（数字）、`circle`（圆点）、`rect`（方块）、`point`（点）。

### 甘特图（gantt）

```
:::gantt{id="gantt-001" height=400 version=1}:::
```

> ⚠️ 甘特图为只读引用，仅保留 id/height/version，不支持手动编辑内容。

### 日历（calendar）

```
:::calendar{id=1 view=month docId=100}:::
```

> `view` 取值：`month`（月视图）、`week`（周视图）。

### 文档目录树（page_tree）

```
:::page_tree{spaceId="space-001" pageId="page-001" maxDepth=3}:::
```

### 多维表格引用（xtable）

```
:::xtable{nodeId="node-xt-001" xtableId="xt-001"}:::
```

> ⚠️ 多维表格为只读引用，不支持手动编辑，保留原值即可。

### 空间更新卡片（spaceupdate）

```
:::spaceupdate{spaceId="space-001"}:::
```

### 不支持的宏（not_support）

```
:::not_support{source="confluence" macro="jira" macroId="m001" pageId="123"}:::
```

> ⚠️ 这是从其他平台迁移来的不支持的宏，**请勿删除**，原样保留。

### 控件（control）

```
:::control{type="date" name="日期控件" key="mykey" value="1773888071769"}:::
:::control{type="date_range" name="日期范围" key="mykey2" value="1773244800000,1773849599999"}:::
```

> `type` 取值：`date`（日期控件）、`date_range`（日期范围控件）。`key` 是控件唯一标识，必须保留原值；`value` 为毫秒时间戳（日期范围用逗号分隔两个时间戳）。

### 文档列表视图（doc_list_view）

```
:::doc_list_view{parentDocType="current" spaceId=0 pageId=0 displayType="catalog" order="asc" displayCount=14}:::
```

> `parentDocType` 取值：`current`（当前文档）。其他属性保留原值。

### 脚注列表（footnote_list）

```
:::footnote_list
:::footnote_list_item{footnoteNodeId="fn-001" nodeId="item-001"}
脚注正文第一段
:::
:::footnote_list_item{footnoteNodeId="fn-002" nodeId="item-002"}
第二条脚注正文
:::
:::
```

> `footnoteNodeId` 和 `nodeId` 是脚注关联标识，必须保留原值；脚注正文可以按普通 CitadelMD 编辑。

### 附录（appendix）

```
:::appendix:::
```

> 附录分隔符，保留原值。其后的脚注列表使用 `:::footnote_list` + `:::footnote_list_item{footnoteNodeId="..." nodeId="..."}` 宏块表示；可以修改脚注正文，但不要改 `footnoteNodeId` / `nodeId`。

### 嵌入卡片（open_card / open_link / open_iframe）

```
:::open_card{url="https://example.com" nodeId="node-001" type="link" align=left}:::
:::open_link{url="https://example.com" title="标题" nodeId="node-002"}:::
:::open_iframe{height=500 nodeId="node-003" type="wpsExcel" align="left" attachmentId=228524748073}:::
```

---

## 特殊居中/右对齐标题

```
:::heading{level=2 align=center}
居中的二级标题
:::

:::heading{level=3 align=right}
右对齐的三级标题
:::
```

> 只有非左对齐标题才使用此语法，普通左对齐标题直接用 `## 标题` 即可。

---

## 后端 Schema 约束（JSON 结构规则）

学城后端（`Deserializer.java`）在接收文档 JSON 时会进行严格的 Schema 校验。生成或编辑文档 JSON 时必须遵守以下规则，否则提交会报错（通常 code=2600001）。

### 支持的节点类型

后端仅接受以下节点类型，**任何其他类型均会导致校验失败**：

| 分类 | 支持的类型 |
| --- | --- |
| 文档根节点 | `doc` |
| 块级节点 | `paragraph`, `heading`, `blockquote`, `code_block`, `horizontal_rule` |
| 列表 | `bullet_list`, `ordered_list`, `task_list`, `list_item`, `task_item` |
| 表格 | `table`, `table_row`, `table_cell`, `table_header` |
| 媒体 | `image`, `audio`, `video`, `attachment` |
| 折叠/提示 | `collapse`, `collapse_title`, `collapse_content`, `note`, `note_title`, `note_content` |
| 代码/公式 | `latex_block`, `markdown`, `html` |
| 嵌入内容 | `catalog`, `spaceupdate`, `page_tree`, `gantt`, `data2chart`, `calendar`, `plantuml`, `drawio`, `minder`, `xtable` |
| 卡片/链接 | `open_iframe`, `open_link`, `open_card` |
| 其他块级 | `appendix`, `not_support`, `control`, `doc_list_view`, `title`, `footnote_list`, `footnote_list_item` |
| 行内节点 | `text`, `hard_break`, `mention`, `link`, `time`, `status`, `emoji`, `latex_inline`, `footnote` |

### 支持的 Mark 类型

| mark 类型 | 说明 | 必填 attrs |
| --- | --- | --- |
| `strong` | 加粗 | 无 |
| `em` | 斜体 | 无 |
| `underline` | 下划线 | 无 |
| `strikethrough` | 删除线 | 无 |
| `code` | 行内代码 | 无 |
| `color` | 文字颜色 | `color`（颜色值） |
| `backgroundcolor` | 背景色 | `color`（颜色值） |
| `font` | 字体大小 | `dataSize`（整数，px） |
| `sub` | 下标 | 无 |
| `sup` | 上标 | 无 |
| `quote` | 划词评论引用 | `quoteId`（字符串） |

### doc 根节点的 title 约束

`doc` 根节点对 `title` 有严格的位置和数量约束（对应后端 `Quantity.ONE`）：

| 约束 | 说明 |
| --- | --- |
| **第一个子节点必须是 `title`** | `doc.content[0]` 必须是 `title` 节点，不能是 `heading`、`paragraph` 等 |
| **有且只有一个 `title`** | `title` 不能出现多次 |
| **`title` 之后至少有一个内容节点** | `title` 后面必须跟 `paragraph`、`heading` 等内容节点 |

> ❌ **常见错误**：用 `# 标题` / `heading` 代替 `:::title:::` 作为文档第一个节点。  
> `heading` 是正文内的标题样式（如章节标题），`title` 是文档元数据标题，**两者完全不同**，不能混用。

### content 数量约束

以下节点类型要求 `content` 不为空（AT_LEAST_ONE），否则后端会报错：

- `doc`：文档根节点，必须有至少一个子节点
- `bullet_list`、`ordered_list`、`task_list`：列表不能为空
- `blockquote`：引用块不能为空
- `collapse_content`：折叠块内容不能为空
- `note_content`：提示框内容不能为空
- `footnote_list`、`footnote_list_item`：脚注列表不能为空

### 子节点类型约束

| 父节点 | 允许的子节点类型 |
| --- | --- |
| `table` | 只能是 `table_row` |
| `table_row` | 只能是 `table_cell` 或 `table_header` |
| `bullet_list`、`ordered_list` | 只能是 `list_item` |
| `task_list` | 只能是 `task_item` |
| `collapse` | 必须包含 `collapse_title` 和 `collapse_content` |
| `note` | 必须包含 `note_title` 和 `note_content` |
| `footnote_list` | 只能是 `footnote_list_item` |

### text 节点规则

- `text` 节点**必须**包含 `text` 字段（字符串）
- `text` 节点**不应**包含 `content` 字段

### code_block 属性约束

- `language` **不能为 `null`**，未指定时必须使用字符串 `"Plain Text"`
- `theme` **不能为 `null`**，未指定时必须使用字符串 `"xq-light"`
- `title` 必须是一行纯文本，不能包含换行符；未指定时使用 `"代码块"`
- ⚠️ **`language` 大小写必须严格匹配**，例如必须写 `"Mermaid"` 而非 `"mermaid"`，`"Plain Text"` 而非 `"plain text"`，`"JavaScript"` 而非 `"javascript"`
- 支持的 `language` 枚举值（共 40 种）：

| 语言 | language 值 |
| --- | --- |
| 纯文本 | `Plain Text` |
| JavaScript | `JavaScript` |
| Java | `Java` |
| JSON | `JSON` |
| Shell/Bash | `Shell` |
| HTML | `HTML` |
| PlantUML | `PlantUML` |
| Mermaid | `Mermaid` |
| C | `C` |
| C++ | `C++` |
| C# | `C#` |
| CSS | `CSS` |
| Dart | `Dart` |
| Elm | `Elm` |
| Go | `Go` |
| Groovy | `Groovy` |
| HTTP | `HTTP` |
| JSX | `JSX` |
| Kotlin | `Kotlin` |
| LaTeX | `LaTeX` |
| Lua | `Lua` |
| Markdown | `Markdown` |
| Nginx | `Nginx` |
| Objective-C | `Objective-C` |
| Perl | `Perl` |
| PHP | `PHP` |
| PowerShell | `PowerShell` |
| Python | `Python` |
| R | `R` |
| Ruby | `Ruby` |
| Sass | `Sass` |
| Scala | `Scala` |
| SQL | `SQL` |
| Stylus | `Stylus` |
| TypeScript | `TypeScript` |
| Swift | `Swift` |
| Vue.js | `Vue.js Component` |
| XML | `XML` |
| YAML | `YAML` |
| 思维导图 | `Mindmap` |
