# 业务 Skill 路由表

> 本文件定义审批中心识别到特定流程编码时，应路由到哪个业务 Skill 补充风险信息。
> 由 DQ 维护，新增业务接入时在此追加。

---

## 路由规则

| processId                | 流程名称                             | 业务域 | 调用业务 Skill             | Skill 名称       | Skill ID |
| ------------------------ | ------------------------------------ | ------ | -------------------------- | ---------------- | -------- |
| `pr_shenqing_feilixiang` | 采购门户\_采购预算申请单审批         | 采购   | procure-approval-monitor   | 采购智能审批助手 | 11356    |
| `pr_shenqing`            | 采购门户\_关联BR采购预算申请单审批   | 采购   | procure-approval-monitor   | 采购智能审批助手 | 11356    |
| `order_shenpi`           | 采购门户\_采购订单审批               | 采购   | procure-approval-monitor   | 采购智能审批助手 | 11356    |
| `purchase_project_N`     | 采购工作系统\_采购项目\_立项汇报审批 | 采购   | procure-approval-monitor   | 采购智能审批助手 | 11356    |
| `purchase_result_N`      | 采购工作系统\_采购项目\_结果汇报审批 | 采购   | procure-approval-monitor   | 采购智能审批助手 | 11356    |
| `attn_chanjia`           | 产假申请流程                         | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `attn chanjianjia`       | 产检假申请流程                       | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `wbkq_02`                | 外包考勤申诉申请                     | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `wbqj_02`                | 外包请假申请                         | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `attn_hunjia`            | 婚假流程                             | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `attn arrangement`       | 排班申请                             | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `attn withdraw bk`       | 撤销补卡申请                         | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `attn liuchanjia`        | 流产假申请流程                       | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `attn_order`             | 考勤申诉申请                         | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `attn absence bk`        | 考勤补卡申请                         | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `attn_yuerjia`           | 育儿假流程                           | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `add childlnfo`          | 育儿假添加子女信息                   | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `wbkq_03`                | 蓝领外包考勤申诉                     | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `wbqj_lanling`           | 蓝领外包请假申请                     | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `attn_leave`             | 请假申请                             | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `compensatory leave`     | 调休流程                             | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `attn withdraw leave`    | 销假申请                             | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `attn peichanjia`        | 陪产假申请流程                       | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `wbxj_02`                | 外包销假申请                         | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |
| `wbxj_lanling`           | 蓝领外包销假申请                     | 考勤   | attendance-approval-helper | HR 考勤审批助手  | 13519    |

---

## 调用规范

**传入参数：**

- `billId`：审批中心单据号（从 `getPendingApprovals` 返回值中获取）
  **期望返回格式（标准协议草案，与采购团队约定）：**

```json
{
  "riskLevel": "高/中/低", // 可选，若无明确判断则不返回此字段
  "reason": "超出预算30%", // 风险摘要，必填
  "keyValue": "超出金额：¥12,000", // 关键数据，必填
  "suggestion": "建议驳回" // 可选
}
```

**字段展示规则：**

- `riskLevel` 有值 → 展示风险等级行
- `riskLevel` 无值或未返回 → 不展示风险等级行，其余正常展示
- 整体调用失败 → 展示「⚠️ {业务域}风险信息不可用」

---

## 试点状态

| processId                | 状态      | 备注                                                     |
| ------------------------ | --------- | -------------------------------------------------------- |
| `pr_shenqing_feilixiang` | 🟢 已上线 | 已与采购智能审批助手（procure-approval-monitor）完成联调 |
| `pr_shenqing`            | 🟢 已上线 | 已与采购智能审批助手（procure-approval-monitor）完成联调 |
| `order_shenpi`           | 🟢 已上线 | 已与采购智能审批助手（procure-approval-monitor）完成联调 |
| `purchase_project_N`     | 🟢 已上线 | 已与采购智能审批助手（procure-approval-monitor）完成联调 |
| `purchase_result_N`      | 🟢 已上线 | 已与采购智能审批助手（procure-approval-monitor）完成联调 |
| `attn_chanjia`           | 🟢 可使用 | 已与 attendance-approval-helper（wanghaidi02）完成对接   |
| `attn chanjianjia`       | 🟢 可使用 | 同上                                                     |
| `wbkq_02`                | 🟢 可使用 | 同上                                                     |
| `wbqj_02`                | 🟢 可使用 | 同上                                                     |
| `attn_hunjia`            | 🟢 可使用 | 同上                                                     |
| `attn arrangement`       | 🟢 可使用 | 同上                                                     |
| `attn withdraw bk`       | 🟢 可使用 | 同上                                                     |
| `attn liuchanjia`        | 🟢 可使用 | 同上                                                     |
| `attn_order`             | 🟢 可使用 | 同上                                                     |
| `attn absence bk`        | 🟢 可使用 | 同上                                                     |
| `attn_yuerjia`           | 🟢 可使用 | 同上                                                     |
| `add childlnfo`          | 🟢 可使用 | 同上                                                     |
| `wbkq_03`                | 🟢 可使用 | 同上                                                     |
| `wbqj_lanling`           | 🟢 可使用 | 同上                                                     |
| `attn_leave`             | 🟢 可使用 | 同上                                                     |
| `compensatory leave`     | 🟢 可使用 | 同上                                                     |
| `attn withdraw leave`    | 🟢 可使用 | 同上                                                     |
| `attn peichanjia`        | 🟢 可使用 | 同上                                                     |
| `wbxj_02`                | 🟢 可使用 | 同上                                                     |
| `wbxj_lanling`           | 🟢 可使用 | 同上                                                     |

---

## 扩展说明

- 新增业务接入：在路由规则表追加一行，同时确认输出格式符合标准协议
- 如业务方返回格式有扩展字段，格式化层取标准字段展示，忽略非标准字段
- 当前已接入采购（2026-03-26 起）和 HR 考勤（2026-04-13 可使用）两个业务域，其他业务域待评估后逐步接入
