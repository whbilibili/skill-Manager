# FSD 部署参考手册

> 所有操作遵循 SKILL.md 核心规则。

## 目录

- [场景路由](#场景路由)
- [应用维度独立部署与部署模板](#sec-app-dimension-deploy-templates)
- [交付上下文优先路由](#交付上下文优先路由)
- [queryJobByGit 接口](#queryjobbygit-接口)
- [错误处理](#错误处理)
- [Maven 依赖缺失（组件 JAR 未进可解析仓库）](#maven-依赖缺失组件-jar-未进可解析仓库)
- [CLI 内部参数](#cli-内部参数)
- [MIS 配置](#mis-配置)
- [部署结果字段映射](#部署结果字段映射)
- [部署结果展示格式](#部署结果展示格式)
- [失败日志处理](#失败日志处理)
- [部署进度与部署机器 IP](#部署进度与部署机器-ip)
- [部署监控流程](#部署监控流程)
- [部署失败 AI 分析](#部署失败-ai-分析)
- [coverage status 输出规范](#coverage-status-输出规范)
- [使用示例](#使用示例)
- [部署场景决策示例](#部署场景决策示例)
- [应用负责人 job-owners](app-job-owners.md)（`fsd app job-owners`）

---

## 场景路由

根据用户描述的环境，自动选择对应的子命令：

| 用户表述 | 子命令 | 说明 |
|----------|--------|------|
| 主干 / 骨干 / test / qa | `fsd deploy test` | 默认场景 |
| 备机 / staging / 预发 | `fsd deploy staging` | `-I`（大写）可选，不填自动获取当前服务备机 IP；`-t` 部署分支默认 `staging` |
| 泳道 / cargo / selftest | `fsd deploy swimlane` | 新建用 `--create`，已有用 `-u <uuid>` |
| 未明确提及 | `fsd deploy test` | 兜底默认主干 |

### 测试计划上下文（覆盖上表「泳道」行）

当**已解析出测试计划 ID** 且用户要**部署测试计划内的应用**（含「部署到泳道 / 测试环境 / 两个应用一起部署」等）时：**不得**按上表选用 `fsd deploy swimlane` / `fsd deploy test`。**必须**使用 **`fsd test deploy --id <testPlan.id> --pretty`**；只部署部分应用时，**每个 `jobName` 各执行一次** `fsd test deploy --id <testPlan.id> --job-name <jobName> --pretty`（CLI 单次仅支持一个 `--job-name`）。完整参数与接口 → [test-plan.md · deploy](test-plan.md#sec-test-deploy-merge)。

**例外：明确指定交付参数**：当用户**明确指定交付相关参数**（如 `--online-program` 上线计划 ID、`--apply-id` 交付 ID）时，即使存在测试计划上下文，也允许使用 `fsd deploy` 走交付流程。这是因为用户明确表达了要操作交付而非测试计划的意图。

**部署失败 / 根因 / 修复**（同一上下文）：**禁止**先跑 `fsd delivery status` / `detail` / `records` / `show` / **`list`（含关键字筛选）** / **`info`** 或 `fsd deploy status`（在未从 `fsd test jobs` 取得 **`eventId`** 前）及任意 `fsd * --help` 兜圈；**`-i` 交付主键仅 `applyProgramId`**。**必须** `fsd test jobs --id <testPlan.id>` → 按 `jobName` 取 **`eventId`** → `fsd deploy analyze -i <eventId>`。完整排查规则见 [troubleshooting.md · 助手执行规范](troubleshooting.md#助手执行规范)。

### 上线计划备机部署

当用户在**上线计划上下文**中要求备机部署时，**必须使用 `--online-program`**：

```bash
fsd deploy staging --online-program <上线计划ID> [-a <appkey>] [-t <分支>] [--apply-id <交付ID>]
```

- `--online-program`：从上线计划的应用列表中取 jobName、betaBranch，自动获取备机 IP，部署记录关联到上线计划
- `-a`：可选，只部署上线计划中的指定应用；不传则部署上线计划中全部应用
- `--apply-id`：可选，只部署指定交付下的应用
- **禁止**在上线计划上下文中用独立的 `fsd deploy staging -a ... -t ...`，否则部署记录不会关联到上线计划

**liteSet**（与交付/测试计划策略一致，接口 `source=2`、`sourceId=上线计划ID`）：

```bash
fsd deploy staging --online-program <上线计划ID> --env liteSet [-a <jobName>] [--apply-id <交付ID>] [-t <分支>] [--test-branch <分支>] [--lite-set-template <name>] [--lite-set-name <name>]
```

部署分支须在 **`getBranchList`**（按 `jobName`）返回列表内。详见 [pub.md · 上线计划 liteSet 部署](pub.md#上线计划-liteset-部署)。

<a id="sec-app-dimension-deploy-templates"></a>

## 应用维度独立部署与部署模板

**范围**：`fsd deploy test`、`fsd deploy staging`（**无** `--online-program`）、`fsd deploy swimlane`。不含交付 `delivery trigger`、不含 `fsd test deploy`。与 skill-dev 中独立部署页调用的 `getTemplates` + 部署接口参数语义对齐（`POST /api/qa/v1/job/getTemplates?env=`，body 为 jobName 数组）。

### `getTemplates` 的 `env`

| `fsd deploy` 场景 | `getTemplates` 查询参数 `env` |
|-------------------|-------------------------------|
| `test` | `test` |
| `staging` | `staging` |
| `swimlane`（含别名 `cargo`） | `test`（与骨干相同；非交付 trigger 下按 `stackUuid`→`cargo` 的规则） |

### `--deploy-template`

- 可选。值为接口返回项的 **`name` 或 `id`**（trim 后全等即视为命中）。
- **未传**：取该 `jobName` + `env` 下返回列表的**首项**（`id` 优先，否则 `name`）。
- **传入且不命中**：拒绝触发，错误信息含 `FSD_JOB_DEPLOY_TEMPLATE_DOC_URL`（见仓库 `fsd/cli/scripts/shared/config.js`）。

### `fsd deploy templates`

在触发前列举当前解析到的 `jobName` 在给定场景下的可选模板：

```bash
fsd deploy templates <scene> [-a <应用或仓库 ssh>] [-t <部署分支>] [-v] [--pretty]
```

- `<scene>`：`test` | `staging` | `swimlane`。
- **jobName 解析**：与 `fsd deploy <scene>` 一致（依赖 `-a`、`-t` 或仓库内当前分支）。
- **默认输出**：JSON，字段含 `jobName`、`scene`、`templatesApiEnv`、`templates`（每项含 `name`、`id`、`url`、`releasePlatform` 等接口字段）。
- **`--pretty`**：表格化列出，便于人工选择后再执行 `fsd deploy <scene> … --deploy-template <name或id>`。

### 与交付侧差异

交付 `triggerPipeline` 多应用时，`--deploy-template` 为「并集命中后仅对含该模板的服务触发，无则跳过；全无则拒绝」（见 [delivery.md · --deploy-template](delivery.md#delivery-deploy-env-template)）；交付详情含 `stackUuid` 时 `getTemplates` 的 `env` 为 **`cargo`**。**应用维度独立部署**单次仅一个 `jobName`，无并集分支；泳道场景拉模板列表 **`env` 仍为 `test`**，与上表一致。

---

## 交付上下文优先路由

<!-- AI_INTERNAL:
当用户明确指定交付（直接提供交付 URL 或 applyProgramId，或明确说「通过交付部署」「触发交付流水线」等）时：部署通过 **`fsd delivery trigger`** 自测流水线完成（可使用 `-n` 指定节点如 `-n 构建部署` 或 `-n 部署环境`）。用户明确要跑**自测流水线**（整链或指定流水线内节点）时用 **`fsd delivery trigger`**。不满足交付路径时再退回独立 **`fsd deploy`**。
测试计划上下文不等于交付上下文。若用户提的是测试计划（ID、测试计划 URL，或 JSON 的 `testPlan.id`），即便关联了 applyProgramId，也不得自动切成交付路由；**部署须走 `fsd test deploy --id <testPlan.id> ...`**（见 SKILL 核心规则）。仅当**无**测试计划上下文、且无交付锚定时，才按「场景路由」使用 `fsd deploy test / staging / swimlane`。
-->

### 用户意图 → 命令映射

| 用户意图 | 命令 |
|----------|------|
| **部署服务 / 部署环境**（说「部署」「发到泳道/骨干/备机」「环境部署」） | **`fsd delivery trigger -i <applyProgramId> -n 构建部署 --pretty`** 或 **`fsd delivery trigger -i <applyProgramId> -n 部署环境 --pretty`**（通过自测流水线完成部署） |
| **跑完整自测流水线**（说「跑流水线」「自测流水线」「trigger」「全量」或同时含多类节点） | `fsd delivery trigger -i <applyProgramId> --pretty`（不传 `-n`） |
| **自测流水线内只跑指定节点**（如「流水线里只跑部署」「只跑 Sonar/自动化」） | `fsd delivery trigger -i <applyProgramId> -n <节点关键词> --pretty` |

节点关键词见 [delivery.md — delivery trigger 与指定节点（-n）](delivery.md#delivery-trigger-与指定节点-n)（`部署环境`、`构建部署`、`静态代码扫描`、`自动化测试`、`代码覆盖率` 等）。

### 退回 fsd deploy 的条件

**仅当以下情况之一成立时**，才退回使用独立的 `fsd deploy` 命令：

1. 用户指定备机部署且需要指定 IP（交付 trigger 不支持 IP 指定，须退回 `fsd deploy staging -I <ip>`）
2. 用户明确要求独立部署某一服务
3. 用户明确要求「部署分支=开发分支」，且**交付内各服务开发分支各不相同**（无法用统一的 `--test-branch` 覆盖）

退回时应尽量从交付详情补全已知字段（`jobName`、`developBranch`、`testBranch`、`stackUuid` 等），不重复询问用户。退回 `fsd deploy swimlane` 时，`-t`（testBranch）须显式设为该服务的 `developBranch`，与 `-d` 保持一致。

---

## queryJobByGit 接口

缺服务名时（如「把当前分支合并到 qa 部署到骨干」），CLI 内部自动调用此接口。

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| git | string | 是 | git 仓库 SSH 地址 |
| branch | string | 是 | 分支名 |

返回 data 每项含 id、name、git、plusId、octoAppKey、plusName 等。其中 **name** 即 jobName。  
当 `bdsMode=jar` 且 `buildProject` 非空时，自动补充 `pomPaths=buildProject` 透传给部署接口。

**jar 包变更模块自动检测（bdsMode=jar）**：

当检测到服务 `bdsMode=jar` 时，CLI 优先通过 git 检测变更模块，按以下顺序：

1. 优先与 master 做三点 diff（`git diff origin/master...HEAD` 或 `git diff master...HEAD`），准确反映当前分支的全部变更
2. 若无法与 master diff，兜底检查工作区未提交变更（staged + unstaged + 未跟踪文件）
3. 解析根 `pom.xml` 中的 `<modules>` 定义，将变更文件映射到对应子模块
4. 读取各子模块 `pom.xml` 中的 `artifactId`，构建 `pomPaths`，格式为逗号分隔，如 `frame-inline-service,agent-api`
5. 若根 `pom.xml` 有变更，在结果中追加 `./`（最外层父 pom），与子模块 artifactId 一起传，如 `./,platform-api`；仅根 pom 变更无子模块变更时传 `./`
6. 若无法检测到任何变更模块，降级使用服务的 `buildProject` 字段值

**多结果自动 appkey 匹配**：

当 `queryJobByGit` 返回多条结果时，在输出候选列表让用户确认之前，**优先通过本地项目的 appkey 进行自动过滤**，流程如下：

1. **读取本地 appkey**（按顺序尝试，取第一个成功结果）：
   ```bash
   # 优先：从 META-INF/app.properties 读取 app.name
   find . -name "app.properties" -path "*/META-INF/*" -type f | head -1 | xargs grep "app.name" | cut -d'=' -f2 | tr -d ' '

   # 备选：从 application.yml 读取 spring.application.name
   grep "spring.application.name" application.yml | cut -d':' -f2 | tr -d ' '
   ```

2. **匹配规则**：将读取到的本地 appkey 与返回列表中每项的 `octoAppKey` 字段做精确匹配，取第一条命中结果自动继续部署（骨干/备机/泳道均适用），无需用户确认；无匹配或无法读取本地 appkey 时，直接取返回列表第一条结果。

## 错误处理

| 错误类型 | 用户提示 | 建议 |
|----------|----------|------|
| 401/403 | 权限不足，无法部署此服务 | 联系服务负责人 |
| 404 | 服务或分支不存在 | 确认名称和分支 |
| 超时 | 部署请求超时 | 稍后查看 FSD 界面 |
| 参数错误 | 参数不正确：${具体错误} | 检查参数格式 |
| 泳道不存在 | 泳道 UUID 不存在或已删除 | 确认 UUID |
| 泳道权限不足 | 没有该泳道的部署权限 | 联系泳道创建者 |

<a id="maven-dependency-publish-flow"></a>

## Maven 依赖缺失（组件 JAR 未进可解析仓库）

排查入口与扩展场景索引 → [troubleshooting.md](troubleshooting.md)。

当 `deploy analyze` 日志中出现 **`Could not resolve dependencies`**、**`Could not find artifact`**、**`absent`** 等，说明**依赖组件**未进入当前构建使用的 Maven 仓库（泳道离线源、快照库等）。助手应按下面顺序执行，**不得**用本机当前 checkout 分支代替「该版本应对应的分支」。

### CLI 能力与边界

| 能力 | 命令 / 接口 | 说明 |
|------|-------------|------|
| 按 **GAV** 查服务、分支、仓库与部署人 | `fsd app jar-info` / `fsd app jar-deploy` | 底层 `/api/qa/v1/jar/versionManager/baseInfo` + `visionHistoryV2`（**仓库根 `pom` 文档**）；`jar-deploy` 解析后直接 `executeAutoDeploy` 或 `deployToExistingStack`。 |
| 按 **Git + 分支** 查应用 | `fsd app find -g <ssh> -b <branch>` | `queryJobByGit`。 |
| 按 **jobName** 列分支 | `fsd app branches -a <jobName> [-q 子串]` | `getBranchListByJob`，兜底用。 |
| 按 **jobName** 或 **octoAppKey** 查研发/测试负责人 | `fsd app job-owners -a <jobName>` 或 `--appkey <octoAppKey>` | `getInfoByName` → `adminRd` / `adminQa`；appkey 路径先 `listPageAuth` 精确匹配 octo。详见 [app-job-owners.md](app-job-owners.md)。 |

### 流程

| 步骤 | 动作 |
|------|------|
| 1. 定坐标 | 从日志提取 `groupId:artifactId:version`（含 `-SNAPSHOT`）。 |
| 2. 解析并发布（首选） | `fsd app jar-info -g … -m … --jar-version … --pretty` 核对 **jobName、发布分支、各 repository 的 deployUser**；再 `fsd app jar-deploy -g … -m … --jar-version …`（骨干）；泳道缺包则加 **`-u <泳道UUID>`**。勿用 `--version`，会与 `fsd --version` 冲突。若 `jar-info` 已列出该版本在各 repository 的记录，**分支与缺包仓库对齐**、**模块用应用默认 `buildProject`（勿随意 `-p`）** 见 [troubleshooting.md#maven-private-jar](troubleshooting.md#maven-private-jar) 小节「有明确版本发布记录时」。 |
| 3. 兜底 | versionManager 无匹配时：`fsd app branches` / `fsd app find` + `fsd deploy test -a <jobName> -t <分支>` 且**不加 `-d`**。 |
| 4. 重试原应用 | 依赖组件成功后，再触发原先失败的应用部署或流水线。 |

### 易错点

- **错误**：用本机 `git branch --show-current` 作为部署分支。  
  **正确**：缺包时优先 **`fsd app jar-info` / `jar-deploy`** 按 GAV 从 versionManager 取分支；兜底再用 **`fsd app branches`** 或 Git + 约定分支名。
- **错误**：`fsd deploy test -d <开发分支>` 且默认 `-t qa`，触发「合并到 qa」导致冲突。  
  **正确**：仅发布某分支上的组件时，常用 **`-t <该分支>` 且省略 `-d`**，直接编该分支。

## CLI 内部参数

以下参数由 CLI 内部处理，AI 不直接传递。仅供理解 CLI 行为。

> **注**：表中 `job_name` 标记为「必填」指接口层必需；CLI 会自动从当前 git 仓库推断（`queryJobByGit`），用户无需手动指定 `-a`。

所有部署命令共享的自动行为：部署前调用 `getInfoByName` 校验服务存在；若 `bdsMode=jar` 且 `buildProject` 非空，自动透传 `pomPaths`。`created_by` 通过 API Key 自动获取。

### fsd deploy test（主干部署）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| job_name | string | 是 | 服务名称 (默认: 必填) |
| deploy_branch | string | 否 | 部署分支 (默认: qa) |
| feature_branch | string | 否 | 开发分支（提供时合并到部署分支） (默认: 无) |
| template | string | 否 | 部署模版 (默认: 空) |
| env | string | 否 | 固定 test (默认: test) |
| pom_paths | string | 否 | jar 包服务构建模块，逗号分隔的 artifactId；`-p` 手动指定时直接透传，不指定时自动与 master diff 检测 (默认: 自动检测) |

禁止传入：`-i`、`-u`、`--create`、`-s`

### fsd deploy staging（备机部署）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| job_name | string | 是 | 服务名称 (默认: 必填) |
| deploy_branch | string | 否 | 部署分支（`-t`），备机默认 `staging`，与骨干默认 `qa` 不同 (默认: **staging**) |
| feature_branch | string | 否 | 开发分支（`-d`），优先本地 `git branch --show-current`，读取不到则留空不传 (默认: 无) |
| ips | string | 否 | 备机 IP 列表（逗号分隔），CLI 参数为 **`-I`（大写 i）**；不指定时自动获取该服务 staging 环境的 slave 备机 IP (默认: 自动获取) |

禁止传入：`-u`、`--create`、`-s`

### fsd deploy swimlane --create（新建泳道）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| job_name | string | 是 | 服务名称 (默认: 必填) |
| deploy_branch | string | 否 | 未指定时用当前 git 分支 (默认: 当前分支) |
| feature_branch | string | 否 | 开发分支 (默认: 无) |
| stack_name | string | 否 | 泳道名称（自动：fsd-skill-{misId}-{timestamp}） (默认: 自动生成) |

固定参数：env=test, buildType=deploy, isCreateStack=1, mavenType=cargo  
禁止同时传入：`-u`、`-i`

### fsd deploy swimlane -u（已有泳道）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| job_name | string | 是 | 服务名称 (默认: 必填) |
| stack_uuid | string | 是 | 泳道 UUID 或详情链接（自动解析） (默认: 必填) |
| deploy_branch | string | 否 | 未指定时用当前 git 分支 (默认: 当前分支) |
| feature_branch | string | 否 | 开发分支 (默认: 无) |

禁止同时传入：`--create`、`-s`、`-i`

### fsd deploy swimlane-info（查询泳道元信息）

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| -n, --name | string | 是 | 泳道名称（如 `selftest-260319-200246-566`） (默认: 必填) |
| --pretty | string | 否 | 人类可读格式输出 (默认: 否) |

返回字段：

| 字段 | 说明 |
|------|------|
| `name` | 编排名称 |
| `machineEnv` | 环境（test/staging） |
| `swimlane` | 泳道名称 |
| `swimlaneVersion` | 泳道版本 |
| `stackUuid` | 编排 UUID（可用于 `fsd deploy swimlane -u`） |
| `url` | Cargo 详情链接 |
| `createTime` | 创建时间 |
| `isolation` | 是否隔离 |
| `deleteFlag` | 是否已删除 |

---

## MIS 配置

| 方式 | 说明 |
|------|------|
| 配置文件 | `~/.meituan_local/config.json` 中 `{"user": {"mis": "你的MIS"}}` |
| SSO 自动 | 安装 `browser-cookie3`，确保浏览器已登录 FSD，自动从 getCurrentUser 获取 |

---

## 部署结果字段映射

### 部署触发结果

| 字段 | 说明 |
|------|------|
| `eventId` | 查询部署进度用 |
| `appkey` | 可传给 `fsd autotest` 的 `--appkey` |
| `swimlane` | 泳道标识 |

其余字段（jobName/developBranch/testBranch/env）含义自明。

### deploy status 结果（data 字段）

| 字段 | 说明 |
|------|------|
| `status` | `running` / `success` / `failure` |
| `env` | `test`=骨干或泳道，`staging`=备机 |
| `appKey` | 可传给 `fsd autotest` 的 `--appkey` |
| `swimLane` | 泳道 ID，传给 `--swimlane` 和覆盖率 |
| `cellType` | `swimlane` / `backbone` / `staging` |
| `startTime` / `endTime` | 毫秒时间戳 |
| `jobOperateSteplVos` | 部署节点列表（见下） |
| `serviceDeployIps` | 可选；`{ jobName, ip }[]`，来自构建部署步骤详情（见下节） |

其余字段（title/jobName/eventId/branch/developBranch/testBranch/cellName/createBy/deploySource）含义自明。

### 部署进度与部署机器 IP

- **主数据**：`GET /api/branchEvent/detailProgress/{eventId}`（与 `queryDeployProgress` 过滤后的 `data` 一致）不含逐服务部署 IP。
- **补充字段 `serviceDeployIps`**：CLI 在默认模式下额外请求 `GET /api/branchEvent/detailByStepName?eventId=&stepName=`，按顺序尝试 `FSD_DeliverQaDeploy`、`FSD_DeliverQaDeployNew`、`BatchDeploy`，与 skill-dev 中 `DeployServiceImpl#detailByStepName` / `DeployStepResultVo.ip`（部署机器 IP）对齐；命中首个能解析出 `deployStepResultVos` 或 `ip` / `ipList` 的响应后，汇总为 `serviceDeployIps`。
- **关闭补充请求**：`fsd deploy status -i <id> --no-service-ips`；内部监控轮询（`monitor-deploy-daemon`）与 `executeAutoDeploy` 合并结果路径默认不请求，避免高频重复调用。

### jobOperateSteplVos 每项

| 字段 | 说明 |
|------|------|
| `stepName` | 节点标识（见映射表） |
| `status` | `success` / `failure` / `running` / `null`(未执行) |
| `errorMsg` | 错误信息 |
| `piplineDetail` | 子节点列表（结构同父） |

其余字段（startTime/endTime/operateId）含义自明。

### stepName 映射

| stepName | 中文 |
|----------|------|
| `scm_manage` | 分支管理 |
| `mergeDevelopBranch` | 合并开发分支 |
| `mergeMasterBranch` | 合并 master |
| `cargo-plus-deploy`(顶层) | 构建部署 |
| `cargo-plus-compile` | 编译构建 |
| `cargo-plus-deploy`(piplineDetail 内) | 部署环境 |
| `plus-compile` | 编译构建 |
| `plus-deploy` | 部署环境 |

同名 `cargo-plus-deploy` 通过层级区分：顶层=构建部署，子节点=部署环境。

---

## 部署结果展示格式

按顺序展示：

**1. data 完整 JSON**：原样输出 data 字段，禁止用 `[...]`/`...`/注释截断，包括 jobOperateSteplVos 及其 piplineDetail。

**2. 摘要行**：

```
环境：{env}  部署分支：{testBranch}  开始时间：{startTime→yyyy-MM-dd HH:mm:ss}
```

**3. 节点状态树**：

```
- {顶层中文名} {图标}
  - {子节点中文名} {图标}
```

图标：success→✅ failure→❌ pending→⏳ null→—

status_label：running→部署中🔄 success→部署成功✅ failure→部署失败❌

---

## 失败日志处理

检测到失败节点时立即处理，无需用户请求。

日志路径：`{workspace}/.fsd-logs/fsd_deploy_{eventId}_{stepNameCn}.log`（已存在则直接读取）

触发条件：stepName 含 `plus-compile`/`plus-deploy`/`cargo-plus-compile`/`cargo-plus-deploy`

stepName 转换（调接口前）：`cargo-plus-compile`→`plus-compile`，`cargo-plus-deploy`→`plus-deploy`

调用：`fsd deploy status -i {eventId}` — CLI 自动完成转换、下载、清洗、提取 ERROR 行（去重，最多 10 条）。

失败汇报格式：

```
{data 完整 JSON}
【部署进度】{jobName} · 部署失败 ❌（eventId: {eventId}）
节点状态（跳过已成功节点）：
- {顶层中文名} ❌
  - {失败子节点} ❌
    失败原因：{errorMessage}
```

---

## 部署监控流程

### 推荐方式（同步阻塞，一条命令搞定）

```bash
fsd deploy test --pretty       # 触发 → 自动启动 daemon → 实时输出直到终态
fsd deploy staging --pretty    # 同上
fsd deploy swimlane --pretty   # 同上
```

触发后 CLI 内部自动完成：

1. 启动后台 daemon 写日志（`~/.fsd_monitor_logs/fsd_deploy_<eventId>_<ts>.log`）
2. 打印 `monitor_file=<path>`（供需要时手动 attach）
3. **立即开始流式输出日志，阻塞直到 success/failure 终态**

AI 无需再单独调用 `--observe`，也无需 sleep 轮询。

### 异步模式（后台执行，立即返回）

```bash
fsd deploy test --pretty --async
```

触发后启动 daemon，打印 `monitor_file=<path>` 后立即返回，不阻塞。

### 手动 attach（用于恢复监控）

```bash
fsd deploy status --observe <monitorFile> -i <eventId>
```

适用于：AI 意外断开、需要在新终端重新 attach，或 `--async` 后想手动查看进度。

### 非 pretty 模式（JSON + monitor_file）

```bash
fsd deploy test        # 输出触发 JSON，末尾追加 monitor_file=<path>
```

daemon 同样会启动，AI 可从输出中提取 `monitor_file=` 后调用 `--observe`。

### 单次状态查询（不触发 daemon）

```bash
fsd deploy status -i <eventId>              # JSON
fsd deploy status -i <eventId> --pretty     # 人类可读
```

---

## 部署失败 AI 分析

### 独立部署失败分析

`deploy status` 返回 `failure` 时，执行 AI 智能分析：

```bash
fsd deploy analyze -i <eventId>
```

### 测试计划下单个应用失败分析

当用户提及特定应用失败（如「应用部署失败：waimai-qa-deploy-test-thrift」）且当前在**测试计划上下文**中时：

**分析流程**：

1. **获取应用列表**：`fsd test jobs --id <testPlanId> --pretty`
2. **精确匹配应用**：从 JSON 的 `jobList` 中按 `jobName` 精确查找用户指定的应用（如 `waimai-qa-deploy-test-thrift`）
3. **提取 eventId**：记下该应用的 `eventId`、`buildStatus` 等信息
4. **分析失败原因**：`fsd deploy analyze -i <eventId>`

**示例**：
```bash
# 步骤 1：获取测试计划下的所有应用
fsd test jobs --id 72928 --pretty
# 输出包含：jobName: "waimai-qa-deploy-test-thrift", buildStatus: "FAILED", eventId: "12345", ...

# 步骤 2-3：找到 waimai-qa-deploy-test-thrift 的 eventId（如 12345）

# 步骤 4：分析该应用的失败原因
fsd deploy analyze -i 12345
```

**约束**：
- **禁止**跳过 `test jobs` 直接凭应用名猜测 eventId
- **禁止**用 `--latest` 代替具体应用的 eventId（多应用时无法准确定位）
- **务必**从平台部署记录中获取 eventId，不从本地代码或 commit 信息推断

### 测试计划下多服务失败分析

当在**测试计划上下文**中且已确定 `testPlan.id`，用户要求分析**所有**失败应用时：

```bash
# 进入测试计划工作目录
cd /Users/song/automan-test-plans/plan_72928

# 自动从测试计划服务列表获取失败服务，分析每个服务的失败原因
fsd deploy analyze --max-lines 500
```

此时命令会：
1. 从测试计划获取完整的服务列表（jobList）
2. 筛选构建状态为失败的服务（如 `waimai-qa-deploy-test-web`、`waimai-qa-deploy-test-jar` 等）
3. 逐一分析每个失败服务的部署日志和错误原因
4. 输出结构化的失败分析结果（包含服务名、失败步骤、错误信息、完整日志等）

**示例场景**：
```bash
# 场景：您有多个应用部署失败，需要一次性分析所有失败原因
cd /Users/song/automan-test-plans/plan_72928
fsd deploy analyze --max-lines 500
# 输出：自动分析所有失败应用的失败原因（无需手动指定每个 eventId）
```

**注意**：
- 不需要手动指定服务名或 eventId，命令会自动关联到所有失败服务的部署记录
- 使用 `fsd test jobs --id <testPlan.id>` 获取失败应用列表后，逐一 `fsd deploy analyze -i <eventId>` 分析
- 输出为 JSON 格式，包含所有失败服务的完整分析信息

### 分析输出要求

命令输出完整的部署上下文 + 各失败步骤的**原始日志**。获取输出后**必须**：

1. **完整阅读日志内容**，不得仅凭 errorMsg 字段或关键字匹配得出结论
2. **输出结构化分析**：
   - **错误详情**：具体报错文件、行号、错误类型和错误信息
   - **根因分析**：解释为什么报错，是什么问题导致的
   - **修复方案**：给出具体的修改建议（文件路径、行号、改法）
3. **不允许**仅凭 commit message 或 branch name 推测原因而不看日志

**处理循环：**

1. `fsd deploy analyze` (或 `-i <eventId>`) → 读完整日志 → 输出错误详情 + 根因 + 修复方案
2. 用户确认修复后 → 重新执行部署命令
3. 循环直到 status=success 或用户放弃

---

## coverage status 输出规范

输出 JSON + 自然语言摘要。

```json
{"coverageIncrementStatistic": {...}, "commitInfo": [...], "multiInfos": {...}}
```

| 字段 | 说明 |
|------|------|
| `coverageIncrementStatistic.*Total/*Covered` | Class/Line/Method/Branch/Instruction 的总数与覆盖数 |
| `commitInfo[].type` | `deploy` / `develop` |
| `commitInfo[].commit/branch/commitUrl/contrastBranch` | commit 信息与对比链接 |
| `multiInfos[appkey][].deployBranch/developBranch/env/swimlane` | 部署信息（swimlane=`core` 表示骨干） |
| `multiInfos[appkey][].startTime/endTime` | 统计时间范围 |

---

## 使用示例

```bash
# 合并开发分支到 qa 并部署主干
fsd deploy test -a waimai-qa-misc-new -d feature/xxx -t qa

# 列举骨干场景下可选部署模板（再按需加 --deploy-template）
fsd deploy templates test -a waimai-qa-misc-new -t qa --pretty

# 直接部署指定分支到主干（默认 -t qa）
fsd deploy test -a waimai-qa-misc-new -t qa

# 备机部署
fsd deploy staging -a waimai-qa-misc-new -t qa -i 10.1.2.3

# 新建泳道部署（指定泳道名）
fsd deploy swimlane --create -a waimai-qa-misc-new -t qa -s my-test-stack

# 新建泳道部署（自动生成泳道名，自动推断服务和分支）
fsd deploy swimlane --create

# 部署到已有泳道（UUID）
fsd deploy swimlane -a waimai-qa-misc-new -t qa -u 2f52fd27-xxxx

# 部署到已有泳道（URL，CLI 自动解析 UUID）
fsd deploy swimlane -u "https://dev.sankuai.com/cargo/stack/detail/f065.../build?..."

# 缺服务名时 CLI 自动从 git remote 推断
fsd deploy test -d feature/xxx -t qa

# 查询泳道元信息
fsd deploy swimlane-info -n selftest-260319-200246-566 --pretty
```

### 部署分支默认值

| 场景 | 命令 | 默认 `-t` | 是否合并 |
|------|------|-----------|----------|
| 主干 | `fsd deploy test` | qa | 若提供 `-d` 则合并 |
| 备机 | `fsd deploy staging` | qa | 若提供 `-d` 则合并 |
| 新建泳道 | `fsd deploy swimlane --create` | 当前分支（不传 `-t`） | 否 |
| 已有泳道 | `fsd deploy swimlane -u <uuid>` | 当前分支（不传 `-t`） | 否 |

**重要**：
- **主干/备机场景**：缺部署分支 → 默认 `-t qa`
- **泳道场景**：用户说「当前服务」「当前分支」或未提分支时，**不要传 `-t qa`**，省略 `-t` 让 CLI 使用当前分支

---

## 部署场景决策示例

> 根据用户自然语言表述，选择对应的 `fsd deploy` 命令

| 用户表述 | 理解 | 命令 |
|----------|------|------|
| "把 X 的 feature/abc 合并到 qa 部署到骨干" | 主干 + 分支合并 | `fsd deploy test -a X -d feature/abc -t qa` |
| "部署骨干" / "部署 X 到 test"（无泳道关键字） | 主干，默认 -t qa | `fsd deploy test -a X -t qa` |
| "把当前分支合并到 qa 部署到骨干"（缺服务名） | CLI 自动从 git remote 推断 | `fsd deploy test -d <当前分支> -t qa`（不传 `-a`） |
| "备机部署 X 到 10.1.2.3" | 备机，指定 IP | `fsd deploy staging -a X -t qa -i 10.1.2.3` |
| "备机部署 X"（未指定 IP） | 备机，自动获取备机 IP | `fsd deploy staging -a X -t qa` |
| "创建泳道 my-stack 并部署 X 的 qa" | 新建泳道 + 部署 | `fsd deploy swimlane --create -a X -t qa -s my-stack` |
| "新建泳道部署当前" / "新建泳道部署下" | 新建泳道，全部自动推断 | `fsd deploy swimlane --create`（不传 `-a` `-t`） |
| "把 feature/abc 合并到 qa 部署到泳道 UUID" | 已有泳道 + 合并 | `fsd deploy swimlane -a X -d feature/abc -t qa -u UUID` |
| "在 UUID 泳道部署当前服务" | 已有泳道，自动推断 | `fsd deploy swimlane -u UUID`（不传 `-a` `-t`） |
| "部署到泳道 URL"（含 Cargo 链接） | CLI 从 URL 自动解析 UUID | `fsd deploy swimlane -u "https://dev.sankuai.com/cargo/..."` |
