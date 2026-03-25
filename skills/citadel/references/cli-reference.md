# CLI 命令参考

完整参数说明，基于 `src/citadel/cli.ts` 实际实现。

## 通用选项

| 选项 | 类型 | 默认值 | 说明 |
|---|---|---|---|
| `--mis <mis>` | string | 从配置文件读取 | 用户 MIS 号，用于认证 |
| `--raw` | flag | false | 输出原始 JSON 到 stdout（默认输出人类可读格式到 stderr） |
| `--clear-cache` | flag | — | 清除认证缓存后退出，不需要指定命令 |

## getMarkdown

获取文档 Markdown 内容。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--contentId` | string | ✅ | — | 文档 ID |

```bash
oa-skills citadel getMarkdown --contentId "2748397739"
```

**输出**：非 raw 模式下，文档标题/ID/长度输出到 stderr，Markdown 正文输出到 stdout。

## getChildContent

获取子文档列表。自动查询文档所属 spaceId。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--contentId` | string | ✅ | — | 父文档 ID |

```bash
oa-skills citadel getChildContent --contentId "2748397739"
```

**输出**：父文档标题、子文档列表（标题、ID、文档链接、类型、创建人、创建/修改时间、是否有子文档）。

## createDocument

创建学城文档。支持四种模式：直接内容、从文件读取、从模板创建、复制文档。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--title` | string | ✅ | — | 文档标题 |
| `--content` | string | 条件 | — | Markdown 正文内容 |
| `--file` | string | 条件 | — | 从本地文件读取 Markdown 内容（优先于 `--content`） |
| `--templateId` | string | 条件 | — | 从模板创建文档 |
| `--copyFrom` | string | 条件 | — | 复制来源文档的 contentId |
| `--parentId` | string | — | — | 父文档 ID（创建子文档时使用） |
| `--spaceId` | string | — | — | 目标空间 ID（不指定则使用个人空间） |

> `--content` / `--file` / `--templateId` / `--copyFrom` 至少提供一个。`--file` 优先级最高，会覆盖 `--content`。

```bash
# 根文档
oa-skills citadel createDocument --title "方案" --content "# 正文"

# 子文档
oa-skills citadel createDocument --title "子文档" --content "# 内容" --parentId "2748397739"

# 从文件
oa-skills citadel createDocument --title "文档" --file ./design.md

# 指定空间
oa-skills citadel createDocument --title "文档" --content "# 正文" --spaceId "2506"

# 从模板
oa-skills citadel createDocument --title "周报" --templateId "template_123"

# 复制
oa-skills citadel createDocument --title "副本" --copyFrom "1234567890"
```

**输出**：创建成功后返回文档 ID 和访问链接。

## deleteDocument

删除学城文档。仅文档所有者可以删除文档。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--contentId` | string | ✅ | — | 文档 ID |

```bash
oa-skills citadel deleteDocument --contentId "2748397739"
```

**输出**：删除成功或失败的提示信息，并明确告知用户删除了哪些文档，给出文档ID。并提示用户如果想撤销删除，可以跟我说撤销刚才删除的文档

## restoreDocument

撤销删除/恢复已删除的学城文档。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--contentId` | string | ✅ | — | 文档 ID |

```bash
oa-skills citadel restoreDocument --contentId "2748397739"
```

**输出**：恢复成功或失败的提示信息，如果撤销删除失败，给出文档ID。

## searchContent

搜索学城文档。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--keyword` | string | ✅ | — | 搜索关键词 |
| `--offset` | number | — | 0 | 结果偏移量（从 0 开始） |
| `--limit` | number | — | 10 | 每页结果数 |
| `--searchTitle` | flag | — | false | 仅搜索标题 |
| `--tabType` | string | — | "all" | 文档类型过滤：`all` / `doc` / `table` 等 |

```bash
oa-skills citadel searchContent --keyword "技术方案"
oa-skills citadel searchContent --keyword "API" --searchTitle --limit 20
oa-skills citadel searchContent --keyword "设计" --offset 10 --tabType doc
```

**输出**：结果总数、每条结果的标题（高亮去 HTML 标签）、contentId、空间名、修改时间/修改人、内容摘要（前 120 字符）。

## getLatestEdit

获取最近编辑的文档列表。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--offset` | number | — | 0 | 偏移量（从 0 开始） |
| `--limit` | number | — | 30 | 每页数量 |
| `--creator` | string | — | "" | 按创建者 MIS 过滤（空字符串表示当前用户） |

```bash
oa-skills citadel getLatestEdit
oa-skills citadel getLatestEdit --limit 10 --creator "zhangsan"
```

**输出**：文档标题、pageId、文档链接、文档类型（在线 WIKI/在线文档/学城文档2.0/多维表格）、修改时间、修改人。

## getRecentlyViewed

获取最近浏览的文档列表。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--pageNo` | number | — | 1 | 页码（从 1 开始） |
| `--pageSize` | number | — | 30 | 每页数量 |
| `--creator` | string | — | "" | 按创建者 MIS 过滤（空字符串表示当前用户） |

```bash
oa-skills citadel getRecentlyViewed
oa-skills citadel getRecentlyViewed --pageSize 10 --pageNo 2
```

**输出**：文档标题、pageId、文档链接、文档类型、浏览时间、作者。

> 注意：此命令用 `--pageNo`（从 1 开始），与其他命令的 `--offset`（从 0 开始）不同。

## getReceivedDocs

获取最近收到的文档列表（通过大象分享收到的）。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--offset` | number | — | 0 | 偏移量（从 0 开始） |
| `--limit` | number | — | 30 | 每页数量 |

```bash
oa-skills citadel getReceivedDocs
oa-skills citadel getReceivedDocs --limit 10 --offset 30
```

**输出**：文档标题、contentId、文档链接、发送人、会话名（大象群名/个人名）、收到时间。

## getDiscussionComments

获取文档划词评论（讨论列表）。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--contentId` | string | ✅ | — | 文档 ID |
| `--pageNo` | number | — | 1 | 页码（从 1 开始） |
| `--pageSize` | number | — | 100 | 每页评论数 |

```bash
oa-skills citadel getDiscussionComments --contentId "2746799101"
oa-skills citadel getDiscussionComments --contentId "2746799101" --pageNo 1 --pageSize 50
```

**输出**：每条评论的 commentId、创建人、引用文本、评论内容（原始 JSON doc 格式）、时间、解决状态、回复列表。

## getDocumentStats

获取文档的统计信息（浏览量、评论数、创作时长等）。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--contentId` | string | ✅ | — | 文档 ID |

```bash
oa-skills citadel getDocumentStats --contentId "2746799101"
```

**输出**：关注人数、收藏人数、浏览人数、浏览次数、评论数量、创作时长。

## getSpaceIdByMis

根据 MIS 号获取学城个人空间 ID。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--targetMis` | string | ✅ | — | 目标用户的 MIS 号 |

```bash
oa-skills citadel getSpaceIdByMis --targetMis "rui.zou"
```

**输出**：用户的个人空间 ID。

## getSpaceRootDocs

获取空间根目录文档列表。

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|---|---|---|---|---|
| `--spaceId` | string | ✅ | — | 空间 ID |

```bash
oa-skills citadel getSpaceRootDocs --spaceId "23583"
```

**输出**：空间根目录文档列表，包含文档标题、文档ID、文档链接、文档类型、创建人以及创建时间。

## listTools

列出可用的 MCP 工具列表。无额外参数。

```bash
oa-skills citadel listTools
```
