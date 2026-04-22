---
name: fsd
description: "通过 fsd CLI 管理部署（骨干/备机/泳道）、交付自测流水线、测试计划撤销环境部署、自动化测试、终止与重试自动化、停止或终止自测流水线、代码覆盖率、需求/任务/测试计划/缺陷管理及上线准备全流程。当用户提到 fsd、deploy、delivery、迭代、autotest、sonar、流水线、自测、预构建、环境部署、撤销部署、取消环境部署、revoke-deploy、回归测试、集成测试、预发回归、需求、需求ID、issueId、按需求查交付、关联交付、关联测试计划、getListByIssueId、任务、测试计划、testPlan、testPlanId、Automan、plan_ 工作目录、场景自动化计划、场景计划、运行自动化、跑自动化、执行自动化、帮我跑自动化、帮我运行自动化、帮我执行自动化、跑一下自动化、运行一下自动化、自动化测试、跑测试、跑用例、执行用例、用例、缺陷、bug、发布、上线、灰度、缺陷报告、链路分析、traceId、eventId、上线注意事项、上线前注意、发布前要准备什么、能上线吗、明日上线、明天上线、delivery-online-notice、分支合并风险和冲突可能性、部署失败、失败原因、终止自动化、停止 FST、终止流水线、测试计划停流水线、重试 FST、retryFst 时触发。测试计划场景与交付链、独立 deploy 易混时，命令路由以「测试计划语境与命令路由」专节与核心规则为准；禁止臆造 CLI 参数名。"

metadata:
  skillhub.creator: "lixuesong05"
  skillhub.updater: "lixuesong05"
  skillhub.version: "V11"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "14902"
  skillhub.high_sensitive: "false"
---

# FSD 技能

通过 `fsd` CLI 管理 FSD 平台的部署、交付、测试、上线全流程。核心工作模式：CLI 命令驱动 → 状态监控至终态 → 失败自动排查。所有操作在终端完成，禁止直接调用内部函数。

## 前置条件

1. **安装/更新**：`fsd --version` 检查；不存在则 `npm install -g @waimai/fsd --registry=http://r.npm.sankuai.com`（Node.js >= 22）
2. **fsd-sso**：`fsd-sso --version` 检查；不存在则执行 `npm install -g @waimai/fsd-sso --registry=http://r.npm.sankuai.com`
3. **认证**：本地开发执行 `fsd-sso login` 完成登录；沙箱/CatClaw 场景优先走自动换票，细节见下文「fsd-sso 认证与登录」。

## fsd-sso 认证与登录

`@waimai/fsd-sso` 与 `fsd` 共用同一份本地登录态。

```bash
npm install -g @waimai/fsd-sso --registry=http://r.npm.sankuai.com
fsd-sso login
fsd-sso status
fsd-sso logout
```

- 本地开发：执行 `fsd-sso login`，走浏览器登录。
- CatClaw / 沙箱：若存在 `CATCLAW_PROFILE`，优先自动换票，通常无需手动登录。
- 遇到 401 / 未登录：本地先 `fsd-sso login` 后重试；若仍失败，再用 `fsd-sso status` 检查状态。
- 未全局安装时，可用 `npx -p @waimai/fsd-sso fsd-sso login`。

## 术语

| 术语 | 含义 | 对应 env |
|------|------|----------|
| 骨干 | 主干测试环境 | `test` |
| 备机 | 预发布环境 | `staging` |
| 泳道 | 隔离测试环境，通过 UUID 标识 | `test`（cellType=swimlane） |
| 迭代 | **不等同于**「交付」。口语可能指交付周期、需求/任务迭代、版本节奏、测试计划周期等，**须结合上下文与具体链接（尤其 FSD URL）判断**；勿默认将「迭代」路由到 `fsd delivery`。链接锚定见 [delivery.md · 迭代与 FSD 链接](references/delivery.md#sec-iteration-fsd-url)。 | — |
| testPlan | 即「测试计划」；平台/API 常用 camelCase（如 `testPlanId`、`source=testPlan`） | — |
| **提测**（`testApply*`） | **提测详情页** / **提测 ID**（`testApplyDetail` / `testApplyId`）；与 **`applyProgramId`、`fsd delivery -i`** 同主键。≠ **waitTest 提测单**（`--delivery-ids`）。对用户只说「提测」系用语，勿直译 `testApply*`、勿称「测试申请」。扩展见 [delivery.md · 平台命名（提测）](references/delivery.md#平台命名提测)。 | — |

## 实体关系

```
空间(project) ─┬─ 需求(req) ──── 任务(task)
               │
               └─ 交付(delivery) ─── 提测单(waitTest) ─ ─ ─ 测试计划(testPlan)
                       │                                 (可选关联)
                       └─ 上线计划(pub) ← 也可直接 add-job 不经交付
```

**关键区分：**

| 概念 | ID 来源 | 易混淆点 |
|------|---------|----------|
| 空间 ID (`-p`) | `fsd req project` 返回的 **`projectId`** 字段（**不是 `id` 字段**） | 创建需求/任务时必填，不是需求 ID |
| 交付 ID（**仅 `applyProgramId`**） | `fsd delivery create` 返回；列表项取 **`applyProgramId`** | **`deliveryId` ≠ 交付 ID**；列表里的 **`id`** 也常 ≠ `applyProgramId`。`fsd delivery * -i` **只用 `applyProgramId`** |
| 客户端 Med（`medId`） | 链接路径 **`/deliveryDetailMed/<数字>`** | **不是** `applyProgramId`；查关联测试计划用 **`fsd delivery med-test-plan`**（见 [delivery.md · 客户端交付](references/delivery.md#客户端交付deliverydetailmed)） |
| 提测单 ID（`waitTest`） | `fsd waitTest list` 返回的 `[提测单ID: xxx]` | **≠ 提测 ID（`testApplyId`）/ 交付 ID**；创建测试计划 `--delivery-ids` 用提测单 ID |
| Ones 链接 | `https://ones.sankuai.com/.../detail/<reqId>` | 交付创建 `-j` 必须传完整 Ones URL，不能传纯数字 ID |

## 测试计划语境与命令路由（必读）

以下为测计划与交付链易混场景的**专节**，读完再执行 CLI；细节与 [deploy-failure-routing.md](references/deploy-failure-routing.md)、核心规则 14–19 一致。

### 测试计划内「触发 / 重试部署」（禁止独立 `fsd deploy test`）

**前提**：上下文已有 **`testPlan.id`** 或 Automan **`plan_<数字>`** 工作目录。

**触发**：用户要把应用**部署到当前测试计划环境**（含「部署到测试」「在测计划里部署两个 app」「重新部署」）→ **必须** **`fsd test deploy --id <testPlan.id> --job-name <应用 jobName> --pretty`**；多应用则多次执行，每次一个 `--job-name`。

**`context.json` 只用于取 ID**：从中读取 **`testPlan.id`（或顶层 `testPlanId`）** 填 `--id`。**有哪些 job、绑定哪套环境以平台为准** → **`fsd test jobs --id <testPlan.id> --pretty`**，必要时 **`fsd test detail --id <testPlan.id> --pretty`**。**不要**用 `targetRepositories`、`stackUuid`、泳道名等字段决定能否部署或改用其它 deploy 子命令。

**禁止（独立部署，与测计划 job 脱钩）**：`fsd deploy test -a <应用>`、`fsd deploy swimlane …`（含 **`swimlane -u` 接从 JSON 抄的 UUID**）、先 `fsd deploy swimlane-info` 再 `swimlane`。**禁止**把 **`fsd deploy --help`** / **`fsd delivery --help`** 当作触发部署的第一步（形态以本节与 [test-plan.md](references/test-plan.md) 为准）。**禁止**先跑 **`fsd delivery show` / `delivery list` / `delivery detail`**（或换 ID 轮番试）来「对齐交付」——触发只认 **`fsd test deploy`**；JSON 里的 `applyProgramId` / `deliveryId` 在用户未**明文**查交付时不作依据。**禁止**因 **`targetRepositories` 里没有用户点名的应用**就推断「只能骨干」并改用 **`fsd deploy test -a`**：应先 **`fsd test jobs`** 看平台 job，再 **`fsd test deploy --id <testPlan.id> --job-name <名> --pretty`**（CLI/平台明确报「job 不属于计划」时再与用户对齐）；**禁止**未查平台、未试 `test deploy` 就先走独立骨干 deploy。**禁止**因 [deploy.md](references/deploy.md) 中「泳道 → `fsd deploy swimlane`」而忽略本条——该表**仅适用于无测试计划部署语境时**。

详见 [deploy-failure-routing.md · 触发部署简判](references/deploy-failure-routing.md#sec-trigger-deploy-routing) 与核心规则 16。

### 测试计划内「分支合并风险 / 冲突可能性」（禁止 `fsd delivery`）

**前提**：同上，已有 **`testPlan.id`** 或 **`plan_<数字>`**。

**主路径**：用户问分支冲突、合并风险、冲突可能性、能合并吗（可列举多个 **jobName**）→ **第一步** **`fsd test branch-risk --id <testPlan.id> --pretty`**（工作目录在 `plan_<id>` 下通常不必再加 `--work-dir`，否则 `--work-dir` 指向该目录）。

**禁止**：`fsd delivery --help`、`fsd delivery detail`、臆造 **`--delivery-id`**（CLI 无此参数；交付为 **`-i <applyProgramId>`**，也不能替代 branch-risk）。交付详情中的应用列表常与用户点的多服务不一致。**禁止**因 `context.json` 含 `deliveryId` / `applyProgramId` 就先查交付「对齐」。若只关心部分 job，在 **branch-risk** 输出里按 job 名对照即可（当前 CLI 按测计划内服务分析，无 per-job 过滤）。

详见核心规则 18、[test-plan.md · branch-risk](references/test-plan.md#sec-branch-risk)。

### 部署失败 / 失败原因 / 修复建议（统一入口）

**测试计划已锚定**（`testPlan.id` / `plan_<数字>` / `context.json`）时，**第一条可执行 CLI 只能是** **`fsd test jobs --id <测试计划ID> --pretty`** → 按失败 **jobName** 取 **`eventId`** → **`fsd deploy analyze -i <eventId>`**。

**禁止作为第一步**：`fsd deploy --help`、`fsd deploy status --help`、`fsd delivery --help`；**`fsd deploy status --plan …` / `--plan-id …`**（测计划 ID 不得进 deploy status）；**`fsd delivery status --plan …`**（勿把测计划 ID 塞进 delivery status）；**`fsd testPlan …` / `fsd testPlan --help`**（易与「测试计划」混淆；job/失败信息在 **`fsd test`** 下）；在计划目录 **`find`** 日志或 record；或「先找 eventId 再决定命令」——**eventId 不能靠翻本地目录得到**；空转 help 与下文「错误兜圈」同类。子命令与参数以本技能及 [deploy-failure-routing.md](references/deploy-failure-routing.md) 为准，**不要**用首轮终端「探索 CLI」。

用户话术中含部署失败、失败原因、修复建议、分析部署、应用挂了、FSD 帮分析部署等定因意图时：**先**按 [references/deploy-failure-routing.md](references/deploy-failure-routing.md) 的**命中顺序**选入口（测试计划 → pub → 纯交付 → 裸 eventId → 追问 ID），**再**跑任何 **`fsd delivery *`**。`plan_<数字>` 或 `context.json` 含 `testPlan.id` / `testPlanId` 时，**测试计划链优先于交付链**（见该文档第三节）。误用 `delivery-id` / `--plan-id` / 把 stackUuid 当 `deploy status -i` 等 → [Automan 节](references/deploy-failure-routing.md#sec-automan-context-trap)。拿到各失败应用的 **`eventId`** 后，日志解读、缺包、jar 链路等 → [references/troubleshooting.md](references/troubleshooting.md)。

### 测试计划语境 vs 交付查询（防误路由，必读）

**优先级**（与 [deploy-failure-routing.md](references/deploy-failure-routing.md) 一致；自上而下，命中即停）：

1. **工作区或消息含** `testPlan.id` / `testPlanId` / `plan_<数字>` / FSD URL 含 `testPlanId=` → **测试计划优先**。**禁止**把 `fsd delivery *`（含 `show` / `detail` / `status` / `list` / 先跑 `delivery --help`）当主入口。意图映射：测计划内触发或重试部署 → **`fsd test deploy --id <testPlanId> --job-name <jobName> --pretty`**（见上文「触发 / 重试部署」专节）；分支合并风险 / 冲突可能性 → **`fsd test branch-risk --id <testPlanId> --pretty`**；部署失败 / 定因 / 修复建议 → **`fsd test jobs --id <testPlanId> --pretty`**（再按 deploy-failure-routing 走 analyze）。**禁止**用 JSON 的 `deliveryId` / `applyProgramId` 跑 `delivery detail` / `show` 等来「回答」上述问题（除非用户**明文**查交付）。
2. **仅数字 ID、无其它上下文** → 问清是 eventId / 测试计划 ID / 交付 ID。
3. **有交付上下文、无测试计划** → `fsd delivery *`。
4. **两者皆无** → 通用部署路径。

**孤立数字 ID**（未说明是事件 / 测试计划 / 交付）时：**禁止**默认 `fsd delivery` 的 `detail` / `list` / `status`；已知为 eventId → `fsd deploy analyze -i`；能锁定测试计划 → 先 `fsd test jobs`；**仅**用户明文查交付、或链接已锚定为交付语境（如 `testApplyDetail/<applyProgramId>`）时用 `delivery -i <applyProgramId>`；**勿**因用户只说「迭代」就默认走 `fsd delivery`。

**「测试计划语境」任一即成立**：用户说「测计划 / 测试计划」；消息或附件含 **`testPlan.id` / `testPlanId`**；路径含 **`plan_<数字>`**（如 Automan）；FSD URL 含 **`testPlanId=`**。

**CLI 实情（禁止臆造参数）**：`fsd deploy status` **仅**支持 `-i <eventId>`，**无** `--plan` / `--plan-id` / `--planId`（例：勿执行 `fsd deploy status --plan 62141`）。`fsd delivery status` **仅**支持 `-i <applyProgramId>`，**无** `--delivery-id`，**勿**发明 `--plan <测试计划ID>`（例：勿执行 `fsd delivery status --plan 62141`）。若已因错误参数失败，**下一步仍须** `fsd test jobs --id <测试计划ID> --pretty`，**禁止**改去 `delivery status` 或 `delivery detail -i <猜的 applyProgramId>`。

在此语境下，用户问**该计划内**部署失败、失败原因、修复建议、应用挂了等 → **禁止**把「部署」关联到**交付流水线**；**禁止**第一步用 `fsd delivery status` / `detail` / `records` / `info` / `list`；**禁止**用 JSON 里被动附带的 `applyProgramId`、`deliveryId`、行内 `id` 填 `delivery -i`（见规则 15、17 与 Gotchas）。**在尚未 `fsd test jobs` 并取得失败 job 的 `eventId` 前，均属错误兜圈**，例如：`fsd deploy status --plan …` / `--plan-id …`；`fsd delivery status --delivery-id …`；任意把测计划 ID 塞进 `delivery status` 的变体；`fsd delivery detail -i <任意交付ID>`（含从 context 被动抄的 `applyProgramId`）；`delivery list` 后轮番 `detail -i`「对齐」；`fsd deploy status` 配 **`--apply-id`** 或凭交付 ID 猜部署态；**`fsd testPlan …`**；以及 **`fsd deploy --help` / `fsd delivery --help`** 占满第一步。**正确第一步**（通常也是先决的一条）：`fsd test jobs --id <测试计划ID> --pretty` → 取 **`eventId`** → **`fsd deploy analyze -i <eventId>`**（`deploy status -i <eventId>` 仅在已有 eventId 且需补看进度时、在 `jobs` 之后）。**仅**用户明文要看交付 / **delivery** 状态，或上下文已用链接锚定为交付时，才以 `fsd delivery *` 为主；**「迭代」单独出现不视为交付意图**。

**用户侧（可选）**：首条消息尽量给出 **`testPlan.id`** 或含 **`testPlanId=`** 的 FSD 链接，减少仅凭 JSON 猜 ID。若助手误走交付，可明确要求：先 **`fsd test jobs --id <测试计划ID> --pretty`**，勿用 `context.json` 里的 `applyProgramId` / `deliveryId` 跑 **`fsd delivery *`**。

## 核心规则

1. **只用 CLI 命令**，禁止直接调用内部函数
2. **泳道交付 ≠ 部署**：用户说「新建泳道并新建交付」且未说「部署」→ 仅 `fsd delivery create -e new-swimlane`，禁止调 `fsd deploy`
3. **部署/流水线禁止自创交付**：用户仅说「部署」「trigger」等 → 禁止执行 `fsd delivery create`；需要交付须先询问
4. **失败排查**：按 [troubleshooting.md](references/troubleshooting.md) 执行；缺包场景（`Could not find artifact`）且可提取 GAV 时，第一个动作必须是执行命令，禁止先输出分析
5. **多 job 候选**：展示列表，等用户确认后再执行
6. **禁止 cd**：用 Shell 工具 `working_directory` 参数指定目录
7. **默认不加 `--pretty`**：AI 解析 JSON 后用自然语言总结，只提炼主要字段。加 `--pretty` 的场景：给用户展示最终结果且无后续操作 / JSON 嵌套过深 / 用户明确要求。`fsd autotest` 仅 `status` 支持 `--pretty`
8. **禁止返回 URL**：不输出任何平台链接，直接展示结果内容。**例外：需求/任务创建成功后 CLI 输出的链接必须以 Markdown 超链接展示给用户**，链接文本用"任务链接"或"需求链接"，如 `[任务链接](https://fsd.sankuai.com/ones/task/detail/12345)`、`[需求链接](https://fsd.sankuai.com/ones/requirement/detail/12345)`
9. **直接执行无需确认**。**例外：`fsd autotest execute-appkey` 返回多个场景计划时，分两种情况：① 上下文无交付/提测/上线/备机等关键词且用户只是泛化说"帮我跑自动化"——直接执行研发自测类计划，无需确认；② 其他情况——必须先推荐一个计划并等用户明确确认后才能执行，禁止自动执行。**
10. **触发后监控至终态**：`deploy` 加 `--pretty` 即可（内部自动启动 daemon 并阻塞至终态，**不存在 `--daemon` 参数**）；`deploy staging --online-program` 内置轮询，无需加 `--pretty`；`delivery trigger` 用 `--pretty` 内置轮询；`autotest` 用 `--monitor` + `--observe`。后台命令**固定每 15 秒**读取终端输出，禁止指数退避/sleep 轮询。建议耗时命令预设 `block_until_ms: 120000`
11. **准出与终局动作**：`gate` 保持默认（自动三步复检），禁止加 `--no-auto-trigger`。准出后按 projectType 分流（见[准出终局路由](#准出终局路由)），严禁混用
12. **交付列表**：`fsd delivery list` 固定 `relatedMe: true`，所有筛选仅在「与我相关」集合内生效；向用户展示结果时**必须**说明该范围（响应含 `scopeDescription` 或 `--pretty` 首行【范围说明】）；后续 `detail`/`status`/`-i` **须用 `applyProgramId`**，**勿用**行内的 **`deliveryId` 或 `id`** 冒充（见「术语」声明）
13. **禁止反向合并**：任何场景（含冲突解决、部署失败排查）下，**严禁**将目标分支（如 `qa`、`staging`）合并到源分支（如 `feature/*`、`develop`）。
14. **测试计划优先于交付（无条件优先）**：当上下文中**同时出现**测试计划和交付（如用户同时提到两者，或对话历史中存在测试计划 ID 和交付 ID），**测试计划优先级永远高于交付**。所有操作（自动化触发、部署、**分支合并风险**、覆盖率等）优先走测试计划相关命令（`fsd test` / `fsd fstPlan`），除非用户**明确指定**「交付」「delivery」等**交付意图**，或 **FSD 链接已锚定为交付**（如 `testApplyDetail/<applyProgramId>`），才走交付路径。**「迭代」一词不单独作为交付路由依据**；若用户只说「迭代」，须结合链接与 [delivery.md · 迭代与 FSD 链接](references/delivery.md#sec-iteration-fsd-url) 判断。即使 JSON 中被动包含 `applyProgramId` / `deliveryId`，只要能解析出 `testPlan.id`，**一律优先测试计划**——不因 JSON 里有交付相关字段就改走交付。
15. **`testPlan.id` 为充分条件**：用户消息、附件或工作区内 JSON（如 Automan `.biz/context.json`）**只要**能解析出 `testPlan.id`，即锁定该值为 FSD 测试计划 ID，后续一律按测试计划路径（`fsd test` / `fsd fstPlan`；部署失败排查先 `fsd test jobs --id <id>`，见测试计划节）。**禁止**依据**同文件其它字段**（`applyProgramId`、`targetRepositories`、`stackUuid` 等）改用任意 `fsd delivery * -i` 或独立 `fsd deploy` 作为主入口，除非用户**明确指定**走交付。**job 是否在计划内、环境绑定**以 **`fsd test jobs` / `test detail`** 为准，不以 JSON 列表为准。
16. **测试计划上下文的部署入口 —— 命令必须是 `fsd test deploy`**：存在可解析的 `testPlan.id` 且用户要**触发**「部署 / 发到测试或泳道」时，**必须用且仅用** `fsd test deploy --id <testPlan.id> [--job-name <应用名>] --pretty`（多应用可多次各带 `--job-name`，或用户确认全量后省略 `--job-name`）。**严禁**用 `fsd deploy test`、`fsd deploy swimlane`、`fsd deploy staging` 等独立部署命令触发（注：`fsd deploy test` ≠ `fsd test deploy`，两者完全不同）。**不因** `context.json` 里**任何非 `testPlan.id` 的字段**（含 `stackUuid`、`applyProgramId`）就改走独立部署或先 `swimlane-info`。**例外**：`fsd deploy analyze -i <eventId>` 等只读排错仍可用；用户**主动明确表达**「通过交付部署」「用提测单」等交付意图词时，可走交付路径；用户**明文**要求「不要走测试计划 / 独立部署」时从其意。
17. **测试计划内部署失败 —— 禁止 `delivery` / 误用 `deploy status` 作主查**：在已锁定 `testPlan.id`（规则 15）的前提下，用户讨论的是**该测试计划下 job 的部署失败**时，**严禁**以 `fsd delivery status`（**含** `delivery status --plan …`、`--delivery-id …` 等**臆造或错误**参数）及同类的 `detail` / `records` / `info` / 关键字 `list` 作为排查入口或第一步；**严禁**用 `fsd delivery list` + 多次 `delivery detail -i <新猜的 applyProgramId>` 试图「找到与测计划对应的那条交付」——定因场景下**一律视为违规兜圈**。**严禁**使用 **`fsd deploy status --plan-id <测试计划ID>`**（CLI **无此参数**；测计划 ID **不得**进 `deploy status`）。**严禁**在取得 `eventId` 前用 `fsd deploy status` 搭配 **`--apply-id`**（或任何以交付 ID 代替 eventId 的用法）代替 `test jobs`。**严禁**在 `deploy status` 瞎参数失败后**转去** `fsd delivery status` 找 eventId——eventId **只来自** `fsd test jobs` 输出。**严禁**因「部署」二字、或因先跑 `fsd deploy --help` / `fsd delivery --help` 就改去交付域。**唯一主路径**：`fsd test jobs --id <testPlan.id> --pretty` → `fsd deploy analyze -i <eventId>`（多应用逐个 `eventId`）。`fsd deploy status -i <eventId>` 仅在已有 `eventId` 后按需补查。**`fsd delivery *`** 仅用于用户**明确**要查交付本体时。
18. **测试计划内分支合并风险 —— 命令必须是 `fsd test branch-risk`**：在已锁定 `testPlan.id`（规则 15）的前提下，用户问**分支冲突、合并风险、冲突可能性、能合并吗**（可列举多个应用名）时，**必须用** `fsd test branch-risk --id <testPlan.id> --pretty`（**纯只读**）。**严禁**用 `fsd delivery detail`、`fsd delivery --help`、或任何 **`--delivery-id`**（**臆造参数**）及拿 `context.json` 里的 `deliveryId` / `applyProgramId` 去交付域「对齐」用户列举的应用——与规则 17 同属**测计划 / 交付链混淆**，只是意图词是「风险」而非「部署失败」。
19. **对用户回复 —— 不展示内部路由**：ID 对应与「走测试计划还是交付」只在内部定夺。**不要**输出「确认：…」「应走某路径…」「正在执行…」等对条文或步骤的复述；只给**结果**（CLI 摘要、成败、下一步）。用户追问原因、或需补 ID / 澄清报错时，**最短**说明即可。

## Gotchas / 常见错误速查

| 易错点 | 正确做法 |
|--------|---------|
| 用户说「当前测计划里 XX 应用部署失败」，第一步却执行 `fsd delivery status` 或拿 `applyProgramId` 查交付 | **严禁**：这是最常见误路由；必须先 `fsd test jobs --id <testPlanId> --pretty`，再 `fsd deploy analyze`；见「测试计划语境 vs 交付查询」专节与核心规则 17 |
| 用 `fsd delivery status --plan <测试计划ID>`、`fsd deploy status --apply-id <交付ID>`，或 `delivery list` 换多个 `detail -i`「对齐」测计划后再分析部署失败 | **严禁**：与测计划 job 失败**不是同一条数据链**；仍须先 `fsd test jobs --id <测试计划ID> --pretty` 取 **`eventId`**，再 `fsd deploy analyze`；禁止用 help/交付试探代替该链路 |
| 用 `fsd deploy status --plan-id <测试计划ID>` 失败后转 `fsd delivery status --delivery-id …` | **严禁**：`deploy status` **无** `--plan-id`；`delivery status` **无** `--delivery-id`（应为 `-i applyProgramId`，且定因场景下仍不能替代 `test jobs`）。必须先 `fsd test jobs --id <测试计划ID> --pretty` |
| 误跑 `fsd deploy status --plan <id>` → `fsd delivery status --plan <id>` → `delivery detail -i <applyProgramId>` → `fsd testPlan --help` | **严禁**：与「用 `--plan-id`」同构；**全程**不得替代 **`fsd test jobs --id <id> --pretty`**。不要用 `testPlan` 子命令当测计划 job 入口 |
| `context.json` 有 `applyProgramId`，查 `delivery detail` 发现泳道/stack 与 **`fsd test jobs` / `test detail` 所反映的当前测计划环境** **不一致**，仍继续用该交付或把 **stackUuid** 当 `deploy status -i` 排查 | **严禁**：定因与路由以**平台测计划数据**为准，**不要**拿 JSON 里的 `testPlan.swimlane` / `stackUuid` 与交付侧做「对齐」依据；不一致说明**不是同一条定因链**；**停止**交付路径，改 `fsd test jobs --id <testPlan.id>` → `deploy analyze`。**`-i` 只能是数字 eventId**，不是 UUID。示例 → [deploy-failure-routing.md#sec-automan-context-trap](references/deploy-failure-routing.md#sec-automan-context-trap) |
| 测试计划上下文用 `fsd autotest execute` 触发自动化 | **必须用 `fsd fstPlan trigger`**，否则结果不关联测试计划卡点 |
| FSD URL 含 `testPlanId=XXXX`（如 `fsd.sankuai.com/test/detail?testPlanId=62141`）时，将 `XXXX` 作为 `autotest execute --plan-id XXXX` 参数 | **`testPlanId` = FSD 测试计划 ID，命中优先级 2，必须用 `fsd fstPlan trigger -i XXXX --pretty`，禁止走 `autotest execute`**。`--pretty` 内置轮询即为监控手段，**触发后禁止再调 `fsd autotest status`**；如需检查 FST 卡点是否通过，用 `fsd test summary --id XXXX --gate-check --pretty` |
| 已给**交付 ID**却要「只跑交付上绑定的 FST」却误用 `fstPlan` | **交付侧用 `fsd delivery fst`**（`source=testApply`）；`fstPlan` 为测试计划（`source=testPlan`） |
| `--interface-name` 用 HTTP 路径 | `find-cases` 的 `--interface-name` 必须用入口层 `类名.方法名`（如 `DbController.branch`） |
| 用 `skip-steps` 跳过「构建部署」「卡点」「准出」等 | **不允许**：须通过 **`delivery trigger` / `trigger-retry`** 重跑检测 |
| 遇到冲突时将 `qa`/`staging` 合并进源分支 | **严禁反向 merge** |
| 用户指定了具体应用名却执行 `fsd test deploy --id <id>` 不加 `--job-name` | **必须加 `--job-name <应用名>`**，否则测试计划下所有应用都会被部署 |
| 已有 `testPlan.id`（或 context JSON）却用 `fsd deploy swimlane -a … -u <stackUuid>`（或 `--uuid`）逐个部署，或先 `swimlane-info` 再 `swimlane` | **禁止**：须 `fsd test deploy --id <测试计划ID> --job-name <应用名> --pretty`（每个应用一条）；**不得**从 `context.json` 抄 `stackUuid` 走独立泳道——与测计划「部署环境」步骤/记录不一致；环境绑定以 **`fsd test jobs` / 平台** 为准 |
| context.json 包含 `testPlan.id` 和 `applyProgramId`，却因为有 `--apply-id` 而用独立 `fsd deploy` | **禁止**：`context.json` 中被动包含的关联 ID 不算「主动指定」；仅当用户**明文说**「通过交付部署」「用提测单」时才走交付；否则必须用 `fsd test deploy --id <testPlanId>` |
| 用户列举多个失败应用（如「waimai-qa-deploy-test-web 和 waimai-qa-deploy-test-jar 部署失败」）却跳过 `fsd test jobs` 直接凭应用名分析 | **禁止**：必须先 `fsd test jobs --id <testPlanId> --pretty` 获取各失败应用的 `eventId`，再逐条 `fsd deploy analyze -i <eventId>` 定因；**禁止**在无 `eventId` 时臆测原因或打开源码推断 |
| 已有 `testPlan.id`，对话却先走 `fsd delivery status / detail / list / show` 查交付 | **严禁**：违反规则 14、15、16、17。**触发部署**须直接 `fsd test deploy --id <testPlanId> --job-name …`。**部署失败定因**第一步须 `fsd test jobs --id <testPlanId> --pretty`。**分支合并风险**第一步须 `fsd test branch-risk --id <testPlanId> --pretty`（见上文专节与规则 18）。不论 JSON 里有无 `applyProgramId`、`deliveryId`，都**禁止**把它们当上述问题的主入口；用户**明文说**「查交付」「看交付状态」时才可主查 `fsd delivery *` |
| 在测试计划上下文中部署失败，因为 context.json 有 `applyProgramId` 就用 `fsd delivery status/info/detail -i <id>` 查询 | **严禁**：被动包含的 `applyProgramId` 可能关联完全不同的交付计划（如标品图合规），与当前测试计划无关；必须忽略该 ID，直接 `fsd test jobs --id <testPlanId> --pretty` 取 `eventId`，再 `fsd deploy analyze -i <eventId>` |
| 用户问「分支会冲突吗」「合并风险」「能合并吗」却用 `fsd pr list` / `fsd delivery --help` / `fsd delivery detail --delivery-id <数字>`（**CLI 无 `--delivery-id`**）查交付 | **严禁**：必须用 `fsd test branch-risk --id <testPlanId> --pretty`（纯只读，本地 Git）；**禁止**用 PR 或交付域代替；与「部署误走 `deploy test`」同属**测计划语境被带偏**，见规则 18 |
| 已有 `testPlan.id`，用户要「部署两个应用到测试环境」，却用 `fsd deploy test -a <应用>` | **严禁**：`fsd deploy test` ≠ `fsd test deploy`。正确命令是 `fsd test deploy --id <testPlanId> --job-name <应用> --pretty`（多应用多次执行或省略 `--job-name` 全量）；**禁止**用独立部署命令代替 |
| 读了 `context.json`，发现 **`targetRepositories` 等列表里没有**用户点名的应用，就改用 `fsd deploy test -a`「补部署」 | **严禁**：测计划有哪些服务**不依赖**该文件；**只从 context 取 `testPlan.id`**，job 列表用 **`fsd test jobs --id <testPlanId> --pretty`**（必要时辅以 **`fsd test detail`**）向平台核对；触发部署仍 **`fsd test deploy --id <testPlanId> --job-name <名> --pretty`**。仅当 CLI/平台明确报错 job 不属于计划时再与用户对齐，**禁止**未查 `test jobs`、未试 `test deploy` 就先 `fsd deploy test -a` |

---

## 应用查询（fsd app）

`find` / `find-by-appkey` / `job-owners` / `branch-create` / `branches` / `jar-info` / `jar-deploy` → 详见 [deploy.md](references/deploy.md)；负责人字段与 appkey 解析见 [app-job-owners.md](references/app-job-owners.md)

---

## 部署（fsd deploy）

`test` / `staging` / `swimlane --create` / `swimlane -u <uuid>` / `templates` / `status -i <eventId>` / `analyze -i <eventId>` → 详见 [deploy.md](references/deploy.md)。**应用维度**下模板列举与 `--deploy-template` → 详见 [deploy.md · 应用维度独立部署与部署模板](references/deploy.md#sec-app-dimension-deploy-templates)。**`status` 输出中的部署机器 IP**（`data.serviceDeployIps`、`--no-service-ips`）→ 详见：[deploy.md · 部署进度与部署机器 IP](references/deploy.md#部署进度与部署机器-ip)。**部署失败 / 定因 / 修复**：先 [deploy-failure-routing.md](references/deploy-failure-routing.md)，再按需读本节与 `deploy.md`。

**场景路由**：骨干/test/qa → `test`；备机/staging → `staging`；泳道/cargo → `swimlane`；未提及 → `test`。分支默认值：`-t` 骨干=`qa`/备机=`staging`/泳道=当前分支；`-d` 优先 `git branch --show-current`。

**测试计划上下文（覆盖本节「泳道」路由）**：若已能解析 `testPlan.id`，用户要部署到该计划关联环境时**不要**用本节 `fsd deploy swimlane` / `fsd deploy test` 触发，一律走同文档「测试计划（fsd test / fsd fstPlan）」节中的 `fsd test deploy`（见核心规则 16）。**部署失败定因**：须先有 `fsd test jobs` 给出的 **`eventId`**，再用本节 `analyze`；**不要**在未跑 `jobs` 前用本节 `status`（**无** `--plan-id`；**仅** `-i <eventId>`，不是测试计划 ID、**不是** `applyProgramId`）；**禁止**用虚构或误传的 `--plan-id` / `--apply-id` 与 `status` 组合替代 `test jobs`（见核心规则 17）。本节其余命令仍按 [deploy.md](references/deploy.md) 使用。

**交付上下文优先路由**：若用户已指定交付（URL 或 ID），**部署服务 / 部署环境**用 **`fsd delivery trigger -i <id> -n 部署环境 --pretty`**（`triggerPipeline` 裁剪到部署节点；与交付详情「环境部署」同属自测流水线路径）。**仅 `-n` 为单个「部署环境」且未传 `--env` 时**，若详情曾带 `stackUuid`，CLI 会**清栈按骨干 test** 触发（避免误走泳道制品）；用户明确要**泳道栈上**跑该节点须加 **`--env swimlane`**；口语「test 骨干 / 测试环境」可写 **`--env test`** 或 **`--env 测试环境`**。**跑完整自测流水线**（整链或指定 `-n` 多节点）时用 **`fsd delivery trigger -i <id> --pretty`** 或按需加 **`-n`**。仅当不满足交付路径时才退回独立 **`fsd deploy`**。`--env` / `--deploy-template`（及独立 **`fsd deploy`** 的 **`--deploy-template`**）详见 [delivery.md · 环境与部署模板](references/delivery.md#delivery-deploy-env-template)。意图路由：

| 用户意图 | 命令 |
|----------|------|
| **部署服务 / 部署环境（默认）** | **`fsd delivery trigger -i <id> -n 部署环境 --pretty`**；备机/泳道/分支等参数与 **`delivery trigger`** 一致 → [delivery.md · trigger -n](references/delivery.md#delivery-trigger-与指定节点-n) |
| **跑完整自测流水线** | `fsd delivery trigger -i <id> --pretty`（不传 `-n`） |
| **自测流水线里只跑某些节点**（含用户明确要「流水线里的」部署/构建/Sonar/自动化等） | `fsd delivery trigger -i <id> -n <节点关键词> --pretty`（`-n` 映射见 [delivery.md](references/delivery.md#delivery-trigger-与指定节点-n)） |

退回条件与完整参数 → [deploy.md · 交付上下文优先路由](references/deploy.md#交付上下文优先路由)

**上线计划备机 / liteSet 部署**：备机须走 `fsd deploy staging --online-program <上线计划ID> [-a <appkey>] [-t <分支>] [--apply-id <交付ID>]`；liteSet 在同命令上加 **`--env liteSet`**（仅 `isLiteSetPlus` 应用；模板/set 与校验规则见 [pub.md · liteSet](references/pub.md#上线计划-liteset-部署)）。勿用独立 `fsd deploy staging -a ... -t ...` 代替上线计划路径。**失败排查**：`fsd pub record -i <上线计划ID> -t deploy`，禁止 `fsd deploy analyze`（eventId 体系不同）。**

**监控**：独立部署加 `--pretty` 内部自动阻塞至终态，失败时 `fsd deploy analyze -i <eventId>`；上线计划部署内置轮询，失败时 `fsd pub record -i <id> -t deploy`。专项排查 → [troubleshooting.md](references/troubleshooting.md)

---

## 交付（fsd delivery）

**与测试计划互斥（查询侧）**：若当前任务已锚定 **FSD 测试计划 ID**（规则 15、「测试计划语境与命令路由」专节），且用户问的是**该计划内应用部署失败 / 部署状态**——**不要**用本节 `status`（**含**误传的 `--plan <测试计划ID>`）/`detail`/`list`/`records` 等去「对齐」部署问题；**不要**用 `list` 换多个 `detail -i` 猜交付 ID。交付侧状态**不能**替代 `fsd test jobs` + `fsd deploy analyze` 链路。本节用于**交付计划本体**（`fsd delivery`：创建、触发流水线、准出、明日上线等）或用户**明确要求**查交付时；**「迭代」一词不单独定义本节是否适用**（见术语表与 [delivery.md · 迭代与 FSD 链接](references/delivery.md#sec-iteration-fsd-url)）。

`list`（含 `--online-tomorrow` 明日上线筛选） / `detail` / `status` / `prep` / `online-notice` / `create` / `edit` / `delete` / `trigger` / `trigger-retry` / **`stop-pipeline -e <eventId>`（终止运行中的交付自测流水线）** / `skip-steps` / `gate` / `deliver-qa` / `check` / `finish` / `records` / `record-detail` / `requirement-branches` / `med-test-plan`（客户端 Med → 测试计划 ID） / `ones` / **`fst list|trigger|result|stop|retry`（交付维度 FST，`source=testApply`）** → 详见 [delivery.md](references/delivery.md)（**`record-detail` 与各服务 `serviceDeployIps`：**详见 [delivery.md · record-detail 与部署机器 IP](references/delivery.md#record-detail-与部署机器-ip)；**stop-pipeline 与测试计划 revoke-deploy 区别**见 [test-plan.md](references/test-plan.md)，勿写入本文件细则）

**标识符**：所有 `-i` 统一用 **`applyProgramId`**，**禁止**用列表 `id`。编辑成功后**不自动串联**其他命令。

**创建路由**：用户意图 → `fsd delivery create`，缺省项由 CLI 自动补全（分支/服务/Ones）；无 Ones 关联 → `fsd delivery ones --pick-json`。场景 `-e` → [delivery.md · 交付类型与场景决策](references/delivery.md#交付类型与场景决策)

**仅触发流水线**：`fsd delivery trigger -a <服务名> -b <分支名> --pretty`，不必先创建交付；`--pretty` 内置轮询，**禁止**额外调 `records`/`status`。

**liteSet（`--env liteSet`）**：参数、`trigger-retry`、校验失败与助手禁止去参重试等 → [delivery-liteSet-trigger.md](references/delivery-liteSet-trigger.md)。

**staging 备机按 set 选机**（`--staging-set` 全局并集、`--staging-set-job` 按应用；与 `getMachineByJobNames` 的 `cell` 对齐）：详见 [delivery.md · staging set](references/delivery.md#delivery-staging-set)。

### 准出终局路由

| 交付类型 | projectType | 完成动作 | 禁止 |
|----------|-------------|---------|------|
| 标准交付 | 4 | `gate`（默认含自动复检）→ `deliver-qa` | ~~`finish`~~ |
| RD 自测 | 1 | `gate` → `check` → `finish` | ~~`deliver-qa`~~ |

gate 三步复检细则 → [delivery.md · gate](references/delivery.md#gate-准出检测)

**上线注意事项 / 明日上线**：`online-notice`、`prep`、`list --online-tomorrow` 等意图与命令路由 → [delivery.md · 上线注意事项与明日上线](references/delivery.md#上线注意事项与明日上线)

---

## 覆盖率 & 扫描

`fsd sonar -a/-b` / `fsd coverage -a/-b`（备机 `-e staging -t staging`；泳道 `--swimlane`）/ `fsd coverage status -i <report_id>`

---

## 自动化测试（fsd autotest）

`execute` / `execute-appkey` / `execute-case-set` / `find-cases` / `status` / `coverage` / `coverage-trace` / `execution-case-list` / `case-log` / `fsd autoproject info` / `claw` / `case-list` → 详见 [autotest.md](references/autotest.md) | [autoproject.md](references/autoproject.md)

**优先级路由**（高 → 低，命中第一条即止）：

| 优先级 | 条件 | 执行路径 |
|--------|------|----------|
| 1（最高）| 上下文同时存在测试计划与交付，且用户**未明确指定**走交付 | **测试计划（fsd test / fsd fstPlan）**（见核心规则 14） |
| 2 | 已能唯一定位 **FSD 测试计划**（测试计划 ID；勿与 `autotest --plan-id` 混淆）。**URL 识别**：`fsd.sankuai.com/test/detail?...testPlanId=XXXX` 中的 `testPlanId` 即为 FSD 测试计划 ID | **测试计划（fsd test / fsd fstPlan）** 节 `fstPlan trigger -i XXXX --pretty`（与卡点关联，**禁止**用 `autotest execute` 代替） |
| 3 | 已能唯一定位**交付**（`applyProgramId`）且上下文无测试计划 | **交付（fsd delivery）** 节 `delivery fst`（`source=testApply`） |
| 4（最低）| 无交付、无测试计划 | 本节 `fsd autotest` + 下方决策路由 |

**execute-appkey 场景计划推荐与执行规则**：完整规则见 [autotest.md](references/autotest.md)「AI 场景计划推荐规则」章节。核心：查到多个计划时，快捷路径（无交付上下文+泛化触发）直接执行研发自测类；其他情况推荐一个计划后等用户确认，禁止自动执行。

**决策路由**（在已按上文排除 `delivery fst` / `fstPlan trigger` 的前提下）：查改动覆盖用例 → `find-cases` 流程；备机上下文 → `execute-appkey --deploy-env staging`；具备 `autotest execute` 所需 `plan-id` → `execute --plan-id`；给了 appkey → `execute-appkey`；以上皆无 → `execute-appkey`（自动查找 appkey）

**监控**（仅适用于优先级 3：`autotest execute` / `execute-appkey` / `execute-case-set`；**禁止**用于优先级 1/2 的 `delivery fst` / `fstPlan trigger`）（禁止 sleep 轮询和 tail）：步骤1 `fsd autotest status --execute-id <ID> --plan-id <ID> --monitor 10s`（返回日志路径）→ 步骤2 `--observe <日志路径>`（实时观察，自动完成退出）

**`fstPlan trigger` 监控路径**（优先级 2）：`--pretty` 内置轮询即为终态；触发返回后如需验证卡点，用 `fsd test summary --id <testPlanId> --gate-check --pretty`，**禁止接 `fsd autotest status`**

---

## 需求管理（fsd req）

| 命令 | 用途 | 关键参数 |
|------|------|----------|
| `fsd req list` | 查询我的需求列表 | `--page`；`--size`；`-p`；`-s` 状态（支持快捷词：未上线/进行中/未开始/已完结，或精确状态如 开发中/测试中）；`--subtype` 需求类型（产品需求/技术需求/默认任务/管理事项/其他）；`-n` 关键词；`--assigned`；`--created-by`；`--start-time`/`--end-time`；`--priority`；`--pretty` |
| `fsd req pd` | 当前用户按日需求工时(PD) | `--start`/`--end` 毫秒时间戳（须成对，否则默认本周）；`--subtype`；`-s`；`--priority`；`-p` 多空间；`-n`；`--pretty`；`-v` |
| `fsd req schedule` | 团队需求排期甘特 | 组织固定为当前用户部门（不可指定）；`--start`/`--end` 毫秒时间戳（须成对，否则默认本周一至周日）；`--mis`；`--subtype`（同 list）；`-n`；`--priority`；`-p` 多空间逗号分隔；`--page`/`--size`；`--pretty`（需求整体阶段→任务阶段+时间）；`-v` |
| `fsd req create` | 创建需求 | `-p` 空间ID（不传则自动使用最近空间）；`-n` 名称；`--subtype`（产品需求/技术需求）；`--priority`；`-a`；`-d` 描述HTML；`-v` |
| `fsd req detail` | 查询需求详情 | `-i` 需求ID（必填）；`--pretty` |
| `fsd req relate` | 按 Ones **issueId** 查关联**交付**列表并汇总 **testPlanId**（去重） | `-i` / `--issue-id`（必填）；`--pretty`；`-v` 完整接口 data；详见 [req.md#getlistbyissueid](references/req.md#getlistbyissueid) |
| `fsd req update` | 修改需求 | `-i`（必填）；`-p`；`-n`；`--priority`；`-a`；`-d` 其他字段JSON（`--data` 同名键覆盖快捷字段） |
| `fsd req delete` | 删除需求 | `-i`（必填） |
| `fsd req project` | 按名称查询空间详情 | `-n` 空间名称（必填，精确匹配）；`-v` 输出完整JSON（默认人类可读格式，会标注 projectId） |
| `fsd req stage` | 查询或变更状态 | `-i`（必填）；`--to` 目标状态（不传则展示可流转列表）；`--form` 表单JSON；`-v` |
| `fsd req bind-branch` | 分支绑定需求 | `-i` 需求ID（必填）；`-b` 分支名（默认当前分支）；`-g` Git 地址（默认当前工程）；`-j` 服务名 |

**创建需求行为：** 参数均可选，CLI 自动补全（空间=最近使用的第一个，名称=`新需求_日期`，类型=产品需求）。创建成功后必须展示链接。

详细参数与决策树 → [req.md](references/req.md)

---

## 任务排期（fsd task）

| 命令 | 用途 | 关键参数 |
|------|------|----------|
| `fsd task list` | 查询我的任务列表 | `--page`；`--size`；`-n`；`-s` 状态；`--subtype` 类型（支持中文/英文/别名）；`--assigned`；`--created-by`；`-p`；`-r`；`--schedule-range`（today/this-week/next-week/日期/日期范围）；`--pretty` |
| `fsd task create` | 创建任务 | 参数均可选；缺省时 CLI 打印需求/空间/排期候选表并退出，需补齐后重试。`-p`；`-n`；`--task-type`；`-r`；`-a`；`--start-time`/`--end-time`；`--schedule '{json}'`；`--bind-branch` |
| `fsd task detail` | 查询任务详情 | `-i`（必填）；`--pretty` |
| `fsd task update` | 修改任务 | `-i`（必填）；`-n`；`--priority`；`-a`；`--data '{json}'` |
| `fsd task delete` | 删除任务 | `-i`（必填） |
| `fsd task edit-schedule` | 修改任务排期 | `-i`（必填）；`--task-type`；`--start-time`/`--end-time`；`--schedule '{json}'`；`--clear <阶段名>` |
| `fsd task stage` | 查询或变更状态 | `-i`（必填）；`--to` 目标状态（不传则展示可流转列表）；`--form` 表单JSON；`-v` |
| `fsd task create-branch` | 创建分支 | `-b` 分支名（必填）；`-f` 迁出分支（默认 master）；`-j` 服务名（默认当前工程）；`-i` 关联工作项ID |
| `fsd task bind-branch` | 分支绑定任务 | `-i` 任务ID（必填）；`-b` 分支名（默认当前分支）；`-g` Git 地址（默认当前工程） |

**创建任务行为：** 助手**必须先执行 `fsd task create`**（拼上用户已给的参数），由 CLI 输出告知缺失信息（需求/空间/排期阶段）。**用户话语中包含任务类型名或别名（如"开发任务""测试""默认任务"）时，必须加 `--task-type`**，否则 CLI 按角色自动判断可能与用户意图不符。**禁止不执行 CLI 就自行编造排期阶段名称**——不同任务类型的排期阶段不同，只有 CLI 输出才是准确的。CLI 输出的排期阶段表**每一行都必须完整展示**，不得省略、重排或丢弃任何阶段。排期时间禁止 AI 自行填充，必须等用户明确提供日期。**排期时间直接传日期字符串**（如 `--start-time 2026-03-01 --end-time 2026-03-02`），**禁止助手自行计算毫秒时间戳**，CLI 内部自动处理时区转换。创建成功后必须展示链接。
**任务类型（6种）：** developOnline（开发任务）、qaOnline（测试任务）、product（产品任务）、design（设计任务）、algorithm（算法任务）、default（默认任务）。注意"默认任务"是正式类型名，不等于"不指定类型"。
**任务类型 vs 状态（易混淆）：** `--subtype` 是任务分类（开发任务/测试任务/产品任务等）；`-s` 是任务进度（待处理/进行中/已完成）。"查进行中的测试任务" → `-s 进行中 --subtype 测试任务`。

**排期筛选（重要）：** 用户说"查今天/本周/下周/某天有排期的任务"时，**必须使用 `--schedule-range` 参数**，禁止先拉全量列表再手动过滤。示例：`fsd task list --schedule-range this-week --pretty`。

详细参数与决策树 → [task.md](references/task.md)

---

## 测试计划（fsd test / fsd fstPlan）

| 命令 | 用途 | 关键参数 |
|------|------|----------|
| `fsd test create` | 创建测试计划 | `-n`；`--delivery-ids` 提测单；`--env`；`--swimlane`/`--create-swimlane` |
| `fsd waitTest accept` | 已有计划上挂提测单 | `-i` `-w`；其余可省略，CLI 按计划详情补全 → [wait-test.md](references/wait-test.md) |
| `fsd test update` | 更新测试计划 | `--id` 必填；其他同 create |
| `fsd test detail` | 查询详情/进度 | `--id`；`--pretty` |
| `fsd test summary` | 准出检测/卡片详情 | `--id`；`--gate-check --pretty`；`--card <key>`；可配 `--auto-finish` |
| `fsd test finish` | 确认测试完成 | `--id`；`--pretty` |
| `fsd test confirm-config` | 确认配置变更（侯羿卡点） | `--id`；`--pretty` |
| `fsd test config-change-info` | 查询配置变更详情（houyiV2） | `--id`；`--pretty` |
| `fsd test coverage` | 覆盖率详情 | `--id` |
| `fsd test refresh-coverage` | 刷新覆盖率 | `--id`；`-j` |
| `fsd test skip-coverage` | 跳过覆盖率卡点 | `--id`；`-j`；`-r` |
| `fsd test jobs` | **只读**查询应用列表及部署状态（不触发任何操作） | `--id`；`--pretty` |
| `fsd test trigger-pipeline` | 测试计划维度跑流水线 | `--id`；`--pretty` |
| `fsd test deploy` | 仅触发「部署环境」步骤 | `--id`；`--job-name <应用名>`（指定单个应用，不传则部署全部）；`--include-non-delivery-jobs`（含非提测应用）；`--pretty` |
| `fsd test stop-pipeline` | 终止运行中的测试计划流水线（同源 `stopPipelineByEventId`） | `--id`；`-e` / `--event-id`；细则见 [test-plan.md](references/test-plan.md) |
| `fsd test deploy-records` | 测试计划部署/流水线记录列表 | `--id`；`--page`；`--size`；`--source`；`--pretty` |
| `fsd test deploy-progress` | 单条部署记录明细 / 刚部署后查最新 | `--record-id` 或 `--plan-id --latest`；`--domain-name`；`--pretty` |
| `fsd test revoke-deploy` | 撤销测试计划环境部署记录（`revokeDeployById` / **recordDetailId**） | `--id`；`-r` / `--record-detail-id`；与交付详情页 preBuild 撤销（**applyRecordDetailId**，无 CLI）区分见 [test-plan.md](references/test-plan.md) |
| `fsd test progress` | 测试进度预估 | `--id`；`--pretty` |
| `fsd test branch-risk` | 分支合并风险分析（本地 Git）：多分支文件重叠 / 冲突预判 / 部署分支落后 master commit 数 | `--id`；`--work-dir`；`--pretty` |
| `fsd test skip-ec` | 跳过用例执行卡点 | `--id`；`--issue-ids`；`-r`；`--pretty` |
| `fsd test list` | 测试计划列表 | 默认「与我相关」最近 30 天；`--team` 查我团队；`--online-time-days` 指定最近 N 天（1-30，默认 30） |
| `fsd test delete` | 删除测试计划 | `--id` |
| `fsd fstPlan list` | 查看测试计划绑定 FST 列表 | `-i`；`--pretty` |
| `fsd fstPlan bind` | 测试计划关联/绑定 FST 计划 | `-i`；`--plan-ids` / `--payload` |
| `fsd fstPlan unbind` | 测试计划解绑/解除关联 FST 计划 | `-i`；`--plan-ids` / `--bind-ids`；`-r` |
| `fsd fstPlan trigger` | 测试计划内批量触发 FST 计划执行 | `-i`；`--plan-ids`；`--ips`；`--pretty` |
| `fsd fstPlan stop` | 终止单次 FST 执行 | `-i`；`--plan-id`；`--execute-id`（= fstRecordId / 页面 fstExecuteId） |
| `fsd fstPlan retry` | 重试 FST（已执行记录） | `-i`；`--plan-id`+`--execute-id` 或 `--items` 或 `--payload`（retryVo） |
| `fsd fstPlan skip` | 跳过 FST 卡点 | `-i`；`--plan-ids`；`-m` |

**部署路由（强制）**：触发「部署环境」**仅**用 `fsd test deploy`；**禁止**因 `stackUuid` 改用 `fsd deploy swimlane`（与 [test-plan.md · deploy](references/test-plan.md#sec-test-deploy-merge) 一致）。多应用可多次各带 `--job-name`，或确认后省略部署全部 job。

**liteSet（`--env liteSet`）**：`test deploy` / `trigger-pipeline` 参数与校验失败、助手禁止去参重试 → [test-plan-liteSet.md](references/test-plan-liteSet.md)（与交付对齐的细则见同页所链 [delivery-liteSet-trigger.md](references/delivery-liteSet-trigger.md)）。

**分支合并风险**：用户说「分支会冲突吗」「合并风险」「分支冲突」等 → **必须** `fsd test branch-risk --id <id> --pretty`（**纯只读**，禁止 merge/commit/push；单次 Shell 调用完成）。**禁止**改用 `fsd pr list`、`fsd delivery --help` 等其他命令兜圈；分支风险分析是测试计划的专项功能，必须走测试计划路线。详见 [test-plan.md · branch-risk](references/test-plan.md#sec-branch-risk)。

**部署状态/报告摘要**：**直接执行 `fsd test jobs --id <id> --pretty`** 汇总。**严禁**在报告中串联 `deploy-progress` / `deploy-records`。展示模板 → [test-plan.md · test jobs 与部署报告摘要](references/test-plan.md#sec-test-jobs-deploy-report)。

**部署失败排查**：**必须先** `fsd test jobs --id <testPlan.id> --pretty` 取失败应用 `eventId`，再逐条 `fsd deploy analyze -i <eventId>` 定因（多应用同理，逐个 analyze 后统一输出）。**禁止**跳过 jobs 凭应用名臆测、**禁止**无 CLI 输出时假装已读日志、**禁止**打开源码推断。完整流程与禁止项 → [test-plan.md · 部署失败排查](references/test-plan.md#sec-test-deploy-failure)。**多语境入口**（测试计划 / 交付 / pub / 裸 eventId）的一页速查 → [deploy-failure-routing.md](references/deploy-failure-routing.md)。

**自动化卡点：** 测试计划下须 `fsd fstPlan trigger`，禁止 `fsd autotest execute`。**计划 ID：** `fstPlan trigger` / `test finish` / `test delete` 等见 [test-plan.md · 测试计划 ID 策略](references/test-plan.md#test-plan-id-policy) 与 [fst-plan.md · trigger 决策树](references/fst-plan.md#sec-fst-trigger-dt)（本条含数字 ID，或上下文唯一 ID 经用户确认；禁止 `test list` 后默认第一条）。

**`test list` 展示：** 默认「与我相关」；向用户转述列表时须说明当前范围（勿在摘要中省略）→ [test-plan.md · list](references/test-plan.md#sec-test-list)。

**准出：** 检测须带 `--gate-check`；**禁止**跳过 gate-check 直接 `finish`。可选用 `fsd test summary --id <id> --gate-check --auto-finish --pretty` 在通过时自动完成；分步卡点 → [test-plan.md · 准出工作流](references/test-plan.md#sec-gate-workflow)。

测试计划 CRUD/准出/部署与流水线/卡片 key/示例 → [test-plan.md](references/test-plan.md)；FST 绑定与触发 → [fst-plan.md](references/fst-plan.md)

---

## 缺陷管理（fsd defect）

**缺陷列表**：测试计划维度 `fsd defect list -p <planId>`；**迭代详情页**（`/fsdIteration/detail/{id}`）`fsd defect list --iteration <id>`，与 `-p` 互斥。`fsd defect fields` / `[--criteria]`。**criteria 核心规则**：① `fieldName` 用 `fieldCode`（非中文）；② `specifiedValue` 用枚举 `key`（非显示名）；③ `operator` 看 `isMultiple`：0 用 `equalTo`，1 用 `in`。完整规则与示例 → [defect.md](references/defect.md)

**测试计划质量分析**:请对当前测试计划的所有缺陷进行智能问题定位分析,完整工作流 → [defect-workflow.md](references/defect-workflow.md)

**缺陷洞察查询**：`context` / `query` / `req-extend` / `req-insight` / `fix-report` / `fix-reports` / `cases-by-defect`。**约束**：`--operator` 只能填当前用户 MIS；`--req-id` 与 `--test-plan-id` 互斥。意图路由 → [defect-insight.md](references/defect-insight.md)

**缺陷报告生成与提交**：`trace` / `select-rd` / `submit`。AI 生成 Markdown 缺陷报告 → 询问用户确认 → `select-rd` + `submit`。完整架构 → [defect-submit.md](references/defect-submit.md)

---

## PR 管理（fsd pr）

`create` / `list` / `detail` → 详见 [pr.md](references/pr.md)

上线 `fsd pub pre-rtag` 的「PR检查」失败时 → `fsd pr create` → 审批通过后重新 pre-rtag。审核人由 CLI 自动获取，失败时**必须向用户询问** `--reviewer`，**禁止**用 `adminRd` 代替。

---

## 上线计划（fsd pub）

`list` / `info` / `status` / `create` / `edit` / `update-base-info` / `search-delivery` / `add-delivery` / `add-job` / `jobs` / `pre-rtag` / `merge` / `rtag` / `bind` / `replace-version` / `record` / `rtag-detail` → 详见 [pub.md](references/pub.md)

**命令路由（必须区分）**：

| 用户意图 | 命令 |
|----------|------|
| 看状态/看进度/看情况/check状态 | `fsd pub status -i <id>`（轻量：基本信息 + 应用列表） |
| 上线检查/能不能打rTag/前置检查/上线流程中的校验步骤 | `fsd pub pre-rtag -i <id>`（重量级：逐项校验） |

**`pre-rtag` 只在上线流程中明确需要校验前置条件时使用，其他一切"看看状态/进度"场景用 `status`。**

**上线流程**：确定/创建计划 → 确保应用在计划中 → pre-rtag → 修复 fail 项 → 全部 success → rtag。交付加入计划先 `pub list --apply-id` 查推荐计划。AI 创建新计划名称自动补 `-ai` 后缀。

---

## 端到端工作流

1. 创建需求/任务 → 2. 部署并监控至终态 → 3. 自动化测试并监控 → 4. 查询覆盖率 → 5. 上线发布（pub: 确定计划 → add-job → check → 修复 → rtag）

### 上下文智能

- **JSON 含 `testPlan.id`**：仅此即可视为测试计划上下文，优先于交付路由；**从 Automan `context.json` 只取 `testPlan.id`（或顶层 `testPlanId`）用于 `--id`**，**部署相关的 job/环境信息以 `fsd test jobs`、`fsd test detail` 等平台命令为准**，勿用文件里的 `targetRepositories`、`stackUuid` 等决定路由。部署失败、查状态、触发流水线等均从 `fsd test` / `fsd fstPlan` 切入，勿凭猜测使用 `delivery -i`。**部署失败**时**禁止**先 `fsd delivery status`（见核心规则 17、「测试计划语境 vs 交付查询」专节）。
- **已有交付上下文**：部署/流水线走 `fsd delivery trigger`；自动化传 `--test-apply-id <applyProgramId>`；覆盖率从交付的 `swimlaneId`/`stackUuid` 补全 `--swimlane`（与上条并存时仍**以测试计划为准**，见核心规则 14、15）
- 部署返回 `appKey` 且用户未指定 → 复用该 appKey；部署备机 → 后续自动化和覆盖率也走 `--env staging`
- 执行前告知环境："在 {泳道ID} 泳道执行" 或 "在骨干执行"
- **服务名/分支未提供时**：不传 `-a`（CLI 自动通过 git remote 查找）；`-d` 优先 `git branch --show-current`，失败则不传（不询问用户）
