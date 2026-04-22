#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
美团 SSO 自动登录 v4 - 分段式，不阻塞 Agent。

命令：
  start   --output FILE    捕获二维码+启动后台轮询，立刻返回
  status                   检查当前登录状态（秒级返回）
  skip                     在当前页面查找并点击 Skip 按钮
  verify                   验证最终登录是否成功

Agent 调用流程：
  1. exec: sso_login.py start → 拿到 QRCODE_SAVED 和 ctxId → 发二维码给用户
  2. 间隔几秒调: sso_login.py status → 返回当前状态
  3. 状态为 SCAN_CONFIRMED → 调: sso_login.py skip → 点击 Skip
  4. 调: sso_login.py verify → 确认登录成功
"""

import argparse
import base64
import json
import os
import re
import ssl
import sys
import time
import urllib.request
import urllib.error

try:
    import websocket
except ImportError:
    import subprocess
    subprocess.check_call(
        [sys.executable, "-m", "pip", "install", "websocket-client", "-q"],
        stderr=subprocess.DEVNULL
    )
    import websocket

CDP_URL = "http://127.0.0.1:9222"
SSO_STATUS_URL = "https://ssosv.sankuai.com/sson/auth/qrcode/v1/status"
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(os.path.dirname(SCRIPT_DIR), "data")
STATE_FILE = os.path.join(DATA_DIR, "sso_state.json")


def log(msg):
    print(f"[INFO] {msg}", file=sys.stderr, flush=True)


def output(msg):
    print(msg, flush=True)


def save_state(state):
    os.makedirs(DATA_DIR, exist_ok=True)
    with open(STATE_FILE, "w") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)


def load_state():
    if os.path.exists(STATE_FILE):
        with open(STATE_FILE, "r") as f:
            return json.load(f)
    return {}


def get_page_ws(cdp_url=CDP_URL, prefer=None):
    resp = urllib.request.urlopen(f"{cdp_url}/json", timeout=5)
    targets = json.loads(resp.read())
    fallback = None
    for t in targets:
        if t.get("type") == "page" and "webSocketDebuggerUrl" in t:
            url = t.get("url", "")
            # 优先找 SSO 或 sankuai 页面
            if prefer and prefer in url:
                return t["webSocketDebuggerUrl"], url
            if "ssosv.sankuai.com" in url or "sankuai.com" in url:
                return t["webSocketDebuggerUrl"], url
            if fallback is None:
                fallback = t
    if fallback:
        return fallback["webSocketDebuggerUrl"], fallback.get("url", "")
    raise RuntimeError("No browser page found")


def send_cdp(ws, method, params=None, msg_id=1):
    ws.send(json.dumps({"id": msg_id, "method": method, **({"params": params} if params else {})}))


def recv_cdp(ws, expected_id=None, timeout=10):
    deadline = time.time() + timeout
    while time.time() < deadline:
        ws.settimeout(min(deadline - time.time(), 2))
        try:
            data = json.loads(ws.recv())
            if expected_id is None or data.get("id") == expected_id:
                return data
        except:
            continue
    return None


def get_browser_url(ws=None, msg_id=900):
    """获取浏览器当前 URL。可传入已有 ws 或自动创建。"""
    close_ws = False
    if ws is None:
        ws_url, _ = get_page_ws()
        ws = websocket.create_connection(ws_url, timeout=10)
        close_ws = True
    send_cdp(ws, "Runtime.evaluate", {"expression": "window.location.href"}, msg_id=msg_id)
    data = recv_cdp(ws, expected_id=msg_id, timeout=5)
    url = data.get("result", {}).get("result", {}).get("value", "") if data else ""
    if close_ws:
        ws.close()
    return url


# ============================================================
# start: 捕获二维码 + ctxId，保存状态
# ============================================================

def cmd_start(args):
    """捕获二维码和 ctxId，保存到 state 文件，立刻返回。"""

    ws_url, page_url = get_page_ws()
    log(f"Page: {page_url[:80]}")

    # 确保在 SSO 页面
    if "ssosv.sankuai.com" not in page_url:
        log("Not on SSO page")
        output("NOT_ON_SSO_PAGE")
        sys.exit(1)

    ws = websocket.create_connection(ws_url, timeout=30)

    # 启用网络监听
    send_cdp(ws, "Network.enable", msg_id=1)
    time.sleep(0.3)

    # 刷新页面获取新二维码
    log("Refreshing SSO page...")
    send_cdp(ws, "Page.reload", {"ignoreCache": True}, msg_id=2)

    # 等待二维码生成请求
    deadline = time.time() + 20
    ctx_id = None
    qr_request_id = None
    qr_re = re.compile(r"ssosv\.sankuai\.com/sson/auth/qrcode/v1/generate/([^?]+)")

    while time.time() < deadline:
        ws.settimeout(3)
        try:
            data = json.loads(ws.recv())
        except:
            continue

        if data.get("method") == "Network.responseReceived":
            url = data.get("params", {}).get("response", {}).get("url", "")
            m = qr_re.search(url)
            if m:
                ctx_id = m.group(1)
                qr_request_id = data.get("params", {}).get("requestId")
                log(f"ctxId: {ctx_id}")
                break

    if not ctx_id:
        ws.close()
        output("FAILED:no_ctxid")
        sys.exit(1)

    # 等 loading 完成
    dl = time.time() + 5
    while time.time() < dl:
        ws.settimeout(1)
        try:
            d = json.loads(ws.recv())
            if (d.get("method") == "Network.loadingFinished"
                    and d.get("params", {}).get("requestId") == qr_request_id):
                break
        except:
            continue

    # 获取二维码图片
    send_cdp(ws, "Network.getResponseBody", {"requestId": qr_request_id}, msg_id=50)
    body_data = recv_cdp(ws, expected_id=50, timeout=10)
    ws.close()

    qr_path = None
    if body_data and "result" in body_data:
        result = body_data["result"]
        body = result.get("body", "")
        is_b64 = result.get("base64Encoded", False)

        img_data = None
        if is_b64:
            img_data = base64.b64decode(body)
        elif body:
            try:
                first_byte = ord(body[0])
                if first_byte in (0x89, 0x50):
                    img_data = body.encode("latin-1")
            except:
                pass
            if not img_data:
                try:
                    jdata = json.loads(body)
                    for key in ("qrcode", "image", "qrcodeImage", "img"):
                        if key in jdata and isinstance(jdata[key], str):
                            b64_str = jdata[key]
                            if "base64," in b64_str:
                                b64_str = b64_str.split("base64,", 1)[1]
                            img_data = base64.b64decode(b64_str)
                            break
                except:
                    pass

        if img_data:
            with open(args.output, "wb") as f:
                f.write(img_data)
            qr_path = args.output
            log(f"QR saved: {qr_path} ({len(img_data)} bytes)")

    # 如果图片提取失败，截图降级
    if not qr_path:
        log("Image extraction failed, falling back to screenshot")
        try:
            ws_url2, _ = get_page_ws()
            ws2 = websocket.create_connection(ws_url2, timeout=15)
            send_cdp(ws2, "Page.captureScreenshot", {"format": "png"}, msg_id=150)
            sdata = recv_cdp(ws2, expected_id=150, timeout=10)
            ws2.close()
            if sdata and "result" in sdata:
                img = base64.b64decode(sdata["result"].get("data", ""))
                with open(args.output, "wb") as f:
                    f.write(img)
                qr_path = args.output
                log(f"Screenshot saved: {qr_path}")
        except Exception as e:
            log(f"Screenshot error: {e}")

    if not qr_path:
        output("FAILED:no_qrcode")
        sys.exit(1)

    # 保存状态
    save_state({
        "ctx_id": ctx_id,
        "qr_path": qr_path,
        "started_at": time.time(),
        "status": "WAITING_SCAN",
    })

    output(f"QRCODE_SAVED:{qr_path}")
    output(f"CTX_ID:{ctx_id}")


# ============================================================
# status: 查询当前扫码状态（秒级返回）
# ============================================================

def cmd_status(args):
    """查询 SSO 扫码状态，秒级返回。"""
    state = load_state()
    ctx_id = state.get("ctx_id")

    if not ctx_id:
        output("NO_SESSION")
        sys.exit(1)

    # 先检查浏览器 URL，看是否已经跳转
    try:
        url = get_browser_url()
        if url and "ssosv.sankuai.com" not in url:
            output("REDIRECTED")
            save_state({**state, "status": "REDIRECTED", "final_url": url})
            return
    except:
        pass

    # 检查页面 DOM 是否有 Skip 按钮（说明扫码成功，在 access-control 页）
    try:
        ws_url, _ = get_page_ws()
        ws = websocket.create_connection(ws_url, timeout=10)
        check_js = """
        (function() {
            var els = document.querySelectorAll('button, a, div, span');
            for (var i = 0; i < els.length; i++) {
                var text = (els[i].textContent || '').trim().toLowerCase();
                if (text === 'skip' || text === '跳过' || text.match(/^skip$/i)) {
                    return 'SKIP_FOUND';
                }
            }
            // 检查是否在 access-control 页
            if (document.body && document.body.innerHTML.indexOf('access-control') !== -1) {
                return 'ACCESS_CONTROL_PAGE';
            }
            return 'NO_SKIP';
        })()
        """
        send_cdp(ws, "Runtime.evaluate", {"expression": check_js}, msg_id=300)
        data = recv_cdp(ws, expected_id=300, timeout=5)
        dom_result = data.get("result", {}).get("result", {}).get("value", "") if data else ""
        ws.close()

        if dom_result in ("SKIP_FOUND", "ACCESS_CONTROL_PAGE"):
            output("SKIP_READY")
            save_state({**state, "status": "SKIP_READY"})
            return
    except Exception as e:
        log(f"DOM check error: {e}")

    # 调 SSO status API
    url = f"{SSO_STATUS_URL}?ctxId={ctx_id}&yodaReady=h5&csecplatform=4&csecversion=4.2.0"
    ctx = ssl.create_default_context()
    opener = urllib.request.build_opener(
        urllib.request.ProxyHandler({}),
        urllib.request.HTTPSHandler(context=ctx)
    )

    try:
        req = urllib.request.Request(url, method="POST", data=b"{}")
        req.add_header("Content-Type", "application/json")
        resp = opener.open(req, timeout=10)
        body = json.loads(resp.read().decode("utf-8"))

        action = body.get("action", {})
        name = action.get("resultEnumMeta", {}).get("name", "UNKNOWN")
        msg = action.get("payload", {}).get("msg", "")

        if name == "QRCODE_SCANNING":
            output("SCANNING")
        elif name == "QRCODE_SCAN_SUCCESS":
            output("SCAN_SUCCESS")
            save_state({**state, "status": "SCAN_SUCCESS"})
        elif name == "AUTH_FLOW_SINGLE_LOGIN" or action.get("type") == "REDIRECT":
            output("CONFIRMED")
            save_state({**state, "status": "CONFIRMED"})
        elif "EXPIRED" in name:
            output("EXPIRED")
            save_state({**state, "status": "EXPIRED"})
        else:
            output(f"UNKNOWN:{name}")

    except Exception as e:
        log(f"Status API error: {e}")
        output("API_ERROR")


# ============================================================
# skip: 查找并点击 Skip 按钮
# ============================================================

def cmd_skip(args):
    """在当前页面查找 Skip 按钮。
    注意：SSO 的 Skip 按钮是 React 组件，CDP JS 无法触发点击。
    此命令只负责检测按钮是否存在，实际点击由 Agent 通过 browser tool 完成。
    """
    try:
        ws_url, page_url = get_page_ws()
        log(f"Page: {page_url[:80]}")
    except Exception as e:
        output(f"FAILED:no_browser ({e})")
        sys.exit(1)

    ws = websocket.create_connection(ws_url, timeout=15)

    # 1. 找 Skip 按钮并获取其位置坐标
    find_js = """
    (function() {
        var els = document.querySelectorAll('button, a, div, span');
        for (var i = 0; i < els.length; i++) {
            var el = els[i];
            var text = (el.textContent || '').trim();
            var lower = text.toLowerCase();
            if (lower === 'skip' || lower === '跳过') {
                var rect = el.getBoundingClientRect();
                return JSON.stringify({
                    found: true,
                    text: text,
                    x: rect.x + rect.width / 2,
                    y: rect.y + rect.height / 2,
                    tag: el.tagName
                });
            }
        }
        var debug = [];
        document.querySelectorAll('button, a, [role="button"]').forEach(function(el) {
            debug.push(el.tagName + ':' + (el.textContent || '').trim().substring(0, 40));
        });
        return JSON.stringify({found: false, elements: debug});
    })()
    """

    send_cdp(ws, "Runtime.evaluate", {"expression": find_js}, msg_id=400)
    data = recv_cdp(ws, expected_id=400, timeout=5)
    result_str = data.get("result", {}).get("result", {}).get("value", "{}") if data else "{}"

    try:
        result = json.loads(result_str)
    except:
        result = {"found": False}

    log(f"Find result: {result_str[:200]}")

    if not result.get("found"):
        ws.close()
        output(f"SKIP_FAILED:NOT_FOUND:{result_str[:200]}")
        sys.exit(1)

    x = result["x"]
    y = result["y"]
    log(f"Skip button at ({x}, {y}), clicking via CDP mouse events...")

    ws.close()

    # 输出按钮信息，Agent 通过 browser tool 点击
    output(f"SKIP_FOUND:{result.get('text', 'Skip')}")
    output("USE_BROWSER_TOOL_TO_CLICK")
    state = load_state()
    save_state({**state, "status": "SKIP_FOUND"})


# ============================================================
# verify: 最终验证
# ============================================================

def cmd_verify(args):
    """验证是否成功登录。"""
    try:
        url = get_browser_url()
        log(f"URL: {url[:80]}")

        if url and "ssosv.sankuai.com" not in url:
            output(f"LOGIN_SUCCESS:{url[:120]}")
            state = load_state()
            save_state({**state, "status": "SUCCESS", "final_url": url})
        else:
            output(f"NOT_YET:{url[:120]}")
    except Exception as e:
        output(f"VERIFY_ERROR:{e}")
        sys.exit(1)


# ============================================================
# CLI
# ============================================================

def main():
    parser = argparse.ArgumentParser(description="SSO Login v4")
    subparsers = parser.add_subparsers(dest="command")

    p = subparsers.add_parser("start", help="Capture QR code, save state")
    p.add_argument("--output", default="/tmp/sso_qrcode.png")

    subparsers.add_parser("status", help="Check scan status (instant)")
    subparsers.add_parser("skip", help="Click Skip button")
    subparsers.add_parser("verify", help="Verify login success")

    args = parser.parse_args()
    if not args.command:
        parser.print_help()
        sys.exit(1)

    cmds = {
        "start": cmd_start,
        "status": cmd_status,
        "skip": cmd_skip,
        "verify": cmd_verify,
    }
    cmds[args.command](args)


if __name__ == "__main__":
    main()
