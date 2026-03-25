---
name: ee-ones
description: "ONES 研发管理助手，通过 `ones` 命令行操作美团 ONES 系统（ones.sankuai.com）。覆盖：工作项管理（查询/创建/更新/删除需求、任务、缺陷、详情、评论、父子关联）、工时管理（查询工时、填写工时、工时汇总、修改工时、补填工时）、分支管理（生成分支名、创建分支、关联分支、搜索分支）、迭代管理（查询迭代、创建迭代）、测试管理（测试用例、测试计划、测试轮次）、提测、空间查询、字段查询、界面方案查询、DSL 筛选。当用户提到以下内容时使用本 skill：查需求、查任务、查缺陷、有哪些 bug、我的待办、帮我填工时、今天工作量、本周工时汇总、建个分支、查迭代进度、创建测试计划、帮我提测、查一下空间、查字段、ones.sankuai.com 链接、本周开发的工作项、今天开发的需求、当月预计开发、本周预计上线。"
version: 2.2.14
tag: [ONES, 工作项, 需求, 任务, 缺陷, bug, 分支, 迭代, 测试, 工时, 工作量, 提测, 空间, 字段, 筛选, 待办, 评论, 关联, 用例, 轮次, 开发进展, 上线, 时间范围, 预计开发]
---

# ONES CLI 助手

通过 `ones` 命令行管理美团 ONES（ones.sankuai.com）系统的工作项、工时、分支、迭代、测试等。

本 Skill 采用渐进式加载：SKILL.md 包含路由、速查和 Case 示例，已覆盖绝大多数场景；只在需要详细参数、写操作确认或排查认证问题时，才按需读取 `references/` 下的文件。

---

## 文件结构与加载策略

```
ee-ones/
├── SKILL.md                     ← 路由 + 速查 + Case 示例（当前文件）
└── references/
    ├── command-reference.md     ← 查具体参数时加载
    ├── interactive-params.md    ← 执行创建/更新/删除时加载
    ├── auth-guide.md            ← 遇到认证问题时加载
    └── filter-query-dsl.md      ← 使用 fi 命令构建 DSL 时加载
```

| 层级 | 内容 | 加载时机 |
|------|------|---------|
| 元数据 | description + tag | 始终在上下文 |
| SKILL.md 正文 | 速查表 + Case 示例 + FAQ | Skill 触发时 |
| references/ | 完整参数、交互流程、认证指南 | 按需读取 |

> 按加载时机拆分而非按实体拆分，因为 Case 示例已串联多个实体的命令，Agent 只需在「查参数」「写操作」「排错」时才额外读取 reference 文件。

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

## Step 1: 版本检查与登录（每次触发必做）

ones-cli 频繁更新，先检查版本可避免参数变更导致的意外失败。

```bash
# 1.1 检查版本是否最新
ones --version
npm view @ee/ones-cli version --registry=http://r.npm.sankuai.com
# 版本不一致 → npm install -g @ee/ones-cli --registry=http://r.npm.sankuai.com

# 1.2 检查登录状态，未登录则执行 CIBA 登录
ones sso status
ones sso login --ciba    # 在大象 App 确认
# Token 过期 → ones sso refresh
```

> SSO Token 8h 有效，ONES FE Token 自动换票缓存 2h。遇到认证问题读取 [认证指南](./references/auth-guide.md)。

---

## Step 2: 根据用户意图选择命令

根据自然语言描述匹配下方速查表中的命令。写操作需确认参数时读取 [写操作参数](./references/interactive-params.md)，查完整参数时读取 [命令速查](./references/command-reference.md)。

---

## 命令速查表

所有命令前缀 `ones`，支持 `--json` 输出和 `--help` 查看帮助。

### 基础

| 别名 | 命令 | 用途 |
|------|------|------|
| - | `sso login --ciba` | CIBA 登录 |
| - | `sso status` | 查看登录状态 |
| - | `sso refresh` | 刷新 Token |
| - | `sso logout` | 登出 |
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
| `wtu` | `worktime-update --id <记录ID>` | 修改工时 |
| `wtdel` | `worktime-delete --id <记录ID>` | 删除工时 |

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

---

## 指令编排模式（Case 示例）

以下示例展示如何组合多个命令完成复杂任务。核心思路：先查后改，前一个命令的输出 ID 作为下一个命令的输入。

### Case 1: 「查看我这周的工时情况并补填」

**User input content:**
```text
帮我看看这周工时填了没，没填的帮我补上
```

```bash
# 1. 查本周汇总，找出缺填日期
ones wts
# 2. 搜索可填工时的工作项
ones wtsearch -n "关键词"
# 3. 对缺填日期逐天填写（ID 来自步骤 2）
ones wtadd -i <工作项ID> --hours 8h -d 2026-03-10
ones wtadd -i <工作项ID> --hours 8h -d 2026-03-11
```

### Case 2: 「为需求创建分支并开始开发」

**User input content:**
```text
帮我给需求 93833807 建个分支
```

```bash
# 1. 获取工作项详情（含空间 ID）
ones workitem-detail -i <工作项ID> --json
# 2. 生成分支名
ones bg -i <工作项ID> --copy
# 3. 创建分支并关联工作项
ones bc -i <工作项ID>
# 4. 本地 checkout（分支名来自步骤 2）
git checkout -b <分支名>
```

### Case 3: 「创建需求并安排到迭代」

**User input content:**
```text
在商品中心空间新建一个高优需求"优化搜索性能"，放到 Sprint 26 迭代里
```

```bash
# 1. 查找空间
ones sp -n "商品中心"
# 2. 查询子类型（获取 subtypeId）
ones vs -p <空间ID> -s <子类型ID>
# 3. 创建工作项
ones wc -t REQUIREMENT -p <空间ID> -s <子类型ID> --priority 高 --title "优化搜索性能" -y
# 4. 查找迭代
ones iter -p <空间ID> -n "Sprint 26"
# 5. 将工作项指派到迭代（ID 来自步骤 3、4）
ones si -i <工作项ID> -t <迭代ID>
```

### Case 4: 「查看需求关联的分支和提测状态」

**User input content:**
```text
查一下 93833807 这个需求的分支和提测情况
```

```bash
# 1. 获取工作项详情（含空间 ID）
ones workitem-detail -i 93833807 --json
# 2. 查关联分支
ones branch -p <空间ID> -i 93833807
# 3. 查提测详情
ones st -p <空间ID> -i <提测单ID>
```

### Case 5: 「创建测试计划 → 轮次 → 添加用例 → 执行」

**User input content:**
```text
给需求 93833807 创建一套完整的测试流程
```

```bash
# 1. 创建测试计划
ones plan-c -c REQUIREMENT -p <空间ID> --title "回归测试" --requirement-ids "93833807"
# 2. 创建轮次（计划 ID 来自步骤 1）
ones round-c -p <空间ID> --plan-id <计划ID> -t FUNCTION_TEST --title "功能测试"
# 3. 向轮次添加用例（轮次 ID 来自步骤 2）
ones round-ca -p <空间ID> -r <轮次ID> --plan-id <计划ID> -a ADD
# 4. 标记用例执行结果
ones round-cu -p <空间ID> -r <轮次ID> -s SUCCESS
```

### Case 6: 「修改或删除某个工时记录」

**User input content:**
```text
帮我把那个 93833807 工作项上填的工时改成 4 小时
```

```bash
# 1. 查工时日志，获取记录 ID
ones wtd -i 93833807
# 2. 修改工时（记录 ID 来自步骤 1）
ones wtu --id <记录ID> -i 93833807 --hours 4h
# 或删除
ones wtdel --id <记录ID>
```

### Case 7: 「一周批量填写工时」

**User input content:**
```text
帮我把这周工时都填上,填到"搜索优化"那个项目上
```

```bash
# 1. 搜索工作项
ones wtsearch -n "搜索优化"
# 2. 批量填写（日期范围 + -y 跳过确认，ID 来自步骤 1）
ones wtadd -i <工作项ID> --hours 8h -d 2026-03-10~2026-03-14 -y
```

### Case 8: 「创建工作项（需求/任务/缺陷）完整引导流程」

**User input content:**
```text
帮我创建一个需求
```

按以下 7 步依次执行：

```bash
# 1. 确定空间：让用户提供关键词搜索
ones sp -n "<关键词>"

# 2. 确定类型：询问用户要创建 REQUIREMENT / DEVTASK / BUG

# 3. 查子类型列表（字段ID 不确定时先用 fs 查出）
ones fo -p <spaceId> -f <子类型字段ID> -t component_issue_type -s <workitemType>
ones fs -p <spaceId> -t <workitemType> -n "子类型"   # 如不知字段ID

# 4. 查界面方案，提取 required=true 的必填字段
ones vs -p <spaceId> -s <subtypeId>

# 5. 补全字段元信息（view-scheme 未包含完整类型时）
ones fs -p <spaceId> -t <workitemType> -n "<字段名>"

# 6. 查必填字段可选值（枚举/用户/迭代等类型）
ones fo -p <spaceId> -f <字段ID> -t component_user
ones fo -p <spaceId> -f <字段ID> -t component_iteration -s <workitemType>

# 7. 拼接参数创建（所有 ID 来自前序查询，不可猜测）
ones wc -t <workitemType> -p <spaceId> -s <subtypeId> \
  --title "<标题>" --priority <优先级> --field-values '<必填字段JSON>' -y
```

> 步骤 3 若 `fo` 报错找不到字段 → 先用步骤 5 的 `fs` 查出字段 ID 再重试。步骤 6 只对有限可选值的字段调用 `fo`，自由文本字段直接询问用户。

---

### Case 9: 「查询指定时间范围内开发/上线的工作项」

**User input content:**
```text
帮我查下本周预计开发的需求有哪些
今天我在开发哪些工作项
当月预计上线的需求进展怎么样
```

时间字段值可能为空，不能直接作为筛选条件（会漏项）。正确做法：先宽松拉取，再把时间字段带到 `-f` 展示列，在返回数据中做区间计算。时间字段 variable 全平台统一（`customField13641` 预计开发开始、`customField13642` 预计开发结束、`customField11681` 预计提测、`customField13200` 预计上线），无需查询，直接使用：

```bash
ones fi -p <空间ID> -t REQUIREMENT \
  --assigned <misId> \
  -f "name,state,priority,customField13641,customField13642,customField13200,customField11681" \
  --json
```

拿到结果后，从 JSON 中筛选开发区间与目标时间范围有交集的工作项（开发进展），或对应时间字段落在目标范围内的工作项（上线/提测进展）。

> 详细 DSL 示例及策略参见 [DSL 筛选指南 - 模板 4 & 策略 4](./references/filter-query-dsl.md)。

---

### Case 10: 「查询有延期风险的工作项」

**User input content:**
```text
帮我看看有哪些工作项有延期风险
本迭代有没有开发延期的需求
当前有哪些工作项可能会影响上线
```

先宽松拉取，再按 `stateCategory` 在返回数据中分层判断：`TODO`（开发前）检查所有时间节点；`DOING`（开发中）跳过已无意义的开发开始时间；进入测试/上线阶段后只看提测和上线时间；`DONE` 直接跳过。具体状态名因空间而异，以语义判断为准，不要硬编码。

```bash
# 需求风险（按指派人或迭代）
ones fi -p <空间ID> -t REQUIREMENT \
  --assigned <misId> \
  -f "name,state,stateCategory,priority,customField13641,customField13642,customField11681,customField13200" \
  --json

# 任务风险（expectStart/expectClose 全平台统一）
ones fi -p <空间ID> -t DEVTASK \
  --assigned <misId> \
  -f "name,state,stateCategory,priority,expectStart,expectClose" \
  --json
```

`--json` 输出采用 `TREE_MODE`，顶层需求的 `children` 直接包含子任务，可一次定位"哪个需求下的哪个任务"异常。时间字段为空时跳过该维度的风险判断。

> 详细分层判断规则及 DSL 初筛示例参见 [DSL 筛选指南 - 模板 8](./references/filter-query-dsl.md)。

---

## 编排原则

1. **先查后改** — ONES 系统 ID 无法猜测，写操作前必须先查询获取 ID
2. **ID 链式传递** — 前一个命令输出的 ID 作为下一个命令的输入
3. **`--json`** — 需要程序化解析字段值时使用
4. **`-y`** — 批量操作或自动化时跳过确认，避免交互阻塞
5. **`--help`** — 不确定参数时查看帮助
6. **按需加载 reference** — 只在需要时读取，不要一次性全部加载

---

## 常见问题速查

| 问题 | 解决 |
|------|------|
| `command not found: ones` | `npm i -g @ee/ones-cli --registry=http://r.npm.sankuai.com` |
| 401 / 认证失败 | `ones sso refresh` 或重新 `ones sso login --ciba`，详见 [认证指南](./references/auth-guide.md) |
| 不知道空间 ID | `ones sp -n "关键词"` 搜索，或从 ONES URL `/project/48465/` 提取 |
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
| [认证排错](./references/auth-guide.md) | 401、Token 过期、登录失败 |
| [DSL 筛选指南](./references/filter-query-dsl.md) | 使用 `ones fi` 构建复杂筛选 |

**外部资源：** [ONES 系统](https://ones.sankuai.com) · [CIBA 认证文档](https://km.sankuai.com/collabpage/2732221228) · [内部 npm 源](http://r.npm.sankuai.com)
