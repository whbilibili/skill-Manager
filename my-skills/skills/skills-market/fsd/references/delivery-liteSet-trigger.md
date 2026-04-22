# 交付自测流水线 · liteSet 环境（CLI）

## 校验失败时（CLI 与助手）

本专节为 **SKILL** 中 liteSet「禁止去参重试」类约束的**唯一详述处**（技能正文仅保留到此文档的链接）。

### 适用范围与命令

| 语境 | 典型命令 |
|------|----------|
| 交付自测流水线 | `fsd delivery trigger`、`fsd delivery trigger-retry`（`--env liteSet`，或交付详情 env 已为 liteSet） |
| 测试计划环境部署 / 流水线 | `fsd test deploy`、`fsd test trigger-pipeline`（`--env liteSet` 或计划详情 env 为 liteSet；字段与接口差异见 [test-plan-liteSet.md](test-plan-liteSet.md)） |

### 现象与终止

若因 **liteSet 部署分支**（`--test-branch` / `--deploy-branch`；交付侧另有 **`-b` / `--branch`** 与 `developBranch` 收窄）、**Talos 模板**（`--lite-set-template`）、**setName**（`--lite-set-name`）、**开发分支**（`--develop-branch`，测试计划）等与 `getJobList` / 平台返回不一致而失败，stderr 常以 **`未触发部署。`** 开头并附学城说明链接 —— **此时流程已终止**，**未**调用 `triggerPipeline`、`FSD_DeliverQaDeploy` 等触发部署接口。

### 助手 / 自动化（必读）

- **禁止**失败后自动再执行「**省略**上述任一参数」的**同一类**命令（例如去掉 `--lite-set-template` 或 `--test-branch` 再跑一遍 `delivery trigger` / `test deploy`）。
- **禁止**静默改参（臆测有效分支、模板或 setName 后重试）。
- **应停止**：向用户展示 **CLI 报错全文** 与文案中的**配置说明链接**，由用户修正 FSD 配置或命令行参数后再**手动**执行。

### CLI 固定提示

同类拒绝错误末尾会附带固定一句（`fsd/cli/scripts/shared/config.js` 中 **`FSD_LITESET_REJECT_NO_OMIT_RETRY_HINT`**），明确勿去掉相关参数后重试同命令。

### 与 troubleshooting.md 的区别

文档或口语中的「重试」指**用户确认修复后**再次执行；**不是**助手在参数校验被拒后自动降级为无参命令。

### Gotchas（速查）

| 易错点 | 正确做法 |
|--------|----------|
| `未触发部署。` 后自动去掉 `--lite-set-template`、`--test-branch`、`--develop-branch` 等再跑同一条 `delivery trigger` / `test deploy` | **严禁**：须展示报错与学城链接，由用户修正后再执行 |

## 命令

```bash
fsd delivery trigger -i <applyProgramId> --env liteSet --pretty
# 自主指定模板与 set（二者均传时不再请求 getLiteSetTemplates / getHostsByJobs）
fsd delivery trigger -i <applyProgramId> --env liteSet --lite-set-template '<模板名>' --lite-set-name '<setName>' --pretty
```

与 ED 在 `env=liteSet` 下一致：`POST /api/fsd_ed/api/deliveryPipeline/triggerPipeline` 的 `jobList[]` 需带 `template`、`setName`。

`fsd delivery trigger-retry` 在交付为 liteSet 时同样支持 `--lite-set-template`、`--lite-set-name`。

## 参数来源

| 字段 | 接口 / 依据 | 说明 |
|------|-------------|------|
| `template` | `POST .../getLiteSetTemplates?env=prod&source=0&sourceId=<applyProgramId>`，Body：`jobName[]` | `data[jobName][0].name`；**`--lite-set-template` 覆盖** |
| `setName` | `POST .../getHostsByJobs?env=prod&source=0&sourceId=<applyProgramId>`，Body：同上 | 从返回中解析首项（支持 `list`/`dataList`/`hosts` 等嵌套及 `set_name`、`liteSetName` 等字段）；**`--lite-set-name` 覆盖** |
| 上线计划（CLI） | `source=2`，`sourceId=<onlineProgramId>`；触发 `publishPlanStep/deploy/staging/<id>?env=liteSet` | 见 [pub.md · 上线计划 liteSet 部署](pub.md#上线计划-liteset-部署) |
| `jobList[].testBranch`（部署分支） | **`GET .../testapply/getBranchList?jobName=&branch=`**（与测试申请详情页同源） | **仅 liteSet**：可选范围以接口返回的 `data[]` 为准；未传 `--test-branch` / `--deploy-branch` 时，在允许列表内按 **`liteSetBranch`（`lite_set_branch`）→ `branches[]` → `developBranch`** 顺序取第一个命中项。**不用**行内 `testBranch`（多为 `qa-selftest-*` 等，属骨干/发布语义）。**非 liteSet** 路径仍为 `--test-branch` → 行 `testBranch` → `qa`/`staging` 等。 |
| `coerceDeploy` | — | 有模板节点时为 `false`，无节点时为 `true` |

查询串统一 `&source=0&sourceId=<applyProgramId>`。

## 同名 job、多 `developBranch`

- `-b <developBranch>`：在交付列表中只保留 `developBranch` 匹配的行，再读该行的 `liteSetBranch` 等字段。
- `getJobList` 一行对应 `jobName` + `developBranch`。`liteSetBranch` 由后端按 `jobName` 从 Map 写入，**多行同名时字段值可能相同**。

## 服务范围

仅 `isLiteSetPlus === true` 的 job 进入 `jobList`。过滤后为空时 CLI 报错并提示学城 [liteSet 部署策略说明](https://km.sankuai.com/collabpage/2711048357)。

## trigger-retry

交付 `env` 为 liteSet 时，重试组装 `jobList` 同样填充 `template` / `setName`；非 `isLiteSetPlus` 报错并给出上述链接。

## 相关代码

- `fsd/cli/scripts/shared/client.js`：`getLiteSetTemplatesByJobs`、`getLiteSetHostsByJobs`（`source=0` 交付 / `source=1` 测试计划 / **`source=2` 上线计划**）、**`getTestapplyBranchList`**（交付 liteSet 部署分支允许列表）
- `fsd/cli/scripts/shared/lite-set-api-parse.js`：解析模板/set 接口返回结构
- `fsd/cli/scripts/deploy/query-ops.js`：`triggerSelfTestPipeline`（`liteSetTemplate` / `liteSetSetName`）、`_buildMultiJobTriggerPayload`、`_buildRetryFailedJobListPayload`、`_fetchDeliveryLiteSetBranchListsByJobNames`（`getTestapplyBranchList`）
- `fsd/cli/scripts/shared/lite-set-deploy-branch-allowlist.js`：`resolveLiteSetDeployBranchFromAllowlist`、`pickDeliveryLiteSetBranchCandidates`
- `fsd/cli/scripts/delivery/commands.js`：`delivery trigger` / `trigger-retry` 的 `--lite-set-template`、`--lite-set-name`
- 测试计划 liteSet：`fsd/references/test-plan-liteSet.md`
