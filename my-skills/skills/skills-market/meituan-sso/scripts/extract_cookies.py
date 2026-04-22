#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
通过 CDP 从浏览器实时提取指定域名的 Cookie。
其他 Skill 可调用此脚本获取认证 Cookie，无需自行管理 Cookie 文件。

用法：
  python3 extract_cookies.py --domain dev.sankuai.com
  python3 extract_cookies.py --domain km.sankuai.com --format json
  python3 extract_cookies.py --domain dev.sankuai.com --check-url https://dev.sankuai.com/rest/api/2.0/users

输出：
  默认输出 Cookie 字符串（name=value; name=value; ...）
  --format json 输出完整 Cookie JSON 数组
  --check-url 同时验证 Cookie 有效性（200=AUTH_OK, 401/302=AUTH_EXPIRED）
"""

import argparse
import json
import os
import ssl
import sys
import time
import urllib.request
import urllib.error

CDP_URL = "http://127.0.0.1:9222"


def extract_cookies(domain, cdp_url=CDP_URL):
    """通过 CDP 从浏览器提取指定域名的 Cookie"""
    try:
        import websocket
    except ImportError:
        import subprocess
        subprocess.check_call(
            [sys.executable, "-m", "pip", "install", "websocket-client", "-q"],
            stderr=subprocess.DEVNULL
        )
        import websocket

    try:
        resp = urllib.request.urlopen(f"{cdp_url}/json", timeout=5)
        targets = json.loads(resp.read())
        page = next((t for t in targets if t.get("type") == "page"), None)
        if not page:
            return None, "NO_BROWSER_PAGE"

        ws = websocket.create_connection(page["webSocketDebuggerUrl"], timeout=15)

        # 构建 URL 列表用于获取 Cookie
        urls = [f"https://{domain}"]
        # 同时获取父域的 Cookie
        parts = domain.split(".")
        if len(parts) > 2:
            parent = ".".join(parts[-2:])
            urls.append(f"https://{parent}")

        ws.send(json.dumps({
            "id": 1,
            "method": "Network.getCookies",
            "params": {"urls": urls}
        }))

        start = time.time()
        while time.time() - start < 10:
            try:
                ws.settimeout(2)
                data = json.loads(ws.recv())
                cookies = data.get("result", {}).get("cookies")
                if cookies is not None:
                    ws.close()
                    if not cookies:
                        return None, "NO_COOKIES"
                    return cookies, None
            except Exception:
                continue
        ws.close()
        return None, "TIMEOUT"
    except Exception as e:
        return None, f"CDP_ERROR: {e}"


def check_auth(cookie_str, check_url):
    """用 Cookie 请求 URL 验证认证有效性"""
    headers = {
        "Cookie": cookie_str,
        "X-Requested-With": "XMLHttpRequest",
        "Accept": "application/json",
    }
    req = urllib.request.Request(check_url, headers=headers, method="GET")
    proxy_handler = urllib.request.ProxyHandler({})
    ctx = ssl.create_default_context()
    https_handler = urllib.request.HTTPSHandler(context=ctx)
    opener = urllib.request.build_opener(proxy_handler, https_handler)

    try:
        resp = opener.open(req, timeout=10)
        return "AUTH_OK"
    except urllib.error.HTTPError as e:
        if e.code in (401, 403):
            return "AUTH_EXPIRED"
        # 其他 HTTP 错误不一定是认证问题
        return "AUTH_OK"
    except Exception as e:
        return f"CHECK_ERROR: {e}"


def main():
    parser = argparse.ArgumentParser(description="Extract browser cookies via CDP")
    parser.add_argument("--domain", required=True, help="Target domain (e.g. dev.sankuai.com)")
    parser.add_argument("--format", choices=["string", "json"], default="string",
                        help="Output format")
    parser.add_argument("--check-url", help="URL to verify cookie validity")
    parser.add_argument("--cdp-port", type=int, default=9222, help="CDP port")
    args = parser.parse_args()

    cdp_url = f"http://127.0.0.1:{args.cdp_port}"
    cookies, error = extract_cookies(args.domain, cdp_url)

    if error:
        print(error)
        sys.exit(1)

    cookie_str = "; ".join(f"{c['name']}={c['value']}" for c in cookies)

    if args.format == "json":
        output = {
            "domain": args.domain,
            "cookie_count": len(cookies),
            "cookie_string": cookie_str,
            "cookies": [{"name": c["name"], "value": c["value"],
                         "domain": c.get("domain", ""), "path": c.get("path", "/"),
                         "httpOnly": c.get("httpOnly", False),
                         "secure": c.get("secure", False)}
                        for c in cookies]
        }
        if args.check_url:
            output["auth_status"] = check_auth(cookie_str, args.check_url)
        print(json.dumps(output, ensure_ascii=False, indent=2))
    else:
        if args.check_url:
            status = check_auth(cookie_str, args.check_url)
            print(status, file=sys.stderr)
            if status != "AUTH_OK":
                sys.exit(1)
        print(cookie_str)


if __name__ == "__main__":
    main()
