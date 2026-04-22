#!/usr/bin/env bash
# 安装 Node.js（通过 nvm / nvm-windows），适用于 Linux / macOS / Windows(GitBash/WSL)
set -euo pipefail

NVM_VERSION="v0.40.4"

already_has() { command -v "$1" &>/dev/null; }

if already_has node && already_has npm; then
  echo "✅ node $(node -v) / npm $(npm -v) 已安装，跳过"
  exit 0
fi

OS="$(uname -s)"
case "$OS" in
  Linux*|Darwin*)
    echo ">>> 安装 nvm ${NVM_VERSION} ..."
    export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh" | bash
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo ">>> Windows 环境，通过 winget 安装 nvm-windows ..."
    if already_has winget; then
      winget install -e --id CoreyButler.NVMforWindows --accept-package-agreements --accept-source-agreements
    else
      echo "❌ 未找到 winget，请手动下载：https://github.com/coreybutler/nvm-windows/releases"
      exit 1
    fi
    ;;
  *)
    echo "❌ 不支持的系统：$OS"
    exit 1
    ;;
esac

echo ">>> 安装 Node.js LTS ..."
nvm install --lts
nvm use --lts

echo "✅ 安装完成：node $(node -v) / npm $(npm -v)"
