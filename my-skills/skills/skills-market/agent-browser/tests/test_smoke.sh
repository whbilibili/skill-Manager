#!/bin/bash
# agent-browser skill 冒烟测试
set -e

echo "=== Test 1: agent-browser 已安装 ==="
command -v agent-browser >/dev/null
agent-browser --version
echo "PASS"

echo "=== Test 2: 环境初始化 ==="
unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
export AGENT_BROWSER_ARGS="--no-sandbox,--ignore-certificate-errors"
echo "PASS"

echo "=== Test 3: open + snapshot ==="
agent-browser open "https://example.com" --timeout 15000
SNAPSHOT=$(agent-browser snapshot -i)
echo "$SNAPSHOT"
# example.com 有 link "More information..." 会产生 ref
echo "$SNAPSHOT" | grep -qE "ref=|@e|link|heading" || { echo "FAIL: snapshot empty or broken"; exit 1; }
echo "PASS"

echo "=== Test 4: get text ==="
TITLE=$(agent-browser get title)
echo "Title: $TITLE"
[ -n "$TITLE" ] || { echo "FAIL: empty title"; exit 1; }
echo "PASS"

echo "=== Test 5: get url ==="
URL=$(agent-browser get url)
echo "URL: $URL"
echo "$URL" | grep -q "example.com" || { echo "FAIL: wrong URL"; exit 1; }
echo "PASS"

echo "=== Test 6: screenshot ==="
TMPFILE=$(mktemp /tmp/ab-test-XXXXXX.png)
agent-browser screenshot "$TMPFILE"
[ -s "$TMPFILE" ] || { echo "FAIL: empty screenshot"; exit 1; }
rm -f "$TMPFILE"
echo "PASS"

echo "=== Test 7: eval ==="
RESULT=$(agent-browser eval 'document.title')
[ -n "$RESULT" ] || { echo "FAIL: empty eval result"; exit 1; }
echo "PASS"

echo "=== Test 8: close ==="
agent-browser close
echo "PASS"

echo ""
echo "✅ All tests passed"
