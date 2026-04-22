#!/usr/bin/env bash
# Step 0：环境自检 + 团队配置加载
# 由 SKILL.md Step 0 引用执行，请勿直接修改主 SKILL.md 中的 Step 0 逻辑

# ── 版本提醒（每次触发必须输出）──────────────────────────────────────
echo "💡 提示：AI CR Skill 持续迭代中，效果越来越好！请确保已更新到最新版："
echo "   mtskills i ai-pr-code-review"
echo ""

# ── 0A. 团队配置加载 ──────────────────────────────────────────────────
CR_CONFIG=$(find ~/.openclaw/workspace -name ".cr-config.yaml" 2>/dev/null | head -1)
[ -z "$CR_CONFIG" ] && CR_CONFIG=$(find . -name ".cr-config.yaml" -maxdepth 2 2>/dev/null | head -1)

if [ -n "$CR_CONFIG" ]; then
  echo "✅ 发现团队配置文件：$CR_CONFIG"
  CR_TABLE_ID=$(python3 -c "
import re, sys
with open('$CR_CONFIG') as f: content = f.read()
m = re.search(r'table_id:\s*(\S+)', content)
print(m.group(1) if m else '')
")
  CR_CITADEL_PARENT=$(python3 -c "
import re, sys
with open('$CR_CONFIG') as f: content = f.read()
m = re.search(r'citadel_parent_id:\s*(\S+)', content)
print(m.group(1) if m else '')
")
  CR_DOMAIN_KNOWLEDGE=$(python3 -c "
import re, sys
with open('$CR_CONFIG') as f: content = f.read()
m = re.search(r'domain_knowledge:\s*(\S+)', content)
print(m.group(1) if m else '')
")
  CR_NOTIFY_MIS=$(python3 -c "
import re, sys
with open('$CR_CONFIG') as f: content = f.read()
m = re.search(r'notify_mis:\s*\[([^\]]+)\]', content)
print(m.group(1).replace(' ','') if m else '')
")
  echo "   table_id: ${CR_TABLE_ID:-（未配置，使用内置默认值）}"
  echo "   citadel_parent_id: ${CR_CITADEL_PARENT:-（未配置，使用内置默认值）}"
  echo "   domain_knowledge: ${CR_DOMAIN_KNOWLEDGE:-（未配置，使用 references/domain-knowledge.md）}"
  echo "   notify_mis: ${CR_NOTIFY_MIS:-（未配置）}"
else
  echo "ℹ️  未发现 .cr-config.yaml，使用内置默认配置（适用于供商方向）"
  echo "   如需接入其他团队，请参考文档末尾的「团队接入指南」创建配置文件"
fi

# 设置最终生效值（配置文件优先，否则用内置默认值）
export TABLE_ID="${CR_TABLE_ID:-2751197605}"
export CITADEL_PARENT_ID="${CR_CITADEL_PARENT:-2749896619}"
export DOMAIN_KNOWLEDGE_PATH="${CR_DOMAIN_KNOWLEDGE:-references/domain-knowledge.md}"
export NOTIFY_MIS_LIST="${CR_NOTIFY_MIS:-}"

# ── 0B. 工具依赖检查 ──────────────────────────────────────────────────
SKILL_CHECK_PASS=true

# 1. code-cli（核心依赖，缺失直接中止）
CODE_CLI_PATH=$(find ~/.claude/skills /root/.openclaw/skills ~/.openclaw/workspace/.claude/skills \
  -name code_cli.py 2>/dev/null | head -1)
if [ -z "$CODE_CLI_PATH" ]; then
  echo "❌ [code-cli] 未安装 → 核心流程不可用，请先安装："
  echo "   mtskills i code-cli"
  echo "   （mtskills 未安装：npm i -g @mtfe/mtskills --registry=http://r.npm.sankuai.com）"
  SKILL_CHECK_PASS=false
else
  export CODE_CLI="python3 $CODE_CLI_PATH"
  if ! $CODE_CLI user-info > /dev/null 2>&1; then
    echo "❌ [code-cli] Cookie 失效 → 请确认浏览器已打开 dev.sankuai.com（localhost:9222）"
    SKILL_CHECK_PASS=false
  else
    echo "✅ [code-cli] 可用"
  fi
fi

[ "$SKILL_CHECK_PASS" = false ] && { echo "⛔ 核心依赖缺失，终止执行"; exit 1; }

# 2. code-repo-search（Layer 2 全仓库反查，缺失降级）
REPO_SEARCH="$HOME/.openclaw/skills/code-repo-search/repo_search.py"
if [ ! -f "$REPO_SEARCH" ]; then
  echo "⚠️  [code-repo-search] 未安装 → Layer 2 全仓库反查降级（仅看 diff，检出率下降），建议安装："
  echo "   mtskills i code-repo-search"
  export REPO_SEARCH_AVAILABLE=false
else
  if python3 "$REPO_SEARCH" --help > /dev/null 2>&1; then
    echo "✅ [code-repo-search] 可用"
    export REPO_SEARCH REPO_SEARCH_AVAILABLE=true
  else
    echo "⚠️  [code-repo-search] 脚本存在但执行失败 → Layer 2 降级，建议重新安装："
    echo "   mtskills i code-repo-search"
    export REPO_SEARCH_AVAILABLE=false
  fi
fi

# 3. citadel（Step 6 学城文档）
if ! command -v oa-skills > /dev/null 2>&1; then
  echo "⚠️  [citadel] oa-skills 未找到 → Step 6 学城文档将失败，建议安装："
  echo "   mtskills i citadel"
else
  if oa-skills citadel --help > /dev/null 2>&1; then
    echo "✅ [citadel] 可用"
  else
    echo "⚠️  [citadel] oa-skills 存在但 citadel 子命令不可用，Step 6 可能失败"
  fi
fi

# 4. citadel-database（Step 9 多维表格）
if ! oa-skills citadel-database --help > /dev/null 2>&1; then
  echo "⚠️  [citadel-database] 未安装 → Step 9 多维表格将失败，建议安装："
  echo "   mtskills i citadel-database"
else
  echo "✅ [citadel-database] 可用"
fi

# 5. ee-ones（可选，Step 1 ONES 上下文）
if command -v ones > /dev/null 2>&1; then
  echo "✅ [ee-ones] 可用"
else
  echo "ℹ️  [ee-ones] 未安装（可选）→ 无 ONES ID 时不影响流程"
fi

echo ""
if [ "${REPO_SEARCH_AVAILABLE:-false}" = "false" ]; then
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo "⚠️  环境自检完成，但存在降级项，请确认后再继续："
  echo ""
  echo "   code-repo-search 未安装 → Layer 2 全仓库反查将跳过"
  echo "   影响：无法反查枚举/DTO/接口消费方，P1 检出率下降"
  echo ""
  echo "   安装命令：mtskills i code-repo-search"
  echo "   安装后重新执行本 CR 可获得完整检出"
  echo ""
  echo "   👉 请回复：【继续（降级）】或【等我安装好再跑】"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  # AI 必须在此暂停，等待用户确认，不得自动继续
else
  echo "✅ 环境自检全部通过，开始执行 CR 流程"
fi
