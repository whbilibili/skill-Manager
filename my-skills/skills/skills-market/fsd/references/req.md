# 需求管理参考手册

> 所有操作遵循 SKILL.md 核心规则。创建成功后必须以 `[需求链接](URL)` 格式展示。

---

## createRequirement 接口

创建需求。`POST /api/qa/v1/reqTaskSkill/createRequirement`

### CLI 参数

**所有参数均为可选，直接执行 `fsd req create` 即可，CLI 自动处理缺失参数。**

| 参数 | 说明 |
|------|------|
| `-p, --project-id <id>` | ONES 空间 ID（不传则用最近空间） |
| `-n, --name <name>` | 需求名称（不传则自动生成 `新需求_yyyy-MM-dd`） |
| `--subtype <subtype>` | 需求子类型：`产品需求`/`产品`(55813)、`技术需求`/`技术`(55826)。不传默认产品需求 |
| `--subtype-id <id>` | 子类型 ID（直接传数字，优先级高于 `--subtype`） |
| `--priority <n>` | 优先级（1-低, 2-中, 3-高, 4-紧急） |
| `-a, --assigned <mis>` | 负责人 MIS |
| `-d, --desc <html>` | 需求描述（HTML） |
| `--req-propose-users <users>` | 逗号分隔 MIS 列表 |
| `-v, --verbose` | 输出完整 JSON |

### 决策树

```
用户说「创建需求」→ 有什么拼什么，直接执行 fsd req create
├─ 给了空间名称 → 先 fsd req project -n <名称> 查到 projectId 再 -p <projectId>（注意：用 projectId 字段，不是 id 字段）
├─ 给了「技术需求」→ --subtype 技术需求
└─ 创建成功 → 以 [需求链接](URL) 格式展示链接
```

**关键规则：禁止追问参数，有什么拼什么，缺的 CLI 自动处理。**

### 响应

成功返回 `data` = 需求 ID（Integer）。链接格式：`https://fsd.sankuai.com/ones/requirement/detail/{id}`

---

## queryReqDetail 接口

查询需求详情。`GET /api/qa/v1/reqTaskSkill/queryReqDetail`

| 参数 | 说明 |
|------|------|
| `-i, --id <reqId>` | 必填，需求 ID |
| `-v, --verbose` | 输出完整 JSON |
| `--pretty` | 人类可读格式输出 |

> 从 ONES 链接中提取需求 ID：`https://ones.sankuai.com/.../detail/123456` → `-i 123456`

---

## getListByIssueId

按 ONES **需求 issueId** 查询关联交付行，并从中汇总 **testPlanId**（去重）。接口：`GET /api/qa/v1/delivery/getListByIssueId?issueId=<ONES 需求 ID>`

与 FSD 需求空间页「交付」抽屉/列表同源。返回 `data.list` 为交付计划行；行内 **`applyProgramId`** 为交付主键（与 `fsd delivery -i`、`testApplyDetail` 一致）；**`testPlanId`** 为该交付当前绑定的测试计划 ID，可为 `null`。  
**`testPlanIds` 汇总规则**：对 `list` 中所有非空 `testPlanId` 去重、升序，**不等于**「该需求下全部测试计划」的独立枚举接口，仅反映交付行上的绑定关系。

### CLI

| 命令 | 说明 |
|------|------|
| `fsd req relate -i <issueId>` | 默认输出 JSON：`issueId`、`deliveryCount`、`testPlanIds`、`deliveries`（摘要字段） |
| `fsd req relate -i <issueId> --pretty` | 人类可读表格与 URL 模板行 |
| `fsd req relate -i <issueId> -v` | 完整 `data`（含 `userMessage`、接口原始 `list` 字段） |

### 后续操作

- 交付：`fsd delivery detail -i <applyProgramId>`（`applyProgramId` 与列表 `testApplyId` 同主键，见 [delivery.md](delivery.md)）
- 测试计划：`fsd test detail --id <testPlanId>`（见 [test-plan.md](test-plan.md)）

---

## updateReqInfo 接口

修改需求信息。`POST /api/qa/v1/reqTaskSkill/updateReqInfo`

### CLI 参数

| 参数 | 说明 |
|------|------|
| `-i, --id <reqId>` | 必填，需求 ID |
| `-p, --project-id <id>` | ONES 空间 ID（不传则自动从需求详情获取） |
| `-n, --name <name>` | 快捷：修改名称 |
| `--priority <n>` | 快捷：优先级（1-低, 2-中, 3-高, 4-紧急） |
| `-a, --assigned <mis>` | 快捷：负责人 MIS |
| `-d, --data <json>` | 其他字段（JSON），支持 FSD 字段名和 ONES 原生字段名 |

快捷字段与 `-d` 可同时使用。`-d` 中同名键覆盖快捷字段。

### 决策树

```
用户说「修改需求」
├─ 需求ID（必填）→ -i <id>，无则必须追问
├─ 快捷字段：名称 -n、优先级 --priority、负责人 -a
└─ 其他字段通过 -d JSON 传入
```

### -d 常用字段映射

| FSD 字段名 | ONES 字段 | 类型 | 说明 |
|------------|-----------|------|------|
| projectId | projectId | Integer | 目标空间 ID（移动需求到新空间） |
| name | name | String | 名称 |
| subtypeId | subtypeId | Integer | 需求子类型 ID（55813=产品需求, 55826=技术需求） |
| desc | desc | String | 描述（HTML） |
| priority | priority | Integer | 优先级 |
| assigned | assigned | String | 负责人 MIS |
| rdMaster | customField14076 | String | 研发负责人 |
| qaMaster | customField12144 | String | 测试负责人 |
| uiMainR | customField22430 | String | UI 负责人 |
| reqProposeUsers | customField12738 | List\<String\> | 提出人（联动提出部门） |
| expectedOnlineTime | customField13200 | Long | 预计上线（毫秒时间戳） |
| label | labels | List | 标签 |
| iterationId | iterationId | Long | 迭代 ID（`-1` 清空） |
| tgId | customField24725 | List\<Long\> | 团队目标（`-1` 不关联） |

> 未在映射表中的字段名会原样透传给 ONES 接口。也可直接传 `customField*` 字段。
> 时间字段传毫秒时间戳；列表类型传数组。推荐 `-d` 整段用单引号：`-d '{"rdMaster":"zhangsan"}'`

---

## deleteOnes 接口

删除需求。`DELETE /api/qa/v1/reqTaskSkill/deleteOnes`

| 参数 | 说明 |
|------|------|
| `-i, --id <issueId>` | 必填，需求 ID |

---

## queryProjectByName 接口

按空间名称精确查询。`GET /api/qa/v1/reqTaskSkill/queryProjectByName`

| 参数 | 说明 |
|------|------|
| `-n, --name <name>` | 必填，空间名称（精确匹配） |
| `--pretty` | 人类可读格式 |

---

## queryMyReqList 接口

分页查询我的需求列表。`POST /api/qa/v1/reqTaskSkill/queryMyReqList`

### CLI 参数

| 参数 | 说明 |
|------|------|
| `--page <n>` | 页码（默认 1） |
| `--size <n>` | 每页大小（默认 20） |
| `-p, --project-id <id>` | 空间 ID |
| `-s, --status <status>` | 状态过滤（逗号分隔）。快捷词：`未上线`、`进行中`、`未开始`、`已完结`；也可直接传精确状态如 `开发中,测试中` |
| `--subtype <type>` | 需求类型（逗号分隔）：`产品需求`/`产品`、`技术需求`/`技术`、`默认任务`/`默认`、`管理事项`/`管理`、`其他` |
| `-n, --name <keyword>` | 名称关键词 |
| `--assigned <mis>` | 负责人 MIS |
| `--created-by <mis>` | 创建人 MIS |
| `--start-time <datetime>` | 创建时间起始（yyyy-MM-dd HH:mm:ss） |
| `--end-time <datetime>` | 创建时间结束 |
| `--priority <n>` | 优先级过滤（逗号分隔数字） |
| `--pretty` | 表格格式输出 |

---

## queryMyReqPd 接口

查询**当前用户**在时间段内、按天的需求 PD（工时）片段。`POST /api/qa/v1/reqTaskSkill/queryMyReqPd`（请求/响应字段见仓库根目录 `reference.md`）。

### CLI 参数（`fsd req pd`）

| 参数 | 说明 |
|------|------|
| `--start <ms>` | 开始时间（毫秒时间戳）；与 `--end` **须成对**，否则默认**本周一至周日**（本地时区） |
| `--end <ms>` | 结束时间（毫秒时间戳） |
| `--subtype <list>` | 需求子类型（逗号分隔，规则同 `fsd req list`）→ `onesSubTypeList` |
| `-s, --status <list>` | 需求状态（逗号分隔，快捷词/精确状态同 list）→ `reqStatusList` |
| `--priority <list>` | 优先级（逗号分隔 1～4）→ `priorityList` |
| `-p, --project-id <ids>` | 空间 ID（逗号分隔）→ `projectIdList` |
| `-n, --name <keyword>` | 需求名称包含匹配 → `reqName` |
| `-v, --verbose` | 输出完整 JSON |
| `--pretty` | 按日期分组、当日小计、条形图 + 需求列 |

---

## reqScheduleTeamGantt 接口

按部门与时间范围查询用户排期甘特数据（需求维度）。`POST /api/qa/v1/reqTaskSkill/reqScheduleTeamGantt`（与 `reference.md` 接口说明一致）。

### CLI 参数（`fsd req schedule`）

| 参数 | 说明 |
|------|------|
| （组织） | **固定**取当前登录用户 `getCurrentUserInfo` 的 `orgId`，**不可在 CLI 指定** |
| `--start <ms>` | 开始时间（**毫秒时间戳**）；与 `--end` **须成对**传入，否则使用默认时间范围 |
| `--end <ms>` | 结束时间（毫秒时间戳） |
| （默认时间） | 未传 `--start`/`--end` 时：当前自然周 **周一 00:00:00.000 ～ 周日 23:59:59.999**（本地时区） |
| `--page <n>` | 页码（默认 1） |
| `--size <n>` | 每页大小（默认 20） |
| `--mis <list>` | 用户 MIS 过滤（逗号分隔，模糊匹配）→ 请求体 `mis` |
| `--subtype <list>` | 需求类型（逗号分隔，规则同 `fsd req list`）→ `onesSubType` |
| `-n, --name <keyword>` | 工作项名称 → `issueName` |
| `--priority <list>` | 优先级（逗号分隔 1～4）→ `priorityList` |
| `-p, --project-id <ids>` | 空间 `projectId`（逗号分隔）→ `projectId` |
| `-v, --verbose` | 输出完整 JSON |
| `--pretty` | 汇总表 + 按人分块；**【需求整体排期】**取 `reqList[].stageList`（`stage`/`stageName` + 排期 + 可选 `durationDay`）；**【任务排期】**优先从 `stageList[].details[]` 展开（`taskDetailId`、`taskPd`、嵌套 `details` 内任务阶段 + 排期）；无则回退 `taskList` |

> 接口层 `orgId`、`startTime`、`endTime` 均为必填；CLI 固定用当前用户 `orgId`，时间默认本周或 `--start`/`--end`。

---

## queryNextStages / changeStage 接口

### queryNextStages

查询可流转的下一状态。`GET /api/qa/v1/reqTaskSkill/queryNextStages`（onesType=`REQUIREMENT`）

### changeStage

变更状态。`PUT /api/qa/v1/reqTaskSkill/changeStage`

### CLI 参数（fsd req stage）

| 参数 | 说明 |
|------|------|
| `-i, --id <issueId>` | 必填，需求 ID |
| `--to <targetState>` | 目标状态名称（不传则仅展示可流转状态列表） |
| `--form <json>` | 表单字段 JSON（格式：`{"restIssue":{"field":"val"}}`） |
| `-v, --verbose` | 输出完整 JSON |

### 自动填充规则

必填字段未通过 `--form` 传入时，按优先级自动填充：defaultValue → valueList 第一项 → possibleValues 第一项 → 人员字段填当前用户 → 时间字段填今天 → 空字符串。`--form` 手动值覆盖自动填充。

---

## branchBindOnes 接口

绑定分支到需求。`GET /api/qa/v1/branch/baseBranch/branchBindOnes`

### CLI 参数（`fsd req bind-branch`）

| 参数 | 说明 |
|------|------|
| `-i, --id <onesId>` | 必填，需求 ID（ONES issueId） |
| `-b, --branch <branch>` | 分支名称；不传则自动取当前 Git 分支 |
| `-g, --git <gitUrl>` | Git 仓库地址；不传则自动取当前工程远程地址 |
| `-j, --job-name <jobName>` | 服务名称；当无法自动识别 Git 时可显式指定 |
| `-u, --user-name <mis>` | 执行人 MIS；默认取当前登录用户 |

### 执行规则

1. 先查询需求详情并校验权限，仅需求创建人或负责人允许绑定。
2. `branch` 缺省时自动取当前分支；如果当前分支是 `master`，直接报错，避免误绑保护分支。
3. `git` 缺省时自动取当前仓库 `remote.origin.url`；若拿不到，则必须显式传 `-g` 或至少传 `-j`。

### 示例

```bash
fsd req bind-branch -i 123456 -b feature/abc
fsd req bind-branch -i 123456
fsd req bind-branch -i 123456 -g ssh://git@git.sankuai.com/group/repo.git -b feature/abc
```

---

## 错误处理

| 错误类型 | 建议 |
|----------|------|
| 401/403 | 确认 API Key 有效 |
| code !== 0 | 检查 projectId、必填字段、reqId 是否正确 |
| 目标状态不可达 | 检查 --to 是否与 nextStateName 一致 |
| 返回格式异常 / 超时 | 联系管理员或稍后重试 |

---

## 使用示例

### 示例1：创建需求

```bash
# 基本创建
fsd req create -p 48364 -n "测试创建需求"

# 技术需求 + 优先级 + 负责人
fsd req create -p 48364 -n "测试创建需求" --subtype "技术需求" --priority 3 -a zhangsan
```

### 示例2：查询需求详情

```bash
fsd req detail -i 123456 --pretty
```

### 示例3：查询需求列表

```bash
# 全部
fsd req list --pretty

# 按状态
fsd req list -s "进行中" --pretty
fsd req list -s "未上线" --pretty
fsd req list -s "进行中,排期完成" --pretty

# 按类型
fsd req list --subtype "技术需求" --pretty
fsd req list --subtype "产品需求,技术需求" --pretty

# 按空间 + 关键词
fsd req list -p 49536 -n "登录" --pretty
```

### 示例4：需求工时（pd）

```bash
fsd req pd --pretty
fsd req pd --start 1711843200000 --end 1711929599999 --pretty
fsd req pd -s 进行中 --subtype 0 -n 登录 -p 10001 --priority 1 --pretty
```

### 示例5：团队需求排期（schedule）

```bash
# 默认：当前组织 + 本周 + 表格与每需求/每任务阶段排期
fsd req schedule --pretty

# 自定义时间范围（毫秒时间戳）
fsd req schedule --start 1704067200000 --end 1735689599000 --pretty

# 过滤：用户、类型、名称、优先级、多空间
fsd req schedule --mis zhangsan,lisi --subtype 0,2 -n 登录 --priority 3,4 -p 3550,3551 --pretty

# 分页
fsd req schedule --page 1 --size 50 --pretty
```

### 示例6：查询空间后创建需求

```bash
fsd req project -n "验证核心本地商业BG空间2024"
# 拿到输出中的 projectId（注意：不是 id 字段）
fsd req create -p <projectId> -n "测试需求"
```

### 示例7：修改需求

```bash
# 快捷字段
fsd req update -i 93972182 -n "用户登录优化" --priority 4 -a zhangsan

# 研发/测试负责人（通过 -d JSON）
fsd req update -i 93972182 -d '{"rdMaster":"lisi","qaMaster":"wangwu"}'

# 混合使用
fsd req update -i 93972182 -n "登录优化V2" --priority 3 -d '{"rdMaster":"zhangsan","expectedOnlineTime":1775145600000}'

# 列表类型字段
fsd req update -i 93972182 -d '{"reqProposeUsers":["zhangsan","lisi"]}'
```

### 示例8：删除需求

```bash
fsd req delete -i 93972182
```

### 示例9：按需求 issueId 查关联交付与测试计划 ID

```bash
fsd req relate -i 93991606
fsd req relate -i 93991606 --pretty
```

### 示例10：流转需求状态

```bash
# 仅查看可流转状态
fsd req stage -i 93941845

# 流转到已上线（带自定义日期字段）
now=$(date +%s)000
fsd req stage -i 93941845 --to "已上线" --form '{"restIssue":{"customField17159":"'$now'","customField17160":"'$now'"}}'
```
