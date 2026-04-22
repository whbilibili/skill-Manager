# 测试计划 · liteSet 部署（CLI）

与 [delivery-liteSet-trigger.md](delivery-liteSet-trigger.md) 字段语义一致；差异为 liteSet 策略接口使用 **`source=1`、`sourceId=<testPlanId>`**（与 `fsd-execute-pipeline` / 页面环境部署一致），交付为 `source=0`、`sourceId=<applyProgramId>`，上线计划为 **`source=2`**（`fsd deploy staging --online-program <id> --env liteSet`，见 [pub.md](pub.md#上线计划-liteset-部署)）。

**校验失败、助手禁止去参重试（与 SKILL 对齐）**：测计划侧命令为 **`fsd test deploy`**、**`fsd test trigger-pipeline`**；涉及 **`--develop-branch`**、**`--test-branch` / `--deploy-branch`**、**`--lite-set-template`**、**`--lite-set-name`**。完整规则（现象、`未触发部署。`、禁止省略参数自动重试、CLI 常量 `FSD_LITESET_REJECT_NO_OMIT_RETRY_HINT`、Gotchas 表）见 [delivery-liteSet-trigger.md](delivery-liteSet-trigger.md) 文首 **「校验失败时（CLI 与助手）」** 专节。

## 命令

```bash
fsd test trigger-pipeline --id <testPlanId> --env liteSet --pretty
fsd test deploy --id <testPlanId> --env liteSet --pretty
# 指定应用 + 开发分支（两命令均支持）
fsd test deploy --id <testPlanId> --job-name <jobName> --develop-branch <branch> --env liteSet
fsd test trigger-pipeline --id <testPlanId> --job-name <jobName> --develop-branch <branch>
# 或使用 --appkey 代替 --job-name
```

- 未传 `--env` 时沿用测试计划详情 `detail.env`；显式 `--env liteSet` / `liteset` 等与交付归一规则相同。
- 仅 **`getJobList` 中 `isLiteSetPlus=true`** 的服务进入请求体；其余服务跳过并 stderr 提示。
- 部署分支：可选范围以 **`GET /api/qa/v1/branch/baseBranch/getBranch?jobName=&branch=`** 的 `data[]` 为准；未传 `--test-branch` / `--deploy-branch` 时，在列表内按 **`liteSetBranch` → `branches[]` → `developBranch`** 取第一个命中；**`--test-branch` 或 `--deploy-branch`** 覆盖（须在列表内）。
- **`--develop-branch`**：覆盖「开发分支」，每服务在请求体中只占一行（默认会按 `getJobList.branches` 多分支多行展开）。
- **`--lite-set-template` / `--lite-set-name`**：覆盖 Talos 模板与 set；**二者均传**时可不请求 `getLiteSetTemplates` / `getHostsByJobs`；只传其一则另一项仍走接口默认。

## 接口

| 用途 | 方法 | 说明 |
|------|------|------|
| job 行 | `GET /api/qa/v1/fsdTestplan/getJobList?testPlanId=` | `liteSetBranch`、`isLiteSetPlus` 等 |
| 部署分支可选列表 | `GET /api/qa/v1/branch/baseBranch/getBranch?jobName=&branch=` | 与测计划详情环境部署分支同源；CLI：`getTestPlanBaseBranchList` |
| template | `POST .../job/getLiteSetTemplates?env=prod&source=1&sourceId=<testPlanId>` | Body：`jobName[]` |
| setName | `POST .../ops/getHostsByJobs?env=prod&source=1&sourceId=<testPlanId>` | Body：`jobName[]` |

## 代码

- `fsd/cli/scripts/test-plan/test-plan-ops.js`：`enrichTestPlanJobsLiteSet`、`isTestPlanEnvLiteSet`、`resolveTestPlanDeliveryPipelineEnv`
- `fsd/cli/scripts/test-plan/commands.js`：`trigger-pipeline` / `deploy` 的 `--env`、`--test-branch`、`--develop-branch`、`--job-name` / `--appkey`、`--lite-set-template`、`--lite-set-name`
- `fsd/cli/scripts/shared/client.js`：`getLiteSetTemplatesByJobs`、`getLiteSetHostsByJobs`（`{ source: 0|1 }`）、`getTestPlanBaseBranchList`
- `fsd/cli/scripts/shared/lite-set-deploy-branch-allowlist.js`：`resolveLiteSetDeployBranchFromAllowlist`、`pickTestPlanLiteSetBranchCandidates`
