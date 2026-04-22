/**
 * Self-Improvement Hook for OpenClaw
 *
 * 1. 注入"记录学习经验"的行为提醒
 * 2. 读取 .learnings/ 中的高优条目，注入到 prompt 中（真正"用上"已有 learning）
 *
 * Fires on agent:bootstrap event before workspace files are injected.
 */

const fs = require('fs');
const path = require('path');

// ── 配置 ────────────────────────────────────────────────────────────
const MAX_ENTRIES = 15;           // 最多注入条目数
const MAX_CHARS = 4000;           // 注入内容上限（控制 token 消耗）
const PRIORITIES = ['critical', 'high', 'medium']; // 按优先级排序注入
const INCLUDE_RESOLVED = true;    // resolved 条目也注入（已踩过的坑仍有参考价值）

// ── 提醒模板（始终注入） ────────────────────────────────────────────
const REMINDER_CONTENT = `
## Self-Improvement Reminder

After completing tasks, evaluate if any learnings should be captured:

**Log when:**
- User corrects you → \`.learnings/LEARNINGS.md\`
- Command/operation fails → \`.learnings/ERRORS.md\`
- User wants missing capability → \`.learnings/FEATURE_REQUESTS.md\`
- You discover your knowledge was wrong → \`.learnings/LEARNINGS.md\`
- You find a better approach → \`.learnings/LEARNINGS.md\`

**Promote when pattern is proven:**
- Behavioral patterns → \`SOUL.md\`
- Workflow improvements → \`AGENTS.md\`
- Tool gotchas → \`TOOLS.md\`

Keep entries simple: date, title, what happened, what to do differently.
`.trim();

// ── 解析 .learnings/*.md 中的条目 ──────────────────────────────────
function parseEntries(filePath) {
  let content;
  try {
    content = fs.readFileSync(filePath, 'utf-8');
  } catch {
    return [];
  }

  const entries = [];
  // 按 ## [TYPE-DATE-SEQ] 分割
  const blocks = content.split(/(?=^## \[(?:LRN|ERR|FEAT)-\d{8}-\d{3}\])/m);

  for (const block of blocks) {
    const headerMatch = block.match(/^## \[((?:LRN|ERR|FEAT)-\d{8}-\d{3})\]\s+(.+)/m);
    if (!headerMatch) continue;

    const id = headerMatch[1];
    const category = headerMatch[2].trim();

    const priorityMatch = block.match(/\*\*Priority\*\*:\s*(\w+)/i);
    const statusMatch = block.match(/\*\*Status\*\*:\s*(\w+)/i);
    const summaryMatch = block.match(/### Summary\s*\n([\s\S]*?)(?=\n###|\n---|\n## \[|$)/);
    const actionMatch = block.match(/### Suggested (?:Action|Fix)\s*\n([\s\S]*?)(?=\n###|\n---|\n## \[|$)/);

    const priority = priorityMatch ? priorityMatch[1].toLowerCase() : 'medium';
    const status = statusMatch ? statusMatch[1].toLowerCase() : 'pending';

    // 跳过 wont_fix 和 promoted 状态
    if (['wont_fix', 'promoted_to_skill', 'promoted_to_memory'].includes(status)) continue;

    // 根据配置决定是否包含 resolved
    if (!INCLUDE_RESOLVED && status === 'resolved') continue;

    const summary = summaryMatch ? summaryMatch[1].trim() : '';
    const action = actionMatch ? actionMatch[1].trim() : '';

    if (!summary) continue;

    entries.push({ id, category, priority, status, summary, action });
  }

  return entries;
}

// ── 按优先级排序 ───────────────────────────────────────────────────
function sortByPriority(entries) {
  const order = { critical: 0, high: 1, medium: 2, low: 3 };
  return entries.sort((a, b) => (order[a.priority] ?? 3) - (order[b.priority] ?? 3));
}

// ── 格式化为注入内容 ───────────────────────────────────────────────
function formatEntries(entries) {
  if (entries.length === 0) return '';

  let lines = [
    '## Past Learnings & Errors (auto-injected)',
    '',
    'These are lessons from previous sessions. Apply them to avoid repeating mistakes.',
    '',
  ];

  for (const e of entries) {
    const statusTag = e.status === 'resolved' ? ' ✓' : '';
    lines.push(`### [${e.id}] ${e.category}${statusTag}`);
    lines.push(`**Priority**: ${e.priority} | **Status**: ${e.status}`);
    lines.push(`**Summary**: ${e.summary}`);
    if (e.action) {
      lines.push(`**Action**: ${e.action}`);
    }
    lines.push('');
  }

  let result = lines.join('\n');

  // 截断保护
  if (result.length > MAX_CHARS) {
    result = result.slice(0, MAX_CHARS) + '\n\n_(truncated — see .learnings/ for full details)_';
  }

  return result;
}

// ── 主 handler ─────────────────────────────────────────────────────
const handler = async (event) => {
  if (!event || typeof event !== 'object') return;
  if (event.type !== 'agent' || event.action !== 'bootstrap') return;
  if (!event.context || typeof event.context !== 'object') return;
  if (!Array.isArray(event.context.bootstrapFiles)) return;

  // 1. 始终注入行为提醒
  event.context.bootstrapFiles.push({
    path: 'SELF_IMPROVEMENT_REMINDER.md',
    content: REMINDER_CONTENT,
    virtual: true,
  });

  // 2. 尝试读取并注入已有 learning
  const workspaceDirs = [
    path.join(process.env.HOME || '/root', '.openclaw', 'workspace'),
    process.cwd(),
  ];

  let allEntries = [];

  for (const ws of workspaceDirs) {
    const learningsDir = path.join(ws, '.learnings');
    const files = ['LEARNINGS.md', 'ERRORS.md', 'FEATURE_REQUESTS.md'];

    for (const file of files) {
      const filePath = path.join(learningsDir, file);
      const entries = parseEntries(filePath);
      allEntries.push(...entries);
    }

    // 找到有效目录后就停，避免重复
    if (allEntries.length > 0) break;
  }

  if (allEntries.length === 0) return;

  // 去重（同 ID 可能出现在多个扫描路径）
  const seen = new Set();
  allEntries = allEntries.filter((e) => {
    if (seen.has(e.id)) return false;
    seen.add(e.id);
    return true;
  });

  // 排序 + 截取
  const sorted = sortByPriority(allEntries).slice(0, MAX_ENTRIES);
  const content = formatEntries(sorted);

  if (content) {
    event.context.bootstrapFiles.push({
      path: 'PAST_LEARNINGS.md',
      content,
      virtual: true,
    });
  }
};

module.exports = handler;
module.exports.default = handler;
