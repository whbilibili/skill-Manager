# 缺陷管理参考手册

> 所有操作遵循 SKILL.md 核心规则。

## 目录
- [能力范围](#能力范围)
- [CLI 命令](#cli-命令)
- [请求体结构](#请求体结构)
- [criteriaListByOr 说明](#criterialistbyor-说明)
- [criteria 拼装流程（AI 必读）](#criteria-拼装流程ai-必读)
- [返回字段映射](#返回字段映射)
- [使用示例](#使用示例)

---

## 能力范围

当前已实现：

- `fsd defect list -p <planId>`：按**测试计划维度**查询缺陷列表
  - 接口：`POST https://teammetric.sankuai.com/api/defect/getDefectList`
  - 固定 `sourceType=fsd_plan`
  - `planId` 为**测试计划 ID**
  - 关注返回 `data.total` 与 `data.list`
  - `data.users` 暂不做业务处理

- `fsd defect list --iteration <id>`：按 **FSD 迭代详情页**查询缺陷列表（与上**不是同一路径**）
  - 接口：`POST https://fsd.sankuai.com/api/fsd_team/api/defect/getDefectList`
  - 固定 `sourceType=fsd_iteration_detail`
  - `planId` 请求体字段填**迭代 ID**（与 URL `/fsdIteration/detail/{id}` 一致）
  - 认证走 FSD 域名，与 `fsd sso login` 一致

详见下文 [迭代详情页 vs 测试计划](#sec-defect-iteration-detail)。

---

## CLI 命令

```bash
# 查询筛选条件空间（可选，字段定义见本文件速查表）
fsd defect fields [--pretty]

# 查询缺陷列表（二选一）
fsd defect list -p <testPlanId> [--page-size 15] [--page-num 1] [--order-by "createdAt desc"] [--criteria '<json>'] [--project-id <id>] [--pretty]

fsd defect list --iteration <iterationId> [--page-size 15] [--page-num 1] [--order-by "createdAt desc"] [--criteria '<json>'] [--project-id <id>] [--pretty]
```

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `-p, --plan-id` | string | 与 `--iteration` 二选一 | 测试计划 ID，对应请求体 `planId`（`sourceType=fsd_plan`） |
| `--iteration` | string | 与 `-p` 二选一 | 迭代详情页 ID，同 `/fsdIteration/detail/{id}`（`sourceType=fsd_iteration_detail`） |
| `--page-size` | string | 否 | (默认值: `15`) 分页大小，对应 `pageSize` |
| `--page-num` | string | 否 | (默认值: `1`) 页码，对应 `pageNum` |
| `--order-by` | string | 否 | (默认值: `createdAt desc`) 排序字段，对应 `orderByClause` |
| `--criteria` | string | 否 | (默认值: `-`) 直接传 `criteriaListByOr` 的 JSON（数组或对象），AI 按需拼装（含 issueid 等） |
| `--project-id` | string | 否 | 透传 `projectId`：`-p` 时未传为 `null`；`--iteration` 时未传为 `""` |
| `--pretty` | string | 否 | (默认值: `false`) 人类可读输出（默认输出完整 JSON） |
| `-v, --verbose` | string | 否 | (默认值: `false`) 强制输出完整 JSON |

`fsd defect fields` 参数：

| 参数 | 说明 |
|------|------|
| `--pretty` | 人类可读格式，列出所有字段名、枚举值及 key 映射 |

限制（`fsd defect list`）：

- `criteriaListByOr` 长度只能为 `1`
- **禁止**同时传 `-p` 与 `--iteration`

---

<a id="sec-defect-iteration-detail"></a>

## 迭代详情页缺陷列表（fsd_iteration_detail）

用户从 **`https://fsd.sankuai.com/fsdIteration/detail/{iterationId}`**（含带 `shareIterationDetail`、`activeTab=defect` 等 query）进入时，前端调用 FSD 域名下的 `getDefectList`，**不是** teammetric 上 `fsd_plan` 那条链。

### 与测试计划列表的差异

| 维度 | 测试计划 `fsd defect list -p` | 迭代详情 `fsd defect list --iteration` |
|------|-------------------------------|----------------------------------------|
| 域名 | teammetric.sankuai.com | fsd.sankuai.com |
| 路径 | `/api/defect/getDefectList` | `/api/fsd_team/api/defect/getDefectList` |
| `sourceType` | `fsd_plan` | `fsd_iteration_detail` |
| `planId` 含义 | **测试计划 ID** | **迭代 ID**（与 URL 路径一致） |
| `projectId` | 默认 `null` | 默认 `""`（空字符串，与前端一致） |

### 助手路由（个性化）

- 用户粘贴 **`/fsdIteration/detail/<数字>`** 且要看缺陷列表 → **`fsd defect list --iteration <数字> --pretty`**，**不要**把路径中的数字当成测试计划 ID 去用 `-p`。
- 用户粘贴 **`/test/detail?testPlanId=`** → 测计划语境，缺陷列表用 **`-p <testPlanId>`**。
- 「迭代」一词本身不区分上述两种 ID；**以链接路径与 query 为准**，与 [delivery.md · 迭代与 FSD 链接](delivery.md#sec-iteration-fsd-url) 一致。

---

## 请求体结构

### 测试计划维度（teammetric）

接口：

- `POST https://teammetric.sankuai.com/api/defect/getDefectList`

标准请求体：

```json
{
  "criteriaListByOr": [{ "criterionListByAnd": [] }],
  "pageSize": 15,
  "pageNum": 1,
  "returnMockedResponse": false,
  "projectId": null,
  "orderByClause": "createdAt desc",
  "sourceType": "fsd_plan",
  "planId": "72359"
}
```

### 迭代详情页维度（FSD）

接口：

- `POST https://fsd.sankuai.com/api/fsd_team/api/defect/getDefectList`

示例请求体（与前端一致）：

```json
{
  "criteriaListByOr": [{ "criterionListByAnd": [] }],
  "pageSize": 15,
  "pageNum": 1,
  "returnMockedResponse": false,
  "projectId": "",
  "orderByClause": "createdAt desc",
  "sourceType": "fsd_iteration_detail",
  "planId": 39205
}
```

---

## criteriaListByOr 说明

`criteriaListByOr` 结构（长度固定最多 1）：

```json
[
  {
    "criterionListByAnd": [
      {
        "fieldName": "issueid",
        "operator": "in",
        "specifiedValue": "93936671"
      }
    ]
  }
]
```

按缺陷 ID 时，AI 在 `--criteria` 中拼装 `fieldName=issueid` 条件即可。

---

---

## criteria 拼装流程（AI 必读）

当用户描述筛选条件时，**必须先调用 `fsd defect fields` 获取实时字段定义**，再按以下规则组装 `--criteria`，禁止凭记忆硬编码枚举 key。

### 第一步：获取最新筛选条件空间

```bash
fsd defect fields
```

接口返回实时数据，枚举值可能随时变化（如新增标签、终端类型等），**优先使用接口返回值**。  
若接口鉴权失败，fallback 到本文件「可用筛选字段速查表」章节。

接口返回字段数组，每个字段含：

| 字段 | 用途 |
|------|------|
| `fieldCode` | criterion 里的 `fieldName`（API 字段名） |
| `fieldName` | 用户看到的中文名（用于匹配用户描述） |
| `isMultiple` | `1`=多选，`0`=单选 |
| `defaultFilterOption` | 默认 operator（`in` / `equalTo` / `between` 等） |
| `filterValues` | 该字段支持的 operator 列表（有则参考，无则用 default） |
| `realityValues` | 枚举值列表，**每项 `key` 是传给接口的真实值，`value` 是显示名** |

### 第二步：逐条映射用户描述 → criterion 对象

每个筛选条件对应一个 criterion 对象：

```json
{
  "fieldName": "<fieldCode>",
  "operator": "<operator>",
  "specifiedValue": "<value1,value2>"
}
```

**规则 1：`fieldName` 取 `fieldCode`**

用用户描述的中文名在 `fieldName` 列匹配，取对应的 `fieldCode`。

```
用户说"状态"      → fieldCode: "state"
用户说"终端类型"  → fieldCode: "customTerminalType"
用户说"标签"      → fieldCode: "customLabel"
用户说"卡点状态"  → fieldCode: "isCard"
用户说"跳过状态"  → fieldCode: "isSkip"
```

**规则 2：`specifiedValue` 必须用 `realityValues[].key`，不能用 `value`（显示名）**

从 `realityValues` 里找用户描述的枚举项，取其 `key`，多个值用英文逗号拼接。

```
用户说"高危场景"   → realityValues 里 value="高危场景" 的 key="92468"   → specifiedValue: "92468"
用户说"全息发现"   → realityValues 里 value="全息发现" 的 key="92428"   → specifiedValue: "92428"
用户说"重新打开"   → realityValues 里 value="重新打开" 的 key="重新打开" → specifiedValue: "重新打开"
多个值合并         → specifiedValue: "92468,92428"
```

> 注意：部分字段（如 `state`）的 key 与 value 相同，此时直接用即可。  
> 部分字段（如 `customLabel`）的 key 是数字 ID，**必须用 key，不能用中文显示名**。

**规则 3：`operator` 的选择**

| 场景 | operator |
|------|----------|
| `isMultiple=1`，用户无特殊说明 | 使用 `defaultFilterOption`（通常是 `in`） |
| `isMultiple=0` | 使用 `defaultFilterOption`（通常是 `equalTo`） |
| 用户说"不包含 X" | 用 `notIn`（前提：该字段 `filterValues` 含 `notIn`） |
| 用户说"包含 X" | 用 `in` |

```
state（isMultiple=1）  + "状态是重新打开或已处理"  → operator: "in"
isCard（isMultiple=0） + "卡点状态是"             → operator: "equalTo"
customTerminalType     + "终端类型不包含 MRN,iOS" → operator: "notIn"
```

**规则 4：所有条件（哪怕只有 1 个）必须放入 `criterionListByAnd` 数组**

> ⚠️ **高频错误**：即使只有一个筛选条件，也**必须**包裹在 `criterionListByAnd` 里，不能直接把 criterion 对象放到外层数组。

❌ 错误示例（单条件时直接放到外层）：
```json
[{"fieldName":"customLabel","operator":"in","specifiedValue":"91785"}]
```

✅ 正确示例（单条件也必须有 `criterionListByAnd` 层）：
```json
[{"criterionListByAnd":[{"fieldName":"customLabel","operator":"in","specifiedValue":"91785"}]}]
```

多条件示例（AND 关系放同一个 `criterionListByAnd`）：
```json
{
  "criterionListByAnd": [
    { "fieldName": "state",              "operator": "in",      "specifiedValue": "重新打开,已处理" },
    { "fieldName": "isCard",             "operator": "equalTo", "specifiedValue": "是" },
    { "fieldName": "customTerminalType", "operator": "notIn",   "specifiedValue": "MRN,iOS" },
    { "fieldName": "customLabel",        "operator": "in",      "specifiedValue": "92468,92428" }
  ]
}
```

**规则 5：`criteriaListByOr` 长度只能为 1**

将上面的对象包装成数组传入 `--criteria`：

```json
[{"criterionListByAnd": [...]}]
```

**规则 6：`specifiedValue` 必须是纯字符串，多值用英文逗号拼接，禁止使用 JSON 数组格式**

> ⚠️ **高频错误**：`specifiedValue` 不是 JSON 数组，不能写成 `"[91785]"` 或 `["91785"]`。

❌ 错误示例：
```json
{ "fieldName": "customLabel", "operator": "in", "specifiedValue": "[91785]" }
```

✅ 正确示例（单值）：
```json
{ "fieldName": "customLabel", "operator": "in", "specifiedValue": "91785" }
```

✅ 正确示例（多值逗号拼接）：
```json
{ "fieldName": "customLabel", "operator": "in", "specifiedValue": "91785,91784" }
```

### 第三步：调用 defect list

```bash
fsd defect list -p <planId> --criteria '<上一步组装的 JSON>'
```

### 可用筛选字段速查表（fallback）

> 仅在 `fsd defect fields` 接口不可用时使用，数据可能与线上存在偏差。  
> 规则：`specifiedValue` 始终用 `key` 列的值；多值用英文逗号拼接；`isMultiple=0` 用 `equalTo`，`isMultiple=1` 用 `in`（"不包含"用 `notIn`）。

#### 状态（fieldCode: `state`，isMultiple=1，operator: `in`/`notIn`）

key=value，直接使用中文值：`未开始` / `处理中` / `已处理` / `重新打开` / `已关闭` / `打开` / `无效缺陷` / `待处理` / `待验收` / `暂不解决` / `延期解决` / `不是缺陷` / `不需修复` / `已修复` / `已合入` / `已分发` / `已解决` / `已完成` / `转化为新需求` / `关闭` / `开发中` / `规划中` / `继续处理` / `后续优化` 等

#### 优先级（fieldCode: `priority`，isMultiple=1，operator: `in`/`notIn`）

| key | 显示名 |
|-----|--------|
| `4` | 紧急 |
| `3` | 高 |
| `2` | 中 |
| `1` | 低 |

#### 严重程度（fieldCode: `severity`，isMultiple=1，operator: `in`/`notIn`）

| key | 显示名 |
|-----|--------|
| `0` | BLOCKER |
| `1` | CRITICAL |
| `2` | MAJOR |
| `3` | NORMAL |
| `4` | TRIVIAL |

#### 卡点状态（fieldCode: `isCard`，isMultiple=0，operator: `equalTo`）

key=value：`是` / `否`

#### 标签（fieldCode: `customLabel`，isMultiple=1，operator: `in`/`notIn`）

⚠️ key 是数字 ID，specifiedValue **必须用 key**，不能用中文名：

| key | 标签名 |
|-----|--------|
| `92705` | 联测阶段发现 |
| `92468` | 高危场景 |
| `92428` | 全息发现 |
| `92426` | 涉及商诉风险 |
| `92419` | 涉及资损风险 |
| `92418` | 涉及S9+风险 |
| `92347` | 涉及客诉风险 |
| `92152` | PHF-资损测试发现 |
| `91963` | PHF-异常测试发现 |
| `91786` | 性能体验 |
| `91770` | 新增功能缺陷 |
| `91769` | 历史功能缺陷 |
| `91768` | 存量自动化用例 |
| `91767` | 新增自动化用例 |
| `91559` | 用例可发现 |
| `91424` | 涉及资损 |
| `91297` | 资损自动化发现 |
| `90216` | 典型缺陷 |
| `89212` | 长链路需求缺陷 |
| `88907` | 冒烟用例发现 |
| `88824` | RD自测 |
| `86729` | 算法缺陷 |
| `86419` | 核心场景回归 |
| `86396` | AICC覆盖率发现 |
| `86327` | 代码可视化houyi系统发现 |
| `85926` | 测试范围评估不全 |
| `84276` | 回归缺陷 |
| `80571` | 流量数据发现 |
| `74364` | 流量用例发现 |
| `74363` | 工程用例发现 |

#### 其余筛选字段（枚举请用 CLI 获取）

- `fieldCode: isSkip`, `isMultiple=0`, `operator: equalTo` — 完整枚举通过 `fsd defect fields` 获取
- `fieldCode: customIsDeclineOnline`, `isMultiple=0`, `operator: equalTo` — 完整枚举通过 `fsd defect fields` 获取
- `fieldCode: customTerminalType`, `isMultiple=1`, `operator: in`/`notIn` — 完整枚举通过 `fsd defect fields` 获取
- `fieldCode: defectType`, `isMultiple=1`, `operator: in`/`notIn` — 完整枚举通过 `fsd defect fields` 获取
- `fieldCode: customFindWay`, `isMultiple=1`, `operator: in`/`notIn` — 完整枚举通过 `fsd defect fields` 获取
- `fieldCode: customFindStep`, `isMultiple=1`, `operator: in`/`notIn` — 完整枚举通过 `fsd defect fields` 获取
- `fieldCode: serverEndpointDiscoveryPhase`, `isMultiple=1`, `operator: in`/`notIn` — 完整枚举通过 `fsd defect fields` 获取
- `fieldCode: clientEndpointDiscoveryPhase`, `isMultiple=1`, `operator: in`/`notIn` — 完整枚举通过 `fsd defect fields` 获取
- `fieldCode: platformTool`, `isMultiple=1`, `operator: in`/`notIn` — 完整枚举通过 `fsd defect fields` 获取
- `fieldCode: customConclusion`, `isMultiple=1`, `operator: in`/`notIn` — 完整枚举通过 `fsd defect fields` 获取
- `fieldCode: customBugReason`, `isMultiple=1`, `operator: in`/`notIn` — 完整枚举通过 `fsd defect fields` 获取

#### 其他字段

| fieldCode | 中文名 | isMultiple | operator | 备注 |
|-----------|--------|------------|----------|------|
| `assigned` | 负责人 | 1 | `in`/`notIn` | 传 MIS 账号 |
| `createdBy` | 创建者 | 1 | `in`/`notIn` | 传 MIS 账号 |
| `issueid` | ID | 0 | `in`/`notIn` | 缺陷 ID |
| `issuename` | 标题 | 0 | `like` | 模糊匹配 |
| `createdAt` | 创建时间 | 1 | `between` | 时间区间 |
| `parentId` | 父需求 | 1 | `in` | 需求 ID |

---

### 常见错误提示

| 错误 | 原因 | 修复 |
|------|------|------|
| 接口返回空列表但预期有数据 | `specifiedValue` 用了显示名而非 key | 重新用 `fsd defect fields` 确认 key 值 |
| 接口报错 operator 不合法 | 单选字段误用了 `in` | `isMultiple=0` 的字段改用 `equalTo` |
| 标签筛选无结果 | 用了标签名文字而非数字 ID | `customLabel` 的 specifiedValue 必须是 key（数字） |
| 筛选条件结构解析失败 / 无效 | 直接把 criterion 对象放到了外层数组，缺少 `criterionListByAnd` 包裹 | 格式必须为 `[{"criterionListByAnd":[...]}]`，即使只有 1 条条件也一样 |
| `specifiedValue` 传了 `"[91785]"` 或 `["91785"]` | 误用了 JSON 数组格式 | 改为纯字符串，多值用英文逗号：`"91785"` / `"91785,91784"` |

---

## 返回字段映射

只关注 `data.total` 与 `data.list`：

| 字段 | 说明 |
|------|------|
| `data.total` | 缺陷总数 |
| `data.list[]` | 缺陷列表 |

**常用字段**（`data.list[]`，AI 交互优先）：

| 字段 | 示例值 | 说明 |
|------|--------|------|
| `issueId` | `93936671` | ONES 缺陷 ID |
| `issueName` | `测试技能-tfh-少一些信息` | 缺陷标题 |
| `assigned` | `tianfeihan` | 当前处理人 MIS |
| `createdBy` | `tianfeihan` | 创建人 MIS |
| `priority` | `中` | 优先级 |
| `state` | `未开始` | 缺陷状态 |
| `severity` | `NORMAL` | 严重程度（枚举值） |
| `defectType` | `服务端缺陷` | 缺陷类型 |
| `customLabel` | `86856,94184` | 标签 ID 列表，逗号分隔 |
| `isCard` | `null` | 是否卡点缺陷 |

**其他字段**：完整字段以接口返回为准，另含 `id`、`createdAt`、`cc`、`customLabelVo`、`customFindStep`、`customFindWay`、`customConclusion`、`customBugReason`、`customTerminalType`、`defectDetailUrl`、`parentId`、`relatedReq`、`projectId`、`belongProject`、`platformTool`、`clientEndpointDiscoveryPhase`、`serverEndpointDiscoveryPhase` 等。

`customLabelVo` 为标签对象数组，每项含 `id`（标签 ID）、`name`（名称）、`color`（颜色 HEX）。

说明：

- `data.users` 当前不参与 CLI 展示逻辑
- 字段中的 `--` 通常表示「未填写/不适用」
- 时间耗时字段当前多为 `null`，建议按「可空数字字段」处理

---

## 使用示例

> 说明：当用户表述为「查缺陷 / 缺陷列表 / 看下有哪些 bug / 缺陷数量」等，路由到 `fsd defect` 命令组执行。

---

## 示例D1：最简查询（只有测试计划 ID）

**用户**: "查下测试计划 72557 的缺陷列表"

**执行**：
```bash
fsd defect list -p 72557
```

---

## 示例D2：人类可读输出（展示给用户看）

**用户**: "帮我看下测试计划 72557 的缺陷，详细展示一下"

**执行**：
```bash
fsd defect list -p 72557 --pretty
```

---

## 示例D3：按缺陷 ID 查询（AI 拼装 criteria）

**用户**: "查下测试计划 72557 里 ID 为 93936671 的缺陷"

**执行**：
```bash
fsd defect list -p 72557 --criteria '[{"criterionListByAnd":[{"fieldName":"issueid","operator":"in","specifiedValue":"93936671"}]}]'
```

多个 ID 逗号分隔：
```bash
fsd defect list -p 72557 --criteria '[{"criterionListByAnd":[{"fieldName":"issueid","operator":"in","specifiedValue":"93936671,93936672"}]}]'
```

---

## 示例D4：按标签筛选缺陷（单标签）— 易错示例

**用户**: "查测试计划 72557 中标签为「情感体验」的缺陷"

**第一步：调用 fields 获取实时字段定义，确认 customLabel 的 key**
```bash
fsd defect fields
```
从返回的 `realityValues` 中找到 `value="情感体验"` 对应的 `key`，假设为 `91785`。

**第二步：组装 --criteria 并查询**
```bash
fsd defect list -p 72557 --criteria '[{"criterionListByAnd":[{"fieldName":"customLabel","operator":"in","specifiedValue":"91785"}]}]' --pretty
```

> ⚠️ **注意**：
> - `specifiedValue` 必须是纯字符串 `"91785"`，不能写成 `"[91785]"`
> - 即使只有一个条件，也必须有 `criterionListByAnd` 层，不能直接写 `[{"fieldName":"customLabel",...}]`

---

## 示例D5：多标签（逗号拼接 key）

多标签：`specifiedValue` 用英文逗号拼接多个 key（先 `fsd defect fields` 查 key，同 D4）。

```bash
fsd defect list -p 72557 --criteria '[{"criterionListByAnd":[{"fieldName":"customLabel","operator":"in","specifiedValue":"91785,91786"}]}]' --pretty
```

---

## 示例D6：按缺陷状态筛选

```bash
fsd defect list -p 72557 --criteria '[{"criterionListByAnd":[{"fieldName":"state","operator":"in","specifiedValue":"重新打开,已处理"}]}]' --pretty
```

注：`state` 的 key 与显示名相同，直接用中文。

---

## 示例D7：按优先级筛选

```bash
fsd defect list -p 72557 --criteria '[{"criterionListByAnd":[{"fieldName":"priority","operator":"in","specifiedValue":"3,4"}]}]' --pretty
```

注：优先级 key 为 `4` 紧急、`3` 高、`2` 中、`1` 低。

---

## 示例D8：卡点状态（单选用 equalTo）

```bash
fsd defect list -p 72557 --criteria '[{"criterionListByAnd":[{"fieldName":"isCard","operator":"equalTo","specifiedValue":"是"}]}]' --pretty
```

注：`isMultiple=0` 须用 `equalTo`，勿用 `in`。

---

## 示例D9：多条件组合筛选（AND 关系）

**用户**: "查测试计划 72557 中，状态是「重新打开」、终端类型不包含 MRN 和 iOS、标签包含「高危场景」的缺陷"

**第一步：获取字段定义**
```bash
fsd defect fields
```
确认 `value="高危场景"` → `key="92468"`

**第二步：多条件放入同一个 `criterionListByAnd`**
```bash
fsd defect list -p 72557 --criteria '[{"criterionListByAnd":[{"fieldName":"state","operator":"in","specifiedValue":"重新打开"},{"fieldName":"customTerminalType","operator":"notIn","specifiedValue":"MRN,iOS"},{"fieldName":"customLabel","operator":"in","specifiedValue":"92468"}]}]' --pretty
```

---

## 示例D10：缺陷类型 / 发现方式（`defectType` / `customFindWay`）

枚举值以 `fsd defect fields` 为准；`fieldName` 分别为 `defectType`、`customFindWay`，多选用 `in`。

```bash
fsd defect list -p 72557 --criteria '[{"criterionListByAnd":[{"fieldName":"defectType","operator":"in","specifiedValue":"服务端缺陷"}]}]' --pretty
fsd defect list -p 72557 --criteria '[{"criterionListByAnd":[{"fieldName":"customFindWay","operator":"in","specifiedValue":"自动化测试"}]}]' --pretty
```

---

## 示例D11：分页

```bash
fsd defect list -p 72557 --page-size 20 --page-num 2 --pretty
```

---

## 示例D12：缺陷总数

```bash
fsd defect list -p 72557 --page-size 1
```

注：解析 JSON 的 `data.total`，无需拉全量列表。

---

## 示例D13：可用筛选字段

```bash
fsd defect fields --pretty
```

---

## 示例D14：不确定枚举 key

与 D4：先 `fsd defect fields` 在 `realityValues` 查 key，再拼 `--criteria` 调用 `fsd defect list`。

---

## --criteria 格式速查

```
正确格式（单条件）：
'[{"criterionListByAnd":[{"fieldName":"XXX","operator":"in","specifiedValue":"val"}]}]'

正确格式（多条件 AND）：
'[{"criterionListByAnd":[{"fieldName":"A","operator":"in","specifiedValue":"v1"},{"fieldName":"B","operator":"equalTo","specifiedValue":"v2"}]}]'

❌ 错误：缺少 criterionListByAnd 层
'[{"fieldName":"customLabel","operator":"in","specifiedValue":"91785"}]'

❌ 错误：specifiedValue 使用了 JSON 数组
'[{"criterionListByAnd":[{"fieldName":"customLabel","operator":"in","specifiedValue":"[91785]"}]}]'
```

完整场景示例见上文「使用示例」（D4–D14）。
