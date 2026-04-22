#!/bin/bash
# OpenClaw Self-Improvement Activation Script
# 一键激活：创建 .learnings 目录、安装 hook、注入 SOUL.md 提醒
# Usage: bash scripts/openclaw-activate.sh [--skill-dir <path>]

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[!]${NC} $1"; }
log_err()  { echo -e "${RED}[✗]${NC} $1" >&2; }

# ── 自动检测 skill 所在目录 ──────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"

# 允许用户显式覆盖
while [[ $# -gt 0 ]]; do
  case $1 in
    --skill-dir) SKILL_DIR="$2"; shift 2 ;;
    *) shift ;;
  esac
done

# ── 确定 workspace 根目录 ───────────────────────────────────────────
if [ -d "$HOME/.openclaw/workspace" ]; then
  WORKSPACE="$HOME/.openclaw/workspace"
elif [ -d "/root/.openclaw/workspace" ]; then
  WORKSPACE="/root/.openclaw/workspace"
else
  log_err "未找到 OpenClaw workspace 目录"
  exit 1
fi

LEARNINGS_DIR="$WORKSPACE/.learnings"
HOOKS_DIR="$HOME/.openclaw/hooks/self-improvement"
SOUL_FILE="$WORKSPACE/SOUL.md"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  Self-Improvement Skill — OpenClaw Activation"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Workspace: $WORKSPACE"
echo "  Skill:     $SKILL_DIR"
echo ""

# ── Step 1: 创建 .learnings/ 目录和模板文件 ─────────────────────────
echo "── Step 1/3: 初始化 .learnings/ 目录 ──"

mkdir -p "$LEARNINGS_DIR"

# LEARNINGS.md
if [ ! -f "$LEARNINGS_DIR/LEARNINGS.md" ]; then
  if [ -f "$SKILL_DIR/assets/LEARNINGS.md" ]; then
    cp "$SKILL_DIR/assets/LEARNINGS.md" "$LEARNINGS_DIR/LEARNINGS.md"
    log_ok "LEARNINGS.md — 从模板创建"
  else
    cat > "$LEARNINGS_DIR/LEARNINGS.md" << 'TMPL'
# Learnings

Corrections, insights, and knowledge gaps captured during development.

**Categories**: correction | insight | knowledge_gap | best_practice
**Statuses**: pending | in_progress | resolved | wont_fix | promoted | promoted_to_skill | promoted_to_memory

---
TMPL
    log_ok "LEARNINGS.md — 使用内置模板创建"
  fi
else
  log_warn "LEARNINGS.md — 已存在，跳过"
fi

# ERRORS.md
if [ ! -f "$LEARNINGS_DIR/ERRORS.md" ]; then
  cat > "$LEARNINGS_DIR/ERRORS.md" << 'TMPL'
# Errors

Command failures, exceptions, and unexpected behaviors captured for analysis.

**Statuses**: pending | in_progress | resolved | wont_fix

---
TMPL
  log_ok "ERRORS.md — 已创建"
else
  log_warn "ERRORS.md — 已存在，跳过"
fi

# FEATURE_REQUESTS.md
if [ ! -f "$LEARNINGS_DIR/FEATURE_REQUESTS.md" ]; then
  cat > "$LEARNINGS_DIR/FEATURE_REQUESTS.md" << 'TMPL'
# Feature Requests

Capabilities requested by users that don't exist yet.

**Statuses**: pending | in_progress | resolved | wont_fix

---
TMPL
  log_ok "FEATURE_REQUESTS.md — 已创建"
else
  log_warn "FEATURE_REQUESTS.md — 已存在，跳过"
fi

echo ""

# ── Step 2: 安装 hook ───────────────────────────────────────────────
echo "── Step 2/3: 安装 self-improvement hook ──"

HOOK_SRC="$SKILL_DIR/hooks/openclaw"
if [ -d "$HOOK_SRC" ]; then
  mkdir -p "$HOOKS_DIR"
  cp -f "$HOOK_SRC/handler.js" "$HOOKS_DIR/" 2>/dev/null || true
  cp -f "$HOOK_SRC/handler.ts" "$HOOKS_DIR/" 2>/dev/null || true
  cp -f "$HOOK_SRC/HOOK.md"    "$HOOKS_DIR/" 2>/dev/null || true
  log_ok "Hook 文件已复制到 $HOOKS_DIR"

  # 尝试 enable（可能因 gateway 不可用而失败，不阻塞）
  if command -v openclaw &>/dev/null; then
    if timeout 10 openclaw hooks enable self-improvement >/dev/null 2>&1; then
      log_ok "Hook 已 enable"
    else
      log_warn "openclaw hooks enable 超时/失败（不影响核心功能，SOUL.md 提醒仍生效）"
    fi
  else
    log_warn "openclaw CLI 不可用，跳过 hook enable"
  fi
else
  log_warn "未找到 hook 源目录 $HOOK_SRC，跳过 hook 安装"
fi

echo ""

# ── Step 3: 注入 SOUL.md 行为提醒 ──────────────────────────────────
echo "── Step 3/3: 注入 SOUL.md 自我改进提醒 ──"

SOUL_MARKER="## 自我改进（Self-Improvement）"

if [ -f "$SOUL_FILE" ]; then
  if grep -qF "$SOUL_MARKER" "$SOUL_FILE"; then
    log_warn "SOUL.md 已包含自我改进段落，跳过"
  else
    # 在文件末尾（最后的 --- 分隔线之前）插入
    cat >> "$SOUL_FILE" << 'SOUL_BLOCK'

## 自我改进（Self-Improvement）

犯错不可怕，重复犯错才可怕。遇到以下情况时，立即记录到 `.learnings/` 目录：

- **命令失败** → `.learnings/ERRORS.md`
- **用户纠正我**（"不对"、"其实是…"）→ `.learnings/LEARNINGS.md`，标记 `correction`
- **发现知识过时** → `.learnings/LEARNINGS.md`，标记 `knowledge_gap`
- **找到更好做法** → `.learnings/LEARNINGS.md`，标记 `best_practice`
- **用户要的功能不存在** → `.learnings/FEATURE_REQUESTS.md`

反复出现的 learning 要提升（promote）到 SOUL.md / TOOLS.md / AGENTS.md，变成永久规则。
SOUL_BLOCK
    log_ok "SOUL.md — 已追加自我改进段落"
  fi
else
  log_warn "SOUL.md 不存在（$SOUL_FILE），跳过注入"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  ✅ 激活完成！"
echo ""
echo "  已创建:"
echo "    $LEARNINGS_DIR/LEARNINGS.md"
echo "    $LEARNINGS_DIR/ERRORS.md"
echo "    $LEARNINGS_DIR/FEATURE_REQUESTS.md"
echo ""
echo "  下次会话起，Agent 将自动记录错误和学习经验。"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
