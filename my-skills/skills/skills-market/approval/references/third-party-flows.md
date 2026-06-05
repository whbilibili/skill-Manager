# 三方流程发起路由表

> 当用户想要发起的流程不属于快搭（审批中心），通过本表匹配对应的三方系统和推荐 Skill。
> 维护者：zhangyi173 | 新增三方接入时在此追加。

---

## 路由表

| 流程类型 | 识别关键词 | 链接域名特征 | 对应系统 | 推荐 Skill | Skill 广场链接 | 备注 |
|---------|-----------|-------------|---------|-----------|--------------|------|
| 合同提报 | 合同、contract、海螺、合同创建、合同审批 | contract.sankuai.com | 海螺合同系统 | contract-creation | https://friday.sankuai.com/skills/skill-detail?id=7416 | 上传合同附件后发起创建，verified ✅ |
| 费用报销 | 报销、expense、钱管家、报销单 | — | 钱管家报销系统 | fin-expense | https://friday.sankuai.com/skills/skill-detail?id=10566 | 创建报销单并提交审批，verified ✅ |
| 医药审批 | 医药审批、医药流程、health-work-flow | — | 医药审批工作流 | health-work-flow | https://friday.sankuai.com/skills/skill-detail?id=6413 | 医药业务线专用，未 verified |
| 采购预算申请 | 采购、采购申请、PR申请、预算申请、申请买东西、采购预算 | — | 采购系统 | procure-budget | https://friday.sankuai.com/skills/skill-detail?id=5756 | 对话式填写采购PR单并提交，支持标品/非标品，verified ✅ |
| 采购下单 | 采购下单、PO单、采购订单、下单、待认领PR | — | 采购系统 | procure-po-assistant | https://friday.sankuai.com/skills/skill-detail?id=8882 | 自动提交采购订单PO单，verified ✅ |
| 名片申请 | 名片、名片制作、办名片、印名片 | — | 名片制作系统 | business-card-helper | https://friday.sankuai.com/skills/skill-detail?id=11069 | 在线提交纸质名片制作申请，verified ✅ |
| 请假/考勤 | 请假、调休、年假、病假、请假申请、考勤申诉、假期余额 | — | 假勤系统 | hr-attendance | https://friday.sankuai.com/skills/skill-detail?id=10178 | 请假申请+考勤申诉+假期查询，verified ✅ |
| 对公用印 | 用印、盖章、对公用印、资质证照、营业执照用印 | xz.sankuai.com | 行政用印系统 | certificate-application | https://friday.sankuai.com/skills/skill-detail?id=3993 | 对公资质用印申请，自动推断字段并提交，verified ✅ |
| 办公用品领用 | 办公用品、领用、文具、办公耗材、领取办公用品 | — | 行政办公用品系统 | xz-office-supplies | https://friday.sankuai.com/skills/skill-detail?id=8677 | 查询和申领行政办公用品，verified ✅ |
| IT资产申请 | IT资产、申请设备、归还设备、电脑维修、申请电脑、还电脑、报修 | — | IT服务平台 | it-buddy | https://friday.sankuai.com/skills/skill-detail?id=7311 | IT资产申请/归还/回购/维修，verified ✅ |
| 差旅出行 | 差旅、出差、订机票、订酒店、差旅申请、出差申请 | — | 企业版差旅平台 | travel-helper | https://friday.sankuai.com/skills/skill-detail?id=12339 | 差旅及一站式出行平台，verified ✅ |
| 采购验收 | 采购验收、GR单、验收申请、确认验收、验收单 | — | 采购系统 | procure-acceptance-assistant | https://friday.sankuai.com/skills/skill-detail?id=8885 | 自动发起采购验收GR单，verified ✅ |
| 工卡/门禁 | 工卡、门禁、补办工卡、工卡挂失、通行二维码、人脸录入 | — | 工卡门禁系统 | mybadge | https://friday.sankuai.com/skills/skill-detail?id=3014 | 工卡挂失补办+门禁权限申请，verified ✅ |

---

## 回复模板

匹配到路由表时，按以下格式回复用户：

```
「{流程类型}」属于「{对应系统}」，不在快搭/审批中心的流程范围内，无法通过审批 Skill 直接发起。

你可以安装「{推荐 Skill}」skill 来让 AI 帮你完成：
👉 [{Skill 名称}]({Skill 广场链接})

安装后直接告诉 AI 你要发起什么单据即可。
```

**示例**（用户说"帮我发起合同审批"）：

```
「合同提报」属于「海螺合同系统」，不在快搭/审批中心的流程范围内，无法通过审批 Skill 直接发起。

你可以安装「contract-creation」skill 来让 AI 帮你完成：
👉 [合同创建](https://friday.sankuai.com/skills/skill-detail?id=7416)

安装后直接告诉 AI 你要发起什么单据即可。
```

---

## 无匹配时回复

当用户描述的流程既不在快搭、也不匹配本路由表时：

```
该流程暂不支持通过 AI 发起。你可以：
1. 前往对应系统手动操作
2. 告诉我具体是哪个系统，我帮你查找是否有对应的 skill 可用

如有疑问，欢迎加入快搭&审批官方Skill-用户交流群反馈：
📌 [点击加入交流群](https://applink.neixin.cn/profile?gid=70425539850)
```

---

## 扩展说明

- **新增路由**：广场上新增 verified 的发起类 skill 时，在路由表追加一行
- **匹配逻辑**：关键词匹配 + 链接域名匹配双保险（有链接时优先看域名，无链接时看关键词）
- **只推荐 verified skill**：未 verified 的 skill 可列入但需在备注中标明，由用户自行判断
- **不做质量背书**：回复中标注"由第三方 skill 提供"，approval skill 不对三方 skill 的功能负责
