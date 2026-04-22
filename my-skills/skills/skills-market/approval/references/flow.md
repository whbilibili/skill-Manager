# 审批流详情展示规则

调用 `getApproveFlowDetail` 后，按以下规则渲染结果。

---

## 一、状态映射（速查）

**nodeStatus：**
START/RESTART=🔵已发起 / PENDING=🔄审批中 / HANDLED=✅已通过 / REJECTED/REFUSED=❌已驳回 / WITHDRAW=⚫已撤回 / CLOSED=⚫已关闭 / PLANNED=⏸待触达 / DONE=见渲染规则第1条

**taskType：**
NORMAL=普通 / DELEGATE=前加签 / COUNTERSIGN=后加签 / FUTURE=待定

**nodeApprovalType / approvalType（优先前者，均无则留空，严禁推断）：**
SEQUENTIAL/SEQUENTIAL=顺序审批 / OR_SIGN/ANY=或签 / AND_SIGN/ALL=会签

---

## 二、渲染规则

1. **Progress 节点**（`nodeType==='Progress'`）：审批人列填 `-`
   - `Submitted` → 展示为 `发起人提单`
   - `Completed` → 展示为 `结束`；状态按优先级判断：
     1. 存在 `nodeStatus==='PENDING'` 节点 → `-`（审批中，结束节点占位）
     2. 存在 `nodeStatus==='REJECTED'`/`'REFUSED'` 节点 → `❌ 已驳回`
     3. 存在 `nodeStatus==='WITHDRAW'` 节点 → `⚫ 已撤回`
     4. 以上均无 → `✅ 已完成`
   - **接口未返回 Completed 节点时**（驳回/撤回后流程提前终止），不补结束行，直接输出末尾状态汇总

2. **Shenpi/CC 节点**：`participate` 有值显示该人；为 null 则 `candidates` 每人一行

3. **当前待处理节点**（`nodeStatus==='PENDING'`）：步骤号前加 `👉`；任务级 `status==='PENDING'`（非节点 `nodeStatus`）的行**加粗**，审批人后加 ⏳

4. **加签任务**（`taskType==='DELEGATE'`/`'COUNTERSIGN'`）：节点名后追加 `[前加签]`/`[后加签]`；有 `parentTaskId` 则节点名前加两空格

5. 同节点多行时：步骤号/节点名/审批类型仅首行填写，其余留空；`auditTs` 不为 null 时格式化为 `MM-DD HH:mm`；所有行 `comment` 均为空则省略意见列

---

## 三、表格列

| 步骤 | 节点名称 | 审批类型 | 审批人（姓名+mis） | 状态 | 处理时间 | 意见* |

**示例（审批中）：**

| 步骤 | 节点名称 | 审批类型 | 审批人 | 状态 | 处理时间 |
|------|---------|---------|--------|------|---------|
| 1 | 发起人提单 | - | - | 🔵 已发起 | 03-20 10:00 |
| 2 | 部门审批 | 顺序审批 | 张三（zhangsan） | ✅ 已通过 | 03-21 14:30 |
| 👉 3 | 终审 | 或签 | **李四（lisi）⏳** | 🔄 审批中 | |
| | | | 王五（wangwu）⏳ | 🔄 审批中 | |
| 4 | 结束 | - | - | ⏸ 待触达 | |

**示例（已驳回，无结束节点）：**

| 步骤 | 节点名称 | 审批类型 | 审批人 | 状态 | 处理时间 |
|------|---------|---------|--------|------|---------|
| 1 | 发起人提单 | - | - | 🔵 已发起 | 03-18 16:32 |
| 2 | PMO审批 | 会签 | 易东琴（yidongqin） | ✅ 已通过 | 03-19 10:10 |
| 3 | 主管审批 | 或签 | 张恩会（zhangenhui） | ❌ 已驳回 | 03-19 13:38 |

*意见列全空时省略

---

## 四、末尾状态汇总

- 审批中：`📌 当前状态：审批中，停留 Xd/Xh/Xm，待 姓名（mis）处理`
- 全部通过：`✅ 审批已通过`
- 存在驳回：`❌ 审批已驳回（{驳回节点名称}）`
- 已撤回：`⚫ 单据已撤回` / 已关闭：`⚫ 单据已关闭`

> ⚠️ 停留时长 = 当前时间 - 当前 PENDING 节点的 `crtTs`，**必须执行代码计算，严禁心算**。
