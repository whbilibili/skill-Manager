#!/bin/bash

# BA-Agent MOA 本地鉴权脚本
# 逻辑：
#   1. 确保 @mtfe/mtsso-auth-official 可用（遵循 mtsso-skills-official 规范）
#   2. npx mtsso-moa-feature-probe 探测 MOA 是否可用
#   3. npx mtsso-moa-local-exchange 换票
#   4. 成功 → token 写入 BA_DATA_DIR/access_token.txt，退出码 0
#   5. 任一步骤失败 → 退出码 1（调用方降级 CIBA）
#
# 用法: bash inject-ba-cookie-moa.sh
#
# 退出码：
#   0  鉴权成功
#   1  失败（调用方应降级到 inject-ba-cookie-supabase-ciba.sh CIBA 方式）
#
# 环境变量：
#   BA_DATA_DIR - 运行时状态目录，默认 ~/.cache/ba-analysis

BA_DATA_DIR="${BA_DATA_DIR:-${HOME}/.cache/ba-analysis}"
mkdir -p "$BA_DATA_DIR"

ACCESS_TOKEN_OUTPUT="${BA_DATA_DIR}/access_token.txt"
MIS_ID_PATH="${BA_DATA_DIR}/mis_id.txt"

# BA-Agent 的 SSO client ID
BA_CLIENT_ID="07b8be90c9"

# NPM registry
NPM_REGISTRY="http://r.npm.sankuai.com"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀  BA-Agent MOA 本地鉴权"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ===== 工具检测函数（检测到未安装则提示用户，不自动安装）=====
_check_mtsso() {
    local cmd="$1"
    if ! command -v "$cmd" &>/dev/null && ! npx --no-install "$cmd" --help &>/dev/null 2>&1; then
        return 1
    fi
    return 0
}

# ===== 步骤 1：检查 mtsso 工具是否已安装 =====
echo "📌  步骤 1：检查 mtsso 工具..."
if ! _check_mtsso "mtsso-moa-feature-probe"; then
    echo ""
    echo "❌  未检测到 @mtfe/mtsso-auth-official，MOA 鉴权不可用。"
    echo ""
    echo "  你可以选择："
    echo "  1. 手动安装后重试 MOA 鉴权："
    echo "     npm install @mtfe/mtsso-auth-official@latest --registry ${NPM_REGISTRY}"
    echo ""
    echo "  2. 改用 CIBA（大象扫码）方式登录："
    echo "     bash $(dirname "$0")/inject-ba-cookie-supabase-ciba.sh <你的misId>"
    echo ""
    exit 1
fi
echo "✅  工具就绪"
echo ""

# ===== 步骤 2：探测本地 MOA =====
echo "📌  步骤 2：探测本地 MOA（mtsso-moa-feature-probe）..."

PROBE_JSON=$(npx mtsso-moa-feature-probe -t 3 2>/dev/null)
PROBE_EXIT=$?

PROBE_STATUS=$(echo "$PROBE_JSON" | python3 -c \
    "import json,sys; d=json.load(sys.stdin); print(d.get('status','unknown'))" 2>/dev/null || echo "unknown")
PROBE_REASON=$(echo "$PROBE_JSON" | python3 -c \
    "import json,sys; d=json.load(sys.stdin); print(d.get('reason',''))" 2>/dev/null || echo "")

echo "  探测退出码: ${PROBE_EXIT}  状态: ${PROBE_STATUS}"
[ -n "$PROBE_REASON" ] && echo "  详情: $PROBE_REASON"

if [ $PROBE_EXIT -ne 0 ]; then
    echo ""
    echo "❌  本地 MOA 不可用（退出码: ${PROBE_EXIT}，状态: ${PROBE_STATUS}）"
    echo "  请确认 MOA 已启动并完成登录"
    exit 1
fi

echo "✅  MOA 可用"
echo ""

# ===== 步骤 3：通过 MOA 本地换票 =====
echo "📌  步骤 3：本地换票（mtsso-moa-local-exchange --audience ${BA_CLIENT_ID}）..."

TOKEN_JSON=$(npx mtsso-moa-local-exchange \
    --audience "${BA_CLIENT_ID}" \
    2>/tmp/ba-moa-exchange-stderr.txt)

EXCHANGE_EXIT=$?

if [ $EXCHANGE_EXIT -ne 0 ]; then
    STDERR_MSG=$(cat /tmp/ba-moa-exchange-stderr.txt 2>/dev/null | tail -5)
    ERROR_MSG=$(echo "$TOKEN_JSON" | python3 -c \
        "import json,sys; d=json.load(sys.stdin); print(d.get('error','') or d.get('message',''))" \
        2>/dev/null || true)
    echo "❌  换票失败（退出码: ${EXCHANGE_EXIT}）"
    [ -n "$ERROR_MSG" ] && echo "  错误: $ERROR_MSG"
    [ -n "$STDERR_MSG" ] && echo "  详情: $STDERR_MSG"
    exit 1
fi

# ===== 步骤 4：提取并保存 access_token =====
echo "📌  步骤 4：保存 access_token..."

ACCESS_TOKEN=$(echo "$TOKEN_JSON" | python3 -c \
    "import json,sys; d=json.load(sys.stdin); print(d.get('access_token',''))" 2>/dev/null)

if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌  无法从响应中提取 access_token"
    echo "  原始响应: ${TOKEN_JSON:0:200}"
    exit 1
fi

echo "$ACCESS_TOKEN" > "$ACCESS_TOKEN_OUTPUT"
echo "✅  access_token 已保存: $ACCESS_TOKEN_OUTPUT"

# 从 token 中解析 misId 并缓存
# token 格式：<encrypted>**mtsso**<sig>**<base64(uid,misId,name,email,...)>
# 最后一段 base64 解码后为逗号分隔字段，[1] 即 misId
MIS_ID=$(echo "$ACCESS_TOKEN" | python3 -c "
import sys, base64
token = sys.stdin.read().strip()
try:
    raw_parts = token.split('**')
    last = raw_parts[-1]
    padded = last + '=' * (4 - len(last) % 4)
    decoded = base64.urlsafe_b64decode(padded).decode('utf-8')
    fields = decoded.split(',')
    if len(fields) >= 2:
        print(fields[1].strip())  # index 1 = misId
except: pass
" 2>/dev/null || true)

if [ -n "$MIS_ID" ] && [ "$MIS_ID" != "null" ]; then
    echo "$MIS_ID" > "$MIS_ID_PATH"
    echo "✅  misId 已从 token 解析并缓存: $MIS_ID"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉  MOA 本地鉴权完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
