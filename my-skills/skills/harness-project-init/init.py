#!/usr/bin/env python3

"""
Harness 工程初始化脚本（Python 版本）
用法：python3 init.py --project-name frontend --project-type frontend --root-dir ./frontend
"""

import argparse
import json
import os
from datetime import datetime, timedelta
from pathlib import Path


class HarnessProjectInitializer:
    """Harness 工程初始化器"""

    def __init__(self, project_name, project_type, root_dir, tech_stack="", include_examples=True):
        self.project_name = project_name
        self.project_type = project_type
        self.root_dir = Path(root_dir)
        self.tech_stack = tech_stack
        self.include_examples = include_examples
        self.harness_dir = self.root_dir / "harness"
        self.docs_dir = self.harness_dir / "docs"
        self.memory_dir = self.harness_dir / "memory"
        self.timestamp = datetime.utcnow().isoformat() + "Z"
        self.date = datetime.now().strftime("%Y-%m-%d")

    def create_directories(self):
        """创建目录结构"""
        print("📁 创建目录结构...")
        self.docs_dir.mkdir(parents=True, exist_ok=True)
        self.memory_dir.mkdir(parents=True, exist_ok=True)

    def create_feature_list(self):
        """创建 feature-list.json"""
        print("📝 创建 feature-list.json...")
        
        tasks = []
        if self.include_examples:
            tasks = [
                {
                    "id": "TASK-001",
                    "title": "项目初始化",
                    "description": "搭建项目基础框架",
                    "status": "pending",
                    "priority": "P0",
                    "assignee": "coding-agent",
                    "created_at": self.timestamp,
                    "updated_at": self.timestamp,
                    "started_at": None,
                    "completed_at": None,
                    "estimated_hours": 2,
                    "actual_hours": 0,
                    "acceptance_criteria": [
                        "项目结构完整",
                        "依赖安装成功",
                        "开发环境可用"
                    ],
                    "branch": "feature/init",
                    "related_docs": ["ARCHITECTURE.md#项目结构"],
                    "dependencies": [],
                    "blockers": [],
                    "notes": "待开始"
                }
            ]

        feature_list = {
            "version": "1.0",
            "project": self.project_name,
            "project_type": self.project_type,
            "created_at": self.timestamp,
            "updated_at": self.timestamp,
            "metadata": {
                "total_tasks": len(tasks),
                "completed_tasks": 0,
                "in_progress_tasks": 0,
                "pending_tasks": len(tasks),
                "completion_rate": 0
            },
            "tasks": tasks
        }

        with open(self.harness_dir / "feature-list.json", "w") as f:
            json.dump(feature_list, f, indent=2, ensure_ascii=False)

    def create_progress_txt(self):
        """创建 progress.txt（交接棒式格式，兼容 session-handoff / harness-watchdog 等 skill）"""
        print("📝 创建 progress.txt...")
        
        content = f"""# {self.project_name} 工程进度记录

> 本文件由 session-handoff 维护，200 行硬上限。
> Section markers 被 7 个 harness skill 解析，请勿修改标题格式。

### [Current Focus]
- 项目初始化：搭建基础框架

### [Key Decisions]
- {self.date}: 使用 harness-project-init v2.1 初始化文档体系

### [Blockers & Solutions]
（暂无）

### [Dead Ends]
（暂无）

### [Next Steps]
- [ ] 编辑 feature-list.json，添加实际任务
- [ ] 编辑 ARCHITECTURE.md，描述项目架构
- [ ] 开始编码，首个会话结束时运行 session-handoff
"""
        with open(self.harness_dir / "progress.txt", "w") as f:
            f.write(content)

    def create_architecture_md(self):
        """创建 ARCHITECTURE.md"""
        print("📝 创建 ARCHITECTURE.md...")
        
        tech_stack_section = ""
        if self.tech_stack:
            tech_stack_section = f"- 技术栈：{self.tech_stack}\n"

        content = f"""# {self.project_name} 架构文档

**工程类型**：{self.project_type}
**创建时间**：{self.date}
**维护者**：架构师 / Coding Agent
**最后更新**：{self.date}

---

## 📋 项目概述

### 项目目标
简要描述项目的目标和范围

### 技术栈
{tech_stack_section}- 待定

### 关键指标
- 性能目标：待定
- 可用性目标：待定
- 测试覆盖率目标：> 80%

---

## 🏗️ 模块划分

### 模块 1：[模块名]
- **职责**：待定
- **关键文件**：src/
- **依赖**：待定
- **接口**：待定

---

## 🎯 关键设计决策

### 决策 1：[决策标题]

| 项目 | 内容 |
|------|------|
| **决策时间** | {self.date} |
| **决策者** | 架构师 |
| **选项** | 待定 |
| **最终选择** | 待定 |
| **原因** | 待定 |
| **权衡** | 待定 |

---

## 🚫 架构约束

### 禁止（红线）

❌ **禁止 1**：待定
- 原因：待定
- 替代方案：待定

### 推荐（绿线）

✅ **推荐 1**：待定
- 好处：待定

---

**维护规则**：
- 新增模块 → 更新此文档
- 架构变更 → 更新此文档
- 新增设计决策 → 更新此文档
"""
        with open(self.harness_dir / "ARCHITECTURE.md", "w") as f:
            f.write(content)

    def create_caveats_md(self):
        """创建 docs/caveats.md"""
        print("📝 创建 docs/caveats.md...")
        
        content = f"""# 踩坑档案

**工程**：{self.project_name}
**维护者**：Coding Agent
**最后更新**：{self.date}

---

> 记录开发过程中遇到的问题、解决方案和经验教训

## 问题 1：[问题标题]

### 问题描述
[简要描述问题]

### 现象
[具体现象和错误信息]

### 复现步骤
1. [步骤 1]
2. [步骤 2]

### 根本原因
[分析根本原因]

### 解决方案
[提供解决方案]

### 状态
✅ 已解决 / ⏳ 待解决 / 🔄 进行中

---

**维护规则**：
- 遇到新问题时更新
- 问题解决时更新状态
"""
        with open(self.docs_dir / "caveats.md", "w") as f:
            f.write(content)

    def create_tech_debt_md(self):
        """创建 docs/tech-debt.md"""
        print("📝 创建 docs/tech-debt.md...")
        
        content = f"""# 技术债清单

**工程**：{self.project_name}
**维护者**：Coding Agent
**最后更新**：{self.date}

---

> 记录需要后续改进的技术问题

## 优先级说明

| 级别 | 含义 | 处理时间 |
|------|------|---------|
| **P0** | 阻塞上线，必须立即处理 | 本周内 |
| **P1** | 影响稳定性，应该尽快处理 | 本月内 |
| **P2** | 影响体验，可以排期处理 | 本季度内 |
| **P3** | 优化建议，可以延后处理 | 待定 |

---

## 技术债列表

| ID | 描述 | 优先级 | 预计工作量 | 状态 |
|----|------|--------|-----------|------|
| TD-001 | 待定 | P2 | 待定 | pending |

---

**维护规则**：
- 发现新的技术债时更新
- 技术债状态变更时更新
- 技术债优先级调整时更新
"""
        with open(self.docs_dir / "tech-debt.md", "w") as f:
            f.write(content)

    def create_changelog_md(self):
        """创建 docs/CHANGELOG.md"""
        print("📝 创建 docs/CHANGELOG.md...")
        
        content = f"""# 变更日志

**工程**：{self.project_name}
**维护者**：Coding Agent
**最后更新**：{self.date}

---

> 记录每个版本的功能、bug 修复和已知问题

## [Unreleased]

### Added
- 待定

### Fixed
- 待定

### Changed
- 待定

### Known Issues
- 待定

---
"""
        with open(self.docs_dir / "CHANGELOG.md", "w") as f:
            f.write(content)

    def create_memory_md(self):
        """创建 memory/MEMORY.md"""
        print("📝 创建 memory/MEMORY.md...")
        
        content = f"""# 长期记忆

**工程**：{self.project_name}
**维护者**：Coding Agent
**最后更新**：{self.date}

---

> 蒸馏自每日工作日志的高价值条目

## 架构决策

### 待定

---
"""
        with open(self.memory_dir / "MEMORY.md", "w") as f:
            f.write(content)

    def create_sync_state_json(self):
        """创建 .sync-state.json"""
        print("📝 创建 .sync-state.json...")
        
        next_sync = (datetime.utcnow() + timedelta(days=1)).isoformat() + "Z"
        
        sync_state = {
            "version": "1.0",
            "project": self.project_name,
            "last_sync": self.timestamp,
            "sync_duration_seconds": 0,
            "harness_version": "1.0",
            "code_commit": "initial",
            "code_branch": "main",
            "status": "in_sync",
            "sync_checks": {},
            "statistics": {
                "total_tasks": 1 if self.include_examples else 0,
                "completed_tasks": 0,
                "in_progress_tasks": 0,
                "pending_tasks": 1 if self.include_examples else 0,
                "completion_rate": 0,
                "total_code_lines": 0,
                "total_commits": 0,
                "test_coverage": 0
            },
            "warnings": [],
            "next_sync_recommended": next_sync,
            "notes": "初始化时自动生成"
        }

        with open(self.root_dir / ".sync-state.json", "w") as f:
            json.dump(sync_state, f, indent=2, ensure_ascii=False)

    def create_gitignore(self):
        """创建 .gitignore"""
        print("📝 创建 .gitignore...")
        
        content = """# Harness 文档不入公共仓库
# 这些文件是本地分支开发的工作记录

# 临时文件
*.tmp
*.log
.DS_Store

# IDE
.vscode/
.idea/
*.swp
*.swo

# 依赖
node_modules/
__pycache__/
.venv/
"""
        with open(self.harness_dir / ".gitignore", "w") as f:
            f.write(content)

    def print_summary(self):
        """打印初始化总结"""
        print("\n" + "=" * 60)
        print("✅ Harness 文档体系初始化完成！")
        print("=" * 60)
        print(f"\n📂 目录结构：")
        print(f"  {self.root_dir}/")
        print(f"  ├── harness/")
        print(f"  │   ├── feature-list.json")
        print(f"  │   ├── progress.txt")
        print(f"  │   ├── ARCHITECTURE.md")
        print(f"  │   ├── docs/")
        print(f"  │   │   ├── caveats.md")
        print(f"  │   │   ├── tech-debt.md")
        print(f"  │   │   └── CHANGELOG.md")
        print(f"  │   ├── memory/")
        print(f"  │   │   └── MEMORY.md")
        print(f"  │   └── .gitignore")
        print(f"  └── .sync-state.json")
        print(f"\n📋 下一步：")
        print(f"  1. 编辑 {self.harness_dir}/feature-list.json，添加实际任务")
        print(f"  2. 编辑 {self.harness_dir}/ARCHITECTURE.md，描述项目架构")
        print(f"  3. 开始编码，每个会话结束时运行 session-handoff")
        print()

    def initialize(self):
        """执行初始化"""
        self.create_directories()
        self.create_feature_list()
        self.create_progress_txt()
        self.create_architecture_md()
        self.create_caveats_md()
        self.create_tech_debt_md()
        self.create_changelog_md()
        self.create_memory_md()
        self.create_sync_state_json()
        self.create_gitignore()
        self.print_summary()


def main():
    parser = argparse.ArgumentParser(
        description="初始化 Harness 工程项目骨架"
    )
    parser.add_argument(
        "--project-name",
        required=True,
        help="项目名称（e.g., frontend）"
    )
    parser.add_argument(
        "--project-type",
        required=True,
        choices=["frontend", "backend", "fullstack"],
        help="项目类型"
    )
    parser.add_argument(
        "--root-dir",
        default=".",
        help="项目根目录路径（默认：当前目录）"
    )
    parser.add_argument(
        "--tech-stack",
        default="",
        help="技术栈描述（可选）"
    )
    parser.add_argument(
        "--include-examples",
        action="store_true",
        default=True,
        help="是否包含示例任务（默认：true）"
    )

    args = parser.parse_args()

    initializer = HarnessProjectInitializer(
        project_name=args.project_name,
        project_type=args.project_type,
        root_dir=args.root_dir,
        tech_stack=args.tech_stack,
        include_examples=args.include_examples
    )

    initializer.initialize()


if __name__ == "__main__":
    main()
