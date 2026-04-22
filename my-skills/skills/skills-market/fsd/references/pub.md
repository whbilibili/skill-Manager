# 上线计划参考手册（fsd pub）

> 所有操作遵循 SKILL.md 核心规则。

## `fsd pub list` 输出关键字段

| 字段 | 说明 | 用途 |
|------|------|------|
| `id` | 上线计划ID | 所有后续命令的 `-i` 参数 |
| `dutyQa` | 值班QA（MIS账号逗号分隔） | create 时推断 `-d` |
| `rdDepartment` | 研发部门orgId（逗号分隔） | create 时推断 `--rd-dept` |
| `planType` | 计划类型（1=普通） | create 时固定传 `1` |
| `projectOnlineTime` | 预计上线时间（毫秒时间戳） | 参考值 |
| `status` | 状态（10=进行中） | 筛选参考 |

---

## `fsd pub create` 参数与值班QA自动推断

`--apply-id <applyProgramId>` 可选参数：创建上线计划时同时关联交付。CLI 会自动查询交付详情，按以下规则设置 `dutyQa`：

| 场景 | dutyQa 规则 |
|------|------------|
| `--apply-id` + 标准交付(projectType=4) | 交付的参与QA(`qa`字段) |
| `--apply-id` + 自测交付(projectType=1) | 当前用户（创建人） |
| 无 `--apply-id`（空计划/单应用） | 当前用户（创建人） |
| 显式传 `-d` | 以 `-d` 为准，不自动推断 |

`rdDepartment` 规则：从最近与我相关的上线计划推断，同时合并交付的 `rdOrgid`。

> **NEVER 手动查交付详情再拼 `-d` 和 `--rd-dept`，直接用 `--apply-id` 让 CLI 自动推断。**

```bash
# 有交付时新建计划（推荐用法）
fsd pub create -n "<计划名>" -t "<上线时间>" --apply-id <applyProgramId>
# 无交付时新建空计划
fsd pub create -n "<计划名>" -t "<上线时间>"
```

### 大象群配置（`--dx-group`）

`pub create` 和 `pub edit` 均支持 `--dx-group`，控制上线计划的大象群通知：

| 值 | 效果 | dxGroupMessageMap |
|---|---|---|
| `create` / `new` | 新建大象群（create 默认行为） | `{ dxGroupId: '', edCreate: 1 }` |
| `<群ID>` | 绑定已有大象群 | `{ dxGroupId: '<群ID>', edCreate: 0 }` |
| `none` / `off` | 不创建大象群 | `{ dxGroupId: '', edCreate: 0 }` |

```bash
fsd pub create -n "xxx" -t "2026-04-01 20:00:00" --dx-group 123456   # 绑定已有群
fsd pub edit -i <id> --dx-group none                                  # 关闭大象群
fsd pub edit -i <id> --dx-group 789012                                # 修改为其他群
```

> `projectOnlineTime` 传**毫秒时间戳**（`new Date("yyyy-MM-dd HH:mm:ss").getTime()`）。
> AI 创建新上线计划时，若名称未以 `-ai` 结尾，会自动补齐该后缀。

---

## `fsd pub list --apply-id` 推荐计划逻辑

当目标是“把某个交付加入上线计划”时，先调用：

```bash
fsd pub list --apply-id <applyProgramId>
```

对应接口：

```text
GET /api/qa/v1/onlinePlan/getOnlinePlanByDelivery?applyProgramId=<applyProgramId>
```

规则：

- 返回结果中的 `id` 字段不对外展示
- 若返回有合适的推荐上线计划，优先加入现有计划
- 若没有合适计划，再创建新上线计划
- 若用户明确要求“新建上线计划”，则跳过推荐计划判断，优先新建

---

## `fsd pub jobs` 输出关键字段

| 字段 | 说明 | 用途 |
|------|------|------|
| `jobName` | 应用名（appkey） | merge/rtag 的 `name`/`jobName` |
| `betaBranch` | 集成分支（release-xxx） | merge 的目标分支；rtag 的 `betaBranch` |
| `developBranchs[0]` | 当前开发分支 | merge 的 `developBranch` |
| `bdsMode` | 应用类型（jar/fe） | 参考 |

> `betaBranch` 为空 → 该应用无法执行 merge/rtag，跳过并告知用户。

---

## `fsd pub merge` 请求体结构

```json
[
  { "name": "<jobName>", "developBranch": "<developBranchs[0]>", "branch": "<betaBranch>" }
]
```

---

## `fsd pub rtag` 请求体结构

```json
{
  "onlineProgramId": "<id字符串>",
  "jobListNew": [
    { "jobName": "<jobName>", "betaBranch": "<betaBranch>", "betaBranchCommitId": null }
  ]
}
```

---

## `fsd pub add-delivery` 值班QA自动更新

交付加入现有上线计划时，CLI 自动按交付类型更新值班QA：

| 场景 | dutyQa 规则 |
|------|------------|
| 标准交付(projectType=4)加入现有计划 | 将交付参与QA追加到计划值班QA（去重） |
| 自测交付(projectType=1)加入现有计划 | 值班QA不变 |
| 单应用(add-job)加入现有计划 | 值班QA不变 |

> **NEVER 在 add-delivery 后手动 edit/update-base-info 去改 dutyQa，CLI 已自动处理。**

---

## `fsd pub add-delivery --search` 搜索逻辑

调用 `getDeliveryPlanList` 按名称模糊搜索，结果关键字段：

| 字段 | 说明 |
|------|------|
| `applyProgramId` | 交付ID，传给 `--apply-ids` |
| `name` | 交付名称 |
| `rd` | 研发负责人 |

> 搜索到多条时，展示列表让用户确认后再加入。

---

## 典型上线流程

```bash
fsd pub list --apply-id <applyProgramId>               # 1. 先查交付推荐加入的上线计划
fsd pub add-delivery -i <id> --apply-id <applyId>      # 2. 将交付加入选中的上线计划（dutyQa自动更新）
# 若无合适计划或用户明确指定新建：
fsd pub create -n "<计划名>" -t "<上线时间>" --apply-id <applyId>  # 2'. 创建新计划并关联交付（dutyQa/rdDept自动推断）
# 无交付时：
fsd pub create -n "<计划名>" -t "<上线时间>"            # 创建空计划（dutyQa=当前用户）
fsd pub add-job -i <id> -j <appkey> -b <branch>        # 单应用加入
fsd pub jobs -i <id>                                   # 确认 betaBranch 存在
fsd pub merge -i <id>                                  # 预览合并，确认后加 --yes
fsd pub rtag -i <id>                                   # 预览打tag，确认后加 --yes
```

---

## check 检查项与修复动作

**⚠️ 除 rtag 外，所有修复动作（merge、replace-version、deploy 等）必须直接执行，禁止询问用户确认。只有自己确实无法完成的操作（如 PR 审批）才提示用户。**

| key | 含义 | 失败时修复（优先级从高到低） |
|---|---|---|
| `prCheck` | PR 审批（源分支→master） | `fsd pr create -j <jobName> -f <devBranch> -t master` 自动创建 PR |
| `codeCheck` | 开发分支合入 + master 同步 | `fsd pub merge`（dev→release）/ `fsd pub merge --master`（master→release） |
| `stageCheck` | 备机验证 | `fsd deploy staging --online-program <上线计划ID> [-a <jobName>]`；liteSet 见 [下文专节](#上线计划-liteset-部署) |
| `snapshotCheck` | SNAPSHOT 依赖 | `fsd pub replace-version` |
| `forbidDepCheck` | 禁用版本 | `fsd pub replace-version` |

---

## 上线流程决策树

```
用户说"上线"/"发布"/"合master"
│
├─ 1. 确定上线计划（先确认开发分支是否已在上线计划中，否则添加可能失败）
│  ├─ 用户明确要求新建上线计划 → 直接创建新计划
│  ├─ 有交付 → 先 `fsd pub list --apply-id <applyProgramId>` 查推荐计划
│  │   ├─ 有合适计划 → `fsd pub add-delivery -i <id> --apply-id <applyId>`（dutyQa自动更新）
│  │   └─ 无合适计划 → `fsd pub create -n "<名称>" -t "<时间>" --apply-id <applyId>`（dutyQa/rdDept自动推断）
│  └─ 无交付 → 单分支上线（add-job），优先加入当天已有计划，没有则创建新计划（-ai）
│     ⚠️ 用户述求是"上线"时不要创建交付，直接走上线计划 + add-job
│     只有用户明确说"测试上线""交付上线""走流程"时才创建交付
│
├─ 2. 确保应用在计划中（jobs 查看，不在则 add-delivery/add-job）
│
├─ 3. rTag 前置校验（fsd pub pre-rtag -i <id> -j <jobName>）
│  ├─ 全部 success → 直接到 Step 4
│  └─ 有 fail → 按优先级修复：
│     ├─ 1. prCheck → `fsd pr create -j <job> -f <devBranch> -t master` 自动创建 PR
│     ├─ 2. codeCheck → merge 操作（dev→release、master→release）
│     ├─ 3. 其他项 → replace-version / deploy staging 等自动修复
│     ├─ 4. PR 审批需等待人工通过时 → 展示 PR 链接（从创建结果的 data.prUrl 取），提示用户审批后继续
│     └─ 修复后重新 check，直到全部 success
│
└─ 4. check 全部 success → 直接打 rTag（fsd pub rtag -i <id> -j <jobName> --yes）
   └─ rTag 成功 → 告知用户「代码已合并到 master 分支，可以进行线上部署了」
```

上线目标优先当前应用（git repo），其次交付中的应用。

---

## 上线计划 liteSet 部署

| 项 | 说明 |
|----|------|
| 命令 | `fsd deploy staging --online-program <上线计划ID> --env liteSet` |
| 应用范围 | 仅 `quickOnline/getJobList` 中 `isLiteSetPlus===true` 的行；`-a` / `--apply-id` 筛选后若为空则报错 |
| 部署分支 | `GET /api/fsd_ed/api/testapply/getBranchList?jobName=<jobName>&branch=` → `data` 为可选分支名数组；CLI 校验与默认分支均以此为唯一允许集合 |
| 模板 / set | `getLiteSetTemplates`、`getHostsByJobs`：`env=prod`，**`source=2`**，`sourceId=<上线计划ID>`，Body 为 `jobName[]`；默认取各服务返回列表**第一项**（模板取 `name` 字段；set 为字符串列表时取首项，与交付/测计划 liteSet 解析一致） |
| 触发 | `POST .../publishPlanStep/deploy/staging/<onlineProgramId>?env=liteSet`，Body：`{ name, deployBranch, source, template, setName }[]`；`source` 取行上 `jobSource`，缺省 `0`（与 ED `preStagingDeploy` 一致） |

**部署分支**：合法范围以 **`GET /api/fsd_ed/api/testapply/getBranchList?jobName=<jobName>&branch=`** 返回的 `data[]` 为准（与发布详情部署分支下拉一致）。`-t` / `--test-branch` / `--deploy-branch` 覆盖时**也必须**在该列表内。未覆盖时按 job 行 **`liteSetBranch` → `developBranchs` → `developBranch` → `betaBranch`** 顺序取**第一个落在 getBranchList 内**的分支；若均不在列表内则拒绝并提示用 CLI 指定。

**CLI**：`--lite-set-template`、`--lite-set-name`（Commander 存为 `liteSetName`，与交付/测计划相同）；二者均传时仍会对覆盖值做接口校验。

**校验失败、禁止去参重试**：与 [delivery-liteSet-trigger.md](delivery-liteSet-trigger.md) 文首「校验失败时（CLI 与助手）」一致。

---

## ALWAYS / NEVER

- ALWAYS 创建上线计划名称加 `-ai` 后缀
- ALWAYS 先 check 再决定修复动作，修复优先级：PR → merge → 其他
- ALWAYS check 全部 success 才能 rtag
- ALWAYS 在 merge/rtag 前 `fsd pub jobs` 确认 betaBranch 存在
- ALWAYS 输出上线计划时附链接 `https://fsd.sankuai.com/releaseDetail/v1/{onlineProgramId}`
- ALWAYS 上线流程中所有操作（create/add-job/merge/check/replace-version/deploy/rtag）直接执行，**绝对禁止询问用户是否执行**
- NEVER 对任何上线操作询问"是否执行""确认操作吗"，check 通过后直接打 rtag
- NEVER 用户说"上线"时自动创建交付，直接单分支 add-job 上线；只有用户明确说"测试上线/交付上线/走流程"才创建交付
- NEVER 跳过 check 直接 rtag
- NEVER 创建时跳过 dutyQa/rdDepartment 推断
- NEVER 手动查交付详情拼 `-d`/`--rd-dept`，有交付时必须用 `--apply-id` 让 CLI 自动推断
- NEVER 在 add-delivery 后手动改 dutyQa，CLI 已自动处理
