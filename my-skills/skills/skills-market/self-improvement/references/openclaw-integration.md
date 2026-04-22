# OpenClaw Integration — 完整指南

## 快速激活（推荐）

安装后运行一条命令即可完成所有初始化：

```bash
bash ~/.openclaw/skills/self-improvement/scripts/openclaw-activate.sh
```

脚本是幂等的，重复运行安全。

## 手动激活（如果需要精细控制）

### Step 1: 创建 .learnings/ 目录

```bash
mkdir -p ~/.openclaw/workspace/.learnings
```

复制模板或手动创建三个文件：

```bash
# 从 skill 资源复制
cp assets/LEARNINGS.md ~/.openclaw/workspace/.learnings/
```

或创建最小模板：

```bash
cat > ~/.openclaw/workspace/.learnings/LEARNINGS.md << 'EOF'
# Learnings
---
EOF

cat > ~/.openclaw/workspace/.learnings/ERRORS.md << 'EOF'
# Errors
---
EOF

cat > ~/.openclaw/workspace/.learnings/FEATURE_REQUESTS.md << 'EOF'
# Feature Requests
---
EOF
```

### Step 2: 安装 Hook（可选但推荐）

```bash
cp -r hooks/openclaw ~/.openclaw/hooks/self-improvement
openclaw hooks enable self-improvement
```

Hook 会在每次会话启动时注入一个简短提醒，让 Agent 在任务结束后评估是否需要记录学习经验。

### Step 3: 注入 SOUL.md 提醒

在 `~/.openclaw/workspace/SOUL.md` 末尾追加：

```markdown
## 自我改进（Self-Improvement）

犯错不可怕，重复犯错才可怕。遇到以下情况时，立即记录到 `.learnings/` 目录：

- **命令失败** → `.learnings/ERRORS.md`
- **用户纠正我**（"不对"、"其实是…"）→ `.learnings/LEARNINGS.md`，标记 `correction`
- **发现知识过时** → `.learnings/LEARNINGS.md`，标记 `knowledge_gap`
- **找到更好做法** → `.learnings/LEARNINGS.md`，标记 `best_practice`
- **用户要的功能不存在** → `.learnings/FEATURE_REQUESTS.md`

反复出现的 learning 要提升（promote）到 SOUL.md / TOOLS.md / AGENTS.md，变成永久规则。
```

## 验证

```bash
# 目录和文件
ls -la ~/.openclaw/workspace/.learnings/

# Hook
ls ~/.openclaw/hooks/self-improvement/

# SOUL.md 提醒
grep "自我改进" ~/.openclaw/workspace/SOUL.md
```

## 升级路径

| Learning 类型 | 升级目标 | 说明 |
|---|---|---|
| 行为模式 | `SOUL.md` | 沟通风格、交互原则 |
| 工作流改进 | `AGENTS.md` | 协作模式、子 agent 使用 |
| 工具 gotchas | `TOOLS.md` | 工具特殊配置、已知问题 |
| 跨会话知识 | `MEMORY.md` | 长期有效的决策和约定 |

## 与 OpenClaw 其他能力配合

### Inter-Session Communication

OpenClaw 提供跨会话工具，可用于分享学习经验：

- **sessions_list** — 查看活跃会话
- **sessions_history** — 读取其他会话的历史
- **sessions_send** — 发送学习经验到其他会话
- **sessions_spawn** — 派 sub-agent 做后台复盘

### 与 OpenViking 配合

如果已启用 OpenViking 插件（长期记忆），可将高价值 learning 通过 `memory_store` 写入向量记忆库，实现跨会话语义检索。

## 常见问题

**Q: 激活脚本运行后没有看到 hook enable 成功？**
A: 如果 gateway 不可用或超时，hook enable 会跳过但不影响核心功能。SOUL.md 提醒是主要的触发机制，hook 是补充。

**Q: 文件已存在会被覆盖吗？**
A: 不会。激活脚本检测到已有文件会跳过，不会丢失已有记录。

**Q: 可以在群聊 session 中使用吗？**
A: 可以记录到 `.learnings/`，但注意不要在群聊中暴露 `MEMORY.md` 的私人内容。
