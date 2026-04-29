# 划词评论（Discussion Comment）

学城文档的划词评论是指：选取文档正文的部分内容作为引用，在引用内容上添加评论。

## 概念说明

划词评论分为两个层级：

- **Discussion（讨论）**：一个划词评论会话，对应文档正文的某段引用内容（通过 `quoteId` 关联）。
- **Comment（评论/回复）**：Discussion 下的单条评论，第一条是创建 discussion 时一起提交的 `firstComment`，后续回复通过 `replyDiscussionComment` 命令添加。

每个 Discussion 有唯一的 `discussionId`（格式：`temp-discussion-{contentId}--{uuid}`）和 `quoteId`（格式：`{contentId}--{uuid}`）。

## 添加划词评论的两步操作

添加划词评论需要同时完成两件事：

### 步骤一：为文档节点添加 quote mark（文档编辑）

通过 `/api/collaboration/content/step` 接口提交 `addMark` 类型的 step，为文档正文中某个节点的范围（from~to）打上 `quote` mark，标记该区域为引用内容。

**关键参数说明：**

| 字段 | 说明 |
|---|---|
| `from` / `to` | 节点在文档 ProseMirror 序列中的起止位置（通过 client 内部计算） |
| `quoteId` | 该引用的唯一 ID，格式 `{contentId}--{uuid}` |
| `stepVersion` / `baseStepVersion` | 当前文档的 step 版本号，从 `getDocumentCitadelMd` 返回 |
| `clientId` | 固定值 `FROM-CITADEL-SKILL` |
| `msgId` | 每次请求随机生成的 UUID |

### 步骤二：创建 Discussion（评论数据）

通过 `/api/comment/discussion/create` 接口提交评论，与步骤一的 `quoteId` 形成绑定。

## CLI 命令

### addDiscussionComment — 添加划词评论

自动执行上述两步操作。

**必填参数：**

| 参数 | 类型 | 说明 |
|---|---|---|
| `--contentId <id>` | string | 文档 ID |
| `--nodeId <nodeId>` | string | 目标节点的 nodeId（从文档 JSON 的段落/标题节点 attrs.nodeId 字段获取） |
| `--stepVersion <版本号>` | number | 文档当前 step 版本号（从 `getDocumentCitadelMd` 返回的 stepVersion 字段） |
| `--text <内容>` | string | 评论正文纯文本内容 |

**可选参数：**

| 参数 | 类型 | 说明 |
|---|---|---|
| `--mention <mis1,mis2>` | string | 要 @提及的用户 MIS 号（逗号分隔） |
| `--mentionNames <名称1,名称2>` | string | 提及用户的姓名（逗号分隔，与 --mention 一一对应，不填则显示 MIS） |

**示例：**

```bash
# 基本划词评论
oa-skills citadel addDiscussionComment \
  --contentId "2755005703" \
  --nodeId "abc123def456" \
  --stepVersion 42 \
  --text "这段描述很准确，符合实际情况"

# 带 @提及的划词评论
oa-skills citadel addDiscussionComment \
  --contentId "2755005703" \
  --nodeId "abc123def456" \
  --stepVersion 42 \
  --text "请帮忙 review 一下" \
  --mention "zhangsan,lisi" \
  --mentionNames "张三,李四"
```

**输出（非 raw 模式）：**

```
✅ 划词评论添加成功！
discussionId：temp-discussion-2755005703--xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
quoteId：2755005703--xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
文档链接：https://km.sankuai.com/collabpage/2755005703
```

**输出（--raw 模式）：**

```json
{
  "discussionId": "temp-discussion-2755005703--...",
  "quoteId": "2755005703--...",
  "success": true
}
```

---

### replyDiscussionComment — 回复划词评论

对已有划词评论添加回复。`discussionId` 通过 `getDiscussionComments` 命令获取（对应结果中的 `commentId` 字段）。

**必填参数：**

| 参数 | 类型 | 说明 |
|---|---|---|
| `--contentId <id>` | string | 文档 ID |
| `--discussionId <id>` | string | 要回复的 discussionId（从 `getDiscussionComments` 返回的 `commentId` 字段获取） |
| `--text <内容>` | string | 回复正文纯文本内容 |

**可选参数：**

| 参数 | 类型 | 说明 |
|---|---|---|
| `--mention <mis1,mis2>` | string | 要 @提及的用户 MIS 号（逗号分隔） |
| `--mentionNames <名称1,名称2>` | string | 提及用户的姓名（逗号分隔，与 --mention 一一对应） |

**示例：**

```bash
# 回复划词评论
oa-skills citadel replyDiscussionComment \
  --contentId "2755005703" \
  --discussionId "temp-discussion-2755005703--xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" \
  --text "已按建议修改"

# 带 @提及的回复
oa-skills citadel replyDiscussionComment \
  --contentId "2755005703" \
  --discussionId "temp-discussion-2755005703--xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" \
  --text "已处理，请再看看" \
  --mention "zhangsan" \
  --mentionNames "张三"
```

## 评论内容格式限制

评论正文（包括划词评论和回复）仅支持以下三种内联节点类型：

| 类型 | 说明 | CLI 传递方式 |
|---|---|---|
| 纯文本 | 普通文字 | `--text` 参数直接传递 |
| @提及 | 提及某人（会触发消息通知） | `--mention` + `--mentionNames` 参数 |
| 链接 | （暂未在 CLI 中直接支持，如需使用请通过 client API 直接调用） | — |

**注意：** 每篇文档每次 AI 会话最多添加 1 条划词评论或 1 条回复，禁止批量循环调用避免刷屏。

## 获取 nodeId 和 stepVersion 的方法

添加划词评论前，需要先获取目标节点的 `nodeId` 和当前文档的 `stepVersion`。

**推荐流程：**

```bash
# 1. 获取文档 CitadelMD 内容（同时返回文档 JSON 结构和 stepVersion）
oa-skills citadel getDocumentCitadelMd --contentId "2755005703"

# 输出中会显示：
# 文档版本（stepVersion）：42
# 内容中的节点都带有 nodeId 属性，例如：
# :::paragraph{nodeId="abc123def456"}
# 这段文字内容
# :::
```

CitadelMD 格式中，每个块级节点的 `nodeId` 属性即为所需参数。也可以通过 `getDocumentJson` 获取原始 JSON，查看节点 `attrs.nodeId` 字段。

### nodeId 的查找说明

划词评论的 `nodeId` 必须是文档顶层内容块（`doc.content` 数组中的直接子节点），即段落（paragraph）、标题（heading）等块级节点的 `attrs.nodeId`。

**当前限制：**
- 只支持对整个顶层块节点添加划词评论（整段或整个标题作为引用范围）
- 不支持对段落内的部分文字范围进行划词（例如某句话中的某几个字）
- 如果需要对特定文字范围划词，建议先调整文档结构，将目标内容拆分为独立段落

## 常见错误处理

| 错误信息 | 原因 | 解决方法 |
|---|---|---|
| `未找到 nodeId=xxx 对应的节点` | nodeId 不存在或拼写有误 | 重新通过 `getDocumentCitadelMd` 获取正确的 nodeId |
| `提交 addMark step 失败` | stepVersion 与服务端不一致（文档有其他人同时编辑） | 重新获取最新的 stepVersion 后重试 |
| `划词评论不支持 1.0 旧版文档` | 文档是 1.0 格式（HTML 存储） | 该文档不支持划词评论，请使用全文评论 |
| `创建划词评论失败` | discussion 创建接口异常 | 检查网络和认证状态后重试 |
