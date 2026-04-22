# AGENTS.md 模板

以下是生成 AGENTS.md 时必须遵循的完整模板结构。用项目实际信息替换 `[占位符]`。

---

```markdown
# 🤖 AI 协作工程空间全局路由 (Agent Manifest)

> **项目**：[项目名称] — [一句话项目描述]
> **最后更新**：[日期]（[本次更新说明]）

---

## ⚡ 启动工作流（每次新会话必须按序执行）

> **任何 Agent 在写第一行代码之前，必须完成以下步骤。跳过任何一步都会导致上下文缺失。**

```
Step 1 → 读本文件（AGENTS.md）             ← 你正在做这步
Step 2 → 读 docs/exec-plans/progress.txt  ← 了解当前攻克点和卡点
Step 3 → 读 docs/exec-plans/feature-list.json ← 锁定唯一 status=pending 的 Task ID
Step 4 → 读 docs/caveats.md               ← 避免重复踩坑
Step 5 → 按需读对应模块文档               ← 见下方索引目录树
```

---

## 📌 核心准则

本仓库受 AI 自动化工作流驱动。

- **编码执行者**：只读 `docs/exec-plans/feature-list.json`，锁定单个 Task ID 后开始工作，**禁止自行扩大范围**
- **架构师**：有权索引所有文档，创建新规范文档后必须同步更新本文件
- **禁止行为**：未经授权修改 `docs/` 下的 PRD 文件；在未读 `progress.txt` 的情况下开始编码；同时推进多个 Task

---

## 📂 索引目录树 (Index)

### 1. 状态与上下文 (State & Context) — ⚠️ 动态更新

| 文件路径 | 权限 | 说明 |
|---------|------|------|
| `@docs/exec-plans/feature-list.json` | 读写 | **【核心】任务流转状态机** |
| `@docs/exec-plans/progress.txt` | 读写 | **【核心】短期记忆交接棒** |
| `@docs/exec-plans/issues.json` | 读写 | 缺陷追踪池（如存在） |

### 2. 项目文档 (Documentation) — 📖 静态查阅

| 文件路径 | 权限 | 说明 |
|---------|------|------|
| `@docs/PRD.md` | 只读 | 产品需求原件 |
| `@ARCHITECTURE.md` | 只读 | 架构约束全集 |
| `@docs/api-spec.md` | 只读 | 接口契约规范 |
| `@docs/caveats.md` | 只读 | 踩坑永久档案 |
| `@docs/exec-plans/tech-debt-tracker.md` | 只读 | 技术债追踪 |

### 3. 环境脚本 (Scripts) — 🔧 执行前阅读注释

| 文件路径 | 权限 | 说明 |
|---------|------|------|
| `@init.sh` | 执行 | **幂等验证脚本**（无副作用，可随时执行） |
| `@start.sh` | 执行 | **服务启动脚本**（有副作用，会占用端口） |
| `@stop.sh` | 执行 | **服务停止脚本** |

---

## ✅ 完成定义 (Definition of Done)

一个 Task 被标记为 `completed` 当且仅当满足以下全部条件：

- [ ] **实现完整**：所有 acceptance_criteria 逐条通过
- [ ] **编译通过**：`[编译命令]` 无报错
- [ ] **验证通过**：执行 feature-list.json 中该 Task 的 `verification` 命令，输出符合预期
- [ ] **测试通过**：相关模块测试用例全部 PASS（如有）
- [ ] **状态更新**：feature-list.json 中该 Task 的 `status` → `completed`
- [ ] **进度同步**：progress.txt 更新 `[Current Focus]` 和 `[Next Steps]` 区块
- [ ] **文档同步**：如有接口变更，同步更新 `docs/api-spec.md`

---

## 🔍 验证命令清单 (Verification Commands)

> 每次提交前必须执行，确保不引入回归。

```bash
# 1. 编译验证（最快，必须通过）
[项目编译命令]

# 2. 单元测试
[单元测试命令]

# 3. 接口冒烟测试（需服务运行中）
[curl 冒烟测试命令]
```

---

## 📋 会话结束 Checklist（End of Session）

> 每次会话结束前必须完成，确保下一个 Agent 能无缝接手。

```
□ 1. 更新 docs/exec-plans/progress.txt
      - [Current Focus] 精确到当前卡在哪个文件/方法
      - [Next Steps] 写出下一步具体指令（不是方向，是命令）
      - [Key Decisions] 记录本次会话的重要技术决策

□ 2. 更新 docs/exec-plans/feature-list.json
      - 已完成的 Task：status → "completed"

□ 3. 文档同步（如有接口变更）
      - docs/api-spec.md
      - docs/CHANGELOG/CHANGELOG-{今日日期}.md

□ 4. 验证通过
      - 执行编译验证命令
      - 相关测试用例全部 PASS

□ 5. 运行 harness-watchdog 巡检（可选但推荐）
```

---

## 🚨 已知死胡同（避免重复踩坑）

| 现象 | 根因 | 解法 | 详见 |
|------|------|------|------|
| [填入遇到的坑] | [根因] | [解法] | [文档引用] |
```
