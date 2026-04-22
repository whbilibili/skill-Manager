---
name: auth-token-cache
description: >
  一句话：调内网服务前先跑一句，省掉反复授权。
  统一管理美团内部服务的认证 Token 缓存，支持 Friday MCP Token 无交互续期、SSO Cookie 检查、MOA 登录态管理。
  agent 调用内部服务前先检查缓存，有效直接复用，过期自动换票。
  触发词：认证缓存、token复用、减少授权、token续期、SSO续期、登录态管理、mcp token刷新、
  401自愈、403自愈、Friday MCP token、CIBA授权、mtsso换票。
  适用场景：(1) Friday MCP 调用前检查 token (2) 访问 .sankuai.com 前检查 SSO
  (3) 需要 MOA 登录态的操作 (4) cron 定时刷新认证 (5) 401/403 自愈换票

metadata:
  skillhub.creator: "linhongcheng"
  skillhub.updater: "linhongcheng"
  skillhub.version: "V20"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "4414"
  skillhub.high_sensitive: "false"
---

# Auth Token Cache

## 场景速查

| 你要做什么 | 跑这句 |
|-----------|--------|
| Friday MCP 调用前拿 token | `bash $SKILL/scripts/auth-cache.sh friday "<client_id>"` |
| 批量续期所有 MCP token | `bash $SKILL/scripts/auto-refresh.sh` |
| 检查某服务缓存是否有效 | `bash $SKILL/scripts/auth-cache.sh check <service>` |
| 获取已缓存的 token | `bash $SKILL/scripts/auth-cache.sh get <service>` |
| SSO Cookie 状态检查 | `bash $SKILL/scripts/auth-cache.sh sso` |
| 查看所有缓存状态 | `bash $SKILL/scripts/auth-cache.sh list` |
| 清除缓存重新换票 | `bash $SKILL/scripts/auth-cache.sh clear [service]` |

> `$SKILL` = 本 skill 安装目录。

## 首次使用

```bash
# 1. 安装换票依赖（一次性）
npm install @mtfe/mtsso-auth-official --registry=http://r.npm.sankuai.com

# 2. 验证安装
npx mtsso-moa-local-exchange --help

# 3. 测试换票（替换为你的 Friday MCP client_id）
bash "$SKILL/scripts/auth-cache.sh" friday "<your_client_id>"
```

## Friday MCP Token 换票流程

```
缓存有效？─→ 是 ─→ 直接返回 token
     │
     └─→ 否 ─→ mtsso-moa-local-exchange 换票（静默，无弹窗）
                  │
                  ├─→ 成功 ─→ 写入缓存，返回 token
                  └─→ 失败（MOA 过期）─→ CIBA 降级
                                           │
                                           ├─→ 大象 App 点击授权 → 换票成功
                                           └─→ 也失败 → exit 1，通知用户
```

**CIBA 降级**：MOA 登录态失效时自动触发，用户只需在大象 App 点击授权推送确认（无需扫码/打开浏览器）。

## 定时刷新（推荐）

将 token 续期配置为定时任务，工作时间每 2-4 小时执行一次：

```bash
bash "$SKILL/scripts/auto-refresh.sh"
# 遍历所有 friday_* 缓存，TTL < 1.5h 时主动换票
# 成功静默，CIBA 失败时告警
```

长假后（≥2天未换票）建议强制执行一次，不依赖缓存检查。

## 401/403 自愈

调用返回 401/403/token invalid 时：

```bash
TOKEN=$(bash "$SKILL/scripts/auth-cache.sh" friday "<client_id>" "<mis_id>")
# 成功 → 用新 token 重试原请求
# 失败 → 通知用户在大象 App 点击 CIBA 授权
```

## 全部命令

| 命令 | 说明 |
|------|------|
| `check <service>` | 检查 token 是否有效（提前 5min 判定过期）|
| `get <service>` | 获取缓存 token（纯文本）|
| `get-all <service>` | 获取完整缓存信息（JSON）|
| `set <service> <token> [client_id] [endpoint] [ttl]` | 写入缓存 |
| `ensure <service>` | 检查+获取，有效返回，过期 exit 1 |
| `list` | 列出所有缓存状态 |
| `clear [service]` | 清除全部或指定服务缓存 |
| `friday <client_id> [mis_id]` | Friday MCP 专用换票（含 CIBA 降级）|
| `friday-list` | 列出所有 friday_* 缓存状态 |
| `sso` | SSO Cookie 状态检查 |
| `moa` | MOA 登录态检查 |

## 详细参考

- 完整命令参数 → `references/commands.md`
- 集成代码示例 → `references/integration-examples.md`
