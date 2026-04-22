#!/bin/bash
# 自动续期脚本，可放入 cron 或定时任务
# 遍历所有 friday_* 缓存，TTL < 5400s（1.5h）时自动用 mtsso-moa-local-exchange 换票
# 换票失败（MOA 登录态失效）→ 记录日志，等待用户下次手动触发 CIBA

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CACHE_MANAGER="$SCRIPT_DIR/cache-manager.py"

echo "=== Auth Token 自动续期检查 $(date) ==="

# 确保 mtsso 包可用
if ! npm list @mtfe/mtsso-auth-official --depth=0 &>/dev/null 2>&1; then
  echo "📦 安装 @mtfe/mtsso-auth-official..."
  npm install @mtfe/mtsso-auth-official --registry=http://r.npm.sankuai.com --silent 2>&1 | tail -1
fi

# 遍历所有 friday_* 缓存
python3 "$CACHE_MANAGER" list 2>/dev/null | python3 -c "
import sys, json
items = json.load(sys.stdin)
for i in items:
    if i['service'].startswith('friday_') and i['remaining_seconds'] < 5400:
        print(i['service'])
" 2>/dev/null | while read -r SERVICE; do
  CLIENT_ID="${SERVICE#friday_}"
  echo "📌 续期 $SERVICE (client_id=$CLIENT_ID)..."

  EXCHANGE_OUTPUT=$(npx mtsso-moa-local-exchange --audience "$CLIENT_ID" 2>&1)
  NEW_TOKEN=$(echo "$EXCHANGE_OUTPUT" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('access_token',''))
except:
    print('')
" 2>/dev/null)

  if [ -n "$NEW_TOKEN" ]; then
    python3 "$CACHE_MANAGER" set "$SERVICE" "$NEW_TOKEN" "$CLIENT_ID" >/dev/null
    echo "  ✅ $SERVICE 续期成功"
  else
    echo "  ⚠️  $SERVICE 换票失败（MOA 登录态可能失效），需手动触发 CIBA"
  fi
done

# 列出当前所有 token 状态
echo ""
echo "📌 Token 缓存状态："
python3 "$CACHE_MANAGER" list

echo "=== 检查完成 ==="
