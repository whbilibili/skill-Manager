# 自动化测试（fsd autotest）参考手册

> 所有操作遵循 SKILL.md 核心规则。

## 目录
- [fsd autotest execute](#fsd-autotest-execute)
- [fsd autotest execute-appkey](#fsd-autotest-execute-appkey)
- [fsd autotest execute-case-set](#fsd-autotest-execute-case-set)
- [fsd autotest find-cases](#fsd-autotest-find-cases)
- [fsd autotest status](#fsd-autotest-status)
- [fsd autotest coverage](#fsd-autotest-coverage)
- [fsd autotest execution-case-list](#fsd-autotest-execution-case-list)
- [fsd autotest case-log](#fsd-autotest-case-log)
- [分析失败用例完整流程](#分析失败用例完整流程)
- [执行状态字段](#执行状态字段)
- [覆盖率结果字段](#覆盖率结果字段)
- [用例执行结果字段](#用例执行结果字段)

---

## fsd autotest execute

按 plan-id 执行 FST 自动化测试计划。

| 参数 | 类型 | 必填 | 说明         |
|------|------|------|------------|
| `--plan-id` | number | 是 | FST 计划 ID  |
| `--swimlane` | string | 否 | 泳道名称（在指定泳道执行） |
| `--test-apply-id` | number | 否 | 交付 ID      |

---

## fsd autotest execute-appkey

按 appkey 自动查找并执行对应场景的测试计划。未指定 appkey 时自动从 `META-INF/app.properties` 的 `app.name` 读取。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--appkey` | string | 否 | 应用 appkey（未提供时自动查找） |
| `--scene-type` | string/number | 否 | 场景类型（见 SKILL.md 场景类型映射）；缺失时列出所有计划等用户选择 |
| `--deploy-env` | string | 否 | 部署环境，`staging` 时自动选预发回归类计划 |

### 返回字段说明（list 状态 / success 状态）

| 字段 | 说明                                                                                                                                       |
|------|------------------------------------------------------------------------------------------------------------------------------------------|
| `cleanName` | **计划可读名称**，已去掉开头重复的 appkey 前缀，直接展示给用户即可                                                                                                  |
| `sceneType` | **FSD 流水线绑定类型**。`0`=未绑定，`1`=FSD交付-QA参与类，`2`=FSD测试计划，`3`=FSD上线计划，`4`=FSD交付-RD自测类                                                          |
| `pipelineUsed` | **是否已经被 FSD 交付流水线绑定了**。由 `sceneType` 决定：`sceneType !== 0` 时为 `true`（已绑定，流水线中自动触发），`sceneType === 0` 时为 `false`（未绑定，需手动执行）。⚠️ 展示给用户时需着重说明 |
| `executeEnv` | **计划的运行环境**。`test`=骨干测试环境，`stage`=预发/备机环境，`prod`=线上环境；有泳道时值为泳道名称。⚠️ 展示给用户时需着重说明                                                          |

### AI 场景计划推荐规则（核心）

#### 快捷路径（直接执行，无需确认）

满足以下**全部条件**时，直接执行研发自测类计划，不推荐、不询问：

1. 上下文**没有**交付、提测、测试计划、上线、备机、预发等关键词
2. 用户意图是"帮我运行/跑自动化"等泛化触发（未指定具体场景）
3. 能找到 appkey（手动提供或自动查找）

执行逻辑：按推荐规则选出研发自测类计划后直接执行，并帮用户监控执行进度至终态。

---

> ⚠️ **其他情况的强制约束（违反即为错误行为）**：
> 1. 每次只能推荐 **一个** 计划，禁止同时推荐或执行多个
> 2. 返回结果存在多个计划且不满足快捷路径时，**推荐后必须停下来等用户明确回复确认，严禁自动执行**
> 3. 用户回复"是"、"确认"、"执行"、"ok"等明确同意词后，才能执行 `fsd autotest execute --plan-id`
> 4. **例外**：用户在请求中已明确指定了计划名称或 plan-id，则直接执行，无需再次确认

---

#### 第一步：判断推荐路径

检查返回的 `plans` 列表中是否存在 `pipelineUsed=true`（`sceneType !== 0`）的计划：

- **全部 `pipelineUsed=false`（sceneType 全为 0）** → 走「路径一：按名称语义推荐」
- **存在 `pipelineUsed=true`（有 sceneType ≠ 0 的计划）** → 走「路径二：按 sceneType 枚举推荐」

> ⚠️ **注意**：`sceneType` 是用户手动关联的，不能单纯用 sceneType 值来判断计划语义。只有 `sceneType !== 0` 时才代表该计划明确绑定了某个流水线节点，此时 sceneType 枚举有意义；`sceneType = 0` 时需要降级到 `cleanName` 语义判断。

---

#### 路径一：sceneType 全为 0（按 cleanName 名称语义推荐）

该项目未绑定 FSD 交付流水线，sceneType 无参考价值，改用 `cleanName` 的关键词语义推荐。

**结合上下文关键词，按以下优先级从 cleanName 中匹配：**

| 上下文关键词 | cleanName 匹配关键词（优先级从高到低） |
|------------|--------------------------------------|
| RD自测 / 研发自测 / 无QA介入 / 自己测 / 无特殊关键词 | `研发自测` > `无QA介入` > `集成` > `预发` > `全量` |
| 交付 / 提测 / QA介入 / 集成 | `集成` > `研发自测` > `预发` > `全量` |
| 备机 / 预发 / staging | `预发` > `集成` > `全量` |
| 上线 / 发布 | `预发` > `全量` > `集成` |
| 全量 / 全量回归 | `全量` > `集成` > `预发` |

匹配方式：`cleanName` 中包含对应关键词即命中，取当前上下文优先级最高的一个。

---

#### 路径二：存在 sceneType ≠ 0 的计划（按 sceneType 枚举结合上下文推荐）

根据**对话上下文关键词**决定目标 sceneType，优先在该类型中挑选，找不到再按备选：

| 上下文关键词 | 优先 sceneType | 备选 sceneType |
|------------|--------------|--------------|
| 无特殊关键词（日常开发、跑测试、提交代码） | `4`（FSD交付-RD自测类） | `1`（FSD交付-QA参与类） |
| RD自测 / 研发自测 / 无QA介入 / 自己测 | `4` | `1` |
| 交付 / 提测 / QA介入 / 集成测试 | `1` | `4` |
| 备机 / 预发 / staging | `1`（优先 `executeEnv=stage`） | - |
| 上线 / 发布 / 上线计划 | `3` | `1` |
| 全量 / 全量回归 / 全量测试 | `0`（降级到路径一按 cleanName 匹配） | - |

> ⚠️ **找不到目标 sceneType 时**：按备选 sceneType 继续找；备选也没有时，降级到路径一按 cleanName 匹配。

**同一 sceneType 下有多个计划时**，选取规则：
1. `executeEnv` 优先匹配当前上下文（备机/预发优先 `stage`，否则优先 `test`）
2. `caseNum` 较多的（用例更全面）

---

#### 情况三：备机/预发部署上下文（staging）

- **必须**传 `--deploy-env staging`
- **禁止**使用 `--scene-type "研发自测"` 或 `"研发自测（无QA介入）"`（会选中错误计划）
- 推荐优先选 `sceneType=1` 且 `executeEnv=stage` 的计划；无则选 `sceneType=1` 中任意一个

---

### AI 执行流程

> ⛔ **禁止输出中间思考过程**：执行 execute-appkey 流程时，不得输出"正在读取技能说明"、"正在检查 fsd 是否可用"、"将按优先级 X 执行"、"根据推荐规则分析如下"等内部决策语句。直接执行命令，按下方格式输出结果，不要向用户解释执行步骤。

1. 执行 `fsd autotest execute-appkey --appkey xxx` 获取计划列表（JSON，不加 `--pretty`）
   - ⚠️ 上下文没有明确提到"备机"/"预发"/"staging"时，**不要传 `--deploy-env staging`**，用默认即可
   - ⚠️ **禁止询问用户"你要在什么环境跑"**，直接按推荐规则选，环境信息从 `executeEnv` 字段读取

2. 读取返回的 `plans` 列表，结合当前对话上下文，按上述推荐规则挑选 **一个** 最合适的计划：
   - 有 `pipelineUsed=true` 的计划 → 按 sceneType 枚举 + 上下文关键词匹配
   - 全是 `pipelineUsed=false` → 按 cleanName 名称语义匹配
   - **选定后立即进入第 3 步，不要罗列条件让用户自己选**

3. 给用户简洁推荐，回复格式严格遵守：

   **只输出以下三项，不得多也不得少：**
   - 推荐计划名 + 一句话说明（直接说推荐这个，不需要分析过程）
   - 确认后将执行的命令
   - 请用户确认

   ✅ **正确示范**：
   > 「推荐执行「研发自测场景」，712 个用例，骨干测试环境。确认后帮你执行，是否确认？」

   ❌ **错误示范1**："已绑定流水线的有三条，executeEnv=prod 的要谨慎...如果你说下打算在什么环境跑，我可以帮你收窄..."

   ❌ **错误示范2**："同应用下还有：研发自测（无QA介入）（17641）、预发回归场景（9026）...请勿混用。回复确认/执行17639/执行17641 三选一..."

   ❌ **错误示范3（暴露参数名）**："确认后将执行：`fsd autotest execute --plan-id 17639 --pretty`" → 不要在回复用户时输出参数名

4. **⛔ 必须在此停止等待用户回复，不得继续执行任何命令**。收到用户明确确认（"是"/"确认"/"执行"/"ok" 等）后，才执行：
   ```bash
   fsd autotest execute --plan-id <fstPlanId>
   ```

5. 找不到 appkey → 提示用户手动提供

---

## fsd autotest execute-case-set

按指定用例 ID 列表执行 FST 临时计划（接口：`/api/FST/fst/fstPlan/executeTempFstPlan`）。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--appkey` | string | 是 | 目标应用 appkey (默认: -) |
| `--case-ids` | string | 是 | 用例 ID 列表（逗号分隔） (默认: -) |
| `--execute-env` | string | 否 | 执行环境（`test`/`staging`） (默认: `test`) |
| `--execute-swimlane` | string | 否 | 泳道 ID (默认: 空字符串) |
| `--stack-uuid` | string | 否 | 泳道 UUID (默认: 空字符串) |
| `--stack-name` | string | 否 | 泳道名称 (默认: 空字符串) |
| `--pretty` | boolean | 否 | 人类可读输出 (默认: `false`) |

### 固定请求字段（内部写死，不对用户暴露）

- `planOrigin = 10`
- `editHolmesPlanParams.isOPen = true`（字段名大小写必须原样）
- `editFlowPlanParams = {}`
- `editUnitPlanParams = {}`

### 字段映射

- `--case-ids` -> `editHolmesPlanParams.editPlanParams[0].conditions.casesSelect`
- `--execute-env` -> `executeEnv` + `editHolmesPlanParams.editPlanParams[0].runEnvs`
- `--execute-swimlane` -> `executeSwimlane`
- `--stack-uuid` -> `stackUUid`
- `--stack-name` -> `stackName`
- `--appkey` -> `appkey`

---

## fsd autotest find-cases

根据接口名称查询能覆盖该接口的自动化用例集合（接口：`GET /api/FST/service/caseList`）。

返回的 `case_ids` 数组可直接传给 `fsd autotest execute-case-set --case-ids`。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--appkey` | string | 是 | 目标应用 appkey (默认: -) |
| `--interface-name` | string | 是 | 接口名称（如 `DbController.branch`） (默认: -) |
| `--env` | string | 否 | 环境 (默认: `offline`) |
| `--case-type` | number | 否 | 用例类型 (默认: `1`) |
| `--page-num` | number | 否 | 页码 (默认: `1`) |
| `--page-size` | number | 否 | 每页数量 (默认: `50`) |
| `--title` | string | 否 | 用例标题筛选（模糊匹配） (默认: -) |
| `--class-or-method-name` | string | 否 | 类名或方法名筛选 (默认: -) |
| `--authors` | string | 否 | 作者筛选 (默认: -) |
| `--pretty` | boolean | 否 | 人类可读输出 (默认: `false`) |

---

## fsd autotest status

查询自动化测试执行状态，支持单次查询、后台监控、实时观察三种模式。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--execute-id` | number | 是 | 执行 ID（由 execute / execute-appkey / execute-case-set 返回） |
| `--plan-id` | number | 是 | 计划 ID |
| `--pretty` | boolean | 否 | 人类可读格式（仅给用户展示时使用） |
| `--monitor` | string | 否 | 启动后台监控，值为查询间隔（如 `10s`, `1m`），返回日志文件路径 |
| `--observe` | string | 否 | 实时观察指定日志文件，文件路径由 `--monitor` 返回，自动检测监控完成并退出 |

### AI 自动查找 appkey 逻辑

当用户未提供 `--appkey` 时，AI 自动查找项目 appkey：

```bash
# 1. 查找并读取 META-INF/app.properties 中的 app.name
find . -name "app.properties" -path "*/META-INF/*" -type f | head -1 | xargs grep "app.name" | cut -d'=' -f2 | tr -d ' '

# 2. 备选：查找 application.yml 中的 spring.application.name
grep "spring.application.name" application.yml | cut -d':' -f2 | tr -d ' '
```

找到 appkey → 执行 `fst executeAppkeyPlan --appkey xxx`；找不到 → 提示用户手动提供。

### 使用模式

#### 模式1：单次查询（默认）
```bash
fsd autotest status --execute-id 2663373 --plan-id 63950
```
仅查询一次当前状态，返回 JSON 格式结果。

#### 模式2：后台监控（--monitor）
```bash
fsd autotest status --execute-id 2663373 --plan-id 63950 --monitor 10s
```
- 启动后台守护进程，每 10 秒查询一次状态并写入日志文件
- 返回日志文件路径（如 `~/.fsd_monitor_logs/fst_monitor_plan63950_exec2663373_20260319_145630.log`）
- 守护进程在测试完成或 35 分钟后自动停止
- ⚠️ **必须配合 `--observe` 使用**，不能只执行 monitor 就停止

#### 模式3：实时观察（--observe）
```bash
fsd autotest status --execute-id 2663373 --plan-id 63950 --observe <日志文件路径>
```
- 实时输出日志文件内容（已有内容 + 新增内容）
- 自动检测监控完成标志（`停止监控` 或 `监控超时停止`）并退出
- ❌ **禁止使用 `tail` 命令**替代（tail 不知道何时退出）

### 监控完整流程（monitor + observe 两步连接）

**适用命令**：`fsd autotest execute`、`execute-appkey`、`execute-case-set` 成功后均可接监控。

**ALWAYS**：测试计划执行成功后自动帮用户监控进度（无需询问）。用户明确「异步监控 / 后台监控 / 不用等 / 让它自己跑」→ 异步；否则默认同步等待完成。

**ALWAYS**：用户说「实时查看执行状态 / 实时监控」→ 若历史中有 monitor 返回的日志路径则直接 observe；否则先启动后台监控再实时观察。

**硬性约束**：monitor 与 observe 必须连贯执行；勿用 `sleep` 等待（daemon 会写首行，可立即 observe）；异步时 observe 用 Bash `run_in_background` 在本地终端跑。

**同步监控（默认）**：
```bash
fsd autotest status --execute-id 2663373 --plan-id 63950 --monitor 10s
fsd autotest status --execute-id 2663373 --plan-id 63950 --observe ~/.fsd_monitor_logs/fst_monitor_plan63950_exec2663373_20260319_145630.log
```

**异步监控（用户明确要求）**：同上两条命令；第二条由工具 `run_in_background=true` 执行，AI 不阻塞、可不向对话流式输出监控日志。

### 监控模式对比

| 维度 | 同步监控（默认） | 异步监控（用户明确要求） |
|------|-----------------|------------------------|
| **执行步骤** | ✅ monitor → observe（两步必须执行） | ✅ monitor → observe（两步必须执行） |
| **AI 是否阻塞** | ✅ 阻塞等待，执行完成才返回 | ❌ 立即返回，不等待 |
| **AI 是否输出监控日志** | ✅ 实时输出监控日志 | ❌ 不输出，只提示已启动 |
| **识别关键词** | 无特殊关键词（默认） | "异步监控" / "后台监控" / "不用等" / "让它自己跑" |

### 轮询策略（不使用监控时）

AI 内部查询不加 `--pretty`（JSON 易于解析）；轮询直到 status 到达终态（成功/失败/部分成功）。

---

## fsd autotest coverage

查询基于自动化执行记录的覆盖率报告。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--plan-id` | number | 是 | 计划 ID |
| `--execute-id` | number | 是 | 执行 ID |
| `--env` | string | 否 | 环境，备机场景传 `staging` |

---

## fsd autotest execution-case-list

查询 FST 执行记录的执行的工程用例执行列表（支持筛选和分页）。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--execute-id` | number | 是 | FST 执行记录 ID (默认: -) |
| `--status` | string | 否 | 用例状态筛选（逗号分割，支持中英文）<br>- 中文：`未运行`, `成功`, `失败`, `跳过`<br>- 英文：`not_run`, `success/pass`, `fail/failed`, `skip/skipped` (默认: `失败,跳过,未运行`) |
| `--case-name` | string | 否 | 用例名称筛选（模糊匹配） (默认: -) |
| `--case-author` | string | 否 | 用例作者筛选（模糊匹配） (默认: -) |
| `--current-page` | number | 否 | 当前页码 (默认: 1) |
| `--page-size` | number | 否 | 每页数量 (默认: 10) |
| `--fst-api-url` | string | 否 | FST API 地址 (默认: https://fstapi.sankuai.com) |
| `--fst-web-url` | string | 否 | FST Web 地址 (默认: https://fst.sankuai.com) |
| `--pretty` | boolean | 否 | 美化输出格式（人类可读） (默认: false) |

### 使用说明

1. **默认筛选**：默认筛选失败、跳过、未运行的用例（不包括成功）
2. **筛选所有**：如需查询所有用例，使用 `--status "未运行,成功,失败,跳过"` 或 `--status "not_run,success,fail,skip"`
3. **筛选成功**：如需仅查询成功用例，使用 `--status "成功"` 或 `--status "success"`
4. **中英文支持**：状态值支持中英文混合，大小写不敏感（如 `--status "失败,success,SKIP"`）
5. **状态映射**：用户友好的状态名会自动转换为底层 API 枚举值（未运行=-1, 成功=1, 失败=2, 跳过=3）

下文 `case-log`、`status` 等含 `--pretty` 的命令：**认证与输出规则同上**（AI 解析用 JSON，仅展示给用户时加 `--pretty`）。

### 常用筛选速查

```bash
# 默认筛选（失败、跳过、未运行）
fsd autotest execution-case-list --execute-id 2655809

# 仅失败用例
fsd autotest execution-case-list --execute-id 2655809 --status "失败"

# 所有用例（含成功）
fsd autotest execution-case-list --execute-id 2655809 --status "未运行,成功,失败,跳过"

# 组合筛选（状态+作者+名称）
fsd autotest execution-case-list --execute-id 2655809 --status "失败" --case-author "zhangsan" --case-name "login"
```

### 状态值参考

| 中文 | 英文别名 | 枚举值 |
|------|---------|--------|
| 未运行 | not_run / notrun | -1 |
| 成功 | success / pass / passed | 1 |
| 失败 | fail / failed / failure | 2 |
| 跳过 | skip / skipped | 3 |

---

## fsd autotest case-log

查询自动化测试计划执行记录的用例执行日志信息（用于失败用例分析）。

**前置条件**：必须先调用 `fsd autotest execution-case-list` 获取用例执行列表，从列表中获取以下参数值。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `--result-id` | number | 是 | 用例执行记录 ID（来自 execution-case-list 的 `id`） (默认: -) |
| `--case-id` | number | 是 | 用例 ID（来自 execution-case-list 的 `case_id`） (默认: -) |
| `--task-id` | number | 是 | 任务 ID（来自 execution-case-list 的 `task_id`） (默认: -) |
| `--plan-id` | number | 是 | 计划 ID（来自 execution-case-list 的 `plan_id`） (默认: -) |
| `--trace-id` | string | 是 | TraceId（来自 execution-case-list 的 `trace_id`） (默认: -) |
| `--fst-web-api-url` | string | 否 | FST Web API 地址 (默认: https://fst.sankuai.com) |
| `--pretty` | boolean | 否 | 美化输出 (默认: false) |

### 使用场景

1. **查看失败用例的详细执行日志**：包括请求体、响应、异常堆栈等
2. **分析用例失败原因**：查看每个请求的详细信息和异常信息
3. **排查环境问题**：查看用例执行时的环境、泳道、应用信息

---

## 分析失败用例完整流程

当自动化测试计划执行完成后，如果存在失败、跳过或未执行的用例，需要分析失败原因。完整流程分为两步：

### 步骤 1：查询失败用例列表

使用 `fsd autotest execution-case-list` 命令查询执行记录中的失败用例。

```bash
fsd autotest execution-case-list --execute-id 2663581 --status "fail"
```

**关键字段说明**：
- `result_id`：用例执行记录 ID（步骤 2 必需）
- `case_id`：用例 ID（步骤 2 必需）
- `task_id`：任务 ID（步骤 2 必需）
- `holmes_plan_id`：Holmes 计划 ID（步骤 2 必需）
- `trace_id`：TraceId（步骤 2 必需，可能为 null）
- `error_message`：错误消息（快速判断失败原因）

### 步骤 2：查询失败用例的详细日志

使用 `fsd autotest case-log` 命令查询失败用例的详细执行日志（请求体、响应、异常堆栈等）。

```bash
fsd autotest case-log \
  --result-id 422236396 \
  --case-id 1645526 \
  --task-id 7968421 \
  --plan-id 63950 \
  --trace-id "-4854956453217552169"
```

**返回数据结构关键字段说明**：
- `execute_status`：执行状态（FAIL/PASS）
- `fail_reason`：失败原因（环境问题/断言失败/超时等）
- `execution_logs[]`：详细执行日志列表
  - `req_body`：请求体（查看请求参数）
  - `response`：响应内容（查看实际返回值）
  - `exception_state`：是否有异常（0=正常 1=异常）
  - `exception_info`：异常堆栈（用于定位代码问题）

### 完整示例（AI 执行流程）

用户请求："帮我分析计划 63950 执行 ID 2663581 的失败用例"

```bash
fsd autotest execution-case-list --execute-id 2663581 --status "fail"
fsd autotest case-log \
  --result-id 422236396 \
  --case-id 1645526 \
  --task-id 7968421 \
  --plan-id 63950 \
  --trace-id "-4854956453217552169"
```

### 注意事项

1. **trace_id 可能为 null**：
   - 如果 `execution-case-list` 返回的 `trace_id` 为 `null`，可能无法查询到详细日志
   - 此时可以尝试不传 `--trace-id` 参数或传空字符串

2. **分页处理**：
   - 如果失败用例较多（超过 10 条），需要使用 `--current-page` 和 `--page-size` 分页查询
   - 例如：`--current-page 2 --page-size 20`

3. **批量分析**：
   - 对于多个失败用例，AI 应逐个调用 `case-log` 命令
   - 避免一次性查询过多用例导致响应超时

4. **状态筛选**：
   - 默认筛选：失败、跳过、未运行（`--status "失败,跳过,未运行"`）
   - 仅失败：`--status "失败"`
   - 所有用例：`--status "未运行,成功,失败,跳过"`

### 错误处理

- **`case_count: 0` / 空 `cases`**：无符合 `--status` 的用例 → 核对筛选条件或放宽 status。
- **`error_code: NO_DATA_FOUND`**：`result_id` / `case_id` / `task_id` / `plan_id` / `trace_id` 与列表不一致 → 重新从 `execution-case-list` 取值。

---

## 执行状态字段

`fsd autotest status` 返回的关键字段：

| 字段 | 说明 |
|------|------|
| `status` | 执行中 / 成功 / 失败 / 部分成功 |
| `execute_id` | 执行 ID |
| `plan_id` | 计划 ID |
| `total` | 用例总数 |
| `passed` | 通过数 |
| `failed` | 失败数 |
| `skipped` | 跳过数 |

---

## 覆盖率结果字段

`fsd autotest coverage` 返回的关键字段：

| 字段 | 说明 |
|------|------|
| `lineCovered` / `lineTotal` | 行覆盖数 / 行总数 |
| `branchCovered` / `branchTotal` | 分支覆盖数 / 分支总数 |
| `methodCovered` / `methodTotal` | 方法覆盖数 / 方法总数 |
| `classCovered` / `classTotal` | 类覆盖数 / 类总数 |

---

## 用例执行结果字段

`fsd autotest execution-case-list` 返回的关键字段：

| 字段 | 说明 |
|------|------|
| `fst_execute_id` | FST 执行记录 ID |
| `task_ids` | 关联的任务 ID 列表 |
| `case_id` | 用例 ID |
| `case_name` | 用例名称 |
| `case_author` | 用例作者 |
| `case_result` | 用例结果枚举值（-1=未运行, 1=成功, 2=失败, 3=跳过） |
| `case_result_text` | 用例结果文本（未运行/成功/失败/跳过） |
| `task_id` | 所属任务 ID |
| `holmes_plan_id` | Holmes 计划 ID |
| `execution_time` | 执行耗时（毫秒） |
| `error_message` | 错误信息（仅失败用例有） |
| `report_url` | 用例报告链接 |
| `pagination.total_count` | 符合筛选条件的用例总数 |
| `pagination.total_pages` | 总页数 |

---

## 使用示例

> 说明：用户未必会说 "FST"。当用户表述为「自动化测试 / 运行自动化 / 执行自动化计划 / 跑测试用例」等，也应路由到本技能，并使用 `fsd autotest` 命令组执行。

### 示例1：按 plan-id 执行自动化测试
**用户**: "帮我执行下自动化测试计划 63950"

**执行**：`fsd autotest execute --plan-id 63950`

---

### 示例2：按 appkey + 场景执行自动化
**用户**: "帮我跑下 com.sankuai.xxx 的自动化用例，场景是 研发自测"

**执行**：`fsd autotest execute-appkey --appkey com.sankuai.xxx --scene-type "研发自测"`

---

### 示例3：备机部署后跑自动化（staging 场景）
**用户**: "备机部署完了，跑下自动化"（或上一轮部署结果 env=staging）

**执行**：`fsd autotest execute-appkey --deploy-env staging`（可加 `--appkey`）

**反例** — 备机后勿跑「研发自测(无QA介入)」：
- ❌ 错误：`fsd autotest execute-appkey --scene-type "研发自测（无QA介入）"` → 会选中错误计划
- ✅ 正确：`fsd autotest execute-appkey --deploy-env staging`，或 `--scene-type "预发回归"`

---

### 示例4：查接口关联用例并执行（闭环工作流）
**用户**: "帮我查下 DbController.branch 接口的关联用例，然后跑一下"

**执行流程**：
```bash
# 步骤1：查询关联用例
fsd autotest find-cases --appkey com.sankuai.ed.flow.http --interface-name DbController.branch
# 返回 case_ids: [411333, 411334]

# 步骤2：用查到的 case_ids 执行临时计划
fsd autotest execute-case-set --appkey com.sankuai.ed.flow.http --case-ids 411333,411334
```

---

### 示例5：查询自动化执行状态
**用户**: "查下自动化执行进度，planId 63950，executeId 2644336"

**执行**：`fsd autotest status --execute-id 2644336 --plan-id 63950`（AI 内部解析用，不加 --pretty）

**给用户展示详细结果时**：加 `--pretty` 美化后输出，向用户展示通过率、失败数等关键信息

---

### 示例6：同步监控（执行 + monitor + observe 完整流程）
**用户**: "执行自动化计划 63950 并监控进度"

`execute_id`、observe 中的日志路径用前两步实际返回值替换。

```bash
fsd autotest execute --plan-id 63950
fsd autotest status --execute-id 2663373 --plan-id 63950 --monitor 10s
fsd autotest status --execute-id 2663373 --plan-id 63950 --observe ~/.fsd_monitor_logs/fst_monitor_plan63950_exec2663373_20260319_145630.log
```

**异步变体**（用户说"不用等"/"后台跑"时）：步骤 1–2 相同；步骤 3 后台运行 observe，AI 立即返回并告知"已在后台帮你监控，执行完成后告知结果"。

---

### 示例7：查询覆盖率报告
**用户**: "查下自动化执行的覆盖率，planId 63950，executeId 2644336"

**执行**：`fsd autotest coverage --plan-id 63950 --execute-id 2644336`

---

### 示例8：查询用例列表（按状态筛选）
**用户**: "查下执行记录 2655809 的用例列表，看有哪些失败的"

**执行**：`fsd autotest execution-case-list --execute-id 2655809`（默认筛选失败、跳过、未运行）

---

### 示例9：查询用例执行日志（失败分析）
**用户**: "查下这个失败用例的详细执行日志"
**前提**: 用户已经通过 `execution-case-list` 获取到用例执行记录的各项参数

**执行**：
```bash
fsd autotest case-log \
  --result-id 422176759 \
  --case-id 1229090 \
  --task-id 7961151 \
  --plan-id 103798 \
  --trace-id "-4854956453217552169"
```

**返回关键字段**：`status`、`case_name`、`execute_status`、`fail_reason`、`execution_logs[]`（含 `req_type`、`req_interface`、`req_body`、`response`、`duration`、`exception_state`、`exception_info`）。

---

## 其他要求

1. 一般别用 --pretty，用 JSON 格式，只有任务完成后给用户看的操作才用 --pretty
2. **向用户输出时禁止暴露 CLI 参数名**：回复用户时，不得出现 `--pretty`、`--monitor`、`--observe`、`--deploy-env`、`--scene-type` 等参数名称。用自然语言表达，例如：
   - `--monitor` + `--observe` → "帮你监控执行进度"
   - `--pretty` → （AI 内部决定加不加，无需告知用户）
   - `--deploy-env staging` → "在预发/备机环境执行"
   - `--scene-type "研发自测"` → "选择研发自测场景"
   - `--execute-id` / `--plan-id` → "执行 ID xxx、计划 ID xxx"（数字直接说，不带参数名）
