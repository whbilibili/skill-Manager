# 测试计划参考手册

**命名：** 英文 `testPlan`（及 `testPlanId` 等）与中文「测试计划」指同一实体。

<a id="test-plan-id-policy"></a>

> **测试计划写操作（计划 ID）** — 适用于须 `fsdTestplanId` 的命令：`fstPlan trigger`、`fstPlan stop`、`fstPlan retry`、`test finish`、`test delete`、`test stop-pipeline`、`test revoke-deploy` 等。
>
> **目的：** 防止误对错误计划执行写操作。
>
> **本条 user 消息含数字计划 ID**（如 `73196`、`对 73196 跑自动化`）→ 可直接使用该 ID。
>
> **上下文含 JSON 且有 `testPlan.id` 字段**（如 `{"testPlan":{"id":73295,...}}`）→ 该值即为测试计划 ID，**直接使用，无需询问确认**。
>
> **本条未写 ID：** 看**会话上下文**是否已有**唯一**计划 ID（如刚 `test create` / `waitTest accept` 后助手回报、用户前文明确写出）。**有** → **先询问是否使用该 ID**，用户确认后再执行；**无**（或多条无法消歧）→ 请用户给出 ID，可配合 `fsd test list --pretty` 并说明列表范围。
>
> **禁止：** 仅「第一个」「刚才那个」等模糊指代且无锚定；同轮 `test list` 出多条后**默认第一条**去 `trigger` / `finish` / `delete` / `stop-pipeline` / `revoke-deploy`。
>
> **优先级：** 本条优先于泛化的「直接执行无需确认」。流程见 [fstPlan trigger · 决策树](#sec-fst-trigger-dt)。
>
> 其余遵循 SKILL.md 核心规则。
>
> **FSD 链接**：`…/test/detail?testPlanId=<id>` 中 **`testPlanId`** 即本手册中的测试计划 ID。「迭代」**不默认**等于交付或测计划；若链接为 **`test/detail?testPlanId=`** 则锚定为测试计划；若为 **`testApplyDetail`** 则锚定为交付 → [delivery.md · 迭代与 FSD 链接（交付 vs 测试计划）](delivery.md#sec-iteration-fsd-url)。

## 目录

- [fsdTestplan add 接口](#fsdtestplan-add-接口)
- [fsdTestplan detail 接口](#fsdtestplan-detail-接口)
- [fsdTestplan pageList 接口](#fsdtestplan-pagelist-接口)
- [fsdTestplan delete 接口](#fsdtestplan-delete-接口)
- [queryTestPlanSummary 接口](#querytestplansummary-接口)
- [testFinished 流程（fsd test finish）](#testfinished-流程fsd-test-finish)
- [测试计划 coverage / refresh-coverage](#sec-test-coverage-merge)
- [测试计划 deploy / trigger-pipeline / stop-pipeline / revoke-deploy / deploy-records / deploy-progress](#sec-test-deploy-merge)
- [test jobs 与部署报告摘要](#sec-test-jobs-deploy-report)
- [skipTestPlanEcPoint 接口](#skiptestplanecpoint-接口)
- [houyiV2 配置变更（confirm-config / config-change-info）](#sec-houyi-v2)
- [分支合并风险分析（branch-risk）](#sec-branch-risk)
- [fstPlan 全部操作（list / bind / unbind / skip / trigger / stop / retry）](fst-plan.md)
- [意图路由索引](#sec-intent-index)
- [准出工作流](#sec-gate-workflow)
- [卡片 key 映射（--card）](#sec-card-keys)
- [错误处理](#错误处理)
- [使用示例](#使用示例)

---

## fsdTestplan add 接口

创建测试计划：`fsd test create`。更新：`fsd test update`（均 `POST /api/qa/v1/fsdTestplan/add`；`update` 先 `GET detail` 再合并未传字段）。

| 项目  | 说明                            |
| --- | ----------------------------- |
| 方法  | POST                          |
| 路径  | `/api/qa/v1/fsdTestplan/add`  |
| 创建  | 不传 `fsdTestplanId`            |
| 更新  | 传 `fsdTestplanId`（CLI：`--id`） |

### CLI 参数 — create

| CLI 参数                                            | 映射字段                                | 必填  | 说明                    |
| ------------------------------------------------- | ----------------------------------- | --- | --------------------- |
| -n, --name                                        | name                                | 是   | 名称，≤200               |
| --qa                                              | qa                                  | 否   | 参与人 MIS，逗号分隔；默认当前 SSO |
| --env test / staging / liteSet                     | env                                 | 是   | 与前端红星一致               |
| --start-time                                      | expectStartTime                     | 否   | 默认当前时间                |
| --end-time                                        | expectFinishTime                    | 是   |                       |
| --online-time                                     | onlineProjectTime                   | 是   |                       |
| --delivery-ids                                    | ids                                 | 否   | 提测单 ID（非交付 ID）        |
| --assigned / --cc                                 | assigned / cc                       | 否   |                       |
| --swimlane / --create-swimlane / --swimlane-maven | swimlane / createSwimlanConfigMaven | 否   | 泳道相关                  |
| --pretty / -v, --verbose                          | —                                   | 否   |                       |

### CLI 参数 — update

| CLI 参数 | 说明               |
| ------ | ---------------- |
| --id   | 必填，测试计划 ID       |
| 其余     | 同 create，仅更新传入字段 |

### 创建 / 更新决策树

```
用户说「创建测试计划」
├─ 【--delivery-ids】
│  ├─ 已有提测单列表 → 用户指定条 → 取 item.id（[提测单ID: xxx]）；禁止用 item.deliveryId
│  ├─ 仅有交付上下文 → 先 fsd waitTest list --pretty，再取提测单 ID；禁止把交付 id / testApplyId 当提测单 ID
│  └─ 未提供 → 可不传（选填）
└─ name/time/env 由 CLI 自动处理，禁止追问；仅当无 delivery 且 env 无法推断时才追问 env
```

---

## fsdTestplan detail 接口

查询详情与进度：`fsd test detail`。

| 项目  | 说明                                      |
| --- | --------------------------------------- |
| 方法  | GET                                     |
| 路径  | `/api/qa/v1/fsdTestplan/detail?id={id}` |

### 请求参数（Query）

| 参数  | 必填  | 说明      |
| --- | --- | ------- |
| id  | 是   | 测试计划 ID |

### CLI 参数

| 参数                       | 说明  |
| ------------------------ | --- |
| --id                     | 必填  |
| --pretty / -v, --verbose | 可选  |

### 决策树

已给 id → `fsd test detail --id <id>`。要列表或未定 id → 见 [pageList](#sec-test-list)。

---

<a id="sec-test-list"></a>

## fsdTestplan pageList 接口

分页列表：`fsd test list`。

| 项目  | 说明                                |
| --- | --------------------------------- |
| 方法  | GET                               |
| 路径  | `/api/qa/v1/fsdTestplan/pageList` |

### 请求与业务参数（摘要）

| 行为                    | 说明                                        |
| --------------------- | ----------------------------------------- |
| 默认                    | 「与我相关」的前后各 30 天（预计上线时间在 30 天前至 30 天后） |
| `--team`              | 「我团队」的前后各 30 天（预计上线时间在 30 天前至 30 天后）  |
| `--online-time-days`  | 指定前后 N 天（正整数，默认 30）                   |
| `--card-not-pass all` | 任意卡片未通过；逐条 summary，耗时长，`--page-size` 不宜过大 |

### CLI 参数

| CLI 参数                                         | 默认     | 说明                              |
| ---------------------------------------------- | ------ | ------------------------------- |
| --page-num / --page-size                       | 1 / 10 |                                 |
| --name / --type / --status                     | —      | type：0 全部；1～4 见原语义；status 支持中文  |
| --qa / --cc                                    | —      | MIS                             |
| --online-time-start / end / --online-time-days | 前后各30天 | 默认前后各 30 天；支持更大时间范围      |
| --team                                         | —      | 我团队（自动用当前用户 orgId，查团队所有计划）|
| --fst-not-pass                                 | —      | 等价 `--card-not-pass fstPlan`    |
| --card-not-pass keys                           | —      | fstPlan,coverage,defect,…；`all` |
| --pretty / -v                                  | —      |                                 |

### 决策树

```
查测试计划列表
├─ 查我团队的
│   └─ fsd test list --team [--online-time-days N] [--pretty]
└─ 查与我相关的（默认）
    └─ fsd test list [--online-time-days N] [--pretty]
```

**时间范围说明**：
- 默认查询前后各 30 天（预计上线时间在 30 天前至 30 天后）
- 可通过 `--online-time-days N` 指定（N 为正整数，默认 30）
- 也可手动指定 `--online-time-start/end` 查询任意时间范围

**权限说明**：
- 默认只查「与我相关」的测试计划（QA/创建人/负责人/抄送人等）
- `--team` 只查当前用户所属团队的计划（自动获取 orgId，不能指定其他团队）

---

## fsdTestplan delete 接口

`fsd test delete`。

| 项目  | 说明                                                 |
| --- | -------------------------------------------------- |
| 方法  | GET                                                |
| 路径  | `/api/qa/v1/fsdTestplan/delete?fsdTestPlanId={id}` |
| 限制  | 已关联提测单时不可删                                         |

### CLI 参数

| 参数   | 说明  |
| ---- | --- |
| --id | 必填  |

### 决策树

```
用户要删除测试计划（test delete）
├─ 已提供测试计划 ID（本条 user 消息含数字 ID）
│   └─ fsd test delete --id <id>
└─ 未提供测试计划 ID（本条无数字 ID）
    ├─ 上下文唯一计划 ID → 询问确认后再删除（确认前本轮不执行）
    └─ 无法唯一确定 → 请用户提供 ID；可 `fsd test list --pretty` 辅助；禁止同轮 list 后默认第一条删除
```

**删除前确认原则**：
- 上下文不清时优先让用户本条显式写 ID
- 已关联提测单的测试计划无法删除（接口会返回业务错误）
- 删除操作不可逆，必须确保用户明确意图

---

## queryTestPlanSummary 接口

准出摘要 / 单卡详情：`fsd test summary`。

| 项目  | 说明                                            |
| --- | --------------------------------------------- |
| 方法  | GET                                           |
| 路径  | `/api/qa/v1/fsdTestplan/queryTestPlanSummary` |

### 请求语义

| 参数             | 说明                                                                |
| -------------- | ----------------------------------------------------------------- |
| `--gate-check` | 返回 `mustCheckStatus`、`mustCheckErrorMsg`；**准出判定必须带**，否则可能漏侯羿 V2 等 |
| `--type`       | 0 默认合并视图；1 另一套卡片                                                  |

### CLI 参数

| 参数                                           | 说明                                        |
| -------------------------------------------- | ----------------------------------------- |
| --id                                         | 必填                                        |
| --card                                       | 单卡 key，见 [卡片 key 映射](#sec-card-keys)      |
| --gate-check / --type / --pretty / --verbose | 可选（**勿用短 `-v` 当 verbose**，与全局 version 冲突） |

### 决策树

```
用户询问 summary / 卡片信息
├─ 「准出检测」「能不能上线」「卡点状态」
│   └─ fsd test summary --id <id> --gate-check --pretty
├─ 含具体卡片关键词（用例执行 / 自动化 / 覆盖率 / 缺陷 等，可附带「今日」「进度」「情况」修饰）
│   └─ 查 [卡片 key 映射](#sec-card-keys) → fsd test summary --id <id> --card <key>
├─ 泛化进度（「测试进度」「测试执行进度」，无具体卡片关键词）
│   └─ fsd test progress --id <id>
└─ 「走完测试计划」「确认完成」
    └─ [准出工作流](#sec-gate-workflow) 后再 finish
```

---

## testFinished 流程（fsd test finish）

确认测试完成：`fsd test finish`（内部串联 `queryTestPlanSummary` / `getTestFinishedResult` / `testFinished` 等）。

| 项目   | 说明                                                                                                |
| ---- | ------------------------------------------------------------------------------------------------- |
| 流程   | `queryTestPlanSummary`（tabType=all）校验 `mustCheckStatus`；true 则继续提交完成；false 输出 `mustCheckErrorMsg` |
| 结束时间 | 默认当前，或 `--finished-time`                                                                          |

### CLI 参数

| 参数              | 说明  |
| --------------- | --- |
| --id            | 必填  |
| --finished-time | 可选  |
| --pretty        | 可选  |

### 决策树

「确认测试完成」「通过测试计划」等 → 先 [准出工作流](#sec-gate-workflow)。**禁止**跳过 `summary --gate-check` 直接 `finish`。

---

<a id="sec-test-coverage-merge"></a>

## 测试计划 coverage / refresh-coverage

### fsd test coverage

测试计划维度覆盖率；HTTP 以 CLI 为准。返回 `data.list` 常见字段：`jobName` / `developBranch`、`incrementLineRate` / `totalLineRate`、`configRate`、`status`、`msg`、`detailUrl`、统计对象等。

| CLI  | 说明  |
| ---- | --- |
| --id | 必填  |

### fsd test refresh-coverage

异步重算覆盖率；完成后用 `coverage` 查看。

| CLI        | 说明                             |
| ---------- | ------------------------------ |
| --id       | 必填                             |
| -j, --jobs | 可选，`jobName:branch` 逗号分隔；不传则全量 |

决策树见 [准出工作流](#sec-gate-workflow)。

---

<a id="sec-test-deploy-merge"></a>

## 测试计划 deploy / trigger-pipeline

<a id="sec-test-stop-pipeline"></a>

### stop-pipeline（终止运行中的流水线）

`fsd test stop-pipeline` → **`GET /api/fsd_ed/api/testapply/stopPipelineByEventId?eventId=`**（与 **`fsd delivery stop-pipeline`**、ED 测试计划详情「停止」同源）。**仅 Query `eventId`**；操作人从 **SSO** 由服务端解析，与 skill-dev **`TestApplyRefactorController#stopPipelineByEventId`** 一致。

| CLI | 说明 |
| --- | --- |
| `--id` | **必填**，测试计划 ID；CLI 会 **`getTestPlanDetail` 校验存在**（**不**校验 event 与计划的归属，归属以后台为准） |
| `-e` / `--event-id` | **必填**，流水线事件 ID；纯数字或与 **`fsd deploy status`** 相同的 **record 链接**（CLI 内 `parseEventId`） |
| `--pretty` | 可选，人类可读格式输出 |

**如何拿到 `eventId`：**

`stop-pipeline` 需要的 `eventId` 是**各个服务分支的 `parentEventId`**，不是流水线记录的 ID。获取方式：

1. **从部署记录获取**：查询部署/流水线记录列表 → 选择要终止的记录 ID → 查询该记录详情 → 从 **各服务下显示的 eventId**（即 `buildPiplineRecordDetailVos[].parentEventId`）选择要终止的服务
2. **从页面获取**：环境部署卡片/流水线执行关联的 **`detailProgress`** 事件 ID
3. **从 deploy status 获取**：页面网络请求或 **`fsd deploy status`** 展示的事件 ID

> **重要区分**：
> - **`recordId`**（流水线记录 ID）：URL 中的 query 参数，用于查询记录详情
> - **`eventId`**（服务分支事件 ID）：记录详情中各服务的 `parentEventId`，用于 `stop-pipeline` 终止该服务的流水线

**与其它命令的区别：**

| 意图 | 命令 |
| --- | --- |
| 停 **环境部署 / trigger-pipeline 这条流水线**（按 **eventId**） | **`fsd test stop-pipeline --id <计划ID> -e <eventId>`** |
| 停 **FST 单次执行** | **`fsd fstPlan stop`**（`--plan-id` + `--execute-id`） |
| 仅有 **交付 applyProgramId**、无测试计划 | **`fsd delivery stop-pipeline -e <eventId>`**（见 [delivery stop-pipeline](delivery.md#delivery-stop-pipeline终止自测流水线)） |

**安全：** 须遵守 [测试计划 ID 策略](#test-plan-id-policy)；**禁止**无明确 **`eventId`** 时猜测或默认「最新一条」执行 stop。

```bash
fsd test stop-pipeline --id 73476 -e 328997044 --pretty
```

<a id="sec-test-revoke-deploy"></a>

### revoke-deploy（撤销环境部署中的任务）

`fsd test revoke-deploy` → **`GET /api/qa/v1/deliveryPipeline/revokeDeployById?recordDetailId=`**（与 **fsd-test-plan-detail** `RecordDetail.vue` 中 **`revokeDeployById?recordDetailId=${scope.row.id}`** 一致）。skill-dev **`DeliveryPipelineController#revokeDeployById`**：**`recordDetailId > 0`** 时查 **`BuildPiplineRecordDetail`**，校验当前用户是否在测试计划相关人员内，再 **`revokeService.revoke`**；**`recordDetailId ≤ 0`** 时按 **`operateId = -recordDetailId`** 直接撤销。

| CLI | 说明 |
| --- | --- |
| `--id` | **必填**，测试计划 ID；CLI 仅 **`getTestPlanDetail` 校验存在**（**权限与明细归属由后端**按 **`recordDetailId`** 校验） |
| `-r` / `--record-detail-id` | **必填**，记录明细主键（表格行 **`id`**）；**可为负**，建议 **`--record-detail-id=-70689379`** |
| `--pretty` | 可选 |

**与 `stop-pipeline` / 交付撤销的区别：**

| 场景 | 命令 | 参数 / 接口 |
| --- | --- | --- |
| 测试计划记录里点「撤销」环境部署（**recordDetailId**） | **`fsd test revoke-deploy --id <计划ID> -r <recordDetailId>`** | **`/api/qa/v1/deliveryPipeline/revokeDeployById`** |
| 停整条流水线（**eventId**） | **`fsd test stop-pipeline`** | **`testapply/stopPipelineByEventId`** |

**安全：** 遵守 [测试计划 ID 策略](#test-plan-id-policy)；**禁止**无明确 **`recordDetailId`** 时猜测行 id。

```bash
fsd test revoke-deploy --id 73476 --record-detail-id=-70689379 --pretty
```

### deploy（单步部署环境）

`fsd test deploy` → `POST /api/qa/v1/deliverySingleStep/triggerStep`，`stepType=FSD_DeliverQaDeploy`。仅部署，非整条流水线。有测试计划上下文时**用本命令**，勿与独立 `fsd deploy` 混用。

> **AI / 助手**：工作区或 context 已给出 **`testPlan.id`** 时，用户说「部署到泳道 / 测试环境 / 带上 UUID」仍**只走本命令**；**禁止**改用 `fsd deploy swimlane`（即使 context 含 `stackUuid` 或泳道名）。多应用：多次 `fsd test deploy` 各带 `--job-name`，或确认全量后省略之。

| CLI                         | 说明       |
| --------------------------- | -------- |
| --id                        | 必填       |
| --job-name                  | 可选，只部署该 **jobName**（与 `--appkey` 二选一） |
| --appkey                    | 可选，**octoAppKey**：在测试计划 **jobList** 内解析为唯一 **jobName** 后只部署该服务（与 `--job-name` 二选一）；解析规则为计划行字段优先，否则通过 **`listPageAuth`** 与计划 jobName 求交。**无交集**或**多条命中**时报错，需改用 `--job-name`。 |
| --include-non-delivery-jobs | 可选，非提测应用；一并部署「非提测应用」（手动新增，isFromDelivery=false） |
| --ips                       | 可选，指定部署机器（逗号分隔 IP 或机器名）；与 `--cell` 互斥 |
| --cell                      | 可选，按机器标签(SET)筛选部署机器，如 `waimai-west`（仅 staging 生效）；与 `--ips` 互斥 |
| --pretty                    | 可选       |

**`--env liteSet`**（及 `trigger-pipeline` 同环境）：CLI 参数、模板/set、`未触发部署。` 与助手禁止去参重试等 → [test-plan-liteSet.md](test-plan-liteSet.md)（与交付对齐的完整说明见 [delivery-liteSet-trigger.md](delivery-liteSet-trigger.md)）。

<a id="sec-test-trigger-pipeline"></a>

### trigger-pipeline（测试计划流水线）

`fsd test trigger-pipeline` → `POST /api/qa/v1/deliveryPipeline/triggerPipeline`，`type=qaTest`。与 `fsd delivery trigger -i <applyProgramId>`（交付自测）**不同**，参数为**测试计划 id**。CLI 取计划 `jobList`、去 SecurityScan；`stackUuid` 存在则 `env=cargo` 否则 `test`。**jobList 为空则 CLI 不调接口**。

| CLI      | 说明  |
| -------- | --- |
| --id     | 必填  |
| --pretty | 可选  |

<a id="sec-test-jobs-deploy-report"></a>

### fsd test jobs 与部署报告摘要（AI 展示格式）

`fsd test jobs --id <id>` → `GET /api/qa/v1/fsdTestplan/getJobList`，**只读**拉取测试计划下应用列表及构建/部署状态；不触发任何操作。

| CLI      | 说明  |
| -------- | --- |
| --id     | 必填  |
| --pretty | 可选；终端人类可读摘要 |

`dataList` 每项常见字段含 `jobName`、`buildStatus`、`buildBy`、`buildTime`、`testBranch` / `branches`、`isFromDelivery`、`eventId` 等（以后端实际返回为准）。**生成面向用户的「部署报告摘要」时**，除执行本命令外，须按下文模板排版，避免在对话里出现空列或截断应用名。

#### 报告格式规范（必须严格遵守）

> 部署报告摘要
>
> - 测试计划：`<name>`（ID: `<id>`）
> - 环境：`<envType>`（`<swimlaneId>`）
> - 状态：`<testPlanStatus>`
>
> **部署概览**
>
> | 指标 | 数量 |
> |------|------|
> | 总应用数 | N |
> | 成功 | N |
> | 失败 | N |
> | 运行中 | N |
>
> **应用详情**
>
> | 应用 | 状态 | 部署分支 | 部署人 |
> |------|------|---------|-------|
> | appName | ✅/❌/⏳/⏸ | branch | buildBy |

- **状态图标映射**（与 CLI `--pretty` 一致）：`success` / `succeed` → ✅；`fail` / `failed` / `failure` → ❌；`running` / `in_progress` → ⏳；其余（如 `init`、空）→ ⏸
- **禁止**在表格中增加 `AppKey`、`octoAppKey` 等 **getJobList 未返回** 的字段列（避免出现整列为空）
- **应用**列必须使用完整 `jobName`，禁止为适配窄表格而截断
- 某字段缺失或为空时，对应单元格填 `-`

与 SKILL.md 一致：**仅汇总状态**时不得串联 `deploy-progress` / `deploy-records`；排查失败另见 [deploy-progress](#sec-test-deploy-progress)。

<a id="sec-test-deploy-records"></a>

### deploy-records 接口

分页查询测试计划流水线记录（与详情页「环境部署」列表请求一致）。`GET /api/qa/v1/fsdTestplan/queryFstRecordByTestPlanId`

`fsd test deploy-records` → 上列接口。

| 参数 | 说明 |
|------|------|
| `--id <id>` | 必填；query `testPlanId` |
| `--page <n>` | 可选；`pageNo`，默认 1 |
| `--size <n>` | 可选；`pageSize`，默认 10 |
| `--source <s>` | 可选；默认 `FSD_DeliverQaDeploy,qaTest`（与前端 `SubTabSourceMap.deploy` 一致） |
| `--pretty` | 可选；简要表格 |

<a id="sec-test-deploy-progress"></a>

### deploy-progress 接口

单条部署流水线记录明细。`GET /api/qa/v1/deliveryPipeline/queryDetailByRecordId`

`fsd test deploy-progress` → 上列接口。

### 决策树（列表 → 明细）

```
查「环境部署」类记录进度/明细
├─ 已有所需记录 id（页面 / 上轮 deploy-records 已给出）
│   └─ fsd test deploy-progress --record-id <id> [--pretty]
├─ 仅有测试计划 id，且要看「刚部署后最新一次」或不必挑条
│   └─ fsd test deploy-progress --plan-id <测试计划ID> --latest [--pretty]
│       （CLI 内先 queryFstRecordByTestPlanId 第一页首条，再 queryDetailByRecordId；与 dataList 创建时间倒序一致）
└─ 需翻页、对比多条或指定非首条
    └─ fsd test deploy-records --id <测试计划ID> [--page --size --pretty]
        └─ 从 dataList 取目标 id → fsd test deploy-progress --record-id <id> [--pretty]
```

| 参数 | 说明 |
|------|------|
| `--record-id <id>` | 与 `--plan-id --latest` 二选一；query `recordId`，非零整数 |
| `--plan-id <id>` | 与 `--latest` 联用 |
| `--latest` | 默认 source 下第一页第一条记录再查明细 |
| `--domain-name <name>` | 可选；query `domainName` |
| `--pretty` | 人类可读摘要；默认输出完整 `data` JSON |

---

## skipTestPlanEcPoint 接口

`fsd test skip-ec` → `GET /api/qa/v1/fsdTestplan/skipTestPlanEcPoint`，卡片 `mobileDeliveryTestCaseV2`。未传 `--issue-ids` 时 CLI 先查未过卡点需求再批量跳过。

| CLI          | 说明  |
| ------------ | --- |
| --id         | 必填  |
| --issue-ids  | 可选  |
| -r, --reason | 可选  |
| --pretty     | 可选  |

---

<a id="sec-houyi-v2"></a>

## houyiV2 配置变更（confirm-config / config-change-info）

### fsd test confirm-config

侯羿等卡点确认；先查状态，未确认则 CLI 触发（路径以 CLI 为准）。**须用户确认后再执行**，禁止静默。

| CLI      | 说明  |
| -------- | --- |
| --id     | 必填  |
| --pretty | 可选  |

### fsd test config-change-info

各服务配置变更展示；`msg` 非空表示过滤或异常。

| CLI      | 说明  |
| -------- | --- |
| --id     | 必填  |
| --pretty | 可选  |

---

<a id="sec-branch-risk"></a>

## 分支合并风险分析（branch-risk）

`fsd test branch-risk` — **纯只读**，禁止做任何 merge / commit / push。

### 工作原理

1. 从测试计划 `getJobList` 取每个服务的分支信息
2. 在 `<workDir>/code/` 下扫描以 `<jobName>` 开头的子目录（兼容 `<jobName><随机数>` 命名）
3. 对每个找到的本地 repo 执行 `git fetch origin --quiet`（只拉取引用，不合并）
4. 执行三项检查后输出报告

### 三项检查内容

| 检查项 | 说明 | 触发条件 |
|--------|------|---------|
| **多分支文件重叠** | 对服务的多个开发分支分别做 `git diff --name-only origin/<deployBranch>...origin/<br>`，取文件集合交集；有交集 = 几乎必然冲突 | `branches.length ≥ 2` |
| **冲突预判** | 用 `git merge-tree`（只读，不修改工作区）对每个开发分支与 `qa` / `master` / `deployBranch` 预判合并结果 | 有开发分支 |
| **部署分支落后 master commit 数** | `git rev-list --count origin/<deployBranch>..origin/master`；落后越多，合并时引入未知变更越多 | 有部署分支 |

> `git merge-tree` 版本适配：Git ≥ 2.38 使用 `--write-tree`（精确）；低版本自动回退到 `merge-tree <base> <ours> <theirs>` 解析 `<<<<<<<` 标记。

### CLI 参数

| 参数 | 说明 |
|------|------|
| `--id` | 必填，测试计划 ID |
| `--work-dir <dir>` | 可选，测试计划工作目录；默认当前目录；`code/` 子目录下存放各服务 repo |
| `--pretty` | 可选，人类可读格式；默认 JSON |

### 决策树

```
用户意图含「分支冲突」「合并风险」「会冲突吗」「能合并吗」「分支情况」
└─ fsd test branch-risk --id <id> --pretty
   （如果 repo 不在默认目录下，加 --work-dir <path>）
```

### Agent / 终端展示约定

- **单次调用**：合并风险分析须在**一条** Shell 命令中完成；**不要**为克隆、fetch、分析等子步骤多次使用 `working_directory` 切目录，否则界面会重复出现「执行命令 cd …」类噪音。
- **路径传递**：已知测试计划根目录时，用 `--work-dir "<path>"` 传入即可，无需先 `cd` 再执行。
- CLI **`--pretty` 模式不打印本地工作目录**；JSON 模式仍含 `codeDir` 字段供程序消费。

---

<a id="sec-test-deploy-failure"></a>

## 部署失败排查（测试计划上下文）

用户意图为**排查/修复**部署失败原因时使用。**与「查看部署状态/生成报告」场景不同**：后者仅用 `fsd test jobs` 汇总状态，不触发排查。

### 触发词

「帮我排查」「看一下失败原因」「为什么失败」「部署失败」「分析失败原因」「修复建议」「FSD帮我分析」「XX 应用部署失败」等。

### 排查流程（强制顺序）

```
用户报告部署失败
├─ ① fsd test jobs --id <testPlanId> --pretty
│   └─ 从 JSON 的 jobList 中筛选 buildStatus=fail 的应用
│       按 jobName 取每个失败应用的 eventId（每个应用一条，不可混用）
├─ ② 对每条失败 eventId 执行
│   └─ fsd deploy analyze -i <eventId>
│       （必要时辅以 fsd test deploy-progress --record-id <记录id> --pretty 看整单摘要）
├─ ③ 按 troubleshooting.md 处理
│   └─ 冲突 → 开发人工合并
│       缺包 → jar-deploy
│       重复队列/环境互斥 → 以 analyze 返回文案为准
└─ ④ 归纳根因 + 修复建议
```

### 多应用场景

用户列举多个失败应用名时（如「waimai-qa-deploy-test-web 和 waimai-qa-deploy-test-jar 部署失败，请 FSD 帮我分析原因并给出修复建议」）：

1. **必须先** `fsd test jobs --id <testPlanId> --pretty` 获取所有应用状态
2. **对每个失败应用**分别执行 `fsd deploy analyze -i <其eventId>`
3. **逐个汇总**原因与修复方案后统一输出
4. **禁止**跳过 `fsd test jobs` 直接凭应用名臆测原因

### 禁止事项

- **禁止**仅输出建议清单或凭业务代码/仓库臆测原因——须按平台部署记录与流水线日志定因
- **禁止**在尚无 CLI 输出时假装已读「实际部署日志」——仅允许复述已执行 CLI（`jobs` / `deploy analyze` / `deploy-progress`）返回中的步骤与 `errorMsg`
- **禁止**打开应用源码做推断——除非用户明确要求，否则只执行 CLI 并复述输出
- **禁止**用 `fsd test deploy-progress --plan-id <id> --latest` 替代各应用 `eventId` 的 analyze——`--latest` 可能无法区分多应用或明细不全
- 用户仅说「生成报告/查看状态」时**不属于本场景**，禁止串联 `deploy-progress` / `analyze`

### 决策树

```
用户说「部署失败 / 帮我排查 / 为什么失败 / FSD帮我分析」
├─ 有 testPlanId
│   ├─ fsd test jobs --id <testPlanId> --pretty → 取失败应用 eventId
│   │   └─ 逐条 fsd deploy analyze -i <eventId>
│   └─ 用户指定了具体应用名 → 仍先 jobs 取 eventId，再 analyze 该应用
├─ 有 eventId（用户直接给）
│   └─ fsd deploy analyze -i <eventId>
└─ 无任何 ID
    └─ 询问用户获取测试计划 ID 或 eventId
```

---

<a id="sec-intent-index"></a>

## 意图路由索引

| 用户意图            | 章节                                                                          |
| --------------- | --------------------------------------------------------------------------- |
| 指定计划详情          | [fsdTestplan detail](#fsdtestplan-detail-接口)                                |
| 列表 / 筛选         | [pageList](#sec-test-list)                                                  |
| 准出 / 单卡 summary（含「用例执行」「自动化执行」「覆盖率」「缺陷」等自然语言卡片名） | [queryTestPlanSummary](#querytestplansummary-接口)                            |
| 测试完成 / 收尾       | [testFinished](#testfinished-流程fsd-test-finish)、[准出工作流](#sec-gate-workflow) |
| FST 全部操作（绑定 / 触发 / 跳过 / 终止 / 重试） | [fst-plan.md](fst-plan.md)                                     |
| Houyi 确认 / 配置详情 | [houyiV2](#sec-houyi-v2)                                                    |
| 计划内「部署环境」触发     | [deploy](#sec-test-deploy-merge)                                            |
| 查看部署状态 / 生成部署报告摘要 | `fsd test jobs --id <id> --pretty`；展示格式见 [test jobs 与部署报告摘要](#sec-test-jobs-deploy-report)（**禁止**串 `deploy-progress`） |
| 计划内「环境部署」记录列表   | [deploy-records](#sec-test-deploy-records)                                  |
| 计划内「环境部署」单条进度（排查失败）| [deploy-progress](#sec-test-deploy-progress)（仅用于排查修复，不用于查状态）           |
| 计划内「跑流水线」       | [trigger-pipeline](#sec-test-trigger-pipeline)                              |
| 分支冲突 / 合并风险 / 会冲突吗 / 能合并吗 / 分支情况 | [branch-risk](#sec-branch-risk) → `fsd test branch-risk --id <id> --pretty` |
| 部署失败排查 / 帮我排查 / 为什么失败 / FSD帮我分析 | [部署失败排查](#sec-test-deploy-failure) → 先 `fsd test jobs` 取 eventId，再 `fsd deploy analyze -i <eventId>` |
| 计划内「停流水线」（非 FST） | [stop-pipeline](#sec-test-stop-pipeline)                                    |
| 计划内「撤销环境部署」（记录行） | [revoke-deploy](#sec-test-revoke-deploy)                               |
| 终止正在跑的 FST       | [fst-plan.md · fstPlan stop](fst-plan.md#sec-fst-stop)                      |
| 重试已执行的 FST       | [fst-plan.md · fstPlan retry](fst-plan.md#sec-fst-retry)                    |

---

<a id="sec-gate-workflow"></a>

## 准出工作流

> 触发词含「确认测试完成」「通过测试计划」「帮我走完流程」等 → **禁止**跳过 Phase 1 直接 `finish`。

### 卡点矩阵

| 卡片 key                   | 处理                                                               |
| ------------------------ | ---------------------------------------------------------------- |
| fstPlan                  | 执行中「停掉」→ `fstPlan stop`；**已有执行记录要重试**→ `fstPlan retry`；问「整批重触发 / 跳过卡点」→ `fstPlan trigger`（须满足 [计划 ID 约束](fst-plan.md#fst-trigger-gate)）或 `fstPlan skip` |
| envDeploy                | 查列表/明细 → **`test deploy-records` / `test deploy-progress`**；停整链流水线 → **`test stop-pipeline -e <eventId>`**；**撤销环境部署记录行** → **`test revoke-deploy -r <recordDetailId>`**（与 **eventId** 不同）→ [stop-pipeline](#sec-test-stop-pipeline)、[revoke-deploy](#sec-test-revoke-deploy) |
| houyiV2 / changeRisk     | 用户授权 → `confirm-config`                                          |
| coverage                 | 刷新 → `refresh-coverage` 后 `--card coverage`；或 `skip-coverage -r` |
| mobileDeliveryTestCaseV2 | 授权 → `skip-ec`                                                   |
| 其余                       | `summary --card <key>` 展示                                        |

### 流程（四步）

1. **扫描**：`fsd test summary --id <id> --gate-check` → `mustCheckStatus` true 可跳第 4 步收尾；false 进入 2。
2. **确认**：区分 ✅ 已通过 / 👤 须用户选 / 📋 人工跟进；无 👤 可进 4。
3. **执行**：按矩阵处理；fstPlan 触发后可提示 `fstPlan list` 查看，**不轮询**。
4. **收尾**：再 `summary --gate-check`；true → `fsd test finish --id <id> --pretty`；false → 输出 `mustCheckErrorMsg`，结束。

---

<a id="sec-card-keys"></a>

## 卡片 key 映射（--card）

> **匹配优先级**：先看用户表述是否含下表关键词（含带「今日」「进度」「情况」「状态」等修饰词的变体），有命中即用对应 `--card`，**不得**因修饰词存在而改路由到 `test detail` 或不带 `--card` 的 `summary`。

| 用户表述（含变体）                                                                     | --card                                        |
| ------------------------------------------------------------------------------- | --------------------------------------------- |
| 用例执行、通过率、测试用例执行、用例执行进度、今日用例执行、用例执行情况、用例执行状态                                    | mobileDeliveryTestCaseV2                      |
| 覆盖率、覆盖率进度、今日覆盖率                                                               | coverage                                      |
| 自动化、FST、自动化执行、自动化进度、自动化执行情况、自动化执行状态、今日自动化                                      | fstPlan                                       |
| 缺陷、缺陷情况、缺陷状态                                                                    | defect                                        |
| 后羿、配置变更、houyiV2                                                                 | houyiV2                                       |
| 环境部署（构建/部署流水线；停跑须 **eventId**）                                                  | envDeploy                                     |
| 变更风险                                                                            | changeRisk                                    |
| Pangolin / BcpApi / FastException / FlowFocus                                   | pangolin / bcpapi / fastexception / flowfocus |

还可含 `linkAssert`、`mock`、`testReport` 等（与 list `--card-not-pass` 一致）。

---

## 错误处理

| 类型              | 说明                                                                    |
| --------------- | --------------------------------------------------------------------- |
| CLI 校验与 `错误: …` | 实现集中在 `fsd/cli/scripts/test-plan/commands.js`（及 fst-plan）；以**终端输出为准** |
| 静态文档            | 勿逐条依赖本文列举；`test create` 等会先自动回填字段，与表格易脱节                              |
| 接口业务错误          | 以后端 `msg` 为准（如 delete 关联提测单、unbind 系统推荐等）                             |

---

<a id="使用示例"></a>

## 使用示例

```bash
# 创建 / 更新 / 列表 / 详情 / 删除
fsd test create --env test
fsd test create --delivery-ids 93389
fsd test update --id 72589 --delivery-ids 51542 --pretty
fsd test update --id 12345 -n 新名称 --assigned lisi
fsd test update --id 12345 --delivery-ids ""
fsd test list --pretty
fsd test list --team --pretty
fsd test list --online-time-days 30 --pretty
fsd test list --name 联调 --status 测试中,已完成 --pretty
fsd test list --team --online-time-days 14 --page-num 1 --page-size 20
fsd test detail --id 12345 --pretty
fsd test delete --id 12345

# 准出 / 单卡 / 完成 / 部署 / 流水线
fsd test summary --id 12345 --gate-check --pretty
fsd test summary --id 12345 --card coverage
fsd test summary --id 12345 --card fstPlan
fsd test finish --id 12345 --pretty
fsd test finish --id 12345 --finished-time "2025-03-19 18:00:00" --pretty
fsd test deploy --id 72848 --pretty
fsd test trigger-pipeline --id 72828 --pretty
fsd test stop-pipeline --id 73476 -e 328997044 --pretty
fsd test revoke-deploy --id 73476 --record-detail-id=-70689379 --pretty
fsd test deploy-records --id 72828 --pretty
fsd test deploy-progress --plan-id 72828 --latest --pretty
```

### 示例8：skip-ec / 配置

```bash
fsd test skip-ec --id 72828 -r "与本次改动无关" --pretty
fsd test confirm-config --id 12345 --pretty
fsd test config-change-info --id 12345 --pretty
fsd test coverage --id 12345
fsd test refresh-coverage --id 12345

# 分支合并风险分析（本地 Git 模式）
fsd test branch-risk --id 12345 --pretty
fsd test branch-risk --id 12345 --work-dir /path/to/project --pretty
fsd test branch-risk --id 12345
```
