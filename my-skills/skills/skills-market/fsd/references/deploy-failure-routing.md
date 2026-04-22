# 部署失败排查：语境路由（速查）

> **本文件为 FSD 技能内「部署失败 / 定因 / 修复建议」的唯一起点**：先按下方顺序选入口，再执行 CLI；**禁止**跳过本节、凭「部署」二字默认 `fsd delivery status` / `detail` / `list`。细则与禁止项仍以 [SKILL.md](../SKILL.md) 核心规则 14–17、[troubleshooting.md](troubleshooting.md)、[deploy.md](deploy.md) 为准。

## 命中顺序（从上到下，命中即停）

1. **已锚定 FSD 测试计划**（`testPlan.id` / 顶层 `testPlanId` / 工作目录 `…/plan_<数字>/…` / URL `testPlanId=`）且用户问的是**该计划里某应用的部署失败**  
   → **只用测试计划链**，不要用交付去「对齐」部署。**不要**先跑 `fsd deploy --help` / `fsd deploy status --help` / `fsd delivery --help`，也**不要**在 `plan_*` 下 `find` 日志代替本条——均属兜圈。  
   - `fsd test jobs --id <测试计划ID> --pretty`  
   - 按失败 `jobName` 取 **`eventId`**  
   - `fsd deploy analyze -i <eventId>`（多应用逐个 eventId）  
   - 需要进度时再 `fsd deploy status -i <eventId>`（**仅**在已有 eventId 之后）

2. **上线计划（pub）里的部署失败**  
   → `fsd pub record -i <上线计划ID> -t deploy`（**不要**用本页的独立部署 `deploy analyze` 体系代替，eventId 链路不同）。详见 [SKILL.md · 上线计划备机部署](../SKILL.md)。

3. **纯交付语境**（用户**明确**在查某条**交付**（含已用链接锚定为 `testApplyDetail` / `applyProgramId`），已给出或可唯一定位 **`applyProgramId`**；且**没有**可解析的测试计划 ID 需要优先；**勿**仅凭用户说「迭代」就默认本条）  
   → 从交付流水线记录拿到部署侧 **eventId**，再分析：  
   - `fsd delivery records -i <applyProgramId> --pretty`（或 `status` / `record-detail`，以当前 CLI 与子命令为准）  
   - `fsd delivery record-detail -i <applyProgramId> -r <recordId> --pretty`  
   - 从明细里的 **`buildPiplineRecordDetailVos[].parentEventId`**（或 CLI 文档当前字段名）得到 **`eventId`**  
   - `fsd deploy analyze -i <eventId>`（与 [delivery.md · trigger 失败](delivery.md#trigger-失败时的自动摘要) 一致）

4. **用户已直接给出部署事件 `eventId`**  
   → `fsd deploy analyze -i <eventId>`（必要时先 `fsd deploy status -i <eventId>`）。

5. **仅一个数字 ID、说不清是测计划 / 交付 / 部署事件**  
   → **先问清**或让用户给 FSD 链接；**禁止**默认 `fsd delivery detail -i <数字>` 当万能入口。

## 测试计划 + 交付字段同时出现（如 Automan `context.json`）

- **测试计划优先**：即使 JSON 里有 `applyProgramId`、`deliveryId`、`relatedApplyProgramIds`，只要存在 **`testPlan.id`**（或等价），**部署失败定因仍走第 1 条**，不得用交付 ID 替代 `test jobs` 取 eventId。
- **泳道不一致 = 立即停止交付定因**：若已误查 `delivery detail/status -i <applyProgramId>`，且返回的 **stackUuid / 泳道名** 与 **`fsd test jobs` / `fsd test detail` 所反映的当前测计划绑定环境** **不一致**，说明该交付**不是**当前测计划部署失败的主数据源——**禁止**用 `context.json` 里的 `testPlan.stackUuid` / 泳道名代替平台数据做对比；**禁止**继续用该交付 ID 或错误地把 **stackUuid** 传给 `fsd deploy status -i`（`-i` **仅**为数字 **eventId**）。**立即**改跑第 1 条：`fsd test jobs --id <testPlan.id> --pretty`。完整示例见下文 **Automan 节**。
- **禁止臆造 flag**：**不存在** `fsd delivery status --delivery-id`、`fsd deploy status --plan-id` / **`--plan <测计划ID>`**（勿写 `fsd deploy status --plan 62141`）；**也不要**写 `fsd delivery status --plan <测计划ID>`。交付侧只用 **`fsd delivery … -i <applyProgramId>`**（且定因场景下不能替代 `test jobs`）。**不要用** `fsd testPlan --help` 等顶栏试探代替 **`fsd test jobs`**。误跑 help 或上述错参后仍须回到 **`test jobs`**。

<a id="sec-automan-context-trap"></a>

## Automan 与 `context.json`（常见误路由复盘）

当 Automan 在系统提示中注入 **`…/plan_<数字>/…`** 与 **`[业务上下文]` JSON** 时，模型常误把 JSON 里的 **`applyProgramId`** 当成「查部署失败」的主入口。下面用**虚构但结构真实**的示例说明：**为何错、第一步该跑什么**。

### 模拟上下文（与常见误路由场景同构）

下列 JSON **仅作教学**：字段名对齐真实工作区形态；数值为示例。

**系统提示中还会出现**（Automan 插件固定格式）：

```text
[工作目录]
当前测试计划工作目录（绝对路径）: /Users/song/automan-test-plans/plan_62141/...
...
[业务上下文] （来自 .biz/context.json，无需再次读取该文件）
```

紧随其后的 JSON 块示例：

```json
{
  "testPlan": {
    "id": 62141,
    "name": "某联调计划",
    "env": "test",
    "swimlane": "selftest-260327-120526-649",
    "stackUuid": "7896b98a-e194-4b25-4bdd-1a47f95a7ec4"
  },
  "applyProgramId": 258966,
  "relatedApplyProgramIds": [258966, 300001]
}
```

| 字段 | 含义 |
|------|------|
| `testPlan.id` | **FSD 测试计划主键**；用户说「当前测试计划」时**以它为准**。 |
| `testPlan.swimlane` / `stackUuid` | JSON 里可能出现的泳道展示信息（**可能与平台滞后或不完整**）。**是否当前测计划环境以 `fsd test jobs` / `test detail` 为准**；**不要**据此字段决定 deploy 子命令或 `swimlane -u`。 |
| `applyProgramId` | 某条**交付计划**的 `applyProgramId`，常与需求/历史提测**关联**，**不一定**与「当前这次测计划里 job 的失败记录」同一条数据链。 |

### 常见错误命令链

用户问：**「在当前测试计划下，某几个应用部署失败，分析原因」**。

错误路径往往类似：

1. 看到 JSON 里的 `applyProgramId: 258966` → 执行 `fsd delivery status -i 258966` 或 **臆造** `fsd delivery status --delivery-id 258966`（**CLI 不存在 `--delivery-id`**，合法的是 **`-i <applyProgramId>`**）。
2. 发现交付详情里泳道是 **`selftest-260327-135446-968`**，与 `testPlan` 里的 **`7896b98a-…` / `selftest-260327-120526-649`** **不一致** → 说明该交付**不是**当前测计划部署定因的主数据源，但模型仍继续用交付/泳道兜圈。
3. 执行 **`fsd deploy status --plan-id 62141`** 或 **`fsd deploy status --plan 62141`**（**均非**合法用法；`status` **仅** `-i <eventId>`）→ 失败后查 `deploy --help`，再 **`fsd delivery status --plan 62141`**、**`fsd testPlan --help`** 等连环试探 —— **错误**：测计划内失败信息**只**从 **`fsd test jobs --id 62141 --pretty`** 来；`-i` 只能是**部署事件 `eventId`（数字）**，不是泳道 UUID、**不是**测计划 ID。

**结论**：上述命令组合在「测计划内应用部署失败」场景下**一律视为兜圈**；即使某步碰巧返回了 JSON，也**不能**替代 `test jobs` 给出的各 job **`eventId`**。

### 正确第一步

只要用户锚定的是**该测试计划内的应用部署失败**，且上下文已有 **`testPlan.id`（或 `plan_62141` 路径）**：

```bash
fsd test jobs --id 62141 --pretty
```

从输出（或 JSON 模式）中按 **`jobName`** 找到失败应用，取出各自的 **`eventId`**，再 `fsd deploy analyze -i <eventId>`。**不要**在跑完 `test jobs` 之前用 `context.json` 的 `applyProgramId` 去 `delivery status/detail` 找「失败原因」。

### 何时才允许用交付链上的 `applyProgramId`？

仅当上文 **第 3 条**成立：**没有**需要优先的测试计划 ID，且用户**明确**在查某条交付流水线记录。测计划 + 交付字段同时出现时，**永远先第 1 条**。

### 泳道不一致时的判据

若已经误跑了 `delivery detail -i <applyProgramId>`，且所见 **stackUuid / swimlane 名称** 与 `testPlan` 中 **stackUuid / swimlane** **不一致**：**停止**用该 `applyProgramId` 继续「对齐」部署失败；**回到** `fsd test jobs --id <testPlan.id>` → `deploy analyze -i <eventId>`。这是**选对查询入口**，不是让用户改平台数据。

## 「两种都能解决吗？」

- **可以**，但是**入口不同**：  
  - **测试计划内失败**：eventId **来自** `fsd test jobs`。  
  - **交付流水线上部署节点失败**：eventId **来自** `record-detail`（等）里的 **`parentEventId`**，再同样用 **`fsd deploy analyze`**。  
- **Maven 缺包、日志解读等**后续步骤：两条路径汇合后都按 [troubleshooting.md](troubleshooting.md)、[deploy.md · Maven](deploy.md) 处理。

---

<a id="sec-trigger-deploy-routing"></a>

## 非「部署失败定因」时的简判（触发/查状态）

| 意图 | 入口（详见 SKILL / 各 reference） |
|------|-------------------------------------|
| 在**已锁定测试计划**（`testPlan.id` / `plan_<数字>` / Automan 工作区）下**触发、重试、补部署**到**该计划环境** | **`fsd test deploy --id <testPlan.id> --job-name <jobName> --pretty`**（每应用一条；或省略 `--job-name` 全量经用户确认）。**`testPlan.id` 可从 `context.json`/消息读取**；**job 是否在计划内用 `fsd test jobs --id … --pretty` 核对**，勿信 `targetRepositories` 等本地列表。**严禁** `fsd deploy test -a <jobName>`、**`fsd deploy swimlane -a … -u <从 JSON 抄的 UUID>`**、**`fsd deploy swimlane-info` 接 `swimlane`**、**先 `fsd delivery show` / `delivery list` / `delivery detail` 对齐交付再部署**——均为**绕开测计划入口**；即使用户话里带「泳道」、JSON 里被动带有 **`stackUuid` / `applyProgramId`**，也**仍走 `test deploy`**（平台会把 job 挂到当前测计划环境）。 |
| 在**已锁定测试计划**下问**分支合并风险 / 冲突可能性**（可列举多个 jobName） | **`fsd test branch-risk --id <testPlan.id> --pretty`**（见 [SKILL.md · 分支合并风险专节](../SKILL.md)、[test-plan.md · branch-risk](test-plan.md#sec-branch-risk)）。**严禁** `fsd delivery detail`、`fsd delivery --help`、臆造 **`--delivery-id`**——交付详情应用列表常与用户点的服务**不一致**。 |
| **无测试计划**、用户明确跑**交付流水线**（含仅部署节点） | `fsd delivery trigger -i <applyProgramId> …` → [deploy.md · 交付上下文优先路由](deploy.md#交付上下文优先路由) |
| **无测试计划**、独立骨干/泳道/备机部署 | [deploy.md · 场景路由](deploy.md#场景路由)（此时才用 `fsd deploy test` 等） |

**常见误触示例（与「有测计划上下文却走独立 deploy」同构）**：工作区已是 `…/plan_62141`，从 `context.json` **只应取 `testPlan.id=62141`**，却**先** `fsd deploy --help`「确认语法」，再 **`fsd deploy test -a waimai-qa-deploy-test-web`**、**`fsd deploy test -a waimai-qa-deploy-test-jar`**——这是**骨干独立部署**，**不会**挂到当前测试计划 job。**正确**：可选 **`fsd test jobs --id 62141 --pretty`** 核对平台侧 job 列表（**不要**用 `targetRepositories` 当依据）；再 **`fsd test deploy --id 62141 --job-name waimai-qa-deploy-test-web --pretty`** 与 **`fsd test deploy --id 62141 --job-name waimai-qa-deploy-test-jar --pretty`**（`working_directory` 指到 `plan_62141`，**禁止** `cd`）。**禁止**以「JSON 里没有这两个仓库名」为由改用 **`fsd deploy test -a`**。另：先 `fsd deploy status`（无 `-i`）、再 `fsd delivery status --id 258966`（易把 **`deliveryId`** 当交付主键）、最后 `fsd deploy test -a …` 同属错误链。测计划内**触发部署**只认 **`test deploy`**。

**测计划语境下误用独立泳道部署**：已能解析 **`testPlan.id`**，却从 **`context.json` 抄 `stackUuid`** 去跑 **`fsd deploy swimlane-info` → `fsd deploy swimlane -u …`**，会把操作变成**测计划外的独立泳道部署**。**正确**：**不要**用文件里的 UUID 驱动 `swimlane`；直接 **`fsd test deploy --id <testPlan.id> --job-name <jobName> --pretty`**（每个应用各一条）。`swimlane-info` / `deploy swimlane` 仅在**无**测计划语境、按 [deploy.md](deploy.md) 场景路由使用时采用。

**分支风险类误触**：在 `plan_62141` 下用户问「检查 A、B、C 的合并风险」，却跑 **`fsd delivery detail --delivery-id 258966`**（**CLI 无 `--delivery-id`**）→ 交付里应用与 A/B/C 对不上。**正确**：**`fsd test branch-risk --id 62141 --pretty`**，在输出中对照各 jobName。
