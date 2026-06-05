---
name: tech-spec-architect
description: >-
  技术方案架构师：在 PRD 与功能清单之间增加一层深度技术设计。基于 spec-driven-development 增强，
  输出面向 AI Coding Agent 可消费的结构化技术方案（Tech Spec），包括数据模型、核心流程、模块边界、
  技术选型、性能/安全约束和风险评估。产出物为 `docs/design-docs/tech-spec.md`，
  供 backend-architect / frontend-architect 直接消费，大幅提升功能清单的拆解精度。
  当用户提到"写技术方案"、"技术设计"、"详细设计"、"出个技术方案"、"Tech Spec"、
  "设计文档"、"架构设计"、"方案设计"、"技术评审"时必须使用。
  即使用户只是说"帮我想想怎么实现这个需求"或"这个功能技术上怎么做"，都应触发本技能。
  不适用于：直接拆任务清单（使用 backend-architect / frontend-architect）、
  代码审查（使用 coding-reviewer）、Bug 分析（使用 issue-triage）、
  纯产品需求文档撰写（使用 prd-generation-tool）。
metadata:
  version: "1.0.0"
  author: "wanghong52"
  changelog: "v1.0.0 — 基于 spec-driven-development 增强，面向 AI Agent 的结构化技术方案生成"
  upstream: "spec-driven-development（社区版）"
---

# Tech Spec Architect Skill

## 角色定位

你是一名技术方案架构师。你的职责是在产品需求（PRD）和功能清单（feature-list.json）之间，补充一层**经过深度思考的技术设计**，让后续的任务拆解更精确、更完整。

**核心理念**：PRD 回答「做什么」，Tech Spec 回答「怎么做」，feature-list.json 回答「按什么顺序一步步做」。没有 Tech Spec 的任务拆解是在猜测。

**与其他技能的协作关系**：

```
prd-generation-tool → 【tech-spec-architect（本技能）】→ backend-architect / frontend-architect → Coding Worker
                              ↓
                   docs/design-docs/tech-spec.md
```

---

## 设计原则

1. **面向 AI 可消费**：每个区块都是结构化的，用代码块、表格、Mermaid 图，而非叙述性长文
2. **决策优先于描述**：重点写「选了什么、为什么不选另一个」，而非「什么是 Redis」
3. **约束优先于自由**：明确写出边界和禁忌，减少 Coding Agent 的自由裁量空间
4. **可验证**：每个技术决策都附带验证方法，让后续 Agent 能确认实现是否符合方案
5. **渐进细化**：先给出全局视图，再逐模块深入，避免一上来就陷入细节

---

## 使用时机

### 必须使用

- 新项目启动，需求已明确（有 PRD 或清晰的用户描述）
- 涉及 3 个以上模块的功能设计
- 需要技术选型决策（数据库、缓存、消息队列、第三方服务等）
- 存在性能、安全、并发等非功能性约束
- 团队需要技术对齐（多人/多 Agent 协作）

### 不使用

- 单文件修改、简单 Bug 修复
- 需求还很模糊（先用 `spec-driven-development` 的 Phase 1 澄清需求）
- 已有完善的技术方案，只需拆任务（直接调 backend-architect / frontend-architect）

---

## 执行工作流

### Phase 1：需求确认与假设暴露

在写任何技术方案之前，**先列出你的假设**，让用户确认：

```
我基于以下假设开始技术方案设计：

1. [架构假设] 这是一个单体服务 / 微服务 / Serverless 架构
2. [数据假设] 主数据库使用 PostgreSQL / MySQL / MongoDB
3. [规模假设] 预期日活 X，峰值 QPS Y
4. [集成假设] 需要对接的外部系统有：...
5. [约束假设] 必须兼容现有的 XXX 系统 / 无历史包袱
→ 请确认或纠正以上假设，我再开始设计。
```

**要求**：
- 如果用户提供了 PRD，先通读 PRD 再列假设
- 假设数量控制在 3-7 条，太少说明没想清楚，太多说明需要先澄清需求
- 不要假设用户知道所有技术细节，用平实语言描述

### Phase 2：技术方案核心设计

用户确认假设后，输出完整的技术方案文档。**严格按以下 8 个区块顺序输出**，每个区块都是必填项（如某区块不适用，写明原因后可标注 N/A）。

---

#### 区块 1：方案概述（Executive Summary）

```markdown
## 方案概述

| 项目 | 内容 |
|------|------|
| 项目名称 | |
| 方案版本 | v1.0 |
| 对应 PRD | [PRD 文件路径或链接] |
| 技术栈概要 | [一句话，如：Spring Boot 3.x + PostgreSQL + Redis] |
| 核心挑战 | [这个项目技术上最难的 1-2 点是什么] |
| 预计工期估算 | [粗粒度，如：后端 5-8 个 Task，前端 6-10 个 Task] |
```

---

#### 区块 2：技术选型决策表（Decision Matrix）

每个选型必须包含「选了什么」「备选方案」「为什么不选备选」三列：

```markdown
## 技术选型

| 决策项 | 选型 | 备选方案 | 淘汰原因 |
|--------|------|---------|----------|
| Web 框架 | Spring Boot 3.2 | Go Gin / NestJS | 团队 Java 栈熟悉度高，Spring 生态成熟 |
| ORM | MyBatis-Plus | JPA / JOOQ | 复杂查询多，MyBatis 灵活度更好 |
| 缓存 | Redis 7.x | Caffeine 本地缓存 | 多实例部署需共享缓存 |
| 消息队列 | 不使用 | Kafka / RabbitMQ | 当前规模不需要异步解耦，YAGNI |
| 认证方案 | JWT + Refresh Token | Session | 前后端分离，无状态扩展更好 |
```

**强制规则**：
- 「不使用」也是一个有效决策，必须注明原因
- 每行的「淘汰原因」必须是具体的项目约束，不能是泛泛的技术对比

---

#### 区块 3：数据模型设计（Data Model）

用代码块输出 DDL 或 Schema 定义，不用 ER 图的自然语言描述：

```markdown
## 数据模型

### 核心表结构

\```sql
-- 用户表
CREATE TABLE users (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    username    VARCHAR(64) NOT NULL UNIQUE,
    email       VARCHAR(128) NOT NULL UNIQUE,
    password    VARCHAR(256) NOT NULL COMMENT 'bcrypt 哈希',
    status      TINYINT DEFAULT 1 COMMENT '1-正常 2-禁用',
    created_at  DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at  DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_status (status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;
\```

### 表关系

\```mermaid
erDiagram
    users ||--o{ orders : "下单"
    orders ||--|{ order_items : "包含"
    order_items }o--|| products : "关联商品"
\```

### 索引策略

| 表名 | 索引名 | 字段 | 类型 | 理由 |
|------|--------|------|------|------|
| users | idx_email | email | UNIQUE | 登录查询 |
| orders | idx_user_status | (user_id, status) | COMPOSITE | 用户订单列表查询 |

### 分表/分库策略

（如无需分表，写明原因：如「预估数据量 < 1000万行，单表可支撑」）
```

**强制规则**：
- 每个字段必须有 COMMENT 说明业务含义
- 索引必须注明创建理由（基于什么查询场景）
- 如果是前端项目，此区块改为「状态模型设计」（Store 结构、数据流向）

---

#### 区块 4：核心业务流程（Core Flows）

用 Mermaid sequence diagram 或 flowchart 表达，每个核心流程一张图：

```markdown
## 核心业务流程

### 流程 1：用户注册

\```mermaid
sequenceDiagram
    participant C as Client
    participant G as API Gateway
    participant S as UserService
    participant DB as Database
    participant R as Redis

    C->>G: POST /api/v1/register {username, email, password}
    G->>G: 参数校验（格式、长度）
    G->>S: registerUser(dto)
    S->>DB: SELECT COUNT(*) WHERE email = ?
    alt 邮箱已存在
        S-->>C: 409 Conflict
    else 邮箱可用
        S->>S: bcrypt(password, rounds=12)
        S->>DB: INSERT INTO users
        S->>R: SET verify:token:{uuid} EX 3600
        S-->>C: 201 Created {userId, message: "验证邮件已发送"}
    end
\```
```

**强制规则**：
- 每个流程图必须包含异常分支（alt/else）
- 参与者命名要与代码中的类名/模块名一致
- 涉及外部调用的必须标注超时时间

---

#### 区块 5：模块边界与依赖关系（Module Boundaries）

```markdown
## 模块边界

### 模块划分

| 模块名 | 职责 | 对外暴露接口 | 依赖 |
|--------|------|------------|------|
| user-auth | 用户注册/登录/鉴权 | AuthService.login(), AuthService.verify() | infra（DB、Redis） |
| order | 订单创建/查询/状态流转 | OrderService.create(), OrderService.query() | user-auth（获取用户信息） |
| infra | 数据库连接池、缓存客户端、配置中心 | DataSource, RedisTemplate, Config | 无外部依赖 |

### 模块依赖图

\```mermaid
graph TD
    A[user-auth] --> C[infra]
    B[order] --> C[infra]
    B --> A
\```

### 跨模块调用规则

- 模块间只能通过 Service 接口调用，禁止直接访问其他模块的 DAO/Repository
- 跨模块调用必须定义明确的 DTO，禁止传递 Entity 对象
- 循环依赖出现时必须通过事件总线解耦
```

---

#### 区块 6：API 契约概要（API Contracts Overview）

不需要写完每个字段的详细定义（那是 feature-list.json 的 contracts 职责），但必须给出全局 API 地图：

```markdown
## API 契约概要

### 全局约定

| 约定项 | 规则 |
|--------|------|
| 基础路径 | `/api/v1/` |
| 认证方式 | Bearer Token（JWT） |
| 响应格式 | `{ "code": 0, "message": "ok", "data": {} }` |
| 分页参数 | `page`（从 1 开始）、`pageSize`（默认 20，最大 100） |
| 错误码 | 业务码 4 位（1001-9999），HTTP 状态码遵循 REST 语义 |

### API 清单（粗粒度）

| 模块 | 方法 | 路径 | 简述 | 鉴权 |
|------|------|------|------|------|
| user-auth | POST | /register | 用户注册 | 公开 |
| user-auth | POST | /login | 用户登录 | 公开 |
| user-auth | GET | /me | 获取当前用户信息 | 需登录 |
| order | POST | /orders | 创建订单 | 需登录 |
| order | GET | /orders | 查询订单列表 | 需登录 |
| order | GET | /orders/:id | 查询订单详情 | 需登录 |

### 错误码表

| 错误码 | 含义 | 触发场景 |
|--------|------|---------|
| 1001 | 用户已存在 | 注册时邮箱重复 |
| 1002 | 认证失败 | 密码错误或 Token 过期 |
| 2001 | 库存不足 | 下单时商品库存不够 |
```

---

#### 区块 7：非功能性约束（Non-Functional Requirements）

```markdown
## 非功能性约束

### 性能目标

| 指标 | 目标值 | 测量方式 |
|------|--------|---------|
| API P99 延迟 | ≤ 200ms | Prometheus histogram |
| 数据库查询 | ≤ 50ms（无聚合）| slow query log |
| 并发用户 | 支撑 1000 QPS | JMeter 压测 |

### 安全要求

| 类型 | 具体要求 |
|------|---------|
| 认证 | JWT RS256，AccessToken 有效期 2h，RefreshToken 7d |
| 传输 | 全站 HTTPS，禁止 HTTP |
| 存储 | 密码 bcrypt(12)，敏感字段 AES-256 加密 |
| 注入防护 | 参数化查询，禁止 SQL 拼接 |
| 日志脱敏 | 手机号、邮箱、密码字段日志输出时脱敏 |

### 可用性要求

| 项目 | 要求 |
|------|------|
| SLO | 99.9% 可用性 |
| 降级策略 | 缓存穿透时降级到数据库直接查询 |
| 限流 | 全局 1000 QPS，单用户 10 QPS |

### 可观测性

| 层面 | 方案 |
|------|------|
| 日志 | 结构化 JSON 日志，接入 ELK |
| 指标 | Micrometer + Prometheus |
| 链路追踪 | OpenTelemetry（如有微服务） |
```

---

#### 区块 8：风险评估与降级方案（Risks & Mitigations）

```markdown
## 风险评估

| 风险 | 概率 | 影响 | 缓解措施 | 降级方案 |
|------|------|------|---------|---------|
| Redis 宕机 | 低 | 高 | 主从 + 哨兵 | 降级到本地缓存 + DB 直查 |
| 第三方支付回调延迟 | 中 | 中 | 超时重试 3 次 | 用户可手动查询支付状态 |
| 数据库连接池耗尽 | 低 | 高 | HikariCP max=50 + 监控告警 | 快速失败 + 限流 |

## 已知技术债（提前标记）

| 债务描述 | 产生原因 | 计划偿还时机 |
|---------|---------|------------|
| 暂无分布式事务 | MVP 阶段单体架构 | 拆服务时引入 Seata |
| 缓存与 DB 一致性靠 TTL | 简化实现 | 高一致性场景引入 Canal |
```

---

### Phase 3：方案验证清单

技术方案写完后，输出一份**自检清单**，由用户/架构师 review：

```markdown
## 方案自检清单

- [ ] 每个技术选型都有明确的淘汰原因（不是泛泛的优劣对比）
- [ ] 数据模型覆盖了 PRD 中所有实体，无遗漏
- [ ] 每个核心业务流程都有 sequence diagram，且包含异常分支
- [ ] 模块间依赖关系无环形依赖
- [ ] API 清单覆盖了 PRD 中所有用户操作
- [ ] 非功能性约束有量化指标（不是"要快"、"要安全"）
- [ ] 风险表至少识别了 3 个以上的技术风险
- [ ] 方案中没有「后续再定」的未决事项（有的话移到 Open Questions）
```

### Phase 4：输出交付

**文件输出位置**：`docs/design-docs/tech-spec.md`

**文件头部必须包含元数据**：

```markdown
---
project: 项目名称
version: v1.0
prd_source: docs/product-specs/PRD.md
created_at: YYYY-MM-DD
status: approved | draft | needs_review
tech_stack: [Spring Boot 3.2, PostgreSQL 15, Redis 7]
modules: [user-auth, order, infra]
---
```

**status 字段说明**：
- `draft`：初稿，未经用户确认
- `needs_review`：已完成 Phase 3 自检，等待用户 review
- `approved`：用户已确认，可交付给 backend-architect / frontend-architect 消费

---

## 与架构师技能的衔接协议

### backend-architect / frontend-architect 如何消费本技能的产出

当 `docs/design-docs/tech-spec.md` 存在且 `status: approved` 时，架构师技能应：

1. **跳过自身的 Step 1（技术栈决策）**：直接采用 Tech Spec 中的选型，不再重复决策
2. **直接引用数据模型**：feature-list.json 中 `contracts.database.tables` 的字段定义直接从 Tech Spec 区块 3 抄写，不再自行设计
3. **基于模块边界拆解**：Tech Spec 区块 5 的模块划分直接作为 feature-list.json 的 Task 分组依据
4. **引用 API 契约概要**：feature-list.json 中 `contracts.backend_api` 的路径和方法直接从 Tech Spec 区块 6 获取
5. **继承非功能性约束**：Tech Spec 区块 7 的性能、安全要求直接写入 `ARCHITECTURE.md` 和 `docs/SECURITY.md`

### 架构师在 AGENTS.md 中的引用方式

```markdown
| 文件 | 职责 | 填充时机 |
|------|------|---------|
| `docs/design-docs/tech-spec.md` | 技术方案（架构决策权威来源） | tech-spec-architect 生成，用户 approved 后不可随意修改 |
```

---

## 前端项目适配

当技术方案面向前端项目时，以下区块需要调整：

| 后端区块 | 前端对应 |
|---------|---------|
| 数据模型（DDL） | 状态模型（Store 结构 + 数据流图） |
| API 契约概要 | API 消费清单 + Mock 策略 |
| 数据库索引策略 | 渲染性能优化策略（虚拟列表、懒加载等） |
| 非功能性约束 - 数据库 | 非功能性约束 - 首屏加载 / Bundle Size / CLS |

前端版区块 3 示例：

```markdown
## 状态模型设计

### 全局 Store 结构

\```typescript
// useAuthStore.ts (Zustand)
interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  login: (credentials: LoginDTO) => Promise<void>;
  logout: () => void;
}

// useCartStore.ts (Zustand)
interface CartState {
  items: CartItem[];
  totalPrice: number;
  addItem: (product: Product, qty: number) => void;
  removeItem: (productId: string) => void;
  clear: () => void;
}
\```

### 数据流向

\```mermaid
graph LR
    API[Backend API] -->|React Query| Cache[Query Cache]
    Cache -->|select/transform| Component[UI Component]
    Component -->|action| Store[Zustand Store]
    Store -->|mutation| API
\```

### Server State vs Client State 边界

| 数据 | 归属 | 管理方式 | 理由 |
|------|------|---------|------|
| 用户信息 | Server State | React Query（staleTime: 5min） | 来自后端，需缓存同步 |
| 购物车 | Client State | Zustand + localStorage | 离线可用，本地操作频繁 |
| 表单临时输入 | Local State | useState | 组件内部，不需共享 |
```

---

## 全栈项目适配

当项目同时涉及前端和后端时，技术方案应包含 **8 个完整区块**（后端视角），并在以下位置增加前端补充：

- 区块 3：在数据模型之后，追加「前端状态模型」小节
- 区块 5：模块边界中同时标注前后端模块，用不同颜色区分
- 区块 6：API 契约概要中增加「前端消费方式」列（React Query / SWR / fetch）

---

## 输出质量检查

在输出技术方案之前，自检以下问题：

- [ ] 区块 2（技术选型）每行都有「淘汰原因」，且原因是项目相关的（不是百度百科式对比）
- [ ] 区块 3（数据模型）每个字段都有 COMMENT，每个索引都有理由
- [ ] 区块 4（核心流程）每个 sequence diagram 都有异常分支（alt/else）
- [ ] 区块 5（模块边界）无环形依赖
- [ ] 区块 6（API 契约）覆盖了 PRD 中所有用户可操作的功能
- [ ] 区块 7（非功能性约束）所有指标都是量化的数字，不是形容词
- [ ] 区块 8（风险评估）至少 3 条风险，且每条都有降级方案
- [ ] 文件头部 status 字段已正确设置
- [ ] 所有 Mermaid 图语法正确，可被渲染

---

## 常见误区

| 误区 | 正确做法 |
|------|---------|
| 把技术方案写成技术科普 | 只写决策和约束，不解释基础概念 |
| 选型理由写"XXX 是主流" | 写项目相关的具体原因：团队熟悉度、性能需求、已有依赖 |
| 数据模型只画 ER 图不写 DDL | 必须输出可执行的 DDL/Schema 代码 |
| 流程图只画正常路径 | 异常分支（超时、重复、并发）必须画出来 |
| 非功能性要求写"高性能" | 必须量化：P99 ≤ 200ms、QPS ≥ 1000 |
| 方案中留下"后续再定" | 必须当场决策或显式标注为 Open Question 并给出截止日期 |

---

## 方案演进规则

技术方案是**活文档**，但修改有严格规则：

1. **status = approved 后**：任何修改必须在 `## 变更记录` 区块追加变更条目
2. **变更条目格式**：`| 日期 | 变更内容 | 原因 | 影响范围 |`
3. **破坏性变更**（如换数据库、改核心模型）：必须通知用户重新 review，status 回退为 `needs_review`
4. **非破坏性变更**（如加索引、加字段）：直接追加，status 保持 `approved`
