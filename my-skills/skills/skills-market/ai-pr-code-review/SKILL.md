---
name: ai-pr-code-review
description: "前后端全栈代码审查一站式 Skill，支持单仓库和多仓库联合 CR。三层上下文感知 + 四层审查模型（P0零容忍/P1稳定性/P2规范/P3性能）+ Cross-Repo 跨仓库检查层（接口兼容/数据流/分布式事务/配置一致/上线顺序/灰度安全/监控/幂等）。全链路：生成学城文档 → 
评论到 
PR → 大象推送 → 登记多维表格，I/O 操作均重试4次失败通知提交人。触发：用户提到 review PR、代码审查、CR、帮我看下这个 PR，或提供 dev.sankuai.com PR 链接（单个或多个）。⚠️ 推荐使用 Claude Opus 4.5 及以上模型以获得最佳检出率。支持识别纯前端改动并自动委托 fe-ai-review 进行前端专项审查。"

metadata:
  skillhub.creator: "mengmuzi"
  skillhub.updater: "zengjiantao"
  skillhub.version: "V128"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "5205"
  skillhub.high_sensitive: "false"
---

# ✅ AI-PR-Code-Review — 线上正式版

> ---
> 📌 **【版本声明】这是线上正式版本，已发布到 Skillhub（skill_id=5205）。**
> - **不要在此做实验性修改**，改动前先同步到 Skillhub
> - 本地实验/集成开发请用：`~/.openclaw/workspace/skills/ai-cr-forlocal/`
> ---

# PR Code Review 自动化（单仓库 + 多仓库）

> 🚨 **执行强制要求（违反则本次 CR 无效）**：
> 1. **每个 Step 开始和结束必须在对话中输出进度**，格式见"过程可见性规范"，禁止静默执行
> 2. 格式：`▶️ Step N：xxx 开始...` → 执行 → `✅ Step N：xxx 完成 — 关键结果`
> 3. 用户反馈"没有进度输出"说明违反了本规则，必须在下次执行时严格遵守
> 4. **🚫🚫 禁止在任何 Step 完成后设置等待点**：每个 Step 完成后必须立即无条件执行下一个 Step，**尤其是 Stage 2 完成后必须直接进入 Stage 3（Step 6 → 7 → 8 → 9）**，绝对禁止输出「是否继续？」「等待用户确认」「回复后继续」等任何中断性语句。即使对话 compact/重开，新会话必须无条件跑完剩余 Step，违反本条 = CR 无效。

## 使用说明

### 触发场景

- **PR 链接**（必须，1 个或多个）：`dev.sankuai.com/code/repo-detail/{org}/{repo}/pr/{id}/diff`
- **ONES 需求 ID**（可选，多仓库推荐）、**学城目录**（可选）、**大象群聊**（可选）、**@人员**（可选）

> **如涉及对前端代码做审查，请展开 `fe-ai-review` Skill，阅读规则并执行前端专有审查流程。**

### ⚠️ 推荐模型

| 场景 | 推荐 | 说明 |
|------|------|------|
| 正式需求 CR / 多仓库联合 CR | **Claude Opus 4.5**（强烈推荐） | P0/P1 检出率最高；跨仓库关联推断需要大 context + 强语义理解；SKILL 指令遵从度最佳 |
| 简单改动（文件数 < 10，无跨仓库） | 轻量模型 | 速度快，适合轻量 CR |

> ⚠️ **使用弱模型（非 Opus 4.5）时**：Layer 2 反查步骤可能被跳过，跨仓库依赖分析可能漏报，P0/P1 检出率下降明显。多仓库 CR **强制推荐 Opus 4.5**。

### 单/多仓库自动判断

比较所有 PR URL 中的 `{org}/{repo}`：
- **相同或只有 1 个 PR** → 单仓库流程，跳过 Step 5 Cross-Repo 层
- **不同** → 多仓库流程，**两阶段串行**：阶段一逐仓完整 CR（每个 PR 独立跑 Step 3~4，禁止合并稀释），阶段二基于阶段一结论做跨仓 CX 检查（Step 5）

> ⚠️ **禁止合并稀释**：多 PR 同时跑时模型注意力被稀释，导致单仓检出率下降。必须串行，每个 PR 生成独立问题清单。

### 全链路重试规则（通用）

所有 I/O 操作（学城文档、PR 评论、多维表格）均遵循：**最多重试 4 次，每次间隔 2~3s，全部失败则输出到对话并大象通知 PR 提交人，不阻塞后续步骤。**

---

## 执行流程概览

### Stage 1 — 准备（环境 + 数据采集）

```
Step 0：环境自检 + 强制安装（每次执行前自动运行）
Step 1 + Step 2：【并行执行】Step 1（ONES需求上下文）与 Step 2（PR元信息提取）相互独立，必须在同一轮 tool call 中同时发出
  ├── Step 1：拉取 ONES 需求上下文（有 ONES ID 时执行，无则立即结束本 Step）
  └── Step 2：提取 PR 元信息 + 仓库归属 + 单/多仓库判断 + 分批判断 + 超大PR检测（文件数=500时触发2D：MCode API全量拉取 + 三层分层）
  └── 2F：识别纯前端改动 → 标记 IS_PURE_FRONTEND，Stage 2 分流
```

Stage 1 完成后，根据 2F 判断结果分流：
- 纯前端改动 → Stage 2 整体由 subagent 执行 fe-ai-review 替代
- 非纯前端改动 → Stage 2 正常执行

### Stage 2 — 审查（核心 CR）

**后端/混合路径：**

```
【单仓库】直接执行 Step 3~5
【多仓库】两阶段串行：
  ┌─── 阶段一：逐仓完整 CR（对每个 PR 独立完整执行）
  │    Step 3：三层上下文感知（每仓库独立，不缩减）
  │      ├── 3A. Layer 1 — 代码结构（文件分级读取 + 高危变更触发器）
  │      ├── 3B. Layer 2 — 变更影响（code-repo-search 全仓库反查，强制执行）
  │      └── 3C. Layer 3 — 业务语义（PR 描述 + ONES 需求 + 领域知识库 + COE 规则库）
  │    Step 4：四层审查（每仓库独立，完整跑，不因多仓库而缩减）
  │      ├── 4B. P0 零容忍异常 🔴 → 4C. P1 稳定性与安全 🟠
  │      ├── 4D. P2 规范与架构 🟡 → 4E. P3 性能与现代化 🔵
  │      └── 4F. Review 结论（四选一）
  │    ↑ 以上对每个 PR 循环执行，生成独立问题清单
  └─── 阶段二：跨仓 CX 检查（基于阶段一的接口契约变更清单）
       Step 5：Cross-Repo 跨仓库检查 Cross-Repo-01~08（专注跨仓边界，不重复单仓问题）
```

**纯前端路径（IS_PURE_FRONTEND=true）：**
🚨 **必须**启动独立 subagent（sessions_spawn），载入 fe-ai-review Skill 执行前端专项审查。
严禁自行审查前端代码，严禁跳过 subagent 直接进入 Stage 3。
subagent 返回后，以 fe-ai-review 报告为**唯一**结论源进入 Stage 3。

### Stage 3 — 发布（结果分发）

```
Step 6 + Step 7：创建学城 CR 文档 & 评论到 PR（并行执行，失败降级串行；Step 8 等 Step 6 完成后取文档 URL）
Step 8 + Step 9：大象群聊推送 & 多维表格登记（并行执行，失败降级串行）
Step 10：采纳率回收（第二轮 CR 自动触发）
Step 11：验证（全链路状态播报）
```

---

## 过程可见性规范（强制执行）

> **每个 Step 开始前和结束后必须输出状态，禁止静默执行。**

### 播报格式

```
▶️ Step N：{步骤名} 开始...
✅ Step N：{步骤名} 完成 — {关键结果摘要}
❌ Step N：{步骤名} 失败 — {错误原因} | 降级处理：{降级策略}
⚠️ Step N：{步骤名} 跳过 — {跳过原因}
```

### 各步骤播报要求

> 播报格式中 Step 编号前可选加 `[Stage N]` 前缀以增强可读性。

| Step | 开始播报 | 完成播报内容 | 失败处理 |
|------|---------|------------|---------|
| Step 0 | ▶️ 环境自检开始 | ✅ 环境就绪，共安装/验证 N 个依赖 | ❌ 列出缺失项，中止或询问继续 |
| Step 1+2 | ▶️ Step 1+2 并行开始（ONES上下文 + PR元信息） | ✅ Step 1：已加载需求：{标题}（或跳过）；Step 2：PR #{id}，{提交人}，{文件数}个文件，{单/多}仓库 | Step 1 失败跳过；Step 2 失败中止 |
| Step 2F | ▶️ 识别纯前端改动 | ✅ 纯前端改动：已展开阅读 fe-ai-review 的审查流程 / 非前端：继续主流程 | ⚠️ fe-ai-review 不可用，中止并告知 |
| Step 3 | ▶️ 三层上下文感知（Layer 1/2/3） | ✅ Layer 1 读取 N 个文件，Layer 2 反查 N 个引用，Layer 3 加载 {知识库内容概要} | ❌/⚠️ Layer 2 降级时必须告知 |
| Step 4 | ▶️ 四层审查开始 | ✅ 审查完成：P0={n}，P1={n}，P2={n}，P3={n}，结论：{四选一} | — |
| Step 5 | ▶️ Cross-Repo 跨仓检查 | ✅ CX 检查完成：{通过N项/发现M项问题} | ⚠️ 单仓库跳过 |
| Step 6 | ▶️ 创建学城 CR 文档 | ✅ 学城文档已创建：{url} | ❌ 降级输出到对话，不阻塞后续 |
| Step 7 | ▶️ 评论到 PR | ✅ 已发 P0/P1 行内评论 N 条 + 全局摘要 1 条 | ❌ 重试4次仍失败，大象通知提交人 |
| Step 8+9 | ▶️ 大象推送 & 多维表格（并行） | ✅ 已推送到全局群 + 多维表格已追加 1 行 | 任一失败降级串行；仍失败则通知提交人 |
| Step 10 | ▶️ 采纳率回收 | ✅ 采纳率：{n}%，误报率：{n}% | ⚠️ 无历史 CR，跳过 |
| Step 11 | ▶️ 全链路验证 | 见 Step 11 完成报告模板 | — |

> ⚠️ **AI 执行约束**：以上播报为强制要求，不得省略。步骤失败时必须明确说明失败原因和降级策略，不允许静默跳过。

---

---

# Stage 1 — 准备（环境 + 数据采集）

---

## 【Stage 1】Step 0：环境自检 + 强制安装 + 团队配置加载

**每次执行 skill 前必须先跑此步**，按顺序执行 0A → 0B → 0C → 0D，全部通过才能进入 Step 1。

> **💡 版本提醒（每次触发必须输出）**：在自检结果开头加上以下提示，提醒触发者保持最新版：
> ```
> 💡 提示：AI CR Skill 持续迭代中，效果越来越好！请确保已更新到最新版：
>    mtskills i ai-pr-code-review
> ```

### 0A. mtskills CLI 安装（元依赖，其他步骤的前提）

```bash
# 检测 mtskills 是否可用
if ! command -v mtskills &>/dev/null; then
  echo "⬇️ mtskills 未安装，正在安装..."
  npm i -g @mtfe/mtskills --registry=http://r.npm.sankuai.com
  echo "✅ mtskills 安装完成"
fi
```

### 0B. Skill 依赖自动安装

对以下每个 skill，先检测是否已安装，缺失则**立即强制安装，不等用户确认**：`code-cli` / `code-repo-search` / `citadel` / `citadel-database` / `ee-ones`

> 依赖清单、检测脚本详见 [references/env-setup-guide.md](references/env-setup-guide.md)

> **按需安装**：`fe-ai-review`（skill_id: 39902）不在 Step 0 预装，仅在 Step 2F 识别纯前端改动时检测 + 安装。缺失则通过 `mtskills i fe-ai-review --target-dir ~/.openclaw/skills` 安装后继续。

安装完成后逐行输出 `✅ {skill名} 已就绪`。

### 0C. 工具路径定位 + 浏览器登录校验

定位 `code-cli` 和 `code-repo-search` 的实际路径，赋值给 `$CODE_CLI` / `$REPO_SEARCH`。校验 dev.sankuai.com 登录状态，设置 `$BROWSER_AUTH` / `$REPO_SEARCH_AVAILABLE`。

> 路径定位命令、降级规则详见 [references/env-setup-guide.md](references/env-setup-guide.md)

> **⚠️ AI 执行规则（严禁违反）**：
> 1. **必须实际执行 shell 命令**获取 `$CODE_CLI` 路径，禁止把 `$(find ...)` 当文本字面量读取，路径为空时必须停止
> 2. **路径优先级**：①Skill 内置 `scripts/code_cli.py`（含 SSO 无感登录）→ ②外部 code-cli Skill。详见 `references/env-setup-guide.md`
> 3. **PR 行内评论必须用 `$CODE_CLI comment-add --url ... --file ... --line ... --line-type ADDED`**，禁止用 `code-cli pr comment`（该命令只支持全局评论）
> 4. `BROWSER_AUTH=false` 或 `REPO_SEARCH_AVAILABLE=false` 时，**必须告知用户影响并等确认**，禁止静默降级

### 0D. 配置加载（接口动态查询 + default fallback）

团队配置（群号、表格 ID、文档目录）由 `get_org_info.py` 接口动态返回，**无需在 yaml 中维护团队列表**。`cr-config.yaml` 仅保留 default 兜底配置。

> 配置文件路径：`cr-config.yaml`（skill 目录内）

**加载流程：**

1. 按以下顺序查找配置文件，取第一个找到的：
   1. `.cr-config.yaml`（当前目录，项目级，优先级最高）
   2. `~/.openclaw/workspace/.cr-config.yaml`（workspace 级）
   3. Skill 目录下的 `cr-config.yaml`（skill 自带默认值）

2. 用 python3 + PyYAML（或 regex）解析配置，提取 `default` 节点

3. **接口动态查询**：Step 2 调用 `get_org_info.py` 时，接口会同时返回 `chatGroupId`、`tableId`、`citadelParentId`。对每个字段：
   - **接口返回非空** → 直接使用接口值
   - **接口返回为空** → fallback 到 default 配置

4. 最终赋值以下变量：

| 变量 | 接口字段 | default 字段 | 说明 |
|------|---------|-------------|------|
| `$TABLE_ID` | `tableId` | `table_id` | 多维表格 ID |
| `$CITADEL_PARENT_ID` | `citadelParentId` | `citadel_parent_id` | 学城文档父目录 ID |
| `$TEAM_CHAT_GROUP_ID` | `chatGroupId` | `chat_group_id` | 团队大象群 ID（为空则不推团队群） |
| `$DOMAIN_KNOWLEDGE_PATH` | — | `domain_knowledge` | 领域知识库路径（仅来自配置文件） |
| `$NOTIFY_MIS_LIST` | — | `notify_mis` | CR 完成后通知的 MIS 列表（仅来自配置文件） |

**配置文件结构（仅 default）：**
```yaml
default:
  table_id: "2751197605"
  citadel_parent_id: "2752508777"
  chat_group_id: ""
  domain_knowledge: "references/domain-knowledge.md"
  notify_mis: ""
```

> ⚠️ **执行时序**：Step 0D 先加载 default 配置；Step 2 调用 `get_org_info.py` 后，用接口返回的非空字段覆盖对应变量。Step 6/8/9 使用最终值。

**用户手动覆盖**（优先级最高）：
- 使用者在触发时提供学城目录 ID → 解析出 contentId → 赋值 `$CITADEL_PARENT_ID`，覆盖接口值
- 不提供 → 使用接口值或 default

后续步骤统一使用 `$CODE_CLI` / `$REPO_SEARCH` / `$REPO_SEARCH_AVAILABLE` / `$BROWSER_AUTH` 以及上述配置变量。

---

## 【Stage 1】Step 1：ONES 需求上下文

> ⚡ **并行执行**：Step 1 与 Step 2 相互独立，必须在同一轮 tool call 中同时发出，不要等 Step 1 完成再执行 Step 2。
> 无 ONES ID 时，Step 1 立即跳过，不等待用户提供。

有 ONES ID → 调用 `ee-ones` 拉取标题、验收条件，注入 Step 4 Cross-Repo 合规性检查。无则跳过。

---

## 【Stage 1】Step 2：PR 元信息提取

### 2A. 输入类型判断（PR 链接 vs 分支名）

| 用户输入 | 处理方式 |
|---------|---------|
| `dev.sankuai.com/.../pr/{id}/diff` PR 链接 | 标准 PR 流程（见 2B） |
| `{org}/{repo}` + 分支名（如 `feature/xxx`） | **分支级 diff 流程（见 2C）**，用于无 PR 的服务 |
| 多仓库混合（部分有 PR、部分只有分支） | 有 PR 的走 2B，无 PR 的走 2C，统一进入后续 Step 3~4 |

### 2B. PR 链接入口（标准流程）

1. **用 code-cli 拉取 PR 元信息和文件列表**（优先，不用浏览器）：
   ```bash
   # 获取 PR 基本信息（标题、提交人、源/目标分支）
   $CODE_CLI pr view {prId} -R {org}/{repo} --json 2>&1

   # 获取变更文件列表
   $CODE_CLI pr diff {prId} -R {org}/{repo} --name-only 2>&1
   ```
   从 `pr view` 提取：标题、提交人 mis、源分支、目标分支；从 `--name-only` 统计文件数。

   > ⚠️ **截断检测**：`code-cli pr diff --name-only` 输出的文件数若**恰好等于 500**，说明 Code 平台触发了截断限制（`This pull request is too large to render. Showing the first 500 files.`），**必须进入 2D 超大 PR 模式**拉取完整列表，禁止用截断列表继续 CR。

2. **提交人姓名 + 组织架构**（必须，用于 Step 8 推送和 Step 9 表格登记）：
   ```bash
   # ⚠️ 必须调用固化脚本，禁止自己写 curl+python 解析（解析逻辑不稳定，历史上多次出现"未知组织"问题）
   SKILL_DIR=$(dirname "$(mtskills path ai-pr-code-review 2>/dev/null)" 2>/dev/null || echo "$HOME/.openclaw/workspace/skills/java-code-review")
   _ORG_JSON=$(python3 "${SKILL_DIR}/scripts/get_org_info.py" "{submitter_mis}" 2>/dev/null)
   _AUTH_NAME=$(echo "$_ORG_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('authorName','{submitter_mis}'))" 2>/dev/null || echo "{submitter_mis}")
   _ORG_ID=$(echo "$_ORG_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('orgId',''))" 2>/dev/null || echo "")
   # 接口同时返回团队配置，提取并覆盖 default（非空时覆盖）
   _API_CHAT_GROUP_ID=$(echo "$_ORG_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('chatGroupId',''))" 2>/dev/null || echo "")
   _API_TABLE_ID=$(echo "$_ORG_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tableId',''))" 2>/dev/null || echo "")
   _API_CITADEL_PARENT_ID=$(echo "$_ORG_JSON" | python3 -c "import sys,json; print(json.load(sys.stdin).get('citadelParentId',''))" 2>/dev/null || echo "")
   ```
   将 `_AUTH_NAME` 保存为 `{authorName}`，`_ORG_ID` 保存为 `{orgId}`。

   **团队配置覆盖**（接口值非空时覆盖 Step 0D 的 default）：
   - `_API_TABLE_ID` 非空 → `$TABLE_ID = _API_TABLE_ID`
   - `_API_CITADEL_PARENT_ID` 非空 → `$CITADEL_PARENT_ID = _API_CITADEL_PARENT_ID`
   - `_API_CHAT_GROUP_ID` 非空 → `$TEAM_CHAT_GROUP_ID = _API_CHAT_GROUP_ID`

   - **多维表格"组织架构"列**：直接填 `{orgId}`（纯数字，如 `103461`），**禁止填组织架构名称**
   - **⚠️ 强制校验**：若 `{orgId}` 为空，兜底填空字符串（**严禁填入 mis 号或推测的部门名**）
   > 大象推送中提交人统一格式：`{authorName}（{submitter_mis}）`，如 `曾建涛（zengjiantao）`

3. **分批判断**（满足任一 → 分批）：文件数 > 30 / 高危层文件 > 15 / 高危触发器 > 3

### 2D. 超大 PR 模式（文件数 = 500，触发截断检测后执行）

> **触发条件**：Step 2B 检测到文件数恰好为 500（Code 平台截断）。
> **详细流程见**：[references/super-large-pr-guide.md](references/super-large-pr-guide.md)

**执行摘要**（完整实现见上方文档）：

1. **2D-1 拉完整列表**：用 MCode API `/code/api/1.0/projects/{org}/repos/{repo}/pull-requests/{prId}/changes` 分页拉取，直到 `isLastPage=true`；Cookie 失败时降级并告知漏报风险
2. **2D-2 三层分层**：P0 核心层全量精读（无上限）→ P1 接口层软上限 200（超出按 Enum>DTO>Config>Client 优先级截断）→ P2 边缘层直接跳过
3. **2D-3 衔接**：超大 PR 模式下必然分批（Batch1 P0高危层 → Batch2 P0其他+P1接口 → Batch3 P1配置 → Batch4 汇总）；单批超时不阻塞，主 Agent 基于已完成批次输出结论

**分层结果播报格式**：
```
🔀 超大 PR 模式：共 {N} 个文件
   ✅ P0 核心层：{p0} 个文件（全量精读）
   📋 P1 接口层：{p1_read} 个文件（扫描）{p1_truncated > 0 ? "，另有 {p1_truncated} 个超出软上限跳过" : ""}
   ⏭ P2 边缘层：{p2} 个文件（已跳过，含 {test_count} 个测试文件）
   {p1_truncated > 0 ? "⚠️ 建议将 PR 拆分为多个小 PR 以获得完整 CR 覆盖" : ""}
```

### 2C. 分支级 diff 入口（无 PR 时使用）

> **场景**：多仓库 CR 中某个服务未创建 PR，但有开发分支。

优先用 `code-cli files list {org}/{repo} --branch {branch}` 拿文件列表，`code-cli diff {org}/{repo} --from master --to {branch}` 拿 diff；不支持时用 `code-repo-search` 搜索关键类名兜底。

- 变更文件列表/diff → 等同于 PR 入口，进入分批判断和三层上下文感知
- **学城文档标注「分支 CR（无 PR）」，Step 7 PR 评论跳过**，其余流程相同
- 若后续创建 PR，可复用本次结论并补充评论

**分批流程：** Batch1 高危层 → Batch2 业务层 → Batch3 配置层 → Batch4 汇总去重。上下文连续不重置。

---

### 2F. 纯前端改动识别（必须执行，不可跳过）

逐一检查 Step 2B/2C 获取的**全部**变更文件扩展名：

**前端文件扩展名白名单**：`.js` `.jsx` `.ts` `.tsx` `.vue` `.css` `.scss` `.less` `.sass` `.styl` `.html` `.ejs` `.hbs` `.json` `.lock` `.mjs` `.cjs`
**前端配置文件白名单**：`package.json` `yarn.lock` `pnpm-lock.yaml` `package-lock.json` `tsconfig.json` `.eslintrc.*` `.prettierrc.*` `.babelrc.*` `webpack.config.*` `vite.config.*` `.env.*`

判断规则：
- 变更文件**全部**命中上述白名单 → `IS_PURE_FRONTEND=true`
- 存在**任何一个**文件不在白名单中（如 `.java` `.xml` `.yml` `.properties` `.py` `.go` `.sql`）→ `IS_PURE_FRONTEND=false`

> ⚠️ 混合改动（前端+后端文件共存）→ `IS_PURE_FRONTEND=false`，按后端主流程走，前端部分本轮不覆盖。

**播报（必须输出，禁止跳过）**：
- `✅ Step 2F：IS_PURE_FRONTEND=true（{N}个前端文件，0个后端文件），Stage 2 将由 subagent 执行 fe-ai-review`
- `✅ Step 2F：IS_PURE_FRONTEND=false（含{M}个后端文件），Stage 2 正常执行后端审查`

---

---

# Stage 2 — 审查（核心 CR）

> 🚨🚨🚨 **Stage 2 分流（强制执行，违反 = CR 无效）**：
>
> ### 当 `IS_PURE_FRONTEND=true` 时：
>
> **严禁执行 Step 3/4/5。严禁自行阅读前端代码后输出审查结论。严禁以任何形式"摘要式"审查前端代码。**
>
> 你**必须**执行以下操作，缺一不可：
>
> 1. **安装 fe-ai-review**（如未安装）：
>    ```bash
>    mtskills i fe-ai-review --target-dir ~/.openclaw/skills
>    ```
>    skill_id: 39902。安装后**必须读取** `~/.openclaw/skills/fe-ai-review/SKILL.md`。
>
> 2. **读取 fe-ai-review 的 SKILL.md**，理解其完整审查流程和输出要求。
>
> 3. **启动 subagent（sessions_spawn）**，在 task 中明确指定：
>    - 读取并严格按照 `~/.openclaw/skills/fe-ai-review/SKILL.md` 的完整流程执行前端代码审查
>    - PR URL：{PR_URL}
>    - 变更文件列表：{前端文件列表}
>    - PR 提交人：{submitter_mis}
>    - code_cli.py 路径（用于拉取 diff）：{$CODE_CLI}
>    - code-repo-search 可用性：$REPO_SEARCH_AVAILABLE={true/false}
>    - 审查完成后将完整 Markdown 报告写入 `/tmp/cr_review_{prId}.md`
>    - 在返回消息中带回：P0/P1/P2/P3 计数、审查结论、issue 列表摘要
>
> 4. **等待 subagent 返回**。subagent 的 fe-ai-review 报告是 Stage 3 的**唯一结论来源**。
>
> 5. **失败处理**：
>    - fe-ai-review 安装失败 / subagent 执行失败 / 超时 → 向用户输出 `❌ 前端改动本轮未审查：fe-ai-review 执行失败`，**终止整个 CR 流程**
>    - **绝对禁止**在 fe-ai-review 失败后回退到 Step 3/4 后端审查链路
>    - **绝对禁止**在不启动 subagent 的情况下自行生成前端审查结论
>
> **自检**：如果你发现自己正在对前端代码执行 Layer 1/Layer 2/P0/P1 等后端审查步骤，说明你违反了本规则，立即停止并回到此处重新执行 subagent 流程。
>
> ### 当 `IS_PURE_FRONTEND=false` 时：
>
> 正常执行 Step 3 → Step 4 → Step 5。

---

## 【Stage 2】Step 3：三层上下文感知

**核心原则：bug 藏在「变化 × 存量语义」的交集里，光看 diff 不够。**

### 3A. Layer 1 — 代码结构

文件分级读取策略：

| 架构层 | 识别特征 | 读取策略 |
|--------|---------|---------|
| 数据流转/校验层 | Converter/Assembler/Checker/Validator/Filter | **读完整文件** |
| 业务/基础设施层 | Service/Manager/Dao/Repository/Client | **读变更方法完整方法体** |
| 接口定义/配置层 | DTO/Request/Response/Enum/Config/XML | **读 diff，扫触发器** |

**高危变更触发器（命中任一 → 强制扩展读取）：**
- DTO/Request 新增字段 → grep 全仓库消费方
- 常量/枚举值被修改 → grep 全仓库引用方
- 方法签名变更（参数类型/数量/顺序） → grep 全仓库调用方
- XML 新增 bean/consumer/producer → 读完整 XML，反查 Java 类
- interface 新增方法 → grep 所有实现类

### 3B. Layer 2 — 变更影响（**强制执行，不可跳过**）

**核心思路：diff 只告诉你"改了什么"，Layer 2 要告诉你"改了之后，谁受影响"。**

两个方向，哪个被 diff 触发就执行哪个（可同时触发）：

---

**3B-1「我新增了东西，谁在消费我？」— 适用场景举例**

- 新增枚举值（如 `ProductFilterTypeEnum.TECHNICIAN_XXX`）→ 哪些 switch/if 没有覆盖这个新值？
- 新增 DTO 字段（如 `filteredProductIds`）→ 哪些 Converter/序列化逻辑会读这个字段？
- 新增接口方法 / 公共方法 → 现有实现类是否都已同步？

**操作**：用 code-repo-search 在全仓库搜索新增的字段名/枚举名/方法名，找到所有引用方，逐一确认兼容性。

```bash
SEARCH="python3 ~/.openclaw/skills/code-repo-search/repo_search.py"

# 在整个仓库搜索「新增的类名/枚举值/方法名」
$SEARCH -r {org}/{repo} -k "{从diff提取的实际名称}" --ext .java --json

# 加 --path 限定源码目录（提速，大仓库推荐）
$SEARCH -r {org}/{repo} -k "{名称}" --ext .java \
  --path {repo-name}/src/main/java --json
```

结果中每个命中文件，精准读 1~3 个相关方法，判断「消费方是否兼容新增内容」。**发现不兼容 → 直接升级 P1。**

> code-repo-search 未安装时降级：在 `dev.sankuai.com/code/repo-detail/{org}/{repo}` 搜索框手动搜，不保证全覆盖，降级须在 CR 结论中注明。

---

**3B-2「我新调用了别人，被调用方的行为是什么？」— 适用场景举例**

- 新增 RPC/Pigeon 调用（新增 `@Reference` 注入或新增调用语句）→ 被调用接口在不同入参下返回什么？
- 新增对外部 Wrapper/Client 的方法调用 → 该方法的异常行为、null 返回、超时表现是什么？

> **触发条件**：diff 中出现新增的外部服务调用（新注入依赖 或 新增调用语句）

**禁止猜测被调用接口的语义**，必须实际读取：
1. 用 code-repo-search（或 dev.sankuai.com 搜索框）找到被调用接口的实现
2. 读接口定义：方法签名 + JavaDoc + 返回值 DTO 的字段注释
3. 确认在当前入参组合下的实际行为（尤其是空值/异常路径）
4. 重点检查：返回值字段的语义（特别是携带多种 ID 的字段，要确认装的是哪种 ID）

**多仓库时**：字段名从 diff 动态提取，跨仓库反查：
```bash
SEARCH="python3 ~/.openclaw/skills/code-repo-search/repo_search.py"

$SEARCH -r {org}/{repo-B} -k "{fieldName}" --ext .java --json
$SEARCH -r {org}/{repo-B} -k "get{FieldName}" --regex --ext .java --json
$SEARCH -r {org}/{repo-B} -k "{topicName}" --ext .xml --json
```

### 3C. Layer 3 — 业务语义

加载顺序（**三层叠加注入，编号越大越贴近当前仓库实际，优先用于业务语义判断**）：

1. **Skill 内置通用规则**（所有团队共享）：
   - `references/zero-tolerance-checklist.md` — P0 零容忍
   - `references/stability-security-checklist.md` — P1 稳定性
   - `references/coe-rules.md` — 历史 COE 提炼规则

2. **团队领域知识库**（Step 0 从 `.cr-config.yaml` 加载路径，默认 `references/domain-knowledge.md`）：
   ```bash
   # $DOMAIN_KNOWLEDGE_PATH 由 Step 0 设置
   # 支持绝对路径（/path/to/team-knowledge.md）或相对 skill 目录的相对路径
   cat "$DOMAIN_KNOWLEDGE_PATH" 2>/dev/null || echo "（未找到领域知识库，跳过）"
   ```
   内容：ID 体系、业务核心概念、双平台规范、团队特有 P0/P1 规则、命名规范

3. **仓库级 spec 文档**（双源合并，权威性最高，与前两层叠加注入，不覆盖通用 P0/P1 规则）：

   > **spec 文件两种来源都要读，合并去重后注入 Layer 3。有任一来源有内容即可；两处都没有才跳过，完全不影响原流程。**

   **来源 A — master 分支存量 spec**（仓库长期维护的领域文档）：
   ```bash
   # 搜索 master 分支上已有的 spec/mdp 文件（与来源 B 并行执行，不是串行）
   $SEARCH -r {org}/{repo} --list-files --path specs --ext .md 2>/dev/null
   $SEARCH -r {org}/{repo} --list-files --path .mdp/context --ext .md 2>/dev/null
   $SEARCH -r {org}/{repo} --list-files --path .mdp/rules/team --ext .md 2>/dev/null
   $SEARCH -r {org}/{repo} --list-files --path .mdp/rules/project --ext .md 2>/dev/null
   # 有结果 → 逐文件读取（code-repo-search 或 code-cli file get）
   # 无结果 → 该来源为空，与来源 B 合并后继续
   ```

   **来源 B — PR feature 分支新增 spec**（本次需求新增/更新的规范文档，与来源 A 并行执行）：
   ```bash
   # 从 Step 2 的 PR diff 文件列表中过滤，路径模式：
   #   specs/**/*.md  /  .mdp/context/*.md  /  .mdp/rules/team/*.md  /  .mdp/rules/project/*.md
   # 命中的文件从 diff 内容提取（-行或+行，取有实质内容的一侧）：
   $CODE_CLI pr diff {prId} -R {org}/{repo} --color never 2>&1 > /tmp/pr_diff.txt
   python3 -c "
   import sys
   content = open('/tmp/pr_diff.txt').read()
   target = '{filename}'
   idx = content.find(f'diff --git a/{target}')
   if idx < 0: sys.exit(0)
   next_idx = content.find('\ndiff --git', idx+10)
   chunk = content[idx:next_idx] if next_idx > 0 else content[idx:]
   lines = [l[1:] for l in chunk.split('\n') if l.startswith(('-','+')) and not l.startswith(('---','+++'))]
   print('\n'.join(lines))
   "
   # 无命中 → 跳过
   ```

   **合并与优先级**（两来源都读完后）：
   - 同名文件以来源 B（PR 新增）为准（代表最新设计意图）
   - 不同文件合并叠加

   **优先读取顺序**（文件多时按此顺序，时间有限可截断后面的）：
   1. `specs/*/spec.md` / `specs/*/design.md` — 需求规范 + 技术方案（最高价值）
   2. `.mdp/context/*.md` — 领域知识、业务概念、状态机
   3. `.mdp/rules/team/*.md`、`.mdp/rules/project/*.md` — 团队/项目规则

   **直接跳过**（纯工具脚手架，与业务语义完全无关）：`.mdp/workflows/`、`.claude/`、`.specify/`

   **`.mdp/rules/company/`**：仓库级 Java 编码规范，**可选读取**。Skill 已内置通用 P0/P1 规则，这里的内容多为代码风格/写法规范（并发、异常、日志等），不影响业务语义判断。若时间充裕（文件数 ≤ 5）可读取，用于补充 P2/P3 判断依据；文件多时优先跳过，不影响主要检出率。

   **注入用途**：校验实现与 design.md 一致性 / 用验收条件验证 P0/P1 合理性 / 用 domain.md 设计决策避免误报

   > 💡 **MDP-Context 接入**：根目录有 `.mdp/` 的仓库自动识别，无需在 `.cr-config.yaml` 配置。

4. **ONES 验收条件**（有 ONES ID 时从 Step 1 注入）

> 💡 **团队扩展点**：各团队只需维护自己的领域知识库（第2层），在 `.cr-config.yaml` 中配置路径即可，无需修改 Skill 本身。使用 MDP-Context 的仓库第3层自动生效，两者可同时使用。

---

## 【Stage 2】Step 4：四层审查

**核心问题：变更改变了什么语义，会不会破坏存量假设。**

**4A 前置确认**：code-repo-search 是否执行？所有触发器是否已反查？消费方是否兼容？任意不兼容 → 升级 P1。

**4B. P0 零容忍** 🔴（必须逐条扫描，不能跳过）
> 见 [references/zero-tolerance-checklist.md](references/zero-tolerance-checklist.md)

> 🚨 **P0 报出三要素（内部校验，不输出到文档）**：
> 每条疑似 P0 在内部必须同时满足以下三个条件，**不满足的直接按实际级别归类，不出现在 P0 中，也不标注"降级"字样**：
> 1. **代码证据确凿**：能指出 diff 中的具体行号和代码片段，不是"可能存在"
> 2. **触达路径可达**：异常输入/null 值能从实际调用链到达该代码点（外层有 try-catch 保护则触达被阻断）
> 3. **线上影响明确**：能说清楚"什么场景下、什么数据会触发、影响什么业务功能、影响范围多大"
>
> **内部分级（用户不可见，只看到最终级别）**：
> - 三要素全满足 → 报 P0
> - 任一要素不满足 → **直接归为 P2 或 P3**（不归 P1）
> - 防御性编程建议（"建议加深度限制"）→ 归为 P2/P3
>
> ⚠️ **禁止在输出文档中出现"降级"、"从 P0 降为"等字眼。三要素是内部判定逻辑，对用户透明——用户看到的每个级别就是最终结论。**

> 🚨 **P0/P1 输出格式（强制，每条必须包含以下全部字段，不可省略）**：
> ```
> **🔴 [P0-xx] {异常类型} — {一句话概括}**
> 
> - **文件**：{完整文件路径} L{起始行号}-L{结束行号}
> - **问题代码**：
>   ```java
>   {粘贴完整的问题代码片段，不要只贴一行，要包含足够上下文}
>   ```
> - **检出原因**：{为什么这是一个 P0/P1 问题？命中了哪条规则？与哪条零容忍/稳定性条目对应？为什么不是 P2？用 2-3 句话说清楚判定依据。}
> - **触达分析**：{完整调用链分析——这个方法被谁调用？入参从哪来（RPC/MQ/HTTP/配置/用户输入）？中间经过哪些转换？到达问题代码点时数据是什么状态？外层有无 try-catch？如果有，catch 了什么、处理了什么？}
> - **线上场景**：{具体业务场景描述——什么用户操作/什么定时任务/什么消息会触发这条代码路径？触发时数据长什么样？在什么条件下会出异常？发生概率是高（每天都可能）/中（特定数据才触发）/低（极端边界情况）？}
> - **影响范围**：{触发后的完整影响链——哪个接口/功能受影响？是单次请求失败还是批量失败？是否会导致上游重试风暴？有无降级兜底？对用户体验的具体影响是什么（页面报错/数据不一致/功能不可用）？影响面：单个用户/单个商户/全量？}
> - **修复建议**：
>   ```java
>   {给出具体的修复代码片段，不要只说"加 try-catch"或"加判空"。
>    展示修复后的完整代码，包含异常处理、日志、兜底逻辑。}
>   ```
>   {如有多种修复方案，列出推荐方案和备选方案，说明各自优劣。}
> ```
>
> ⚠️ P0/P1 的每个字段都必须有实质内容（≥2 句话），禁止用"可能""建议确认"等模糊措辞敷衍。如果某个字段写不出实质内容，说明证据不足，应归为 P2/P3。

**4C. P1 稳定性与安全** 🟠（合并前必须修复）
> 见 [references/stability-security-checklist.md](references/stability-security-checklist.md)

> 🚨 **P1 报出门槛（内部校验，不输出到文档）**：每条疑似 P1 在内部必须满足：
> 1. **diff 中有明确代码证据**（具体行号 + 代码片段），不是推测
> 2. **能说清线上影响场景**：什么请求/什么数据/什么时机会触发，不能是"理论上可能"
> 3. **排除已有保护**：确认调用链上没有 try-catch、降级、兜底等已有防护
>
> **不满足的直接归为 P2/P3 或不报，不在文档中提及判定过程。** 以下场景禁止报 P1：
> - "超时时间可能不够" — 无数据支撑的猜测 → 归为 P2/P3
> - "没有 failover" — 直连测试环境等非核心链路 → 归为 P2/P3
> - "没有重试" — 用户主动触发的同步操作 → 归为 P2/P3
> - "没有事务" — 跨 RPC + 乐观锁 + 逐步 catch 有意设计 → 不报
> - "catch(Exception) 范围过宽" — 已有 log.error + Cat 上报 → 归为 P2
>
> P1 输出格式同 P0（所有字段必须有实质内容）。

**4D. P2 规范与架构** 🟡（本 MR 修或跟进）
> 见 [references/coding-standards-checklist.md](references/coding-standards-checklist.md)
>
> **P2/P3 输出格式（精简，每条 2-3 行即可）**：
> ```
> **🟡 [P2-xx] {一句话概括}**
> {文件名} L{行号}：{问题描述 + 建议}，示例：`{修复代码片段}`
> ```

**4E. P3 性能与现代化** 🔵（可选）
> 见 [references/performance-checklist.md](references/performance-checklist.md)
>
> ```
> **🔵 [P3-xx] {一句话概括}**
> {文件名} L{行号}：{建议内容}
> ```

**4F. Review 结论（四选一）：**

| 结论 | 判定条件 |
|------|---------|
| ✅ 通过 | P0=0 且 P1=0 且 P2≤3 |
| 💚 通过（有建议） | P0=0 且 P1=0 且 P2>3 |
| 🟠 需修复 | P0>0 或 P1>0 或 Cross-Repo 有 P1 问题 |
| 🔴 需重新设计 | 架构级问题 |

> 🚨🚨🚨 **Step 4 完成后的强制指令（本条优先级最高，覆盖所有其他行为）**：
> - **立即、无条件、不等待任何用户输入，直接执行 Step 5（多仓库）或 Step 6（单仓库）**
> - **严禁**输出以下任何内容：「是否继续？」「回复确认后继续」「请告知是否发布」「如需继续请回复」「等待你的指示」或任何形式的停顿提示
> - **严禁**在对话中等待用户回复后再继续。用户不需要也不应该触发后续步骤。
> - 违反本条 = 本次 CR 无效，必须重跑。

---

## 【Stage 2】Step 5：Cross-Repo 跨仓库检查（多仓库专属，单仓库跳过）

**核心问题：A 承诺给 B 什么，B 期望从 A 得到什么，这两件事有没有对齐。**

**5-PRE：接口契约变更清单**（从 diff 提取，禁止硬编码字段名）

| 信号类型 | 识别方式 | 用于 |
|---------|---------|------|
| HTTP 接口签名变更 | `@RequestMapping`/`@GetMapping` 方法变更 | Cross-Repo-01 |
| DTO/VO 新增/删除字段 | 接口定义层字段级变更 | Cross-Repo-01、02、06 |
| MQ 消息体结构变更 | Mafka topic 相关类变更 | Cross-Repo-02、08 |
| 枚举新增/删除值 | 枚举文件新增/删除 case | Cross-Repo-02 |
| Lion/配置 key 变更 | `.yml`/`.properties`/Lion 文件变更 | Cross-Repo-04 |
| 反序列化配置/新增 required 字段 | Jackson/Fastjson 配置或 `@NotNull` 变更 | Cross-Repo-06 |
| MQ/RPC 新增消费或调用路径 | 新增 Consumer 类或 RPC 调用 | Cross-Repo-08 |

**Cross-Repo-01 接口变更兼容性**：用 code-repo-search 在 repo-B 中搜索 `{actualMethodName}` 找调用方，检查参数/返回值适配，灰度向前兼容。未适配 → **P1**

**Cross-Repo-02 数据流完整性**（最高优先级）：
- RPC/DTO：`code-repo-search -r {org}/{repo-B} -k "{fieldName}" --ext .java` → 检查读取和 null 判断
- MQ：检查 filter 字段与 map 取值字段是否一致（filter X 但取 Y → 新增场景丢失数据）
- 枚举：检查 B 的 switch/if 有无 default 兜底
- 无法正确消费 → **P1**

**Cross-Repo-03 分布式事务边界**：构建失败场景矩阵，检查 B 失败时补偿机制（重试幂等？定时补偿？）。无补偿 → **P1**

**Cross-Repo-04 配置一致性**：`code-repo-search -r {org}/{repo-B} -k "{configKey}" --ext .yml,.properties,.xml` 检查两边 key 一致性和上线顺序。不一致 → **P1**

**Cross-Repo-05 上线顺序依赖（必查）：**

| 场景 | 顺序 |
|------|------|
| A 新增接口，B 新增调用 | 先 A 后 B |
| A 删除接口，B 删除调用 | 先 B 后 A |
| A 修改接口（向前兼容） | 先 A 后 B |
| A 修改接口（不兼容） | 蓝绿/版本兼容 |
| A 新增枚举值，B 新增 case | 先 B（default 兜底）后 A |

**Cross-Repo-06 版本兼容性/灰度安全**：检查 B 的反序列化配置，未配置 `FAIL_ON_UNKNOWN_PROPERTIES=false` + A 新增字段 → **P1**

**Cross-Repo-07 监控覆盖度对齐**（P2）：检查 A/B 两侧 Cat.logEvent/Metrics 打点是否对称，key 是否一致。

**Cross-Repo-08 幂等性覆盖**：检查 B 的 `RECONSUME_LATER` 场景有无幂等保护（DB unique key / Redis setNX），A 的重试次数是否合理。无幂等 → **P1**

**Cross-Repo 层输出：** 逐项列出 Cross-Repo-01~08 结论（✅/🟠/不适用），注明上线顺序。

---

---

# Stage 3 — 发布（结果分发）

---

## 【Stage 3】Step 6：创建学城 CR 文档（**必须执行，无论 PR 大小，不可跳过**）

> ⚡ **并行执行**：Step 6 与 Step 7 相互独立（Step 7 不依赖学城文档 URL），必须在同一轮 tool call 中同时发出。
> 若并行失败，降级为串行：先完成 Step 6，再执行 Step 7。
> Step 6 的文档 URL 在 Step 8 大象推送时使用（Step 8 必须等 Step 6 完成）。

> 命令规范、失败处理、文档结构见 [references/citadel-write-guide.md](references/citadel-write-guide.md)
> 文档内容格式见 [references/comment-templates.md](references/comment-templates.md)

1. 将 CR 内容写入 `/tmp/cr_review_{prId}.md`（**必须用 `--file`，禁止 `--content`**）

2. 调 `citadel createDocument` 创建文档，`parentId = $CITADEL_PARENT_ID`
3. 从 PR overview 提取 CatPaw 评论，写入「与 CatPaw 对比」章节（无则跳过）
4. 失败降级：输出到对话 + 大象通知提交人，**不阻塞 Step 7**

---

## 【Stage 3】Step 7：评论到 PR

> ⚡ **并行执行**：Step 7 与 Step 6 相互独立，必须在同一轮 tool call 中同时发出，不要等学城文档创建完再发 PR 评论。
> 若并行失败，降级为串行：先完成 Step 6，再执行 Step 7。

> 评论内容格式见 [references/comment-templates.md](references/comment-templates.md)

**⚠️ 必须使用 `references/cr-comment.sh` 脚本发评论，禁止直接调用 `code-cli pr comment`（该命令只支持全局评论，无法发行内评论）。**

- **7-PRE**：验证鉴权可用
  ```bash
  python3 $CODE_CLI_PATH user-info
  ```

- **7A**：P0/P1 逐条行内评论，锚定代码行（只挂 ADDED/CONTEXT 行，不挂 REMOVED）

  > ✅ **使用 `--file-keyword` 传文件名，脚本自动从 `pr-changes` 解析完整路径，彻底避免路径拼错。**
  > 若关键词匹配到多个文件，脚本会报错并列出所有候选，换更精确的关键词重试即可。
  > 锚定失败（file 字段为 null）时脚本会报错并退出，**必须修正后重发，不可跳过**。

  ```bash
  bash /root/.openclaw/workspace/skills/java-code-review/references/cr-comment.sh inline \
    --url "{PR_URL}" \
    --file-keyword "{文件名，如 DealGroupExtendPriceProcessor.java}" \
    --line {行号} \
    --line-type ADDED \
    --text "{评论内容}"
  ```

- **7B**：P2/P3/Cross-Repo 发一条全局摘要评论
  ```bash
  bash /root/.openclaw/workspace/skills/java-code-review/references/cr-comment.sh global \
    --url "{PR_URL}" \
    --text "{全局摘要内容}"
  ```

- **7C**：验证，脚本已内置 `file` 字段非 null 校验；若提示 file 为 null **必须修正 --file 路径后重发，不可跳过**（file 为 null = 评论发成了全局评论，行内锚定失败）
  ```bash
  bash /root/.openclaw/workspace/skills/java-code-review/references/cr-comment.sh verify \
    --url "{PR_URL}"
  ```

失败重试 4 次（脚本内置），仍失败则大象通知提交人，不阻塞后续步骤。

---

## 【Stage 3】Step 8：大象群聊推送（双轨模式）

> ⚡ **并行执行**：Step 8 与 Step 9 相互独立，必须在同一轮 tool call 中同时发出，不要等 Step 8 完成再执行 Step 9。
> 若并行发出失败（任一步骤报错或无响应），立即降级为串行：先完成 Step 8，再执行 Step 9。

> 消息模板见 [references/comment-templates.md](references/comment-templates.md)
> API 实现细节见 [references/daxiang-notify-api.md](references/daxiang-notify-api.md)

使用 AI-CR Claw bot 直接调用大象开放平台 API，不依赖 OpenClaw bot。

> ⚠️ **强制规则（违反则 CR 结果无效）**：
> - **禁止**使用 OpenClaw `message` tool 发送大象群消息（它用的是 OpenClaw bot，不在目标群里，必然报 `code=70003 机器人不在该群`）
> - **必须**使用 `daxiang-notify-api.md` 中的 Python 脚本，通过 AI-CR Claw bot 调用大象开放平台 API 发送；凭证（appId/appSecret/GID）已在 `daxiang-notify-api.md` 中配置，直接使用，**禁止替换**
> - 任何情况下都不允许降级为 `message` tool，失败只允许重试或输出到对话提示手动发送

**双轨推送：**
- **全局汇总群**（GID: 70457605151）：所有人 CR 完必推，无需配置
- **团队专属群**（自动）：由 `$TEAM_CHAT_GROUP_ID` 决定（Step 2 接口返回，或 fallback 到 default），非空则自动推送

### 8A. 获取团队群 ID

**优先级（从高到低）**：
1. `$TEAM_CHAT_GROUP_ID`（Step 2 接口返回的 `chatGroupId`，非空时已在 Step 2 覆盖）
2. `TOOLS.md` 中手动配置的群 ID（搜索 `ai-cr`，兼容旧配置）
3. 均为空 → 仅推全局群，不阻塞 Step 9

### 8B. 执行

1. 取 token（每次重新取，无需缓存）→ 详见 `daxiang-notify-api.md`
2. 填充消息文本 → 详见 `comment-templates.md` 大象群聊推送模板
   - `{triggerName}（{triggerMis}）`：格式与提交人一致（姓名+mis）。triggerMis 从当前 session USER.md 或 `code_cli.py user-info` 动态获取，triggerName 通过 `code_cli.py user-info {triggerMis}` 获取真实姓名，**禁止硬编码**
   - ⚠️ **触发人是必填项，禁止省略**；消息中必须包含"触发人：{triggerName}（{triggerMis}）"，让群里的人知道是谁发起的这次 CR
3. **🚨 发送前校验（强制，不可跳过）**：消息内容**必须以 `【AI-CR】` 开头**，否则**拒绝发送**并在对话中输出 `❌ 消息未发送：内容未以【AI-CR】开头，疑似非 CR 消息`。此规则适用于所有目标群（全局群 + 团队群），无例外。
4. 推全局汇总群（必推）
5. 若有团队群 ID → 再推团队群
6. 每次发送失败重试最多 4 次，仍失败则输出到对话提示手动发送，**不阻塞 Step 9**
7. **Step 8 执行后必须在对话中输出推送结果**（✅已推送 / ❌推送失败 / ❌消息被拦截），禁止静默跳过
8. **重跑保证**：每次完整执行 CR 流程，无论是否重跑，Step 8 **必须无条件执行**，不依赖上下文中是否有"已推送"记录。重跑 = 再推一次，这是预期行为。



---

## 【Stage 3】Step 9：登记多维表格

> ⚡ **并行执行**：Step 9 与 Step 8 相互独立，必须在同一轮 tool call 中同时发出，不要等 Step 8 完成再执行 Step 9。
> 若并行发出失败（任一步骤报错或无响应），立即降级为串行：先完成 Step 8，再执行 Step 9。

> 写入命令、结论映射表、注意事项见 [references/table-write-guide.md](references/table-write-guide.md)

表格 ID 存于 `$TABLE_ID`（Step 2 接口返回的 `tableId` 非空时使用接口值，否则 fallback 到 default：`2751197605`）。

1. 调 `getTableMeta` 刷新 schema（列名匹配，防顺序变化）
2. **🚨 执行 `exec` 获取今日毫秒时间戳并校验**（见 table-write-guide.md，禁止 AI 自行推算）
3. 按模板拼 `--data`，结论值从强制映射表选取，日期用上一步 exec 的结果
4. 调 `addData` 追加（**严禁 deleteData / updateData**）
4. 失败重试 4 次，仍失败则通知提交人，不阻塞后续步骤
5. **Step 9 无条件执行**：每次完整执行 CR 流程都必须写入表格，不依赖上下文中是否有"已登记"记录。重跑 = 再追加一行，这是预期行为（效果回收必须完整）。

---

## 【Stage 3】Step 10：采纳率回收（第二轮 CR 自动触发）

> 模板见 [references/comment-templates.md](references/comment-templates.md)

检测到 PR 已有历史 CR 评论（含 `🤖 AI Code Review 结果`）时触发：
1. 扫描评论区，识别标记：✅已采纳 / ⚠️规则太严 / ⏭暂不修复 / ❌误报 / 无回复=未反馈
2. 未反馈 issue 检查对应代码行是否有变更 → 有则自动判定「已采纳」
3. 计算采纳率/有效率/误报率，追加「上轮 CR 采纳情况」章节到本轮文档

---

## 【Stage 3】Step 11：验证

报告各步骤状态：学城文档 URL 可访问 ✅/失败 ❌ | PR 评论已提交 | 大象消息已发送 | 多维表格已追加 | 采纳率已回收（如有）

**完成报告模板（强制格式）：**

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━
🤖 AI CR 完成报告
━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 PR：{org}/{repo}#{prId}（{提交人}）
🔍 审查结论：{✅通过 / 💚通过有建议 / 🟠需修复 / 🔴需重新设计}
   P0={n} P1={n} P2={n} P3={n}

📄 学城文档：{url} {✅ / ❌未生成}
💬 PR 评论：行内 {n} 条 + 全局摘要 {✅ / ❌未发出}
📣 大象推送：{✅已推送 / ❌失败，请手动发送}
📊 多维表格：{✅已登记 / ❌失败}
━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Step 11 完成后自动执行中间文件清理：**

```bash
# 清理本次 CR 产生的所有中间文件（/tmp 下，机器重启也会自动清）
rm -f /tmp/cr_review_{prId}.md \
      /tmp/cr_files_{prId}.txt \
      /tmp/pr_diff.txt
```

> 清理失败不影响 CR 结果，静默跳过即可。

---

## 注意事项

- **P0/P1 必须逐条扫描，不能跳过**
- **在用户确认前不要自动修改代码，Review first**

---

## References

| 文件 | 内容 |
|------|------|
| [references/zero-tolerance-checklist.md](references/zero-tolerance-checklist.md) | P0 零容忍异常完整清单 + 代码示例 |
| [references/stability-security-checklist.md](references/stability-security-checklist.md) | P1 稳定性与安全：EH/RM/TP/CC/FT/SEC 共 29 条规则 |
| [references/coding-standards-checklist.md](references/coding-standards-checklist.md) | P2 规范与架构：14 大类 100+ 条规则，含美团中间件规范 |
| [references/performance-checklist.md](references/performance-checklist.md) | P3 性能与现代化：DB/CACHE/COLL/RPC/MEM/JDK 共 27 条规则 |
| [references/coe-rules.md](references/coe-rules.md) | 历史 COE 提炼的 6 大类 11 条规则，含触发关键词映射 |
| [references/domain-knowledge.md](references/domain-knowledge.md) | 供商方向领域知识：7 类 ID 体系、双平台规范、命名规范、CR 触发映射 |
| [references/comment-templates.md](references/comment-templates.md) | 行内评论、全局评论、大象推送、学城文档结构、采纳率章节模板 |
| [references/daxiang-notify-api.md](references/daxiang-notify-api.md) | 大象群推送 API 实现：token 获取（client_secret_jwt）、发送消息代码、常见错误 |
| [references/table-write-guide.md](references/table-write-guide.md) | 多维表格写入：addData 命令、结论强制映射表、日期时间戳规范、多仓库规则 |
| [references/citadel-write-guide.md](references/citadel-write-guide.md) | 学城文档创建：--file 写入命令、失败处理、CatPaw 对比章节 |
| [references/pr-comment-guide.md](references/pr-comment-guide.md) | PR 评论操作：行内评论命令参数、7A/7B/7C 流程、file 字段验证 |

---

## 团队接入指南

详见 [`references/team-onboarding.md`](references/team-onboarding.md)。
