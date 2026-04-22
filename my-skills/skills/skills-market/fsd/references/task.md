# 任务排期参考手册

> **排期时间禁止自动填充**：用户没有明确说出具体日期时，助手禁止自行生成任何时间值。必须将排期阶段展示给用户并等待回复。
>
> **直接传日期字符串，禁止自行计算时间戳**：`--start-time` / `--end-time` / `--schedule` 均支持日期字符串（如 `2026-03-01`、`3.1`、`3/1`），CLI 内部自动转换（开始取 00:00:00，结束取 23:59:59，本地时区）。**助手不需要也不应该手动计算毫秒时间戳。**
>
> **用户未给年份时默认当年。**
>
> **创建成功后必须展示超链接**：以 `[任务链接](https://fsd.sankuai.com/ones/task/detail/{id})` 格式展示。

---

## createTask 接口

创建任务。`POST /api/qa/v1/reqTaskSkill/createTask`

### CLI 参数

**可直接执行 `fsd task create`（参数均可选）。** 缺必填信息时 CLI 打印候选表后退出，需补齐后重试。

| 参数 | 说明 |
|------|------|
| `--task-type <type>` | 任务类型（支持英文 key/中文名/别名，不传则根据用户角色自动判断） |
| `-r, --req-id <reqId>` | 父需求 ID（developOnline/qaOnline/product/design 必需） |
| `-p, --project-id <id>` | ONES 空间 ID（有 -r 时优先从需求带出） |
| `-n, --name <name>` | 任务名称（不传则自动生成） |
| `-a, --assigned <mis>` | 负责人 MIS（不传则用 SSO） |
| `--start-time <time>` | 排期开始时间，支持日期字符串（如 `2026-03-01`、`3.1`）或毫秒时间戳。**推荐用日期字符串**，CLI 自动取 00:00:00 |
| `--end-time <time>` | 排期结束时间，支持日期字符串（如 `2026-03-02`、`3.2`）或毫秒时间戳。CLI 自动取 23:59:59 |
| `--schedule <json>` | 多阶段排期 JSON，值支持日期字符串，如 `{"techDesign":["2026-03-01","2026-03-02"]}` |
| `--module-name <name>` | 模块名称 |
| `--expect-time <pd>` | 预计工时（人天） |
| `--bind-branch` | 创建成功后绑定当前 Git 分支 |
| `-v, --verbose` | 输出完整 JSON |

### 任务类型

| 英文 key | 中文名 | 别名 |
|----------|--------|------|
| developOnline | 开发任务 | 开发 |
| qaOnline | 测试任务 | 测试、QA |
| product | 产品任务 | 产品、PM |
| design | 设计任务 | 设计、UI、UX |
| algorithm | 算法任务 | 算法 |
| default | 默认任务 | 默认 |

> **注意："默认任务"是一个正式的任务类型（key=default），不等于"不指定类型"。**
> - 用户说"创建**默认任务**" → 必须传 `--task-type default`
> - 用户说"创建一个任务"（未提及任何类型名） → 不传 `--task-type`，由 CLI 按角色自动判断

### 决策树

```
用户说「创建任务」
  ↓
步骤1：提取用户已给的参数，拼到命令中执行 fsd task create
  ⚠ 用户话语中包含任务类型表中的任何中文名或别名 → 必须加 --task-type
    例："创建一个开发任务" → fsd task create --task-type developOnline
    例："帮我建测试任务"   → fsd task create --task-type qaOnline
    例："创建产品任务"     → fsd task create --task-type product
    例："创建设计任务"     → fsd task create --task-type design
    例："创建算法任务"     → fsd task create --task-type algorithm
    例："创建默认任务"     → fsd task create --task-type default  ← "默认任务"是类型名！
    ⚠ 用户只说"创建一个任务"（话语中无任何类型名/别名）→ 不传 --task-type，由 CLI 按角色自动判断
  ↓
步骤2：CLI 返回缺失信息（需求/空间/排期阶段）
  ↓
步骤3：助手**原样转述** CLI 输出的所有缺失信息（禁止自行编造、禁止省略行）
  → CLI 输出的排期阶段表必须完整展示每一行，不得重新格式化或丢弃任何阶段
  → 等待用户一次性提供所有信息，部分信息不足时追问
  ↓
步骤4：用户给齐后，拼上所有参数重新执行 fsd task create
  ↓
步骤5：创建成功 → 以 [任务链接](URL) 格式展示
```

> **⚠️ 绝对禁止：不执行 CLI 就自行编造排期阶段名称 ⚠️**
>
> 不同任务类型（开发/测试/产品/设计/算法）的排期阶段完全不同。
> 助手**必须先执行 `fsd task create`**，以 CLI 输出的阶段为准。
> 例如测试任务的阶段是"测试准备"和"测试执行"，而不是"测试"和"灰度&上线"。
> **任何未经 CLI 确认的阶段名称都是错误的。**
>
> **⚠️ 禁止省略或重新格式化 CLI 输出的排期阶段表 ⚠️**
>
> CLI 输出的排期阶段表**每一行都必须展示**，不得丢弃、合并或重排。
> 例如开发任务 CLI 会列出全部必填排期阶段（技术方案设计、开发、灰度&上线、预发），必须展示完整、不得丢行。

### 排期时间约束

1. **禁止**助手自行生成任何时间值（包括"今天"、"一周后"等）
2. CLI 输出排期阶段时，助手**必须原样列出 CLI 给出的阶段名称**，询问具体时间后等待回复
3. 用户明确说出日期后，**直接将日期字符串传给 CLI**（如 `--start-time 2026-03-01 --end-time 2026-03-02`），CLI 自动处理时区和时间点。**禁止助手自行计算毫秒时间戳**
4. 用户给出的日期**没有年份**时，**默认当年**，CLI 支持短格式（如 `3.1`、`3/1`、`3-1`）
5. 用户只给了部分信息时，**必须追问**缺失部分，不能只带部分参数执行

### 排期阶段配置

| 任务类型          | 阶段字段              | 中文名    | 用户常见说法（别名）      | 必填 |
|---------------|-------------------|--------|-----------------|----|
| developOnline | techDesign        | 技术方案设计 | 技术方案、方案设计、技术设计  | 是  |
| developOnline | rdStartEndTime    | 开发     | 开发排期、研发         | 是  |
| developOnline | grayAndOnline     | 灰度&上线  | 上线、灰度、上线排期、灰度上线 | 是  |
| developOnline | selfTest          | 自测联调   | 自测、联调           | 否  |
| developOnline | testApplyTime     | 提测日期   | 提测              | 否  |
| developOnline | stagingDeploy     | 预发     | 备机、预发部署         | 否  |
| qaOnline      | qaDesign          | 测试准备   | 测试准备排期          | 是  |
| qaOnline      | qaTest            | 测试执行   | 测试、测试排期、执行      | 是  |
| qaOnline      | stagingValidation | 备机验证   | 备机、备机测试         | 否  |
| qaOnline      | onlineCheck       | 上线验证   | 上线验证、线上验证       | 否  |
| product       | requirementDesign | 产品排期   | 产品              | 是  |
| design        | designSchedule    | 设计排期   | 设计              | 是  |
| algorithm     | researchDesign    | 调研设计   | 调研、算法排期         | 是  |
| default       | rdStartEndTime    | 排期时间   | 排期              | 否  |

> **用户回复排期时，助手必须将用户的说法模糊匹配到上表的中文名或别名，映射到正确的阶段字段。**
> 例如：用户说"上线排期 3/1-3/2" → 匹配到"灰度&上线"（grayAndOnline）；用户说"技术方案 3/1-3/2" → 匹配到"技术方案设计"（techDesign）。
> 如果用户的说法无法匹配到任何阶段，**必须追问**，不得忽略。
>
> 多个必填阶段时，至少填写一个即可。`--start-time`/`--end-time` 只传一对时间，自动写入第一个必填阶段。产品/设计任务给了时间段未给工作量时自动按工作日计算 PD。

### 响应

成功返回 `data` = 任务 ID（Integer）。

---

## updateTask 接口

修改任务属性。`PUT /api/qa/v1/reqTaskSkill/updateTask`

### CLI 参数

| 参数 | 说明 |
|------|------|
| `-i, --id <issueId>` | 必填，任务 ID |
| `-n, --name <name>` | 快捷：修改名称 |
| `--priority <n>` | 快捷：优先级（1-低, 2-中, 3-高, 4-紧急） |
| `-a, --assigned <mis>` | 快捷：负责人 MIS |
| `--data <json>` | 其他字段以 JSON 传入 |
| `-v, --verbose` | 输出完整 JSON |

快捷参数与 `--data` 可混用，快捷参数优先。**字段名使用 ONES 原生字段名。**

### --data 常用字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| description | String | 任务描述（HTML） |
| cc | List\<String\> | 抄送人 MIS |
| tester | String | 测试人员 MIS |
| developer | String | 开发人员 MIS |
| expectStart | Long | 预计开始（毫秒，取 00:00:00） |
| expectClose | Long | 预计结束（毫秒，取 23:59:59） |
| expectTime | Double | 预计工作量（人天），清空传 `0` |
| parentId | Integer | 父需求 ID |
| iterationId | Long | 迭代 ID，`-1` 清空 |
| customField14076 | String | 研发负责人（rdMaster） |
| customField12144 | String | 测试负责人（qaMaster） |

> 也可传任意 `customField*` 字段，取决于 ONES 空间配置。

---

## deleteTask 接口

删除任务。`DELETE /api/qa/v1/reqTaskSkill/deleteOnes`

| 参数 | 说明 |
|------|------|
| `-i, --id <issueId>` | 必填，任务 ID |

---

## editTaskSchedule 接口

修改任务排期时间。`POST /api/qa/v1/reqTaskSkill/editTaskSchedule`

### CLI 参数

| 参数 | 说明 |
|------|------|
| `-i, --id <issueId>` | 必填，任务 ID |
| `--task-type <type>` | 任务类型（不传则使用已有类型） |
| `--start-time <ts>` | 排期开始时间（毫秒时间戳） |
| `--end-time <ts>` | 排期结束时间（毫秒时间戳） |
| `--schedule <json>` | 多阶段排期 JSON |
| `--clear <fields>` | 清空指定阶段（逗号分隔阶段名） |
| `-v, --verbose` | 输出完整 JSON |

### 决策树

```
用户说「修改排期」
├─ 用户给了时间 → 开始取 00:00:00，结束取 23:59:59，转毫秒时间戳拼参数
├─ 用户没给时间 → CLI 列排期阶段后退出 → 助手展示给用户并等待
└─ 用户要清空 → --clear <阶段名>
```

排期时间约束同创建任务，禁止助手自行编造时间。

### 失败场景

| 场景 | msg |
|------|-----|
| 排期记录不存在 | `任务对应的排期id不能为空` |
| 排期被删除 | `排期id不存在，请刷新后重试` |

---

## queryTaskDetail 接口

查询任务详情。`GET /api/qa/v1/reqTaskSkill/queryTaskDetail`

| 参数 | 说明 |
|------|------|
| `-i, --id <taskId>` | 必填，任务 ID |
| `-v, --verbose` | 输出完整 JSON |
| `--pretty` | 人类可读格式输出 |

---

## queryMyTaskList 接口

分页查询我的任务列表。`POST /api/qa/v1/reqTaskSkill/queryMyTaskList`

### CLI 参数

| 参数 | 说明 |
|------|------|
| `--page <n>` | 页码（默认 1） |
| `--size <n>` | 每页大小（默认 20） |
| `-n, --name <keyword>` | 任务名称关键词 |
| `-s, --status <status>` | 状态过滤（逗号分隔） |
| `--subtype <type>` | 任务类型过滤（支持中文/英文/别名） |
| `--assigned <mis>` | 负责人 MIS |
| `--created-by <mis>` | 创建人 MIS |
| `-p, --project-id <id>` | 空间 ID |
| `-r, --req-id <reqId>` | 父需求 ID |
| `--schedule-range <range>` | **排期时间筛选（推荐）**：`today`/`this-week`/`next-week`/`YYYY-MM-DD`/`YYYY-MM-DD~YYYY-MM-DD` |
| `--pretty` | 表格格式输出 |

> **排期筛选（重要）：** 用户说"查今天/本周/某天有排期的任务"时，**必须使用 `--schedule-range`**，禁止先拉全量再手动过滤。

> **类型 vs 状态（易混淆）：** `--subtype` 是分类（开发任务/测试任务），`-s` 是进度（待处理/进行中）。"查进行中的测试任务" → `-s 进行中 --subtype 测试任务`。

---

## queryNextStages / changeStage 接口

流程与 [req.md · changeStage](req.md#querynextstages--changestage-接口) 完全一致，仅 `onesType` 固定为 `DEVTASK`。

| 参数 | 说明 |
|------|------|
| `-i, --id <issueId>` | 必填，任务 ID |
| `--to <targetState>` | 目标状态名称（不传则展示可流转列表） |
| `--form <json>` | 表单字段 JSON（`{"restIssue":{"field":"val"}}`） |
| `-v, --verbose` | 输出完整 JSON |

---

## createBranchV2 / branchBindOnes 接口

### fsd task create-branch

创建分支。`GET /api/qa/v1/deploy/createBranchV2`

| 参数 | 说明 |
|------|------|
| `-b, --branch <name>` | 必填，目标分支名称 |
| `-f, --from <branch>` | 迁出分支（默认 master） |
| `-j, --job-name <name>` | 服务名称（默认从 Git 推导） |
| `-i, --id <issueId>` | 关联工作项 ID（自动绑定） |

### fsd task bind-branch

分支绑定任务。`GET /api/qa/v1/branch/baseBranch/branchBindOnes`

| 参数 | 说明 |
|------|------|
| `-i, --id <onesId>` | 必填，任务 ID |
| `-b, --branch <name>` | 分支名称（默认当前分支） |
| `-g, --git <url>` | Git 仓库地址（默认当前工程） |
| `-j, --job-name <name>` | 服务名称 |

> 在 Git 仓库目录下执行时，`-b` 和 `-g` 自动获取，只需传 `-i`。

---

## 错误处理

| 错误类型 | 建议 |
|----------|------|
| taskType 为空 | 指定 --task-type |
| 缺少父需求 | developOnline/qaOnline/product/design 须传 -r |
| 无法获取空间 | 传 -p 或确保 -r 对应的需求存在 |
| 目标状态不可达 | 检查 --to 是否与 nextStateName 一致 |
| 401/403 | 确认 API Key 有效 |
| 返回格式异常 / 超时 | 联系管理员或稍后重试 |

---

## 使用示例

### 示例1：创建任务

```bash
# 开发任务（关联需求）
fsd task create -p 48364 -n "开发登录模块" --task-type developOnline -r 90689902

# 测试任务
fsd task create --task-type 测试 -r 90689902

# 默认任务（无需关联需求）
fsd task create --task-type 默认
```

### 示例2：创建任务（带排期）

```bash
# 简单模式（填入第一个排期阶段）
fsd task create --task-type qaOnline -r 93990227 --start-time 2026-04-01 --end-time 2026-04-05

# 多阶段模式
fsd task create --task-type 开发 -r 90689902 --schedule '{"techDesign":["2026-04-03","2026-04-05"],"rdStartEndTime":["2026-04-06","2026-04-16"]}'

# 短日期格式（省略年份，默认当年）
fsd task create --task-type qaOnline -r 93990227 --start-time 4.1 --end-time 4.5
```

### 示例3：查询任务列表

```bash
# 全部任务
fsd task list --pretty

# 进行中的测试任务
fsd task list -s "进行中" --subtype 测试任务 --pretty

# 按排期时间筛选
fsd task list --schedule-range today --pretty
fsd task list --schedule-range this-week --pretty
fsd task list --schedule-range 2026-03-25~2026-03-30 --pretty
```

### 示例4：查询任务详情

```bash
fsd task detail -i 12345678 --pretty
```

### 示例5：修改任务

```bash
# 快捷字段
fsd task update -i 93972200 -n "接口联调V2" --priority 4 -a zhangsan

# 通过 --data 修改其他字段
fsd task update -i 93972200 --data '{"description":"<p>接口联调</p>","expectTime":3.5}'

# 研发/测试负责人
fsd task update -i 93972200 --data '{"customField14076":"lisi","customField12144":"wangwu"}'

# 混合使用
fsd task update -i 93972200 -n "支付重构" --priority 3 --data '{"cc":["lisi","wangwu"]}'

# 时间字段（开始取 00:00:00，结束取 23:59:59）
fsd task update -i 93972200 --data '{"expectStart":1774972800000,"expectClose":1776268799000}'
# 2026-04-01 00:00:00 ~ 2026-04-15 23:59:59
```

### 示例6：删除任务

```bash
fsd task delete -i 93972200
```

### 示例7：修改排期

```bash
# 单阶段（技术方案设计 4/1~4/5）
fsd task edit-schedule -i 93972200 --task-type developOnline --start-time 2026-04-01 --end-time 2026-04-05

# 多阶段
fsd task edit-schedule -i 93972200 --task-type developOnline --schedule '{"techDesign":["2026-04-01","2026-04-05"],"rdStartEndTime":["2026-04-05","2026-04-15"]}'

# 清空排期
fsd task edit-schedule -i 93972200 --task-type developOnline --clear techDesign,rdStartEndTime
```

### 示例8：流转任务状态

```bash
# 查看可流转状态
fsd task stage -i 93972200

# 流转到进行中（带自定义日期字段）
now=$(date +%s)000
fsd task stage -i 789012 --to "进行中" --form '{"restIssue":{"customField17159":"'$now'","customField17160":"'$now'"}}'
```

### 示例9：分支操作

```bash
# 创建分支
fsd task create-branch -b feature/login
fsd task create-branch -b feature/login -i 93972182

# 绑定分支到任务（Git 仓库下执行）
fsd task bind-branch -i 93972182
fsd task bind-branch -i 93972182 -b feature/login
```
