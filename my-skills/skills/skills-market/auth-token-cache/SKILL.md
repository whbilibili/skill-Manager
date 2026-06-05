---
name: auth-token-cache
description: >
  一句话：调内网服务前先跑一句，省掉反复授权。
  基于 mtsso-skills-official 官方协议，在其上构建缓存管理层+定时续期+CIBA降级编排。
  agent 调用内部服务前先检查缓存，有效直接复用，过期自动换票。
  ⚠️ 限制：CIBA 协议授权（首次/过期后）仍需用户在大象 App 手动点击确认，无法完全自动化。
  触发词：认证缓存、token复用、减少授权、token续期、SSO续期、登录态管理、mcp token刷新、
  401自愈、403自愈、Friday MCP token、CIBA授权、mtsso换票。
  适用场景：(1) Friday MCP 调用前检查 token (2) 访问 .sankuai.com 前检查 SSO
  (3) 需要 MOA 登录态的操作 (4) cron 定时刷新认证 (5) 401/403 自愈换票
skill-dependencies:
  mtsso-skills-official:
    user_access_token_placeholder: ${user_access_token}
    audience:
      - b9ab5ad54bd141

metadata:
  skillhub.creator: "linhongcheng"
  skillhub.updater: "linhongcheng"
  skillhub.version: "V22"
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

## 与 mtsso-skills-official 的关系

本 Skill 基于 **mtsso-skills-official（ID: 6556）** 官方协议构建，是其上层缓存管理层：

| 层级 | 职责 | 提供者 |
|------|------|--------|
| **底层协议** | 定义换票CLI工具（moa-local-exchange/client-credentials/token-exchange/introspect） | mtsso-skills-official（官方） |
| **缓存+编排** | 缓存检查（避免重复换票）+ 定时续期 + MOA→CIBA降级链路 + 401自愈 | auth-token-cache（本Skill） |

- 缓存有效期遵循官方建议：**≤ 2小时**（实际设置 buffer 600s，提前10分钟判定过期）
- 底层换票调用均通过 `npx mtsso-moa-local-exchange` 实现，遵循官方参数契约
- 官方 Skill 更新时，本 Skill 需同步检查兼容性

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

## 自动续期能力边界

### ✅ 可完全自动（无需人工介入）

| 场景 | 机制 | 有效期 | 说明 |
|------|------|--------|------|
| Friday MCP Token 常规续期 | mtsso-moa-local-exchange | 3h | MOA 登录态有效时，静默换票，零弹窗 |
| oa-skills（学城/TT/审批） | MOA 无感登录 | 10min | 自动刷新，耗时~370ms，完全无感 |
| SSO Cookie 缓存复用 | 本地缓存读取 | session 级 | 浏览器 SSO 有效期内直接复用 |
| 401/403 自愈重试 | 检测错误码 → 重新换票 | — | MOA 有效时自动恢复 |

### ⚠️ 需要人工确认（无法完全自动化）

| 场景 | 触发条件 | 用户动作 | 频率 |
|------|---------|---------|------|
| CIBA 授权确认 | MOA 登录态失效，降级到 CIBA 流程 | 大象 App 收到推送 → 点击「同意」 | 约每 72h 一次（token TTL 过期时） |
| 新 audience 首次授权 | 从未对某 MCP Server 授权过 | 大象 App 点击授权推送确认 | 仅首次一次 |
| SSO 重新登录 | SSO session 完全过期（通常 7~14天） | 浏览器扫码登录 or CIBA 确认 | 低频（长假后） |
| mtskills CLI 过期 | 72h TTL 到期且无 refresh 通道 | 大象 App 点击 CIBA 授权推送 | 每 3 天一次 |

### 🚫 本 Skill 不能做的事

- **不能绕过 CIBA 人工确认** — 这是 mtsso 安全协议的设计，非技术限制
- **不能延长 token TTL** — 由服务端控制（3h/72h 等），客户端无法修改
- **不能替代浏览器 SSO 登录** — session 级 cookie 过期后必须重新登录
- **不能跨设备共享缓存** — token 绑定设备+用户，不可迁移

### 💡 减少授权弹窗的最佳实践

1. **配置定时换票 cron**：在 token 过期前主动续期，避免使用时才发现过期
2. **集中刷新时间**：将多个系统的 CIBA 触发集中在同一时段（如每周一/四早8点），减少零散弹窗
3. **长假前预刷新**：假期 >2天时，假前手动执行一次 `auto-refresh.sh`
4. **避免频繁 clear**：不要随意清除缓存，让 TTL 自然管理过期

## 详细参考

- 完整命令参数 → `references/commands.md`
- 集成代码示例 → `references/integration-examples.md`
