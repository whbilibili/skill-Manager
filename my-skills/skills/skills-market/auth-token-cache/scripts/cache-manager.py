#!/usr/bin/env python3
"""统一认证缓存管理

缓存文件位置：$SKILL_DIR/cache/auth-cache.json（与 skill 同目录，便于迁移）
"""
import json, os, sys, time, base64
from pathlib import Path

# 缓存文件：skill 目录下的 cache/auth-cache.json
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
SKILL_DIR = os.path.dirname(SCRIPT_DIR)
CACHE_DIR = os.path.join(SKILL_DIR, "cache")
CACHE_FILE = os.path.join(CACHE_DIR, "auth-cache.json")


def load_cache():
    if os.path.exists(CACHE_FILE):
        with open(CACHE_FILE) as f:
            return json.load(f)
    return {}


def save_cache(cache):
    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(CACHE_FILE, 'w') as f:
        json.dump(cache, f, indent=2)


def parse_jwt_expiry(token):
    """从 JWT token 中解析过期时间"""
    try:
        parts = token.split('.')
        if len(parts) != 3:
            return None
        payload = parts[1]
        # 补齐 base64 padding
        payload += '=' * (4 - len(payload) % 4)
        decoded = json.loads(base64.urlsafe_b64decode(payload))
        return decoded.get('exp')
    except Exception:
        return None


def check(service, buffer_seconds=300):
    """检查 service 的 token 是否有效（提前 buffer_seconds 判定过期）"""
    cache = load_cache()
    entry = cache.get(service)
    if not entry:
        print(json.dumps({"valid": False, "reason": "not_cached"}))
        return False

    expires_at = entry.get("expires_at", 0)
    now = time.time()
    if now + buffer_seconds >= expires_at:
        print(json.dumps({"valid": False, "reason": "expired", "expired_seconds_ago": int(now - expires_at)}))
        return False

    remaining = int(expires_at - now)
    hours = remaining // 3600
    minutes = (remaining % 3600) // 60
    expires_human = f"{hours}h{minutes}m" if hours > 0 else f"{minutes}m"
    print(json.dumps({"valid": True, "remaining_seconds": remaining, "expires_in": expires_human}))
    return True


def set_token(service, token, client_id=None, endpoint=None, ttl=None):
    """缓存 token"""
    cache = load_cache()

    # 尝试从 JWT 解析过期时间
    expires_at = None
    if token:
        expires_at = parse_jwt_expiry(token)

    # 如果 JWT 解析失败，用 TTL
    if not expires_at:
        expires_at = time.time() + (ttl or 3600)  # 默认 1 小时

    cache[service] = {
        "token": token,
        "expires_at": expires_at,
        "client_id": client_id,
        "endpoint": endpoint,
        "cached_at": time.time()
    }
    save_cache(cache)
    remaining = int(expires_at - time.time())
    print(json.dumps({"status": "cached", "service": service, "remaining_seconds": remaining}))


def get_token(service):
    """获取缓存的 token（不检查过期，由调用方先 check）"""
    cache = load_cache()
    entry = cache.get(service)
    if entry:
        print(entry.get("token", ""))
    else:
        sys.exit(1)


def get_all(service):
    """获取 service 的完整缓存信息"""
    cache = load_cache()
    entry = cache.get(service)
    if entry:
        print(json.dumps(entry))
    else:
        print(json.dumps({"error": "not_found"}))
        sys.exit(1)


def list_services():
    """列出所有缓存的 service"""
    cache = load_cache()
    now = time.time()
    result = []
    for svc, entry in cache.items():
        expires_at = entry.get("expires_at", 0)
        result.append({
            "service": svc,
            "valid": now < expires_at,
            "remaining_seconds": max(0, int(expires_at - now)),
            "cached_at": entry.get("cached_at")
        })
    print(json.dumps(result, indent=2))


def clear(service=None):
    """清除缓存"""
    if service:
        cache = load_cache()
        cache.pop(service, None)
        save_cache(cache)
    else:
        save_cache({})
    print(json.dumps({"status": "cleared", "service": service or "all"}))


def check_and_return(service, buffer=300):
    """检查缓存并直接返回 token，有效则输出 token，过期则输出错误到 stderr 并 exit 1"""
    cache = load_cache()
    entry = cache.get(service)
    if not entry:
        print(json.dumps({"valid": False, "reason": "not_cached"}), file=sys.stderr)
        sys.exit(1)
    expires_at = entry.get("expires_at", 0)
    now = time.time()
    remaining = int(expires_at - now)
    if now + buffer >= expires_at:
        print(json.dumps({"valid": False, "reason": "expired", "remaining_seconds": remaining}), file=sys.stderr)
        sys.exit(1)
    # 有效，直接输出 token
    print(entry.get("token", ""))


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("用法: cache-manager.py <check|set|get|get-all|list|clear|ensure> [args]")
        sys.exit(1)

    cmd = sys.argv[1]
    if cmd == "check":
        service = sys.argv[2] if len(sys.argv) > 2 else ""
        buffer = int(sys.argv[3]) if len(sys.argv) > 3 else 300
        check(service, buffer)
    elif cmd == "set":
        service = sys.argv[2]
        token = sys.argv[3]
        client_id = sys.argv[4] if len(sys.argv) > 4 else None
        endpoint = sys.argv[5] if len(sys.argv) > 5 else None
        ttl = int(sys.argv[6]) if len(sys.argv) > 6 else None
        set_token(service, token, client_id, endpoint, ttl)
    elif cmd == "get":
        get_token(sys.argv[2])
    elif cmd == "get-all":
        get_all(sys.argv[2])
    elif cmd == "list":
        list_services()
    elif cmd == "clear":
        clear(sys.argv[2] if len(sys.argv) > 2 else None)
    elif cmd == "ensure":
        service = sys.argv[2]
        check_and_return(service)
