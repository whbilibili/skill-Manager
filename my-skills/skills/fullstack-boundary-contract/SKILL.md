---
name: fullstack-boundary-contract
description: 前后端功能边界契约生成器。在需求拆解阶段，分析 PRD 或用户故事，逐条判断每个功能点的归属（前端/后端/协作），生成一份前后端双方认可的"功能边界契约文档"，并分别输出前端架构师和后端架构师的任务 breakdown。当用户提到"前后端分工"、"功能边界"、"接口契约"、"前后端拆解任务"、"谁来做这个功能"、"前后端职责划分"、"fullstack boundary"、"API contract"、"前后端协作规范"时使用。不适用于：已有明确接口文档只需格式化的场景（用 backend-to-frontend-handoff-docs）；纯接口 schema 生成（用 openapi-contract）。
---

# Fullstack Boundary Contract

前后端功能边界契约生成器。输入需求，输出三份文档：**功能边界契约**、**前端任务 Breakdown**、**后端任务 Breakdown**。

## 工作流

### Phase 1：需求解析

读取用户提供的需求（PRD、用户故事、功能描述均可）。若以下信息缺失，先提问：

- 技术栈是什么？（影响边界判断，如 SSR/CSR、BFF 层是否存在）
- 是否有 BFF（Backend for Frontend）层？
- 安全等级要求？（影响鉴权、数据校验的归属）

### Phase 2：功能归属决策

逐条分析每个功能点，按 [DECISION-RULES.md](DECISION-RULES.md) 中的规则判断归属，输出决策表：

```
| 功能点 | 归属 | 决策理由 | 接口依赖 |
|--------|------|----------|----------|
| 用户登录表单校验 | 前端 | 纯 UI 交互，无需持久化 | — |
| 登录凭证验证 | 后端 | 涉及密钥比对，不可暴露在客户端 | POST /auth/login |
| 记住登录状态 | 前后端协作 | 前端存 token，后端签发/验证 | POST /auth/refresh |
```

归属类型：
- **前端（FE）**：纯展示、交互状态、客户端缓存、UI 校验
- **后端（BE）**：数据持久化、鉴权/权限、业务规则、防刷/限流、敏感计算
- **协作（FE+BE）**：需要接口配合，前后端各有职责

### Phase 3：生成三份输出物

按 [TEMPLATE.md](TEMPLATE.md) 中的模板生成：

1. **`boundary-contract.md`** — 功能边界契约（前后端双方共同签认的基准文档）
2. **`fe-tasks.md`** — 前端架构师任务 Breakdown
3. **`be-tasks.md`** — 后端架构师任务 Breakdown

文件默认输出到 `.claude/contracts/<feature-name>/` 目录。

### Phase 4：契约确认

输出完成后，询问用户：

> 以上边界划分是否符合预期？如有调整，请指出具体功能点，我将更新契约并同步两份任务清单。

---

## 关键决策原则（速查）

**必须后端**：密码/密钥处理、权限校验、金额计算、数据落库、发送通知（邮件/短信）、防刷限流、跨用户数据聚合

**必须前端**：表单 UI 校验（非业务规则）、页面路由、动画/过渡、本地状态管理、无障碍属性、骨架屏/Loading 状态

**通常协作**：分页列表（前端渲染+后端分页接口）、搜索（前端输入+后端全文检索）、文件上传（前端选择+后端存储）、实时数据（前端 WebSocket 连接+后端推送）

完整决策规则见 [DECISION-RULES.md](DECISION-RULES.md)。

---

## 输出物说明

生成的三份文档互相引用，形成完整的协作基准：

- `boundary-contract.md` 是**唯一真相来源**，前后端任何争议以此为准
- `fe-tasks.md` 和 `be-tasks.md` 均引用契约中的接口定义，保持一致性
- 契约变更时，三份文档需同步更新

输出物模板见 [TEMPLATE.md](TEMPLATE.md)。
