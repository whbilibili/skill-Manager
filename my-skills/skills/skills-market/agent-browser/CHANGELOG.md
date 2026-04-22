# Changelog

## 1.0.0

- 初始版本：从 openclaw-bundled agent-browser skill (670行) 精简为 131 行
- 核心工作流：open → snapshot → @ref 交互 → re-snapshot
- 环境初始化：sandbox --no-sandbox、代理、证书配置
- 已知坑：Chromium ≤117 keyboard/wait bug 规避
- CDP 模式禁忌文档
- L3 references: 完整命令参考、认证持久化、高级功能
