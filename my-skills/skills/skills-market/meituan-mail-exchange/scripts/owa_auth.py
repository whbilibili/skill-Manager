#!/usr/bin/env python3
"""
OWA SSO 认证模块 - 三级策略

OWA (mail.meituan.com) 使用 ADFS 认证，不属于 sankuai SSO 体系，
无法通过换票获取 cookie。

认证策略（优先级从高到低）：
  1. cookie.json 缓存：复用本地有效 cookie（有效期约 6 小时）
  2. 浏览器提取：从 agent-browser 当前 OWA session 提取 cookie，写入缓存
  3. 浏览器导航：导航到 OWA，等待登录后提取

返回 {"cookie": "...", "canary": "..."} 或 None
"""

import json, os, sys, time, subprocess
from pathlib import Path
from datetime import datetime

SKILL_DIR = Path(__file__).parent.parent
COOKIE_FILE = SKILL_DIR / "cookie.json"
OWA_URL = "https://mail.meituan.com/owa/"
COOKIE_TTL = 21600  # 6小时


def _load_cached_cookie():
    try:
        data = json.loads(COOKIE_FILE.read_text())
        cookie_str = data.get("cookie", "")
        canary = data.get("canary", "")
        saved_at = data.get("saved_at", 0)
        if not cookie_str or not canary:
            return None
        if time.time() - saved_at > COOKIE_TTL:
            print("[owa_auth] 缓存 cookie 已过期", file=sys.stderr)
            return None
        age_min = int((time.time() - saved_at) / 60)
        print(f"[owa_auth] ✅ 命中缓存 cookie（已缓存 {age_min} 分钟）", file=sys.stderr)
        return {"cookie": cookie_str, "canary": canary}
    except Exception:
        return None


def _save_cookie(cookie_data):
    try:
        COOKIE_FILE.write_text(json.dumps({
            "cookie": cookie_data["cookie"],
            "canary": cookie_data["canary"],
            "saved_at": time.time(),
            "saved_at_human": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }, ensure_ascii=False, indent=2))
        print(f"[owa_auth] cookie 已缓存到 {COOKIE_FILE}", file=sys.stderr)
    except Exception as e:
        print(f"[owa_auth] 缓存写入失败: {e}", file=sys.stderr)


def _extract_from_browser():
    # 检查浏览器当前页面
    nav_result = subprocess.run(['agent-browser', 'get', 'url'],
                                capture_output=True, text=True, timeout=15)
    current_url = nav_result.stdout.strip()

    if 'mail.meituan.com' not in current_url:
        print("[owa_auth] 浏览器不在 OWA，正在导航...", file=sys.stderr)
        subprocess.run(['agent-browser', 'open', OWA_URL], capture_output=True, timeout=30)
        subprocess.run(['agent-browser', 'wait', '--load', 'networkidle'], capture_output=True, timeout=30)
        time.sleep(2)
        url_check = subprocess.run(['agent-browser', 'get', 'url'], capture_output=True, text=True, timeout=10)
        if 'mail.meituan.com' not in url_check.stdout:
            print("[owa_auth] OWA 跳转到登录页，需要用户完成认证", file=sys.stderr)
            return None

    js = r"""(function() {
  const cookies = {};
  document.cookie.split(';').forEach(c => {
    const idx = c.indexOf('=');
    if (idx > 0) cookies[c.substring(0,idx).trim()] = c.substring(idx+1).trim();
  });
  const canary = cookies['X-OWA-CANARY'] || '';
  const cookieStr = Object.entries(cookies).map(([k,v]) => k+'='+v).join('; ');
  return JSON.stringify({canary, cookieStr});
})()"""

    result = subprocess.run(['agent-browser', 'eval', js], capture_output=True, text=True, timeout=30)
    if result.returncode != 0:
        print(f"[owa_auth] 浏览器提取失败: {result.stderr[:100]}", file=sys.stderr)
        return None

    try:
        raw = result.stdout.strip()
        if raw.startswith('"'):
            raw = json.loads(raw)
        data = json.loads(raw)
        if not data.get('canary'):
            print("[owa_auth] 未找到 X-OWA-CANARY，浏览器可能未登录 OWA", file=sys.stderr)
            return None
        print(f"[owa_auth] ✅ 从浏览器提取到 OWA cookie", file=sys.stderr)
        return {"cookie": data["cookieStr"], "canary": data["canary"]}
    except Exception as e:
        print(f"[owa_auth] 解析失败: {e}", file=sys.stderr)
        return None


def get_owa_cookie(force_refresh=False):
    """获取 OWA cookie，返回 {"cookie": "...", "canary": "..."} 或 None"""
    if not force_refresh:
        cached = _load_cached_cookie()
        if cached:
            return cached

    print("[owa_auth] 正在从浏览器提取 OWA cookie...", file=sys.stderr)
    browser_cookie = _extract_from_browser()
    if browser_cookie:
        _save_cookie(browser_cookie)
        return browser_cookie

    print("[owa_auth] ❌ 无法自动获取，请确保浏览器已登录 mail.meituan.com", file=sys.stderr)
    return None


if __name__ == "__main__":
    import argparse, urllib.request
    parser = argparse.ArgumentParser()
    parser.add_argument("--refresh", action="store_true")
    parser.add_argument("--test", action="store_true")
    args = parser.parse_args()

    cookie_data = get_owa_cookie(force_refresh=args.refresh)
    if not cookie_data:
        print("❌ 认证失败"); sys.exit(1)

    print(f"✅ 认证成功，Canary: {cookie_data['canary'][:30]}...")

    if args.test:
        payload = json.dumps({
            "__type": "FindItemJsonRequest:#Exchange",
            "Header": {"__type": "JsonRequestHeaders:#Exchange", "RequestServerVersion": "Exchange2013"},
            "Body": {
                "__type": "FindItemRequest:#Exchange",
                "Traversal": "Shallow",
                "ItemShape": {"__type": "ItemResponseShape:#Exchange", "BaseShape": "IdOnly"},
                "IndexedPageItemView": {"__type": "IndexedPageView:#Exchange", "BasePoint": "Beginning",
                                        "Offset": 0, "MaxEntriesReturned": 3},
                "ParentFolderIds": [{"__type": "DistinguishedFolderId:#Exchange", "Id": "inbox"}]
            }
        }).encode('utf-8')
        req = urllib.request.Request(
            'https://mail.meituan.com/owa/service.svc?action=FindItem&EP=1',
            data=payload,
            headers={'Content-Type': 'application/json; charset=utf-8',
                     'X-OWA-CANARY': cookie_data['canary'],
                     'Cookie': cookie_data['cookie'], 'Action': 'FindItem'},
            method='POST'
        )
        with urllib.request.urlopen(req, timeout=15) as resp:
            result = json.loads(resp.read())
            items = result.get('Body', {}).get('ResponseMessages', {}).get('Items', [])
            total = items[0].get('Root', {}).get('TotalItemsInView', 0) if items else 0
            print(f"   API 测试成功！收件箱共 {total} 封邮件")
