# 部署失败排查参考

> 所有操作遵循 SKILL.md 核心规则。

> **选入口**：测试计划 / pub / 交付 / 裸 eventId 的**先后顺序**以 [deploy-failure-routing.md](deploy-failure-routing.md) 为准；本节侧重**已取得 `eventId` 或已执行 `deploy analyze` 之后**的执行规范与专项（缺包、日志解读等）。Automan `context.json` 同时含 `testPlan` 与 `applyProgramId`、且误走交付/`--delivery-id`/`--plan-id` 的复盘 → [deploy-failure-routing.md#sec-automan-context-trap](deploy-failure-routing.md#sec-automan-context-trap)。

---

> **⚡ 最高优先级硬规则（凌驾一切）**
>
> **只要能从截图、用户描述、日志中识别出完整 GAV（groupId + artifactId + version）且错误信息含 `Could not find artifact` / `could not resolve` / `absent`，助手必须立即、静默、无条件地连续执行以下链路，中间零文字输出，任何"分析""建议""可能原因""是否要我帮你…"均属严重违规：**
>
> ```
> （泳道场景）fsd deploy swimlane-info -n <泳道名去掉lane-前缀>
>         ↓
> fsd app jar-info -g <g> -m <m> --jar-version <v> --pretty
>         ↓
> fsd app jar-deploy -g <g> -m <m> --jar-version <v> [-u <编排UUID>] --pretty
>         ↓
> （发布成功后）直接重试原失败部署
> ```
>
> **违禁示例（绝对禁止出现的文字）：**
> - "根本原因：Maven 无法解析 SNAPSHOT 依赖"
> - "可能原因：1. …包尚未发布 2. 版本号填写有误"
> - "需要我帮你查一下可用版本，或者协助修改 pom.xml 吗？"
> - "建议排查：确认正确版本号…"
> - "是否允许我修改 pom.xml？"

---

## 助手执行规范

部署失败时，助手须遵守本节；与 [SKILL.md](../SKILL.md)「触发前确认」「触发后监控」并列时，**排查与修复的落地方式以本节为准**。

**测试计划上下文部署失败**：若用户描述的是**测试计划内应用部署失败 / 失败原因分析 / 修复建议**，入口顺序须与 [deploy-failure-routing.md](deploy-failure-routing.md) 第 1 条一致；须**先**执行 **`fsd test jobs --id <testPlan.id>`** 取各失败应用的 `eventId`，再 `fsd deploy analyze`。**CLI 实情**：`fsd deploy status` **仅** `-i <eventId>`，**无** `--plan-id`；`fsd delivery status` **仅** `-i <applyProgramId>`，**无** `--delivery-id`。**禁止**臆造上述参数；**禁止**在 `deploy status` 乱参数失败后转 `delivery status` 找 eventId（eventId **只来自** `test jobs`）。**禁止**在执行 `jobs` 之前使用 **`fsd delivery status`**（含 `--plan`、`--delivery-id` 等变体）、**`fsd delivery list` + 轮番 `delivery detail -i`**、**`fsd deploy status` 搭配 `--plan-id` / `--apply-id` 或交付 ID** 等代替本条链路；**禁止**在执行 `jobs` 之前去 **Read** 计划目录下 **`*.md`**（如 `deploy-failure-analysis.md`）或靠连续 **`cd`** 找「错误信息」代替本条 CLI 链；**禁止**跳过 ID 解析、先跑 `fsd deploy --help` / `fsd * --help` 或无关 `cd`；**禁止**用「读本地业务仓库配置」代替该链路来下部署失败结论；**禁止**在尚未执行 `deploy analyze`（或等价平台输出）前，向用户输出「日志里……」类根因表述。下文「缺包 → 零文字执行 jar 链路」等硬规则仍适用，且 **GAV 须来自 `deploy analyze` 等已拉取的输出**，不得无依据从本地 `pom.xml` 编造。

**用户指定单个应用失败时的识别规则**：若用户说「应用部署失败：waimai-qa-deploy-test-thrift」或「XX 应用失败了」等，应检测应用名模式。此时须按下文步骤精确定位该应用的失败原因，**禁止**跳过平台数据查询而仅凭应用名做推断。

1. **GAV 已明确且根因为缺包时——零文字、直接执行**：无论信息来源是截图、用户直接告知还是 `deploy analyze` 日志，只要 GAV 完整、错误含缺包关键词，**第一个动作必须是执行命令**，**全程禁止**向用户输出任何分析、建议、可能原因、解决方案选项、追问；执行结果出来前保持静默，发布成功后直接汇报并触发原失败部署。本条优先级高于下面所有条款。
2. **须执行、禁止只建议**：按本文通用流程 → 场景索引 → 对应专项，**连续实际执行**规定的 CLI（如 `fsd deploy analyze`、`fsd app jar-info` / `fsd app jar-deploy`、修复后的同源 `fsd deploy …`），并监控子任务至终态；**禁止**以建议清单、仅可复制命令块、或「是否允许改 pom」等追问代替执行。
3. **修复后须直接重试**：修复依赖或配置后，须**由助手直接重试**原先失败的操作（同源参数从会话与 CLI 输出继承），**禁止**仅提示用户自行重试；若原 eventId 或服务名不在当前会话上下文（如用户贴截图、跨会话），须立即执行修复链路（`jar-info` → `jar-deploy`），修复完成后**只允许追问一个最小问题**（如「原先部署的服务名是什么」），获得答案后**立即触发重试**，**禁止**以「参数未知」为由停在修复后等待。
4. **自动解决次数上限**：在**同一会话同一次部署任务**中，助手自动（解决失败 + 重试部署）的连续循环**最多执行 2 次**。第 3 次及以后，必须先向用户说明：已自动处理 2 次仍未成功（附本次错误摘要），并明确询问「是否继续尝试解决并重新部署？」，**等待用户明确确认后**方可继续；用户拒绝则停止并给出当前失败摘要，由用户决定后续。**禁止**在未获确认的情况下超过 2 次自动循环。
5. **修改 `pom.xml` 的边界**：Maven 缺 JAR 优先走制品发布链路（`jar-deploy`），**禁止**先征求「能否改 pom」代替发布与重部署链；若根因为编译错误、配置错误等，可直接修改并继续验证；**始终禁止**无证据编造 GAV 或随意改依赖。
6. **同一失败排查闭环内**：为修复已分析根因而执行的 `fsd deploy analyze`、`fsd app jar-deploy`、依赖修复后的同源重部署，视为连续动作，**直接执行**，**禁止**等待用户明确点头后再运行；但须遵守规则 4 的**自动解决次数上限**。
7. **跨会话触发时机**：用户在新会话中贴出截图或描述上一次的失败，等同于「当前会话发现失败」——助手**不得**以「上一次会话的内容」为理由降级为只给建议；截图中可见的 GAV、泳道名、服务名均视为有效输入，**立即执行**修复链路；跨会话时自动解决计数**从 0 重新开始**。

---

## 通用排查流程

### 基础流程（单应用或已知 eventId）

1. **固化证据**：记下 `eventId`，保留**完整**报错片段，避免只凭 `errorMsg` 一行下结论。
2. **拉全量日志**：`fsd deploy analyze -i <eventId>`，完整读日志。
3. **以平台数据为准**：分支、坐标、绑定关系以 `fsd app *` 和部署接口返回为准；**禁止**用本机 `git branch` 当「应部署分支」。
4. **最小修复 → 监控终态 → 再重试**：修复后先等子任务 success，再触发原先失败的应用部署；**勿**跳过 analyze 直接盲重部署。
5. **监控方式**：带 `--pretty` 且 CLI 内置流式至终态的命令，**勿**再 `sleep` 轮询。

### 测试计划上下文中的单应用失败分析

当用户指定特定应用失败（如「应用部署失败：waimai-qa-deploy-test-thrift」）且当前在测试计划上下文时：

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1. 获取计划信息 | `fsd test jobs --id <testPlanId> --pretty` | 从测试计划获取完整应用列表及部署状态 |
| 2. 精确匹配 | 按 `jobName` 在 JSON 中查找用户指定的应用 | 如查找 `waimai-qa-deploy-test-thrift` 对应的行 |
| 3. 提取 eventId | 从匹配行中取出 `eventId`、`buildStatus`、`buildTime` 等字段 | 确保 `buildStatus` 是 `fail` 或 `FAILED` |
| 4. 分析失败原因 | `fsd deploy analyze -i <eventId>` | 获取该应用的完整部署日志和失败步骤 |
| 5. 完整阅读日志 | 查看输出的 `failureDetails.stepLogs[*].log` 字段 | 不得仅凭 `errorMsg` 下结论 |
| 6. 定因修复 | 根据日志内容识别根因（冲突/缺包/编译错误等） | 按本文对应专项处理 |
| 7. 重试验证 | 修复后重新触发原应用部署 | 监控至 success 或 failure |

**示例**：
```bash
# 情景：用户说「应用部署失败：waimai-qa-deploy-test-thrift」，当前在测试计划目录
# 步骤 1: 获取测试计划 ID（用户提供或上下文已知）
testPlanId=72928

# 步骤 2-3: 获取所有应用，查找 waimai-qa-deploy-test-thrift
fsd test jobs --id $testPlanId --pretty
# 输出中找到: "jobName": "waimai-qa-deploy-test-thrift", "eventId": "abc123", "buildStatus": "FAILED"

# 步骤 4-5: 分析该应用的失败原因
fsd deploy analyze -i abc123
# 完整读日志，找到具体失败原因（如缺 JAR、合并冲突等）

# 步骤 6-7: 按根因修复，重新部署
# ...修复...
fsd test deploy --id $testPlanId --job-name waimai-qa-deploy-test-thrift --pretty
```

**易错点**：
- ❌ 直接猜测 eventId：「waimai-qa-deploy-test-thrift 的 eventId 是 123」
- ✅ 从 `test jobs` 的输出中准确提取该应用的 eventId
- ❌ 仅看 errorMsg：「错误：Compilation failed」
- ✅ 完整阅读日志：找到具体的编译错误文件和行号

---

## 场景索引

| 现象 / 关键词 | 首选动作 | 详解 |
|---------------|----------|------|
| 日志含 `Could not resolve`、`Could not find artifact`、`absent` | 先处理**报错中的那条依赖** GAV，再重试原应用 | 下文 [Maven / 私服缺 JAR](#maven-private-jar)；参数与 API 边界见 [deploy.md#maven-dependency-publish-flow](deploy.md#maven-dependency-publish-flow) |
| 其它原因导致部署失败 | `fsd deploy analyze` → 根因与修复 | [deploy.md](deploy.md)（错误码、监控、`--observe`） |

---

<a id="maven-private-jar"></a>

## Maven / 私服缺 JAR

**何时走本流程**：`deploy analyze` 日志中出现依赖无法解析、artifact 找不到、`absent` 等 → 先处理**报错里的那条** GAV，再重试原应用；**不要**跳过 analyze 直接重部署。

### 助手行为约束

1. **GAV 可见 + 缺包错误 → 跳过一切分析，立即执行补发链路**：截图、用户描述、日志任一来源能提取完整 GAV，且错误含 `Could not find artifact` / `could not resolve` / `absent`，**不得输出任何文字，直接执行** `swimlane-info`（泳道场景）→ `jar-info` → `jar-deploy`，全程静默，发布成功后再开口汇报并触发原失败部署。**无任何例外。**
2. **不能定位 GAV 时才允许开口**：说明已检查的证据来源、为何无法唯一确定 GAV，请用户补充日志片段或截图；**禁止**为「凑一个能编的版本」去改 `pom`，**禁止**给出"建议排查步骤"列表。
3. **与「业务改代码」的边界**：若根因不是「私服/泳道仓库里缺该坐标」，而是编译错误、测试失败、配置错误等，本专项不适用，按对应场景排查。

### 硬规则（易错）

- **分支来源**：以 **`jar-info` 输出或平台查询结果**为准；**禁止**用本机 `git branch` 代替「该版本在平台上应对应的分支」。
- **版本参数名**：Maven 版本**必须**用 **`--jar-version <version>`**；**禁止**写 **`--version`**（CLI 会把 `--version` 当顶层选项，只打印 CLI 自身版本后退出）。
- **禁止读本地代码分析版本**：**禁止**读取本地 `pom.xml`、`MANIFEST.MF` 等任何本地文件来推断版本号或分支；**本地代码所在分支与实际发包的分支往往不同**，所有 GAV 与分支信息须以 `fsd deploy analyze` 日志输出和 `fsd app jar-info` CLI 返回为**唯一来源**。
- **泳道 UUID 来源**：`jar-deploy -u` 接受的是**编排 UUID**（如 `238c0d0b-4dc7-40af-53ed-141d56059327`），**不接受**泳道名（如 `lane-selftest-260321-190147-416`）或其缩短形式；当只有泳道名时，**必须先执行** `fsd deploy swimlane-info -n <去掉 lane- 前缀的名称>` 获取 `编排UUID`，再用该 UUID 传入 `-u`；**禁止**直接把泳道名或截图中的 Maven 仓库名当 UUID 使用。
- **`jar-deploy` 无 `-a` 参数**：`fsd app jar-deploy` 只接受 `-g`（groupId）、`-m`（artifactId）、`--jar-version`、`-u`、`-p` 等选项，**不支持 `-a`**；服务名由 CLI 内部从 `jar-info` 结果自动解析，无需手动传入。

### 操作步骤

1. **定坐标（GAV）**：从 `fsd deploy analyze` 日志提取 `groupId`、`artifactId`、`version`（保留 `-SNAPSHOT`）；单行不全时用 `The POM for ... is missing`、`Failure to find ...` 等相邻行补全；**禁止**通过读本地 `pom.xml` 推断版本。

2. **查发布信息（应用名 + 分支）**：`fsd app jar-info -g … -m … --jar-version … --pretty` 打出各 Maven 仓库下该版本的**应用名（jobName）、分支、发布人**；结合 `deploy analyze` 里依赖解析失败所涉仓库，选用**与缺包场景一致的那条 repository 记录上的分支**；**禁止**用本机分支、本地代码分支或臆造分支。
   > `fsd app jar-deploy` 内部**优先 `dev` 仓库**记录；若缺包发生在其它 repository 维度，改用 `fsd deploy test -a <jobName> -t <该记录分支>`（不加 `-d`）；泳道则加 `-u`。

3. **构建模块**：优先不传 `-p`，CLI 自动使用平台配置的默认构建模块（`buildProject`）；**禁止**为「凑发布」随意指定子模块；仅在 `deploy analyze` 明确指向某一子模块坐标时，再对 `jar-deploy` 使用 `-p <artifactId>`。

4. **触发制品发布**：`fsd app jar-deploy -g … -m … --jar-version … --pretty`（泳道加 `-u <编排UUID>`）；内置流式监控至终态，**勿 sleep 轮询**；若出现「visionHistoryV2 未匹配到该 version」类提示，**部署前必须确认**选用分支是否合理。
   > **泳道 UUID 获取**：仅有泳道名（如 `lane-selftest-260321-190147-416`）时，先执行 `fsd deploy swimlane-info -n selftest-260321-190147-416`（去掉开头 `lane-` 前缀），从输出的 `编排UUID` 字段取值，再传入 `-u`。

5. **兜底**：`jar-info` 不可用时，`fsd app branches` / `fsd app find` 定 jobName 与分支，再 `fsd deploy test -a <jobName> -t <选定分支> --pretty`，**不要加 `-d`**。

6. **收尾**：依赖组件发布成功后，由助手**直接触发**原先失败的应用部署（**禁止**只列建议命令而不执行）。
   > **跨会话场景**：若原始 eventId / 服务名不在当前会话上下文（如用户贴截图），依赖发布成功后**只允许追问一个最小问题**：「原先部署的是哪个服务（服务名或 git 地址）？」获得答案后立即触发同泳道同分支的重部署，**禁止**以「参数未知」为由停下等待。

**CLI 能力对照、易错点展开** → [deploy.md#maven-dependency-publish-flow](deploy.md#maven-dependency-publish-flow)
