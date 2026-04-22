---
name: self-improvement-reminder
description: "Outputs a lightweight self-improvement reminder for CatPaw Desk workflows."
metadata: {"compatibility":{"legacyPath":"hooks/openclaw","note":"folder name kept for backward compatibility"}}
---

# Self-Improvement Reminder Hook（兼容路径）

此目录保留 `hooks/openclaw/` 命名仅用于兼容历史分发结构。

在 CatPaw Desk 生态中，建议把这里的 handler 作为“可复用提醒逻辑”使用，而不是依赖某个固定平台事件总线。

## 功能

该 hook 的核心行为是注入一个简短提醒，提示在任务结束后评估是否要把经验沉淀到 `.learnings/`。

## CatPaw Desk 推荐用法

如果你的本地流程支持事件注入，可在会话启动或任务结束时调用该 handler。

如果没有事件注入能力，直接使用 `scripts/activator.sh` 与 `scripts/error-detector.sh` 即可达到主要效果。