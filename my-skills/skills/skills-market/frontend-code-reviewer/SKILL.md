---
name: frontend-code-reviewer
description: 前端代码审查专家 - 扫描 Git 变更（暂存区/工作区），产出 PR 审查报告。覆盖 JS/TS/React/Vue/单测规范，确保代码符合公司标准。

metadata:
  skillhub.creator: "liuxinru"
  skillhub.updater: "liuxinru"
  skillhub.version: "V2"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "1456"
  skillhub.high_sensitive: "false"
---

# 前端代码审查专家 (Frontend Code Reviewer)

## 任务目标
- 本Skill用于：扫描Git变更，产出完整的代码审查报告
- 能力包含：复杂度分析、规范审查、问题分类（强制/建议）、结构化报告生成
- 触发条件：用户要求审查代码、PR提交前检查、代码质量评估

## 前置准备
- 依赖说明：本Skill不需要额外依赖，使用Git命令和Node.js环境
- 环境要求：
  - 必须在Git仓库中执行
  - 需要有Git命令行工具
  - 建议在项目根目录执行

## 操作步骤

### 标准流程

#### 0. 扫描Git变更并产出报告

**第一步：运行复杂度分析脚本**

```bash
# 方法1：如果Skill已解压到项目目录
node frontend-code-review/scripts/analyze_complexity.js

# 方法2：使用绝对路径（根据实际Skill安装位置调整）
node /path/to/skill/scripts/analyze_complexity.js
```

该脚本会自动：
- 检测暂存区（Staged）或工作区（Unstaged）的前端文件变更
- 分析文件行数复杂度（业界标准：< 300 行警告，> 500 行严重）
- 输出 Markdown 格式的变更分析报告

**第二步：读取 Git Diff**

```bash
# 暂存区变更（推荐）
git diff --cached

# 或工作区变更
git diff
```

**第三步：按规范逐项审查**

根据变更文件的类型，按需加载对应的规范参考文件：
- 通用规范 → [references/common.md](references/common.md)
- JS 文件 → [references/js.md](references/js.md)
- TS 文件 → [references/ts.md](references/ts.md)
- React 组件 → [references/react.md](references/react.md)
- Vue 组件 → [references/vue.md](references/vue.md)
- 测试文件 → [references/testing.md](references/testing.md)

#### 1. 审查代码变更

**智能体执行以下审查**：
- 以PR描述为契约，验证代码变更是否符合预期
- 对照规范检查每项变更
- 区分优先级：优先处理【强制】项（阻塞性），其次【建议】项（风格）
- 工具优先：ESLint/Prettier可自动修复的问题不逐条列出，统一建议运行修复命令

#### 2. 产出审查报告

使用标准模板产出完整的PR审查报告（见"输出格式"章节）

### 可选分支

- **当暂存区为空时**：自动检查工作区变更
- **当存在大量格式问题**：在"建议优化"中统一建议运行 `npm run lint -- --fix`
- **当无法验证某些内容**：明确标记为"未验证(Unverified)"并建议验证步骤

## 操作准则 (Operating Rules)

1. **以 PR 描述为契约**：验证代码变更是否符合 PR 描述的预期，检查 Diff 是否与描述一致。
2. **区分优先级**：优先处理**必须修复（阻塞性）**的问题（对应规范中的【强制】项），其次才是风格建议（对应规范中的【建议】项）。
3. **工具优先 (Leverage Tools)**：
   - **如果是 ESLint/Prettier 可自动修复的问题**（如：引号类型、分号、缩进、空格、简单的 `let`/`const` 替换）：**不要逐行列出**。直接在"建议优化"中添加一条："存在大量格式/风格问题，建议运行 `npm run lint -- --fix` 或相应格式化命令"。
   - **如果是逻辑/架构问题**：必须逐条指出并给出建议。
4. **明确验证状态**：如果你无法验证某些内容，请明确标记为"未验证 (Unverified)"并建议最小验证步骤。
5. **确认责任人**：任何合并的代码必须有明确的人类负责人。

## 输出格式 (Output Format)

使用此模板产出 PR 审查报告：

```markdown
## 总结 (Summary)

- [一句话描述：变更内容 + 原因]
- [一句话描述：整体风险等级：低/中/高 + 原因]

## 📊 变更分析报告 (Complexity & Stats)

_(运行 `analyze_complexity.js` 的结果)_
| 状态 | 行数 | 文件 | 建议 |
|---|---|---|---|
| [状态] | [行数] | [文件名] | [建议] |

## 必须修复 (Must-fix / Blocking)

_对应规范中的【强制】项或严重逻辑错误_

- [ ] **[问题类型]**: 理由 + 位置 (文件/函数) + 建议修复方案

## 建议优化 (Suggestions / Non-blocking)

_对应规范中的【建议】项或代码风格优化_

- [ ] **[ESLint/风格]**: (如果存在大量格式问题) 建议运行 `eslint --fix` 统一修复格式。
- [ ] **[问题类型]**: 理由 + 建议改进

## 锦上添花 (Nice-to-have)

- [ ] **[优化点]**: 可选的打磨建议

## 测试计划 (Test Plan)

- **已验证 (Verified)**:
  - [ ] 你（或 CI）已验证的内容 (单元测试/E2E/手动)
- **未验证 (Unverified)**:
  - [ ] 剩余未验证内容及验证方法 (具体的命令/步骤)

## 风险与回滚 (Risk & Rollback)

- **风险领域**: [例如：鉴权, 路由, 缓存, 性能]
- **回滚方案**: [如何回滚 / 特性开关 / 安全降级策略]

## 权责检查 (Ownership / Process Checks)

- **人类负责人**: [姓名/角色 或 "缺失"]
- **AI 生成代码**: [是/否/未知] (如果是，请确认作者理解关键变更)
```

## 资源索引

- **必要脚本**：[scripts/analyze_complexity.js](scripts/analyze_complexity.js)（用途：扫描Git变更、分析复杂度、生成Markdown报告）
- **规范参考**（完整规范清单）：
  - [references/COMMON.md](references/COMMON.md) - 通用规范（文件/目录/包）
  - [references/JAVASCRIPT.md](references/JAVASCRIPT.md) - JavaScript 规范
  - [references/TS.md](references/TS.md) - TypeScript 规范
  - [references/REACT.md](references/REACT.md) - React 规范
  - [references/VUE.md](references/VUE.md) - Vue 规范
  - [references/TESTING.md](references/TESTING.md) - 单元测试规范

## 注意事项

- **脚本路径**：根据Skill的实际安装位置调整路径。如果Skill安装在项目根目录的`frontend-code-review/`下，使用`node frontend-code-review/scripts/analyze_complexity.js`；如果在其他位置，使用绝对路径。
- 审查时必须同时覆盖：**通用（文件/目录/包）+ JS + TS + React + Vue + 单测**
- 任何【强制】项违规默认视为 **Must-fix（阻塞）**；【建议】项放入 Suggestions/Nice-to-have
- 无论是人类编写的代码还是 AI 生成的代码，都应采用相同的审查标准
- 智能体负责解读规范、匹配违规、生成报告；脚本负责Git操作和复杂度计算
- 检查结果仅为建议，需结合实际项目情况进行判断和调整

## 快速检查清单 (Quick Checklist)

_(复制并粘贴到回复末尾)_

- [ ] PR 描述清晰，UI 变更包含截图/视频
- [ ] 明确了人类负责人
- [ ] **ESLint/Prettier 检查通过** (无大量格式噪音)
- [ ] **代码复杂度检查通过** (无单个文件 > 500行)
- [ ] 代码、日志、截图中无密钥/PII 泄露
- [ ] 已处理 错误/加载/空 状态
- [ ] 外部输入已进行 类型定义 + 运行时守卫
- [ ] **TS 规范**：无 `any`，无滥用非空断言 `!`
- [ ] **框架规范**：Hooks 依赖正确 (React) / 无 v-if & v-for 冲突 (Vue)
- [ ] **性能**：无明显重渲染或包体积回退
- [ ] **测试**：单元测试已更新，且无 console.log 验证
