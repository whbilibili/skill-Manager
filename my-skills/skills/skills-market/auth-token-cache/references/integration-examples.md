# Auth Token Cache — 集成示例

---

## 最简集成（3 行）

```bash
SKILL_DIR="<your_skill_install_path>/auth-token-cache"
TOKEN=$(bash "$SKILL_DIR/scripts/auth-cache.sh" friday "<your_client_id>" "<your_mis_id>")
# 此后直接用 $TOKEN 调用 Friday MCP
```

---

## 其他 Skill 调用 Friday MCP 前的标准集成模式

```bash
# 配置：根据实际情况修改
SKILL_DIR="<your_skill_install_path>/auth-token-cache"
CLIENT_ID="<your_friday_client_id>"
MIS_ID="<your_mis_id>"
CACHE_KEY="friday_${CLIENT_ID}"

# Step 1: 检查缓存
CHECK=$(bash "$SKILL_DIR/scripts/auth-cache.sh" check "$CACHE_KEY" 300)
VALID=$(echo "$CHECK" | python3 -c "import sys,json; print(json.load(sys.stdin).get('valid',False))")
TTL=$(echo "$CHECK" | python3 -c "import sys,json; print(json.load(sys.stdin).get('remaining_seconds',0))")

if [ "$VALID" = "True" ]; then
  # 缓存有效，直接复用
  TOKEN=$(bash "$SKILL_DIR/scripts/auth-cache.sh" get "$CACHE_KEY")
  echo "[auth] 使用缓存 token，剩余 TTL: ${TTL}s"
else
  # 缓存过期，用 mtsso-moa-local-exchange 一步换票
  EXCHANGE_OUTPUT=$(npx mtsso-moa-local-exchange --audience "$CLIENT_ID" 2>/dev/null)
  NEW_TOKEN=$(echo "$EXCHANGE_OUTPUT" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('access_token',''))
except:
    print('')
" 2>/dev/null)
  if [ -n "$NEW_TOKEN" ]; then
    bash "$SKILL_DIR/scripts/auth-cache.sh" set "$CACHE_KEY" "$NEW_TOKEN" "$CLIENT_ID"
    TOKEN="$NEW_TOKEN"
    echo "[auth] mtsso-moa-local-exchange 换票成功"
  else
    # MOA 登录态失效，走 CIBA（大象 App 点击确认，无需扫码）
    TOKEN=$(bash "$SKILL_DIR/scripts/auth-cache.sh" friday "$CLIENT_ID" "$MIS_ID")
    echo "[auth] CIBA 换票完成"
  fi
fi

# 此后用 $TOKEN 调用 MCP
```

**触发时机建议**：在定时任务或 Skill 入口处检查 TTL，TTL < 5400s（1.5h）时主动触发续期。

---

## Agent 访问 .sankuai.com 前的标准集成模式

```bash
SKILL_DIR="<your_skill_install_path>/auth-token-cache"

# 检查 SSO Cookie
SSO_RESULT=$(bash "$SKILL_DIR/scripts/auth-cache.sh" sso)
echo "$SSO_RESULT"
# 如有自动化 SSO 刷新需求，配合 CDP 浏览器或 sso-cookie-manager 使用
```

---

## 定时自动刷新集成示例

在 cron 或定时任务中添加：

```bash
# 自动续期脚本：遍历所有 friday_* 缓存，TTL < 1.5h 时换票
bash "$SKILL_DIR/scripts/auto-refresh.sh"
```

推荐频率：每天 3~7 次（如工作时间每 2 小时一次）。

`auto-refresh.sh` 内部逻辑：

```bash
#!/bin/bash
# 遍历所有 friday_* 缓存
# TTL < 5400s → 用 mtsso-moa-local-exchange 无交互续期
# 续期失败（MOA 登录态失效）→ 记录日志，等待用户下次手动触发 CIBA
```

---

## 401/403 自愈集成

```bash
SKILL_DIR="<your_skill_install_path>/auth-token-cache"
CLIENT_ID="<your_friday_client_id>"
MIS_ID="<your_mis_id>"

# 调用 MCP 返回 401/403 时
TOKEN=$(bash "$SKILL_DIR/scripts/auth-cache.sh" friday "$CLIENT_ID" "$MIS_ID")
if [ $? -eq 0 ]; then
  echo "换票成功，用新 token 重试"
  # 重试原请求...
else
  echo "换票失败，请在大象 App 点击 CIBA 授权推送后重试"
fi
```
