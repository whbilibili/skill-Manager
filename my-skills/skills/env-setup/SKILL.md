---
name: env-setup
description: "Install Node.js, Python, and PowerShell development environments on macOS and Windows. Zero sudo, zero admin — uses nvm for Node.js, uv for Python, both user-scope. Use when the user asks to install/setup development tools, e.g. '安装 node/python/powershell'、'install node/python/pwsh'、'PowerShell 7'、'配置环境/开发环境'、'setup/dev environment'、'环境安装/配置'、'配置 npm 源/pip 源'、'install/安装 nvm/uv', or when a command fails with 'node/python/npm/pnpm/pwsh: command not found'."
---

# Environment Setup — Install Node.js, Python & PowerShell

**Flow**: detect → skip or install → verify → prompt restart → ask about registries. Strictly linear, never jump backwards.

**IMPORTANT: Execute each step as a separate command** — do NOT chain download + install + verify into one block. Split into individual tool calls (e.g. download → install → verify) so the user sees progress at each stage instead of waiting with no feedback.

## Key Constraints

- Agent shell is **fresh non-interactive** — does NOT source `~/.zshrc` / `~/.bashrc`.
- **Detect by file path**, not `node -v` / `python3 --version` (PATH is incomplete).
- After install, user must **restart CatPaw Desk** for PATH to take effect.
- If existing nvm/fnm/volta/pyenv/conda found, use that instead of reinstalling.
- nvm and uv are **zero-privilege** (no sudo/admin). They don't affect system installs.
- On failure: try fallback **once**, then **stop and report**. Never retry in a loop.

## China Mirrors

| Target | Mirror URL | Env/Config |
|--------|-----------|------------|
| nvm script (macOS) | `https://gitee.com/mirrors/nvm/raw/v0.40.3/install.sh` | fallback to GitHub |
| Node.js binary | `https://npmmirror.com/mirrors/node/` | `NVM_NODEJS_ORG_MIRROR` / `node_mirror` in settings.txt |
| Python binary | `https://registry.npmmirror.com/-/binary/python-build-standalone/` | `UV_PYTHON_INSTALL_MIRROR` |
| pip packages | `https://pypi.tuna.tsinghua.edu.cn/simple` | `pip config set global.index-url` |
| PowerShell MSI/ZIP | `https://mirrors.tuna.tsinghua.edu.cn/github-release/PowerShell/PowerShell/v{VER}%20Release%20of%20PowerShell/` | direct download, fallback to GitHub |

## Step 1: Detect Installed Tools (MANDATORY)

### macOS / Linux

```bash
echo "=== Node.js Detection ==="
NVM_NODE_DIR="$HOME/.nvm/versions/node"
NODE_FOUND=""
if [ -d "$NVM_NODE_DIR" ]; then
  NVM_LATEST=$(ls -d "$NVM_NODE_DIR"/v* 2>/dev/null | sort -t. -k1,1 -k2,2n -k3,3n | tail -1)
  [ -n "$NVM_LATEST" ] && [ -x "$NVM_LATEST/bin/node" ] && NODE_FOUND="$NVM_LATEST/bin/node" && echo "Found (nvm): $NODE_FOUND → $($NODE_FOUND --version)"
fi
[ -z "$NODE_FOUND" ] && [ -x "$HOME/.volta/bin/node" ] && NODE_FOUND="$HOME/.volta/bin/node" && echo "Found (volta): $NODE_FOUND → $($NODE_FOUND --version)"
[ -z "$NODE_FOUND" ] && [ -x "$HOME/.local/share/fnm/aliases/default/bin/node" ] && NODE_FOUND="$HOME/.local/share/fnm/aliases/default/bin/node" && echo "Found (fnm): $NODE_FOUND → $($NODE_FOUND --version)"
for p in /opt/homebrew/bin/node /usr/local/bin/node; do
  [ -z "$NODE_FOUND" ] && [ -x "$p" ] && NODE_FOUND="$p" && echo "Found (system): $NODE_FOUND → $($NODE_FOUND --version)"
done
[ -z "$NODE_FOUND" ] && echo "Node.js: NOT FOUND"

PNPM_FOUND=""
[ -n "$NODE_FOUND" ] && [ -x "$(dirname "$NODE_FOUND")/pnpm" ] && PNPM_FOUND="$(dirname "$NODE_FOUND")/pnpm"
[ -z "$PNPM_FOUND" ] && [ -x "$HOME/.local/bin/pnpm" ] && PNPM_FOUND="$HOME/.local/bin/pnpm"
[ -n "$PNPM_FOUND" ] && echo "pnpm: $($PNPM_FOUND --version 2>/dev/null)" || echo "pnpm: NOT FOUND"

echo ""
echo "=== Python Detection ==="
PYTHON_FOUND=""
UV_BIN="$HOME/.local/bin/uv"
if [ -x "$UV_BIN" ]; then
  echo "uv: $($UV_BIN --version 2>/dev/null)"
  UV_PYTHON=$($UV_BIN python find 2>/dev/null)
  [ -n "$UV_PYTHON" ] && [ -x "$UV_PYTHON" ] && PYTHON_FOUND="$UV_PYTHON" && echo "Found (uv): $PYTHON_FOUND → $($PYTHON_FOUND --version)"
fi
if [ -z "$PYTHON_FOUND" ]; then
  for p in /opt/homebrew/bin/python3 /usr/local/bin/python3 /usr/bin/python3; do
    [ -x "$p" ] && PYTHON_FOUND="$p" && echo "Found (system): $PYTHON_FOUND → $($PYTHON_FOUND --version)" && break
  done
fi
[ -z "$PYTHON_FOUND" ] && echo "Python: NOT FOUND"
```

### Windows (PowerShell)

```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
Write-Host "=== Node.js ===" ; node -v 2>$null ; if (!$?) { Write-Host "NOT FOUND" }
Write-Host "=== pnpm ===" ; pnpm -v 2>$null ; if (!$?) { Write-Host "NOT FOUND" }
Write-Host "=== Python ===" ; python --version 2>$null ; if (!$?) { Write-Host "NOT FOUND" }
Write-Host "=== uv ===" ; uv --version 2>$null ; if (!$?) { Write-Host "NOT FOUND" }
```

### Decision

- Node.js found **≥ 18** → skip. Python found **≥ 3.8** → skip. pnpm found → skip.
- `uv python find` is the primary Python detection (uv doesn't create a `python3` symlink).
- Only install what is missing or too old.

## Step 2: Install Node.js via nvm

### macOS / Linux

**Step A — Install nvm** (run as one command):

```bash
export NVM_DIR="$HOME/.nvm"
if [ ! -s "$NVM_DIR/nvm.sh" ]; then
  curl -o- https://gitee.com/mirrors/nvm/raw/v0.40.3/install.sh | bash \
    || curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
fi
```

**Step B — Install Node.js LTS** (separate command so user sees download progress):

```bash
export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh"
export NVM_NODEJS_ORG_MIRROR=https://npmmirror.com/mirrors/node/
nvm install --lts
nvm alias default node
```

**Step C — Install pnpm** (separate command):

```bash
export NVM_DIR="$HOME/.nvm" && . "$NVM_DIR/nvm.sh"
command -v pnpm >/dev/null 2>&1 || npm install -g pnpm
```

**Verify** (check binary on disk, not `node -v`):

```bash
NVM_LATEST=$(ls -d "$HOME/.nvm/versions/node"/v* 2>/dev/null | sort -t. -k1,1 -k2,2n -k3,3n | tail -1)
if [ -n "$NVM_LATEST" ] && [ -x "$NVM_LATEST/bin/node" ]; then
  echo "✅ Node.js: $($NVM_LATEST/bin/node --version) at $NVM_LATEST/bin/node"
else
  echo "❌ Node.js install FAILED"; exit 1
fi
```

**Use in subsequent commands** — prepend PATH each time:

```bash
NVM_LATEST=$(ls -d "$HOME/.nvm/versions/node"/v* 2>/dev/null | sort -t. -k1,1 -k2,2n -k3,3n | tail -1)
export PATH="$NVM_LATEST/bin:$PATH"
```

### Windows (PowerShell)

**Step A — Download & extract nvm-windows** (run as one command):

```powershell
$nvmDir = "$env:APPDATA\nvm"
$nvmSymlink = "$env:APPDATA\nvm\nodejs"
if (!(Test-Path "$nvmDir\nvm.exe")) {
    $nvmZip = "$env:TEMP\nvm-noinstall.zip"
    Write-Host "Downloading nvm-windows..."
    Invoke-WebRequest -Uri "https://github.com/coreybutler/nvm-windows/releases/download/1.2.2/nvm-noinstall.zip" -OutFile $nvmZip
    Write-Host "Extracting..."
    New-Item -ItemType Directory -Force -Path $nvmDir | Out-Null
    Expand-Archive -Path $nvmZip -DestinationPath $nvmDir -Force
    Remove-Item $nvmZip
    Write-Host "nvm-windows installed to $nvmDir"
} else { Write-Host "nvm-windows already installed" }
@("root: $nvmDir", "path: $nvmSymlink", "node_mirror: https://npmmirror.com/mirrors/node/") | Set-Content "$nvmDir\settings.txt"
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$newPaths = @($nvmSymlink, $nvmDir) | Where-Object { $userPath -notlike "*$_*" }
if ($newPaths) { [Environment]::SetEnvironmentVariable("Path", ($newPaths -join ";") + ";$userPath", "User") }
```

**Step B — Install Node.js LTS** (separate command — downloads Node binary, may take a while):

```powershell
$nvmDir = "$env:APPDATA\nvm"
$nvmSymlink = "$env:APPDATA\nvm\nodejs"
$env:Path = "$nvmSymlink;$nvmDir;$env:Path"
nvm install lts
nvm use lts
```

**Step C — Install pnpm** (separate command):

```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
if (!(Get-Command pnpm -ErrorAction SilentlyContinue)) { npm install -g pnpm }
```

**Use in subsequent commands**: `$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")`

## Step 3: Install Python via uv

### macOS / Linux

**Step A — Install uv** (run as one command):

```bash
export PATH="$HOME/.local/bin:$PATH"
if ! command -v uv >/dev/null 2>&1; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  export PATH="$HOME/.local/bin:$PATH"
fi
uv --version
```

**Step B — Install Python via uv** (separate command — downloads Python binary):

```bash
export PATH="$HOME/.local/bin:$PATH"
export UV_PYTHON_INSTALL_MIRROR="https://registry.npmmirror.com/-/binary/python-build-standalone/"
uv python install
```

**Step C — Configure pip mirror** (separate command):

```bash
export PATH="$HOME/.local/bin:$PATH"
uv run pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
uv run pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn
```

**Verify** (use `uv python find`, not `python3 --version`):

```bash
export PATH="$HOME/.local/bin:$PATH"
UV_PYTHON=$(uv python find 2>/dev/null)
[ -n "$UV_PYTHON" ] && [ -x "$UV_PYTHON" ] && echo "✅ Python: $($UV_PYTHON --version)" || echo "❌ Python install FAILED"
```

**Use in subsequent commands**: `export PATH="$HOME/.local/bin:$PATH"` then `uv run python` or `$(uv python find)`.

**Last resort** (if uv + npmmirror both fail): direct installer from `https://www.python.org/downloads/` — macOS `.pkg` (requires sudo), Windows `.exe` (run with `/quiet InstallAllUsers=0 PrependPath=1`).

### Windows (PowerShell)

**Step A — Install uv** (run as one command):

```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
if (!(Get-Command uv -ErrorAction SilentlyContinue)) {
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    $env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
}
uv --version
```

**Step B — Install Python via uv** (separate command — downloads Python binary):

```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
$env:UV_PYTHON_INSTALL_MIRROR = "https://registry.npmmirror.com/-/binary/python-build-standalone/"
uv python install
```

**Step C — Configure pip mirror & fix PATH** (separate command):

```powershell
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
uv run pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
uv run pip config set global.trusted-host pypi.tuna.tsinghua.edu.cn
# uv doesn't add Python to PATH on Windows — fix it
$uvPython = uv python find 2>$null
if ($uvPython) {
    $pyDir = Split-Path $uvPython
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($userPath -notlike "*$pyDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$pyDir;$userPath", "User")
    }
    $env:Path = "$pyDir;$env:Path"
}
```

**Verify (Windows)**: `$env:Path = ...(refresh)...` then `uv run python --version` and `python --version`.

**Use in subsequent commands (Windows)**: refresh PATH then `python` or `uv run python`.

## Step 4: Post-install — Prompt Restart

After **any** successful install (Node.js, Python, and/or PowerShell), always tell the user:

> ✅ 安装完成！请**重启 CatPaw Desk**（完全退出后重新打开）让环境变量生效。
> - macOS/Linux 独立终端：运行 `source ~/.zshrc` 或新开窗口
> - Windows 独立终端：新开一个 PowerShell 窗口

## Step 5: Meituan Internal Registry (OPTIONAL)

Tsinghua pip mirror is already configured. Ask the user: "是否需要配置美团内部 npm/pip 源？" Only if user confirms:

```bash
# macOS / Linux
NVM_LATEST=$(ls -d "$HOME/.nvm/versions/node"/v* 2>/dev/null | sort -t. -k1,1 -k2,2n -k3,3n | tail -1)
export PATH="$NVM_LATEST/bin:$HOME/.local/bin:$PATH"
npm config set registry http://r.npm.sankuai.com
pnpm config set registry http://r.npm.sankuai.com
uv run pip config set global.index-url http://pypi.sankuai.com/simple/
uv run pip config set global.trusted-host pypi.sankuai.com
```

```powershell
# Windows
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
npm config set registry http://r.npm.sankuai.com
pnpm config set registry http://r.npm.sankuai.com
uv run pip config set global.index-url http://pypi.sankuai.com/simple/
uv run pip config set global.trusted-host pypi.sankuai.com
```

## Step 6: Install PowerShell 7 (Windows only)

PowerShell 7 (`pwsh.exe`) coexists with built-in 5.1 (`powershell.exe`). Never remove 5.1.

> **Why MSI only (no winget)**: winget without admin privileges installs PS7 as an MSIX package
> into `C:\Program Files\WindowsApps\Microsoft.PowerShell_*\`. While `pwsh.exe` works from PATH,
> CatPaw CLI's `ShellUtils.ts` only checks the MSI path (`C:\Program Files\PowerShell\7\pwsh.exe`)
> via `fs.existsSync`. MSIX installs cause CLI to silently fall back to PowerShell 5.1.
> MSI install guarantees the correct path and full compatibility with CLI + all tool chains.
>
> MSI requires admin privileges — the install step uses `-Verb RunAs` which pops a one-time UAC
> dialog for the user to click "Yes". This is unavoidable for writing to `C:\Program Files\`.

### Detect

```powershell
$ProgressPreference = 'SilentlyContinue'
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
$pwshMsiPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
if (Test-Path $pwshMsiPath) {
    $ver = & $pwshMsiPath -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
    Write-Host "PowerShell 7: $ver (MSI install at $pwshMsiPath)"
} elseif ($pwshCmd -and $pwshCmd.Source -like '*WindowsApps*') {
    Write-Host "PowerShell 7: MSIX_ONLY (installed at $($pwshCmd.Source) — CLI cannot detect this, needs MSI install)"
} elseif ($pwshCmd) {
    $ver = pwsh -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
    Write-Host "PowerShell 7: $ver at $($pwshCmd.Source)"
} else {
    Write-Host "PowerShell 7: NOT FOUND"
}
```

### Decision

- `pwsh.exe` exists at MSI path (`C:\Program Files\PowerShell\7\`) and ≥ 7.2 → **skip**.
- `pwsh` found but path is under `WindowsApps` (MSIX) → **must install MSI version** for CLI compatibility. Uninstall MSIX first, then proceed to MSI install.
- `pwsh` not found at all → proceed to install.

### Install (MSI direct — UAC required)

**Step A — Uninstall existing MSIX if present** (run as one command — only needed if Detect showed `MSIX_ONLY`):

> Skip this step if Detect showed `NOT FOUND` or already has MSI install.

```powershell
$ProgressPreference = 'SilentlyContinue'
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $wingetList = winget list Microsoft.PowerShell --disable-interactivity 2>$null | Out-String
    if ($wingetList -match 'Microsoft\.PowerShell') {
        Write-Host "正在卸载 MSIX 版 PowerShell 7..."
        winget uninstall Microsoft.PowerShell --silent --disable-interactivity 2>$null
        Start-Sleep -Seconds 2
        Write-Host "MSIX 版已卸载"
    } else {
        Write-Host "未检测到 winget 注册的 PowerShell 7，跳过卸载"
    }
} else {
    Write-Host "winget 不可用，跳过 MSIX 卸载检查"
}
```

**Step B — Download MSI** (run as one command):

```powershell
$ProgressPreference = 'SilentlyContinue'
$psVersion = "7.6.0"
$arch = if ([Environment]::Is64BitOperatingSystem) { "x64" } else { "arm64" }
$msiName = "PowerShell-$psVersion-win-$arch.msi"
$msiPath = "$env:TEMP\$msiName"
$mirrorUrl = "https://mirrors.tuna.tsinghua.edu.cn/github-release/PowerShell/PowerShell/v$psVersion%20Release%20of%20PowerShell/$msiName"
$githubUrl = "https://github.com/PowerShell/PowerShell/releases/download/v$psVersion/$msiName"
Write-Host "正在从清华镜像下载 $msiName ..."
try {
    Invoke-WebRequest -Uri $mirrorUrl -OutFile $msiPath -UseBasicParsing
    Write-Host "清华镜像下载成功"
} catch {
    Write-Host "清华镜像失败，尝试 GitHub..."
    try { Invoke-WebRequest -Uri $githubUrl -OutFile $msiPath -UseBasicParsing; Write-Host "GitHub 下载成功" } catch { Write-Host "❌ 所有下载均失败"; $msiPath = $null }
}
if ($msiPath -and (Test-Path $msiPath)) { Write-Host "MSI 已保存到 $msiPath ($('{0:N1} MB' -f ((Get-Item $msiPath).Length/1MB)))" }
```

**Step C — Install MSI** (separate command — will show one UAC prompt for admin privileges):

> **IMPORTANT**: MSI installs to `C:\Program Files\PowerShell\7\` which requires admin privileges.
> `-Verb RunAs` pops a UAC dialog — user clicks "Yes" once, then installation is fully silent.
> Do NOT use `-NoNewWindow` with `-Verb RunAs` (they are incompatible).
> After `Start-Process`, verify by checking the installed binary on disk — `$LASTEXITCODE` is unreliable for `Start-Process`.

```powershell
$ProgressPreference = 'SilentlyContinue'
$msiPath = "$env:TEMP\PowerShell-7.6.0-win-$(if ([Environment]::Is64BitOperatingSystem) {'x64'} else {'arm64'}).msi"
$pwshExpected = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
if ($msiPath -and (Test-Path $msiPath)) {
    Write-Host "正在安装 PowerShell 7（将弹出 UAC 权限确认窗口，请点击'是'）..."
    $proc = Start-Process msiexec.exe -ArgumentList "/i", "`"$msiPath`"", "/quiet", "/norestart", "ADD_EXPLORER_CONTEXT_MENU_OPENPOWERSHELL=1", "REGISTER_MANIFEST=1", "USE_MU=1", "ENABLE_MU=1", "ADD_PATH=1" -Wait -Verb RunAs -PassThru
    Remove-Item $msiPath -Force -ErrorAction SilentlyContinue
    if (Test-Path $pwshExpected) {
        Write-Host "✅ MSI 安装成功 — $pwshExpected"
    } else {
        Write-Host "❌ MSI 安装失败 (exit code: $($proc.ExitCode)) — $pwshExpected 不存在"
    }
} else {
    Write-Host "❌ MSI 文件不存在，安装失败"
}
```

### Verify

> Check the MSI install path directly — this is the path that CLI's `ShellUtils.ts` checks.

```powershell
$ProgressPreference = 'SilentlyContinue'
$env:Path = [Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [Environment]::GetEnvironmentVariable("Path","User")
$pwshMsiPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
if (Test-Path $pwshMsiPath) {
    $ver = & $pwshMsiPath -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>$null
    Write-Host "✅ PowerShell 7: $ver at $pwshMsiPath"
} elseif (Get-Command pwsh -ErrorAction SilentlyContinue) {
    $src = (Get-Command pwsh).Source
    Write-Host "⚠️ PowerShell 7 found at $src but NOT at MSI path — CLI may not detect it"
} else {
    Write-Host "❌ PowerShell 7 install FAILED — pwsh.exe not found"
}
```

After PowerShell install succeeds, **also prompt restart** (same as Step 4).

### Uninstall (if requested)

```powershell
$ProgressPreference = 'SilentlyContinue'
$pwshMsiPath = "$env:ProgramFiles\PowerShell\7\pwsh.exe"
if (Test-Path $pwshMsiPath) {
    Write-Host "正在卸载 MSI 版 PowerShell 7..."
    Start-Process msiexec.exe -ArgumentList "/x", "{DD740601-FA57-4ACC-9293-8C7B928E7F64}", "/quiet", "/norestart" -Wait -Verb RunAs -PassThru
    if (!(Test-Path $pwshMsiPath)) { Write-Host "✅ 卸载成功" } else { Write-Host "❌ 卸载失败" }
} elseif (Get-Command winget -ErrorAction SilentlyContinue) {
    winget uninstall Microsoft.PowerShell --silent --disable-interactivity
} else {
    Write-Host "未找到已安装的 PowerShell 7"
}
```

## Error Handling

On failure: try fallback **once** → stop and report. Never loop or jump backwards.

| Failure | Action |
|---------|--------|
| Download fails (nvm/uv/PowerShell) | Try fallback mirror once. If all fail, stop. |
| Install command fails | Report error, suggest manual install. |
| Verify fails (binary not on disk) | Report "FAILED" with path checked. Do NOT re-detect. |
| UAC denied / cancelled (Windows) | User clicked "No" on the UAC prompt. Cannot install to `Program Files` without admin. Report and suggest the user re-run or right-click CatPaw Desk → "Run as administrator". |
| `CreateFile() Error: 5` (Windows) | `ERROR_ACCESS_DENIED` — harmless if from `WindowsApps` ACL. If MSI install failed, it means UAC was denied. |
| MSIX installed but CLI uses PS5.1 | winget without admin installs MSIX (into `WindowsApps`). CLI only checks MSI path. Uninstall MSIX, then install MSI version (Step A → B → C). |
