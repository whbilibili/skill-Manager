#!/bin/bash
# 统一认证缓存入口
# 用法:
#   auth-cache.sh check <service> [buffer_seconds]  — 检查 token 有效性
#   auth-cache.sh get <service>                     — 获取缓存 token
#   auth-cache.sh get-all <service>                 — 获取完整缓存信息
#   auth-cache.sh set <service> <token> [client_id] [endpoint] [ttl] — 缓存 token
#   auth-cache.sh friday <client_id> [mis_id]       — Friday MCP: 检查缓存→有效返回 token，过期则 mtsso-moa-local-exchange 换票
#   auth-cache.sh sso                               — SSO: 检查→有效跳过，过期则提示
#   auth-cache.sh moa                               — MOA: 检查登录态
#   auth-cache.sh list                              — 列出所有缓存状态
#   auth-cache.sh clear [service]                   — 清除缓存
#   auth-cache.sh ensure <service>                  — 一步完成 check+get，有效返回 token，过期 exit 1
#   auth-cache.sh friday-list                       — 列出所有 friday_* 缓存的状态

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CACHE_MANAGER="$SCRIPT_DIR/cache-manager.py"

# 缓存目录：skill 自身目录下的 cache/
CACHE_DIR="$SKILL_DIR/cache"
mkdir -p "$CACHE_DIR"

case "$1" in
  check|get|get-all|set|list|clear)
    python3 "$CACHE_MANAGER" "$@"
    ;;
  ensure)
    # ensure <service>: 一步完成 check+get，有效返回 token，过期 exit 1
    SERVICE="${2:?需要 service name}"
    python3 "$CACHE_MANAGER" ensure "$SERVICE"
    ;;
  friday-list)
    # 列出所有 friday_* 缓存的状态
    python3 "$CACHE_MANAGER" list | python3 -c "
import sys, json
items = json.load(sys.stdin)
friday_items = [i for i in items if i['service'].startswith('friday_')]
print(json.dumps(friday_items, indent=2))
"
    ;;
  friday)
    # Friday MCP Token: 检查缓存 → 有效则返回 → 过期则用 mtsso-moa-local-exchange 换票
    # 用法: auth-cache.sh friday <client_id> [mis_id]
    CLIENT_ID="${2:?需要 client_id}"
    MIS_ID="${3:-}"
    SERVICE="friday_${CLIENT_ID}"

    # Step 1: 检查缓存（提前 5 分钟判定过期）
    CHECK=$(python3 "$CACHE_MANAGER" check "$SERVICE" 300 2>/dev/null)
    VALID=$(echo "$CHECK" | python3 -c "import sys,json; print(json.load(sys.stdin).get('valid',False))" 2>/dev/null)

    if [ "$VALID" = "True" ]; then
      # 缓存有效，直接返回 token
      python3 "$CACHE_MANAGER" get "$SERVICE"
      exit 0
    fi

    # Step 2: 确保 mtsso 包可用
    if ! command -v npx &>/dev/null; then
      echo "ERROR: npx 不可用，请先安装 Node.js" >&2
      exit 1
    fi

    # 检查 mtsso-auth-official 包是否已安装（仅首次安装）
    if ! npm list @mtfe/mtsso-auth-official --depth=0 &>/dev/null 2>&1; then
      echo "📦 安装 @mtfe/mtsso-auth-official..." >&2
      npm install @mtfe/mtsso-auth-official --registry=http://r.npm.sankuai.com --silent 2>&1 | tail -1 >&2
    fi

    # Step 3: 用 mtsso-moa-local-exchange 一步换票
    echo "🔄 Token 过期，尝试 mtsso-moa-local-exchange 换票..." >&2
    EXCHANGE_OUTPUT=$(npx mtsso-moa-local-exchange --audience "$CLIENT_ID" 2>&1)
    FINAL_TOKEN=$(echo "$EXCHANGE_OUTPUT" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('access_token',''))
except:
    print('')
" 2>/dev/null)

    # Step 4: 换票失败 → CIBA 降级
    if [ -z "$FINAL_TOKEN" ]; then
      echo "⚠️  mtsso-moa-local-exchange 失败（MOA 登录态可能失效），尝试 CIBA..." >&2

      # CIBA 需要 mis_id：优先用参数 > 环境变量 AUTH_MIS_ID > 提示退出
      if [ -z "$MIS_ID" ]; then
        MIS_ID="${AUTH_MIS_ID:-}"
      fi
      if [ -z "$MIS_ID" ]; then
        echo "ERROR: CIBA 降级需要 mis_id。传参: auth-cache.sh friday <client_id> <mis_id>，或设置环境变量 AUTH_MIS_ID" >&2
        exit 1
      fi

      # 尝试通过 mtsso-skills-official 的 CIBA 方式登录
      CIBA_OUTPUT=$(npx mtsso-moa-local-exchange --audience "$CLIENT_ID" --ciba "$MIS_ID" 2>&1) || true
      FINAL_TOKEN=$(echo "$CIBA_OUTPUT" | python3 -c "
import json,sys
try:
    d=json.load(sys.stdin)
    print(d.get('access_token',''))
except:
    print('')
" 2>/dev/null)

      if [ -z "$FINAL_TOKEN" ]; then
        echo "ERROR: CIBA 换票也失败。请在大象 App 找到授权推送消息，点击确认后重试。" >&2
        exit 1
      fi
      echo "✅ CIBA 换票成功" >&2
    fi

    # Step 5: 获取 endpoint（从旧缓存中读取，可选）
    ENDPOINT=$(python3 -c "
import json,sys,os
try:
    cache_path = os.path.join('$CACHE_DIR', 'auth-cache.json')
    with open(cache_path) as f:
        print(json.load(f).get('friday_${CLIENT_ID}',{}).get('endpoint',''))
except: pass
" 2>/dev/null)

    # Step 6: 写入缓存并输出新 token
    python3 "$CACHE_MANAGER" set "$SERVICE" "$FINAL_TOKEN" "$CLIENT_ID" "$ENDPOINT" >/dev/null
    echo "✅ 换票成功，已写入缓存" >&2
    echo "$FINAL_TOKEN"
    ;;
  sso)
    # SSO Cookie 检查（通用提示）
    echo "ℹ️  SSO 状态检查：请确保浏览器中已登录 .sankuai.com 域名。" >&2
    echo "如需自动刷新 SSO Cookie，建议配合 CDP 浏览器自动化或 sso-cookie-manager 使用。" >&2
    echo '{"status": "check_manually", "hint": "确保浏览器已登录 .sankuai.com"}'
    ;;
  moa)
    # MOA 登录态检查
    if command -v npx &>/dev/null && npx mtsso-moa-local-exchange --audience "test" 2>&1 | grep -q "access_token"; then
      echo '{"status": "logged_in"}'
    else
      # 尝试简单验证 MOA 可用性
      echo '{"status": "unknown", "hint": "运行 npx mtsso-moa-local-exchange --audience <任意client_id> 测试换票是否成功"}'
    fi
    ;;
  *)
    echo "用法: auth-cache.sh <check|get|get-all|set|ensure|friday|friday-list|sso|moa|list|clear> [args]"
    echo ""
    echo "命令说明:"
    echo "  check <service> [buffer]  检查 token 有效性（buffer 秒数，默认 300）"
    echo "  get <service>             获取缓存 token"
    echo "  get-all <service>         获取完整缓存信息"
    echo "  set <service> <token> ... 写入缓存"
    echo "  ensure <service>          check+get 一步完成"
    echo "  friday <client_id> [mis]  Friday MCP token 检查+换票"
    echo "  friday-list               列出所有 friday_* 缓存"
    echo "  sso                       SSO 状态检查"
    echo "  moa                       MOA 登录态检查"
    echo "  list                      列出所有缓存"
    echo "  clear [service]           清除缓存"
    exit 1
    ;;
esac
