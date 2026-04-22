> **说明**：Step 2 采用 **A+B 双轨制**——内置控件速查表覆盖常见场景（零依赖）；遇到复杂控件时自动安装 [kuaida-submit](https://friday.sankuai.com/skills/skill-detail?id=3060) skill 并引用其完整格式规范。详见 Step 2。

---

## IRON LAW

**⛔ 禁止在未获得用户「确认」前调用 `updateRecord`**
**⛔ 禁止跳过 Step 1.5（显隐检测）——即使用户未修改任何字段**
**⛔ `--billData` 必须包含所有字段（含未修改项），不能只传改动字段**

---

## Anti-Pattern

| #    | 禁止行为                                   | 正确做法                                          |
| ---- | ------------------------------------------ | ------------------------------------------------- |
| AP-0 | 未获取用户提供的详情链接就尝试查找记录     | 快搭表单无法从审批列表反查，必须先追问链接        |
| AP-1 | 未调用 `getRecordInfo` 就直接构建 billData | Step 1 先通过 recordId 获取当前表单数据和 schema  |
| AP-2 | 跳过显隐检测直接构建 billData              | 每次用户修改字段后必须做显隐检测                  |
| AP-3 | `--billData` 只包含修改字段                | 必须传入完整 billData（含未改动字段）             |
| AP-4 | 将 people/department 字段传为字符串        | 人员和部门控件必须传对象结构                      |
| AP-5 | 未等用户确认就执行更新                     | Step 3 预览后等待「确认」「是」「好」等明确肯定词 |
| AP-6 | 必填字段原值为空就直接传空                 | 必须提醒用户补充，不得静默跳过                    |
| AP-7 | 未检查 permissions 就直接构建 billData     | Step 1 获取数据后立即检查 permissions 含 UPDATE   |

---

### 查询记录详情接口 `getRecordInfo` 返回结构说明

```
{
  billDataList,    // 格式化后的字段列表 [{key, label, value}]，直接展示给用户
  formSchema,      // 原始表单 schema（JSON 字符串），供解析显隐规则和 Select/SelectDD 可选值
  bpmCode,         // 作为 updateRecord 的 --bpmCode
  formCode,        // 作为 updateRecord 的 --formCode
  formVersion,     // 作为 updateRecord 的 --formVersion
  permissions,     // 用户权限数组，如 ["QUERY", "UPDATE", "DELETE"]
}
```

## Step 1 · 获取记录详情

> ⚠️ **重要区分**：`recordId` 是快搭表单记录 ID，从用户提供的记录详情链接中获取 `?recordId=`；**不是**审批流的 `procInstId` 或 `billId`

**入口条件**：收到「修改记录」「把 XX 改成 YY」「更新表单内容」等触发词

- **若用户未提供快搭详情链接，必须先追问，不得向下推进：**
  ```
  请提供该记录的详情页链接（格式：https://kuaida.sankuai.com/app-xxx/detail?recordId=<recordId>）
  ```
  > 快搭表单不一定触发审批流，无法从待审批/已发起列表反查，必须由用户提供链接。
- 用户提供链接后，提取 URL 中的 `recordId` 参数，调用 `getRecordInfo --recordId <recordId>`
- **权限检查（⚠️ 必须执行）**：检查 `permissions` 数组是否包含 `"UPDATE"`
  - 不含 `"UPDATE"` → 告知「您没有修改该记录的权限」，流程结束
  - 含 `"UPDATE"` → 继续
- 从返回结果中提取并缓存：
  - `bpmCode` → 作为 `updateRecord` 的 `--bpmCode`
  - `formCode` → 作为 `updateRecord` 的 `--formCode`
  - `formVersion` → 作为 `updateRecord` 的 `--formVersion`
  - `billDataList` → 格式化后的字段列表，直接用于展示
  - `JSON.parse(formSchema)` → 控件类型和显隐规则
- 向用户展示 `billDataList`（含 label、当前值），针对 `Select`、`SelectDD` 控件增加「可选值」列，必须从 `formSchema` 对应控件的 `props.options` 提取，不能自造
- 询问用户需要修改哪些字段

**出口条件**：用户已说明需要修改的字段及新值

---

## Step 1.5 · 显隐条件检测（⚠️ 必须执行）

**入口条件**：用户已确认修改字段

解析 `formSchema` 中所有含 `props.visibility.formula` 的控件。公式格式为 `#{fieldId}` 引用其他字段值，例如 `(#{select_bd241043}==="select05yn6vkcly8k")`。用户修改字段后，用旧值和新值分别代入依赖它的公式——若结果不同，说明该控件可见性发生变化，需向用户确认：

```
⚠️ 检测到以下字段可见性将发生变化：

| 字段 | 变化 | 原因 |
|------|------|------|
| 项目补充 | 隐藏 → ✅ 显示（必填） | 项目等级 B → A |

该字段当前有历史值：「一期：MFA多因素认证……」
是否保留此值？还是需要修改？
```

⛔ 等待用户确认后再进入 Step 2。

**出口条件**：无显隐变化，或已就变化字段与用户确认处理方式

---

## Step 2 · 构建 billData（控件格式）

**入口条件**：Step 1.5 完成，已确认所有字段新值

> 与 `kuaida-submit` skill 的差异如下（其余完全相同）：

| 项目                   | kuaida-submit           | 本章（修改记录）                                                                                                                  |
| ---------------------- | ----------------------- | --------------------------------------------------------------------------------------------------------------------------------- |
| formSchema 来源        | 调用 `getFormSchema`    | 复用 Step 1 返回的 `formSchema`，**跳过 getFormSchema 调用**                                                                      |
| 字段初始值             | 空（用户从头填）        | 以 `billDataList` 原值预填，用户只需说明修改项                                                                                    |
| 预览表格               | 填写内容                | 原值 vs 新值对比（✏️ 已修改 / 未改动）                                                                                            |
| People 控件值格式      | 纯字符串 `userId`       | `{value, label, mis, ...}` 对象，如 `{"value":"123456","label":"张三","mis":"zhangsan","avatar":"","name":"张三","tenantId":"1"}` |
| MultiPeople 控件值格式 | `userId` 字符串数组     | 对象数组，如 `[{"value":"123456","label":"张三","mis":"zhangsan",...},{"value":"123789","label":"李四","mis":"lisi",...}]`        |
| Department 控件值格式  | 纯字符串 `departmentId` | `{value, label, seriesCode, externalSource, tenantId}` 对象，如 `{"value":"40054678","label":"美团/核心本地商业",...}`            |

### 格式规范选择逻辑（A+B 双轨制）

```
Step 2a · 遍历 billDataList 中所有字段的控件类型
  ↓
Step 2b · 对照下方「控件格式速查」判断是否全部覆盖
  ├─ 全部覆盖 → 直接用速查表构建 billData（走 A 方案）
  └─ 存在速查表未涵盖的控件类型 → 走 B 方案 ↓
       │
       Step 2c · 检测 kuaida-submit skill 是否已安装
       ├─ 已安装 → 读取其 references/fill-form.md 获取完整格式规范后构建
       └─ 未安装 → 自动执行安装：
                      oa-skills skill install --id 3060 -g
                    安装成功 → 读取 fill-form.md 获取完整规范后构建
                    安装失败 → 用速查表尽力构建 + 提示用户该字段可能需要手动确认
```

### 控件格式速查（A 方案——覆盖 8 种常见控件）

| 控件类型                | 值格式                                                                                                                           |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| People（人员）          | `{value, label}` object，如 `{"value":"123456","label":"张三"}`                                                                  |
| MultiPeople（多选人员） | 对象数组，如 `[{"value":"123456","label":"张三"},{"value":"789","label":"李四"}]`                                                |
| Department（部门）      | `{value, label}` object，如 `{"value":"40054678","label":"美团/核心本地商业"}`                                                   |
| Table / 子表单          | 纯数组 `[{...}]`。⚠️ **platformId=14（快搭应用）时每行必须含 `"id": "row_N"`**（任意唯一字符串），否则报「子表单数据缺少id」错误 |
| Select / 单选           | `{value, label}` object，如 `{value: "option_key", label: "选项一"}`                                                             |
| DateRange               | `[startTs, endTs]` 数组（日期字符串），如 `["2026-04-07", "2026-04-30"]`                                                         |
| Date                    | 日期字符串，如 `"2026-04-07"`                                                                                                    |
| Cascader / 级联         | `{path, fullName}` object，如 `{"path": "330000/330100/330105", "fullName": "浙江省/杭州市/拱墅区"}`                             |

**B 方案**：自动安装并引用 [kuaida-submit](https://friday.sankuai.com/skills/skill-detail?id=3060) skill 的 `references/fill-form.md` 获取完整控件格式规范。

### 必填字段兜底检查（⚠️ 必须执行）

构建完 billData 后，遍历 `formSchema` 中 `validation` 含 `{"type":"required","enable":true}` 的字段：

- 若该字段在 billData 中的值为**空字符串、null、undefined 或空数组** → **必须提醒用户补充**

```
⚠️ 检测到以下必填字段当前为空：

| 字段 | 控件类型 | 说明 |
|------|---------|------|
| 采购说明 | TextArea | 必填项，原值为空 |

请提供该字段的内容（或确认留空并自行承担校验不通过的风险）。
```

⛔ 等待用户回复后再进入 Step 3。

**出口条件**：已构建完整 billData 对象，包含所有字段（含未修改项），所有必填字段非空或已与用户确认

---

## Step 3 · 预览确认并执行

**入口条件**：billData 构建完成

展示原值 vs 新值对比表格：

```
📋 表单变更预览 — {流程名称}

| 字段 | 原值 | 新值 | 状态 |
|------|------|------|------|
| 采购金额 | 1000 | 1500 | ✏️ 已修改 |
| 采购说明 | 打印纸 | （同上） | 未改动 |

确认修改记录？回复「确认」执行。
```

⛔ 等待用户明确回复「确认」「是」「好」等肯定词，未收到则不执行

**出口条件**：收到用户明确确认

---

## Step 4 · 执行更新

- 调用以下命令更新记录（`bpmCode`/`formCode`/`formVersion` 均来自 `getRecordInfo` 的返回字段）：
  ```bash
  oa-skills shenpi updateRecord \
    --bpmCode "<bpmCode>" \
    --formCode "<formCode>" \
    --formVersion "<formVersion>" \
    --billData '<完整 billData JSON>'
  ```
- `--billData` 必须包含**所有字段**（含未修改项），不能只传改动字段
- 成功后回复「✅ 表单记录已更新」；失败则参照错误处理
