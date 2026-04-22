# ARCHITECTURE.md 模板（全栈版）

生成架构文档时使用此模板。Mermaid 图必须体现从用户交互到数据持久化的完整链路。

---

```markdown
# 系统架构文档

> **版本**：v1.0 | **最后更新**：[日期]

---

## 系统概览

[2-3 句话描述系统核心职责和边界]

---

## 整体架构图

### 全栈框架模式（Next.js / Remix / SvelteKit 等）

```mermaid
graph TD
    Browser[浏览器] -->|HTTP Request| Framework[框架 Router<br/>Next.js / Remix / SvelteKit]
    Framework -->|Server Component / Loader| ServerLayer[Server 层]
    Framework -->|Client Component| ClientLayer[客户端]

    ClientLayer -->|React Query / SWR| Hooks[数据 Hook 层]
    Hooks -->|fetch / tRPC| APIRoutes[API Routes / Server Actions / tRPC]

    ServerLayer -->|直接调用| ORM[ORM 层<br/>Prisma / Drizzle]
    APIRoutes -->|调用| ORM

    ORM -->|SQL| DB[(数据库<br/>PostgreSQL / SQLite)]

    ServerLayer -->|认证| Auth[Auth Provider<br/>NextAuth / Clerk]
    APIRoutes -->|中间件| Auth

    subgraph 客户端
        ClientLayer
        Hooks
    end

    subgraph 服务端
        ServerLayer
        APIRoutes
        ORM
        Auth
    end
```

### BaaS 模式（Supabase / Convex / Firebase）

```mermaid
graph TD
    Browser[浏览器] -->|Client SDK| BaaSClient[BaaS 客户端<br/>Supabase / Convex / Firebase]
    Browser -->|React Component| UI[UI 组件层]
    UI -->|useQuery / subscribe| DataHook[数据 Hook 层]
    DataHook -->|SDK 调用| BaaSClient

    BaaSClient -->|Auth| AuthService[认证服务]
    BaaSClient -->|Query + RLS| Database[(数据库<br/>PostgreSQL / Convex DB / Firestore)]
    BaaSClient -->|Storage| Storage[(文件存储)]

    ServerFn[Edge Functions /<br/>Convex Actions] -->|服务端逻辑| Database
    BaaSClient -->|触发| ServerFn

    subgraph BaaS 平台
        AuthService
        Database
        Storage
        ServerFn
    end

    subgraph 客户端应用
        UI
        DataHook
        BaaSClient
    end
```

---

## 核心数据流时序图

### [核心业务流程名] — 全栈框架模式

```mermaid
sequenceDiagram
    participant U as 用户/浏览器
    participant P as Page（Server Component）
    participant A as API Route / Server Action
    participant M as 中间件（Auth）
    participant O as ORM（Prisma/Drizzle）
    participant D as Database

    U->>P: 访问 /[path]
    P->>M: 检查认证状态
    M-->>P: 返回 session
    P->>O: 查询初始数据
    O->>D: SELECT ...
    D-->>O: 返回结果
    O-->>P: 返回类型化数据
    P-->>U: 渲染 HTML + Hydration

    Note over U: 用户交互触发 mutation

    U->>A: POST /api/[action]
    A->>M: 验证 Auth Token
    M-->>A: userId
    A->>O: 执行写操作
    O->>D: INSERT/UPDATE ...
    D-->>O: 确认
    O-->>A: 返回结果
    A-->>U: 200 OK + 新数据
```

### [核心业务流程名] — BaaS 模式

```mermaid
sequenceDiagram
    participant U as 用户/浏览器
    participant C as 客户端组件
    participant H as useQuery Hook
    participant S as BaaS SDK
    participant Auth as Auth Service
    participant DB as BaaS Database

    U->>C: 访问页面
    C->>H: 调用 useQuery / useConvexQuery
    H->>S: SDK.from('table').select()
    S->>Auth: 附加 Auth Token
    Auth-->>S: 验证通过 + RLS 策略
    S->>DB: 执行查询（RLS 过滤）
    DB-->>S: 返回数据
    S-->>H: 返回类型化结果
    H-->>C: 更新 UI

    Note over U: 用户提交表单

    U->>C: 触发 mutation
    C->>S: SDK.from('table').insert(data)
    S->>Auth: 验证权限
    Auth-->>S: RLS 检查通过
    S->>DB: INSERT
    DB-->>S: 确认 + 实时推送
    S-->>C: 返回新记录
    S-->>H: 自动更新订阅
```

---

## 数据库 Schema

```mermaid
erDiagram
    TABLE_A {
        uuid id PK
        text name
        int status
        timestamp created_at
        timestamp updated_at
    }
    TABLE_B {
        uuid id PK
        uuid a_id FK
        text content
        uuid user_id FK
    }
    USER {
        uuid id PK
        text email
        text name
        timestamp created_at
    }
    TABLE_A ||--o{ TABLE_B : "has many"
    USER ||--o{ TABLE_B : "owns"
```

---

## 环境变量

### 客户端可见（安全）

| 变量名 | 说明 | 示例 |
|--------|------|------|
| `NEXT_PUBLIC_SUPABASE_URL` | BaaS 端点 | `https://xxx.supabase.co` |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | BaaS 匿名公钥 | `eyJhbG...` |

### 服务端专用（敏感）

| 变量名 | 说明 | 绝不暴露给客户端 |
|--------|------|-----------------|
| `DATABASE_URL` | 数据库连接串 | ✅ |
| `SUPABASE_SERVICE_ROLE_KEY` | BaaS 管理密钥 | ✅ |
| `AUTH_SECRET` | 认证签名密钥 | ✅ |

---

## 模块职责

### [模块名称]

**职责**：[该模块做什么，不做什么]

**关键文件**：
- `[文件路径]`：[职责]
- `[文件路径]`：[职责]

**数据依赖**：操作 [表名/集合名]，被 [下游模块] 消费

---

## 非共识技术决策记录

| 决策点 | 选择 | 原因 | 放弃的方案 |
|--------|------|------|-----------|
| [决策] | [选择] | [原因] | [备选] |
```
