# AGENTS.md 模板（全栈版）

以下是生成 AGENTS.md 时必须遵循的完整模板结构。用项目实际信息替换 `[占位符]`。

---

```markdown
# 🤖 AI 协作工程空间全局路由 (Agent Manifest)

> **项目**：[项目名称] — [一句话项目描述]
> **技术栈**：[框架 + 数据层 + 认证方案]
> **最后更新**：[日期]（[本次更新说明]）

---

## ⚡ 启动工作流（每次新会话必须按序执行）

> **任何 Agent 在写第一行代码之前，必须完成以下步骤。跳过任何一步都会导致上下文缺失。**

```
Step 1 → 读本文件（AGENTS.md）             ← 你正在做这步
Step 2 → 读 docs/exec-plans/progress.txt  ← 了解当前攻克点、Dead Ends 和卡点
Step 3 → 读 docs/exec-plans/feature-list.json ← 锁定唯一 status=pending 的 Task ID
Step 4 → 读 docs/caveats.md               ← 避免重复踩坑
Step 5 → 按需读对应模块文档               ← 见下方索引目录树
```

---

## 上下文加载顺序（Coding Worker 启动时严格遵守）

> 严禁无序全量扫描代码库。按以下优先级顺序加载上下文，找到足够信息后立即停止。

| 优先级 | 文件 | 作用 | 最大行数 |
|--------|------|------|---------|
| 1 | `AGENTS.md`（本文件） | 导航地图，定位其他文件 | ≤100 行 |
| 2 | `ARCHITECTURE.md` | 架构约束全集（含数据层+设计系统约束），红线不得违反 | 无限制 |
| 3 | `docs/SECURITY.md` | 安全红线，P0 零容忍 | 无限制 |
| 4 | `docs/DESIGN.md` | 设计语言约定，视觉实现依据 | 无限制 |
| 5 | `docs/caveats.md` | 已知陷阱，避免重蹈覆辙 | 无限制 |
| 6 | `docs/exec-plans/feature-list.json` 当前 Task 的 `contracts` | 本次任务契约 | — |
| 7 | `docs/exec-plans/active/[task_id]/plan.md` | 并行工作区执行计划（仅并行模式下存在） | 按需 |
| 8 | `metadata.files_affected` 列出的具体文件 | 最后才读源码 | 按需 |

**规则**：优先级 1-4 能定位所有信息时，不主动读取优先级 8 的源码文件。每多读一个无关文件 = 给本次 Session 增加一份幻觉风险。

---

## 📌 核心准则

本仓库受 AI 自动化工作流驱动。

- **编码执行者**：只读 `docs/exec-plans/feature-list.json`，锁定单个 Task ID 后开始工作，**禁止自行扩大范围**
- **架构师**：有权索引所有文档，创建新规范文档后必须同步更新本文件
- **禁止行为**：未经授权修改 `docs/` 下的 PRD 文件；在未读 `progress.txt` 的情况下开始编码；同时推进多个 Task；客户端组件直接 import 数据库客户端

---

## 📂 文档索引

| 文件路径 | 权限 | 说明 |
|----------|------|------|
| `docs/exec-plans/feature-list.json` | 读写 | **【核心】任务流转状态机** |
| `docs/exec-plans/progress.txt` | 读写 | **【核心】短期记忆交接棒** |
| `docs/exec-plans/issues.json` | 读写 | 缺陷追踪池 |
| `docs/exec-plans/tech-debt-tracker.md` | 读写 | 技术债追踪 |
| `docs/exec-plans/active/` | 读写 | 并行工作区（串行模式下为空） |
| `ARCHITECTURE.md` | 读写 | 架构约束全集（含数据层+设计系统约束） |
| `PLANS.md` | 读写 | 项目长期规划 & 里程碑 |
| `docs/SECURITY.md` | 读写 | 安全约束（P0 红线） |
| `docs/DESIGN.md` | 读写 | 设计语言约定 |
| `docs/QUALITY_SCORE.md` | 读写 | 代码质量评分面板 |
| `docs/RELIABILITY.md` | 读写 | 可靠性 & SLO 约定 |
| `docs/PRODUCT_SENSE.md` | 读写 | 产品感知 & 用户价值 |
| `docs/product-specs/` | 只读 | 产品需求文档 |
| `docs/caveats.md` | 读写 | 踩坑永久档案 |
| `docs/CHANGELOG/` | 只读 | 历史决策归档 |

---

## 🔧 环境脚本

| 文件路径 | 权限 | 说明 |
|----------|------|------|
| `init.sh` | 执行 | **幂等验证脚本**（无副作用，可随时执行，含数据层健康检查） |
| `start.sh` | 执行 | **服务启动脚本**（有副作用，启动 dev server + 数据库/BaaS） |
| `stop.sh` | 执行 | **服务停止脚本** |

---

## ✅ 完成定义 (Definition of Done)

一个 Task 被标记为 `completed` 当且仅当满足以下全部条件：

- [ ] **TypeScript 编译通过**：`npm run typecheck` 无 error（零容忍）
- [ ] **数据层同步**：Schema 迁移通过（`[数据层验证命令]`）
- [ ] **API 可调通**：端点返回预期响应（`verification.data` + `verification.auto`）
- [ ] **单元测试通过**：覆盖率 ≥ 80%，`npm run test` 全部 PASS
- [ ] **视觉验证**：对照 `contracts.design_contract` 确认间距/色彩/字体/响应式均符合规范
- [ ] **色彩未硬编码**：样式中使用 CSS 变量（`var(--color-*)`）而非直接写色值
- [ ] **环境变量安全**：敏感变量不在客户端可见前缀下（`NEXT_PUBLIC_*` / `VITE_*`）
- [ ] **状态更新**：feature-list.json 中该 Task 的 `status` → `completed`
- [ ] **进度同步**：progress.txt 更新 `[Current Focus]` 和 `[Next Steps]` 区块

---

## 🔍 验证命令清单 (Verification Commands)

### 自动验证（CI 可直接执行）

```bash
# 1. TypeScript 类型检查
npm run typecheck

# 2. 单元测试
npm run test

# 3. 构建验证
npm run build

# 4. 缺陷池状态一致性检查
node -e "const fs=require('fs');try{const i=JSON.parse(fs.readFileSync('docs/exec-plans/issues.json','utf8'));console.log('✅ issues.json:',i.issues?.length||0,'条工单')}catch(e){if(e.code==='ENOENT')console.log('ℹ️ issues.json 不存在，跳过');else throw e}"
```

### 数据层验证

```bash
# 根据技术栈选择对应命令：
# Prisma: npx prisma validate && npx prisma migrate status
# Drizzle: npx drizzle-kit check
# Supabase: npx supabase db diff --linked
# Convex: npx convex dev --once --typecheck
[数据层验证命令]
```

### 人工确认（需视觉验证，无法机器断言）

```bash
# 启动开发服务器后在浏览器确认
npm run dev
# → 访问 /xxx 页面，确认组件渲染正确、交互符合 PRD
# → 确认数据读写正常（CRUD 全流程）
# → 确认响应式布局在 375px / 768px / 1280px 下表现正常
# → 对照 contracts.design_contract 逐项确认视觉实现
```

---

## 📋 会话结束 Checklist（End of Session）

> 每次会话结束前必须完成，确保下一个 Agent 能无缝接手。

```
□ 1. 更新 docs/exec-plans/progress.txt
      - [Current Focus] 精确到当前卡在哪个文件/方法
      - [Next Steps] 写出下一步具体指令
      - [Key Decisions] 记录本次会话的重要技术决策
      - [Dead Ends] 记录本次踩到的坑

□ 2. 更新 docs/exec-plans/feature-list.json
      - 已完成的 Task：status → "completed"

□ 3. 数据层同步
      - Schema 变更已提交迁移文件
      - 数据层验证命令通过

□ 4. 文档同步
      - 新增约束追加到 ARCHITECTURE.md
      - 踩坑记录追加到 docs/caveats.md

□ 5. 验证通过
      - TypeScript 编译通过
      - 相关测试用例全部 PASS

□ 6. 运行 harness-watchdog 巡检（可选但推荐）
```

---

## 🚨 已知死胡同（Dead Ends 快速索引）

> 详细记录在 `progress.txt` [Dead Ends] 区块和 `docs/caveats.md`。以下是高频陷阱摘要：

| 现象 | 根因 | 解法 | 详见 |
|------|------|------|------|
| [填入遇到的坑] | [根因] | [解法] | [文档引用] |

---

## 🔒 架构约束（红线）

以下约束由架构师决策，Coding Agent 不得违反：

1. **分层隔离**：客户端组件绝不直接 import 数据库客户端，所有数据操作通过 API 层中转
2. **环境变量安全**：敏感密钥绝不放在客户端可见的环境变量前缀下
3. **[第三条项目特有的红线]**

> 完整架构约束见 `ARCHITECTURE.md`。
```
