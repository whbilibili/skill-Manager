# CHANGELOG

## v2.3.0 (2026-04-07)

### Changed
- **Auth: MOA 无感登录优先**（参考《业务 Skill 接入 SSO 身份体系》开发者指南）
  - 默认认证改为 `npx mtsso-moa-local-exchange`（@mtfe/mtsso-auth-official）
  - MOA 不可用时自动降级为 CIBA 手动确认，保持向后兼容
  - 认证前通过 `npx mtsso-moa-feature-probe` 探测 MOA 支持情况
- **SKILL.md 新增 `skill-dependencies`**，声明 `mtsso-skills-official` 依赖及 audience

### Added
- `download` 命令支持 `--extract` / `-x` 参数：自动解压下载的 Skill zip 包

### Fixed
- CIBA 等待进度输出改为 `process.stderr.write`（避免污染 stdout JSON 输出）

## v2.2.0 (2026-03-31)

### Breaking
- **Removed bundled `node_modules/`** — zero external dependencies now

### Changed
- Replaced `jsonwebtoken` with hand-rolled HS256 JWT (Node.js `crypto` built-in)
- Replaced `axios` with built-in `fetch` (Node.js 18+)
- `zipDir` now respects `.skillignore` for custom exclusion patterns
- Default exclusions always applied: `tests/*`, `evals/*`, `pending/*`, `node_modules/*`, `__pycache__/*`, `*.bak`, `.git/*`
- Directory patterns in `.skillignore` (e.g. `scratch/`) auto-normalized to `scratch/*`
- Zip size: 900K → ~30K

### Added
- `tests/test_friday_skill.sh`: 28 unit tests (JWT, parseArgs, parseSkillMd, zipDir)

## v2.1.0 (2026-03-24)

### 新增
- `install --id <id>`：从 Friday 广场下载 skill、解压到 `~/.openclaw/skills/`，并自动写入 skill-lock.json（source=friday, installedAt, policy=auto）
- `status [--all]`：查看本地已安装 skill 状态，无需认证，直接读 skill-lock.json；`--all` 展示完整表格含 local skill

### 改进
- skill-lock.json 兼容：install 写入标准化字段（source/id/name/updateTime/installedAt/installPath/updatePolicy），与 skill-updater 完全兼容

## v2.0.0 (2026-03-15)

### 重写
- 底层认证从 App Auth 迁移到 SSO CIBA（用户身份正确传递，防凭据泄漏）
  - 新增 `--browser` 模式：通过 Chrome DevTools Protocol 读取浏览器 Cookie 进行 SSO 认证
  - 保留 `--app-auth` 作为自动化场景（无用户身份）
- Token 缓存：首次认证后缓存到 `~/.openclaw/credentials/friday-ciba-token.json`
- 网络重试：3 次 + 指数退避
- 用户身份验证：防止 token 所属用户冒用

### 新增命令
- `download --id <id> [--out skill.zip]`：下载 skill zip 到本地路径，适合离线分发，不自动解压、不写 lock

## v1.0.0 (2026-03-07)

- 初始版本：App Auth 认证，基础 CRUD 命令
