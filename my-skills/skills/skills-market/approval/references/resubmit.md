> **说明**：Step 3 采用 **A+B 双轨制**——内置控件速查表覆盖常见场景（零依赖）；遇到复杂控件时自动安装 [kuaida-submit](https://friday.sankuai.com/skills/skill-detail?id=3060) skill 并引用其完整格式规范。详见 Step 3。

---

## 目录

- [IRON LAW 与 Anti-Pattern](#iron-law--anti-pattern)
- [Step 1 · 确定目标单据](#step-1--确定目标单据)
- [Step 2 · 获取原表单数据](#step-2--获取原表单数据)
  - [Step 2.5 · 显隐条件检测（⚠️ 必须执行）](#step-2.5--显隐条件检测⚠️-必须执行)
- [Step 3 · 构建 billData（控件格式）](#step-3--构建-billdata控件格式)
  - [Step 3d · 必填字段兜底检查（⚠️ 必须执行）](#step-3d--必填字段兜底检查⚠️-必须执行)
- [Step 4 · 预览确认](#step-4--预览确认)
- [Step 5 · 执行重新提交](#step-5--执行重新提交)

---

## IRON LAW

**⛔ 禁止在未获得用户「确认」前调用 `resubmitApproval`**
**⛔ 禁止跳过 Step 2.5（显隐检测）——即使用户未修改任何字段**
**⛔ `--billData` 必须包含所有字段（含未修改项），不能只传改动字段**

---

## Anti-Pattern

| #    | 禁止行为                                                 | 正确做法                                               |
| ---- | -------------------------------------------------------- | ------------------------------------------------------ |
| AP-1 | 未调用 `getSubmittedApprovals` 就直接 `getApproveDetail` | Step 1 先确认 billId 来自已驳回/已撤回列表             |
| AP-2 | 跳过 Step 2.5，直接构建 billData                         | 每次用户修改字段后都必须做显隐检测                     |
| AP-3 | `--billData` 只包含修改字段                              | 必须传入完整 billData（含未改动字段）                  |
| AP-4 | 将 people/department 字段传为对象                        | 人员必须传纯字符串 userId，部门传纯字符串 departmentId |
| AP-5 | 未等用户确认就执行提交                                   | Step 4 预览后等待「确认」「是」「好」等明确肯定词      |
| AP-6 | 必填字段原值为空就直接传空                               | 重新提交时平台会做必填校验，必须提醒用户补充或确认     |

---

## Step 1 · 确定目标单据

**入口条件**：收到「重新提交」「重新发起」等触发词

- 若上下文缺少 billId，分别调用两次查询，合并结果展示：
  ```bash
  oa-skills shenpi getSubmittedApprovals --billStatus 3 --limit 20
  oa-skills shenpi getSubmittedApprovals --billStatus 4 --limit 20
  ```
  **仅展示 billStatus=3（已驳回）和 billStatus=4（已撤回）的单据**，由用户选择
- 取得 `billId` 和 `platformId`，供后续步骤使用

**出口条件**：已确定目标单据的 `billId` 和 `platformId`

---

## Step 2 · 获取原表单数据

**入口条件**：已有 `billId` 和 `platformId`

- 调用 `oa-skills shenpi getApproveDetail --billId <id> --platformId <1|14>`
- 返回 `billDataList`（字段列表，含各控件当前值）、`formSchema`（表单 schema JSON 字符串）、`pdId`（platformId=1）或 `formCode`（platformId=14）
- **展示 `billDataList` 字段列表**，针对 `Select`、`SelectDD` 控件增加 `可选值` 列，必须从 `formSchema` 对应控件的 `props.options` 匹配，不能自造
- 询问用户需要修改哪些字段

**出口条件**：用户已说明需要修改的字段及新值

---

### Step 2.5 · 显隐条件检测（⚠️ 必须执行）

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

⛔ 等待用户确认后再进入 Step 3。

**出口条件**：无显隐变化，或已就变化字段与用户确认处理方式

---

## Step 3 · 构建 billData（控件格式）

**入口条件**：Step 2.5 完成，已确认所有字段新值

> 与 `kuaida-submit` skill 的差异如下（其余完全相同）：

| 项目            | kuaida-submit        | 本章（重新提交）                                             |
| --------------- | -------------------- | ------------------------------------------------------------ |
| formSchema 来源 | 调用 `getFormSchema` | 复用 Step 2 返回的 `formSchema`，**跳过 getFormSchema 调用** |
| 字段初始值      | 空（用户从头填）     | 以 `billDataList` 原值预填，用户只需说明修改项               |
| 预览表格        | 填写内容             | 原值 vs 新值对比（✏️ 已修改 / 未改动）                       |

### 格式规范选择逻辑（A+B 双轨制）

```
Step 3a · 遍历 billDataList 中所有字段的控件类型
  ↓
Step 3b · 对照下方「控件格式速查」判断是否全部覆盖
  ├─ 全部覆盖 → 直接用速查表构建 billData（走 A 方案）
  └─ 存在速查表未涵盖的控件类型 → 走 B 方案 ↓
       │
       Step 3c · 检测 kuaida-submit skill 是否已安装
       ├─ 已安装 → 读取其 references/fill-form.md 获取完整格式规范后构建
       └─ 未安装 → 自动执行安装：
                      oa-skills skill install --id 3060 -g
                    安装成功 → 读取 fill-form.md 获取完整规范后构建
                    安装失败 → 用速查表尽力构建 + 提示用户该字段可能需要手动确认
```

> **核心原则**：常规场景零依赖自给自足；遇到复杂控件自动补全能力，无需用户操心。

### 控件格式速查（A 方案——覆盖 8 种常见控件）

| 控件类型                | 值格式                                                                                                                           |
| ----------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| People（人员）          | 纯字符串 userId，如 `"60549382"`                                                                                                 |
| MultiPeople（多选人员） | `userId` 数组，如 `["60549382", "20541342"]`                                                                                     |
| Department（部门）      | 纯字符串 departmentId，如 `"100260"`                                                                                             |
| Table / 子表单          | 纯数组 `[{...}]`。⚠️ **platformId=14（快搭应用）时每行必须含 `"id": "row_N"`**（任意唯一字符串），否则报「子表单数据缺少id」错误 |
| Select / 单选           | `{value, label}` object，如 `{value: "option_key", label: "选项一"}`                                                             |
| DateRange               | `[startTs, endTs]` 数组（日期字符串），如 `["2026-04-07", "2026-04-30"]`                                                         |
| Date                    | 日期字符串，如 `2026-04-07`                                                                                                      |
| Cascader / 级联         | `{path, fullName}` object，如 `{"path": "330000/330100/330105", "fullName": "浙江省/杭州市/拱墅区"}`                             |

**B 方案——当字段类型不在上表中时**：自动安装并引用 [kuaida-submit](https://friday.sankuai.com/skills/skill-detail?id=3060) skill 的 `references/fill-form.md` 获取完整控件格式规范。

### Step 3d · 必填字段兜底检查（⚠️ 必须执行）

构建完 billData 后，遍历 `formSchema` 中 `validation` 含 `{"type":"required","enable":true}` 的字段：

- 若该字段在 billData 中的值为**空字符串、null、undefined 或空数组** → **必须提醒用户补充**
- 即使原值就是空的（用户之前没填），重新提交时平台会做必填校验

```
⚠️ 检测到以下必填字段当前为空：

| 字段 | 控件类型 | 说明 |
|------|---------|------|
| 项目描述 | TextArea | 必填项，原值为空 |

请提供该字段的内容（或确认留空并自行承担校验不通过的风险）。
```

⛔ 等待用户回复后再进入 Step 4。

**出口条件**：已构建完整 billData 对象，包含所有字段（含未修改项），所有必填字段非空或已与用户确认

---

## Step 4 · 预览确认

**入口条件**：billData 构建完成

展示原值 vs 新值对比表格：

```
📋 单据变更预览 — {流程名称}

| 字段 | 原值 | 新值 | 状态 |
|------|------|------|------|
| 项目等级 | B | A | ✏️ 已修改 |
| 项目名称 | 统一身份认证平台升级项目 | （同上） | 未改动 |
| 项目补充 | （隐藏）一期：MFA…… | 一期：MFA…… | 🔍 由隐变显 |

确认提交？回复「确认」执行。
```

- ⛔ 等待用户明确回复「确认」「是」「好」等肯定词，未收到则不执行

**出口条件**：收到用户明确确认

---

## Step 5 · 执行重新提交

- 调用 `oa-skills shenpi resubmitApproval --billId "<原单据 billId>" --platformId <1|14> --billData '<完整 billData JSON>'` 重新提交
- `--billData` 必须包含**所有字段**（含未修改项），不能只传改动字段
- 成功后回复「✅ 重新提交成功」（附 `detailUrl` 链接）；失败则参照错误处理
