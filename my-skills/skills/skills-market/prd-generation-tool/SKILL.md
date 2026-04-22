---
name: prd-generation-tool

description: 一个智能产品需求文档（PRD）撰写助手。根据产品目标、用户需求和市场调研信息，自动生成结构化 PRD 文档，明确功能模块、用户场景、业务流程和优先级，并提供可行性分析与风险提示，提高产品规划和团队沟通效率。

metadata:
  skillhub.creator: "zhangyuze04"
  skillhub.updater: "zhangyuze04"
  skillhub.version: "V1"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "19"
---

# 📝 智能产品需求文档 (PRD) 撰写助手

## Instructions

该技能采用结构化方法论，将初始产品输入转化为完整且可执行的 PRD。请遵循以下步骤生成文档：

1.  **输入解析 (Input Parsing):** 明确识别三个核心输入：**产品目标 (Product Goal)**、**用户需求 (User Needs)** 和 **市场/竞品信息 (Market/Competitive Data)**。

2.  **核心结构生成 (Core Structure Generation):**

    * **功能模块 (Feature Modules):** 根据输入，将相关的用户需求逻辑分组为不同的功能模块（例如：认证、任务管理、分析）。

    * **用户场景与故事 (User Scenarios & Stories):** 使用“作为一个 [用户角色]，我想 [目标]，以便 [价值]”的格式详细描述关键用户互动。

    * **业务/系统流程 (Business/System Flow):** 描述关键互动的分步序列，从用户触发到系统响应。

3.  **约束与决策 (Constraints and Decisions):**

    * **优先级 (Prioritization):** 基于产品目标和资源限制（如果提供），为每个功能分配明确的优先级（例如：高/中/低，或 MoSCoW 方法）。

4.  **专业分析与评估 (Professional Analysis and Assessment):**

    * **可行性分析 (Feasibility Analysis):** 简要评估核心功能的技术复杂度和预估工作量。

    * **潜在风险与对策 (Potential Risk Mitigation):** 识别潜在的项目风险（如：技术债、范围蔓延、集成问题）并提供高层级的缓解策略。

5.  **文档交付 (Document Delivery):** 以清晰、高度结构化的格式呈现输出结果，确保内容完整、清晰且便于开发、设计和质量保证团队执行和沟通。