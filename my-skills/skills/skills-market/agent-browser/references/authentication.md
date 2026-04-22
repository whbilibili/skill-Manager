# 认证与登录持久化

## 方案选择

| 方案 | 适用场景 | 持久性 |
|------|---------|--------|
| State save/load | 通用，最可靠 | ✅ 手动管理 |
| --profile | 反复访问同一站点 | ✅ 自动 |
| Auth vault | 多账号管理 | ✅ 加密存储 |
| --session-name | 临时会话 | ⚠️ 不够可靠 |
| CDP connect | 复用已登录浏览器 | 依赖源浏览器 |

## State Save/Load（推荐）

```bash
# 登录后保存状态
agent-browser open https://app.example.com/login
agent-browser snapshot -i
agent-browser fill @e1 "$USERNAME"
agent-browser fill @e2 "$PASSWORD"
agent-browser click @e3
agent-browser wait --load networkidle
agent-browser state save auth.json

# 后续会话加载
agent-browser state load auth.json
agent-browser open https://app.example.com/dashboard
```

⚠️ state 文件含明文 token，记得加 .gitignore。
可设 `AGENT_BROWSER_ENCRYPTION_KEY` 加密。

## Profile 持久化

```bash
# 首次登录
agent-browser --profile ~/.myapp open https://app.example.com/login
# ... 登录操作 ...

# 后续自动已认证
agent-browser --profile ~/.myapp open https://app.example.com/dashboard
```

## Auth Vault（加密凭据管理）

```bash
# 保存（推荐 stdin 避免 shell 历史记录）
echo "$PASS" | agent-browser auth save github \
  --url https://github.com/login \
  --username user --password-stdin

# 登录
agent-browser auth login github

# 管理
agent-browser auth list
agent-browser auth show github
agent-browser auth delete github
```

## Session Name（⚠️ 已知不稳定）

```bash
agent-browser --session-name myapp open https://app.example.com/login
# ... 登录 ...
agent-browser close
# 下次可能恢复，也可能丢失 — 建议用 state save 替代
```

## 从用户浏览器导入

```bash
# 自动发现已运行的 Chrome
agent-browser --auto-connect state save ./auth.json
# 用该 state 访问
agent-browser --state ./auth.json open https://app.example.com
```
