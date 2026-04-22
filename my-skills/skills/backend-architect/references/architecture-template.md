# architecture.md 模板

生成架构文档时使用此模板。Mermaid 图必须体现请求从网关到数据库的完整链路。

---

```markdown
# 系统架构文档

> **版本**：v1.0 | **最后更新**：[日期]

---

## 系统概览

[2-3 句话描述系统核心职责和边界]

---

## 整体架构图

```mermaid
graph TD
    Client[客户端/前端] -->|HTTP/HTTPS| Gateway[API 网关/Nginx]
    Gateway -->|鉴权通过| Auth[鉴权中间件]
    Auth -->|注入 userId| Controller[Controller 层]
    Controller -->|调用| Service[Service 层]
    Service -->|读缓存| Redis[(Redis 缓存)]
    Redis -->|Cache Miss| DAO[DAO/Repository 层]
    DAO -->|SQL 查询| DB[(MySQL/PostgreSQL)]
    Service -->|异步任务| MQ[消息队列 MQ]
    MQ -->|消费| Worker[异步 Worker]
    Worker -->|写结果| DB
```

---

## 核心时序图

### [核心业务流程名] 时序

```mermaid
sequenceDiagram
    participant C as Client
    participant GW as Gateway
    participant SVC as Service
    participant Cache as Redis
    participant DB as Database

    C->>GW: POST /api/v1/[path]
    GW->>GW: 鉴权校验（JWT/Session）
    GW->>SVC: 转发请求（含 userId）
    SVC->>Cache: GET key:[id]
    alt Cache Hit
        Cache-->>SVC: 返回缓存数据
    else Cache Miss
        SVC->>DB: SELECT ... WHERE id = ?
        DB-->>SVC: 返回原始数据
        SVC->>Cache: SET key:[id] EX 300
    end
    SVC-->>GW: 返回响应
    GW-->>C: 200 OK
```

---

## 模块职责

### [模块名称]

**职责**：[该模块做什么，不做什么]

**关键类**：
- `[ClassName]`：[职责]
- `[ClassName]`：[职责]

**依赖关系**：依赖 [上游模块]，被 [下游模块] 依赖

---

## 数据库 ER 图

```mermaid
erDiagram
    TABLE_A {
        bigint id PK
        varchar name
        int status
        datetime create_time
    }
    TABLE_B {
        bigint id PK
        bigint a_id FK
        text content
    }
    TABLE_A ||--o{ TABLE_B : "has"
```

---

## 缓存策略

| 缓存 Key 格式 | TTL | 更新时机 | 降级策略 |
|--------------|-----|---------|---------|
| `[key:pattern]` | [秒] | [写操作后] | [降级行为] |

---

## 非共识技术决策记录

| 决策点 | 选择 | 原因 | 放弃的方案 |
|--------|------|------|-----------|
| [决策] | [选择] | [原因] | [备选] |
```
