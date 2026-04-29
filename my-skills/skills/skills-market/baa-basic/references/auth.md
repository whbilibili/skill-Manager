# 鉴权说明

## 鉴权方式选择（优先级：MOA > CIBA）

触发重新登录前，**主 agent 必须先判断 MOA 是否可用**，决策流程如下：

```
触发重新登录
     │
     ▼
inject-ba-cookie-moa.sh
（内部自动：检查包 → 安装 → 探测 → 换票）
     │ 退出码 0（MOA 鉴权成功）
     ▼
继续执行
     │ 退出码 1（安装失败 / MOA 未启动未登录 / 换票失败）
     ▼
降级：inject-ba-cookie-supabase-ciba.sh <misId>
```

`inject-ba-cookie-moa.sh` **内部自动完成**以下步骤：
1. 检查 `scripts/node_modules/.bin/mtsso-moa-feature-probe` 是否存在
2. 不存在则执行：`npm install @mtfe/mtsso-auth-official@latest --registry http://r.npm.sankuai.com --prefix <skills/ba-analysis/scripts/>`
3. 安装失败 → 退出码 1
4. 执行 `mtsso-moa-feature-probe -t 3` 探测 MOA 可用性
5. 探测失败（退出码非 0）→ 退出码 1
6. 执行 `mtsso-moa-local-exchange --audience 07b8be90c9` 换票
7. 换票失败 → 退出码 1
8. 成功 → token 写入 `~/.cache/ba-analysis/access_token.txt`，退出码 0

| 情况 | 使用脚本 | 是否需要 misId |
|------|---------|----------------|
| MOA 可用且换票成功 | `inject-ba-cookie-moa.sh` | ❌ 不需要 |
| 安装失败 / MOA 不可用 / 换票失败 | `inject-ba-cookie-supabase-ciba.sh` | ✅ 需要 |

> 两个脚本最终都将 access_token 写入 `~/.cache/ba-analysis/access_token.txt`，互不干扰。

---

## 登录状态校验（每次分析任务前必做）

每次用户发起分析类请求（analyze / plan / confirm_plan）前，**主 agent 必须先执行 `user_info` 子命令校验登录状态**：

```bash
MIS=$(python3 -c "
import os, json
mis = os.environ.get('MIS_ID') or os.environ.get('MIS_ID_HINT')
if not mis:
    for f in ['/root/.openclaw/config/sandbox.json', os.path.expanduser('~/.openclaw/config/sandbox.json')]:
        try:
            d = json.load(open(f)); mis = d.get('misId') or d.get('mis_id') or d.get('loginHint'); break
        except: pass
if not mis:
    try: mis = open(os.path.expanduser('~/.cache/ba-analysis/mis_id.txt')).read().strip()
    except: pass
print(mis or '')
" 2>/dev/null)

if [ -n "$MIS" ]; then
  python3 {cwd}/scripts/call_ba_agent.py user_info --expected-mis "$MIS"
else
  python3 {cwd}/scripts/call_ba_agent.py user_info
fi
```

**退出码处理：**

| 退出码 | 含义 | 主 agent 行为 |
|--------|------|---------------|
| `0` | 已登录且用户匹配 | 正常继续后续步骤 |
| `2` | 未登录 / token 无效 | 停止分析，**主动执行登录脚本**（见下方），不要要求用户手动执行 |
| `3` | 登录用户与当前用户不符（已自动清除 token） | 停止分析，**主动执行登录脚本**（见下方） |

---

## 重新登录

退出码非 0 时，执行以下完整登录逻辑：

### 步骤 A：尝试 MOA 本地鉴权

```bash
bash {cwd}/scripts/inject-ba-cookie-moa.sh
```

`inject-ba-cookie-moa.sh` 内部流程（无需外部干预，全自动）：
1. 检查 `{cwd}/scripts/node_modules/.bin/mtsso-moa-feature-probe` 是否存在
2. 不存在则自动执行：
   `npm install @mtfe/mtsso-auth-official@latest --registry http://r.npm.sankuai.com --prefix {cwd}/scripts/`
3. 安装失败 → 退出码 `1`（调用方降级 CIBA）
4. 安装成功后，执行 `{cwd}/scripts/node_modules/.bin/mtsso-moa-feature-probe -t 3` 探测 MOA 可用性
5. 探测失败（退出码非 0）→ 退出码 `1`
6. 探测通过后，执行 `{cwd}/scripts/node_modules/.bin/mtsso-moa-local-exchange --audience 07b8be90c9` 换票
7. 成功则保存 token 至 `~/.cache/ba-analysis/access_token.txt`，退出码 `0`
8. 任一步骤失败则退出码 `1`

**`inject-ba-cookie-moa.sh` 退出码：**

| 退出码 | 含义 |
|--------|------|
| `0` | MOA 鉴权成功，继续后续分析 |
| `1` | 失败（安装失败 / MOA 未登录 / 换票失败），降级 CIBA |

### 步骤 B：降级 CIBA 鉴权（MOA 失败时）

```bash
bash {cwd}/scripts/inject-ba-cookie-supabase-ciba.sh <misId>
```

misId 获取优先级：
1. 环境变量 `MIS_ID` / `MIS_ID_HINT`
2. `/root/.openclaw/config/sandbox.json` 中的 `misId`/`mis_id`/`loginHint`
3. `~/.cache/ba-analysis/mis_id.txt`（MOA 成功登录后会自动写入）
4. 以上都无 → 询问用户

**CIBA 流程（`inject-ba-cookie-supabase-ciba.sh` 内部逻辑）：**
1. `POST /api/sandbox/sso/ciba-auth` → 触发大象 App 推送授权通知
2. 每 5s 轮询 `POST /api/sandbox/sso/ciba-token`，最多 3 分钟
3. `POST /api/sandbox/sso/exchange-token-by-client-ids` 换票（audience: `07b8be90c9`）
4. token 保存至 `~/.cache/ba-analysis/access_token.txt`

> ⚠️ BA-Agent 的 `client_id` 当前为 `07b8be90c9`。若换票失败，提示用户联系 BA-Agent 系统管理员确认正确的 clientId。

**连续登录失败 2 次后，停止重试，告知用户并提示联系 BA-Agent 系统管理员。**

---

## ⚠️ 子 agent 内禁止重鉴权

**子 agent（BA-Agent 执行专员）遇到 401/403 或 token 过期时，必须直接以非 0 退出码终止并报错返回，不得自行触发登录流程。**

鉴权职责归属：
- **主 agent**：负责 spawn 子 agent 前的鉴权保障；负责子 agent 报鉴权失败后的补救登录
- **子 agent**：只负责执行分析命令，遇到鉴权问题立即报错，由主 agent 处理

子 agent task 中应包含 `--no-reauth` 参数（调用脚本时禁用自动重鉴权），并明确告知：「不重鉴权，失败时将错误原文回复」。

---

## 异常处理

| 情况 | 处理方式 |
|------|---------|
| MOA 安装失败 | 降级 CIBA |
| MOA 探测不可用（未启动/未登录） | 降级 CIBA |
| MOA 换票失败 | 降级 CIBA |
| CIBA 退出码 2（401/403） | **主 agent** 主动执行登录脚本，登录后重新 spawn 子 agent |
| 退出码 1（其他错误） | 展示错误信息给用户 |
| 换票失败（clientId 问题） | 提示联系管理员确认 `07b8be90c9` 是否正确 |
| 分析超时 | 告知用户后台仍在运行，可通过 `history` 查询结果 |
