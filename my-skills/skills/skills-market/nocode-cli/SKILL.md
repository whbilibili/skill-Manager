---
name: nocode-cli
description: 通过 NoCode CLI 操作美团 NoCode 零代码平台。当用户要求创建/修改零代码应用、截图预览、部署上线、管理项目、查看工程文件、操作数据库、设计稿转代码，或提及 "nocode"、"零代码"、"NoCode"、"D2C"、"设计稿"、"MasterGo" 时使用。

metadata:
  skillhub.creator: "zhaomenghuan02"
  skillhub.updater: "wanghongzhou03"
  skillhub.version: "V11"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "2981"
  skillhub.high_sensitive: "false"
---

# NoCode CLI Skill

## ⛔ 核心约束（最高优先级，违反将导致对话无法正常运行）

1. **所有操作只能通过 `nocode` CLI 命令完成。** 严禁使用 fetch / web_fetch / curl / HTTP 请求等方式直接请求 NoCode API 接口。
2. **向 NoCode Agent 发送命令时（`nocode create` / `nocode send`），必须使用自然语言描述需求。** 严禁在 prompt 中包含以下内容：
   - ❌ 执行具体命令（`git`、`npm`、`yarn`、`pnpm`、`pip`、`curl`、`wget` 等任何 shell 命令均不允许）
   - ❌ 指定使用某个工具或 MCP 工具（如 "使用 xxx 工具"、"调用 xxx MCP" 等）
   - ❌ 发送 shell 脚本、代码片段让 Agent 执行
   - ❌ 发送大段代码或完整文件内容（如通过 `nocode files get` 读取的文件内容直接粘贴到 prompt 中）
   - ✅ 可以给出文件相对路径，NoCode Agent 自身能读取工程文件，例如 "修改 src/App.jsx 中的标题样式"
   - ✅ 正确做法：用自然语言描述你想要的结果，例如 "把标题颜色改成红色"、"添加一个用户注册表单"
   - ✅ 例外：可以附带 SQL 语句，例如 "帮我执行以下 SQL 建表：CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT)"
   - ✅ 例外：可以附带**简短的**代码片段（几行）辅助定位，例如 "这段代码有问题，请修复：`const data = fetch('/api')`，应该加上 await"。但严禁发送整个函数、整个组件或整个文件的代码
3. **`create`/`send` 必须后台执行且设置足够超时（`yieldMs=600000`）。** 这两个命令是长时间流式命令（2-5 分钟），不设超时会导致进程被 SIGTERM 杀掉 → poll 不到 `done` 事件 → 无法判断完成状态 → 重复发送 send 陷入死循环。
4. **send/create 必须串行执行。** 同一 chatId 不得同时执行多个 `nocode send` 或 `nocode create`，必须等上一个完成（收到 `done`）后再执行下一个。并发执行会导致对话状态异常。
5. **遇到渲染异常、部署异常等平台侧异常时，严禁自行尝试解决。** 必须立即停止操作，引导用户联系 NoCode 研发排查处理。详见 [异常处理规则](#-异常处理规则)
6. **严禁修改 NoCode 工程架构。** 执行 `create`/`send`/`code clone` 以及本地开发修改代码前，必读 [project-architecture.md](references/project-architecture.md)，按其中的受保护文件清单、Prompt 拦截规则和替代方案执行。

## 前置准备

### 版本检查（每次执行前必须）

```bash
nocode --version
npm view @nocode/nocode-cli version --registry=http://r.npm.sankuai.com
```

- 未安装 → `npm install -g @nocode/nocode-cli --registry=http://r.npm.sankuai.com`
- 本地版本 < 最新版本 → 重新安装升级
- 已是最新 → 继续

### 登录状态检查（版本检查后必须执行）

执行 `nocode status` 检查环境和登录状态：
- 已登录 → 继续（会显示当前登录方式：CIBA / SSO OIDC / token）
- 未登录 → `nocode status` 会根据运行环境推荐登录命令，按提示执行即可：
  - **CatClaw 环境**：推荐 `nocode login --mis <mis>`，提示 **"请在大象个人助理确认登录"**
  - **非 CatClaw 环境**：推荐 `nocode login --sso`（SSO OIDC 浏览器登录）
- 如登录仍存在问题，请联系 NoCode 研发。**不推荐直接使用浏览器操作 NoCode 平台。**
- 输出包含 `⚠️  发现新版本` → **必须停止后续操作，立即更新 `@nocode/nocode-cli` 和 `nocode-cli` Skill（ID: 2981）的版本；若未安装该 Skill，应立即安装以确保 CLI 正常使用**

**获取 MIS 号**：先读 `~/.openclaw/openclaw.json` 中的 `X-User-Id`，读不到再问用户。不要猜测。

**⚠️ Token 过期自动续期（执行 API 类命令时可能触发）：**

执行 `create`、`send`、`deploy`、`list`、`screenshot`、`files list`、`files get` 等需要调用 API 的命令时，如果检测到 Token 过期，CLI 会根据登录方式自动续期：
- **SSO OIDC 登录**：自动静默续期
- **CIBA 登录**：自动重新换票

## 关键概念

- **NoCode Agent**：运行在云端 IDE 容器中的 AI，通过 `nocode create` / `nocode send` 命令触发，能自动生成代码、建表、安装依赖等。详见 [NoCode Agent 能力说明](references/nocode-agent-capabilities.md)
- **对话/作品环境变量**：每个对话/作品支持配置线上 (prod) / 线下 (test) 两套环境变量，仅当用户需要区分时才使用。详见 [env 命令规则](references/commands/cmd-env.md)
- **D2C（设计稿转代码）**：将 MasterGo 设计稿链接转换为 HTML 产物，再提交到 NoCode 平台创建页面。详见 [d2c 命令规则](references/commands/cmd-d2c.md)

## ⚠️ 强制约束

### send 相关

- **按功能模块拆分**：每次 `nocode send` 只包含**一个内聚的功能模块或一组紧密相关的修改**。多个不相关的功能必须拆分为多次 send，逐步 send → 截图确认 → 再 send 下一步。违反此规则会导致 NoCode Agent 生成质量严重下降甚至失败。
  - ❌ `nocode send <chatId> "添加用户注册表单并加验证，同时加一个登录页面，再把导航栏颜色改成深蓝色"` — 多个不相关功能混在一条
  - 完整拆分示例和原则见 [create & send 规则](references/commands/cmd-create-send.md)「每次 send 只包含一个功能模块」章节

### 代码同步（code clone / code pull）

- **`code clone` 用于将作品代码克隆到本地**：首次全量 clone，后续增量更新
- **`code pull` 用于将远程仓库的最新代码同步到 Sandbox**：当用户需要在 Sandbox 中获取仓库最新代码时使用
- **有本地变更时 pull 需确认**：`code pull` 检测到 Sandbox 有未推送变更时会拒绝执行，需 `--force` 跳过确认
- **⭐ 本地开发工作流**：当用户要求"拉代码到本地改"、"本地开发"、"本地修改代码"时，**必须先读取 [workflow-local-dev.md](references/workflows/workflow-local-dev.md) 并严格按其 Spec-Driven 流程执行**（Phase 0~5：INITIALIZE → ANALYZE → DESIGN → IMPLEMENT → VALIDATE → HANDOFF）。不要自行编排流程

### 链接与展示

- **预览页面只能通过截图或 chatUrl**：给用户预览效果时，只能使用 `nocode screenshot` 截图展示，或提供 chatUrl（形如 `https://nocode.sankuai.com/#/chat?pageId=xxx`）让用户自行查看。**严禁将 renderUrl**（形如 `https://xxx.sandbox.nocode.sankuai.com`）**展示给用户**——renderUrl 仅供 CLI 内部截图使用，且容器未启动时访问会 404
  - ❌ 错误：`https://xxx.sandbox.nocode.sankuai.com` ← 不要给用户
  - ✅ 正确：`https://nocode.sankuai.com/#/chat?pageId=xxx` ← 给用户
- **chatId 链接**：必须使用 `[{chatId}]({chatUrl})` 格式（可同时展示纯文本 chatId 供复制）
- **部署地址链接**：必须使用 `[{externalUrl}]({externalUrl})` 格式
- 禁止以纯文本输出 URL，所有面向用户的链接必须可点击

### 文件与数据库

- **查看文件必须用 files 命令**：使用 `nocode files list` / `nocode files get`，禁止通过 `nocode send` 获取文件内容
- **数据库操作必须先询问用户意图**：当用户提到数据库、database、supabase 等关键词时，必须先明确询问用户是为当前对话**新建 database 资源**（`nocode database create`）还是**复用既有 database 资源**（`nocode database projects` + `connect`），禁止未经确认直接执行 `create`
- **建表/改表必须用 NoCode Agent**：NoCode CLI `database` 命令仅支持数据 CRUD，DDL 操作必须通过 `nocode send` 让 NoCode Agent 完成
- **数据库状态判断**：`database status` 返回 `isConfirmed: false` 时，即使 `connected: true`，数据库也不可用，必须通过 `create`（新建）或 `projects` + `connect`（复用既有）重新建立连接
- **数据驱动需求（看板、报表、仪表盘等）推荐走 database 流程**：禁止将数据文件直接 `--files` send 给 NoCode Agent 或让 Agent curl 下载；不推荐让 Agent 通过请求外部静态数据文件的下载链接来驱动页面。详细流程见 [best-practices.md](references/best-practices.md) 场景 2

### 📌 最佳实践

遇到 HTML 复刻、数据驱动看板、架构改动需求等场景时，**必读 [best-practices.md](references/best-practices.md)**，按其中的对应流程执行。

## 命令速查

**⚠️ 强制规则：执行有"详细规则"链接的命令前，必须先读取对应的 references 文件，按其中的规则执行。不可跳过。**

| 命令 | 用途 | 备注 | 详细规则（执行前必读） |
|------|------|------|---------|
| `nocode create "<prompt>"` | 创建应用 | NDJSON 流式，需后台执行（`yieldMs=600000`）+ poll。支持 `--images`/`--files`/`--urls`/`--safety` | ⚠️ [命令必读](references/commands/cmd-create-send.md) · [架构保护必读](references/project-architecture.md) |
| `nocode send <chatId> "<msg>"` | 发送修改 | NDJSON 流式，需后台执行（`yieldMs=600000`）+ poll。支持 `--images`/`--files`/`--urls`/`--safety` | ⚠️ [命令必读](references/commands/cmd-create-send.md) · [架构保护必读](references/project-architecture.md) |
| `nocode files list <chatId> [path]` | 查看目录树 | 边界标记 `---TREE_START/END---` | ⚠️ [必读](references/commands/cmd-files.md) |
| `nocode files get <chatId> <path>` | 查看文件内容 | 边界标记 `---FILE_CONTENT_START/END---` | ⚠️ [必读](references/commands/cmd-files.md) |
| `nocode screenshot <chatId>` | 截图预览 | 返回 S3 URL，失败不阻塞 | ⚠️ [必读](references/commands/cmd-screenshot.md) |
| `nocode deploy <chatId>` | 部署上线 | 自动用最新版本，渲染失败会拦截 | ⚠️ [必读](references/commands/cmd-deploy.md) |
| `nocode env <action> <chatId>` | 对话/作品环境变量管理 | list / set / delete / switch | ⚠️ [必读](references/commands/cmd-env.md) |
| `nocode status` | 检查环境和登录状态 | 显示登录方式、版本信息 | — |
| `nocode login` | 登录 | `--mis <mis>`（CIBA）/ `--sso`（SSO）/ `--token <token>` | — |
| `nocode logout` | 登出 | 清除本地凭证 | — |
| `nocode list` | 项目列表 | `--page N --size N --json` | — |
| `nocode detail <chatId>` | 查看详情 | JSON 输出 | — |
| `nocode messages <chatId>` | 查看消息列表 | `--page N --size N --json` | — |
| `nocode versions <chatId>` | 版本列表 | — | — |
| `nocode delete <chatId> --confirm` | 删除项目 | `--confirm` 为必需参数 | — |
| `nocode code clone <chatId>` | 克隆作品代码到本地 | 智能增量更新，支持 `--dir`、`--json` | ⚠️ [命令必读](references/commands/cmd-code.md) |
| `nocode code pull <chatId>` | 从远程仓库拉取代码到 Sandbox | 支持 `--force`（跳过确认）、`--json` | ⚠️ [命令必读](references/commands/cmd-code.md) |
| `nocode answer <chatId> <eventId> <conversationId>` | 回答 NoCode Agent 提问 | 根据 `question` 事件的 `answer_hint` 拼接参数，支持 `--select`/`--text`/`--cancel` | ⚠️ [必读](references/commands/cmd-create-send.md) |
| `nocode database <action> <chatId>` | 数据库操作 | JSON `{ action, status, data }` | ⚠️ [必读](references/commands/cmd-database.md) |
| `nocode d2c "<design-link>"` | 设计稿转代码 | 生成 HTML + 截图，需配合 `nocode create` 提交平台 | ⚠️ [必读](references/commands/cmd-d2c.md) |

## 典型工作流

> 以下为概览示例。执行具体命令前，**必须先读取命令速查表中对应的「详细规则」链接**，按其中的完整规则执行。

```bash
# 1. 登录
nocode login --mis <mis>

# 2. 创建（NDJSON 流式输出，done 事件包含 chatId）
nocode create "做一个宣传页面"

# 3. 修改
nocode send <chatId> "把主色调改成深蓝色"

# 4. 截图确认
nocode screenshot <chatId>

# 5. 部署
nocode deploy <chatId>

# 6. 遇到问题时：先查代码再精确修改（禁止用 send 获取文件内容）
nocode files list <chatId>                        # 查看工程目录结构
nocode files list <chatId> src                    # 浏览子目录
nocode files get <chatId> src/App.jsx             # 读取相关文件内容
# → 分析代码，定位问题原因
nocode send <chatId> "具体的修改指令"        # 发送精确修改
nocode screenshot <chatId>                  # 截图确认修改效果
```

### 用户提供图片/文档/链接时的处理方式

当用户上传了图片、文档文件或提供了学城链接时，应优先询问用户：是希望总结内容后描述给 NoCode Agent，还是以附件形式直接传给 NoCode Agent（通过 `--images`/`--files`/`--urls` 参数）

- ⚠️ 不推荐：直接读取文件内容或学城文档内容再粘贴到 prompt、将图片转为文字描述后发送 — 这些方式会丢失原始上下文或视觉信息，且 prompt 超长会导致质量下降
- ✅ 推荐：`nocode create "参考设计稿做页面" --images ./design.png`
- ✅ 推荐：`nocode send <chatId> "参考这个文档修改" --files ./requirements.md`
- ✅ 推荐：`nocode create "参考学城文档做页面" --urls https://km.sankuai.com/collabpage/xxxxx`

## 容器状态检查

`screenshot`、`send`、`deploy`、`code pull`、`files list`、`files get` 命令执行前会自动检查容器状态。如容器已停止，会自动触发冷启动并等待就绪（最长 5 分钟）。无需手动处理。

## 常见错误速查

| 错误信息 | 解决方案 |
|----------|---------|
| `未登录，请先执行 nocode login` | 执行 `nocode status` 按提示登录 |
| `busy` 事件 | 等待上一轮 `done`，经用户确认后重试 |
| `Agent 对话异常，请稍后重试` | 向用户反馈该错误信息，提示稍后重试。禁止自动重试或静默忽略 |
| `SIGTERM` / 进程被强制终止 | `create`/`send` 是长时间流式命令（可能 2-5 分钟），必须后台执行并设置足够的超时（`yieldMs=600000`即 10 分钟），否则进程会被终端提前杀掉 |
| `容器启动等待超时` | 检查网络或稍后重试 |
| `当前有其他文件操作正在执行` | 等几秒后重试，最多 2 次 |
| `question` 事件（NoCode Agent 提问） | **必须先向用户询问，禁止自动回答。** 展示 `title` + `questions[].prompt`（问题内容）和 `answer_hint.actions`（可选动作），用户回复后拼接 `nocode answer` 命令执行。详见 [create & send 规则](references/commands/cmd-create-send.md)「question 事件处理」章节 |
| `暂无可部署版本` | 先创建或修改生成代码 |
| `获取文件内容失败` | 检查路径，先用 `nocode files list <chatId>` 确认文件存在 |
| 渲染失败 / 截图白屏 / 部署异常 / 页面无法访问 | **⛔ 平台侧异常，禁止自行修复。** 停止操作，告知用户并引导联系 NoCode 研发排查 |
| Agent 连续 2 次 `error` 事件 | **⛔ 停止重试，** 告知用户并引导联系 NoCode 研发排查 |

## 🚨 异常处理规则

遇到平台侧异常（渲染失败、部署失败、容器崩溃、Agent 连续失败等）时，严禁自行解决，必须立即停止操作并引导用户联系 NoCode 研发排查。

**禁止的处理方式：**

- ❌ 尝试通过 `nocode send` 让 Agent 修复渲染问题（如 "修复页面白屏"）
- ❌ 反复重试部署命令期望异常自行恢复
- ❌ 猜测异常原因并自行实施修复方案
- ❌ 不告知用户异常情况就静默重试

**正确做法：** 停止操作 → 告知用户具体错误信息 → 建议联系 NoCode 研发排查处理
