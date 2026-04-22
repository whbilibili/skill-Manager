---
name: self-improvement
description: "自我进化助手——把错误、纠正、知识缺口和能力诉求沉淀到 .learnings，并在必要时升级到 memory 或新 skill。支持 CatPaw Desk 和 OpenClaw 双平台，OpenClaw 安装后可一键激活（自动创建 .learnings、安装 hook、注入 SOUL.md 提醒）。"

metadata:
  skillhub.creator: "wangsongmian"
  skillhub.updater: "wangsongmian"
  skillhub.version: "V3"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "1648"
---

# Self-Improvement（自我进化学习助手）

把"踩坑"变成可复用资产，降低重复犯错概率。

## 什么时候使用

| 触发场景 | 建议动作 |
|---|---|
| 工具调用失败（命令、lints、web、MCP） | 写入 `.learnings/ERRORS.md` |
| 用户明确纠正你 | 写入 `.learnings/LEARNINGS.md`，分类 `correction` |
| 发现知识过时/认知缺口 | 写入 `.learnings/LEARNINGS.md`，分类 `knowledge_gap` |
| 找到更优实践 | 写入 `.learnings/LEARNINGS.md`，分类 `best_practice` |
| 用户提出当前能力不支持的诉求 | 写入 `.learnings/FEATURE_REQUESTS.md` |
| 同类问题持续复发（建议 >=3 次） | 评估升级到 memory 或抽取为 skill |

---

## OpenClaw 一键激活（推荐）

### 安装

通过 SkillHub 安装到 OpenClaw：

```bash
mtskills i mt --id 1648 --target-dir ~/.openclaw/skills
```

### 激活

安装后运行激活脚本，自动完成所有初始化：

```bash
bash ~/.openclaw/skills/self-improvement/scripts/openclaw-activate.sh
```

**激活脚本会做三件事：**

1. **创建 `.learnings/` 目录** — 在 `~/.openclaw/workspace/.learnings/` 下生成 `LEARNINGS.md`、`ERRORS.md`、`FEATURE_REQUESTS.md` 模板文件（已存在则跳过）
2. **安装 self-improvement hook** — 将 `hooks/openclaw/` 下的 handler 复制到 `~/.openclaw/hooks/self-improvement/` 并尝试 enable。Hook 在每次会话启动时做两件事：① 注入"记得记录学习经验"的行为提醒；② **读取 `.learnings/` 中已有的高优条目（最多 15 条），自动注入到 Agent prompt 中**，确保过去踩过的坑不会重复踩
3. **注入 SOUL.md 行为提醒** — 在 `~/.openclaw/workspace/SOUL.md` 末尾追加"自我改进"段落，确保 Agent 在每次会话中都能看到记录规则（已存在则跳过）

> 💡 激活脚本是幂等的，重复运行不会覆盖已有文件。

### 验证激活状态

```bash
# 检查 .learnings/ 目录
ls ~/.openclaw/workspace/.learnings/

# 检查 hook
ls ~/.openclaw/hooks/self-improvement/

# 检查 SOUL.md 提醒
grep "自我改进" ~/.openclaw/workspace/SOUL.md
```

### OpenClaw 目录结构

激活后的完整结构：

```
~/.openclaw/
├── workspace/
│   ├── AGENTS.md
│   ├── SOUL.md          ← 已注入自我改进提醒
│   ├── TOOLS.md
│   ├── MEMORY.md
│   ├── memory/
│   │   └── YYYY-MM-DD.md
│   └── .learnings/      ← 激活脚本创建
│       ├── LEARNINGS.md
│       ├── ERRORS.md
│       └── FEATURE_REQUESTS.md
├── hooks/
│   └── self-improvement/ ← 激活脚本安装
│       ├── handler.js
│       └── HOOK.md
└── skills/
    └── self-improvement/ ← mtskills 安装
        ├── SKILL.md
        ├── scripts/
        │   ├── openclaw-activate.sh
        │   ├── activator.sh
        │   ├── error-detector.sh
        │   └── extract-skill.sh
        ├── hooks/openclaw/
        ├── assets/
        └── references/
```

### OpenClaw 升级路径

| Learning 类型 | 升级目标 | 说明 |
|---|---|---|
| 行为模式 | `SOUL.md` | "Be concise, avoid disclaimers" |
| 工作流改进 | `AGENTS.md` | "Spawn sub-agents for long tasks" |
| 工具 gotchas | `TOOLS.md` | "Git push needs auth configured first" |
| 跨会话知识 | `MEMORY.md` | 长期有效的决策和约定 |

---

## CatPaw Desk 安装

### 推荐目录

```text
<workspace>/
├── .learnings/
│   ├── LEARNINGS.md
│   ├── ERRORS.md
│   └── FEATURE_REQUESTS.md
└── .catpaw/
    └── skills/
        └── self-improvement/
            └── SKILL.md
```

全局 skill 放在 `~/.catpaw/skills/`，项目级 skill 放在 `<workspace>/.catpaw/skills/`。

### 手动初始化

```bash
mkdir -p .learnings
# 复制 assets/LEARNINGS.md 作为模板，或手动创建三个文件
```

---

## 执行流程

先识别信号。常见信号包括：`run_terminal_cmd` 非零退出码、`read_lints` 新增高优先级诊断、`web_fetch` 失败、`CallMcpTool` 参数/schema 错误，以及用户明确纠正语句。

再选日志文件。偏纠正与认知更新写 `LEARNINGS.md`，偏失败异常写 `ERRORS.md`，偏能力缺口写 `FEATURE_REQUESTS.md`。

记录时至少包含时间、摘要、上下文、建议动作、相关文件或命令。

最后评估是否升级。若具有跨会话价值，升级到 memory；若可执行且可复用，抽取为新 skill。

## 条目模板

### Learning

```markdown
## [LRN-YYYYMMDD-XXX] category

**Logged**: ISO-8601 timestamp
**Priority**: low | medium | high | critical
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config | tooling

### Summary
一行总结

### Details
发生了什么、原先哪里错了、正确做法是什么

### Suggested Action
下一次如何避免

### Metadata
- Source: user_feedback | tool_error | self_reflection
- Related Files: path/to/file.ext
- Tags: tag1, tag2
- See Also: LRN-YYYYMMDD-XXX (optional)
- Pattern-Key: stable.key (optional)
- Recurrence-Count: 1 (optional)

---
```

### Error

```markdown
## [ERR-YYYYMMDD-XXX] operation_name

**Logged**: ISO-8601 timestamp
**Priority**: medium | high | critical
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config | tooling

### Summary
一句话描述失败点

### Error
粘贴原始报错（可多行）

### Context
- Tool/Command: ...
- Input: ...
- Environment: ...

### Suggested Fix
可执行修复建议

### Metadata
- Reproducible: yes | no | unknown
- Related Files: path/to/file.ext
- See Also: ERR-YYYYMMDD-XXX (optional)

---
```

### Feature Request

```markdown
## [FEAT-YYYYMMDD-XXX] capability_name

**Logged**: ISO-8601 timestamp
**Priority**: low | medium | high
**Status**: pending
**Area**: frontend | backend | infra | tests | docs | config | tooling

### Requested Capability
用户想要什么能力

### User Context
为什么需要，当前痛点是什么

### Complexity Estimate
simple | medium | complex

### Suggested Implementation
可行实现路径

### Metadata
- Frequency: first_time | recurring
- Related Features: xxx

---
```

## 状态与 Resolution

推荐状态：`pending`、`in_progress`、`resolved`、`wont_fix`、`promoted`、`promoted_to_skill`、`promoted_to_memory`。

完成后建议补充：

```markdown
### Resolution
- **Resolved**: 2026-03-02T12:00:00Z
- **Commit/PR**: abc123 / #42 / N/A
- **Notes**: 做了什么改动
```

## ID 规范

ID 采用 `TYPE-YYYYMMDD-XXX`，其中 TYPE 为 `LRN`、`ERR`、`FEAT`。

## 升级到 Memory

**OpenClaw**：写入 `MEMORY.md`（长期稳定信息）或 `memory/YYYY-MM-DD.md`（当天上下文）。

**CatPaw Desk**：使用 `memory_write(type="longterm")` 或 `memory_write(type="daily")`。

## 抽取为新 Skill

满足以下任意条件可抽取：重复出现、解决路径非直觉、用户明确要求固化。

```bash
./scripts/extract-skill.sh skill-name --dry-run
./scripts/extract-skill.sh skill-name
```

## 周期性复盘建议

```bash
grep -h "Status\*\*: pending" .learnings/*.md | wc -l
grep -n "Priority\*\*: high\|Priority\*\*: critical" .learnings/*.md
grep -l "Area\*\*: backend" .learnings/*.md
```

## Hook 集成（可选）

### OpenClaw

激活脚本已自动安装。也可手动：

```bash
cp -r <skill-dir>/hooks/openclaw ~/.openclaw/hooks/self-improvement
openclaw hooks enable self-improvement
```

**Hook 行为（agent:bootstrap 事件）：**

1. **注入行为提醒** — 提醒 Agent 在任务中遇到错误/纠正时记录到 `.learnings/`
2. **注入已有 learning** — 自动读取 `.learnings/LEARNINGS.md`、`ERRORS.md`、`FEATURE_REQUESTS.md`，筛选高优条目（critical > high > medium），最多 15 条、4000 字符，作为 `PAST_LEARNINGS.md` 虚拟文件注入 prompt

跳过的条目：`wont_fix`、`promoted_to_skill`、`promoted_to_memory` 状态的条目不会注入（已沉淀到其他地方）。

**配置项**（在 handler.js 顶部可调）：

| 变量 | 默认值 | 说明 |
|---|---|---|
| `MAX_ENTRIES` | 15 | 最多注入条目数 |
| `MAX_CHARS` | 4000 | 注入内容字符上限 |
| `INCLUDE_RESOLVED` | true | 是否包含已解决的条目 |

### Claude Code / Codex

```json
{
  "hooks": {
    "UserPromptSubmit": [{
      "matcher": "",
      "hooks": [{
        "type": "command",
        "command": "./skills/self-improvement/scripts/activator.sh"
      }]
    }],
    "PostToolUse": [{
      "matcher": "Bash",
      "hooks": [{
        "type": "command",
        "command": "./skills/self-improvement/scripts/error-detector.sh"
      }]
    }]
  }
}
```

## 兼容性说明

本 skill 同时支持 OpenClaw 和 CatPaw Desk。保留了 `references/openclaw-integration.md` 与 `hooks/openclaw/` 的历史路径以兼容旧分发结构。
