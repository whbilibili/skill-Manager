# 测试计划 FST 参考手册

本文仅 `fsd fstPlan`（list / bind / unbind / skip / trigger）。

| 若须判断 … | 打开 |
| ---------- | ---- |
| 计划 ID 来源与确认（`finish` / `delete` / `trigger` 同规） | [test-plan · ID 策略](test-plan.md#test-plan-id-policy) |
| 整单准出顺序、fstPlan 与其他卡点、何时可 `finish` | [test-plan · 准出工作流](test-plan.md#sec-gate-workflow) |

其余遵循 SKILL.md 核心规则。上表第一行的计划 ID 门禁**优先于** SKILL 泛化的「直接执行无需确认」（须先问用户时不得省略）。

## fstPlan list

| CLI      | 说明                                                                 |
| -------- | -------------------------------------------------------------------- |
| -i, --id | 测试计划 ID                                                          |
| --pretty | 可选；人类可读并输出绑定记录 **id**，供 `unbind --bind-ids` 使用 |

## fstPlan bind

| CLI                    | 说明                                                                 |
| ---------------------- | -------------------------------------------------------------------- |
| -i, --id               | 必填，测试计划 ID                                                    |
| --plan-ids / --payload | 二选一；`--payload` 须含 `applyWithFstVo`；仅 `planId` 时 CLI 自动补全 |
| --pretty               | 可选                                                                 |

### 决策树

```
用户要将 FST 计划绑定到测试计划上（fstPlan bind）
├─ 已给测试计划 ID + FST planId
│   └─ `fsd fstPlan bind -i <id> --plan-ids <fst-ids> [--pretty]`
└─ 未给测试计划 ID
    └─ 先让用户提供测试计划 ID；不得直接执行绑定
```

## fstPlan unbind

| CLI                     | 说明                                                                 |
| ----------------------- | -------------------------------------------------------------------- |
| -i, --id                | 必填，测试计划 ID                                                    |
| --plan-ids / --bind-ids | 二选一；`bind-ids`→`ids`（**apply_with_fst 主键**，非 FST planId）。`GET /api/qa/v1/fst/unbindFst`，`businessId`=计划，`source=testPlan`；系统推荐绑定由 CLI 预剔除 |
| -r                      | reason                                                               |

## fstPlan skip

| CLI        | 说明    |
| ---------- | ------- |
| -i, --id   | 必填    |
| --plan-ids | 可选    |
| -m         | 原因，可选 |

---

<a id="sec-fst-trigger"></a>

## fstPlan trigger

| CLI        | 说明                             |
| ---------- | -------------------------------- |
| -i, --id   | 必填，测试计划 ID                |
| --plan-ids | 可选，FST planId 列表            |
| --ips      | 可选，needMachine 且无历史 IP 时 |
| --pretty   | 可选                             |

<a id="fst-trigger-gate"></a><a id="fst-trigger-bad-example"></a>

### 计划 ID 约束（同 [test-plan · ID 策略](test-plan.md#test-plan-id-policy)；触发前须满足）

- `fstPlan trigger`：计划 ID 须来自**本条消息中的数字**，或**上下文唯一 ID 且用户已确认**；禁止臆测、禁止用 `test list` 排序代替选定。
- `test finish` / `test delete` 同则；`delete` 上下文不清时优先让用户本条显式写 ID。
- **误触：** 无 ID、无确认仍填 `-i`；同轮 `test list` 多候选后立即对第一条 `trigger`。

<a id="sec-fst-trigger-dt"></a>

### 决策树

```
用户要跑计划内 FST（fstPlan trigger）
├─ 已提供测试计划 ID（本条 user 消息含数字 ID）
│   └─ fsd fstPlan trigger -i <id> [--plan-ids] [--ips] [--pretty]
└─ 未提供测试计划 ID（本条无数字 ID）
    ├─ 上下文唯一计划 ID → 询问确认后再 trigger（确认前本轮不执行）
    └─ 无法唯一确定 → 请用户提供 ID；可 `fsd test list --pretty` 辅助；禁止同轮 list 后默认第一条 trigger
```

---

---

<a id="sec-fst-stop"></a>

## fstPlan stop（终止单次 FST 执行）

与交付侧 **`fsd delivery fst stop`** 调用同一接口 **`GET /api/FST/fst/fstPlan/stopPlan`**（`fstPlanId` + `fstRecordId`）。后端与 skill-dev `ApplyFstService#stopPlan` 一致。

```bash
fsd fstPlan stop -i <testPlanId> --plan-id <FST planId> --execute-id <fstExecuteId> [--pretty]
```

| CLI | 说明 |
| --- | --- |
| -i, --id | 必填，测试计划 ID；用于校验 `--plan-id` 已绑定本计划（`queryFst` source=testPlan） |
| --plan-id | 必填，FST 计划 ID（planId） |
| --execute-id | 必填，**单次执行记录 ID** = 接口参数 **`fstRecordId`** = **`queryFstDetail` 行内 `fstExecuteId`** = 提测/计划详情页报告 URL 的 **`fstExecuteId`** |
| --pretty | 可选，一行成功摘要 |

**与 `fstPlan skip` 区别：** `stop` 用于**执行中**终止当前跑批；`skip` 用于准出上**跳过已结束但未通过的 FST 卡点**。交付侧参数说明与对比表见 [delivery.md](delivery.md)「delivery fst」章节。

**助手路由：** 用户说「终止/停掉/不要跑了」须先区分对象——**环境部署 / 整条测试流水线**（非 FST）且已有明确 **`eventId`** → **`test stop-pipeline --id <计划ID> -e <eventId>`**；**撤销环境部署记录行**（页面「撤销」、有 **`recordDetailId`**）→ **`test revoke-deploy`**；**测试计划上的 FST 自动化** → `fstPlan stop`；**交付 ED 卡片上的自动化** → `delivery fst stop`。

---

<a id="sec-fst-retry"></a>

## fstPlan retry（重试 FST）

**`POST /api/qa/v1/fst/retryFstPlan`**，body：`{ retryVo: [{ planId, fstExecuteId }, ...] }`，与交付侧 **`fsd delivery fst retry`**、前端 `fsd-common-auto` 一致。

| 参数来源 | 字段 |
|----------|------|
| **`queryFst`**（`source=testPlan`） | **`planId`** |
| **`queryFstDetail`** 列表行 | **`fstExecuteId`**（须已执行过，未执行时后端会报错） |

```bash
fsd fstPlan retry -i <testPlanId> --plan-id <planId> --execute-id <fstExecuteId> [--pretty]
fsd fstPlan retry -i <testPlanId> --items "19887:2708362,19888:2708400"
fsd fstPlan retry -i <testPlanId> --payload '{"retryVo":[{"planId":19887,"fstExecuteId":2708362}]}'
```

**与 `fstPlan trigger`：** `trigger` 为首次/再次整批触发；`retry` 针对**已有执行记录**按条重试，**必须**提供 **`fstExecuteId`**。

**助手路由：** 用户说「重试自动化 / 再跑一遍失败的 FST」且为测试计划上下文 → `fstPlan retry`；交付提测详情上的自动化 → `delivery fst retry`。

---

## 使用示例

```bash
fsd fstPlan list -i 71399 --pretty
fsd fstPlan bind -i 71399 --plan-ids 63950 --pretty
fsd fstPlan unbind -i 71399 --plan-ids 63950 -r "误绑" --pretty
fsd fstPlan trigger -i 71399 --pretty
fsd fstPlan skip -i 71399 -m "已知风险可放行" --pretty
fsd fstPlan stop -i 71399 --plan-id 19887 --execute-id 2708223 --pretty
fsd fstPlan retry -i 71399 --plan-id 19887 --execute-id 2708362 --pretty
```
