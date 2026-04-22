# 全栈技术栈模式参考

本文件收录常见全栈技术栈的目录结构模式和关键配置决策点，供架构师在 Step 1 做技术栈决策时参考。

---

## 模式 A：Next.js App Router + Prisma（全栈框架典型）

**适用场景**：需要 SSR/SSG、SEO 友好、有自己的数据库、中等复杂度

```
project/
├── app/
│   ├── layout.tsx              ← 根布局
│   ├── page.tsx                ← 首页
│   ├── api/                    ← API Routes
│   │   └── [resource]/
│   │       └── route.ts
│   ├── (auth)/                 ← 认证路由组
│   │   ├── login/page.tsx
│   │   └── register/page.tsx
│   └── dashboard/
│       ├── layout.tsx
│       └── page.tsx
├── components/
│   ├── ui/                     ← 基础 UI 组件（shadcn-ui）
│   └── [feature]/              ← 按功能组织的业务组件
├── hooks/                      ← 自定义 Hook
├── lib/
│   ├── db.ts                   ← Prisma Client 实例（singleton）
│   ├── auth.ts                 ← NextAuth 配置
│   └── utils.ts
├── prisma/
│   ├── schema.prisma           ← Schema 定义
│   └── migrations/             ← 迁移文件
├── types/                      ← 共享类型定义
└── public/
```

**关键决策**：
- Server Components 直接调用 Prisma，无需额外 API 层
- Client Components 通过 Server Actions 或 API Routes 访问数据
- `lib/db.ts` 导出的 Prisma Client 只能在服务端 import

---

## 模式 B：T3 Stack（Next.js + tRPC + Prisma + NextAuth）

**适用场景**：端到端类型安全、团队熟悉 TypeScript、中大型项目

```
project/
├── src/
│   ├── app/                    ← Next.js App Router
│   ├── server/
│   │   ├── api/
│   │   │   ├── routers/        ← tRPC Routers
│   │   │   │   ├── post.ts
│   │   │   │   └── user.ts
│   │   │   ├── root.ts         ← Root Router
│   │   │   └── trpc.ts         ← tRPC 初始化 + Context
│   │   ├── auth.ts             ← NextAuth 配置
│   │   └── db.ts               ← Prisma Client
│   ├── trpc/                   ← 客户端 tRPC 配置
│   │   ├── react.tsx           ← React Query 集成
│   │   └── server.ts           ← Server-side caller
│   ├── components/
│   ├── hooks/
│   └── types/
├── prisma/
│   └── schema.prisma
└── ...
```

**关键决策**：
- tRPC 提供端到端类型安全，替代手写 REST API
- React Query 由 tRPC 自动管理，不需要手动配置
- Server-side caller 允许在 Server Components 中直接调用 tRPC

---

## 模式 C：React/Next.js + Supabase（BaaS 典型）

**适用场景**：快速上线、不想运维数据库、需要实时功能、个人/小团队项目

```
project/
├── app/                        ← Next.js App Router
│   ├── layout.tsx
│   ├── page.tsx
│   ├── auth/
│   │   ├── login/page.tsx
│   │   ├── callback/route.ts   ← OAuth 回调
│   │   └── confirm/route.ts    ← Email 确认
│   └── dashboard/
│       └── page.tsx
├── components/
├── hooks/
│   └── use-supabase.ts         ← Supabase 客户端 Hook
├── lib/
│   ├── supabase/
│   │   ├── client.ts           ← 浏览器端 Client（anon key）
│   │   ├── server.ts           ← 服务端 Client（service role key）
│   │   └── middleware.ts       ← Auth middleware
│   └── utils.ts
├── supabase/
│   ├── config.toml             ← 本地开发配置
│   ├── migrations/             ← SQL 迁移文件
│   └── seed.sql                ← 种子数据
├── types/
│   └── supabase.ts             ← 自动生成的类型（npx supabase gen types）
└── ...
```

**关键决策**：
- 区分 `client.ts`（客户端，anon key + RLS）和 `server.ts`（服务端，service role key）
- RLS 策略是安全的核心，每张表必须配置
- 类型由 `supabase gen types typescript` 自动生成，不手写
- 实时订阅通过 `supabase.channel()` 实现

---

## 模式 D：React + Convex（实时 BaaS）

**适用场景**：需要强实时性、自动缓存更新、TypeScript 全栈、快速原型

```
project/
├── app/                        ← Next.js / Vite React
│   ├── layout.tsx
│   └── page.tsx
├── components/
├── convex/
│   ├── _generated/             ← 自动生成（API 类型、data model）
│   ├── schema.ts               ← Schema 定义（Convex validator）
│   ├── auth.config.ts          ← 认证配置
│   ├── [module].ts             ← Query + Mutation 函数
│   │   ├── // export const get = query(...)
│   │   └── // export const create = mutation(...)
│   └── http.ts                 ← HTTP endpoint（可选）
├── hooks/
│   └── use-[feature].ts
├── lib/
│   └── convex.ts               ← ConvexProvider 配置
└── ...
```

**关键决策**：
- Convex 函数（query/mutation/action）定义在 `convex/` 目录，自动部署
- `useQuery` 自动订阅实时更新，无需手动管理缓存
- Convex 不支持 SQL JOIN，复杂查询用 `.collect()` + JS 聚合
- Schema 使用 Convex validator（`v.string()`, `v.number()` 等），不是 SQL DDL
- 文件存储通过 `storage.getUrl()` 获取

---

## 模式 E：Remix + Prisma

**适用场景**：重表单应用、需要渐进增强、偏好 Web 标准

```
project/
├── app/
│   ├── root.tsx                ← 根布局
│   ├── routes/
│   │   ├── _index.tsx          ← 首页
│   │   ├── dashboard.tsx       ← 布局路由
│   │   ├── dashboard._index.tsx
│   │   └── api.[resource].ts  ← Resource Routes
│   ├── components/
│   ├── models/                 ← 数据访问层（封装 Prisma 调用）
│   │   └── user.server.ts
│   └── utils/
│       ├── db.server.ts        ← Prisma Client（.server 后缀确保不打入客户端）
│       └── session.server.ts   ← Session 管理
├── prisma/
│   └── schema.prisma
└── ...
```

**关键决策**：
- `.server.ts` 后缀确保模块不打入客户端 bundle
- Loader（GET）和 Action（POST）是数据获取/变更的唯一入口
- 表单提交通过原生 `<form>` + `useFetcher`，支持渐进增强
- 不需要 React Query — Remix 内置了数据 revalidation

---

## 模式 F：Astro + Cloudflare Workers + D1

**适用场景**：内容优先站点 + 轻量 API、全球边缘部署

```
project/
├── src/
│   ├── pages/
│   │   ├── index.astro
│   │   └── api/                ← API 端点（运行在 Cloudflare Workers）
│   │       └── [resource].ts
│   ├── components/
│   │   ├── static/             ← Astro 组件（零 JS）
│   │   └── interactive/        ← React/Vue 岛屿组件
│   ├── layouts/
│   └── lib/
│       └── db.ts               ← D1 Client
├── migrations/                 ← D1 迁移文件
├── wrangler.toml               ← Cloudflare 配置
└── ...
```

**关键决策**：
- 静态页面用 Astro 组件（零 JS），交互部分用 React/Vue 岛屿
- D1 是 SQLite 兼容的边缘数据库
- API 端点通过 `context.locals.runtime.env.DB` 访问 D1

---

## 技术栈选型决策树

```
需求分析
├── 需要 SSR/SEO？
│   ├── 是 → 需要端到端类型安全？
│   │   ├── 是 → T3 Stack（模式 B）
│   │   └── 否 → Next.js + Prisma（模式 A）
│   └── 否（SPA 即可）
│       ├── 需要实时数据？
│       │   ├── 是 → React + Convex（模式 D）
│       │   └── 否 → React + Supabase（模式 C）
│       └── 内容优先站点？
│           └── 是 → Astro + D1（模式 F）
├── 不想运维数据库？
│   ├── 需要实时订阅？ → Convex（模式 D）
│   ├── 需要 PostgreSQL 功能？ → Supabase（模式 C）
│   └── 需要 NoSQL？ → Firebase
├── 重表单/渐进增强？
│   └── Remix + Prisma（模式 E）
└── Vue 生态？
    └── Nuxt 3 + Drizzle（参考模式 A 结构，替换为 Vue 组件）
```
