---
name: ee-ones
description: "ONES 研发管理助手，通过 `ones` 命令行操作美团 ONES 系统（ones.sankuai.com）。覆盖：工作项管理（查询/创建/更新/删除/指派需求、任务、缺陷、详情、评论、父子关联、资产管理、附件管理）、URL 解析（从 ones.sankuai.com 链接中提取空间ID/工作项ID/类型等字段）、工时管理（查询工时、填写工时、工时汇总、修改工时、补填工时、替他人填工时、团队工时查询）、分支管理（生成分支名、创建分支、关联分支、搜索分支、根据仓库和分支查询关联工作项）、迭代管理（查询迭代、创建迭代、迭代进展）、测试管理（测试用例、测试计划、测试轮次）、提测、排期管理（查询排期、创建排期事项、更新排期事项、删除排期事项、设置排期时间）、空间查询、字段查询、界面方案查询、DSL 筛选、大象群管理（查询/创建工作项关联的大象群）。当用户提到以下内容时使用本 skill：查需求、查任务、查缺陷、有哪些bug、我的待办、建个需求、建个任务、提个bug、改一下需求、分给谁、转给某人、做到哪了、进展怎么样了、还差什么没做完、哪些在进行中、我负责的、指派给我的、帮我看看有什么要做的、这周要做的、这个迭代有什么、看一下详情、加个评论、建个子任务、挂到父需求下面、拉个分支、分支名叫什么、这个分支是哪个需求的、冲刺、今天填工时了吗、补填工时、今天做了什么、本周工作量、这个月工时、帮他填工时、代填工时、发起提测、提测了吗、转测、写用例、建个测试计划、跑一轮测试、执行用例、用例通过了吗、关联缺陷到用例、测试进度怎么样、用例目录、安排排期、什么时候上线、什么时候交付、延期了吗、有没有延期风险、帮我看看这个ONES链接、ones.sankuai.com 链接、PRD、技术方案、设计稿、上传文件到工作项、字段有哪些可选项、筛选一下、帮我查一下、工作项建群。"
version: 2.2.29
tag: [ONES, 工作项, 需求, 任务, 缺陷, bug, 分支, 迭代, 冲刺, 测试, 工时, 工作量, 提测, 转测, 空间, 字段, 筛选, 查询, 搜索, 待办, 我的, 评论, 关联, 用例, 轮次, 计划, 开发进展, 进度, 上线, 时间范围, 预计开发, 预计上线, 链接解析, 工作项链接, ones.sankuai.com, 资产, 文档, PRD, MRD, BRD, 设计稿, 技术文档, 测试方案, 排期, 排期事项, 排期进度, UI交付, 排期时间, 交付时间, 附件, 上传附件, 删除附件, 新建, 创建, 修改, 更新, 删除, 指派, 详情, 状态, 流转, 子任务, 父需求, 工时填写, 工时记录, 工时汇总, 补填, 代填, 团队工时, 大象群, 建群, 工作项群, 延期, 风险, 版本进度, 项目进展, 做到哪了, 谁负责, 分给谁, 拉分支, 提个bug, 填工时, 看详情, 加评论, 建迭代, 写用例, 上线时间, 什么时候上线, 解析链接]

metadata:
  skillhub.creator: "hequanchuan"
  skillhub.updater: "hequanchuan"
  skillhub.version: "V12"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "2120"
---

# ONES CLI 助手

通过 `ones` 命令行管理美团 ONES（ones.sankuai.com）系统的工作项、工时、分支、迭代、测试等。

本 Skill 采用渐进式加载：SKILL.md 包含路由、速查和 Case 精简索引，已覆盖绝大多数场景；只在需要详细参数、写操作确认、完整编排步骤或排查认证问题时，才按需读取 `references/` 下的文件。

---

## 文件结构与加载策略

```
ee-ones/
├── SKILL.md                     ← 路由 + 速查 + Case 精简索引（当前文件）
└── references/
    ├── command-reference.md     ← 查具体参数时加载
    ├── interactive-params.md    ← 执行创建/更新/删除时加载
    ├── auth-guide.md            ← 遇到认证问题时加载
    ├── filter-query-dsl.md      ← 使用 fi 命令构建 DSL 时加载；
    │                               含「与我相关查询」强制规则（策略 5）
    └── case-examples.md         ← 完整多步骤编排示例（按需加载）
```

| 层级 | 内容 | 加载时机 |
|------|------|---------|
| 元数据 | description + tag | 始终在上下文 |
| SKILL.md 正文 | 速查表 + Case 精简索引 + FAQ | Skill 触发时 |
| references/ | 完整参数、交互流程、认证指南、完整 Case 示例 | 按需读取 |

> 按加载时机拆分而非按实体拆分，SKILL.md 提供路由和精简索引，Agent 只需在「查参数」「写操作」「排错」「查看完整编排步骤」时才额外读取 reference 文件。

---

## Step 0: 系统消歧（ONES vs MEP）

美团有两套研发管理系统：ONES（`ones` 命令，本 Skill）和 MEP（`ones2` 命令，ee-mep-ones Skill）。多数用户只用其中一套，通过以下检测避免误触发。

**0.1 检测环境：**

```bash
which ones2
```

- `ones2` **不存在** → 跳过 Step 0，直接进入 Step 1
- `ones2` **存在** → 双 CLI 共存，继续消歧 ↓

**0.2 读取偏好：**

```bash
ones config   # 查看「偏好系统」字段
```

**0.3 按偏好路由：**

| 偏好状态 | 用户意图 | 处理 |
|---------|---------|------|
| 偏好 = ONES | — | 直接进入 Step 1 |
| 偏好 = MEP | — | 告知用户使用 `ones2`（ee-mep-ones Skill），结束 |
| 未设置 | 明确提到 ONES（如 "查ONES需求"、ones.sankuai.com URL） | 执行 `ones config --set-system ONES` 后进入 Step 1 |
| 未设置 | 明确提到 MEP（如 "帮我用MEP查"） | 执行 `ones config --set-system MEP` 后引导到 `ones2` |
| 未设置 | 未指定系统 | 询问用户日常用哪套系统，确认后执行 `ones config --set-system <ONES/MEP>` |

偏好持久化到本地配置文件，跨会话生效，设置一次后不再询问。

---

## Step 1: 指令探测、版本检查与认证（每次触发必做）

ones-cli 频繁更新，先探测可用指令和检查版本，可避免参数变更导致的意外失败。

```bash
# 1.1 探测当前可用指令（⚠️ 必做，作为后续编排的依据）
ones --help
# Agent 必须根据 --help 输出的实际子命令列表来编排指令，
# 不要假设命令存在，以 --help 输出为准。
# 对于不确定参数的子命令，可进一步执行 ones <子命令> --help 查看详细参数。

# 1.2 检查版本是否最新
ones --version
npm view @ee/ones-cli version --registry=http://r.npm.sankuai.com
# 版本不一致 → npm install -g @ee/ones-cli --registry=http://r.npm.sankuai.com

# 1.3 认证（默认策略：先执行，按需认证）
#   token 通常已缓存，Agent 应直接执行目标命令，不要在每次执行前主动走认证步骤。
#   CLI 自动按优先级静默获取凭证：
#     ⓪ CatClaw SSO（沙箱环境自动，无需交互）
#     ① 环境变量 ONES_ACCESS_TOKEN（CI/CD、定时任务）
#     ② 已缓存的 SSO Token（ones sso login 登录过，实际 72h 有效，48h 内免登录）
#     ③ CatPaw 本地降级（自动读取 ~/.catpaw/ 配置）
#   全部不可用时 → 进入认证修复流程（见下方）
```

> **指令探测策略**：`ones --help` 的输出是 Agent 编排指令的唯一权威来源。如果 SKILL.md 速查表中列出了某个命令但 `--help` 输出中不存在，说明当前版本尚未支持，**不要执行该命令**。对于不确定参数的命令，可进一步执行 `ones <子命令> --help` 查看详细参数。
>
> **认证策略（先执行，按需认证）**：
>
> **步骤 A：直接执行目标命令**（如 `ones workbench`、`ones workitem-detail` 等），token 通常已缓存，Agent 不要在每次执行前主动走认证。
> - 成功 → 继续后续流程（无需任何认证操作）
> - 失败（401 / "未登录" / "token expired"）→ 进入步骤 B
>
> **步骤 B：认证修复流程（仅在步骤 A 失败时执行，按顺序尝试）**
>
> | 优先级 | 方式 | 命令 | 说明 |
> |--------|------|------|------|
> | ① | CatClaw SSO | `ones sso login --catclaw --mis <misId>` | **沙箱环境首选**，完全自动、非交互式。`--mis` 必传 |
> | ② | Token 刷新 | `ones sso refresh` | 使用已保存的 refresh_token 静默续期 |
> | ③ | CIBA 认证 | `ones sso login --ciba --mis <misId> --force` | 大象 App 确认，`--force` 跳过重新登录确认 |
> | ④ | 浏览器 SSO | `ones sso login --browser --force` | 自动打开浏览器完成 SSO，`--force` 跳过重新登录确认 |
> | ⑤ | 手动粘贴 Token | `ones sso login --manual` | **终极兜底**，用户从浏览器复制 Token 粘贴 |
>
> ```
> 命令返回 401 / 未登录
>   ├── ones sso login --catclaw --mis <misId>
>   │     ├── 成功 → 重试原命令
>   │     └── 失败 ↓
>   ├── ones sso refresh
>   │     ├── 成功 → 重试原命令
>   │     └── 失败 ↓
>   ├── ones sso login --ciba --mis <misId> --force
>   │     ├── 成功 → 重试原命令
>   │     └── 失败 ↓
>   ├── ones sso login --browser --force（浏览器兜底）
>   │     ├── 成功 → 重试原命令
>   │     └── 失败 ↓
>   └── 提示用户手动登录: ones sso login --manual（终极兜底）
>         └── 用户粘贴 Token 后 → 重试原命令
> ```
>
> **`--force` 参数说明**：所有 `sso login` 子命令均支持 `-f / --force`，跳过已登录时的「是否要重新登录？」交互确认，Agent 场景下**必须加 `--force`** 以避免交互阻塞。`sso logout` 同样支持 `--force` 跳过登出确认。
>
> **获取 MIS 号的方式**（按优先级）：
> 1. 从 `ones config` 中读取已保存的 `operator` 字段
> 2. 从沙箱环境上下文获取（如 `USER.md` 或环境变量 `ONES_OPERATOR`）
> 3. 直接询问用户
>
> **沙箱环境额外依赖**：CatClaw SSO 认证依赖 `@mtfe/mtsso-auth-official`，CLI 会自动检测并安装。若自动安装失败，执行：`npm install @mtfe/mtsso-auth-official@latest --registry=http://r.npm.sankuai.com`
>
> **Token 时效**：SSO access token 实际有效 72h（3天），CLI 本地 48h 判定过期（留 24h 余量），**48h 内无需二次确认登录**。遇到认证问题读取 [认证指南](./references/auth-guide.md)。
>
> **⚠️ 禁止交互式认证命令**：Agent 场景下所有认证命令**必须**带 `--mis <misId>` 参数，避免产生交互式输入阻塞。**禁止**使用不带 `--mis` 的 `ones sso login --ciba` 或 `ones sso login --catclaw`。

---

## Step 2: 根据用户意图选择命令

根据自然语言描述匹配下方速查表中的命令。写操作需确认参数时读取 [写操作参数](./references/interactive-params.md)，查完整参数时读取 [命令速查](./references/command-reference.md)。

---

## 命令速查表

所有命令前缀 `ones`，支持 `--json` 输出和 `--help` 查看帮助。

### 基础

| 别名 | 命令 | 用途 |
|------|------|------|
| - | `sso login --catclaw --mis <MIS号>` | CatClaw SSO 登录（沙箱环境首选，完全自动，必须带 --mis） |
| - | `sso login --ciba --mis <MIS号> --force` | CIBA 登录（大象 App 确认，--force 跳过重新登录确认） |
| - | `sso login --browser --force` | 浏览器 SSO 登录（自动开浏览器，--force 跳过重新登录确认） |
| - | `sso login --manual` | 手动粘贴 Token 登录（终极兜底，无需浏览器/大象） |
| - | `sso status` | 查看登录状态 |
| - | `sso refresh` | 刷新 Token |
| - | `sso logout --force` | 登出（--force 跳过确认） |
| - | `config` | 查看配置 |

### 工作项与查询

| 别名 | 命令 | 用途 |
|------|------|------|
| - | `issues -p <空间ID>` | 查询空间工作项 |
| - | `ones-workitem-issues -p <空间ID>` | 查询空间工作项（同上） |
| `fi` | `filter-issues -p <空间ID>` | DSL Query 筛选查询工作项 |
| `fv` | `filter-views -p <空间ID>` | 查询空间筛选视图（含 query 和 columns） |
| - | `my -p <空间ID>` | 我的待处理 |
| `wb` | `workbench` | 工作台数据 |
| `ws` | `search` | 交互式检索 |
| `ss` | `space-search -p <空间ID>` | 空间内检索 |
| `wc` | `workitem-create` | 创建工作项 |
| `wurl` | `workitem-url -i <ID>` | 获取工作项页面 URL（调用接口；或加 `-t <TYPE> -p <spaceId>` 本地构造 V1 URL，不走网络） |
| `up` | `url-parse -u <URL>` | 解析 ONES V1 页面 URL，提取空间 ID、工作项 ID、类型等字段（V2 URL 自动提示使用 ones2） |
| `wu` | `workitem-update` | 更新工作项 |
| `wd` | `workitem-delete` | 删除工作项 |
| - | `workitem-detail -i <ID>` | 查询详情 |
| `wco` | `workitem-comment list` | 查询评论 |
| `wch` | `workitem-child -i <父ID> -w <子ID> -a <关联类型>` | 关联子工作项 |
| `wcq` | `workitem-child-query -i <父ID> -a <关联类型>` | 查询子工作项列表 |
| `wchd` | `workitem-child-delete -i <父ID> -s <子ID> -a <关联类型>` | 删除子关联 |
| `wcp` | `workitem-parent -i <子ID> -w <父ID> -a <关联类型>` | 关联父工作项 |
| `wcpq` | `workitem-parent-query -i <子ID> -a <关联类型>` | 查询父工作项 |
| `wcpd` | `workitem-parent-delete -i <子ID>` | 解除父关联 |
| `wco` | `workitem-comment add` | 添加/回复评论 |
| `wa` | `workitem-asset list -i <工作项ID>` | 查询工作项资产列表 |
| `wa` | `workitem-asset add -i <工作项ID> --title <标题> --url <链接> --type <类型>` | 添加工作项资产 |
| `wa` | `workitem-asset update -i <工作项ID> -a <资产ID> --title <标题> --url <链接> --type <类型>` | 更新工作项资产 |
| `wa` | `workitem-asset remove -i <工作项ID> -a <资产ID>` | 移除工作项资产 |

### 附件

| 别名 | 命令 | 用途 |
|------|------|------|
| `watt` | `workitem-attachment upload -i <ID> -f <文件路径>` | 上传附件到工作项 |
| `watt` | `workitem-attachment delete -i <工作项ID> -a <附件ID>` | 删除工作项附件（强制二次确认） |

### 大象群

| 别名 | 命令 | 用途 |
|------|------|------|
| `wxg` | `workitem-xmgroup query -i <ID> -t <TYPE>` | 查询工作项已关联的大象群 |
| `wxg` | `workitem-xmgroup roles -i <ID> -t <TYPE>` | 查询可选字段及默认入群成员 |
| `wxg` | `workitem-xmgroup create -i <ID> -t <TYPE>` | 创建大象群（自动查询成员，已关联则跳过） |
| `wxg` | `workitem-xmgroup create -i <ID> -t <TYPE> --users <MIS,逗号分隔>` | 手动指定成员创建大象群 |

| `sp` | `spaces` | 空间列表 |
| `apps` | `space-apps -p <空间ID>` | 空间应用 |

### 分支

| 别名 | 命令 | 用途 |
|------|------|------|
| `bg` | `branch-gen -i <ID>` | 生成分支名 |
| `bc` | `branch-create -i <ID>` | 创建分支并关联 |
| `ba` | `branch-associate` | 关联已有分支 |
| `bs` | `branch-search` | 搜索分支 |
| `bd` | `branch-disassociate -b <ID>` | 取消关联 |
| `br` | `branch -p <空间ID> -i <ID>` | 查询关联分支 |
| `bw` | `branch-workitems -r <仓库SSH地址> -b <分支名>` | 根据仓库和分支查询关联的工作项 |

### 迭代

| 别名 | 命令 | 用途 |
|------|------|------|
| `iter` | `iterations -p <空间ID>` | 迭代列表 |
| `ci` | `create-iteration` | 创建迭代 |
| `ui` | `update-iteration` | 编辑迭代 |
| `di` | `delete-iteration` | 删除迭代 |
| `si` | `set-iteration` | 设置工作项迭代 |
| `fi -i` | `filter-issues -i <迭代ID>` | 迭代下工作项 |

### 测试

| 别名 | 命令 | 用途 |
|------|------|------|
| `case-info` | `case-detail -i <用例ID>` | 查询用例详情 |
| `case-info` | `case-detail -i <用例ID> --with-requirements` | 查询用例详情 + 关联需求 |
| `case-info` | `case-detail -i <用例ID> --with-defects` | 查询用例详情 + 关联缺陷 |
| `case-info` | `case-detail -i <用例ID> --all` | 查询用例详情 + 关联需求 + 关联缺陷 |
| `case-c` | `case-create` | 创建用例 |
| `case-u` | `case-update` | 更新用例 |
| `case-d` | `case-delete` | 删除用例 |
| `case-ss` | `case-space-search` | 搜索用例 |
| - | `case-tree -p <空间ID>` | 浏览用例目录树 |
| - | `case-tree -p <空间ID> --list-dirs` | 仅展示目录树 |
| - | `case-tree -p <空间ID> --dir-id <目录ID>` | 查询目录下用例 |
| - | `case-tree -p <空间ID> --list-views` | 查看用例视图 |
| `plan-c` | `plan-create` | 创建计划 |
| `plan-u` | `plan-update` | 更新计划 |
| `plan-s` | `plan-search` | 搜索计划 |
| `plan-d` | `plan-delete` | 删除计划 |
| `round-c` | `round-create` | 创建轮次 |
| `round-u` | `round-update` | 更新轮次名称 |
| `round-d` | `round-delete` | 删除轮次 |
| `round-ca` | `round-case` | 添加/删除轮次用例 |
| `round-cu` | `round-case-update` | 更新执行状态 |
| `round-ce` | `round-case-executor` | 更新执行人 |
| `round-cs` | `round-case-search` | 查询执行用例 |
| `round-cli` | `round-case-link-issue` | 关联缺陷 |

### 提测

| 别名 | 命令 | 用途 |
|------|------|------|
| `st` | `submit-test -p <空间ID> -i <ID>` | 查询提测详情 |
| `stc` | `submit-test-create` | 创建提测单 |
| `stu` | `submit-test-update` | 更新提测状态 |

### 工时

| 别名 | 命令 | 用途 |
|------|------|------|
| `wtl` | `worktime-list` | 已填工时工作项 |
| `wtd` | `worktime-detail -i <ID>` | 工作项工时日志 |
| `wts` | `worktime-summary` | 每日工时汇总 |
| `wtsearch` | `worktime-search` | 检索可填工时项 |
| `wtadd` | `worktime-save -i <ID> --hours <N>` | 填写工时 |
| `wtadd-for` | `worktime-save-for --operator <MIS> -i <ID> --hours <N>` | 替他人填写工时 |
| `wtu` | `worktime-update --id <记录ID>` | 修改工时 |
| `wtdel` | `worktime-delete --id <记录ID>` | 删除工时 |
| `wtteam` | `worktime-team` | 团队工时周汇总 |

### 字段

| 别名 | 命令 | 用途 |
|------|------|------|
| `fs` | `field-search -p <空间ID>` | 查询空间字段列表（含字段 ID、variable、类型） |
| `fs` | `field-search -p <空间ID> -t DEVTASK` | 查询开发任务字段（默认 REQUIREMENT） |
| `fs` | `field-search -p <空间ID> -n "关键词"` | 按字段名称模糊搜索 |
| `fs` | `field-search -p <空间ID> --is-work-time-group` | 查询工时相关字段 |
| `fo` | `field-options -p <空间ID> -f <字段ID> -t <字段类型>` | 查询字段可选值 |
| `fo` | `field-options -p <空间ID> -f <字段ID> -t component_user` | 查询空间成员列表 |
| `fo` | `field-options -p <空间ID> -f <字段ID> -t component_iteration -s REQUIREMENT` | 查询迭代可选值 |
| `fo` | `field-options -p <空间ID> -f <字段ID> -t component_state -i <工作项ID>` | 查询可流转状态 |

### 界面方案

| 别名 | 命令 | 用途 |
|------|------|------|
| `vs` | `view-scheme -p <空间ID> -s <子类型ID>` | 查询子类型界面方案字段列表 |

### 排期管理

| 别名 | 命令 | 用途 |
|------|------|------|
| `sq` | `schedule-query -p <空间ID> -i <工作项ID>` | 查询排期信息（含各阶段事项） |
| `sq` | `schedule-query -p <空间ID> -i <工作项ID> -s DEVELOPING` | 查询指定阶段排期 |
| `sic` | `schedule-item-create -p <空间ID> -i <工作项ID> -s <阶段>` | 新建排期事项 |
| `siu` | `schedule-item-update -p <空间ID> -i <工作项ID> --item-id <事项ID>` | 更新排期事项 |
| `sid` | `schedule-item-delete -p <空间ID> -i <工作项ID> --item-id <事项ID>` | 删除排期事项 |
| `sctu` | `schedule-time-update -p <空间ID> -i <工作项ID>` | 修改排期字段（时间/人员/实现类型/研发自测） |

---

## 指令编排模式（Case 精简索引）

以下索引覆盖常见场景的核心命令。完整的多步骤编排流程见 [完整 Case 示例](./references/case-examples.md)。

核心思路：**先执行 `ones --help` 确认可用指令 → 先查后改 → ID 链式传递**。

| Case | 场景 | 核心命令 | 要点 |
|------|------|---------|------|
| 1 | 查工时 & 补填 | `ones wts` → `ones wtsearch` → `ones wtadd` | 先查汇总找缺填日期，再逐天填写 |
| 2 | 为需求建分支 | `ones workitem-detail` → `ones bg` → `ones bc` | 详情获取空间ID，生成分支名后创建 |
| 3 | 创建需求到迭代 | `ones sp` → `ones vs` → `ones wc` → `ones iter` → `ones si` | 查空间→子类型→创建→查迭代→指派 |
| 4 | 查分支和提测 | `ones workitem-detail` → `ones branch` → `ones st` | 先查详情获取空间ID |
| 5 | 完整测试流程 | `ones plan-c` → `ones round-c` → `ones round-ca` → `ones round-cu` | 计划→轮次→用例→执行 |
| 6 | 改/删工时记录 | `ones wtd` → `ones wtu` / `ones wtdel` | 先查日志获取记录ID |
| 7 | 批量填工时 | `ones wtsearch` → `ones wtadd -d 起~止 -y` | 日期范围 + `-y` 跳过确认 |
| 8 | 创建工作项引导 | `ones sp` → `ones fo` → `ones vs` → `ones fs` → `ones fo` → `ones wc` | ⚠️ 必填字段未填齐会被 CLI 阻断，详见下方说明 |
| 9 | ⚠️ 查我的工作项 | `ones fi --assigned <misId> --state TODO,DOING` | **必须带人员筛选**，[详见策略5](./references/filter-query-dsl.md) |
| 10 | 按时间查开发/上线 | `ones fi -f "...,customField13641,...,customField13200" --json` | 时间字段可能为空，先拉取再做区间计算 |
| 11 | 延期风险分析 | `ones fi -f "...,stateCategory,..." --json` | 按 stateCategory 分层判断风险 |
| 12 | 管理资产/文档 | `ones wa list` → `ones wa add/update/remove` | type 可选: PRD/TD/DESIGN_DRAFT 等 |
| 13 | 创建大象群 | `ones wxg create -i <ID> -t <TYPE>` | 自动幂等检查，已关联则跳过 |
| 14 | 查排期 & 设时间 | `ones sq` → `ones sctu --release-time` | 查排期→修改排期时间字段 |
| 15 | 新建排期事项 | `ones sq` → `ones sic` → `ones siu` | 工作量/时间设在子事项上 |
| 16 | 解析 ONES 链接 | `ones url-parse -u <URL>` → `ones workitem-detail` | V2 URL 提示用 `ones2` |

> **关键提示**：
> - **⛔ Case 8 创建工作项必填字段校验**：`ones wc` 会在创建前自动查询子类型界面方案（CREATE_VIEW），提取所有 `required=true` 的必填字段并校验。**如果存在未填的必填字段，CLI 会直接阻断创建并一次性列出所有缺失字段**（含 variable、type、id 和补充方式）。Agent 收到阻断信息后：
>   1. **不要重试相同的命令** — 必须先补齐缺失字段再执行
>   2. **根据 CLI 输出的缺失清单**，逐个补充：CLI 参数可覆盖的（如 `--assigned`、`--desc`）直接加参数；其他字段通过 `-F / --field` 传入
>   3. **字段可选值获取**：`ones fo -p <空间ID> -f <字段ID> -t <字段类型>` 查询可选值，不要猜测
>   4. **如果界面方案查询本身失败**（网络/权限问题），CLI 同样会阻断，此时应提示用户检查空间 ID、子类型 ID 和权限
>   5. **面向用户的提示**：告知用户「该空间的子类型要求必须填写 XX、YY 等字段，请提供这些信息后再创建」，而不是静默跳过
> - Case 9 **「与我相关」查询必须带人员筛选**，查不到禁止去掉 `--assigned` 重试。详细规则见 [DSL 筛选指南 - 策略 5](./references/filter-query-dsl.md)
> - Case 9/10/11 相关的**全局字段 variable（所有空间通用，无需查询）**：时间字段 `customField13641`(预计开发开始)、`customField13642`(预计开发结束)、`customField11681`(预计提测)、`customField13200`(预计上线)；人员角色字段 `customField13161`(产品主R)、`customField24214`(技术主R，DSL 别名 `rdMasters`)、`customField24215`(测试主R)、`developer`(开发人员，DSL 别名 `developers`)。人员组件类型统一为 `component_user`，ONES 中**不存在** `component_container_user` 类型
> - Case 16 若 URL 为 V2 格式（含 `app/ones/space/`），命令会中止并提示使用 `ones2`

---

## 编排原则

1. **先探测可用指令** — 每次触发必先执行 `ones --help`，根据实际输出的子命令列表来编排指令，**不假设命令存在**；对不确定参数的子命令执行 `ones <子命令> --help` 确认
2. **先查后改** — ONES 系统 ID 无法猜测，写操作前必须先查询获取 ID
3. **ID 链式传递** — 前一个命令输出的 ID 作为下一个命令的输入
4. **`--json`** — 需要程序化解析字段值时使用
5. **`-y`** — 批量操作或自动化时跳过确认，避免交互阻塞
6. **`--help`** — 不确定参数时查看帮助
7. **按需加载 reference** — 只在需要时读取，不要一次性全部加载
8. **⛔ 空间权限前置校验** — CLI 在**所有涉及空间的操作（尤其是创建、更新、删除等写操作）开始时**，会立即校验用户是否有目标空间的权限，无权限时直接阻断，不继续执行后续逻辑（如字段校验、界面方案查询等）。Agent 编排时应遵循：
   - **创建工作项**：`wc` 命令在参数解析后、字段校验和界面方案查询之前，会前置调用 `assertSpacePermission` 校验空间权限，无权限直接退出
   - **更新工作项**：`wu` 命令在解析工作项 ID 后，会先查询工作项详情获取所属空间并校验权限，无权限直接退出，不会进入字段校验和预计工作量换算等重操作
   - **查询/删除/迭代/分支等操作**：服务层方法已在调用前校验空间权限
   - 若遇到「无权限操作空间」或「操作被阻断」错误，**不应重试或绕过**，应提示用户：① 确认空间 ID 是否正确（`ones spaces` 查看有权限的空间）；② 联系 ONES 管理员申请加入空间
9. **人员标识使用 MIS 号** — ONES 系统中所有涉及人员的参数（如 `--assigned`、`--operator`、`--users`、`--owner`、`--admins` 等）必须使用用户的 **MIS 号**。MIS 号由用户的中文名称（或英文名称，如海外员工）加上重名数字 ID 组成（如 `zhangsan02`）；如果没有重名则没有后面的数字 ID，就是纯中文或纯英文（如 `zhangsan`、`JohnSmith`）。**不能使用中文姓名或者纯数字id作为参数值**，必须转换为对应的 MIS 号
10. **「与我相关」查询必须带人员筛选** — 当用户描述的意图涉及「自己的工作项」（如「我的需求」、「我在做的任务」、「帮我查查要开发什么」、「我的待办」等），查询条件中**必须**包含当前用户的人员筛选（`--assigned <misId>` 或 DSL 中 `assigned`/`customField24214`(技术主R)/`developer`(开发人员) 等字段）。如果筛选后结果为空，**不要自行扩大搜索范围或去掉人员筛选条件**，而是直接告诉用户「在当前筛选条件（指派给/技术主R/开发人员为您的 MIS）下，未找到匹配的工作项」，让用户自行决定是否调整筛选条件
11. **⛔ 创建工作项必填字段不可跳过** — `ones wc` 创建前会强制校验子类型界面方案的必填字段，缺失任何必填字段都会被阻断（`exit 1`）。Agent 遇到阻断后必须根据 CLI 输出的缺失字段清单补齐所有必填字段，然后重新执行；**禁止绕过校验或忽略缺失字段直接调用后端接口**。如果是交互式场景，应将缺失字段列表展示给用户并询问对应的值
12. **字段取值规则** — 创建/更新工作项通过 `-F` 传入自定义字段时：① 下拉字段取 `value` 而非 `displayValue`；② **级联字段（cascader）只能选最末级节点，各层 value 用 `^` 拼接**（如 `"1^2^3"`），CLI 会自动调用 `field-options` 接口获取可选值树，**校验传入的值是否在可选值范围内且为末级节点**，不合法时会阻断并列出当前层级的合法可选值；③ 组织类字段（`component_new_org`）需用户提供完整部门链（可从**大象个人名片**中查找，如：美团/行政/行政BP中心），通过 `getOrgByPath` 接口获取组织 ID 后填入。详见 [写操作参数 - 字段取值规则](./references/interactive-params.md)
13. **字段全局唯一** — ONES 中的字段 variable（如 `customField24214`、`developer`）**全局唯一、所有空间通用**，不因空间不同而变化。常用人员角色字段：产品主R=`customField13161`、技术主R=`customField24214`、测试主R=`customField24215`、开发人员=`developer`，这些可直接使用无需查询。人员组件类型统一为 `component_user`

---

## 常见问题速查

| 问题 | 解决 |
|------|------|
| `command not found: ones` | `npm i -g @ee/ones-cli --registry=http://r.npm.sankuai.com` |
| 401 / 认证失败 | 按顺序尝试：① `ones sso login --catclaw --mis <MIS>` → ② `ones sso refresh` → ③ `ones sso login --ciba --mis <MIS> --force` → ④ `ones sso login --browser --force` → ⑤ 提示用户 `ones sso login --manual`；CI/CD 场景确认 `ONES_ACCESS_TOKEN` 已设置，详见 [认证指南](./references/auth-guide.md) |
| 无权限操作该空间 / 操作被阻断 | CLI 在操作开始时前置校验空间权限，无权限直接阻断。确认空间 ID 是否正确（`ones sp -n "关键词"` 查看自己有权限的空间）；若空间正确则联系 ONES 管理员申请加入。**不要重试或绕过** |
| 不知道空间 ID | `ones sp -n "关键词"` 搜索，或使用 `ones up -u <URL>` 从 ONES URL 中自动解析 |
| 收到 ONES 链接想知道是什么 | `ones up -u "<链接"` 解析出空间 ID / 工作项 ID / 类型，然后用 `ones workitem-detail -i <ID>` 查详情 |
| 不知道命令参数 | `ones <命令> --help`，或读取 [命令速查](./references/command-reference.md) |
| 删除不可恢复 | 所有 delete 操作不可撤销，务必先确认 |
| 子类型更新报错 | 子类型只能更新为相同工作项类型下的合法子类型 |
| 工时记录 ID 怎么获取 | `ones wtd -i <工作项ID>` 查询工时日志 |
| 工时校验不通过 | 检查空间是否要求填写投入类型，或日期是否在允许范围内 |

---

## References

按需加载，不要一次性全部读取：

| 文件 | 加载时机 |
|------|---------|
| [命令参数速查](./references/command-reference.md) | 速查表不够详细时 |
| [写操作参数](./references/interactive-params.md) | 创建/更新/删除前确认必填参数 |
| [认证排错](./references/auth-guide.md) | 401、Token 过期、登录失败、环境变量 / CatPaw 降级认证 |
| [DSL 筛选指南](./references/filter-query-dsl.md) | 使用 `ones fi` 构建复杂筛选；「与我相关查询」规则（策略 5） |
| [完整 Case 示例](./references/case-examples.md) | 上方精简索引不够详细时，查看完整的多步骤编排示例 |

**外部资源：** [ONES 系统](https://ones.sankuai.com) · [CIBA 认证文档](https://km.sankuai.com/collabpage/2732221228) · [内部 npm 源](http://r.npm.sankuai.com)
