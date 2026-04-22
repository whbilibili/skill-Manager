# 提醒机制配置

## OpenClaw（推荐用激活脚本）

最简方式 — 运行激活脚本自动完成所有配置：

```bash
bash ~/.openclaw/skills/self-improvement/scripts/openclaw-activate.sh
```

手动安装 hook：

```bash
cp -r <skill-dir>/hooks/openclaw ~/.openclaw/hooks/self-improvement
openclaw hooks enable self-improvement
```

Hook 行为：在每次会话启动时向 Agent bootstrap 文件中注入一个简短的学习提醒。

> 即使 hook 未生效，激活脚本也会将提醒直接写入 SOUL.md，确保 Agent 始终能看到记录规则。

## CatPaw Desk

CatPaw Desk 本身已有较完善的系统提示与工具调用流程，建议把脚本作为"补充提醒"。

手动运行：

```bash
./scripts/activator.sh
TOOL_OUTPUT="error: sample" ./scripts/error-detector.sh
```

## Claude Code / Codex

在 `.claude/settings.json` 中配置：

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

## 内置脚本

| 脚本 | 用途 |
|---|---|
| `scripts/openclaw-activate.sh` | OpenClaw 一键激活（创建目录 + hook + SOUL.md） |
| `scripts/activator.sh` | 输出"请评估是否有可沉淀经验"的提醒 |
| `scripts/error-detector.sh` | 检测工具输出中的常见错误关键词并提醒记错 |
| `scripts/extract-skill.sh` | 从 learning 条目抽取为独立 skill |

## 故障排查

若脚本无法执行：

```bash
chmod +x scripts/*.sh
```

若 `openclaw hooks enable` 超时，通常是 gateway 启动慢导致的，不影响核心功能（SOUL.md 提醒仍生效）。
