# CLI 速查

```bash
# 查询
oa-skills shenpi getPendingApprovals
# 查我发起的审批单据（审批中）
oa-skills shenpi getSubmittedApprovals --billStatus 1
oa-skills shenpi getPendingApprovals --starttime '2025-03-03 09:00' --endtime '2025-03-31 23:30:30'
oa-skills shenpi getPendingApprovals --limit 50 --offset 1
oa-skills shenpi getHandledApprovals --billStatus 2
oa-skills shenpi getSubmittedApprovals
oa-skills shenpi getCCApprovals
oa-skills shenpi getApproveDetail --billId "UOH3000043156781" --platformId 1
oa-skills shenpi queryAllowSubmitProcess --keyword "设备借用"
oa-skills shenpi queryUserInfo --filter "zhangsan06"
# 操作
# ⚠️ operationType 与 operationUrl 必须配对：
#   APPROVE → 传 approveUrl；REJECT → 传 rejectUrl
#   不匹配时后端返回「操作失败」
oa-skills shenpi operateApprove \
  --billId "UOH3000043156781" \
  --operationType "APPROVE" \
  --operationUrl "https://shenpi.sankuai.com/approveUrl" \
  --platformId 1 --taskId "782000000000061552" --tenantId "1" --message "通过意见"
# 撤回单据
oa-skills shenpi withdrawApprove --billId "UOH3000043156781" --operateType "WITHDRAW" --platformId 1
# 催办（审批平台）
oa-skills shenpi urgeApproval --billId "UOH3000043156781" --platformId 1
# 催办（快搭平台）
oa-skills shenpi urgeApproval --procInstId "puo6vpw3y7oyklh6ctcc7" --platformId 14
# 转交审批（仅快搭平台）
oa-skills shenpi transferApproval \
  --procInstId "puo6vpw3y7oyklh6ctcc7" \
  --taskInstId "task-xxxxxxxx" \
  --targetUserId "123456" \
  --comment "转交意见"  # 可选参数
# 加签操作
oa-skills shenpi addSignApprove \
  --taskId "782000000000061552" \
  --targetUserId "123456" --operateType "ADD_TASK_BEFORE" \
  --comment "加签意见" --platformId 1
# 重新提交单据
oa-skills shenpi resubmitApproval --billId "UOH3000043156781" --platformId 1 --billData '{"input_abc123":"修改后的值"}'
# 提交单据（新发起）
oa-skills shenpi submitApproval --processRef "pdId_or_formCode" --platformId 1 --billData '{"input_abc123":"值"}'
# 查询快搭应用列表
oa-skills shenpi queryAppList --keyword "应用名称"
# 查询快搭应用下的表单列表
oa-skills shenpi getFormListByAppCode --appCode "app-xxx"
# 查询快搭记录详情（非审批详情）
oa-skills shenpi getRecordInfo --recordId "b4ce749bb810497bbf395bac5dc14745"
# 修改快搭表单记录
oa-skills shenpi updateRecord \
  --bpmCode "2af1db0c8edc4e68bb0377002c5059de" \
  --formCode "form-fim7pxmmxyhw8f1rmdet1" \
  --formVersion 8 \
  --billData '{"input_abc123":"新值","people_xyz":"60549382"}'

# 其他
oa-skills shenpi --clear-cache
```

## 参数速查

| 参数                                              | 说明                                                                                                         | 默认值 |
| ------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ------ |
| `--starttime / --endtime`                         | 时间范围，直接传日期字符串即可，无需手动转换为时间戳（如"2025-03-03 09:00"）                                 | -      |
| `--billStatus`                                    | 0=全部 1=待审批 2=已通过 3=已驳回 4=已撤回                                                                   | -      |
| `--limit / --offset`                              | 分页                                                                                                         | 20 / 1 |
| `--sponsorId`                                     | 发起人 userId（数字，非 MIS ID；如需通过姓名查询，可用 `oa-skills shenpi queryUserInfo --filter 姓名` 获取） | -      |
| `--filter`（queryUserInfo）                       | 需要查询的姓名或mis ⚠️ **调用queryUserInfo必须用`--filter`传参**                                             | -      |
| `--taskDesc`                                      | 按摘要内容筛选，如「采购」「考勤」                                                                           | -      |
| `--keyword`                                       | 流程或应用名称关键词（`queryAllowSubmitProcess` 搜流程；`queryAppList` 搜快搭应用，仅 platformId=14）        | -      |
| `--appCode`                                       | 快搭应用编码 `app-xxx`（`getFormListByAppCode` 必填，仅 platformId=14）                                      | -      |
| `--billId / --taskId / --platformId / --tenantId` | 操作必填                                                                                                     | -      |
| `--platformId`（getApproveDetail）                | 平台 ID，1=审批中心，14=快搭                                                                                 | -      |
| `--processRef`                                    | 流程/表单标识（submitApproval 必填）：platformId=1 传 pdId，platformId=14 传 formCode（form-xxx）            | -      |
| `--procInstId`                                    | 流程实例 ID（快搭平台单据催办必填、 transferApproval 必填）                                                 | -      |
| `--billData`                                      | 表单数据对象（submitApproval / resubmitApproval / updateRecord 必填）                                        | -      |
| `--operationType`                                 | APPROVE / REJECT                                                                                             | -      |
| `--operationUrl`                                  | 通过传 approveUrl，驳回传 rejectUrl（operateApprove 必填）；与 operationType 不匹配后端报错                  | -      |
| `--message`                                       | 审批意见（可选，通过或驳回时均可附加）                                                                       | -      |
| `--targetUserId`                                  | 被加签人/转交目标用户 userId                                                                                 | -      |
| `--operateType`                                   | 操作类型 撤回=WITHDRAW 前加签=ADD_TASK_BEFORE 后加签=ADD_TASK_AFTER                                          | -      |
| `--comment`                                       | 加签意见 / 转交意见（可选）                                                                                  | -      |
| `--taskInstId`                                    | 转交目标任务 ID（transferApproval 必填）                                                                     | -      |
| `--recordId`                                      | 快搭表单记录 ID（getRecordInfo 必填）                                                                        | -      |
| `--bpmCode`                                       | 快搭表单 bpmCode（updateRecord 必填）                                                                        | -      |
| `--formCode`                                      | 快搭表单 formCode（updateRecord 必填）                                                                       | -      |
| `--formVersion`                                   | 快搭表单schema版本（updateRecord 必填）                                                                      | -      |
