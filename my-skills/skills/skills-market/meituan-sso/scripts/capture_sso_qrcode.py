#!/usr/bin/env python3
"""
Capture SSO QR code image from Chromium browser via CDP.
Connects to Chromium DevTools Protocol, enables Network domain,
refreshes the SSO page to trigger a QR code request, intercepts
the response body to extract the raw QR code image.

Usage:
    python3 capture_sso_qrcode.py [--output /tmp/sso_qrcode.png] [--timeout 60] [--cdp-port 9222]
"""

import argparse
import base64
import json
import re
import sys
import time
import urllib.request

try:
    import websocket
except ImportError:
    print("[WARN] websocket-client not installed, installing...", file=sys.stderr)
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "websocket-client", "-q"])
    import websocket


SSO_QRCODE_PATTERN = re.compile(
    r"https?://ssosv\.sankuai\.com/sson/auth/qrcode/v1/generate"
)


def get_ws_url(cdp_port: int, target_url_pattern: str = None):
    """
    Get the WebSocket debugger URL for an inspectable page.
    If target_url_pattern is provided, prefer a page whose URL matches it.
    Falls back to the first available page.
    """
    url = f"http://127.0.0.1:{cdp_port}/json"
    with urllib.request.urlopen(url, timeout=5) as resp:
        pages = json.loads(resp.read())

    # Prefer the SSO page if we can find it
    if target_url_pattern:
        for page in pages:
            if (page.get("type") == "page"
                    and "webSocketDebuggerUrl" in page
                    and target_url_pattern in page.get("url", "")):
                return page["webSocketDebuggerUrl"], page.get("id")

    # Fallback: first inspectable page
    for page in pages:
        if page.get("type") == "page" and "webSocketDebuggerUrl" in page:
            return page["webSocketDebuggerUrl"], page.get("id")

    raise RuntimeError("No inspectable page found in browser")


def send_cdp(ws, method: str, params: dict = None, cmd_id: int = 1) -> int:
    """Send a CDP command and return the next cmd_id."""
    msg = {"id": cmd_id, "method": method}
    if params:
        msg["params"] = params
    ws.send(json.dumps(msg))
    return cmd_id + 1


def wait_for_cdp_response(ws, expected_id: int, timeout: float = 10) -> dict:
    """Wait for a CDP response with a specific id."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        remaining = deadline - time.time()
        if remaining <= 0:
            break
        ws.settimeout(min(remaining, 2))
        try:
            raw = ws.recv()
        except websocket.WebSocketTimeoutException:
            continue
        except Exception:
            continue
        data = json.loads(raw)
        if data.get("id") == expected_id:
            return data
    return None


def capture_qrcode(cdp_port: int, output: str, timeout: int) -> str:
    """
    1. Connect to browser via CDP
    2. Enable Network domain to intercept requests
    3. Refresh the SSO page to trigger a fresh QR code request
    4. Intercept the QR code response via Network.getResponseBody
    5. Extract and save the QR code image

    Returns the local file path on success.
    """
    ws_url, page_id = get_ws_url(cdp_port, target_url_pattern="ssosv.sankuai.com")
    ws = websocket.create_connection(ws_url, timeout=timeout)

    cmd_id = 1

    # Enable Network domain
    cmd_id = send_cdp(ws, "Network.enable", cmd_id=cmd_id)
    cmd_id += 1
    time.sleep(0.3)

    # Refresh the SSO page to trigger a new QR code generation request
    print("[INFO] Refreshing SSO page to trigger QR code request...", file=sys.stderr)
    refresh_id = cmd_id
    cmd_id = send_cdp(ws, "Page.reload", params={"ignoreCache": True}, cmd_id=refresh_id)
    cmd_id += 1

    print(f"[INFO] Monitoring browser network for SSO QR code (timeout={timeout}s)...", file=sys.stderr)

    deadline = time.time() + timeout
    qrcode_request_id = None
    qrcode_url = None

    # Phase 1: Wait for the QR code network request
    while time.time() < deadline:
        remaining = deadline - time.time()
        if remaining <= 0:
            break
        ws.settimeout(min(remaining, 5))
        try:
            raw = ws.recv()
        except websocket.WebSocketTimeoutException:
            continue
        except Exception:
            continue

        data = json.loads(raw)
        method = data.get("method", "")

        # Capture requestId from responseReceived so we can fetch the body
        if method == "Network.responseReceived":
            resp_info = data.get("params", {})
            resp_url = resp_info.get("response", {}).get("url", "")
            if SSO_QRCODE_PATTERN.search(resp_url):
                qrcode_request_id = resp_info.get("requestId")
                qrcode_url = resp_url
                print(f"[INFO] Captured SSO QR code response: {qrcode_url}", file=sys.stderr)
                print(f"[INFO] Request ID: {qrcode_request_id}", file=sys.stderr)
                break

        # Also check requestWillBeSent for logging
        if method == "Network.requestWillBeSent":
            req_url = data.get("params", {}).get("request", {}).get("url", "")
            if SSO_QRCODE_PATTERN.search(req_url):
                print(f"[INFO] Detected SSO QR code request: {req_url}", file=sys.stderr)

    if not qrcode_request_id:
        print("[ERROR] Timeout: SSO QR code response not detected", file=sys.stderr)
        ws.close()
        sys.exit(1)

    # Wait for the response body to be fully loaded
    loading_deadline = time.time() + 5
    while time.time() < loading_deadline:
        ws.settimeout(1)
        try:
            raw = ws.recv()
            data = json.loads(raw)
            method = data.get("method", "")
            if method == "Network.loadingFinished":
                finished_req_id = data.get("params", {}).get("requestId")
                if finished_req_id == qrcode_request_id:
                    print("[INFO] QR code response fully loaded", file=sys.stderr)
                    break
        except websocket.WebSocketTimeoutException:
            break
        except Exception:
            break

    # Phase 2: Fetch the response body via CDP
    print("[INFO] Fetching QR code response body via CDP...", file=sys.stderr)
    get_body_id = cmd_id
    cmd_id = send_cdp(
        ws, "Network.getResponseBody",
        params={"requestId": qrcode_request_id},
        cmd_id=get_body_id
    )

    body_resp = wait_for_cdp_response(ws, get_body_id, timeout=15)
    ws.close()

    if not body_resp or "result" not in body_resp:
        error_msg = body_resp.get("error", {}).get("message", "Unknown error") if body_resp else "No response"
        print(f"[WARN] Failed to get response body via CDP: {error_msg}", file=sys.stderr)
        print("[INFO] Falling back to direct URL download...", file=sys.stderr)
        return _download_from_url(qrcode_url, output)

    result = body_resp["result"]
    body = result.get("body", "")
    is_base64 = result.get("base64Encoded", False)

    if is_base64:
        # Response body is base64-encoded binary (image)
        img_data = base64.b64decode(body)
        print(f"[INFO] Got base64-encoded image ({len(img_data)} bytes)", file=sys.stderr)
    else:
        # Response body is text - likely JSON with QR code data
        img_data = _extract_qrcode_from_json(body, qrcode_url)

    if not img_data:
        print("[ERROR] Failed to extract QR code image data", file=sys.stderr)
        sys.exit(1)

    with open(output, "wb") as f:
        f.write(img_data)

    print(f"[OK] QR code saved to {output} ({len(img_data)} bytes)", file=sys.stderr)
    print(output)
    return output


def _extract_qrcode_from_json(body: str, original_url: str) -> bytes:
    """
    Try to extract QR code image from a JSON response body.
    The SSO endpoint may return JSON with a base64-encoded image or a URL.
    """
    try:
        data = json.loads(body)
        print(f"[INFO] Response is JSON, keys: {list(data.keys()) if isinstance(data, dict) else type(data)}", file=sys.stderr)

        def find_image_data(obj, depth=0):
            """Recursively search for image data in nested dicts."""
            if depth > 5 or not isinstance(obj, dict):
                return None
            for key, val in obj.items():
                if isinstance(val, str):
                    # Check if it's a base64 image
                    if key.lower() in ("qrcode", "image", "qrcodeimage", "qr_code",
                                        "qrcodebase64", "img", "base64", "imagedata",
                                        "qrimage", "qrcodeimage"):
                        b64_str = val
                        if "base64," in b64_str:
                            b64_str = b64_str.split("base64,", 1)[1]
                        try:
                            return base64.b64decode(b64_str)
                        except Exception:
                            pass
                    # Check if it's a URL to an image
                    if key.lower() in ("url", "qrcodeurl", "imageurl", "qr_url"):
                        if val.startswith("http"):
                            print(f"[INFO] Found QR code URL in JSON: {val}", file=sys.stderr)
                            return _download_raw(val)
                elif isinstance(val, dict):
                    result = find_image_data(val, depth + 1)
                    if result:
                        return result
            return None

        result = find_image_data(data)
        if result:
            return result

        print(f"[WARN] Could not find QR image in JSON structure", file=sys.stderr)
        print(f"[DEBUG] JSON body preview: {body[:500]}", file=sys.stderr)
        return None

    except json.JSONDecodeError:
        # Not JSON - maybe raw image data?
        raw_bytes = body.encode("latin-1")
        if raw_bytes[:4] == b"\x89PNG" or raw_bytes[:3] == b"GIF" or raw_bytes[:2] == b"\xff\xd8":
            return raw_bytes
        try:
            return base64.b64decode(body)
        except Exception:
            pass
        print(f"[WARN] Response body is not JSON and not recognizable image", file=sys.stderr)
        print(f"[DEBUG] Body preview: {body[:200]}", file=sys.stderr)
        return None


def _download_raw(url: str) -> bytes:
    """Download raw bytes from a URL."""
    try:
        req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=15) as resp:
            return resp.read()
    except Exception as e:
        print(f"[WARN] Failed to download from {url}: {e}", file=sys.stderr)
        return None


def _download_from_url(url: str, output: str) -> str:
    """Fallback: download QR code directly from the captured URL."""
    print(f"[INFO] Downloading QR code from URL: {url}", file=sys.stderr)
    img_data = _download_raw(url)
    if not img_data:
        print("[ERROR] Failed to download QR code image", file=sys.stderr)
        sys.exit(1)

    with open(output, "wb") as f:
        f.write(img_data)

    print(f"[OK] QR code saved to {output} ({len(img_data)} bytes)", file=sys.stderr)
    print(output)
    return output


def main():
    parser = argparse.ArgumentParser(description="Capture SSO QR code from browser via CDP")
    parser.add_argument("--output", default="/tmp/sso_qrcode.png", help="Output image path")
    parser.add_argument("--timeout", type=int, default=60, help="Timeout in seconds")
    parser.add_argument("--cdp-port", type=int, default=9222, help="Chrome DevTools Protocol port")
    args = parser.parse_args()

    capture_qrcode(args.cdp_port, args.output, args.timeout)


if __name__ == "__main__":
    main()
