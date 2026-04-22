#!/usr/bin/env python3
"""
OWA API 客户端 - 通过浏览器 fetch 调用 OWA service.svc

OWA 使用 ADFS session cookie，与浏览器绑定，
沙箱直接 HTTP 请求会 440。所有 API 调用必须通过 agent-browser eval 执行。

主要函数：
  ensure_owa_session()         - 确保浏览器已登录 OWA
  find_messages(...)           - 查询邮件列表（支持搜索/分页）
  get_message_body(id, ck)     - 获取单封邮件完整正文
  format_messages_table(msgs)  - 格式化为 Markdown 表格
"""

import json, os, subprocess, sys, time, base64, mimetypes
from pathlib import Path
from datetime import datetime, timezone, timedelta

OWA_URL = "https://mail.meituan.com/owa/"


def _run_browser_js(js: str, timeout: int = 30):
    """在 agent-browser 中执行 JS，返回解析后的 Python 对象"""
    result = subprocess.run(
        ['agent-browser', 'eval', js],
        capture_output=True, text=True, timeout=timeout
    )
    if result.returncode != 0:
        print(f"[owa_api] browser eval 失败: {result.stderr[:200]}", file=sys.stderr)
        return None
    raw = result.stdout.strip()
    try:
        if raw.startswith('"'):
            raw = json.loads(raw)  # 解包外层引号
        return json.loads(raw)
    except Exception as e:
        print(f"[owa_api] JSON 解析失败: {e}, raw[:100]: {raw[:100]}", file=sys.stderr)
        return None


COOKIE_FILE = os.path.expanduser('~/.openclaw/meituan-mail-exchange-cookie.json')

def _save_cookies() -> None:
    """登录成功后，把浏览器里的 OWA/ADFS cookie 持久化到 cookie.json"""
    js = """(function(){
  const cookies = document.cookie.split(';').map(c => {
    const i = c.indexOf('=');
    return {name: c.substring(0,i).trim(), value: c.substring(i+1).trim(), domain: location.hostname};
  }).filter(c => c.name);
  return JSON.stringify(cookies);
})()"""
    result = subprocess.run(['agent-browser', 'eval', js], capture_output=True, text=True, timeout=10)
    if result.returncode != 0:
        return
    try:
        raw = result.stdout.strip()
        if raw.startswith('"'): raw = json.loads(raw)
        cookies = json.loads(raw)
        if cookies:
            with open(COOKIE_FILE, 'w') as f:
                json.dump(cookies, f, ensure_ascii=False, indent=2)
            print(f"[owa_api] 💾 已保存 {len(cookies)} 个 cookie 到 cookie.json", file=sys.stderr)
    except Exception as e:
        print(f"[owa_api] 保存 cookie 失败: {e}", file=sys.stderr)

def _restore_cookies() -> bool:
    """从 cookie.json 恢复 cookie 到浏览器，返回是否成功注入"""
    if not os.path.exists(COOKIE_FILE):
        return False
    try:
        with open(COOKIE_FILE, 'r') as f:
            cookies = json.load(f)
        if not cookies:
            return False
        # 先导航到 OWA 域名，让 cookie 能注入
        result = subprocess.run(['agent-browser', 'get', 'url'], capture_output=True, text=True, timeout=10)
        current_url = result.stdout.strip()
        if 'mail.meituan.com' not in current_url:
            subprocess.run(['agent-browser', 'open', 'https://mail.meituan.com/owa/'], capture_output=True, timeout=15)
            time.sleep(2)
        # 用 JS 注入 cookie
        cookie_js = "document.cookie = " + "; document.cookie = ".join(
            f'"{c["name"]}={c["value"]}; path=/; domain=.meituan.com"' for c in cookies
        )
        subprocess.run(['agent-browser', 'eval', cookie_js], capture_output=True, text=True, timeout=10)
        print(f"[owa_api] 🍪 已从 cookie.json 注入 {len(cookies)} 个 cookie", file=sys.stderr)
        return True
    except Exception as e:
        print(f"[owa_api] 恢复 cookie 失败: {e}", file=sys.stderr)
        return False

def ensure_owa_session() -> bool:
    """确保浏览器已登录 OWA。优先从 cookie.json 恢复 session，失败才提示扫码"""
    result = subprocess.run(['agent-browser', 'get', 'url'], capture_output=True, text=True, timeout=10)
    current_url = result.stdout.strip()

    if 'mail.meituan.com' not in current_url:
        print("[owa_api] 导航到 OWA...", file=sys.stderr)
        subprocess.run(['agent-browser', 'open', OWA_URL], capture_output=True, timeout=30)
        subprocess.run(['agent-browser', 'wait', '--load', 'networkidle'], capture_output=True, timeout=30)
        time.sleep(2)

    check_js = "(function(){ const c={}; document.cookie.split(';').forEach(x=>{const i=x.indexOf('=');if(i>0)c[x.substring(0,i).trim()]=x.substring(i+1).trim();}); return JSON.stringify({hasCanary:!!c['X-OWA-CANARY'],url:location.href}); })()"

    def _check_session() -> bool:
        r = subprocess.run(['agent-browser', 'eval', check_js], capture_output=True, text=True, timeout=15)
        if r.returncode != 0:
            return False
        try:
            raw = r.stdout.strip()
            if raw.startswith('"'): raw = json.loads(raw)
            data = json.loads(raw)
            return bool(data.get('hasCanary'))
        except Exception:
            return False

    # 1. 先检查当前 session
    if _check_session():
        print("[owa_api] ✅ OWA session 有效", file=sys.stderr)
        _save_cookies()
        return True

    # 2. session 无效，尝试从 cookie.json 恢复
    print("[owa_api] session 失效，尝试从 cookie.json 恢复...", file=sys.stderr)
    if _restore_cookies():
        # 恢复后重新导航到 OWA 并检查
        subprocess.run(['agent-browser', 'open', OWA_URL], capture_output=True, timeout=30)
        subprocess.run(['agent-browser', 'wait', '--load', 'networkidle'], capture_output=True, timeout=30)
        time.sleep(2)
        if _check_session():
            print("[owa_api] ✅ cookie 恢复成功，OWA session 有效", file=sys.stderr)
            return True  # 恢复的 cookie 不需要重新保存
        print("[owa_api] cookie 已过期，需要重新登录", file=sys.stderr)

    # 3. cookie 也过期了，提示扫码
    print("[owa_api] ❌ 未登录 OWA，需要扫码登录", file=sys.stderr)
    return False


def find_messages(
    folder: str = "inbox",
    query: str = "",
    max_count: int = 20,
    offset: int = 0,
) -> list | None:
    """
    查询邮件列表。

    参数：
      folder:    文件夹名，如 "inbox"/"sentitems"/"deleteditems"
      query:     OWA 搜索关键词（如 "from:zhangsan" / "项目评审"）
      max_count: 最多返回条数（默认 20）
      offset:    分页偏移

    返回 list of dict：
      id, change_key, subject, from_name, from_email,
      display_to, display_cc, received_at, sent_at,
      has_attachment, is_read, importance
    """
    # 构建 QueryString 部分（可选）
    query_part = f', "QueryString": {json.dumps(query)}' if query else ""

    js = f"""
(async function() {{
  const canary = document.cookie.split(';').map(c=>c.trim()).find(c=>c.startsWith('X-OWA-CANARY='))?.split('=').slice(1).join('=') || '';
  if (!canary) return JSON.stringify({{error: 'no canary'}});

  const payload = {{
    "__type": "FindItemJsonRequest:#Exchange",
    "Header": {{
      "__type": "JsonRequestHeaders:#Exchange",
      "RequestServerVersion": "V2015_10_15",
      "TimeZoneContext": {{
        "__type": "TimeZoneContext:#Exchange",
        "TimeZoneDefinition": {{"__type": "TimeZoneDefinitionType:#Exchange", "Id": "China Standard Time"}}
      }}
    }},
    "Body": {{
      "__type": "FindItemRequest:#Exchange",
      "Traversal": "Shallow",
      "ItemShape": {{"__type": "ItemResponseShape:#Exchange", "BaseShape": "AllProperties"}},
      "IndexedPageItemView": {{
        "__type": "IndexedPageView:#Exchange",
        "BasePoint": "Beginning",
        "Offset": {offset},
        "MaxEntriesReturned": {max_count}
      }},
      "SortOrder": [{{"__type":"SortResults:#Exchange","Order":"Descending","Path":{{"__type":"PropertyUri:#Exchange","FieldURI":"item:DateTimeReceived"}}}}],
      "ParentFolderIds": [{{"__type":"DistinguishedFolderId:#Exchange","Id":"{folder}"}}]
      {query_part}
    }}
  }};

  const resp = await fetch('/owa/service.svc?action=FindItem&ID=-100&AC=1', {{
    method: 'POST', credentials: 'include',
    headers: {{'Content-Type':'application/json; charset=utf-8','X-OWA-CANARY':canary,'Action':'FindItem','X-Requested-With':'XMLHttpRequest'}},
    body: JSON.stringify(payload)
  }});

  const data = await resp.json();
  const rf = data?.Body?.ResponseMessages?.Items?.[0]?.RootFolder || {{}};
  const msgs = rf.Items || [];
  const total = rf.TotalItemsInView || 0;

  const result = msgs.map(m => ({{
    id: m.ItemId?.Id || '',
    change_key: m.ItemId?.ChangeKey || '',
    subject: m.Subject || '(无主题)',
    from_name: m.From?.Mailbox?.Name || m.Sender?.Mailbox?.Name || '',
    from_email: m.From?.Mailbox?.EmailAddress || m.Sender?.Mailbox?.EmailAddress || '',
    display_to: m.DisplayTo || '',
    display_cc: m.DisplayCc || '',
    received_at: m.DateTimeReceived || '',
    sent_at: m.DateTimeSent || '',
    has_attachment: !!m.HasAttachments,
    is_read: !!m.IsRead,
    importance: m.Importance || 'Normal'
  }}));

  // _server_total 来自 TotalItemsInView，不可靠，禁止用于统计展示
  return JSON.stringify({{_server_total: total, count: result.length, messages: result}});
}})()
"""

    data = _run_browser_js(js, timeout=45)
    if not data:
        return None
    if "error" in data:
        print(f"[owa_api] FindItem 错误: {data['error']}", file=sys.stderr)
        return None

    print(f"[owa_api] 查询到 {data['count']} 封邮件（以实际返回列表长度为准）", file=sys.stderr)
    return data.get("messages", [])


def get_message_body(item_id: str, change_key: str) -> dict | None:
    """获取单封邮件的完整正文和附件列表"""
    js = f"""
(async function() {{
  const canary = document.cookie.split(';').map(c=>c.trim()).find(c=>c.startsWith('X-OWA-CANARY='))?.split('=').slice(1).join('=') || '';
  if (!canary) return JSON.stringify({{error: 'no canary'}});

  const payload = {{
    "__type": "GetItemJsonRequest:#Exchange",
    "Header": {{
      "__type": "JsonRequestHeaders:#Exchange",
      "RequestServerVersion": "V2015_10_15",
      "TimeZoneContext": {{
        "__type": "TimeZoneContext:#Exchange",
        "TimeZoneDefinition": {{"__type": "TimeZoneDefinitionType:#Exchange", "Id": "China Standard Time"}}
      }}
    }},
    "Body": {{
      "__type": "GetItemRequest:#Exchange",
      "ItemShape": {{
        "__type": "ItemResponseShape:#Exchange",
        "BaseShape": "AllProperties",
        "BodyType": "Text"
      }},
      "ItemIds": [{{"__type":"ItemId:#Exchange","Id":{json.dumps(item_id)},"ChangeKey":{json.dumps(change_key)}}}]
    }}
  }};

  const resp = await fetch('/owa/service.svc?action=GetItem&ID=-100&AC=1', {{
    method: 'POST', credentials: 'include',
    headers: {{'Content-Type':'application/json; charset=utf-8','X-OWA-CANARY':canary,'Action':'GetItem','X-Requested-With':'XMLHttpRequest'}},
    body: JSON.stringify(payload)
  }});

  const data = await resp.json();
  const item = data?.Body?.ResponseMessages?.Items?.[0]?.Items?.[0];
  if (!item) return JSON.stringify({{error: 'item not found', raw: JSON.stringify(data).substring(0,200)}});

  const body = item.Body?.Value || '';
  const attachments = (item.Attachments||[]).map(a => a.Name || '');
  const toList = (item.ToRecipients||[]).map(r => ({{name:r.Name||'',email:r.EmailAddress||''}}));
  const ccList = (item.CcRecipients||[]).map(r => ({{name:r.Name||'',email:r.EmailAddress||''}}));

  return JSON.stringify({{
    subject: item.Subject || '',
    from_name: item.From?.Mailbox?.Name || '',
    from_email: item.From?.Mailbox?.EmailAddress || '',
    to: toList,
    cc: ccList,
    received_at: item.DateTimeReceived || '',
    is_read: !!item.IsRead,
    importance: item.Importance || 'Normal',
    has_attachment: !!item.HasAttachments,
    attachments,
    body: body.substring(0, 4000),
    body_truncated: body.length > 4000
  }});
}})()
"""
    return _run_browser_js(js, timeout=30)


def _utc_to_local(dt_str: str) -> str:
    """将 UTC 时间字符串转为 UTC+8 显示格式"""
    try:
        dt = datetime.fromisoformat(dt_str.replace('Z', '+00:00'))
        local = dt + timedelta(hours=8)
        return local.strftime("%m-%d %H:%M")
    except Exception:
        return dt_str[:16] if dt_str else ''


def format_messages_table(messages: list) -> str:
    """将邮件列表格式化为逐封卡片（每封独立展示，禁止合并行或汇总）"""
    if not messages:
        return "（未找到符合条件的邮件）"

    importance_map = {'High': '🔴重要', 'Low': '⬇️低', 'Normal': '普通'}
    cards = []
    for i, m in enumerate(messages, 1):
        time_str = _utc_to_local(m.get('received_at', ''))
        from_name = m.get('from_name', '')
        from_email = m.get('from_email', '')
        sender = from_name if from_name else from_email
        subject = m.get('subject', '(无主题)')
        display_to = m.get('display_to', '') or '—'
        display_cc = m.get('display_cc', '') or ''
        has_attach = '📎' if m.get('has_attachment') else ''
        is_read = '' if m.get('is_read') else '🔵'
        importance = importance_map.get(m.get('importance', 'Normal'), '普通')
        preview = m.get('preview', '') or ''
        if preview and len(preview) > 100:
            preview = preview[:100] + '…'

        # 第一行：序号 + 已读状态 + 主题 + 附件标记
        line1 = f"{is_read}[{i}] {subject}{' ' + has_attach if has_attach else ''}"
        # 第二行：发件人 + 时间
        line2 = f"   👤 {sender}  🕐 {time_str}"
        # 第三行：收件人（截断过长）
        to_short = display_to[:30] + '…' if len(display_to) > 30 else display_to
        line3 = f"   📬 {to_short}"
        # 第四行：重要性（非普通才显示）+ 抄送（有才显示）
        meta_parts = []
        if importance != '普通':
            meta_parts.append(importance)
        if display_cc:
            cc_short = display_cc[:20] + '…' if len(display_cc) > 20 else display_cc
            meta_parts.append(f"抄送：{cc_short}")
        # 第五行：正文摘要（有才显示）
        card_lines = [line1, line2, line3]
        if meta_parts:
            card_lines.append(f"   {'  '.join(meta_parts)}")
        if preview:
            card_lines.append(f"   💬 {preview}")

        cards.append("\n".join(card_lines))

    result = "\n\n".join(cards)
    result += f"\n\n共 {len(messages)} 封（🔵=未读 📎=有附件）"
    return result





MAX_ATTACHMENT_SIZE = 10 * 1024 * 1024  # 单个附件最大 10MB（base64 编码前）


def prepare_attachments(file_paths: list) -> list:
    """
    读取本地文件列表，返回附件数据。

    参数：
      file_paths: 本地文件路径列表，如 ["/tmp/report.pdf", "/tmp/data.xlsx"]

    返回：
      [{"name": "report.pdf", "content_base64": "...", "content_type": "application/pdf"}, ...]

    限制：
      - 单个文件不能超过 10MB（base64 编码前）
      - 文件不存在或不可读时抛出 FileNotFoundError / PermissionError
    """
    result = []
    for fp in file_paths:
        fp = os.path.expanduser(fp)
        if not os.path.isfile(fp):
            raise FileNotFoundError(f"附件文件不存在: {fp}")
        file_size = os.path.getsize(fp)
        if file_size > MAX_ATTACHMENT_SIZE:
            raise ValueError(f"附件 {os.path.basename(fp)} 大小 {file_size / 1024 / 1024:.1f}MB 超过 10MB 限制")
        with open(fp, 'rb') as f:
            content = f.read()
        content_b64 = base64.b64encode(content).decode('ascii')
        content_type = mimetypes.guess_type(fp)[0] or 'application/octet-stream'
        result.append({
            "name": os.path.basename(fp),
            "content_base64": content_b64,
            "content_type": content_type,
        })
    return result


def _delete_draft(item_id: str, change_key: str) -> None:
    """尝试删除草稿（best effort，失败不抛异常）"""
    js = f"""
(async function() {{
  const canary = document.cookie.split(';').map(c=>c.trim()).find(c=>c.startsWith('X-OWA-CANARY='))?.split('=').slice(1).join('=') || '';
  if (!canary) return JSON.stringify({{error:'no canary'}});
  const payload = {{
    "__type": "DeleteItemJsonRequest:#Exchange",
    "Header": {{
      "__type": "JsonRequestHeaders:#Exchange",
      "RequestServerVersion": "V2015_10_15",
      "TimeZoneContext": {{
        "__type": "TimeZoneContext:#Exchange",
        "TimeZoneDefinition": {{"__type": "TimeZoneDefinitionType:#Exchange", "Id": "China Standard Time"}}
      }}
    }},
    "Body": {{
      "__type": "DeleteItemRequest:#Exchange",
      "DeleteType": "HardDelete",
      "ItemIds": [{{"__type":"ItemId:#Exchange","Id":{json.dumps(item_id)},"ChangeKey":{json.dumps(change_key)}}}]
    }}
  }};
  const resp = await fetch('/owa/service.svc?action=DeleteItem&ID=-100&AC=1', {{
    method:'POST', credentials:'include',
    headers:{{'Content-Type':'application/json; charset=utf-8','X-OWA-CANARY':canary,'Action':'DeleteItem','X-Requested-With':'XMLHttpRequest'}},
    body:JSON.stringify(payload)
  }});
  return JSON.stringify({{ok:true}});
}})()
"""
    try:
        _run_browser_js(js, timeout=15)
    except Exception:
        pass  # best effort，静默失败


def send_message(
    to: list,
    subject: str,
    body: str,
    cc: list = None,
    bcc: list = None,
    importance: str = "Normal",
    body_type: str = "HTML",
    attachments: list = None,
) -> dict:
    """
    通过 OWA API 发送邮件。

    无附件时使用 SendAndSaveCopy 一步发送（向后兼容）。
    有附件时走三步流程：CreateItem(草稿) → CreateAttachment → SendItem。

    参数：
      to:          收件人列表，支持邮箱地址或 mis（不含@时自动补全 @meituan.com）
      subject:     邮件主题
      body:        正文内容（HTML 或纯文本，由 body_type 决定）
      cc:          抄送列表（可选）
      bcc:         密送列表（可选）
      importance:  Normal / High / Low
      body_type:   HTML（默认）或 Text
      attachments: 附件列表（可选），每个元素为 dict：
                   {"name": "文件名.pdf", "content_base64": "base64字符串", "content_type": "application/pdf"}
                   可通过 prepare_attachments() 辅助生成

    返回：
      {"success": True, "item_id": "..."}  或  {"success": False, "error": "..."}
    """
    def _make_recipients(addrs):
        result = []
        for addr in (addrs or []):
            addr = addr.strip()
            if not addr:
                continue
            if "@" not in addr:
                addr = f"{addr}@meituan.com"
            # OWA 原生格式：扁平 EmailAddress 对象，而非 Recipient 包装
            result.append({
                "__type": "EmailAddress:#Exchange",
                "MailboxType": "OneOff",
                "RoutingType": "SMTP",
                "EmailAddress": addr,
                "Name": ""
            })
        return result

    # ---------- 无附件：SendAndSaveCopy 一步发送（OWA 原生 payload 格式）----------
    if not attachments:
        payload = {
            "__type": "CreateItemJsonRequest:#Exchange",
            "Header": {
                "__type": "JsonRequestHeaders:#Exchange",
                "RequestServerVersion": "V2015_10_15",
                "TimeZoneContext": {
                    "__type": "TimeZoneContext:#Exchange",
                    "TimeZoneDefinition": {
                        "__type": "TimeZoneDefinitionType:#Exchange",
                        "Id": "China Standard Time"
                    }
                }
            },
            "Body": {
                "__type": "CreateItemRequest:#Exchange",
                # MessageDisposition / ComposeOperation 放在 Body 级别（OWA 原生要求）
                "ClientSupportsIrm": True,
                "OutboundCharset": "AutoDetect",
                "MessageDisposition": "SendAndSaveCopy",
                "ComposeOperation": "newMail",
                "Items": [{
                    "__type": "Message:#Exchange",
                    "Subject": subject,
                    "Body": {"__type": "BodyContentType:#Exchange", "BodyType": body_type, "Value": body},
                    "Importance": importance,
                    "ToRecipients": _make_recipients(to),
                    "CcRecipients": _make_recipients(cc) or [],
                    "BccRecipients": _make_recipients(bcc) or [],
                    "Sensitivity": "Normal",
                    "IsDeliveryReceiptRequested": False,
                    "IsReadReceiptRequested": False,
                }]
                # 不传 SavedItemFolderId，OWA 自动保存到已发送
            }
        }
        payload_json = json.dumps(payload, ensure_ascii=False)

        js = """
(async function() {
  const canary = document.cookie.split(';').map(c=>c.trim()).find(c=>c.startsWith('X-OWA-CANARY='))?.split('=').slice(1).join('=') || '';
  if (!canary) return JSON.stringify({success:false, error:'no canary, OWA session invalid'});

  const payload = """ + payload_json + """;

  const resp = await fetch('/owa/service.svc?action=CreateItem&ID=-100&AC=1', {
    method: 'POST', credentials: 'include',
    headers: {'Content-Type':'application/json; charset=utf-8','X-OWA-CANARY':canary,'Action':'CreateItem','X-Requested-With':'XMLHttpRequest'},
    body: JSON.stringify(payload)
  });

  const data = await resp.json();
  const item = data?.Body?.ResponseMessages?.Items?.[0];
  if (item?.ResponseClass === 'Success') {
    const itemId = item.Items?.[0]?.ItemId?.Id || '';
    return JSON.stringify({success:true, item_id:itemId});
  } else {
    const errMsg = item?.MessageText || JSON.stringify(data).substring(0,300);
    return JSON.stringify({success:false, error:errMsg});
  }
})()
"""
        result = _run_browser_js(js, timeout=30)
        if result is None:
            return {"success": False, "error": "browser eval returned None"}
        return result

    # ---------- 有附件：三步流程 CreateItem(草稿) → CreateAttachment → SendItem ----------

    # 附件大小检查（base64 编码前，即原始文件大小估算）
    for att in attachments:
        raw_size = len(att["content_base64"]) * 3 / 4  # base64 → 原始字节数近似
        if raw_size > MAX_ATTACHMENT_SIZE:
            return {"success": False, "error": f"附件 {att['name']} 超过 10MB 限制"}

    # ---- 第一步：CreateItem 创建草稿（OWA 原生格式，SaveOnly）----
    draft_payload = {
        "__type": "CreateItemJsonRequest:#Exchange",
        "Header": {
            "__type": "JsonRequestHeaders:#Exchange",
            "RequestServerVersion": "V2015_10_15",
            "TimeZoneContext": {
                "__type": "TimeZoneContext:#Exchange",
                "TimeZoneDefinition": {
                    "__type": "TimeZoneDefinitionType:#Exchange",
                    "Id": "China Standard Time"
                }
            }
        },
        "Body": {
            "__type": "CreateItemRequest:#Exchange",
            # MessageDisposition / ComposeOperation 放在 Body 级别（OWA 原生要求）
            "ClientSupportsIrm": True,
            "OutboundCharset": "AutoDetect",
            "MessageDisposition": "SaveOnly",
            "ComposeOperation": "newMail",
            "Items": [{
                "__type": "Message:#Exchange",
                "Subject": subject,
                "Body": {"__type": "BodyContentType:#Exchange", "BodyType": body_type, "Value": body},
                "Importance": importance,
                "ToRecipients": _make_recipients(to),
                "CcRecipients": _make_recipients(cc) or [],
                "BccRecipients": _make_recipients(bcc) or [],
                "Sensitivity": "Normal",
                "IsDeliveryReceiptRequested": False,
                "IsReadReceiptRequested": False,
            }]
            # 不传 SavedItemFolderId，OWA 自动处理草稿目录
        }
    }
    draft_payload_json = json.dumps(draft_payload, ensure_ascii=False)

    create_draft_js = """
(async function() {
  const canary = document.cookie.split(';').map(c=>c.trim()).find(c=>c.startsWith('X-OWA-CANARY='))?.split('=').slice(1).join('=') || '';
  if (!canary) return JSON.stringify({success:false, error:'no canary, OWA session invalid'});

  const payload = """ + draft_payload_json + """;

  const resp = await fetch('/owa/service.svc?action=CreateItem&ID=-100&AC=1', {
    method: 'POST', credentials: 'include',
    headers: {'Content-Type':'application/json; charset=utf-8','X-OWA-CANARY':canary,'Action':'CreateItem','X-Requested-With':'XMLHttpRequest'},
    body: JSON.stringify(payload)
  });

  const data = await resp.json();
  const item = data?.Body?.ResponseMessages?.Items?.[0];
  if (item?.ResponseClass === 'Success') {
    const draftId = item.Items?.[0]?.ItemId?.Id || '';
    const changeKey = item.Items?.[0]?.ItemId?.ChangeKey || '';
    return JSON.stringify({success:true, draft_id:draftId, change_key:changeKey});
  } else {
    const errMsg = item?.MessageText || JSON.stringify(data).substring(0,300);
    return JSON.stringify({success:false, error:errMsg});
  }
})()
"""
    draft_result = _run_browser_js(create_draft_js, timeout=30)
    if not draft_result or not draft_result.get("success"):
        err = (draft_result or {}).get("error", "创建草稿失败（browser eval returned None）")
        return {"success": False, "error": f"第一步创建草稿失败: {err}"}

    draft_id = draft_result["draft_id"]
    change_key = draft_result["change_key"]

    # ---- 第二步：CreateAttachment 逐个添加附件 ----
    for att in attachments:
        attach_payload = {
            "__type": "CreateAttachmentJsonRequest:#Exchange",
            "Header": {
                "__type": "JsonRequestHeaders:#Exchange",
                "RequestServerVersion": "V2015_10_15",
                "TimeZoneContext": {
                    "__type": "TimeZoneContext:#Exchange",
                    "TimeZoneDefinition": {
                        "__type": "TimeZoneDefinitionType:#Exchange",
                        "Id": "China Standard Time"
                    }
                }
            },
            "Body": {
                "__type": "CreateAttachmentRequest:#Exchange",
                "ParentItemId": {"__type": "ItemId:#Exchange", "Id": draft_id, "ChangeKey": change_key},
                "Attachments": [{
                    "__type": "FileAttachment:#Exchange",
                    "Name": att["name"],
                    "ContentType": att["content_type"],
                    "Content": att["content_base64"],
                }]
            }
        }
        attach_payload_json = json.dumps(attach_payload, ensure_ascii=False)

        create_attach_js = """
(async function() {
  const canary = document.cookie.split(';').map(c=>c.trim()).find(c=>c.startsWith('X-OWA-CANARY='))?.split('=').slice(1).join('=') || '';
  if (!canary) return JSON.stringify({success:false, error:'no canary'});

  const payload = """ + attach_payload_json + """;

  const resp = await fetch('/owa/service.svc?action=CreateAttachment&ID=-100&AC=1', {
    method: 'POST', credentials: 'include',
    headers: {'Content-Type':'application/json; charset=utf-8','X-OWA-CANARY':canary,'Action':'CreateAttachment','X-Requested-With':'XMLHttpRequest'},
    body: JSON.stringify(payload)
  });

  const data = await resp.json();
  const item = data?.Body?.ResponseMessages?.Items?.[0];
  if (item?.ResponseClass === 'Success') {
    const newChangeKey = item.Attachments?.[0]?.AttachmentId?.RootItemChangeKey || '';
    return JSON.stringify({success:true, change_key:newChangeKey});
  } else {
    const errMsg = item?.MessageText || JSON.stringify(data).substring(0,300);
    return JSON.stringify({success:false, error:errMsg});
  }
})()
"""
        attach_result = _run_browser_js(create_attach_js, timeout=60)
        if not attach_result or not attach_result.get("success"):
            err = (attach_result or {}).get("error", "browser eval returned None")
            # best effort 清理草稿
            _delete_draft(draft_id, change_key)
            return {"success": False, "error": f"第二步添加附件 {att['name']} 失败: {err}"}
        # 更新 ChangeKey（每次添加附件后 ChangeKey 会变）
        change_key = attach_result["change_key"]

    # ---- 第三步：UpdateItem (MessageDisposition=SendAndSaveCopy) 发送草稿 ----
    # OWA 原生发送附件邮件用的是 UpdateItem，不是 SendItem
    def _make_set_field(field_uri, item_type, field_name, field_value):
        return {
            "__type": "SetItemField:#Exchange",
            "Path": {"__type": "PropertyUri:#Exchange", "FieldURI": field_uri},
            "Item": {"__type": f"{item_type}:#Exchange", field_name: field_value}
        }

    send_payload = {
        "__type": "UpdateItemJsonRequest:#Exchange",
        "Header": {
            "__type": "JsonRequestHeaders:#Exchange",
            "RequestServerVersion": "Exchange2015",
            "TimeZoneContext": {
                "__type": "TimeZoneContext:#Exchange",
                "TimeZoneDefinition": {
                    "__type": "TimeZoneDefinitionType:#Exchange",
                    "Id": "China Standard Time"
                }
            }
        },
        "Body": {
            "__type": "UpdateItemRequest:#Exchange",
            "ConflictResolution": "AlwaysOverwrite",
            "ClientSupportsIrm": True,
            "SendCalendarInvitationsOrCancellations": "SendToNone",
            "MessageDisposition": "SendAndSaveCopy",
            "SuppressReadReceipts": False,
            "ComposeOperation": "newMail",
            "OutboundCharset": "AutoDetect",
            "PromoteEmojiContentToInlineAttachmentsCount": 0,
            "UnpromotedInlineImageCount": 0,
            "PromoteInlineAttachments": False,
            "SendOnNotFoundError": True,
            "ItemChanges": [{
                "__type": "ItemChange:#Exchange",
                "ItemId": {"__type": "ItemId:#Exchange", "Id": draft_id, "ChangeKey": change_key},
                "Updates": [
                    _make_set_field("CcRecipients", "Message", "CcRecipients", _make_recipients(cc) or []),
                    _make_set_field("BccRecipients", "Message", "BccRecipients", _make_recipients(bcc) or []),
                    _make_set_field("ToRecipients", "Message", "ToRecipients", _make_recipients(to)),
                    _make_set_field("IsReadReceiptRequested", "Message", "IsReadReceiptRequested", False),
                    _make_set_field("IsDeliveryReceiptRequested", "Message", "IsDeliveryReceiptRequested", False),
                    _make_set_field("Importance", "Message", "Importance", importance),
                    _make_set_field("Sensitivity", "Message", "Sensitivity", "Normal"),
                    _make_set_field("Subject", "Message", "Subject", subject),
                    _make_set_field("item:Body", "Message", "Body", {
                        "__type": "BodyContentType:#Exchange",
                        "BodyType": body_type,
                        "Value": body
                    }),
                ]
            }]
        }
    }
    send_payload_json = json.dumps(send_payload, ensure_ascii=False)

    send_js = """
(async function() {
  const canary = document.cookie.split(';').map(c=>c.trim()).find(c=>c.startsWith('X-OWA-CANARY='))?.split('=').slice(1).join('=') || '';
  if (!canary) return JSON.stringify({success:false, error:'no canary'});

  const payload = """ + send_payload_json + """;

  const resp = await fetch('/owa/service.svc?action=UpdateItem&ID=-100&AC=1', {
    method: 'POST', credentials: 'include',
    headers: {'Content-Type':'application/json; charset=utf-8','X-OWA-CANARY':canary,'Action':'UpdateItem','X-Requested-With':'XMLHttpRequest'},
    body: JSON.stringify(payload)
  });

  const data = await resp.json();
  const item = data?.Body?.ResponseMessages?.Items?.[0];
  if (item?.ResponseClass === 'Success') {
    return JSON.stringify({success:true});
  } else {
    const errMsg = item?.MessageText || JSON.stringify(data).substring(0,300);
    return JSON.stringify({success:false, error:errMsg});
  }
})()
"""
    send_result = _run_browser_js(send_js, timeout=30)
    if not send_result or not send_result.get("success"):
        err = (send_result or {}).get("error", "browser eval returned None")
        # best effort 清理草稿
        _delete_draft(draft_id, change_key)
        return {"success": False, "error": f"第三步发送草稿失败: {err}"}

    return {"success": True, "item_id": draft_id}


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="OWA API 命令行工具")
    parser.add_argument("action", choices=["list", "get"])
    parser.add_argument("--folder", default="inbox")
    parser.add_argument("--query", default="")
    parser.add_argument("--count", type=int, default=20)
    parser.add_argument("--offset", type=int, default=0)
    parser.add_argument("--id", help="邮件 ID（get 操作用）")
    parser.add_argument("--ck", default="", help="邮件 ChangeKey（get 操作用）")
    parser.add_argument("--raw", action="store_true")
    args = parser.parse_args()

    if not ensure_owa_session():
        print("❌ OWA 未登录"); sys.exit(1)

    if args.action == "list":
        messages = find_messages(folder=args.folder, query=args.query,
                                  max_count=args.count, offset=args.offset)
        if messages is None:
            print("❌ 查询失败"); sys.exit(1)
        if args.raw:
            print(json.dumps(messages, ensure_ascii=False, indent=2))
        else:
            print(f"\n共 {len(messages)} 封邮件\n")
            print(format_messages_table(messages))

    elif args.action == "get":
        if not args.id:
            print("❌ --id 必填"); sys.exit(1)
        result = get_message_body(args.id, args.ck)
        if result:
            if args.raw:
                print(json.dumps(result, ensure_ascii=False, indent=2))
            else:
                print(f"主题: {result.get('subject')}")
                print(f"发件人: {result.get('from_name')} <{result.get('from_email')}>")
                print(f"时间: {_utc_to_local(result.get('received_at',''))}")
                print(f"正文:\n{result.get('body','')[:1000]}")
        else:
            print("❌ 获取失败"); sys.exit(1)
