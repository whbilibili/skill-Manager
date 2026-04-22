# Auth Token Cache — 命令完整参数速查

脚本路径：`$SKILL_DIR/scripts/auth-cache.sh`

---

## 通用缓存命令

### check — 检查有效性

```bash
bash auth-cache.sh check <service> [buffer_seconds]
```

- `service`：缓存 key（如 `friday_<your_client_id>`、`sso`）
- `buffer_seconds`：提前判定过期的秒数（默认 300，即 5 分钟）
- 返回 JSON：`{"valid": true/false, "ttl": <剩余秒数>, "expires_at": <unix timestamp>}`
- 退出码：0=有效，1=过期/不存在

### get — 获取 token

```bash
bash auth-cache.sh get <service>
```

- 纯文本输出 token 字符串，可直接赋值给变量
- 无缓存时输出空字符串，退出码 1

### get-all — 获取完整信息

```bash
bash auth-cache.sh get-all <service>
```

- 返回完整 JSON（含 token、expires_at、cached_at、client_id 等字段）

### set — 写入缓存

```bash
bash auth-cache.sh set <service> <token> [client_id] [endpoint] [ttl_seconds]
```

- `service`：缓存 key
- `token`：token 字符串（JWT 时自动解析 exp 字段）
- `client_id`：可选，关联的 client id
- `endpoint`：可选，关联的 API endpoint
- `ttl_seconds`：可选，有效期秒数（JWT 则自动从 exp 读取）

### ensure — 检查并返回

```bash
bash auth-cache.sh ensure <service>
```

- 有效 → 直接输出 token（stdout），退出码 0
- 过期/不存在 → 错误信息到 stderr，退出码 1
- 适合脚本中直接赋值：`TOKEN=$(bash auth-cache.sh ensure friday_xxx) || handle_error`

### list — 列出所有缓存

```bash
bash auth-cache.sh list
```

输出 JSON 数组，每个条目包含 service、valid、remaining_seconds、cached_at。

### clear — 清除缓存

```bash
bash auth-cache.sh clear [service]
```

- 不带参数：清除全部缓存
- 带 `service`：仅清除指定服务

---

## Friday MCP 专用命令

### friday — token 检查+自动换票

```bash
bash auth-cache.sh friday <client_id> [mis_id]
```

流程（v2，mtsso-moa-local-exchange）：
1. 检查 `friday_<client_id>` 缓存（buffer=300s）
2. 有效 → 直接输出缓存 token，退出
3. 无效/过期 → 调用 `npx mtsso-moa-local-exchange --audience "<client_id>"` 一步换票
4. 换票失败（MOA 登录态失效）→ 触发 CIBA（需用户大象 App 点击确认）
5. 换票成功 → 写入缓存，输出新 token

参数：
- `client_id`：Friday MCP 的 client id（从 mcphub 管理页获取）
- `mis_id`：可选，MIS 号，用于 CIBA 降级流程

**续期逻辑说明**：
- MOA 登录态有效 → `mtsso-moa-local-exchange` 一步换票（无弹窗）
- MOA 登录态失效 → 必须走 CIBA（大象 App 内点击确认推送，无需扫码）
- 建议 TTL < 5400s（1.5h）时主动触发续期，避免 token 过期

### friday-list — 列出 Friday 缓存

```bash
bash auth-cache.sh friday-list
```

仅列出 `friday_*` 前缀的缓存条目。

---

## SSO Cookie 命令

```bash
bash auth-cache.sh sso
```

检查 SSO 登录状态并给出提示。如需自动刷新 SSO Cookie，建议配合 CDP 浏览器自动化或 sso-cookie-manager 使用。

---

## MOA 登录态命令

```bash
bash auth-cache.sh moa
```

- 检查 MOA 登录态是否有效（通过尝试 mtsso 换票验证）
- 返回 JSON status 字段

---

## 缓存文件结构

路径：`$SKILL_DIR/cache/auth-cache.json`（首次运行自动创建）

```json
{
  "friday_<your_client_id>": {
    "token": "<access_token>",
    "expires_at": 1742572800,
    "client_id": "<your_client_id>",
    "endpoint": "<mcp_endpoint>",
    "cached_at": 1742565600
  },
  "sso": {
    "token": "<sso_token>",
    "expires_at": 1742659200,
    "cached_at": 1742565600
  }
}
```

字段说明：
- `expires_at`：Unix timestamp，token 过期时间（JWT 自动解析 exp）
- `cached_at`：Unix timestamp，写入缓存时间
- `client_id`：Friday MCP client id（仅 friday_* 类型有）
- `endpoint`：MCP Server endpoint（仅 friday_* 类型有）

---

## 前置依赖

换票需要 `@mtfe/mtsso-auth-official` npm 包：

```bash
npm install @mtfe/mtsso-auth-official --registry=http://r.npm.sankuai.com
```

脚本会在首次换票时自动检查并安装。
