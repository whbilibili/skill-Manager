#!/bin/bash

# BA-Agent SSO Cookie 注入脚本
# 用法: bash inject-ba-cookie-supabase-ciba.sh <misId>
#
# 环境变量：
#   BA_ENV      - 目标环境（prod/st/staging），默认 prod
#                 prod/st/staging 使用线上 SSO：https://supabase.sankuai.com
#                 注意：test 环境因环境隔离不支持
#   BA_DATA_DIR - 运行时状态目录（token/cookie 存放位置）
#                 默认：~/.cache/ba-analysis

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IDENTIFIER=$(bash "${SCRIPT_DIR}/read-env.sh")

# ===== 配置 =====
if [ -z "$1" ]; then
    echo "❌ 错误：请提供登录者 misId"
    echo ""
    echo "使用方式："
    echo "  bash $0 <misId>"
    echo ""
    echo "示例："
    echo "  bash $0 zhangsan"
    exit 1
fi
LOGIN_HINT="$1"

# SSO host（prod/st/staging 统一使用线上 SSO）
_BA_ENV="${BA_ENV:-prod}"
BASE_URL="https://supabase.sankuai.com"
echo "环境: ${_BA_ENV}  SSO: ${BASE_URL}"

# 运行时状态文件目录
BA_DATA_DIR="${BA_DATA_DIR:-${HOME}/.cache/ba-analysis}"
mkdir -p "$BA_DATA_DIR"

COOKIE_OUTPUT="${BA_DATA_DIR}/cookies.json"

# BA-Agent 的 SSO client ID
# 如果换票失败，请联系系统管理员确认 BA-Agent 系统的正确 clientId
BA_CLIENT_ID="07b8be90c9"

# 检查 IDENTIFIER 是否以 ERROR 开头
if [[ "$IDENTIFIER" == ERROR* ]]; then
    echo "❌  IDENTIFIER 错误: $IDENTIFIER"
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀  开始获取 BA-Agent Token"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "login_hint: $LOGIN_HINT"
echo ""

# ===== 步骤 1：获取 auth_req_id =====
echo "📌  步骤 1：获取 auth_req_id..."

BC_RESPONSE=$(curl --noproxy "*" -s -X POST "${BASE_URL}/api/sandbox/sso/ciba-auth" \
  -H 'Content-Type: application/json' \
  -d "{\"identifier\": \"${IDENTIFIER}\",\"misId\": \"${LOGIN_HINT}\"}")

echo "响应: $BC_RESPONSE"

AUTH_REQ_ID=$(echo "$BC_RESPONSE" | python3 -c "import json,sys; data=json.load(sys.stdin); d=data.get('data',{}) if data.get('code')==0 else {}; print(d.get('authReqId','') or d.get('existingAuthReqId',''))" 2>/dev/null)

if [ -z "$AUTH_REQ_ID" ]; then
    ERROR_DESC=$(echo "$BC_RESPONSE" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('data',{}).get('errorDescription','') or data.get('message','未知错误'))" 2>/dev/null)
    echo "❌  auth_req_id 获取失败: $ERROR_DESC"
    exit 1
fi

echo "✅  auth_req_id: $AUTH_REQ_ID"
echo ""

# ===== 步骤 2：轮询获取 access_token =====
echo "📌  步骤 2：轮询获取 access_token（每 5s 一次，最多 3 分钟）..."

MAX_RETRY=36
RETRY=0
ACCESS_TOKEN=""

while [ $RETRY -lt $MAX_RETRY ]; do
    RETRY=$((RETRY + 1))
    echo "  第 ${RETRY}/${MAX_RETRY} 次轮询..."

    TOKEN_RESPONSE=$(curl --noproxy "*" -s -X POST "${BASE_URL}/api/sandbox/sso/ciba-token" \
      -H 'Content-Type: application/json' \
      -d "{\"authReqId\": \"${AUTH_REQ_ID}\"}")

    echo "  响应: ${TOKEN_RESPONSE:0:100}..."

    ACCESS_TOKEN=$(echo "$TOKEN_RESPONSE" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('data',{}).get('accessToken','') if data.get('code')==0 else '')" 2>/dev/null)

    if [ -n "$ACCESS_TOKEN" ]; then
        echo "✅  access_token 获取成功"
        break
    fi

    ERROR_DESC=$(echo "$TOKEN_RESPONSE" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('data',{}).get('errorDescription','') or data.get('message','未知错误'))" 2>/dev/null)
    if [ -n "$ERROR_DESC" ] && [ "$ERROR_DESC" != "null" ]; then
        echo "  错误: $ERROR_DESC"
    fi

    echo "  等待 5s..."
    sleep 5
done

if [ -z "$ACCESS_TOKEN" ]; then
    echo "❌  轮询超时，未获取到 access_token"
    exit 1
fi

echo ""

# ===== 步骤 3：换票 =====
echo "📌  步骤 3：换票获取最终 access-token..."

EXCHANGE_RESPONSE=$(curl --noproxy "*" -s -X POST "${BASE_URL}/api/sandbox/sso/exchange-token-by-client-ids" \
  -H 'Content-Type: application/json' \
  -d "{\"accessToken\":\"${ACCESS_TOKEN}\",\"clientIds\":[\"${BA_CLIENT_ID}\"]}")

echo "响应: $EXCHANGE_RESPONSE"

COOKIE_DATA=$(echo "$EXCHANGE_RESPONSE" | python3 -c "import json,sys; data=json.load(sys.stdin); print(json.dumps(data.get('data',[])) if data.get('data') else '')" 2>/dev/null)

if [ -z "$COOKIE_DATA" ] || [ "$COOKIE_DATA" = "[]" ] || [ "$COOKIE_DATA" = "null" ]; then
    ERROR_MSG=$(echo "$EXCHANGE_RESPONSE" | python3 -c "import json,sys; data=json.load(sys.stdin); print(data.get('message','未知错误'))" 2>/dev/null)
    echo "❌  换票失败: $ERROR_MSG"
    exit 1
fi

# ===== 步骤 4：提取 access-token 值并保存 =====
echo "📌  步骤 4：保存 access-token..."

EXCHANGE_RESPONSE_FILE=$(mktemp)
echo "${EXCHANGE_RESPONSE}" > "${EXCHANGE_RESPONSE_FILE}"

python3 - << PYEOF
import json, os, sys

exchange_response_file = "${EXCHANGE_RESPONSE_FILE}"
output_path = "${BA_DATA_DIR}/access_token.txt"
login_hint = "${LOGIN_HINT}"
mis_id_path = "${BA_DATA_DIR}/mis_id.txt"
cookie_output = "${COOKIE_OUTPUT}"

try:
    with open(exchange_response_file) as _f:
        exchange_response = _f.read()
finally:
    try:
        os.unlink(exchange_response_file)
    except Exception:
        pass

try:
    data = json.loads(exchange_response)
    raw_data = data.get('data')

    token_value = None

    if isinstance(raw_data, str):
        # 直接就是 token 字符串
        token_value = raw_data
        cookie_data = [{
            "domain": "ba-ai.sankuai.com",
            "httpOnly": True,
            "name": "ssoid",
            "path": "/",
            "secure": True,
            "value": raw_data
        }]
    elif isinstance(raw_data, list):
        cookie_data = raw_data
        # 尝试找 ssoid 或第一个 value
        for c in raw_data:
            if 'ssoid' in c.get('name','').lower() or 'token' in c.get('name','').lower():
                token_value = c['value']
                break
        if not token_value and raw_data:
            token_value = raw_data[0]['value']
    else:
        print(f"❌  未知数据格式: {type(raw_data)}")
        exit(1)

    # 保存 access-token 到文本文件（供 Python 脚本读取）
    with open(output_path, 'w') as f:
        f.write(token_value)
    print(f"✅  access-token 已保存: {output_path}")

    # 保存 misId 到文本文件（供自动重鉴权时读取，避免子 agent 沙箱读不到环境变量）
    if login_hint:
        with open(mis_id_path, 'w') as f:
            f.write(login_hint)
        print(f"✅  misId 已保存: {mis_id_path}")

    # 保存 cookies.json（供 inject-cookie.py 使用）
    with open(cookie_output, 'w') as f:
        json.dump(cookie_data, f, indent=2, ensure_ascii=False)
    print(f"✅  cookies.json 已生成: {cookie_output}")

except Exception as e:
    print(f"❌  保存失败: {e}")
    exit(1)
PYEOF

if [ $? -ne 0 ]; then
    exit 1
fi

echo ""

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉  BA-Agent 鉴权完成！"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
