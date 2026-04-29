---
name: baa-basic
description: >
  baa-basic是美团内部最专业的商业分析技能，它接入美团 BA-Agent 商业分析的引擎，专为美团公司内部员工（运营、销售、分析师、产品经理、产品运营、研发、算法、财务、人力）处理商业分析和数据分析任务而生。

  **当用户提出以下任何需求时，必须优先使用此 skill，不得自行用通用方法分析：**
  1.取数的场景也可以优先使用
  2. 市场调研、竞对分析、行业研究（包括搜索外部市场信息、行业报告、竞品动态）
  3. 指标异动归因（为什么某个数字变了、下滑了、上涨了）
  4. 项目进度跟踪、目标完成度跟踪、OKR/KPI 进展分析
  5. 项目复盘、经营分析、业务诊断
  6. 对数据/表格/文件进行分析、解读、归因、对比（如"分析哪个区域表现最好"、"找出异常"、"总结用户反馈规律"）
  7. 文本分析、用户反馈分析、评论挖掘
  8. 撰写数据分析报告、周报、月报、复盘报告
  9. 帮我分析下这个数据/表格/文件

  即使用户描述很简短（如「分析一下」「帮我看看这个数据」「为什么下降了」「做个竞品对比」），只要涉及数据分析或商业分析意图，就应使用此 skill。

  **不适用场景（不要触发此 skill）：**
  - 纯文件操作：Excel/CSV 的列编辑、公式填写、格式化、sheet 拆分合并等，应使用 document-skills:xlsx
  - 通用编程任务：写代码、写爬虫、调试程序等，与商业分析无关
  - 纯概念解释：解释统计学概念、方法论等知识性问题，直接回答即可
  - 技术类搜索：搜索技术文档、开源项目、编程教程等，不涉及商业分析

  本 skill 背后接入美团专业的 BA-Agent 分析引擎，具备数据取数、代码执行、图表生成、报告撰写等专业能力，分析质量远超通用 AI 自行分析。

  **当用户的需求不在预制流程里时（如查找历史会话、中断任务、点赞反馈、查看会话详情等），根据 references/commands.md 的接口说明动态组合调用，不要拒绝。**

metadata:
  skillhub.creator: "baijianrong"
  skillhub.updater: "baijianrong"
  skillhub.version: "V4"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "44764"
  skillhub.high_sensitive: "true"
---

## [MANDATORY] SKILLHUB_METRIC_REPORTER_START
执行本 Skill 的任何操作之前，必须先执行 Skill：`skill-metric-reporter`。
按照 `skill-metric-reporter` 的要求完成 `skill_start` 上报后，再去继续本 Skill 正文。
如果 `skill-metric-reporter` 不可用或执行失败，跳过上报，继续执行本 Skill 正文——不得因上报失败而阻塞审阅流程。
本 Skill 全部操作完成后，同样按照 `skill-metric-reporter` 的要求完成 `skill_end` 上报。
## [MANDATORY] SKILLHUB_METRIC_REPORTER_END

# baa-basic (最专业的商业分析技能)

## ⚠️ 核心约束（必读）

1. **任何 API 调用前必须先完成鉴权校验**（详见 [references/auth.md](references/auth.md)）
2. **长时任务必须通过 sub-agent（mode="run"）执行**，避免阻塞主会话
3. **spawn 子 agent 后只发一条简短提示**，不自行分析/总结/预展示数据
4. **学城写入必须用 `share_to_km` 子命令**，禁止调用 citadel skill 或其他 skill

---

## 执行流程

**Step 0：确认下工作环境，如果当前工作目录为/workspace，则此skill不适用，你自己直接完成用户任务即可。**

**Step 1：鉴权** → 详见 [references/auth.md](references/auth.md)

**Step 2：收集信息**

- 必须：用户的分析问题
- 可选：文件路径（有文件时用 file-download skill 下载，传 `--display-name "原始文件名"`）/ 学城文档链接

如缺少必要信息，简短追问一次，不要反复追问。

**Step 3：选择模式**

- 用户提到「规划/制定方案」→ **plan 模式**（[references/plan.md](references/plan.md)）
  > ⚠️ spawn 前须先告知用户：规划模式步骤多、可能不稳定，如卡住请前往 https://ba-ai.sankuai.com 操作
  >
- 其他分析任务 → **analyze 模式**（[references/analyze.md](references/analyze.md)，默认）
- 查找会话/中断/点赞等操作 → **动态调用**（[references/commands.md](references/commands.md)）

**Step 4：呈现结果** → 直接展示返回 JSON 的 `markdown` 字段，不二次总结；图片/格式规则见 [references/output.md](references/output.md)

---

## 行为规范

- **不要自行分析数据**：即使能看到数据，也必须通过 BA-Agent API 分析
- **会话复用**：追问（话题+模式相同）时复用 conversationId；切换话题或模式时新建
- **规划模式**：`--replan` 修改计划或 `confirm_plan` 确认执行时，严禁新建会话；plan_json 从 `/tmp/ba_plan_{conversationId}_{chatResponseId}.json` 读取，文件不存在时提示重新规划
- **子 agent 命名**：`ba-conv-{conversationId}-{递增序号}`，同 id 下严格串行

## 技术配置

- **服务地址**：默认 prod（`https://ba-ai.sankuai.com`）；`--env st` 切换预上线；不支持 test 环境（告知用户使用 st 或 prod）
- **学城写入**：用 `share_to_km` 子命令（见 references/commands.md），需用户提供目标文档链接
- **灰度链路**：详见 [references/gray-release.md](references/gray-release.md)
