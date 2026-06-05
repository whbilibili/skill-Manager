# 自定义 Skill 套件 · 迁移依赖清单

> 迁移步骤：整体复制 skills/ 下的自定义目录 + commands/ 下的 .md 文件 → 在新环境补装 market 依赖 → 完成。
>
> 最后更新：2026-05-14

---

## 一、迁移操作速查

### Step 1：复制自定义文件

将以下目录和文件复制到新环境的 `~/.catpaw/` 对应位置：

```
# 自定义 Skills → ~/.catpaw/skills/
ai-code-trust/
backend-architect/
coding-reviewer/
doc-sync/
feature-request/
frontend-architect/
fullstack-architect/
fullstack-boundary-contract/
fullstack-coordinator/
harness-project-init/
harness-watchdog/
issue-triage/
iteration-close/
session-handoff/
test-architect/

# 以下为独立 Skill，无跨 Skill 依赖，按需携带
agent-folder-init/
architecture-blueprint-generator/
birchline-design/
contract-testing/
convex/
convex-create-component/
convex-migration-helper/
convex-performance-audit/
convex-quickstart/
convex-setup-auth/
database-migration/
doc-to-html/
frontend-design/
harness-creator/
harness-engineering-playbook/
homestock-design/
hue/
nodejs-backend-patterns/
sleek-design-mobile-apps/
spec-driven-development/
trae-design/
typescript-advanced-types/
update-docs/
vercel-react-best-practices/
webapp-testing/

# Commands → ~/.catpaw/commands/
Coding Worker v3.md
# 以下按需携带
Coding Worker v2.md
AI 研发架构师.md
前端架构师.md
后端架构师.md
资深创新产品经理.md
首席 SaaS 产品经理.md
首席代码审计与测试官.md
首席缺陷诊断专家.md
故障分诊智能体.md
QA质量保障.md
优化提示词.md
原型反推PRD.md
工程初始化脚本.md
FSD备机环境部署.md
FSD测试环境部署.md
UI优化.md
```

### Step 2：补装 Market 依赖

在新环境中通过 Skill 市场安装以下技能（按重要性排序）：

| Market Skill | 重要性 | 被谁引用 | 缺失影响 |
|---|---|---|---|
| **ai-pr-code-review** | 必装 | coding-reviewer, backend-architect, Coding Worker v3 | Java 代码审查规范缺失，CR 报告缺少稳定性/安全性/零容忍三项专项检查 |
| **frontend-code-reviewer** | 必装 | coding-reviewer, backend-architect, frontend-architect, fullstack-architect, Coding Worker v3 | TS/React/JS/Testing 四项前端规范缺失 |
| **code-reviewer** | 必装 | coding-reviewer | React/TS 大 diff（>200行）无法委托深度审查 |
| **ui-ux-pro-max** | 推荐 | frontend-architect, fullstack-architect, backend-architect | 设计系统搜索功能不可用，降级为内置设计规范 |
| **papi-mock-generator** | 可选 | test-architect | 美团项目 Mock 数据生成不可用 |
| **testing-strategies** | 可选 | test-architect | 测试策略参考不可用 |

### Step 3：验证

复制完成后，在新环境中运行任意一个 Coding Worker v3 任务，观察 CR 阶段是否能正常加载外部规范文件。如果看到"降级为内置规范"的提示，说明对应的 market skill 未安装。

---

## 二、自定义 Skill 间依赖关系

### 核心流水线（必须整体迁移）

```
Coding Worker v3 (Command)
  └→ coding-reviewer (CR 阶段)
       └→ ai-code-trust (Step 4.5, AI 代码信任检查)

test-architect (测试阶段)
  ├→ issue-triage (测试失败 → 自动分诊)
  └→ session-handoff (会话结束 → 断点保存)

fullstack-coordinator (跨工程协调)
  ├→ issue-triage (缺陷流转)
  └→ fullstack-boundary-contract (契约参考)
```

### 运维治理链

```
harness-watchdog (诊断)
  └→ doc-sync (修复)
       └→ iteration-close (归档)
```

### 完整依赖图

```
                    ┌─────────────────────────────────────────┐
                    │           入口层 (Commands)              │
                    │  Coding Worker v3 ──→ coding-reviewer   │
                    └──────────────────────────┬──────────────┘
                                               │
                    ┌──────────────────────────▼──────────────┐
                    │          质量守门层                       │
                    │  coding-reviewer ──→ ai-code-trust      │
                    │  test-architect ──→ issue-triage         │
                    │                  └→ session-handoff      │
                    └──────────────────────────┬──────────────┘
                                               │
  ┌────────────────────────────┐    ┌─────────▼──────────────┐
  │      架构规划层             │    │     缺陷管理层          │
  │  backend-architect         │◄───│  issue-triage           │
  │  frontend-architect        │    │    (排期→架构师)         │
  │  fullstack-architect       │    └────────────────────────┘
  │  fullstack-boundary-contract│
  └────────────────────────────┘
                                    ┌────────────────────────┐
                                    │     运维治理层          │
                                    │  harness-watchdog       │
                                    │    └→ doc-sync          │
                                    │         └→ iteration-close│
                                    │  harness-project-init   │
                                    │  feature-request        │
                                    │  session-handoff        │
                                    └────────────────────────┘
```

---

## 三、Market 依赖引用明细

### ai-pr-code-review

被引用的文件：

- `~/.catpaw/skills/skills-market/ai-pr-code-review/references/coding-standards-checklist.md`
- `~/.catpaw/skills/skills-market/ai-pr-code-review/references/stability-security-checklist.md`
- `~/.catpaw/skills/skills-market/ai-pr-code-review/references/zero-tolerance-checklist.md`

引用方：coding-reviewer, backend-architect, Coding Worker v2, Coding Worker v3

### frontend-code-reviewer

被引用的文件：

- `~/.catpaw/skills/skills-market/frontend-code-reviewer/references/ts.md`
- `~/.catpaw/skills/skills-market/frontend-code-reviewer/references/react.md`
- `~/.catpaw/skills/skills-market/frontend-code-reviewer/references/js.md`
- `~/.catpaw/skills/skills-market/frontend-code-reviewer/references/testing.md`

引用方：coding-reviewer, backend-architect, frontend-architect, fullstack-architect, Coding Worker v2, Coding Worker v3

### code-reviewer

被引用的文件：

- `~/.catpaw/skills/skills-market/code-reviewer/SKILL.md`

引用方：coding-reviewer（diff > 200 行时委托完整审查）

### ui-ux-pro-max

被引用的文件：

- `~/.catpaw/skills/skills-market/ui-ux-pro-max/SKILL.md`
- `~/.catpaw/skills/skills-market/ui-ux-pro-max/scripts/search.py`（注意：当前环境该脚本不存在，已触发降级）

引用方：frontend-architect, fullstack-architect, backend-architect

---

## 四、已知问题

**ui-ux-pro-max/scripts/search.py 缺失**：frontend-architect 和 fullstack-architect 引用了该脚本用于设计系统搜索，但当前环境中 ui-ux-pro-max 没有 scripts/ 目录。三个架构师 Skill 均已内置降级逻辑（"降级为内置设计规范"），不影响核心功能。

---

## 五、路径兼容性说明

所有跨 Skill 引用均使用 `~/.catpaw/skills/...` 格式，不含硬编码用户名。迁移到新机器后 `~` 会自动解析为新用户的 home 目录，无需修改任何文件内容。

唯一前提：新环境的 CatPaw Desk 使用相同的 `~/.catpaw/` 作为配置根目录。
