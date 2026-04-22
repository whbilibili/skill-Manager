# 备选方案与存档（降级 / Desk 环境备用）

> 本文件包含当官方 mtsso skill（[id: 6556](https://friday.sankuai.com/skills/skill-detail?id=6556)）不可用时的降级方案。
> 沙箱环境请优先使用 `SKILL.md` 中的推荐方案。

---

## 备选方案总览

| 目标 | 使用路径 |
|------|---------|
| CLI / API 调用需要 ssoid / access token | **路径 B：sso-auth-cli** |
| 浏览器访问内网页面（km、dev、ones 等） | **路径 A：Browser SSO** |
| 其他 skill 需要获取已有 Cookie | **路径 C：extract_cookies.py** |

> 以上路径均依赖沙箱环境的 Chromium（CDP 9222）和 MOA，不适用于 Desk 环境。

---

## 备选路径 B：sso-auth-cli（CLI / API 获取 access token）

适用于：CLI 工具调用内网 API、需要 ssoid / Bearer token、其他非浏览器场景。

### 安装（首次使用）

```bash
npm install -g @dp/sso-auth-cli --registry http://r.npm.sankuai.com
```

### 获取 token

```bash
# 获取 access token（自动通过 CDP 读取 MOA 凭证，无需扫码）
sso-auth-cli <clientId>

# 获取 Cookie 格式（yun_portal_ssoid=xxx）
sso-auth-cli <clientId> --cookie

# 带 misId 作为 CIBA loginHint 兜底
sso-auth-cli <clientId> --mis wangkai120
```

**clientId 说明：**
- 传入 clientId 数字（如 `60921859`）→ 直接用
- 传入内网 URL（如 `https://km.sankuai.com`）→ 自动解析出 clientId

**工作原理：**
1. 通过 CDP（端口 9222）从 Chromium 读取 MOA 凭证（TGCX / moa_token）
2. 凭 MOA 凭证向 SSO 换取 OIDC token（无需扫码，秒级完成）
3. token 缓存在 `~/.config/sso-auth-cli/cache.json`，自动续期

**常见 clientId：**
| 系统 | clientId |
|------|----------|
| yun_portal（通用） | `60921859` |
| 传 URL 自动解析 | `https://<system>.sankuai.com` |

### 注意事项

- 依赖 Chromium 中已有的 MOA 凭证（TGCX Cookie）
- 如果 CDP 获取凭证失败，说明 Chromium 里没有 TGCX，需要先走存档路径 A 扫码登录
- token 有效期约 2-3 小时，脚本自动检测过期并刷新

### 集成接口（供其他 skill 调用）

```bash
# 先检查是否已有有效 token
TOKEN=$(sso-auth-cli 60921859 --cookie 2>/dev/null)
if [ $? -ne 0 ]; then
  # token 失效，需要重新登录
  echo "SSO token 失效，需要重新登录"
fi
```

---

## 沙箱环境说明

- **沙箱已在美团内网**：`.sankuai.com` 域名直连，不需要额外代理
- **Chromium 由 supervisor 管理**：`/usr/bin/chromium-browser`，CDP 端口 9222，`profile="openclaw"` 直接可用
- **MOA 由 supervisor 管理**：开机自启，无需手动安装。MOA 登录态与内网访问**无关**——沙箱本身就在内网
- **SSO Cookie 持久化**：Chromium profile 自动保存，约 8 小时有效期

---

## 存档路径 A：Browser SSO（浏览器访问内网）

### A1. 先检测是否已有登录态

```
browser navigate targetUrl="https://km.sankuai.com" profile="openclaw"
browser snapshot profile="openclaw" compact=true
```

- snapshot 显示正常页面 → ✅ 已登录，直接用
- URL 跳转到 `ssosv.sankuai.com` → ❌ Cookie 过期，执行 A2

### A2. SSO 扫码登录（分段式，不阻塞）

#### Step 1：启动登录，获取二维码

```bash
python3 <skill_dir>/scripts/sso_login.py start --output /tmp/sso_qrcode.png
```

输出：
- `QRCODE_SAVED:/tmp/sso_qrcode.png` — 二维码已保存
- `CTX_ID:xxx` — 会话 ID

然后上传二维码到 S3Plus：

```bash
SANDBOX_ID=$(hostname)
python3 <skill_dir>/scripts/upload_s3plus.py \
  --file /tmp/sso_qrcode.png \
  --env prod-corp \
  --object-name ${SANDBOX_ID}/sso_qrcode.png
```

**必须用 `message tool`（action=send）主动推送给用户，不要等 turn 结束：**

```
🔐 需要登录内网系统，请用大象扫描二维码：

⚠️ 扫码并点击「确认」后，我会自动完成，不需要回复我

![SSO登录二维码](<s3plus_url>)
```

#### Step 2：轮询状态（发完二维码后立即开始）

⚠️ **每次单独调用，不要用 shell 循环包裹。每次间隔 4 秒，最多 20 次。**

```bash
sleep 4
python3 <skill_dir>/scripts/sso_login.py status
```

| 输出 | 含义 | 下一步 |
|------|------|--------|
| `SCANNING` | 等待扫码 | sleep 4，再调一次 status |
| `SCAN_SUCCESS` | 已扫码待确认 | sleep 4，再调一次 status |
| `CONFIRMED` | 已确认 | sleep 2，再调一次 status |
| `SKIP_READY` | 出现 Skip 按钮 | 立即执行 Step 3 |
| `REDIRECTED` | 已跳转目标页 | 立即执行 Step 4 |
| `EXPIRED` | 二维码过期 | 通知用户，重新 start |
| `NO_SESSION` | 没有登录会话 | 先调 start |

#### Step 3：点击 Skip

```bash
python3 <skill_dir>/scripts/sso_login.py skip
```

输出 `SKIP_FOUND:Skip` + `USE_BROWSER_TOOL_TO_CLICK` → 用 browser tool 点击：

```
browser snapshot profile="openclaw" → 找到 Skip 按钮的 ref（通常是 e5）
browser act profile="openclaw" request={"kind":"click","ref":"<skip_ref>"}
```

#### Step 4：验证

```bash
python3 <skill_dir>/scripts/sso_login.py verify
```

- `LOGIN_SUCCESS:...` → ✅ 登录完成，继续原任务
- `NOT_YET:...` → sleep 4，再调一次 status

---

## 存档路径 C：extract_cookies.py（给其他 skill 提供 Cookie）

其他 skill 需要内网 Cookie 时调用：

```bash
# Cookie 字符串
python3 <skill_dir>/scripts/extract_cookies.py --domain km.sankuai.com

# JSON 格式 + 验证有效性
python3 <skill_dir>/scripts/extract_cookies.py \
  --domain km.sankuai.com \
  --format json \
  --check-url "https://km.sankuai.com/api/user/info"
```

输出 `AUTH_EXPIRED` → 说明 Cookie 已过期，需要走存档路径 A 重新登录。

---

## 存档：集成接口（供其他 skill 调用浏览器 SSO）

其他 skill 需要内网访问时：

```
1. browser navigate targetUrl="<内网 URL>" profile="openclaw"
2. browser snapshot → 检查是否被拦截
3. URL 含 ssosv.sankuai.com → 触发存档路径 A（SSO 扫码）
4. 页面正常 → 继续原 skill 逻辑
```

---

## 存档：环境初始化（首次使用 / MOA 未安装时）

**正常情况下不需要执行**——沙箱镜像已预装 MOA 并配置好 supervisor。

但如果检测到以下任一情况，需要先跑初始化脚本：

```bash
# 检测是否需要初始化
dpkg -l moa 2>/dev/null | grep -q "^ii" || echo "❌ MOA 未安装"
supervisorctl status moa 2>/dev/null | grep -q "RUNNING" || echo "❌ MOA 未运行"
ss -tlnp | grep -q 9222 || echo "❌ Chromium CDP 未就绪"
```

任何一条输出 ❌，执行：

```bash
bash <skill_dir>/scripts/install_moa.sh
```

脚本会自动完成：
1. 配置 `/etc/hosts`（MOA 所需的域名规则，幂等可重入）
2. 下载并安装 MOA deb 包（已安装则跳过）
3. 更新 supervisor 配置，启动 Chromium 和 MOA

安装完成后重新检测，再走路径 A/B/C。

---

## 环境状态检测

```bash
# 一键检查所有状态
echo "=== Chromium ===" && ps aux | grep chromium-browser | grep -v grep | wc -l
echo "=== CDP 端口 ===" && ss -tlnp | grep 9222
echo "=== MOA 进程 ===" && supervisorctl status moa
echo "=== SSO token 缓存 ===" && cat ~/.config/sso-auth-cli/cache.json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); print('有缓存 token' if d.get('tokens') else '无缓存')" 2>/dev/null || echo "无缓存"
echo "=== mtsso skill ===" && mtskills list 2>/dev/null | grep -i sso || echo "未安装官方 mtsso skill"
```

---

## 反模式（不要做）

- ❌ `browser getCookies` — API 不存在
- ❌ 手动导出/导入 Cookie 到 JSON 文件 — profile 自动持久化
- ❌ 省略 `profile="openclaw"` — 会走 chrome 扩展，不是沙箱浏览器
- ❌ 用 shell for/while 循环包裹 `sso_login.py status` — 必须单次调用
- ❌ 发完二维码后等用户回复再轮询 — 应立即开始轮询

---

## 致谢

- **官方 mtsso skill**（[id: 6556](https://friday.sankuai.com/skills/skill-detail?id=6556)）：推荐的沙箱 SSO 认证方案
- **路径 A 分段式 SSO 登录**（`sso_login.py`）和**路径 C Cookie 提取**（`extract_cookies.py`）来自 [@huyazhou03](friday.sankuai.com/skills/skill-detail?id=5576) 的 [mt-sso-login](https://friday.sankuai.com/skills/skill-detail?id=5576) skill，感谢原作者的优秀设计。
- **路径 B sso-auth-cli** 来自 `@dp/sso-auth-cli` npm 包，感谢开发团队。
