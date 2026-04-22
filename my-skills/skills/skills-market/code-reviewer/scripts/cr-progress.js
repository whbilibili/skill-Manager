#!/usr/bin/env node

/**
 * 代码审查进度跟踪
 *
 * 目的：
 *   - 把审查过程的阶段（phase）和中间发现（findings）落盘到 .cr-progress.json
 *   - 大 diff / 多阶段 / 多 Agent 模式下，即便 context 被截断也能从文件恢复进度
 *   - 主 Agent 合并阶段直接读各阶段 JSON 文件，不依赖单次对话记忆
 *
 * 使用方式：
 *   node cr-progress.js init [--mode <standard|grouped|two-phase|multi-agent>] [--base <branch>]
 *   node cr-progress.js phase-start <phase_name>
 *   node cr-progress.js phase-done  <phase_name> [--findings <file>]
 *   node cr-progress.js phase-fail  <phase_name> [--reason <text>]
 *   node cr-progress.js update-counts --p0 N --p1 N --p2 N
 *   node cr-progress.js note <text>                   # 追加一条 scratch 笔记
 *   node cr-progress.js stat                          # 打印当前进度
 *   node cr-progress.js cleanup                       # 删除进度文件
 *
 * 文件位置：
 *   当前工作目录下的 .cr-progress.json（与 .code-review-diff.tmp 同级）
 */

import { existsSync, readFileSync, writeFileSync, unlinkSync } from 'fs';
import { execSync } from 'child_process';
import { join } from 'path';

const PROGRESS_FILE = join(process.cwd(), '.cr-progress.json');

// ------------------------ 基础 IO ------------------------

function nowISO() {
  return new Date().toISOString();
}

function readProgress() {
  if (!existsSync(PROGRESS_FILE)) {
    throw new Error(`进度文件不存在: ${PROGRESS_FILE}，请先运行 "cr-progress init"`);
  }
  try {
    return JSON.parse(readFileSync(PROGRESS_FILE, 'utf-8'));
  } catch (e) {
    throw new Error(`进度文件解析失败: ${e.message}`);
  }
}

function writeProgress(data) {
  data.updated_at = nowISO();
  writeFileSync(PROGRESS_FILE, JSON.stringify(data, null, 2), 'utf-8');
}

function safeGit(cmd, fallback = '') {
  try {
    return execSync(cmd, { encoding: 'utf-8', stdio: 'pipe' }).trim();
  } catch {
    return fallback;
  }
}

// ------------------------ 命令实现 ------------------------

function cmdInit(args) {
  const mode = getFlag(args, '--mode') || 'standard';
  const base = getFlag(args, '--base') || 'master';

  const currentBranch = safeGit('git branch --show-current', '(unknown)');
  const headSha = safeGit('git rev-parse HEAD', '(unknown)');

  // diff 统计从已生成的 .code-review-diff.tmp 里读，没有就记 0
  const diffPath = join(process.cwd(), '.code-review-diff.tmp');
  let filesChanged = 0;
  let linesChanged = 0;
  let sizeKB = 0;
  if (existsSync(diffPath)) {
    const diffContent = readFileSync(diffPath, 'utf-8');
    filesChanged = (diffContent.match(/^diff --git/gm) || []).length;
    linesChanged = diffContent.split('\n').length;
    sizeKB = +(Buffer.byteLength(diffContent, 'utf-8') / 1024).toFixed(2);
  }

  const data = {
    session_id: `cr-${Date.now()}`,
    started_at: nowISO(),
    updated_at: nowISO(),
    branch: currentBranch,
    base,
    head_sha: headSha,
    mode,
    diff_stats: {
      files_changed: filesChanged,
      lines_changed: linesChanged,
      size_kb: sizeKB,
    },
    phases: [],
    findings_so_far: { p0: 0, p1: 0, p2: 0 },
    notes: [],
    last_checkpoint: nowISO(),
  };

  writeProgress(data);

  console.log(`📝 已创建审查进度文件: ${PROGRESS_FILE}`);
  console.log(`   session_id : ${data.session_id}`);
  console.log(`   branch     : ${currentBranch} vs ${base}`);
  console.log(`   mode       : ${mode}`);
  console.log(`   diff       : ${filesChanged} files / ${linesChanged} lines / ${sizeKB} KB`);
}

function cmdPhaseStart(args) {
  const name = args[0];
  if (!name) throw new Error('用法: cr-progress phase-start <phase_name>');

  const data = readProgress();
  // 同名 phase 如果存在且状态是 done，不覆盖；否则创建/重置
  const existing = data.phases.find((p) => p.name === name);
  if (existing && existing.status === 'done') {
    console.log(`ℹ️  阶段 "${name}" 已完成，跳过 start`);
    return;
  }

  if (existing) {
    existing.status = 'in_progress';
    existing.started_at = nowISO();
    existing.finished_at = null;
    existing.error = null;
  } else {
    data.phases.push({
      name,
      status: 'in_progress',
      started_at: nowISO(),
      finished_at: null,
      findings_file: null,
      error: null,
    });
  }

  data.last_checkpoint = nowISO();
  writeProgress(data);
  console.log(`▶️  阶段 "${name}" 已开始`);
}

function cmdPhaseDone(args) {
  const name = args[0];
  if (!name) throw new Error('用法: cr-progress phase-done <phase_name> [--findings <file>]');
  const findingsFile = getFlag(args, '--findings') || null;

  const data = readProgress();
  let phase = data.phases.find((p) => p.name === name);
  if (!phase) {
    // 允许跳过 start 直接 done（小 phase 用）
    phase = {
      name,
      status: 'in_progress',
      started_at: nowISO(),
      finished_at: null,
      findings_file: null,
      error: null,
    };
    data.phases.push(phase);
  }

  phase.status = 'done';
  phase.finished_at = nowISO();
  if (findingsFile) phase.findings_file = findingsFile;

  data.last_checkpoint = nowISO();
  writeProgress(data);
  console.log(`✅ 阶段 "${name}" 已完成${findingsFile ? ` (findings: ${findingsFile})` : ''}`);
}

function cmdPhaseFail(args) {
  const name = args[0];
  if (!name) throw new Error('用法: cr-progress phase-fail <phase_name> [--reason <text>]');
  const reason = getFlag(args, '--reason') || 'unspecified';

  const data = readProgress();
  let phase = data.phases.find((p) => p.name === name);
  if (!phase) {
    phase = { name, status: 'in_progress', started_at: nowISO(), findings_file: null };
    data.phases.push(phase);
  }
  phase.status = 'failed';
  phase.finished_at = nowISO();
  phase.error = reason;

  data.last_checkpoint = nowISO();
  writeProgress(data);
  console.log(`❌ 阶段 "${name}" 已标记失败: ${reason}`);
}

function cmdUpdateCounts(args) {
  const p0 = parseInt(getFlag(args, '--p0') ?? '', 10);
  const p1 = parseInt(getFlag(args, '--p1') ?? '', 10);
  const p2 = parseInt(getFlag(args, '--p2') ?? '', 10);

  const data = readProgress();
  if (!Number.isNaN(p0)) data.findings_so_far.p0 = p0;
  if (!Number.isNaN(p1)) data.findings_so_far.p1 = p1;
  if (!Number.isNaN(p2)) data.findings_so_far.p2 = p2;
  data.last_checkpoint = nowISO();
  writeProgress(data);
  console.log(
    `📊 已更新计数: P0=${data.findings_so_far.p0} P1=${data.findings_so_far.p1} P2=${data.findings_so_far.p2}`,
  );
}

function cmdNote(args) {
  const text = args.join(' ').trim();
  if (!text) throw new Error('用法: cr-progress note <text>');

  const data = readProgress();
  data.notes.push({ at: nowISO(), text });
  data.last_checkpoint = nowISO();
  writeProgress(data);
  console.log(`📌 已追加笔记 (#${data.notes.length})`);
}

function cmdStat() {
  if (!existsSync(PROGRESS_FILE)) {
    console.log('（无进度文件，尚未开始或已 cleanup）');
    return;
  }
  const data = readProgress();
  const line = '─'.repeat(60);
  console.log(line);
  console.log(`📋 代码审查进度  (${data.session_id})`);
  console.log(line);
  console.log(`分支          : ${data.branch}  →  ${data.base}`);
  console.log(`模式          : ${data.mode}`);
  console.log(
    `Diff          : ${data.diff_stats.files_changed} files / ${data.diff_stats.lines_changed} lines / ${data.diff_stats.size_kb} KB`,
  );
  console.log(
    `当前发现      : P0=${data.findings_so_far.p0}  P1=${data.findings_so_far.p1}  P2=${data.findings_so_far.p2}`,
  );
  console.log(`最后更新      : ${data.updated_at}`);
  console.log(`阶段 (${data.phases.length}):`);
  for (const p of data.phases) {
    const icon =
      p.status === 'done' ? '✅' : p.status === 'in_progress' ? '▶️ ' : p.status === 'failed' ? '❌' : '⏸ ';
    const extra = p.findings_file
      ? `  findings=${p.findings_file}`
      : p.error
        ? `  error=${p.error}`
        : '';
    console.log(`  ${icon} ${p.name.padEnd(24)} ${p.status}${extra}`);
  }
  if (data.notes.length) {
    console.log(`笔记 (${data.notes.length}):`);
    data.notes.slice(-5).forEach((n, i) => console.log(`  - [${n.at}] ${n.text}`));
  }
  console.log(line);
}

function cmdCleanup() {
  if (existsSync(PROGRESS_FILE)) {
    unlinkSync(PROGRESS_FILE);
    console.log(`🗑️  已删除进度文件: ${PROGRESS_FILE}`);
  } else {
    console.log('ℹ️  进度文件不存在，无需清理');
  }
}

// ------------------------ 工具函数 ------------------------

function getFlag(args, flag) {
  const i = args.indexOf(flag);
  if (i === -1) return null;
  return args[i + 1] ?? null;
}

function showHelp() {
  console.log(`
代码审查进度跟踪 (.cr-progress.json)

用法:
  node cr-progress.js init [--mode <mode>] [--base <branch>]
  node cr-progress.js phase-start <phase_name>
  node cr-progress.js phase-done  <phase_name> [--findings <file>]
  node cr-progress.js phase-fail  <phase_name> [--reason <text>]
  node cr-progress.js update-counts --p0 N --p1 N --p2 N
  node cr-progress.js note <text>
  node cr-progress.js stat
  node cr-progress.js cleanup
`);
}

// ------------------------ 入口 ------------------------

const [, , cmd, ...rest] = process.argv;

try {
  switch (cmd) {
    case 'init':
      cmdInit(rest);
      break;
    case 'phase-start':
      cmdPhaseStart(rest);
      break;
    case 'phase-done':
      cmdPhaseDone(rest);
      break;
    case 'phase-fail':
      cmdPhaseFail(rest);
      break;
    case 'update-counts':
      cmdUpdateCounts(rest);
      break;
    case 'note':
      cmdNote(rest);
      break;
    case 'stat':
      cmdStat();
      break;
    case 'cleanup':
      cmdCleanup();
      break;
    case '-h':
    case '--help':
    case 'help':
    case undefined:
      showHelp();
      break;
    default:
      console.error(`未知命令: ${cmd}`);
      showHelp();
      process.exit(2);
  }
} catch (e) {
  console.error(`❌ ${e.message}`);
  process.exit(1);
}
