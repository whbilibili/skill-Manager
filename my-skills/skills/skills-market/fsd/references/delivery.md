# FSD 交付参考手册

> 所有操作遵循 SKILL.md 核心规则。

> 部署相关内容（参数、监控、失败分析等）见 [deploy.md](deploy.md)。
>
> **前置条件**：交付创建与编辑需使用 SSO 登录，请求会自动携带 Cookie。请先执行 `fsd-sso login` 登录。

## 目录

- [delivery create 参数与默认值](#delivery-create-参数与默认值)
- [delivery create 场景](#delivery-create-场景)
- [delivery ones / edit / delete / list / status / detail / prep / online-notice 参数说明](#delivery-ones-参数说明)
- [gate 准出检测](#gate-准出检测)
- [deliver-qa 交付 QA](#deliver-qa-交付-qa)
- [delivery fst（交付 FST 自动化）](#delivery-fst交付-fst-自动化)
- [交付正常流程](#交付正常流程)
- [delivery trigger / trigger-retry / skip-steps](#delivery-trigger-底层接口)
- [delivery stop-pipeline（终止自测流水线）](#delivery-stop-pipeline终止自测流水线)
- [record-detail 与部署机器 IP](#record-detail-与部署机器-ip)
- [delivery prep（上线前准备）](#delivery-prep上线前准备)
- [delivery online-notice（上线注意事项）](#delivery-online-notice上线注意事项)
- [上线注意事项与明日上线](#上线注意事项与明日上线)
- [迭代与 FSD 链接（交付 vs 测试计划）](#sec-iteration-fsd-url)
- [客户端交付（deliveryDetailMed）](#客户端交付deliverydetailmed)
- [API 接口说明](#api-接口说明)
- [AI 决策树](#ai-决策树)
- [使用示例](#使用示例)

---

## delivery create 参数与默认值

**推断顺序（简）**：显式入参 > 默认规则；Ones 来自 `-j` 完整链接或 `-i`/`--ones-id`（内部拼 ones URL）。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| -a, --app | string | 否 | `queryJobByGit` 解析当前仓库服务 |
| -b, --branch | string | 否 | 当前 git 分支；若已传 `-j` 或 `-i`/`--ones-id` 与 `-n` 可同时省略（仅依赖 requirementBranchView 组 jobList） |
| -j, --jira-task | string | 否 | 与 `-i`/`--ones-id` 二选一；支持 ones 与**同路径** fsd 详情 URL；否则 `getBranchListByJob`→无则 `getOnes` 取首条需求（优先开发中），仍无则须 `-j`/`-i` |
| -i, --issue-id | number | 否 | Ones 数字主键；非 `--no-auto` 时 `getOnesDetails` 拼 `jiraTask`；`--no-auto` 时建议配 `--ones-type` |
| --ones-id | number | 否 | 同 `-i`（别名，勿与 `-i` 混填不同数字） |
| --ones-type | string | 否 | `--no-auto` 且用 `-i` 时建议：`REQUIREMENT` / `DEVTASK` / `DEFECT` |
| -n, --name | string | 否 | `-i` 且非 `--no-auto`：`getOnesDetails` 展示名覆盖 `-n`；显式 `-j` 且未传 `-n`：以链接工作项展示名为准；其余：分支/`getOnes` 自动名或显式 `-n` |
| -e, --scene | string | 否 | 未传→`getPiplineConfig` 按 `rdSelfTestEnv` 映射；**已传 `-e`**→不调 `getPiplineConfig`；`--no-auto` 未传则 `test` |
| -u, --swimlane-id | string | 否 | `swimlane` 必填或由推断填入；显式优先 |
| -s, --stack-name | string | 否 | `new-swimlane` 可选泳道名，不填自动生成 |
| --stack-uuid | string | 否 | 已有泳道可选；可从 `-u` 解析 |
| --online-time | string | 否 | 预计上线时间 |
| --test-branch | string | 否 | 按场景推断 |
| --project-type | number | 否 | 未传→`getOnesDetails`：`qas` 非空→4 否则 1；`--no-auto` 关闭推断（未传则固定 1） |
| --qa | string | 条件 | **标准交付（`projectType=4`）**：仅当 `getOnesDetails` 的 **`qas`（测试人员）** 能解析出有效 MIS 时，可不传并由 CLI 拼接；**若需求未配置有效 `qas` 且未传 `--qa`，CLI 报错退出**。**不会**用当前登录人、**也不会**用需求 **`assigned`/负责人/提出人** 等代替 QA——见下节「标准交付 QA 来源」。 |
| --technical-solution | string | 否 | 标准交付未传、非 `--no-auto` 且能取到 ones 信息→`listDocs(PRODUCT_SCHEME)` 拼 `title`+`wikiUrl`；失败或未配置→「标准交付」；显式传入以用户为准 |
| --pipline-template | number | 否 | 未传 `-e` 且未指定→优先 `getPiplineConfig`；已传 `-e`→不调该接口，未指定按 0 规范化（展示 4→API 2） |
| --no-auto | flag | 否 | 不调 `getOnesDetails`/`getPiplineConfig`/`requirementBranchView`/listDocs；`project-type` 未传→1；`-e` 未传→test；jobList 仅当前服务+`-b` |

**参数优先级**：用户显式传入优先。自动选取时结果中可含 `autoPickedOnesFromList` / `linkedOnesName` / `linkedOnesUrl`（`--pretty` 会说明）。

### 多服务 jobList（默认）

**规则（服务与分支来源）**：新建交付时，`jobList` 中的**服务、开发分支**优先来自 **Ones 需求分支视图**（`requirementBranchView`），对应两类需求上下文（二选一，解析结果均为 `jiraTask` → `issueId`）：

1. **指定的需求**：用户传入 `-j`（Ones 链接）或 `-i` / `--ones-id`；
2. **当前分支关联的需求**（或未传 Ones 时由 `getOnes` 自动选用的需求）：在仓库内由分支解析出的关联 Ones，与 ED「按分支建交付」一致。

条件：未加 `--no-auto`，且最终 `jiraTask` 可解析出有效 `issueId`。  
行为：分页 `GET .../requirementBranchView/{issueId}`（默认 `excludeSpecialBranch=true`），每条 `jobName`+`branch`→`jobList` 一项（`developBranch`=接口 `branch`），`jobName+branch` 去重。无有效数据则回退「当前仓库解析的单个服务 + 当前开发分支」单条；若显式指定了需求但仍无视图数据（如部分任务/缺陷），允许空 `jobList` 先建交付、后续在详情补服务（与 ED 一致）。

**`--no-auto`**：不拉 `requirementBranchView`，`jobList` 仅为当前服务与 `-b` 分支。

### 交付类型与 QA（默认自动）

`projectType`：`getOnesDetails.qas` 判 1/4。标准交付且未传 `--qa` 时用 **`qas` 去重拼接**。

### 标准交付 QA 来源（强制）

- **接口与 CLI**：`qa` 字段**只**来自 **`getOnesDetails` 的 `qas`**（Ones 上配置的测试人员），或用户显式 **`--qa <MIS>`**。实现上**从不**读取需求的 **`assigned`、负责人、提出人、创建人**等字段作为 QA。
- **助手（Agent）**：新建标准交付时，若**没有**从需求解析到有效测试人员（即无可用 `qas`），用户也**没有**明确提供 QA，则**必须向用户索要**具体测试人员 MIS（或请其先在 Ones 需求上维护测试人员后再创建）。**严禁**用需求负责人、默认 RD/当前用户等顶替 QA。

### 交付场景 `-e`（默认自动）

未传 `-e`：请求 `getPiplineConfig`，`rdSelfTestEnv`→`0/1`→test，`2`→有 Ones 需求泳道则 swimlane（补 `swimlane-id`）否则 new-swimlane（内部 `createCargo`），`3`→staging，`5`（liteSet）暂映射 test。  
已传 `-e`：**不**调 `getPiplineConfig`，环境字段仅由 [场景映射](#delivery-create-场景) 固定。  
详见下文「delivery create 场景」。

### jiraTask：Ones 站与 FSD 站链接

**接口约定**：`addTestApply` / `editTestApply` 的 `jiraTask` 为 **ones.sankuai.com** 工作项详情 URL。

**FSD 前台链接**（仅 host 不同）：`https://fsd.sankuai.com/ones/{requirement|task|defect}/detail/<issueId>`。

**CLI**：`-j` 为 fsd 域名且为上述路径时，提交前将 host 换为 `ones.sankuai.com`，路径与 query 保留。`requirement-branches` 等解析 `issueId` 同样支持该形态。

**仍支持**：传统 ones 链接，以及 `-i`/`--ones-id` 由 CLI 拼标准 Ones URL。**`delivery edit`** 传入 FSD 形态 `-j` 时同样先规范化。

---

<a id="sec-iteration-fsd-url"></a>

## 迭代与 FSD 链接（交付 vs 测试计划）

> 下列规则为**个性化路由**（用户说「迭代」并粘贴 FSD 链接时），写在本文档，**不写入 SKILL.md 正文**。对齐 **skill-dev** 中路由：提测/交付详情走 **`testApplyDetail/<applyProgramId>`**（如 `IterationTable`、`fsd-delivery-create-for-ed` 创建后跳转）；测试计划详情走 **`/test/detail?testPlanId=`**（如 `fsd-test-plan-detail` `App.vue`、`apply-test-action` 打开测试计划）。

用户口语中的「迭代」可能指 **交付（提测单）** 或 **测试计划**，**不能**仅凭词义二选一；须**先看 URL 形态**再锚定 ID 与 CLI 子系统。

### 链接形态与 ID 含义

| 链接形态 | 页面含义 | 提取的 ID | CLI 锚定 |
|----------|----------|-----------|----------|
| `…/testApplyDetail/<正整数>` 或路径含 **`/testApplyDetail/`** | **交付（提测）详情页**；路径段为 **`applyProgramId`**（列表、接口里与 **`testApplyId`** 同值） | 路径最后一段 | **交付上下文**：`fsd delivery … -i <applyProgramId>`（如 `status`、`trigger`、`fst`） |
| `…/test/detail?testPlanId=<正整数>` 或 query 含 **`testPlanId=`** | **测试计划详情页** | query **`testPlanId`** | **测试计划上下文**：`fsd test … --id <testPlanId>`、`fsd fstPlan … -i <testPlanId>` 等（见 [test-plan.md](test-plan.md)） |
| `…/fsdIteration/detail/<正整数>` | **迭代详情页**（与交付/测计划不同主键） | 路径最后一段 **`iterationId`** | 缺陷列表：`fsd defect list --iteration <id>`（见 [defect.md · 迭代详情页](defect.md#sec-defect-iteration-detail)） |
| `…/deliveryDetail/<数字>` | **交付计划**（另一类列表/详情入口，非 `testApplyDetail`） | 多为 **`deliveryPlanId`** 等列表维度字段 | 与 **`applyProgramId`** 语义不同；操作交付能力仍以详情/列表返回的 **`applyProgramId`** 为准，勿与 `testPlanId` 混用 |
| `…/deliveryDetailMed/<数字>` | **客户端交付** | **`medId`** | 见 [客户端交付](#客户端交付deliverydetailmed) |

### 助手决策要点

1. **用户只给「迭代」+ 一条链接**：按上表解析；**不要**把 `testApplyDetail` 路径里的数字当成测试计划 ID，也**不要**把 `testPlanId` 当成 `applyProgramId`。
2. **同一消息里两种链接并存**：分别提取 **`applyProgramId`** 与 **`testPlanId`**，对应交付侧与测试计划侧命令，**禁止交叉混用**。
3. **路径 `…/fsdIteration/detail/<id>`**：该 `<id>` 为**迭代 ID**；用户要查该页**缺陷列表**时 → **`fsd defect list --iteration <id>`**（**不要**用 `-p` 误当成测试计划 ID）。详见 [defect.md · 迭代详情页缺陷列表](defect.md#sec-defect-iteration-detail)。
4. **与 SKILL 术语**：SKILL 中 **「迭代」不等同于「交付」**；是否指交付、测试计划或其它，**以本条链接形态与对话上下文为准**。**URL 为 `test/detail?testPlanId=` 时，上下文是测试计划**；**URL 为 `testApplyDetail/<id>` 等时，上下文是交付（`applyProgramId`）**。

### 示例

```text
# 交付（提测详情）— applyProgramId = 397771
https://fsd.sankuai.com/testApplyDetail/397771
  → fsd delivery status -i 397771 --pretty

# 测试计划详情 — testPlanId = 73594
https://fsd.sankuai.com/test/detail?testPlanId=73594
  → fsd test detail --id 73594 --pretty
```

---

## 客户端交付（deliveryDetailMed）

> 下列规则为**个性化路由**（Med / 服务端交付 ID 区分），写在本文档，不写入 SKILL.md 正文。

### 识别

- FSD 链接路径含 **`/deliveryDetailMed/<medId>`**（示例：`https://fsd.sankuai.com/deliveryDetailMed/42179?deliveryTab=delivery&...`）表示 **客户端交付**（`DeliveryPlan.medId`，与 ED/列表中「客户端」一致）。
- **`medId` 不是** `testApplyDetail/<id>` 里的 **`applyProgramId`**。对客户端页误用 `fsd delivery status -i <medId>` 会查错对象。

### 查关联测试计划 ID

后端 **`DeliveryPlan`** 上 **`testPlanId`** 为 FSD 测试计划主键。客户端场景应调用：

| 项目 | 说明 |
|------|------|
| 接口 | `GET /api/qa/v1/delivery/getDeliveryPlanByMedId` |
| 查询参数 | **`medId`**：与 URL 路径 `deliveryDetailMed` 后数字一致 |
| 成功响应 | `code === 0`，**`data.testPlanId`** 即为测试计划 ID（可能为空） |

CLI（推荐，自动带 SSO）：

```bash
fsd delivery med-test-plan -m 42179 --pretty
# 或
fsd delivery med-test-plan -u "https://fsd.sankuai.com/deliveryDetailMed/42179?deliveryTab=delivery" --pretty
```

拿到 `testPlanId` 后，再使用测试计划相关命令，例如 `fsd test detail --id <testPlanId>`（以当前 CLI 测试模块为准）。

### 与 skill-dev / baseapi 的对应关系

- 前端路由：`deliveryDetailMed/:medId`（如 `fsd-testapply-list` 中 `path: /deliveryDetailMed/${medId}`）。
- 数据模型：`DeliveryPlan.medId`、`DeliveryPlan.testPlanId`（见 baseapi `DeliveryPlan` / `DeliveryPlanService.getByMedIds` 等）。
- 自助排查可用 curl（需自行替换 Cookie；**生产排查优先用 `fsd delivery med-test-plan`**）：

```bash
curl -sS -G 'https://fsd.sankuai.com/api/qa/v1/delivery/getDeliveryPlanByMedId' \
  --data-urlencode 'medId=42179' \
  -H 'accept: application/json' \
  -H "Cookie: <登录后的 ssoid>"
```

### AI 决策要点

- 用户给出 **`deliveryDetailMed`** 链接或明确 **Med / 客户端交付**：查测试计划 → **`fsd delivery med-test-plan`**（或 `-m`），**不要**用 `delivery -i` 传入 medId。
- 用户给出 **`testApplyDetail`** 链接：`-i` 使用 **`applyProgramId`**，与上条区分。
- 用户给出 **`test/detail?testPlanId=`** 链接：按 [迭代与 FSD 链接](#sec-iteration-fsd-url) 走测试计划命令，**不要**用 `delivery -i` 传入该数字。

---

## delivery create 场景

| 场景 | testBranch 默认 | 说明 |
|------|----------------|------|
| `test` | qa（或 staging，见下） | 骨干；未传 `-e` 且非 `--no-auto` 时与 `getPiplineConfig` 对齐；显式 `-e test` 时固定下行映射 |
| `new-swimlane` | qa | 新建泳道 |
| `swimlane` | qa | 已有泳道（需 swimlaneId） |
| `staging` | staging | 备机 |

场景映射（**`--no-auto`、已显式 `-e`、`getPiplineConfig` 失败或未请求**时按左列固定）：
- `test` → rdSelfTestEnv=0, env=test
- `new-swimlane` → rdSelfTestEnv=2, mavenType=cargo, env=test
- `swimlane` → rdSelfTestEnv=2, mavenType=cargo, swimlaneId=传入, env=test
- `staging` → rdSelfTestEnv=3, env=staging

## 交付类型与场景决策

> AI 快速决策：根据用户表述选择 `fsd delivery create` 参数组合

| 用户表述 | 建议 CLI |
|----------|----------|
| 仅「新建/创建交付」等，未说明类型 | `fsd delivery create`，**不传** `--project-type`；由 `getOnesDetails` 的 `qas` 推断 **projectType** 与 **qa** |
| 同上，且未说明场景 | **不传** `-e`；由 **`getPiplineConfig.rdSelfTestEnv`** 映射 **test / swimlane / new-swimlane / staging**；泳道所需 **`swimlane-id`** 从 Ones **`stackMetaVos`** 补齐 |
| 已明确场景（CLI 将带 `-e`） | **不再请求** `getPiplineConfig`；自测环境仅按场景固定映射 |
| 明确「RD 自测」「自测交付」或 project-type 1 | 追加 **`--project-type 1`** |
| 需与自动推断、getPiplineConfig 完全脱钩 | **`--no-auto`**（固定类型与骨干映射；不调 getOnesDetails / getPiplineConfig） |
| 明确「标准交付」「QA 参与」或 project-type 4 | 追加 **`--project-type 4`**；若 Ones **有**有效 `qas` 可自动拼 **qa**；若 **无** `qas`，须让用户提供 **`--qa <MIS>`** 后再执行（勿默认当前用户） |
| 标准交付且需求无 QA、CLI 报错 | 说明原因并请用户给出 **`--qa <MIS>`**（或 Ones 上先配置测试人员）；**禁止**用需求负责人等代替 |
| 未传 `--technical-solution` | CLI 经 **`listDocs`（PRODUCT_SCHEME）** 以「`title` + 空格 + `wikiUrl`」逐行拼接；失败或未配置时回退为「标准交付」 |

---

### delivery create 输出

创建成功后，默认输出 JSON，`--pretty` 输出人类可读格式。字段与入参、API 保持一致（英文命名）：

| 字段 | 说明 |
|------|------|
| id / applyProgramId | 创建成功后与 **`applyProgramId` 一致**（ED 交付主键）；后续 `fsd delivery -i`、详情 URL 等均用此值 |
| name | 交付名称 |
| rd | 创建人 MIS |
| jiraTask | Ones 链接，关联需求 |
| jobName | 首条服务的名称（与 `jobs[0].jobName` 一致，便于单服务脚本兼容） |
| developBranch | 首条服务的开发分支（与 `jobs[0].developBranch` 一致） |
| jobCount | `jobList` 条数（含单服务） |
| jobs | **全量** `{ jobName, developBranch, testBranch }[]`，与提交 `addTestApply` 的 jobList 一一对应；默认 JSON 与 `--pretty` 均展示 |
| env | 交付场景：test/swimlane/staging |
| stackUuid | 泳道场景时返回，泳道 stackUuid（新建泳道从 createCargo 返回的 stackUuid 获取） |
| jobsFromRequirementBranchView | 可选；摘要 JSON 中当 jobList 来自 requirementBranchView 时为条目数 |

---

## requirementBranchView 与多服务 jobList

创建交付（非 `--no-auto`）时 CLI 分页调用 **`requirementBranchView/{issueId}`** 拉取需求侧分支，用返回项的 **`jobName` + `branch`** 组装多服务 **`jobList[].developBranch`**；默认 **`excludeSpecialBranch=true`**，分页直至穷尽 `total`。

---

## 多工作区工程创建交付

**触发场景**：用户明确指定要将多个工程加入同一个交付（如「把工作区里的几个工程都加进来」「把应用A和B加进交付」等）。`requirementBranchView` 不保证覆盖用户指定的所有工程，需按用户意图补全。

**流程**：

1. `fsd delivery create -i <issueId> --pretty`（从任一工程目录执行）
2. `fsd delivery edit -i <id> --add-jobs-json '[{"git":"<ssh地址>","developBranch":"<分支>"},...]' --pretty`（追加其余工程；`git` 字段 CLI 内部自动校验并解析 jobName，无 FSD 应用则报错退出；也可用 `jobName` 或 `appkey` 替代 `git`）
3. `fsd delivery detail -i <id> --pretty`（确认所有服务已加入）

---

## delivery requirement-branches

```bash
fsd delivery requirement-branches -j "https://ones.sankuai.com/..." --all --pretty
fsd delivery requirement-branches -i 92461322 -p 1 --page-size 20
```

| 参数 | 说明 |
|------|------|
| -j / -i | Ones 链接或 issueId，二选一 |
| --all | 分页拉全量（与 create 使用的拉取方式一致） |
| -p / --page-size | 未加 `--all` 时单页查询 |
| --include-special-branch | 传则 **excludeSpecialBranch=false** |
| --pretty | 人类可读列表 |

---

## delivery ones 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| -n, --name | string | 否 | 按名称模糊过滤 |
| -v, --verbose | - | 否 | 输出完整 JSON（可先配合 `--developing-only`、`--max`） |
| --pretty | - | 否 | 人类可读（序号+名称+onesUrl），**面向终端** |
| --pick-json | - | 否 | **助手推荐**：结构化 JSON，优先「开发中」；`--page`/`--page-size` 翻页，`--all` 输出全部候选 |
| --developing-only | - | 否 | 仅保留状态含「开发中」（与 `-v`/`--pretty` 联用） |
| --max | number | 否 | 与 `-v`/`--pretty` 联用限制条数（非 `--all` 且无翻页时） |
| --page | number | 否 | 页码从 1 起（`--all` 时忽略） |
| --page-size | number | 否 | 默认 15；`--pick-json` 可设为 5～10 |
| --all | - | 否 | 一次输出全部（`-v`/`--pretty`）；与 `--pick-json` 联用时 `items` 含全量候选 |

**`--pick-json`**：`items`（name/type/onesUrl/status，优先开发中）、分页字段、`hint` 等。分支无法解析 Ones 时用 **`fsd delivery ones --pick-json`** 展示 `items`，选定后 `onesUrl`→`-j`；勿用 `--pretty` 让用户在终端挑。

---

## delivery edit 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| -i, --id | number | 是 | 交付 ID：须为 **`applyProgramId`**（与 `testApplyId` 同值）。**`deliveryId` 不是交付 ID**；勿用列表中的 **`id`** / **`deliveryId`** 代替 |
| -j, --jira-task | string | 否 | Ones 或同路径 fsd.sankuai.com 详情链接（与 [create · jiraTask](#jirataskones-站与-fsd-站链接) 一致，提交前规范化为 ones 域名） |
| -n, --name | string | 否 | 交付名称 |
| -b, --branch | string | 否 | 开发分支 |
| -e, --scene | string | 否 | 场景：test/new-swimlane/swimlane/staging |
| -u, --swimlane-id | string | 否 | 泳道 ID（-e swimlane 时必填） |
| --online-time | string | 否 | 预计上线时间 yyyy-MM-dd HH:mm:ss |
| --test-branch | string | 否 | 测试分支 |
| --cc-grouper | string | 否 | 抄送人 MIS |
| --pipline-template | number | 否 | 流水线模板 |
| --jobs-json | JSON / @文件 | 否 | 与 `getJobList` 按 **数组下标 / jobName** 合并的补丁列表（长度与语义见下节；会替换为补丁条数对应的列表，慎用）。**传 `[]` 表示清空交付下全部关联应用（jobList 提交为空）** |
| --add-jobs-json | JSON / @文件 | 否 | 在 **当前** jobList 上 **追加** 新服务或 **按 jobName 更新** 已有行；支持 **appkey / octoAppKey** 省略 jobName；**未写 `developBranch` 时新增行 `developBranch` 为空串**（与 ED 创建页「先选应用、分支可后补」一致） |

编辑：拉详情+`getJobList` 合并后 **`POST .../testapply/edit`**（创建仍 `.../v2/testapply/add`）。

### 编辑交付 · 关联服务（jobList）与 octoAppKey

| 字段 | 含义 |
|------|------|
| `jobName` | 服务名；新增行可无 `developBranch`（提交 `""`） |
| `developBranch` / `testBranch` | 开发/测试分支；新增未传 `testBranch` 时 CLI 对齐首条非空 |
| `id` / `applyJobId` | 已有行主键；新增 `null` |
| `isAddpr` / `prTobranch` / `prReviewers` | 有分支且走 PR 时使用 |

**`--add-jobs-json`**：数组；每项需 `jobName` 或可解析的 `appkey`/`octoAppKey`。新增无 `developBranch` 键 → `""`；同名 `jobName` 仅在有 `developBranch` 键时更新分支。**只追加用 `--add-jobs-json`**，勿与按长度合并的 `--jobs-json` 混用致截断。

```bash
# 仅按 octoAppKey 追加应用，开发分支为空（与页面「新增应用」未选分支一致）
fsd delivery edit -i <applyProgramId> --add-jobs-json '[{"octoAppKey":"com.sankuai.xxx.yyy"}]'

# 追加并指定分支
fsd delivery edit -i <applyProgramId> --add-jobs-json '[{"jobName":"my-service","developBranch":"feature/foo"}]'
```

编辑成功后勿自动串联 trigger/status/deploy；待用户明确要求再执行。

---

## delivery delete 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| -i, --id | number | 是 | 交付 ID：须为列表 **`applyProgramId`**（**`deliveryId` 不是交付 ID**；勿用列表 **`id`/`deliveryId`**） |

删除交付为不可逆操作，需为提测相关人。

---

## delivery list 参数说明

### 查询范围（与我相关）

**无论传入何种筛选条件**（环境、服务名、名称、状态、时间、RD/QA MIS、`cardType` 等），列表查询**始终**在 **`relatedMe: true`** 下执行，即**仅当前登录用户在 FSD 中「与我相关」的交付集合**；其它条件只在该集合内进一步筛选，**不会**变成他人交付、全量或按组织拉取。接口请求前 CLI 会再次强制 `relatedMe=true`。

默认 JSON 响应中含 **`relatedMe: true`** 与 **`scopeDescription`**（人类可读范围说明）；**`--pretty`** 时会在表格化 JSON 前输出一行 **【范围说明】**。助手向用户总结列表时**必须**明确：结果是「在与我相关的交付中按条件筛选的」，**不得**省略或暗示为全量/团队视图。

### 查询限制（组织 / orgId）

**不支持**通过 `--org-id`、`--rd-business`、`--qa-business` 按组织或部门 orgId 拉交付列表。命令行若传入上述任一参数，CLI 会**打印说明并退出**（**不调** `getDeliveryPlanList`、**不返回**列表数据）。助手遇到「按组织 / orgId / 部门查交付」等意图时，应直接说明该限制，并建议改用交付名称、服务名、状态、时间、**创建人**、RD/QA MIS 等「与我相关」内筛选，或引导用户到 **FSD 前台**查看团队/组织维度数据；**勿编造交付列表**。

### 创建人 vs RD（助手须区分）

- **`--create-by <MIS>`**：对应接口 **`createBy`**，筛「**谁创建**了这条交付」（与 skill-dev 列表页「创建人」一致）。
- **`--rd <MIS>`**：对应接口 **`rd`**，筛交付单上的 **参与研发 / RD**，与创建人**不一定相同**（例如代建、转交场景）。

用户说「查看 **某人创建的** 交付」时，必须使用 **`--create-by`**，**禁止**用 `--rd` 代替。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| -p, --page | number | 否 | 页码，默认 1 |
| -e, --env | string | 否 | 环境筛选：test/liteSet/staging |
| -a, --job | string | 否 | 服务名（jobName）筛选 |
| -n, --name | string | 否 | 交付名称模糊查询（对应接口 `name`） |
| -S, --status | string | 否 | **状态筛选**：逗号分隔，见下表「状态码」；支持中文/英文别名；对应后端 `List<Integer> status`（HTTP 为多组 `status=`） |
| --source | string | 否 | 来源 `source`，逗号分隔，默认 `0,1,2` |
| --card-type | 1～6 | 否 | **卡片快捷筛选**（`cardType`）；传入后由服务端按卡片规则设置 status/时间窗 |
| --project-type | number | 否 | `projectType`：1=RD自测，4=标准交付 |
| --create-by | mis | 否 | 按 **创建人** MIS 筛选（`createBy`）；**查某人创建的交付用此项** |
| --rd | mis | 否 | 按 **参与研发（rd）** MIS 筛选；**不是**创建人，参见上节 |
| --qa | mis | 否 | 按参与 QA MIS 筛选（`qa`） |
| --recent | string | 否 | **快捷时间筛**：自动设置 `createTime`/`createTimeEnd`（从「当前时刻」往前推）。如 `1d`（24 小时）、`24h`、`7d`、`1w`、`30d`、`1m`（30 天）、或纯数字天数 `3`。与 `--create-time` / `--create-time-end` **互斥**。成功时 JSON 顶层含 **`_meta`** 回显换算结果 |
| --create-time / --create-time-end | string | 否 | 创建时间区间 `yyyy-MM-dd HH:mm:ss`（精确控制时用；与 `--recent` 二选一） |
| --online-time-start / --online-time-end | string | 否 | 预计上线时间区间 |
| --online-tomorrow | flag | 否 | 预计上线时间为**明天**（本地日历日 00:00～23:59）；自动填上线时间区间。与 `--online-time-start` / `--online-time-end` **互斥**；成功时 JSON 可含 **`_meta`** |
| --online-use | flag | 否 | 传参 `onlineUse=true` |

需 SSO。后续 `-i`/详情均以 **`applyProgramId`** 为准，勿用列表 `id`。

### 交付状态码（DeliveryStatusEnum）

| 码 | 含义 |
|----|------|
| 0 | 开发中 |
| 10 | 提测打回 |
| 20 | 交付QA |
| 25 | 待测试 |
| 30 | 测试中 |
| 50 | 测试完成 |
| 55 | 待上线 |
| 60 | 已上线 |
| 65 | 已挂起 |
| 70 | 已终止 |

```bash
fsd delivery list -S 0,30,55
fsd delivery list --recent 1d
fsd delivery list --card-type 2 --project-type 1
fsd delivery list --create-by zhangsan
fsd delivery list --online-tomorrow --pretty
```

---

## delivery list 输出规范

### 自测环境展示（rdSelfTestEnv）

`getDeliveryPlanList` 列表行**常常不返回** `rdSelfTestEnv`。CLI 行为：**优先**行内 `rdSelfTestEnv` / `rd_self_test_env`；缺失时与同列表页 **skill-dev `IterationTable#getTagInfo`** 一致推断数值：`env=staging`→3（备机），`env=liteSet`→5，`env=test` 且无泳道标识（`stackUuid`/`swimlaneId`/`stackName` 皆空）→0（Test 骨干），否则 test 场景→2（泳道）。再按数值映射为 **`rdSelfTestEnvLabel`**（与创建页 `CONST_OPTIONS` 一致：`0/1`→Test（骨干），`2`→泳道，`3`→备机（staging），`4`→已有泳道，`5`→liteSet）。

### `fsd delivery list --pretty` 字段（英文键）

与接口/脚本一致使用**英文键**，便于程序解析。每行大致含：`applyProgramId`、`name`、`projectType`、`projectTypeLabel`、`status`、`statusLabel`、`env`（原样）、`rdSelfTestEnv`（解析后的数值，未知为 `null`）、`rdSelfTestEnvLabel`、`rd`、`qa`、`createBy`、`onesSummary`、`detailUrl`。

助手展示：**先复述或引用 `scopeDescription`（或「与我相关」范围）**，再列当前页；向用户说明自测环境时以 **`rdSelfTestEnvLabel`**（及必要时 `rdSelfTestEnv`）为准，勿仅用 `env` 代替映射结果。勿展开 `userMessage` 等；首次仅一页，翻页待用户要求。若用户要求按组织 / orgId / 部门列交付，**不得输出列表数据**，须说明上文「查询限制（组织 / orgId）」并给出替代方式。

---

## delivery status 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| -i, --id | number | 是 | 交付 ID：须为列表 **`applyProgramId`**（**`deliveryId` 不是交付 ID**；勿用列表 **`id`/`deliveryId`**） |
| -t, --type | number | 否 | 类型：0 流水线，1 自测联调，默认 0 |
| -v, --verbose | - | 否 | 与默认一致输出 JSON（保留兼容） |
| --pretty | - | 否 | 人类可读；展示内容见 [delivery status 展示规则](#delivery-status-展示规则) |

默认与 `-v` 均输出 **结构化 JSON**（先 `getTestApplyDetail` 再按需拉 `queryTestApplySummaryV2` / 测试计划接口）：含 `projectType`、`deliveryStatus`、`analysisSource`、`deliveryProgress`、`testPlanFromDetail`（标准交付时可能非空）、`testPlans`（可能为空）等，与 `delivery prep` 数据源路由一致，见下文展示规则。

---

## delivery detail 参数说明

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| -i, --id | number | 是 | 交付 ID：须为列表 **`applyProgramId`**（**`deliveryId` 不是交付 ID**；勿用列表 **`id`/`deliveryId`**） |
| -v, --verbose | - | 否 | 摘要中附加备注、提测建议、计划 ID、MCC/工程数量等（仍不含 `userMessage`） |
| --pretty | - | 否 | 人类可读摘要（创建/上线/人员/环境/Ones/服务列表） |

底层 `getTestApplyDetail`；CLI 输出摘要 JSON（已剔 `userMessage` 等大块）。**关键字段**：`applyProgramId`/`id`、`name`、`status`、`env`、`rd`/`qa`、`projectType`、`jiraTask`/`ones`、`jobs`、`swimlaneId`/`stackUuid`、`detailUrl`。

---

## gate 准出检测

### 命令

```bash
fsd delivery gate -i <applyProgramId>
fsd delivery gate -i <applyProgramId> --pretty
fsd delivery gate -i <applyProgramId> -v
# 仅快照准出、不准出也不触发自测流水线（旧行为）
fsd delivery gate -i <applyProgramId> --no-auto-trigger
# 关闭 stderr 进度（默认会输出多服务触发步骤与流水线轮询详情）
fsd delivery gate -i <applyProgramId> --silent-progress
```

| 参数 | 说明 |
|------|------|
| `-i, --id` | 交付主键（`applyProgramId`） |
| 默认行为 | 三步自动复检：① skip 非卡点失败步骤 → ② 未构建则主干部署 → ③ 仍不准出则 `triggerPipeline`（同 `delivery trigger`）+ 轮询终态 + 再判 |
| `--no-auto-trigger` | 只拉一次准出，不准出也不触发流水线 |
| `--silent-progress` | 不向 stderr 打印进度 |
| `--pretty` | 人类可读；失败时追加「失败节点摘要」与处理建议 |
| `-v, --verbose` | 完整 payload（含 `rawBefore`/`rawAfter`） |

### 复检 JSON（默认流程且首次 `canAccess: false` 时）

| 字段 | 说明 |
|------|------|
| `mode` | `trigger_failed` / `still_blocked_after_trigger` / `cleared_after_trigger` / `cleared_after_skip` / `cleared_after_auto_deploy` / `skip_failed` |
| `canAccess` | 再次检测后是否准出 |
| `assistantHint` | 给助手的下一步说明 |
| `gateReportBefore` / `gateReportAfter` | 触发前/后的准出报告 |
| `pipelineFailure` | 失败终态摘要（`jobs[].failedSteps`），供决策重跑/skip/修代码 |
| `autoDeployResults` | 若执行过主干部署：逐服务摘要 |
| `remediationPlan` | `gateNodeKeywords`（触发的节点）、`skipApplied`、`autoDeploy` 等 |

需 `fsd-sso login`。默认自动复检（SKILL.md #11）；仅用户明确要快照时加 `--no-auto-trigger`。

**getJobList**：`GET .../getJobList?testApplyId=` → `canAccess`、`cannotAccessReason`、`jobList[].stepMessage`（`stepName`、`status`、`isPoint` 等）。

### 单次检测 `report`（已准出或 `--no-auto-trigger` 且非 `-v`）

| 字段 | 说明 |
|------|------|
| `testApplyId` | 交付 ID |
| `canAccess` | 是否已准出 |
| `cannotAccessReason` | 后端汇总原因 |
| `failedByJob` | 数组；每项含 `jobName`、`developBranch`、`testBranch`、`jobStatus`、`jobMessage`、`failedSteps` |
| `failedSteps` | 该服务下 **`status` 非 success/skip** 的步骤 |
| `aiHint` | 固定行为说明文案 |

**准出后**：`projectType` **4**→`deliver-qa`；**1**→`check`→`finish`（勿混用）。详 SKILL.md。`gate`≠`status` 语义。

---

## deliver-qa 交付 QA

**仅标准交付（`projectType === 4`）**。RD 自测走 `check`/`finish`。

### 命令

```bash
fsd delivery deliver-qa -i <applyProgramId>
fsd delivery deliver-qa -i <applyProgramId> --dry-run
fsd delivery deliver-qa -i <applyProgramId> --jobs-json '[{"jobName":"...","developBranch":"...","modules":[],"testBranch":"..."}]'
fsd delivery deliver-qa -i <applyProgramId> --jobs-json @jobs.json --pretty
```

| 参数 | 说明 |
|------|------|
| `-i, --id` | 交付主键，与列表 **`applyProgramId`**、接口 **`testApplyId`** 一致 |
| `--jobs-json` | JSON 字符串或 **`@文件路径`**；每项为 **`ApplyJobVo`** 子集（见下）。**不传**时由 **`getJobList`** 自动组装 `jobName` / `developBranch` / `testBranch` / `modules: []` |
| `--dry-run` | 只打印将提交的 JSON 数组，**不**调接口 |
| `-v, --verbose` | 输出完整接口返回 |
| `--pretty` | **`data` 非空**：接口表示同步完成，输出「已完成」类结论；**`data` 为空**：表示需异步跑交付流水线，CLI **先不下成功/失败结论**，与 **`delivery trigger --pretty`** 同源调用 **`waitForLatestPipelineTerminal`** 轮询直至记录终态，再输出 ✅/❌ 或超时说明 |
| `--no-wait` | 仅与 **`--pretty`** 联用：当 **`data` 为空**（流水线异步）时**不轮询**，只提示到详情/records 查看，**不下终态结论**（供脚本快速返回） |

需 `fsd-sso login`。**CLI 在调用交付 QA 接口前会强制校验**：`projectType === 4` 且 **`getJobList` 的 `canAccess === true`**（未准出则直接报错退出，与前端「交付 QA」前置一致）；`--dry-run` 同样会先校验准出再打印 JSON。接口约定：`data` 有值=同步完成；`data` 空=异步触发流水线（**`--pretty` 默认会等到流水线结束再下结论**）。

### 无关联服务（空 jobList）

当 **`getJobList` 返回的 `jobList` 为空、缺失，或没有任何带有效 `jobName` 的条目** 时，视为「交付未挂服务」，与前端一致：**不再要求准出**（`canAccess` 校验跳过），可直接调用 **`deliverQaWithFsd`**，请求体为 **空数组 `[]`**（未传 `--jobs-json` 时由 CLI 自动如此组装）。有至少一条有效服务时，仍须 **`canAccess === true`** 才能交付 QA。

---

## delivery fst（交付 FST 自动化）

在**交付**维度查询/触发 FST 自动化，与 **`fsd fstPlan`**（`source=testPlan`、测试计划 ID）区分：本组命令固定 **`source=testApply`**，**`businessId` = 交付 `applyProgramId`**。接口约定与 `.claude/skills/autoTest` 一致。

### 命令

```bash
# 1) 查询交付下已绑定的 FST 计划
fsd delivery fst list -i <applyProgramId>
fsd delivery fst list -i <applyProgramId> --pretty
fsd delivery fst list -i <applyProgramId> -v

# 2) 触发（env、stackUuid 默认来自 getTestApplyDetail，可用 --env / --stack-uuid 覆盖）
fsd delivery fst trigger -i <applyProgramId>
fsd delivery fst trigger -i <applyProgramId> --plan-ids 19887,19888 --pretty
fsd delivery fst trigger -i <applyProgramId> --ips 10.x.x.x,10.x.x.x

# `--pretty`：提交成功后内置轮询 `queryFstDetail`，直至各计划 `success` / `fail` / `skip`（间隔与 `waitForLatestPipelineTerminal` 默认一致：首次前 2s，之后每 3s）；非 `--pretty` 仅输出 JSON（含 recordId），不阻塞。

# 3) 查询一次 trigger 返回的 recordId 对应的执行结果
fsd delivery fst result -r <recordId>
fsd delivery fst result -r <recordId> --pretty

# 4) 终止正在跑的单次 FST 执行（与页面「终止自动化」同源接口）
fsd delivery fst stop --plan-id <FST planId> --execute-id <fstExecuteId>
# 建议带交付上下文，避免误停其它业务下的同 planId：
fsd delivery fst stop -i <applyProgramId> --plan-id <FST planId> --execute-id <fstExecuteId> --pretty

# 5) 重试已执行过的 FST（与页面「重试」同源：body 仅 retryVo）
fsd delivery fst retry --plan-id <planId> --execute-id <fstExecuteId>
fsd delivery fst retry -i <applyProgramId> --plan-id <planId> --execute-id <fstExecuteId> --pretty
fsd delivery fst retry --items "19887:2708362,19888:2708400"
fsd delivery fst retry --payload '{"retryVo":[{"planId":19887,"fstExecuteId":2708362}]}'
```

| 子命令 | 说明 |
|--------|------|
| `fst list` | `GET /api/qa/v1/fst/queryFst?businessId=<交付ID>&source=testApply`；JSON 默认 `{ total, list, source, businessId }`；`-v` 附带 `delivery`（详情原始 data）与 `queryFstData` |
| `fst trigger` | `POST /api/qa/v1/fst/triggerFst`；body 含 `businessId`、`source=testApply`、`env`、`stackUuid`、`fstPlanInfo[]`（`planId` / `planType` / `ips`）。某计划 `needMachine` 且未带 IP 时：优先 `--ips`，否则 `queryHostListV2` 自动取机（与 fstPlan trigger 同源）。**`--pretty`** 时在返回 `recordId` 后继续轮询 **`GET queryFstDetail`** 直至终态，行为对齐 `delivery trigger --pretty` |
| `fst result` | `GET /api/qa/v1/fst/queryFstDetail?recordId=`（`recordId` 为 trigger 响应 **`data`**） |
| `fst stop` | **`GET /api/FST/fst/fstPlan/stopPlan`**，query：`fstPlanId`、`fstRecordId`。CLI 用 **`--execute-id`** 传 **`fstRecordId`**（与 **`queryFstDetail` 每行里的 `fstExecuteId`**、提测详情页 URL 的 **`fstExecuteId`** 一致）。**`-i <applyProgramId>`** 可选：传入则先校验该 `planId` 出现在本交付的 `queryFst` 列表中，防止误操作 |
| `fst retry` | **`POST /api/qa/v1/fst/retryFstPlan`**，body：`{ retryVo: [{ planId, fstExecuteId }, ...] }`。**`planId`** 来自 **`queryFst`**；**`fstExecuteId`** 来自 **`queryFstDetail`** 对应行（与前端 `fsd-common-auto` 勾选重试一致）。支持 **`--plan-id` + `--execute-id`**、**`--items`**（`planId:fstExecuteId` 逗号分隔）、**`--payload`**。**`-i`** 可选：校验各 `planId` 已绑定本交付 |

需 **`fsd-sso login`**。

### 终止自动化 vs 跳过卡点

| 意图 | 命令 |
|------|------|
| 正在执行中，希望**停掉当前这次 FST 跑批**（与前端「终止自动化」一致） | **`fsd delivery fst stop`**（或测试计划侧 **`fsd fstPlan stop`**） |
| 正在执行中，希望**停掉交付自测流水线**（整链/构建部署等，按 **eventId**） | **`fsd delivery stop-pipeline -e <eventId>`** → [delivery stop-pipeline](#delivery-stop-pipeline终止自测流水线) |
| 执行已结束但未达准出，希望**在准出上跳过 FST 卡点** | **`fsd fstPlan skip`**（测试计划维度）；交付维度卡点策略见 gate / 各卡片说明 |
| 已跑过一批，希望**对失败/需重跑的记录点「重试」**（非首次触发） | **`fsd delivery fst retry`** 或 **`fsd fstPlan retry`**（与 **`trigger`** 不同：retry 须带 **`fstExecuteId`**） |

**如何拿到 `--execute-id`：** 对应当前跑批，在 **`fsd delivery fst result -r <trigger 返回的 recordId> --pretty`** 的输出里查看各计划的 **`fstExecuteId`**；或从提测详情页自动化报告 URL 的 **`fstExecuteId=`** 读取。

### 与 fstPlan / delivery trigger 的关系

| 场景 | 命令 |
|------|------|
| 交付 ED 卡片上的「自动化」、按交付 ID 跑 FST | **`fsd delivery fst`** |
| 测试计划准出「自动化测试」、按测试计划 ID | **`fsd fstPlan`**（见 test-plan 参考） |
| 跑整条交付自测流水线（含构建部署等节点） | **`fsd delivery trigger`** |

---

## 交付正常流程

> 遵循 SKILL.md 核心规则 #8（禁止返回 URL）。

`create --pretty` → `gate -i <id> --pretty`（勿 `--no-auto-trigger`）→ 4 型 `deliver-qa` / 1 型 `check`→`finish`；未准出则在 gate 内或再 `trigger`/`trigger-retry`/`skip-steps` 后重 `gate`。**RD 自测**下仅执行 `check`/`finish` 时，若 getJobList 未准出，CLI **默认**会再跑与 **gate** 相同的自动卡点处理后再复检（见 [自测完成流程](#自测完成流程)）。`status` 仅辅助。Ones 解析失败：`ones --pick-json`→对话选 `onesUrl`→`-j`。

---

## delivery status 展示规则

当用户**查看交付状态**时，助手应依据本节的**分支规则**解读 `fsd delivery status` 的 JSON 或 `--pretty` 输出。**勿将本节写入 SKILL.md。**

对齐 **skill-dev** / **baseapi** `DeliveryStatusEnum`：`20` = 交付QA（RD 已提交 QA 侧，**尚待 QA 接收提测**）；`25` = 待测试（**QA 已接收**后的阶段）及 `30/50/55/60` 等均为提测已受理之后的状态。

### 分支（与 `delivery prep` 一致）

1. **`projectType = 1`（RD 自测）**：只关心 **交付计划进度** → `queryTestApplySummaryV2`（`deliveryProgress.cardMessage`）。`--pretty` 仅展示【交付进度】块，**不**拉测试计划。
2. **`projectType = 4`（标准交付）**：**是否拉测试计划以 `getTestApplyDetail` 返回的 `data.testPlan` 为准**（与 skill-dev 交付详情一致），**不**再以 `status ≥ 25` 或 `planIds` 是否非空作为判定条件（`planIds` 可能为 `null` 而 `testPlan.id` 仍有效）。
   - **`testPlan` 非空且含有效正整数 `id`**：视为已关联测试计划 → **`--pretty` 主展示【测试计划进度】**（对该 `id`：`fsdTestplan/detail` + `queryTestPlanSummary`，算法同 `fsd test progress`）。JSON 含 `testPlans`、`testPlanFromDetail`、`analysisSource: test_plan`；同时仍会拉 `queryTestApplySummaryV2` 供 `prep`/`online-notice` 的「交付侧进度参考」。
   - **`testPlan` 为空、`null` 或 `id` 无效**：仅 **交付计划进度**（JSON 中 `analysisReason` 说明）。
   - **状态码仅作辅助说明**：`status < 25`（含 `20` 交付QA）表示流程上可能仍在「等待 QA 接收」等；与是否展示测试计划进度**解耦**，以接口实际返回的 `testPlan` 为准。

3. **其它 `projectType`**：仅 **交付计划进度**。

### 交付计划进度块（`queryTestApplySummaryV2`）

底层 **`queryTestApplySummaryV2`**：`cardMessage` / `showCard` / `hasNewCard`；其它 key 含 `project`、`houyiV2`、`bcpapi` 等。**`--pretty` 下该块只展示 3 项**（已按 MCC `delivery_card_config` 格式化）：

| 展示名 | key |
|--------|-----|
| 部署 | `deploy` |
| 研发自测代码覆盖率 | `codeCoverage` |
| 自动化测试 | `auto` |

> **NEVER** 展示 project、houyiV2、defectSafety、bcpapi 等其余卡片

---

## 自测完成流程

> ⚠️ 自测完成 = 研发侧操作（`delivery check` + `delivery finish`），与测试计划（`fsd test`）完全无关。禁止用 `delivery status` 判断能否自测完成，必须以 **`delivery check`** 的 **`canFinish`** 为准（底层与页面 RD 视图一致：先以 **`getJobList`** 的 **`canAccess`** 判断准出；前端「确认自测完成」前还会调 **`rdSelfTestFinishCheck`** 做 commit 对比，CLI **`finish` 的 `--force`** 可跳过该校验）。

**触发场景：**「流水线跑完了」/「能否或确认自测完成」→ 直接执行 `check` → `finish`。

### RD 自测：check/finish 内置自动卡点（与 gate 决策树一致）

**适用范围**：仅当交付 **`projectType === 1`（RD 自测）**，且 **`getJobList` 返回 `canAccess === false`** 时；**无关联服务（空 `jobList` / 无有效 `jobName`）时不进入本逻辑**（视为已准出，不跑自动卡点）。标准交付（`projectType === 4`）不走本逻辑，请用 **`fsd delivery gate`** / **`deliver-qa`**（空服务规则与标准交付 **`deliver-qa`** 一致，见上文「无关联服务（空 jobList）」）。

**默认行为**（与 **`fsd delivery gate`** 默认自动复检同源：`runDeliverGateWithAutoTrigger`）：

1. **`fsd delivery check`**：首次拉 **`getJobList`**；若未准出，则依次尝试：**`skipApplySteps`**（仅明确 `isPoint === false` 的非卡点失败）→ 推断缺部署则 **主干部署 executeAuto** → 仍不准出则 **定向/全量 `triggerPipeline`** 并等待终态 → 再拉 **`getJobList`** 复检。
2. **`fsd delivery finish`**（未加 **`--force`**）：先做与上条相同的自动修复再判 **`canAccess`**；仍 false 则退出并提示可再手动 **`gate`**。

**`--no-auto-gate`**：仅拉 **`getJobList`**，不准出时不执行上述自动修复（旧行为）。**`--silent-progress`**：与 **`fsd delivery gate --silent-progress`** 一致。

自动修复后 JSON 含 **`autoGate`**、**`gateRemediation`**；**`-v`** 时可能含较大 raw。

**助手决策树：**

```
fsd delivery check -i <applyId> [--pretty]
  ├─ 首次 canFinish=true → 可 fsd delivery finish -i <applyId>
  ├─ 首次 canFinish=false 且 projectType=1 → 默认内嵌 gate 同序自动修复后再判
  │   ├─ 修复后 canFinish=true → 可 finish
  │   └─ 仍 false → 输出 blockMsg / gateRemediation，再 gate / trigger / skip-steps 后重 check
  └─ projectType≠1 或未知 → 不自动修复（autoGateSkippedReason），标准交付勿用 finish
```

---

## delivery trigger / trigger-retry / check / finish 通过 appkey 部署

> 下列规则为**个性化增强**（通过 octoAppKey 指定部署服务），写在本文档，**不写入 SKILL.md 正文**。

交付自测流水线的触发、重试、检查、完成等操作均支持通过 **`--appkey`** 参数指定目标服务，作为 **`-a, --app`（jobName）** 的替代方式。

### 适用命令

| 命令 | --appkey 参数说明 |
|------|------------------|
| `fsd delivery trigger` | 通过 appkey 指定要触发的服务（与 `-a` 二选一） |
| `fsd delivery trigger-retry` | 通过 appkey 指定要重试的服务（与 `-a` 二选一） |
| `fsd delivery check` | 通过 appkey 检查指定服务的自测完成状态（与 `-a` 二选一） |
| `fsd delivery finish` | 通过 appkey 确认指定服务的自测完成（与 `-a` 二选一） |

### appkey 解析规则

当使用 `--appkey` 参数时：

- **已与 `-i <交付ID>` 联用**：不再执行下列 1–3 的全平台步骤，改为交付内解析（见下第 5 点）。
- **未传 `-i`**：执行下列 1–4。

1. **查询关联服务**：调用 `GET /api/qa/v1/job/listPageAuth`（与 `fsd app find-by-appkey` 同源），传入 `name=<appkey>`
2. **精确匹配**：优先从返回列表中筛选 `octoAppKey` 字段与输入 appkey 精确匹配的服务
3. **唯一性校验**：
   - 若返回 0 个服务：报错提示未找到关联服务
   - 若返回多个服务：报错并列出所有候选 jobName，提示用户改用 `--app <jobName>` 指定
   - 若返回 1 个服务：自动提取 `name` 字段作为 jobName，继续执行部署流程
4. **透明转换（仅无 `-i` 时）**：未同时传交付 ID 时，appkey 在入口经全平台解析为 jobName 后，后续与 `-a` 一致。
5. **与 `-i` 同时传 `--appkey`**：**不**再调用全平台 `listPageAuth` 做唯一 jobName 解析；直接 `getJobList(applyId)` + `getTestApplyDetail(applyId)`，在**该交付 job 列表**内调用 `resolveJobNameFromOctoAppKeyInScope`，**跳过 `getTestApplyByJob`**，避免因当前 git 分支与交付不一致而走错「无交付」或找不到交付。

### 交付内 `-a` 未命中 jobName 时自动按 octoAppKey 解析

在 **已有交付**（能拉到 `getJobList`）且用户传入 **`-a <字符串>`** 时，若该字符串与交付内任一行的 `jobName` **都不相等**，CLI 会再尝试将其视为 **octoAppKey**，在 **当前交付计划 job 列表范围内** 解析唯一 `jobName`（逻辑与创建/编辑交付时 `--add-jobs-json` 使用 `resolveJobNameFromOctoAppKeyInScope` 一致：计划行上 `octoAppKey` 精确匹配，或与 `listPageAuth` 结果求交）。

- **成功**：得到唯一 jobName 后，仅触发该服务，与先 `fsd app find-by-appkey` 再 `-a jobName` 等价，但**不必**用户分两步。
- **失败**：仍报错并列出交付内可用 `jobName`；若 octoAppKey 在计划内命中多条或无法与计划求交，错误信息会说明原因。

> **仅 `--appkey` 且无 `-i`**：入口已解析为 jobName，不再走本节的「`-a` 字符串当 octoAppKey」。**`-i` + `--appkey`**：入口不解析，仅走交付内 octoAppKey 求交（见上节第 5 点）。

### 触发自测与「上次触发」模板（直接部署）

`fsd delivery trigger` 组装 `triggerPipeline` 的 `jobList` 时，会调用 `POST /api/qa/v1/pipline/queryLastTriggerStep` 拉取各服务流水线节点模板（与 ED 执行页一致）。**当用户意图是尽快部署时**，不必先人工查历史部署记录或等「上次触发」数据齐全：

- 若 **`queryLastTriggerStep` 失败**或返回数据中**无可用 `pipelineNode`**，CLI **不再抛错中止**，而是对该服务使用 **`pipelineStepList: []` + `coerceDeploy: true`** 继续调用 `triggerPipeline`（与「无交付」场景下单服务 `triggerPipelineSkill` 的直触发策略一致）。
- 若用户同时指定 **`-n` / `--nodes` 节点关键词**，而模板节点为空，CLI 会 **stderr 告警**：无法满足节点筛选，将按 **全量 coerceDeploy** 触发；需精确按节点触发时，应在平台或历史记录可拉取模板后再用 `-n`。

<a id="delivery-deploy-env-template"></a>

### delivery trigger：--env 与 --deploy-template（含 trigger-retry）

- **未传 `--env`**：运行环境与分支、模板解析与历史版本一致，仍从 `getTestApplyDetail` / `getJobList` 推断；会沿用交付详情里的环境与栈信息。`getTemplates` 的 query 与 ED 一致：`stackUuid` 非空时按 **cargo**，否则 **test**；staging 为 **staging**；liteSet 走 **getLiteSetTemplates**（`source=0`、`sourceId=applyProgramId`）。
- **`--env`**（显式覆盖）：`test` / `test骨干` / `骨干` / `qa` / **`测试环境`** / **`test环境`** → 运行环境 **test**，并清空栈（与「强制骨干」一致）；`staging` / `stage` / `备机` / `预发` → **staging**；`swimlane` / `cargo` / `泳道` → 若交付详情已有 **stackUuid** 则复用该泳道，否则调用 **`/api/cargo/createStack`** 新建栈后再触发，`triggerPipeline.env` 仍与详情对齐（通常为 **test** + `stackUuid`）；`liteSet` → 仅 **isLiteSetPlus** 服务（与 [delivery-liteSet-trigger.md](delivery-liteSet-trigger.md) 一致）。
- **部署执行分支（`jobList[].testBranch`）**：**骨干 test**（无 `stackUuid` 或未走显式 swimlane 分支）且未传 `--test-branch` / `--deploy-branch` 时默认 **qa**（**不**再用 `getJobList` 的 `testBranch` 顶替默认）。**staging** 未传覆盖时默认 **staging**。交付侧带 **stackUuid** 的泳道制品环境（`env` 仍为 test）时：仍可用 job 上 **testBranch** 再回落 **qa**。显式 **`--env` 为 swimlane** 时：若交付**原本已有泳道**则默认取各 job 的 **testBranch**（无则 **developBranch**）；若本次为**新建栈**则默认 **developBranch**（再回落 testBranch/qa）。
- **`--deploy-template`**：与 **`--lite-set-template`** 共用语义——非 liteSet 时校验 **`POST /api/qa/v1/job/getTemplates?env=`**（test / cargo / staging 由当前运行环境决定）；liteSet 时校验 **getLiteSetTemplates**（`env=prod&source=0`）。未传模板时取接口返回的**各服务列表首项**。传入名称/ id 时：对多应用取各服务列表**并集**判断——**若并集中无该模板则拒绝触发**；**若部分服务有、部分无**则**仅对有该模板的服务**组装 `jobList`（stderr 提示已跳过服务），**不再**对无模板服务回退「列表首项」。liteSet 下显式模板/set 的并集与收窄逻辑见 **`liteSetExplicitFilterJobNames`**（与上条一致）。说明链：**`FSD_JOB_DEPLOY_TEMPLATE_DOC_URL`**（与 liteSet 策略文档同域）。
- **`fsd delivery trigger-retry`**：支持相同 **`--env` / `--deploy-template`**；**swimlane** 仅允许复用交付已有栈（**不**在 retry 路径新建泳道）。

<a id="delivery-staging-set"></a>

### staging 备机：按 set（`cell`）选机（`--staging-set` / `--staging-set-job`）

- **接口**：`POST /api/fsd_ed/api/publishPlanStep/getMachineByJobNames?env=staging&applyProgramId=<applyProgramId>`，body 为 jobName 字符串数组；返回 `data[jobName]` 为机器列表。字段 **`cell` 即 set**；`ip_lan` 写入 `triggerPipeline.jobList[].ips`（同一服务多台命中时逗号拼接，与平台行为一致）。
- **CLI**：`fsd delivery trigger` / `fsd delivery trigger-retry` 支持 **`--staging-set <cell>`**、**`--staging-set-job <pairs>`**（`pairs` 为 `jobName:cell`，多个以**英文逗号**分隔；`jobName` 须为本次解析到的交付内服务名）。**仅当最终运行环境为 `staging`（备机）** 时生效；二者均与 **`--ips` 互斥**；无交付上下文时拒绝。
- **默认（不传上述两项）**：按列表中 **`is_select === true`** 的机器取 `ip_lan`；接口异常时 stderr 告警、`ips` 可留空。
- **`--staging-set`（全局 set）**：先取本次参与解析的**所有**服务返回列表中 **`cell` 的并集**（非空 trim 值）。所传字符串须**出现在该并集**中，否则**拒绝触发**。CLI 将**仅保留**列表中能命中该 `cell` 且能解析出有效 `ip_lan` 的服务参与触发（多应用时 stderr 提示已跳过服务）；**不再**对缺该 `cell` 的服务回退默认（`is_select === true`）以免误用备机。
- **`--staging-set-job`**：仅对片段中出现的 **`jobName`** 强制使用对应 **`cell`** 选机；该服务**必须**能命中且 `ip_lan` 有效，否则拒绝。未在片段中出现的其它服务：**若同时传了 `--staging-set`**，则按上一条的全局规则；**若未传全局**，则其它服务一律走默认 `is_select`。
- **同时传 `--staging-set` 与 `--staging-set-job`**：对 `--staging-set-job` 中列出的 `jobName` **以 per-job 为准**；其余服务走全局 `--staging-set` 规则（并集校验仍针对全局字符串）。

### 参数互斥性

**`-a, --app`** 与 **`--appkey`** 为**互斥参数**，不能同时使用：

```bash
# ✅ 正确：通过 jobName 部署
fsd delivery trigger -i 12345 -a waimai-service-demo --pretty

# ✅ 正确：通过 appkey 部署
fsd delivery trigger -i 12345 --appkey com.sankuai.waimai.demo --pretty

# ❌ 错误：不能同时使用
fsd delivery trigger -i 12345 -a waimai-service-demo --appkey com.sankuai.xxx
# 输出：错误: --app 与 --appkey 不能同时使用，请二选一
```

### 使用场景

| 场景 | 推荐方式 |
|------|---------|
| 已知服务名（jobName） | 使用 `-a, --app` |
| 仅知道 octoAppKey | 使用 `--appkey` |
| appkey 对应多个服务 | 先 `fsd app find-by-appkey --appkey <appkey> --pretty` 查看候选，再用 `-a` 指定 jobName |
| 不在 git 仓库内但需触发部署 | 提供 `-i <交付ID>` 加 `--appkey`（直拉交付内解析，**可不依赖**当前目录分支）或 `-i` + `-a`（`-a` 可与交付内 octoAppKey 求交；若需 git 解析服务名则仍要 `-b` 或仓库内分支） |

### 完整示例

```bash
# 1. 通过 appkey 触发交付自测流水线（全部节点）
fsd delivery trigger -i 397771 --appkey com.sankuai.waimai.service --pretty

# 2. 通过 appkey 触发指定节点（如构建部署）
fsd delivery trigger -i 397771 --appkey com.sankuai.waimai.service -n 构建部署 --pretty

# 3. 通过 appkey 触发备机部署
fsd delivery trigger -i 397771 --appkey com.sankuai.waimai.service --env staging --pretty

# 3b. 备机全局 set（仅部分服务有该 cell 时，其余服务自动 is_select）
fsd delivery trigger -i 397771 --env staging --staging-set gray-release-waimai-baseapi --pretty

# 3c. 仅指定个别服务的 set（cell），其它服务默认 is_select
fsd delivery trigger -i 397771 --env staging --staging-set-job 'waimai-qa-baseapi:gray-release-waimai-baseapi' --pretty

# 4. 通过 appkey 检查自测完成
fsd delivery check -i 397771 --appkey com.sankuai.waimai.service --pretty

# 5. 通过 appkey 确认自测完成
fsd delivery finish -i 397771 --appkey com.sankuai.waimai.service --pretty

# 6. 通过 appkey 重试失败节点
fsd delivery trigger-retry -i 397771 --appkey com.sankuai.waimai.service --pretty

# 7. appkey 对应多个服务时的错误提示
fsd delivery trigger -i 397771 --appkey com.sankuai.waimai.common --pretty
# 输出：octoAppKey=com.sankuai.waimai.common 对应多个服务，请改用 --app 指定其一：service-a / service-b / service-c
```

### AI 决策要点

1. **优先使用场景**：当用户提供 octoAppKey 而非 jobName 时，使用 `--appkey`
2. **歧义处理**：appkey 对应多个服务时，执行 `fsd app find-by-appkey` 让用户选择具体 jobName
3. **透明性**：向用户说明时可提及「通过 appkey 自动解析为服务 XX」
4. **与交付 ID 配合**：`--appkey` 通常与 `-i <交付ID>` 配合使用，在交付范围内指定要操作的服务
5. **分支推断**：不在 git 仓库内时，`-b, --branch` 会从交付的 jobList 中该服务的 `developBranch` 读取；**`-i` + `--appkey`** 时 octoAppKey 仅在交付内解析，**不必**求当前仓库分支与 `getTestApplyByJob` 一致
6. **`-a` 既可 jobName 也可 octoAppKey**：在交付上下文中，若用户给的名称不像 jobName 或匹配失败，可说明 CLI 会自动按 octoAppKey 在计划内解析，**无需**先查历史部署记录再触发
7. **直接触发部署**：用户明确要部署时，直接执行 `fsd delivery trigger`（及所需 `-i/-a/--appkey`）；**不要**先要求用户查 `records` / record-detail，除非排查失败或用户需要审计

### `--pretty` 轮询：基线 recordId（避免误判「上次成功」）

`fsd delivery trigger` / `trigger-retry` / `deliver-qa` 在调用触发接口**之前**，会拉一次 `getPretestRecordList` 取当前**第一条**记录的 `id` 作为 **baseline**（写入 `trigger` 返回 `_meta.baseline_record_id`）。`--pretty` 随后轮询「最新一条」时：若列表首条 `id` 仍 **≤ baseline**，说明**新流水尚未落库**，CLI **不会**把这条（往往是**上一次已成功**的）记录当作本次触发的终态而直接报成功。待出现 `id > baseline` 的新记录后再判成功/失败。`fsd delivery gate` 自动触发后的等待逻辑与此一致。

---

## delivery trigger 底层接口

| 场景 | HTTP |
|------|------|
| 有交付（`-i` 或 `getTestApplyByJob` 命中） | `POST /api/fsd_ed/api/deliveryPipeline/triggerPipeline`（body 含 `testApplyId`，`jobList` 与 `getJobList` 全量一致） |
| 无交付（仅 `-a`/`-b`） | `POST /api/qa/v1/pipline/triggerPipeline` |

`triggerPipeline.type` 与 `projectType` 对齐：**4 → `deliverQa`**，**1 → `rdSelfTestFinish`**（以 `getTestApplyDetail.projectType` 为准）。无交付 ID 时 `--pretty` 会轮询部署进度。

**`--env liteSet`**：`template` / `setName` 由 `getLiteSetTemplates`、`getHostsByJobs`（`source=0`、`sourceId=applyProgramId`）按 job 解析；仅 `isLiteSetPlus` 服务进入 `jobList`。详见 [delivery-liteSet-trigger.md](delivery-liteSet-trigger.md)（文首 **「校验失败时（CLI 与助手）」** 含 `未触发部署。`、禁止去参重试与 CLI 提示常量说明）。

---

## delivery trigger 与指定节点（-n）

触发自测流水线并用 **`-n`** 限定节点（可多次；与 `matchPipelineNodesByKeywords` 同源；不传则全量）。节点名取自用户描述或 `record-detail`。部署操作也通过流水线完成。

```bash
fsd delivery trigger -i <applyProgramId> -n 部署环境 -n 自动化测试 --pretty
```

**常见 `-n`：**

| 用户描述 | `-n` 传入值 |
|----------|-------------|
| 构建部署 / 未部署 | `构建部署` |
| 部署环境 | `部署环境` |
| 静态扫描 / Sonar | `静态代码扫描` |
| 自动化 / 执行自动化 | `自动化测试` |
| 覆盖率 | `代码覆盖率` |
| 单测 | `单测` |
| PR 检查 | `PR检查` |
| Web 安全 | `Web安全检查` |

---

## delivery trigger 与测试分支覆盖（--test-branch）

```bash
fsd delivery trigger -i <applyProgramId> -n 部署环境 --test-branch <branch> --pretty
```

**`--test-branch`**：全局覆盖各服务 `testBranch`；全员同开发分支时一条即可；各服务分支不同时须逐服务 **`fsd deploy swimlane`**。优先级：CLI 值 > `getJobList` 已存值。

---

## delivery trigger-retry

失败终态记录上只重跑失败段顶层节点（`jobList.pipelineStepList` 裁剪）。**`-i`** 必填；**`-r`** 可选指定 `recordId`；**`--dry-run`** 仅预览 JSON；**`--pretty`** 同 trigger（含失败摘要）。

---

## delivery stop-pipeline（终止自测流水线）

按 **流水线事件 ID（`eventId`）** 请求终止**正在运行**的交付自测流水线。对齐 **skill-dev** 中 ED `fsd-deliveryqa-pipeline/excuteBtn.vue` 的 **`stopPipelineByEventIdApi`**，以及 **`TestApplyRefactorController#stopPipelineByEventId`**：Query **`eventId`**（Long，必填）；服务端从 SSO 取 **`userName`**，再调 baseapi **`stopPipelineByEventId(eventId, userName)`**。

| 项目 | 说明 |
|------|------|
| CLI | `fsd delivery stop-pipeline -e <eventId> [--pretty]` |
| HTTP | `GET /api/fsd_ed/api/testapply/stopPipelineByEventId?eventId=` |
| 成功 | 通常 `code === 0`，`data` 可能为「终止中,请稍等！」等（**异步终止**，需在前台或 `record-detail` / `deploy status` 再看状态） |

**如何拿到 `eventId`：**

`stop-pipeline` 需要的 `eventId` 是**各个服务分支的 `parentEventId`**，不是流水线记录的 ID（recordId）。获取方式：

1. **最常用**：**`fsd delivery record-detail -i <applyProgramId> -r <recordId> --pretty`** → 输出中各服务下显示的 **eventId**（即 `buildPiplineRecordDetailVos[].parentEventId`）
2. **无交付场景触发时直接获取**：**`fsd delivery trigger --pretty`** 触发成功时，若仅返回 **`data` 为数字**，即本次流水线的 **eventId**
3. **已知 eventId** 时可直接用 **`fsd deploy status -i <eventId>`** 查看状态（与 **`detailProgress/{eventId}`** 同源）

> **重要区分**：
> - **`recordId`**（流水线记录 ID）：从 `records` 列表获取，用于查询记录详情
> - **`eventId`**（服务分支事件 ID）：从 `record-detail` 各服务的 `parentEventId` 获取，用于 `stop-pipeline` 终止该服务的流水线

**与其它命令的区别（助手须区分）：**

| 意图 | 命令 |
|------|------|
| 停 **交付自测流水线**（按 **eventId**） | **`fsd delivery stop-pipeline -e <eventId>`** |
| 停 **FST 自动化**单次执行 | **`fsd delivery fst stop`** / **`fsd fstPlan stop`**（`planId` + **`fstExecuteId` / execute-id**） |
| 停 **测试计划**侧「环境部署 / 测试流水线」（按 **eventId**） | **`fsd test stop-pipeline --id <测试计划ID> -e <eventId>`**（**同源接口**；路由与 **eventId** 获取见 [test-plan.md · stop-pipeline](test-plan.md#sec-test-stop-pipeline)） |

**安全与路由：** **禁止**在缺少明确 **`eventId`**（或可从用户消息/链接 **唯一**解析）时猜测、或默认「最新一条记录」执行 stop。无 ID 时先 **`record-detail`** / **`records`** / **`deploy status`** 让用户确认目标事件。

```bash
fsd delivery stop-pipeline -e 328980149 --pretty
# 与 deploy status 相同，支持 record 链接形式（由 CLI 解析出数字 ID）
fsd delivery stop-pipeline -e "https://fsd.sankuai.com/record/328980149" --pretty
```

---

## delivery skip-steps

`POST .../skipApplySteps`，Body **`ApplyJobSkipVO[]`**。CLI **拒绝**跳过构建部署/交付、卡点、准出、交付 QA 等敏感节点。

| 方式 | 说明 |
|------|------|
| `--json` | 直接 `ApplyJobSkipVO[]` |
| `-a`/`-b`/`--steps` + `-m`/`--step-messages` | CLI 组装（多服务建议 `--json`） |

---

## trigger 失败时的自动摘要

`trigger` / `trigger-retry` 在 **`--pretty`** 下失败或超时时，CLI 会解析记录并输出失败步骤与建议的后续命令（见 `query-ops.js`）。子步骤深挖：用 `record-detail` 里的 **`parentEventId`** 走 `fsd deploy status`/`analyze`（见下节）。

---

## trigger 轮询（非 --pretty 模式）

非 `--pretty` 时响应含 `recordId`；用 **`fsd delivery record-detail -i <applyId> -r <recordId> --pretty`** 查进度，约 15s 重试至终态（不必先 `records` 列表）。

---

## record-detail 与部署机器 IP

- **主数据**：`getPretestRecordDetail`（CLI `queryPipelineRecordDetail` 未补全前）不含逐机 IP。
- **`serviceDeployIps`**：对 **`buildPiplineRecordDetailVos`** 各行，当 **`env`** 为 **`test` / `staging`** 或泳道类（**`swimlane` / `cargo` / `new-swimlane`**；骨干与泳道在明细中常同为 `test`）且存在 **`parentEventId`** 时，CLI 以之为 **`GET /api/branchEvent/detailByStepName?eventId=&stepName=`** 的 **`eventId`**（与部署域一致）。依次尝试 **FSD 构建部署类 `stepName`**（与 [deploy.md · 部署进度与部署机器 IP](deploy.md#部署进度与部署机器-ip) 所列同源），再尝试 **`plus-compile` / `plus-deploy`**：从 **`deployStepResultVos` / `ip` / `ipList`**，或 Plus 路径下 **`step === 'plus-deploy'`** 的 **`hosts[]`**，汇总为 **`serviceDeployIps`**（元素至少含 **`jobName`/`ip`**，Plus 路径可含 **`hostName`/`status`**）。
- **关闭补充请求**：**`fsd delivery record-detail … --no-service-ips`**（**`fsd deploy record-detail`** 同源）；交付/部署 **trigger `--pretty` 轮询**等高频路径内部 **`includeDeployIps: false`**，不发起上述请求。

## 节点级执行详情（via parentEventId）

`record-detail` 的 **`buildPiplineRecordDetailVos[].parentEventId`** 即部署侧 `eventId`：`fsd deploy status -i <parentEventId> [--pretty]`、`fsd deploy analyze -i <parentEventId>`。详见 [deploy.md](deploy.md)。

---

## API 接口说明

> 助手不直接调；供理解 CLI 推断。

| 接口 | 用途（简） |
|------|------------|
| getOnesDetails | 类型/QA/泳道元数据 |
| listDocs | 技术方案文档拼接 |
| getPiplineConfig | 未传 `-e` 时映射场景 |
| requirementBranchView | 多服务 jobList |
| createTestApply / editTestApply / deleteTestApply | create / edit / delete |
| getDeliveryPlanList / getTestApplyDetail / queryTestApplySummaryV2 | list / detail / status / prep / online-notice（组合） |
| getDeliveryPlanByMedId | **客户端交付**按 medId 取交付计划及 **`data.testPlanId`** → `delivery med-test-plan` |
| getTestPlanDetail / queryTestPlanSummary | status / prep / online-notice（标准交付且 **getTestApplyDetail.data.testPlan 含有效 id**） |
| skipApplySteps / deliverQaWithFsd | skip-steps / deliver-qa |
| testapply/stopPipelineByEventId | delivery stop-pipeline（按 eventId 终止运行中的自测流水线） |
| deliveryPipeline/revokeDeployById | **测试计划**：`fsd test revoke-deploy`（**recordDetailId**） |
| queryFst（source=testApply）/ triggerFst / queryFstDetail / stopPlan / retryFstPlan | delivery fst list / fst trigger / fst result / fst stop / fst retry |

### 应用服务类型标签（bdsMode）

交付详情页面中，应用信息服务名称前的标签（web、thrift、jar、pom、npm 等）来自字段 **`bdsMode`**。

**数据流：**

- **后端接口**：`getJobList` 返回 `ApplyJobVo.bdsMode`（从 `Job.getBdsMode()` 获取）
- **前端渲染**：使用 `scope.row.bdsMode` 或 `slotProps.row.bdsMode` 显示为标签（`<mtd-tag>`）
- **CLI 输出**：`fsd delivery detail --pretty` 在服务列表中以 `[bdsMode]` 形式显示

**注意**：`getTestApplyDetail` 返回的 `jobList` 是 `List<ApplyJob>` 类型，通常不带 `bdsMode`；完整的 `jobVoList` 是 `List<ApplyJobVo>` 类型，包含 `bdsMode` 字段。前端应用列表页面使用 `getJobList` 接口来获取带 `bdsMode` 的完整服务信息。

---

## delivery prep（上线前准备）

**命令**：`fsd delivery prep -i <交付ID> [--pretty] [-t <type>]`

当用户问「交付上线前还要准备什么」等时，助手应执行本命令取结构化结果后再回答。**下列分支为个性化规则，写在本文档，不写入 SKILL.md。**

### 分析依据

1. 读取 `getTestApplyDetail` 的 **`projectType`**（1=RD 自测，4=标准交付）、**`status`**、**`data.testPlan`**（对象，含 `id`/`name`/`url`；可能为 `null`）、以及 **`planIds`**（仅供参考，**不作为**是否拉测试计划的依据）。
2. **RD 自测（projectType=1）**：**始终**按 **交付计划进度** 分析（`queryTestApplySummaryV2`），与 `fsd delivery status` 同源。
3. **标准交付（projectType=4）**：
   - **`testPlan` 有效（非空且 `id` 为正整数）**：按该 **`testPlan.id`** 拉测试计划：`fsdTestplan/detail` + `queryTestPlanSummary`（`tabType=all`），与 `fsd test progress` 一致；并拉 **交付计划进度** 作参考。
   - **否则**：仅 **交付计划进度**，`analysisReason` 说明 `testPlan` 为空或无效。
4. **其它 projectType**：仅 **交付计划进度**。

`--pretty` 下，走测试计划分支时会先打印各计划进度，再附「交付侧进度参考」；仅交付分支时只打印交付进度摘要。与 [delivery status 展示规则](#delivery-status-展示规则) 一致。

---

## delivery online-notice（上线注意事项）

**命令**：`fsd delivery online-notice -i <交付ID> [--pretty] [-t <type>]`（别名：`go-live-notice`）

当用户问**要上线的交付有什么要注意**、**上线前注意什么**、**发布前要准备什么**等时，助手应执行本命令。上述意图已并入 **`fsd` 技能**（见下节「[上线注意事项与明日上线](#上线注意事项与明日上线)」），**无需**单独挂载 `delivery-online-notice` 目录。

### 数据路由（与 status / prep 完全一致）

对齐 skill-dev 前端交付详情与 baseapi **`DeliveryStatusEnum`**：`20` = 交付QA（**等待 QA 接收**）；**`25` = 待测试** 起为 **QA 已接收提测** 及之后阶段。

1. **`projectType = 1`（RD 自测）**：只输出 **交付计划进度**（`queryTestApplySummaryV2`），即「交付状态」层面的卡片进度。
2. **`projectType = 4`（标准交付）**：与 `status`/`prep` 同源——**`data.testPlan` 有效**时输出 **测试计划** 进度并附交付侧参考；**否则**仅 **交付计划进度**。**`reminders`**（上线注意事项 CLI）：
   - **`status < 20`**（尚未到「交付QA」）：可含预计上线时间、`gate`/交付链路类建议，以及提测/接收类文案（与历史一致）。
   - **`status ≥ 20`**（已走 **交付QA** 及之后，与 skill-dev **`DeliveryStatusEnum`** 一致）：**只输出与测试计划状态相关的句子**（如 `assessment` 偏慢、无 testPlan 数据时的测试计划侧核对提示等），**不**输出交付状态解读、**不**输出「再执行 gate」类交付操作建议；预计上线时间在此场景下也省略，避免与「仅测试计划」混淆。
3. **其它 projectType**：仅 **交付计划进度**。

### 输出

- JSON 在路由结果上增加 **`intent`: `go_live_notice`**、**`reminders`**: 字符串数组（非接口字段；标准交付且 **`status ≥ 20`** 时仅测试计划向提醒，见上条）。
- **`--pretty`**：先【上线注意事项】清单，再输出与 **`prep --pretty`** 相同的进度与「分析依据」段落。

---

## 上线注意事项与明日上线

> 原独立技能 **`delivery-online-notice`**、**`delivery-tomorrow-online`** 的触发说明与 CLI 路由统一写在本节；**不**在仓库 `fsd/` 外再建目录。

### 上线注意事项（原 delivery-online-notice）

- **命令**：`fsd delivery online-notice -i <applyProgramId> [--pretty]`（别名 `go-live-notice`）。
- **规则**：与上节 [delivery online-notice](#delivery-online-notice上线注意事项) 及 [delivery status 展示规则](#delivery-status-展示规则) 完全一致。

### 明日上线（原 delivery-tomorrow-online）

用户问**明天有哪些交付要上线**、**明日上线**、**明天上线计划**等，且尚未指定具体交付 ID 时：

1. **筛列表**：`fsd delivery list --online-tomorrow --pretty`（按**预计上线时间**落在**本地日历的明天 00:00:00～23:59:59**；与 `--online-time-start` / `--online-time-end` **互斥**）。
2. 对关心的 **`applyProgramId`** 再执行 **`fsd delivery prep -i <id> --pretty`** 或 **`fsd delivery online-notice -i <id> --pretty`**，与「已知交付 ID」场景相同。

若用户**已给出**交付 ID，则直接 `prep` / `online-notice` / `status`，**不必**先 `list`。

---

## AI 决策树

- **创建**：「创建/新建交付」→ `fsd delivery create --pretty`；未口述场景/类型由 CLI 推断；Ones 列表用 `ones --pick-json` 在对话中选；成功后告知需求并问是否触发自测；仅新建泳道交付→`create -e new-swimlane`，勿 `deploy`。**标准交付**：无有效 `qas` 且用户未给 QA 时**必须追问 QA MIS**，**禁止**用需求负责人顶替 → [标准交付 QA 来源](#标准交付-qa-来源强制)。
- **编辑**：`edit -i <id>`（泳道/场景/`--add-jobs-json`）；成功后勿自动串联命令。
- **准出**：`gate -i <id>`；通过后 4→`deliver-qa`，1→`check`/`finish`。**交付 QA**：助手解读结果时须用 **`deliver-qa -i <id> --pretty`**（或看完整 JSON）；若接口触发异步流水线，**在运行中不得宣称「已交付成功/失败」**，应以 CLI 轮询结束后的输出或 `records` 为准 → [deliver-qa](#deliver-qa-交付-qa)。
- **交付侧仅跑 FST（不跑整条交付流水线）**：`delivery fst list|trigger|result -i <applyProgramId>`（`source=testApply`）；测试计划上下文勿与此混用 → `fstPlan`。
- **终止交付自测流水线（非 FST）**：用户要停「自测流水线 / ED 上正在跑的流水线」→ **`fsd delivery stop-pipeline -e <eventId>`**。先通过 **`records`** 查看流水线记录列表获取 `recordId`，再通过 **`record-detail -r <recordId>`** 查询记录详情，从各服务下显示的 **`eventId`**（即 `parentEventId`）选择要终止的服务。**`eventId` 是各服务分支的事件 ID**，不是流水线记录的 recordId。与 **FST 终止**、**测试计划** 侧区分见 [delivery stop-pipeline](#delivery-stop-pipeline终止自测流水线)；**测试计划 URL / `testPlanId` 上下文** → **`fsd test stop-pipeline --id <计划ID> -e <eventId>`**（同源接口，细则见 [test-plan.md · stop-pipeline](test-plan.md#sec-test-stop-pipeline)）。
- **交付里部署服务 / 环境**：**`fsd delivery trigger -i <applyProgramId> -n 构建部署 --pretty`** 或 **`fsd delivery trigger -i <applyProgramId> -n 部署环境 --pretty`**（通过自测流水线完成部署）。
- **自测完成（1）**：`check`→`finish`（默认未准出时 check/finish 会先跑与 gate 一致的自动卡点处理；`--no-auto-gate` 关闭），勿 `deliver-qa`。
- **查询**：`list` 首次一页、只列主字段；`detail`/`delete` 按需。「**某人创建的**交付」→ **`list --create-by <MIS>`**（接口 `createBy`），**勿用 `--rd`** → [delivery list · 创建人 vs RD](#创建人-vs-rd助手须区分)。
- **交付状态**：`status -i <id>`；自测仅交付进度，标准交付在 **`getTestApplyDetail.data.testPlan` 有效**时主看测试计划进度 → [delivery status 展示规则](#delivery-status-展示规则)。
- **客户端 Med 链接 / `deliveryDetailMed`**：查关联测试计划 ID → **`med-test-plan`**（`getDeliveryPlanByMedId`），**勿**将 medId 当作 `applyProgramId` 用于 `status`/`prep` → [客户端交付](#客户端交付deliverydetailmed)。
- **上线前准备**：`prep -i <id>`；解读同 [delivery prep](#delivery-prep上线前准备)（与 status 路由一致）。
- **上线注意事项**：`online-notice -i <id>`（别名 `go-live-notice`）；数据路由同上，另附 `reminders` → [delivery online-notice](#delivery-online-notice上线注意事项)；意图说明见 [上线注意事项与明日上线](#上线注意事项与明日上线)。
- **明日上线 / 明天上线（无具体交付 ID）**：`delivery list --online-tomorrow --pretty` → 再对单条 `prep` / `online-notice` → [上线注意事项与明日上线](#上线注意事项与明日上线)。

---

## 使用示例

```bash
# 1) 登录
fsd-sso login

# 2) 创建（自动解析 Ones/分支/服务）
fsd delivery create --pretty

# 3) 创建（显式 Ones/名称/分支/服务；场景示例：test | new-swimlane | swimlane -u <id> | staging）
fsd delivery create -j "https://ones.sankuai.com/..." -n 交付名称 -b <分支> -a <服务名> -e swimlane -u selftest-xxxx --pretty

# 4) 详情
fsd delivery detail -i <交付ID> --pretty

# 4a) 交付状态（自测=交付进度；标准交付在详情 testPlan 有效时主看测试计划进度）
fsd delivery status -i <交付ID> --pretty

# 4b) 上线前还需准备什么（与 status 同源路由，pretty 含「分析依据」说明）
fsd delivery prep -i <交付ID> --pretty

# 4c) 要上线的交付注意事项（同源路由 + 提醒清单）
fsd delivery online-notice -i <交付ID> --pretty

# 4d) 明日预计上线的交付列表（再对单条用 prep / online-notice）
fsd delivery list --online-tomorrow --pretty

# 5) 准出 → 标准交付交付 QA（gate 默认含自动复检；可先 gate 再 deliver-qa）
fsd delivery gate -i <交付ID> --pretty
fsd delivery deliver-qa -i <交付ID> --pretty

# 6) 交付关联 FST：查询 → 触发 → 查结果（recordId 来自 trigger 返回的 data）
fsd delivery fst list -i <交付ID> --pretty
fsd delivery fst trigger -i <交付ID> --pretty
fsd delivery fst result -r <recordId> --pretty

# 7) 终止运行中的交付自测流水线（先 records 获取 recordId，再 record-detail 查看各服务的 parentEventId）
fsd delivery stop-pipeline -e 328980149 --pretty

# 8) 客户端交付（deliveryDetailMed）：按 medId 查关联测试计划 ID
fsd delivery med-test-plan -m 42179 --pretty
fsd delivery med-test-plan -u "https://fsd.sankuai.com/deliveryDetailMed/42179?deliveryTab=delivery" --pretty

# 9) 通过流水线部署环境（未传 --env 时默认沿用交付详情环境；如需显式切到骨干或泳道可用 --env）
fsd delivery trigger -i <交付ID> -n 构建部署 --pretty
fsd delivery trigger -i <交付ID> -n 部署环境 --pretty
fsd delivery trigger -i <交付ID> -n 部署环境 --env 测试环境 --pretty
```