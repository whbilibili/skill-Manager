#!/usr/bin/env node

/**
 * Git变更复杂度分析脚本
 *
 * 功能：
 * - 检测暂存区（Staged）或工作区（Unstaged）的前端文件变更
 * - 分析文件行数复杂度
 * - 输出Markdown格式的变更分析报告
 */

const { execSync } = require('child_process');
const path = require('path');

// 前端文件扩展名
const FRONTEND_EXTENSIONS = [
  '.js', '.jsx', '.ts', '.tsx',
  '.vue', '.css', '.scss', '.less', '.sass',
  '.html', '.htm'
];

/**
 * 执行git命令
 */
function execGit(cmd) {
  try {
    return execSync(cmd, { encoding: 'utf-8', cwd: process.cwd() }).trim();
  } catch (error) {
    return '';
  }
}

/**
 * 检查是否在Git仓库中
 */
function isInGitRepo() {
  const result = execGit('git rev-parse --is-inside-work-tree');
  return result === 'true';
}

/**
 * 获取暂存区变更文件
 */
function getStagedFiles() {
  const output = execGit('git diff --cached --name-only');
  if (!output) return [];

  return output.split('\n').filter(file => {
    const ext = path.extname(file).toLowerCase();
    return FRONTEND_EXTENSIONS.includes(ext);
  });
}

/**
 * 获取工作区变更文件
 */
function getUnstagedFiles() {
  const output = execGit('git diff --name-only');
  if (!output) return [];

  return output.split('\n').filter(file => {
    const ext = path.extname(file).toLowerCase();
    return FRONTEND_EXTENSIONS.includes(ext);
  });
}

/**
 * 获取文件变更行数统计
 */
function getFileStats(filePath, isStaged) {
  const diffCmd = isStaged ? 'git diff --cached --numstat' : 'git diff --numstat';
  const output = execGit(diffCmd);

  if (!output) return null;

  const lines = output.split('\n');
  for (const line of lines) {
    const [additions, deletions, file] = line.split('\t');
    if (file === filePath) {
      const added = parseInt(additions) || 0;
      const deleted = parseInt(deletions) || 0;
      return {
        added,
        deleted,
        total: added + deleted
      };
    }
  }

  return { added: 0, deleted: 0, total: 0 };
}

/**
 * 评估复杂度并生成建议
 */
function assessComplexity(stats) {
  if (stats.total === 0) {
    return { status: '✅', suggestion: '无变更' };
  }

  if (stats.total > 500) {
    return {
      status: '🔴',
      suggestion: `严重超出建议行数（>500，实际${stats.total}），建议拆分为多个文件或模块`
    };
  }

  if (stats.total > 300) {
    return {
      status: '⚠️',
      suggestion: `超出建议行数（>300，实际${stats.total}），建议检查是否可优化拆分`
    };
  }

  if (stats.total > 100) {
    return {
      status: '📝',
      suggestion: `变更较大（${stats.total}行），建议重点关注`
    };
  }

  return {
    status: '✅',
    suggestion: '变更合理'
  };
}

/**
 * 生成Markdown表格
 */
function generateTable(files, isStaged) {
  if (files.length === 0) {
    return '| 状态 | 行数 | 文件 | 建议 |\n|---|---|---|---|\n| ℹ️ | - | 无变更 | 没有发现前端文件变更 |';
  }

  let table = '| 状态 | 行数 | 文件 | 建议 |\n|---|---|---|---|\n';

  for (const file of files) {
    const stats = getFileStats(file, isStaged);
    const assessment = assessComplexity(stats);

    const lineInfo = stats.total > 0
      ? `+${stats.added} -${stats.deleted} (${stats.total})`
      : '重命名';

    table += `| ${assessment.status} | ${lineInfo} | \`${file}\` | ${assessment.suggestion} |\n`;
  }

  return table;
}

/**
 * 主函数
 */
function main() {
  // 检查Git仓库
  if (!isInGitRepo()) {
    console.error('❌ 错误：当前目录不是Git仓库');
    process.exit(1);
  }

  // 检查暂存区
  const stagedFiles = getStagedFiles();
  const unstagedFiles = getUnstagedFiles();

  let scope = '';
  let files = [];
  let isStaged = false;

  if (stagedFiles.length > 0) {
    scope = '暂存区 (Staged)';
    files = stagedFiles;
    isStaged = true;
  } else if (unstagedFiles.length > 0) {
    scope = '工作区 (Unstaged)';
    files = unstagedFiles;
    isStaged = false;
  } else {
    scope = '暂存区和工作区';
    files = [];
    isStaged = true;
  }

  // 输出报告
  console.log(`\n## 📊 Git变更复杂度分析报告`);
  console.log(`\n**检测范围**: ${scope}`);
  console.log(`**文件数量**: ${files.length}`);
  console.log(`\n${generateTable(files, isStaged)}\n`);

  // 统计摘要
  if (files.length > 0) {
    let totalAdded = 0;
    let totalDeleted = 0;
    let warningCount = 0;
    let criticalCount = 0;

    for (const file of files) {
      const stats = getFileStats(file, isStaged);
      totalAdded += stats.added;
      totalDeleted += stats.deleted;

      if (stats.total > 500) criticalCount++;
      else if (stats.total > 300) warningCount++;
    }

    console.log(`**统计摘要**:`);
    console.log(`- 总添加行数: +${totalAdded}`);
    console.log(`- 总删除行数: -${totalDeleted}`);
    console.log(`- 总变更行数: ${totalAdded + totalDeleted}`);
    console.log(`- 警告文件数（>300行）: ${warningCount}`);
    console.log(`- 严重文件数（>500行）: ${criticalCount}`);
    console.log('');
  }
}

// 执行主函数
try {
  main();
} catch (error) {
  console.error(`❌ 执行失败: ${error.message}`);
  process.exit(1);
}
