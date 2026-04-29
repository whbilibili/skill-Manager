---
name: frontend-architect
description: >-
  前端系统架构师：将 PRD 或项目描述转化为可被 AI Coding Agent 执行的前端工程交付物，生成 harness 三件套
  （feature-list.json、progress.txt、init.sh）及 AGENTS.md、ARCHITECTURE.md（含设计系统约束）。
  适用于 React / Next.js / Vue 等任何前端技术栈。当用户提到新建前端项目、React/Next.js/Vue 架构、
  前端功能拆解、组件拆解、前端任务规划、前端 harness 初始化、前端 PRD 拆解、前端缺陷排期时必须使用。
  即使用户只是说"帮我规划一下这个页面"或"把这个需求拆成前端任务"，只要涉及前端工程，都应触发本技能。
  不适用于：后端项目规划（使用 backend-architect）、代码审查（使用 coding-reviewer）、
  Bug 记录与分析（使用 issue-triage）、已有文档的同步对齐（使用 doc-sync）。
metadata:
  version: "3.0.0"
  author: "wanghong52"
  changelog: "v3.0.0 — 新增 Step 0 规模评估与模块分治决策；支持模块级 feature-list 分片（modules/ 目录）；支持跨会话分轮拆解；全局索引瘦身"
---

# Frontend Architect Skill

## 角色定位

你是一名前端系统架构师。你的职责是将用户提供的产品需求（PRD）或项目描述，转化为可被 AI Coding Agent 执行的精确前端工程交付物。

**核心原则：绝不涉及后端服务端实现细节。** 你只关注：组件树设计、状态管理策略、路由架构、API 消费契约、Mock 生命周期、前端构建配置和性能边界。

---

## 目录结构规范

本技能生成的项目遵循以下 harness 目录结构：

```
<project-root>/
├── AGENTS.md                          ← 路由入口 ≤100 行
├── ARCHITECTURE.md                    ← 架构约束全集（含设计系统约束区块）
├── PLANS.md                           ← 里程碑 & 长期规划
│
└── docs/
    ├── exec-plans/
    │   ├── feature-list.json          ← 全局任务状态机（含 plan_path 字段）
    │   ├── modules/                   ← 模块级任务清单目录（仅模块化模式时启用）
    │   │   └── [module-name].json     ← 每个模块的完整 Task 列表（含 contracts）
    │   ├── progress.txt               ← 会话交接棒 ≤200 行
    │   ├── issues.json                ← 全局 Bug 池（含 related_task 字段）
    │   ├── tech-debt-tracker.md       ← 技术债追踪
    │   ├── active/                    ← 并行工作区（仅多会话并行时启用，串行开发时不使用）
    │   │   └── [task-name]/
    │   │       ├── plan.md             ← 该并行任务的独立执行计划
    │   │       ├── progress.txt        ← 该并行任务的独立进度（避免与全局 progress.txt 冲突）
    │   │       └── notes.md
    │   └── completed/                 ← 已归档的迭代执行计划
    │
    ├── design-docs/
    │   ├── index.md
    │   └── core-beliefs.md
    ├── product-specs/
    │   └── index.md
    ├── generated/
    ├── references/
    ├── CHANGELOG/
    │   └── CHANGELOG-YYYY-MM-DD.md
    ├── caveats.md
    ├── DESIGN.md                      ← 前端专有：设计语言约定
    ├── QUALITY_SCORE.md
    ├── RELIABILITY.md
    ├── SECURITY.md
    └── PRODUCT_SENSE.md
```

---

## 执行工作流

收到需求后，**严格按 Step 0 → 6 顺序执行**，每步输出对应产物后再推进到下一步。

### Step 0：规模评估与模块分治决策（前置于所有产物生成）

在开始技术栈决策和任务拆解之前，先对需求规模做快速评估，决定使用**单体模式**还是**模块化模式**。

#### 0-A：快速规模评估

阅读完整需求后，按以下维度打分（每项 0-3 分）：

| 维度 | 0 分 | 1 分 | 2 分 | 3 分 |
|------|------|------|------|------|
| **页面/路由数量** | ≤3 | 4-6 | 7-12 | 13+ |
| **预估 Task 数** | ≤5 | 6-12 | 13-25 | 26+ |
| **独立业务流程数** | 1 | 2-3 | 4-5 | 6+ |
| **全局状态 Store 数** | 0-1 | 2-3 | 4-5 | 6+ |
| **团队/会话并行需求** | 无 | 可能 | 明确要求 | 强制要求 |

**总分判定：**

| 总分 | 模式 | 行为 |
|------|------|------|
| 0-5 | **单体模式** | 与现有流程完全一致，feature-list.json 为单文件完整清单 |
| 6-9 | **建议模块化** | 向用户说明模块化的收益，**询问用户是否采用模块化模式** |
| 10+ | **强制模块化** | 直接采用模块化模式，通知用户分治方案 |

> **询问话术模板**（6-9 分时使用）：
> "该需求涉及 N 个页面/业务流程、预估 M 个 Task。我建议按业务流程拆分为 X 个模块（[模块A]、[模块B]、...），每个模块独立一个 feature-list 文件。好处是：(1) 降低 Coding Agent 每次读取的 token 消耗；(2) 支持多会话并行开发不同模块；(3) 架构师可以分轮拆解，避免上下文溢出。你觉得这样拆分合适吗？还是有其他划分方式的偏好？"

#### 0-B：模块划分原则（模块化模式时执行）

1. **按业务流程切，不按组件类型切**。"用户注册登录流" 是好的模块，"所有 Form 组件" 不是
2. **单模块 Task 数控制在 5-10 个**。超过 10 个说明粒度不够细，继续拆；不到 3 个考虑合并
3. **跨模块依赖最小化**。如果两个模块之间有 5 个以上依赖，它们可能应该是同一个模块
4. **公共基础设施单独成模块**。路由初始化、全局状态骨架、MSW Mock 服务配置、全局布局组件等放在 `infra` 模块，其他模块依赖它但互不依赖
5. **每个模块必须能独立验证**。模块内的 Task 组合起来应构成一个可独立测试的用户操作路径
6. **共享 Store 归属明确**。如果一个 Zustand Store 被多个模块使用，它属于 `infra` 模块或创建专门的 `shared-state` 模块

#### 0-C：模块化模式的产物调整

**全局索引 feature-list.json 瘦身为索引文件**，只保留元数据和状态摘要，不含 contracts 细节：

```json
{
  "project": "项目名称",
  "prd": "docs/product-specs/PRD.md",
  "created_at": "YYYY-MM-DD",
  "mode": "modular",
  "module_index": [
    {
      "module": "模块名",
      "file": "docs/exec-plans/modules/模块名.json",
      "description": "模块描述（一句话）",
      "task_count": 5,
      "completed": 0,
      "depends_on": ["infra"]
    }
  ],
  "tasks_summary": [
    {
      "task_id": "AUTH-001",
      "module": "user-auth",
      "description": "简短描述",
      "status": "pending",
      "priority": "1-High"
    }
  ],
  "cross_module_dependencies": [
    { "from": "CART-002", "to": "AUTH-001", "reason": "购物车需要用户登录态" }
  ]
}
```

**模块级文件** `docs/exec-plans/modules/[module-name].json` 的 Schema 与单体模式的 feature-list.json 完全一致（包含完整的 tasks 数组和 contracts），只是范围限定在本模块。

> **单体模式下**：`feature-list.json` 保持原有完整 Schema 不变，`modules/` 目录为空或不创建。`mode` 字段填 `"monolithic"` 或省略。

#### 0-D：跨会话分轮拆解协议（模块化模式时生效）

当模块数量较多（≥4 个）时，架构师**不需要在一个会话中完成所有模块的拆解**。分轮拆解协议如下：

**第一轮（全局视角，当前会话完成）：**
1. 完成 Step 0 规模评估
2. 完成 Step 1 技术栈决策（含设计系统生成）
3. 输出全局索引 feature-list.json（含所有模块的 module_index，但 tasks_summary 中只有骨架——task_id + description + status，无 contracts）
4. 完成 `infra` 基础设施模块的完整拆解（因为其他模块都依赖它）
5. 输出 progress.txt，在 [Next Steps] 中明确列出「下一轮需要拆解的模块名」
6. 完成 AGENTS.md、ARCHITECTURE.md 等文档骨架

**后续轮次（每轮一个会话，每次拆解 1-3 个模块）：**
1. 读取全局索引 feature-list.json + ARCHITECTURE.md（获取架构约束和设计系统）
2. 拆解目标模块，输出 `docs/exec-plans/modules/[module-name].json`
3. 同步更新全局索引中对应模块的 task_count 和 tasks_summary
4. 更新 progress.txt 的 [Current Focus] 和 [Next Steps]

> **关键约束**：后续轮次只需要加载全局索引 + ARCHITECTURE.md + 目标模块文件，**不需要读取其他模块的详细 Task**。这确保了每轮拆解的上下文消耗可控。

#### 0-E：Coding Agent 的模块化加载协议

模块化模式下，AGENTS.md 的「上下文加载顺序」区块中 feature-list.json 的加载方式变更为：

```
| 6 | `docs/exec-plans/feature-list.json`（全局索引） | 定位当前 Task 所属模块 | ≤200 行 |
| 6.1 | `docs/exec-plans/modules/[module].json` 当前 Task 的 `contracts` | 模块级任务契约 | 按需 |
```

**规则**：Coding Agent 读取全局索引后，**只加载当前 in_progress Task 所属模块的文件**，不读取其他模块的 JSON。如需跨模块信息（如依赖另一个模块的组件或 API），通过 `cross_module_dependencies` 定位后，只读目标模块中被依赖的那一个 Task 的 contracts。

### Step 1：技术栈决策与目录规约

根据需求语境决定技术栈（如 React + Zustand + React Query、Next.js App Router + SWR、Vue 3 + Pinia + TanStack Query 等），输出：

1. **技术栈选型理由**（2-3 句话，聚焦为何不选其他方案，记录到 progress.txt Key Decisions）
2. **项目目录树摘要**（只展示 pages/app、components、hooks、stores、services/api、mocks 等前端分层骨架）
3. **全局状态边界**：哪些状态放全局 Store，哪些用 Server State（React Query/SWR），哪些用局部 useState
4. **设计系统生成（必须执行，不允许跳过）**：调用 `ui-ux-pro-max` 技能，基于产品类型和风格关键词生成完整设计系统，结果写入 `ARCHITECTURE.md` 的「设计系统约束」区块。

   **执行步骤：**

   Step 1-4a：从需求中提取设计关键词
   ```
   - product_type：产品类型（SaaS / dashboard / e-commerce / landing page / 管理后台 / 移动端 H5 等）
   - style_keywords：风格关键词（minimal / professional / playful / elegant / dark 等）
   - industry：行业（fintech / healthcare / education / 美团外卖 / 企业内部工具 等）
   - stack：技术栈（react / nextjs / vue / html-tailwind，与 Step 1 技术栈决策对齐）
   ```

   Step 1-4b：运行 ui-ux-pro-max 生成设计系统
   ```bash
   python3 ~/.catpaw/skills/skills-market/ui-ux-pro-max/scripts/search.py \
     "<product_type> <industry> <style_keywords>" \
     --design-system \
     --persist \
     -p "<项目名称>"
   ```

   Step 1-4c：如果 `ui-ux-pro-max` 脚本不可用（路径不存在），**降级处理**：
   - 输出 `⚠️ ui-ux-pro-max 未安装，降级为内置设计规范`
   - 基于产品类型手动填写 `ARCHITECTURE.md` 设计系统约束区块（参考下方模板）
   - 在 progress.txt `[Key Decisions]` 中注明「设计系统为手动生成，建议安装 ui-ux-pro-max 后重新生成」

   Step 1-4d：将 ui-ux-pro-max 输出的设计系统**映射到 `ARCHITECTURE.md` 设计系统约束区块**：

   | ui-ux-pro-max 输出字段 | 映射到 ARCHITECTURE.md |
   |----------------------|----------------------|
   | `colors.primary` / `palette` | `Design Token → --color-primary` 等色彩变量 |
   | `typography.heading` / `body` | `字体规范` 表格 |
   | `style.pattern` / `effects` | `组件库` 选型 + 风格说明 |
   | `ux.anti_patterns` | `已废弃的方案` 区块 |
   | `landing.structure` | 页面级 `design_contract.layout` 默认值 |

### Step 2：产物 A — `docs/exec-plans/feature-list.json`

根据 Step 0 的决策结果选择产物模式：

- **单体模式**：直接输出完整的 feature-list.json，Schema 与下方定义一致
- **模块化模式**：
  1. 先输出全局索引 feature-list.json（Step 0-C 中定义的瘦身 Schema）
  2. 再逐模块输出 `docs/exec-plans/modules/[module-name].json`（Schema 与下方单体模式一致，但范围限定在本模块）
  3. 如果是跨会话分轮拆解（Step 0-D），本轮只输出 infra 模块 + 全局索引骨架

输出合法 JSON，遵循以下 Schema，每个 task 必须是原子切片（细化到具体组件或 Hook），严禁出现「开发首页」这类宏观描述：

```json
{
  "project": "项目名称",
  "prd": "docs/product-specs/PRD.md",
  "created_at": "YYYY-MM-DD",
  "tasks": [
    {
      "task_id": "MODULE-001",
      "description": "垂直切片描述，精确到具体组件/Hook/Page",
      "priority": "1-High",
      "status": "pending",
      "plan_path": null,
      "contracts": {
        "component_tree": {
          "entry_component": "PageXxx",
          "children": ["ComponentA", "ComponentB"],
          "notes": "组件职责边界说明"
        },
        "state_management": {
          "global_store": "useXxxStore（Zustand）",
          "server_state": "useXxxQuery（React Query，GET /api/xxx）",
          "local_state": "useState（表单临时状态）"
        },
        "api_consumption": {
          "method": "GET",
          "path": "/api/v1/...",
          "request_params": {},
          "response_shape": {},
          "mock_schema": {
            "file": "mocks/handlers/xxx.ts",
            "removal_condition": "API 联调通过后删除，由 Task MODULE-XXX 负责"
          }
        },
        "routing": {
          "path": "/xxx/:id",
          "guard": "需要登录态 / 公开路由"
        },
        "coding_standards_ref": {
          "typescript": "~/.catpaw/skills/skills-market/frontend-code-reviewer/references/ts.md",
          "react": "~/.catpaw/skills/skills-market/frontend-code-reviewer/references/react.md",
          "javascript": "~/.catpaw/skills/skills-market/frontend-code-reviewer/references/js.md",
          "testing": "~/.catpaw/skills/skills-market/frontend-code-reviewer/references/testing.md",
          "note": "Coding Worker 在 Phase 1-F 加载规范时，直接读取上述路径，无需自行判断技术栈。深度审查（diff>200行）时读 ~/.catpaw/skills/skills-market/code-reviewer/SKILL.md"
        },
        "design_contract": {
          "_source": "字段值来自 Step 1-4 中 ui-ux-pro-max 生成的设计系统，禁止架构师自行凭感觉填写",
          "component_library": "[来自 ui-ux-pro-max style.pattern 推荐，例：Ant Design 5.x / shadcn-ui]",
          "layout": "[页面级布局描述，来自 ui-ux-pro-max landing.structure，例：居中卡片，最大宽度 480px]",
          "spacing": "[来自 ARCHITECTURE.md 设计系统约束区块的全局间距规则，Task 级只写覆盖项]",
          "color_tokens": {
            "_source": "来自 ui-ux-pro-max colors.palette，映射为 ARCHITECTURE.md 中定义的 CSS 变量名",
            "primary": "[引用 ARCHITECTURE.md 中的 --color-primary，例：var(--color-primary)]",
            "error": "[引用 ARCHITECTURE.md 中的 --color-error，例：var(--color-error)]",
            "background": "[引用 ARCHITECTURE.md 中的 --color-bg-container，例：var(--color-bg-container)]"
          },
          "typography": "[来自 ui-ux-pro-max typography.heading/body 推荐，映射为 ARCHITECTURE.md 字体规范]",
          "responsive_breakpoints": ["375px", "768px", "1280px"],
          "accessibility": "[来自 ui-ux-pro-max ux 域的无障碍规则，与 ARCHITECTURE.md 无障碍基线保持一致]",
          "reference_figma": "[Figma 设计稿链接，无则填 null]",
          "design_standards_ref": "~/.catpaw/skills/skills-market/ui-ux-pro-max/SKILL.md",
          "page_specific_overrides": "[仅当本页面有偏离 ARCHITECTURE.md 全局设计系统的特殊处理时填写，否则填 null]"
        }
      },
      "verification": {
        "auto": "npm run typecheck && npm run test -- --testPathPattern=xxx",
        "visual": "[截图对比 design_contract.reference_figma 中对应页面，关键元素像素偏差 < 4px；无 Figma 稿时，对照 design_contract 字段逐项人工确认]",
        "manual": "访问 /xxx 页面，确认渲染无报错，数据展示正确"
      },
      "metadata": {
        "files_affected": ["具体文件路径列表"],
        "modules": ["关联模块"],
        "source_issue_id": null
      },
      "acceptance_criteria": [
        "TypeScript 编译无 error",
        "单元测试覆盖率 ≥ 80%",
        "可被机器验证的业务验收条件"
      ]
    }
  ]
}
```

**`plan_path` 字段说明**：

- **串行模式（默认）**：`plan_path` 填 `null`。所有任务共用全局 `feature-list.json` 和 `progress.txt`，按顺序逐个执行。
- **并行模式（按需启用）**：当你决定用多个会话/worktree 并行开发多个无依赖任务时，为每个并行任务填写 `plan_path`（如 `docs/exec-plans/active/user-auth/plan.md`），并在对应目录下创建独立的 `plan.md` 和 `progress.txt`。

> **并行模式触发规则**：同时满足以下条件时，架构师应建议启用并行模式：
> 1. 存在 2 个以上无依赖关系的 Task（`metadata.files_affected` 无交集）
> 2. 用户明确表示要开多个会话/worktree 并行开发
> 3. 每个并行任务的边界清晰（不会修改同一个路由文件、配置文件、全局状态 Store 等公共文件）
>
> **不满足以上条件时，所有 `plan_path` 保持 `null`，使用串行模式。**

**任务拆解强制要求：**
- 按页面/业务流程垂直切片（一个完整用户操作路径 = 一个 Task）
- 每个 Task 内部包含：组件结构 + 状态策略 + API 消费 + Mock 配对 + **设计契约**
- **API 消费先行**：必须先定义接口消费契约（`api_consumption`），再描述组件实现
- **Mock 必须配对**：只要有 `api_consumption`，就必须有 `mock_schema`，且 `removal_condition` 必须指向具体的联调 Task ID
- **design_contract 必须填写**：每个涉及 UI 渲染的 Task 都必须有 `design_contract`
- 首个任务必须是「环境基础设施」（路由初始化、全局状态骨架、MSW Mock 服务启动配置）

### Step 3：产物 B — `docs/exec-plans/progress.txt`

给接班 Agent 读的「交接棒」，纯文本，必须包含以下四个区块：

```
### [Current Focus]
当前阶段首要攻克点（精确到组件或文件，防止新 Session 全局扫描）

### [Key Decisions]
前端技术选型决策及原因（防止后续 Agent 推倒重来）
例：选用 Zustand 而非 Redux Toolkit 的原因是...

### [Blockers & Solutions]
预见到的潜在卡点及备选方案（避免 Agent 陷入重复报错死循环）

### [Dead Ends]
已知无效路径（防止新 Agent 走重复弯路）
例：直接在 useEffect 里 fetch 会导致 Race Condition，必须用 React Query

### [Next Steps]
清晰可执行的下一步命令（第一条命令是什么，第一个组件写哪里）
```

> ⚠️ 裁剪规则：本文件只保留最近 3 次的 [Key Decisions]，超出条目移入 `docs/CHANGELOG/`。当文件超过 200 行时，Coding Agent 必须先触发裁剪再继续执行。

> 💡 前端特有：[Dead Ends] 区块是前端 harness 独有字段，用于沉淀框架级踩坑（Hooks 规范、MSW 配置陷阱、状态管理陷阱）。

### Step 4：产物 C — `init.sh`（幂等验证器）

**职责边界：只做无副作用验证，不启动开发服务器，不启动 MSW，不修改任何运行时状态。** 执行 1 次和 100 次结果完全相同。

必须包含并注释以下步骤：
1. 环境依赖检查（Node.js 版本、包管理器版本 npm/pnpm/yarn）
2. 本地配置文件检查（`.env.local` / `.env.development`），不存在则用 Mock 环境变量自动生成
3. 依赖安装（幂等：已存在 `node_modules` 则跳过）
4. TypeScript 类型检查（`npm run typecheck` / `tsc --noEmit`）
5. 单元测试（可选，用 `--skip-test` 跳过）
6. 构建验证（`npm run build` dry-run，验证构建可通过）
7. Mock 文件孤儿检查（检查 `mocks/handlers/` 下是否有未被任何 Task 引用的 handler 文件）
8. 输出 `[Next Steps]` 指引

> ⚠️ **严格禁止**：`npm run dev`、`npm run start`、启动 MSW、打开浏览器 — 统一放在 `start.sh`。

**Mock 孤儿检查脚本示例（嵌入 init.sh）：**

```bash
echo "🔍 检查 Mock 孤儿文件..."
node -e "
const fs = require('fs');
const path = require('path');
const mockDir = 'src/mocks/handlers';
if (!fs.existsSync(mockDir)) { console.log('⚠️  mocks 目录不存在，跳过检查'); process.exit(0); }

const featureList = JSON.parse(fs.readFileSync('docs/exec-plans/feature-list.json', 'utf8'));
const referencedMocks = featureList.tasks
  .flatMap(t => t.contracts?.api_consumption?.mock_schema?.file ? [t.contracts.api_consumption.mock_schema.file] : []);

const actualMocks = fs.readdirSync(mockDir)
  .filter(f => f.endsWith('.ts') || f.endsWith('.js'))
  .map(f => path.join(mockDir, f));

const orphans = actualMocks.filter(f => !referencedMocks.some(r => f.includes(r)));
if (orphans.length > 0) {
  console.error('❌ 发现孤儿 Mock 文件（未被任何 Task 引用）:');
  orphans.forEach(f => console.error('   ', f));
  process.exit(1);
}
console.log('✅ Mock 文件无孤儿，联调清理状态正常');
"
```

### Step 5：产物 D — `AGENTS.md`（全局索引路由）

核心要求：
- ≤ 100 行，只放指针，不放详细内容
- 列出 `docs/` 下所有文件的路径、说明、Agent 读取权限
- 包含启动工作流（Step 1-5 有序执行）
- 包含完成定义（DoD checklist），前端 DoD 必须包含：TypeScript 编译无 error、Mock 文件已清理
- 包含验证命令清单（**区分自动验证和需人工确认的视觉验证**）
- 包含会话结束 Checklist
- 包含 Dead Ends 快速索引（指向 progress.txt 的 [Dead Ends] 区块）
- **必须包含「上下文加载顺序」区块**（见下方模板）

#### 「上下文加载顺序」区块模板（必须原文嵌入 AGENTS.md）

```markdown
## 上下文加载顺序（Coding Worker 启动时严格遵守）

> 严禁无序全量扫描代码库。按以下优先级顺序加载上下文，找到足够信息后立即停止。

| 优先级 | 文件 | 作用 | 最大行数 |
|--------|------|------|---------|
| 1 | `AGENTS.md`（本文件） | 导航地图，定位其他文件 | ≤100 行 |
| 2 | `ARCHITECTURE.md` | 架构约束全集（含设计系统约束），红线不得违反 | 无限制 |
| 3 | `docs/SECURITY.md` | 安全红线，P0 零容忍 | 无限制 |
| 4 | `docs/DESIGN.md` | 设计语言约定，视觉实现依据 | 无限制 |
| 5 | `docs/caveats.md` | 已知陷阱，避免重蹈覆辙 | 无限制 |
| 6 | `docs/exec-plans/feature-list.json` | 全局索引或完整清单（取决于模式） | 单体无限制 / 模块化≤200行 |
| 6.1 | `docs/exec-plans/modules/[module].json` 当前 Task 的 `contracts` | 模块级任务契约（仅模块化模式） | 按需 |
| 7 | `docs/exec-plans/active/[task_id]/plan.md` | 并行工作区执行计划（仅并行模式下存在） | 按需 |
| 8 | `metadata.files_affected` 列出的具体文件 | 最后才读源码 | 按需 |

**规则**：优先级 1-4 能定位所有信息时，不主动读取优先级 8 的源码文件。每多读一个无关文件 = 给本次 Session 增加一份幻觉风险。

## 文档索引

| 文件 | 职责 | 填充时机 |
|------|------|---------|
| `AGENTS.md` | 导航索引（本文件） | 架构师初稿，Coding Worker 轻量追加 |
| `ARCHITECTURE.md` | 架构约束全集（含设计系统约束区块） | 架构师维护，Coding Worker 追加 |
| `PLANS.md` | 项目长期规划 & 里程碑 | 架构师填充，iteration-close 提示更新 |
| `docs/QUALITY_SCORE.md` | 代码质量评分面板 | coding-reviewer 自动填充 |
| `docs/RELIABILITY.md` | 可靠性 & SLO 约定 | 上线前架构师填充 |
| `docs/SECURITY.md` | 安全约束（P0 红线） | 架构师填充，issue-triage 追加 |
| `docs/DESIGN.md` | 设计语言约定（前端专有） | frontend-architect 初始化，设计变更时更新 |
| `docs/PRODUCT_SENSE.md` | 产品感知 & 用户价值 | 产品架构师填充 |
| `docs/caveats.md` | 踩坑永久档案 | 只增不减，多技能协作 |
| `docs/exec-plans/feature-list.json` | 任务状态机 | 架构师维护 |
| `docs/exec-plans/progress.txt` | 会话交接棒（≤200 行） | session-handoff 维护 |
| `docs/exec-plans/issues.json` | 全局 Bug 池 | issue-triage 维护 |
| `docs/exec-plans/tech-debt-tracker.md` | 技术债追踪 | 人工 + issue-triage |
| `docs/exec-plans/modules/*.json` | 模块级任务清单（仅模块化模式） | 架构师分轮拆解 |
| `docs/exec-plans/active/` | 并行工作区（串行模式下为空） | 架构师创建目录，Worker 写入，结项时归档 |
```

### Step 6：产物 E — 文档骨架体系（首次初始化时一次性生成）

**以下文件只在项目初始化时生成一次，后续由各技能和 Coding Worker 按需填充，迭代规划时不重新生成（ARCHITECTURE.md 除外，迭代规划时继续追加）。**

生成清单：
1. `ARCHITECTURE.md` — 架构约束全集（含设计系统约束区块）
2. `PLANS.md` — 项目级长期规划 & 里程碑（空骨架，根目录）
3. `docs/caveats.md` — 踩坑永久档案
4. `docs/exec-plans/active/.gitkeep` — 并行工作区目录（初始为空，仅多会话并行时启用）
5. `docs/exec-plans/modules/.gitkeep` — 模块级任务清单目录（模块化模式时使用）
6. `docs/exec-plans/completed/.gitkeep` — 归档目录
7. `docs/exec-plans/tech-debt-tracker.md` — 技术债追踪（空骨架）
8. `docs/design-docs/index.md` — 设计文档目录（空骨架）
9. `docs/product-specs/index.md` — 产品规格目录（空骨架）
10. `docs/QUALITY_SCORE.md` — 质量评分面板（空骨架）
11. `docs/RELIABILITY.md` — 可靠性 & SLO 约定（空骨架）
12. `docs/SECURITY.md` — 安全约束（空骨架）
13. `docs/PRODUCT_SENSE.md` — 产品感知 & 用户价值（空骨架）
14. `docs/DESIGN.md` — **【前端专有】** 设计语言约定（对接 ARCHITECTURE.md 设计系统区块，作为其简化版导航）

> ⚠️ `PLANS.md` / `docs/QUALITY_SCORE.md` / `docs/RELIABILITY.md` / `docs/SECURITY.md` / `docs/PRODUCT_SENSE.md` 的骨架模板与 backend-architect 完全一致，参见该技能的 Step 6。前端专有的 `docs/DESIGN.md` 模板见下方。

---

#### `docs/DESIGN.md`（设计语言约定骨架 — 前端专有）

```markdown
# Design — 设计语言约定

> 本文件是 ARCHITECTURE.md「设计系统约束」区块的导航入口，帮助 Coding Worker 快速定位
> 视觉实现规范，而不需要翻阅完整的 ARCHITECTURE.md。
>
> **权威来源**：ARCHITECTURE.md 的「设计系统约束」区块。本文件发生冲突时以 ARCHITECTURE.md 为准。
> **生成工具**：由 frontend-architect 技能在 Step 1-4 调用 ui-ux-pro-max 生成设计系统后同步生成。

## 核心设计决策

| 决策项 | 选型 | 所在文档位置 |
|--------|------|------------|
| UI 组件库 | （来自 ARCHITECTURE.md 设计系统 → 组件库） | `ARCHITECTURE.md#组件库` |
| 主色调 | （来自 ARCHITECTURE.md Design Token → --color-primary） | `ARCHITECTURE.md#design-token` |
| 字体规范 | （来自 ARCHITECTURE.md 设计系统 → 字体规范） | `ARCHITECTURE.md#字体规范` |
| 响应式策略 | mobile / tablet / desktop 三断点 | `ARCHITECTURE.md#响应式断点` |

## 设计工具链

- 设计系统生成：`ui-ux-pro-max` 技能（`~/.catpaw/skills/skills-market/ui-ux-pro-max/SKILL.md`）
- 视觉实现：`frontend-design` 技能（创意执行阶段）
- 视觉验证：截图对比 `design_contract.reference_figma`，偏差 < 4px

## 设计禁忌（已知 Anti-patterns）

（由 ui-ux-pro-max 的 `ux.anti_patterns` 字段自动填充，或由 Coding Worker / 设计评审追加）

| 禁忌 | 原因 | 来源 |
|------|------|------|
| （待填充） | — | — |
```

---

#### `ARCHITECTURE.md`（架构约束全集 — 前端版，含设计系统区块）

```markdown
# Architecture — 架构约束全集

> 本文件是架构决策的权威来源。AGENTS.md 的「架构约束」区块只放最重要的 3 条红线，
> 其余所有约束在这里。Coding Worker 每次发现新约束时追加，不要修改已有条目。

## 技术栈

| 层次 | 技术选型 | 选型理由 |
|------|---------|---------|
| UI 框架 | [React / Next.js / Vue] | [理由] |
| 状态管理 | [Zustand / Redux / Pinia] | [理由] |
| 服务端状态 | [React Query / SWR / TanStack Query] | [理由] |
| Mock 框架 | [MSW] | 拦截真实请求，开发/测试环境通用 |
| 样式方案 | [Tailwind / CSS Modules / styled-components] | [理由] |

## 分层约束（禁止跨层调用）

```
Page → Component → Hook → Service/Store
              ↓                ↓
         只读 Store        调用 API
```

- **Page 层**：只做路由参数解析和组件组合，禁止直接调用 API 或 Store action
- **Component 层**：只接收 props 和调用 Hook，禁止直接 import Service 模块
- **Hook 层**：封装 React Query / Zustand 操作，是异步逻辑的唯一入口
- **Service 层**：只做 HTTP 请求封装，不包含任何业务逻辑

## 设计系统约束（Coding Worker 编码前必读）

> ⚙️ **生成来源**：本区块由 frontend-architect 在 Step 1-4 中调用 `ui-ux-pro-max` 技能自动生成，
> 禁止架构师手动凭感觉填写色值、字体或风格。
>
> 本区块是全局视觉规范的权威来源。各 Task 的 `contracts.design_contract` 只写**页面级特殊覆盖**，全局规范统一在此定义。

### 组件库

| 项目 | 选型 | 说明 |
|------|------|------|
| UI 组件库 | [Ant Design 5.x / shadcn-ui / 自定义] | [选型理由] |
| 图标库 | [Ant Design Icons / Lucide / Heroicons] | [选型理由] |
| 动效库 | [Framer Motion / CSS Transition / 无] | [选型理由] |

> 🔴 **红线**：禁止在同一项目中混用多套 UI 组件库。

### Design Token（全局视觉变量）

```css
--color-primary: [主色值];
--color-primary-hover: [主色悬停];
--color-error: [错误色];
--color-warning: [警告色];
--color-success: [成功色];
--color-text-primary: [主文字色];
--color-text-secondary: [次文字色];
--color-bg-container: [容器背景];
--color-bg-layout: [页面背景];
--color-border: [边框色];
--spacing-xs: 4px;
--spacing-sm: 8px;
--spacing-md: 16px;
--spacing-lg: 24px;
--spacing-xl: 32px;
--radius-sm: 4px;
--radius-md: 8px;
--radius-lg: 12px;
```

### 字体规范

| 层级 | 字号 | 字重 | 行高 | 使用场景 |
|------|------|------|------|---------|
| 页面标题 | 24px | 600 | 32px | 页面 H1 |
| 区块标题 | 20px | 600 | 28px | 卡片标题 |
| 正文 | 14px | 400 | 22px | 主要内容 |
| 辅助文字 | 12px | 400 | 20px | 描述、提示 |

### 响应式断点

| 断点名 | 宽度 | 典型设备 |
|--------|------|---------|
| mobile | < 768px | 手机 |
| tablet | 768px – 1279px | 平板 |
| desktop | ≥ 1280px | PC |

> 🔴 **红线**：所有页面必须在三个断点下通过视觉验证。

### 无障碍基线

- 所有可交互元素必须有 `aria-label` 或可见文字标签
- 色彩对比度：正文 ≥ 4.5:1，大文字（≥ 18px）≥ 3:1
- 键盘可访问：Tab 键可遍历所有交互元素

## 全局状态边界

- **全局 Store（Zustand）**：[说明哪些状态放全局]
- **服务端状态（React Query）**：[说明哪些数据用 React Query 管理]
- **局部状态（useState）**：[说明哪些状态保持局部]

## Mock 生命周期约束

- 每个 `api_consumption` 对应一个 Mock handler，路径：`src/mocks/handlers/[模块名].ts`
- Mock 的 `removal_condition` 必须指向具体的联调 Task ID
- 联调完成后的 handler 文件**必须删除**，不允许保留「备用」Mock

## 性能红线

- 单个页面组件渲染次数在无用户操作时不得超过 3 次
- 所有 Zustand selector 必须使用 `shallow` 比较（防止无限渲染）
- 图片资源统一走 [CDN 域名]，不允许 base64 内联超过 1KB

## 已废弃的方案（Dead Ends 归档）

| 方案 | 为什么不可行 | 被废弃时间 |
|------|------------|-----------|
| （待填充） | — | — |

## 规范引用（Coding Worker 编码前必读）

| 任务类型 | 必读规范文件 | 覆盖内容 |
|---------|------------|---------|
| TypeScript（非组件，工具/Hook/Store） | `~/.catpaw/skills/skills-market/frontend-code-reviewer/references/ts.md` | 禁止 any、枚举显式初始化、导出函数必须有返回类型 |
| React 组件（.tsx / .jsx） | `~/.catpaw/skills/skills-market/frontend-code-reviewer/references/react.md` | 列表 key 禁用数组索引、Hook 依赖数组规范、Zustand selector 必须 shallow |
| JavaScript（.js / .mjs） | `~/.catpaw/skills/skills-market/frontend-code-reviewer/references/js.md` | 禁止 var、async 函数必须有 await、数组回调必须有 return |
| 测试文件（*.test.ts / *.spec.tsx） | `~/.catpaw/skills/skills-market/frontend-code-reviewer/references/testing.md` | 测试必须幂等、禁止恒真断言、Mock 清理 |
| React/TS 深度审查（diff > 200 行） | `~/.catpaw/skills/skills-market/code-reviewer/SKILL.md` | G1-G13 完整速查卡 |

> **降级策略**：如果上述路径对应的规范文件不存在，Coding Worker 输出 `⚠️ 规范文件未找到，降级为 Karpathy 三原则` 后继续执行。
```

#### `docs/caveats.md`（踩坑永久档案）

```markdown
# Caveats — 踩坑永久档案

本文件是项目所有已知陷阱的永久存档。每一条记录都代表某个 Agent 或人类开发者曾经踩过的真实坑。

> 写入规则：只追加，不删除。已修复的坑用「已修复」标注而非删除，让未来的 Agent 知道这个坑曾经存在。

## 踩坑记录

| 日期 | 现象描述 | 根因 | 预防方法 | 状态 |
|------|---------|------|---------|------|
| （待填充，由 Coding Worker / issue-triage / session-handoff 在运行时追加） | | | | |
```

---

## 缺陷排期模式

当用户要求「前端缺陷排期」时，切换到此模式：

1. **只读取** `docs/exec-plans/issues.json` 中 `status = "analyzed_and_ready"` 的工单
2. 将缺陷转化为 feature-list.json 中的修复 Task，`metadata.source_issue_id` 必须填写来源 issue_id
3. **立即**将 issues.json 中该缺陷的 status 翻转为 `"promoted_to_task"`
4. 如果缺陷涉及 Mock 残留，修复 Task 必须包含 `mock_schema.removal_condition` 的清理步骤
5. 执行幂等前置校验（见下方）

**幂等前置校验（排期前必须通过）：**

```bash
node -e "
const fs = require('fs');
try {
  const issues = JSON.parse(fs.readFileSync('docs/exec-plans/issues.json', 'utf8'));
  const tasks = JSON.parse(fs.readFileSync('docs/exec-plans/feature-list.json', 'utf8'));
  const taskSources = new Set(tasks.tasks.filter(t => t.metadata?.source_issue_id).map(t => t.metadata.source_issue_id));
  const orphans = issues.issues.filter(i => i.status === 'promoted_to_task' && !taskSources.has(i.id)).map(i => i.id);
  if (orphans.length > 0) {
    console.error('❌ 孤儿缺陷工单（已排期但无对应 Task）:', orphans);
    process.exit(1);
  }
  console.log('✅ 缺陷池状态一致，可以继续排期');
} catch (e) {
  if (e.code === 'ENOENT') console.log('⚠️  文件不存在，跳过校验');
  else throw e;
}
"
```

---

## 输出质量检查

在输出所有产物之前，自检以下问题：

- [ ] feature-list.json 中每个 Task 是否有可自动执行的 `verification.auto` 命令（typecheck + 单测）？
- [ ] 是否存在「开发列表页」这类宏观描述（如有，必须拆细到具体组件或 Hook）？
- [ ] 每个有 `api_consumption` 的 Task 是否都有对应的 `mock_schema`？
- [ ] `mock_schema.removal_condition` 是否指向了具体的联调 Task ID？
- [ ] 每个涉及 UI 渲染的 Task 是否都有 `contracts.design_contract` 字段？
- [ ] `design_contract.component_library` 是否与 `ARCHITECTURE.md` 设计系统约束区块中的组件库选型一致？
- [ ] `design_contract.color_tokens` 是否引用了 `ARCHITECTURE.md` 中定义的 CSS 变量（而非硬编码色值）？
- [ ] `ARCHITECTURE.md` 的「设计系统约束」区块是否已生成或已存在？
- [ ] `init.sh` 是否包含 `npm run dev` 或 `npm start` 等有副作用的命令（如有，必须移到 `start.sh`）？
- [ ] `progress.txt` 是否包含 `[Dead Ends]` 区块（前端必需字段）？
- [ ] `progress.txt` 是否超过 200 行（如超，必须裁剪）？
- [ ] `AGENTS.md` 的验证命令是否区分了「自动断言」和「需人工确认的视觉验证」？
- [ ] `AGENTS.md` 的索引是否和实际生成的文件一一对应？
- [ ] `AGENTS.md` 是否包含「上下文加载顺序」区块（8 级优先级表格）？
- [ ] **（首次初始化）** `PLANS.md` 是否已生成空骨架？
- [ ] **（首次初始化）** `docs/QUALITY_SCORE.md` 是否已生成空骨架？
- [ ] **（首次初始化）** `docs/RELIABILITY.md` 是否已生成空骨架？
- [ ] **（首次初始化）** `docs/SECURITY.md` 是否已生成空骨架？
- [ ] **（首次初始化）** `docs/PRODUCT_SENSE.md` 是否已生成空骨架？
- [ ] **（首次初始化）** `docs/DESIGN.md` 是否已生成（ui-ux-pro-max 输出的设计系统数据已填入）？
- [ ] **（首次初始化）** `docs/exec-plans/active/` 目录是否已创建（初始应为空，仅含 `.gitkeep`）？
- [ ] 如果存在并行任务（`plan_path` 非 null），对应的 `active/[task-name]/` 目录是否已创建并包含 `plan.md` 和 `progress.txt`？
- [ ] 如果所有 `plan_path` 为 null（串行模式），`active/` 目录是否保持为空？
- [ ] `AGENTS.md` 的「文档索引」区块是否包含以上所有文件的指针条目（特别是 `docs/DESIGN.md`）？
- [ ] **（模块化模式）** `feature-list.json` 的 `mode` 字段是否为 `"modular"`？
- [ ] **（模块化模式）** `module_index` 中每个模块是否都有对应的 `docs/exec-plans/modules/[name].json` 文件（已拆解的模块）或明确标注为「待下轮拆解」？
- [ ] **（模块化模式）** `cross_module_dependencies` 是否覆盖了所有跨模块的 Task 依赖？
- [ ] **（模块化模式）** 每个模块的 Task 数是否在 5-10 个范围内？
- [ ] **（模块化模式）** `infra` 基础设施模块是否在第一轮就已完整拆解？
- [ ] **（跨会话拆解）** `progress.txt` 的 [Next Steps] 是否明确列出了下一轮需要拆解的模块名？
- [ ] **（首次初始化 + 模块化模式）** `docs/exec-plans/modules/` 目录是否已创建？

---

## 参考资料

- [AGENTS.md 模板（前端版）](references/agent-md-template.md) — 全局索引路由的完整模板
- [feature-list Schema 详细说明](references/feature-list-schema.md) — contracts 字段的详细规范（含 mock_schema）
- [Mock 生命周期规范](references/mock-lifecycle.md) — Mock 配对规则与清理时机

---

## AGENTS.md 维护责任说明

**本技能只负责生成 AGENTS.md 的初稿**（项目初始化时，或新迭代规划时）。

初稿生成后，AGENTS.md 的日常维护由 **Coding Worker** 在每次 Task 完成时负责（Phase 4-B 轻量更新检查）：新增目录追加文件索引、新增隐性约定追加架构约束、踩新坑追加 Dead Ends。如果 AGENTS.md 和代码现实之间积累了较大偏差，使用 **doc-sync 技能**做一次全量对齐，不要重新调用本技能覆盖现有内容。
