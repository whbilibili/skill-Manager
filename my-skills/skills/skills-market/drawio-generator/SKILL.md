---
name: drawio-generator
description: Generate Draw.io flowchart XML scripts for Meituan Xuecheng (学城) platform. Use when users need to create flowcharts, architecture diagrams, process diagrams, or any visual diagrams for documentation. The workflow includes: (1) Generating .drawio XML files, (2) Displaying ASCII preview for confirmation, (3) URL-encoding the XML for Xuecheng draw.io editor compatibility.

metadata:
  skillhub.creator: "panheyi"
  skillhub.updater: "panheyi"
  skillhub.version: "V5"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "1535"
  skillhub.high_sensitive: "false"
---

## [MANDATORY] SKILLHUB_METRIC_REPORTER_START
执行本 Skill 的任何操作之前，必须先执行 Skill：`skill-metric-reporter`。
按照 `skill-metric-reporter` 的要求完成 `skill_start` 上报后，才可继续本 Skill 正文。
本 Skill 全部操作完成后，同样按照 `skill-metric-reporter` 的要求完成 `skill_end` 上报。
## [MANDATORY] SKILLHUB_METRIC_REPORTER_END

# Draw.io Flowchart Generator

Generate Draw.io XML flowcharts compatible with Xuecheng (学城) draw.io editor.

## Prerequisites

运行脚本所需工具（均为系统内置，无需额外安装）：

| 工具 | 用途 | 备注 |
|------|------|------|
| `bash` | 运行脚本 | 系统内置 |
| `perl` | 注释修复、中文引号修复 | macOS/Linux 内置 |
| `awk` | 节点重叠检测 | macOS/Linux 内置 |
| `xmllint` | XML 语法校验 | macOS 内置；Linux: `apt install libxml2-utils` |

## Workflow

### Step 1: Generate Draw.io XML

1. Understand user's flowchart requirements
2. Generate XML following the Draw.io mxGraph format
3. Save to `drawio/` directory under the project root (create if not exists)

**Key requirements:**
- XML must be compatible with older draw.io versions (avoid new features)
- Follow the XML structure defined in [references/drawio-xml-generation.md](references/drawio-xml-generation.md)
- Use standard colors and styles for consistency
- **Special characters**: Use XML entity encoding for quotes and special chars:
  - Use `&quot;` for quotation marks (NOT Chinese quotes `””`)
  - Use `&#xa;` for line breaks
  - See [references/drawio-xml-generation.md](references/drawio-xml-generation.md) for full encoding table
- **XML comments must be valid**:
  - Never use `--` or `-->` inside comment body (forbidden by XML spec)
  - Avoid separators like `<!-- ---- section ---- -->`
  - Prefer `<!-- == section == -->` or `<!-- section -->`
  - When describing flow direction in comments, use `->` (single arrow), never `-->`
- **No overlapping nodes**: verify every node's bounding box does not intersect with siblings under the same parent
- **XML 验证流程**（生成文件后必须执行，URL 编码前完成）：
  1. 运行 `bash scripts/lint_and_fix.sh <file.drawio>` — 自动修复注释和引号问题，内置 xmllint 校验
  2. 如果 xmllint 报错，**AI 根据错误信息定位问题行，修正 XML 后重新运行步骤 1**
  3. 如果报告节点重叠 Warning，**AI 读取每条 Warning 中的 parent/id/坐标信息，结合流程语义判断布局，修正重叠节点的坐标后重新运行步骤 1，直到无 Warning 为止**

### Step 2: Display ASCII Preview

After generating the XML, display an ASCII art preview of the flowchart:

```
┌─────────┐     ┌─────────┐     ┌─────────┐
│  开始   │────▶│  处理   │────▶│  结束   │
└─────────┘     └─────────┘     └─────────┘
```

**Ask user:** "流程图已生成，请确认是否正确？确认后将完成输出。"

Wait for user confirmation before proceeding.

### Step 3: Provide Instructions

告知用户两种等价的使用方式：

> ✅ 流程图已生成：`drawio/<filename>.drawio`
>
> **导入学城 draw.io 编辑器（两种方式等价，任选其一）：**
>
> **方式一（推荐）：拖入**
> 将 `.drawio` 文件直接拖入学城 draw.io 编辑器即可。
>
> **方式二：复制粘贴**
> 如需复制内容粘贴，请告知，我将生成 URL 编码版本。

### Step 3 (可选): URL Encode

仅当用户选择"复制粘贴"方式时执行：

```bash
bash scripts/xml_urlencode.sh <input.drawio> <output_encoded.drawio>
```

编码说明：
- 将所有字符转为 `%XX` 十六进制格式（纯 Shell，无 Python/Node.js 依赖）
- 输出文件约为原始大小的 3 倍
- 编码文件与直接拖入效果完全等价

完成后告知用户：

> ✅ URL 编码完成：`drawio/<filename>_encoded.drawio`
>
> **使用方式：**
> 1. 打开学城编辑器
> 2. 创建空白框图
> 3. 复制编码文件的全部内容并粘贴

## Output Directory

Generated `.drawio` files are saved to `<project_root>/drawio/` directory.
- Create the directory if it does not exist
- This keeps generated files separate from source code

## File Structure

```
drawio-generator/
├── README.md                             # 使用说明与版本记录
├── SKILL.md                              # This file
├── scripts/
│   ├── xml_urlencode.sh                  # URL encoding script
│   └── lint_and_fix.sh                   # XML lint + auto-fix (pure shell, no Python needed)
└── references/
    ├── drawio-xml-generation.md          # XML format specification
    └── drawio-example.drawio             # Example flowchart XML

<project_root>/
└── drawio/                                # Generated flowcharts (output)
    └── *.drawio
```

## Reference Files

- **[drawio-xml-generation.md](references/drawio-xml-generation.md)**: Complete XML structure, element definitions, style properties, and best practices. READ THIS for detailed XML format.

- **[drawio-example.drawio](references/drawio-example.drawio)**: Working examples including:
  - Simple flowchart with decision nodes
  - Grouped containers with layers
  - Multi-tier architecture diagram

## Quick Reference

### Standard Node Styles

| Type | Style |
|------|-------|
| Input/Output | `fillColor=#fff2cc;strokeColor=#d6b656;` |
| Function | `fillColor=#dae8fc;strokeColor=#6c8ebf;` |
| Success | `fillColor=#d5e8d4;strokeColor=#82b366;` |
| Error | `fillColor=#f8cecc;strokeColor=#b85450;` |

### Standard Sizes

| Element | Width | Height |
|---------|-------|--------|
| Standard node | 120 | 60 |
| Large node | 160 | 80 |
| Label | auto | 30 |

### Connection Line

```xml
<mxCell id="X" style="edgeStyle=orthogonalEdgeStyle;rounded=0;orthogonalLoop=1;jettySize=auto;html=1;entryX=0;entryY=0.5;entryDx=0;entryDy=0;exitX=1;exitY=0.5;exitDx=0;exitDy=0;" parent="1" source="FROM_ID" target="TO_ID" edge="1">
  <mxGeometry relative="1" as="geometry" />
</mxCell>
```

## Important Notes

1. **Compatibility First**: Avoid advanced features not supported in older draw.io versions
2. **Unique IDs**: Every `mxCell` must have a unique `id` attribute
3. **Coordinate System**: Origin (0,0) is top-left, Y increases downward
4. **Spacing**: Minimum 20px between elements, coordinates as multiples of 10
5. **Comment Safety**: XML comments cannot contain `--` (e.g. `<!-- ---- xx ---- -->` is invalid)
6. **Pre-encode Check**: Run `xmllint --noout` before URL encoding to fail fast on malformed XML
