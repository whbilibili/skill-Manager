---
name: lobster-daxiang-image
alias: 龙虾给我大象发图图
description: 🦞📸 CatClaw/OpenClaw 图片发送增强技能。在大象（Daxiang）频道中，当用户需要查看图片时，自动将本地图片上传到美团 S3Plus，然后以 Markdown 图片格式返回给用户，确保图片在大象中可直接预览。优先使用外网地址，外网不可用时回退到内网地址。适用于 CatClaw、OpenClaw 等 AI Agent 平台。触发词：看图片、发图片、截图发我、显示图片、查看图片、图片预览。
tags: 工作流程,catclaw,openclaw
作者：李平江

metadata:
  skillhub.creator: "lipingjiang"
  skillhub.updater: "lipingjiang"
  skillhub.version: "V1"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "2145"
---

# 龙虾给我大象发图图 🦞📸

## Overview

在大象（Daxiang）消息频道中，当用户需要查看图片时，自动完成：
1. 将本地图片文件上传到美团 S3Plus 存储
2. 优先获取**外网可访问地址**（prod 环境），若失败则回退到**内网地址**（prod-corp 环境）
3. 将 S3 URL 包装成 Markdown 图片格式 `![描述](url)` 返回给用户
4. 图片在大象消息中可直接预览，无需用户手动下载

## 触发条件

当用户在大象频道中发送以下类型的请求时激活：
- "帮我看一下这张图片"
- "截图发给我"
- "把图片发出来"
- "显示/查看/预览图片"
- 任何需要将本地图片展示给用户的场景

## 工作流程

### Step 1: 确认图片文件

确认本地图片文件路径。支持的格式：png, jpg, jpeg, gif, webp, bmp, svg

### Step 2: 上传到 S3Plus

使用 s3plus-upload skill 的上传脚本，**优先外网，内网兜底**：

```bash
# 优先尝试外网地址（prod 环境）
python3 <s3plus_skill_dir>/scripts/upload_to_s3plus.py \
  --file <图片路径> \
  --env prod \
  --object-name "images/<日期>/<文件名>" \
  --output json

# 如果外网上传失败，回退到内网地址（prod-corp 环境）
python3 <s3plus_skill_dir>/scripts/upload_to_s3plus.py \
  --file <图片路径> \
  --env prod-corp \
  --object-name "images/<日期>/<文件名>" \
  --output json
```

其中 `<s3plus_skill_dir>` 是 s3plus-upload skill 的安装路径（通常为 `/app/skills/s3plus-upload`）。

### Step 3: 返回 Markdown 图片

将 S3 URL 包装成 Markdown 图片格式返回给用户：

```markdown
![图片描述](https://s3plus.sankuai.com/bucket/images/2026/0308/screenshot.png)
```

## 返回格式规范

### 单张图片

```markdown
![截图](https://s3plus.sankuai.com/bucket/images/xxx.png)
```

### 多张图片

每张图片之间空一行：

```markdown
![截图1](https://s3plus.sankuai.com/bucket/images/xxx1.png)

![截图2](https://s3plus.sankuai.com/bucket/images/xxx2.png)
```

### 图片 + 文字说明

文字在前，图片在后：

```markdown
当前桌面状态如下：

![桌面截图](https://s3plus.sankuai.com/bucket/images/desktop.png)
```

## 环境优先级

| 优先级 | 环境 | Host | 适用场景 |
|--------|------|------|---------|
| 1 (优先) | prod | s3plus.sankuai.com | 外网可访问 |
| 2 (兜底) | prod-corp | s3plus-corp.sankuai.com | 内网访问 |

## Object Name 命名规范

使用日期分目录，避免文件名冲突：

```
images/<YYYY>/<MMDD>/<原文件名或描述>_<时间戳>.png
```

示例：`images/2026/0308/desktop_screenshot_143058.png`

## 依赖

- **s3plus-upload** skill：提供 S3Plus 上传能力
- Python 3 + requests 库

## 注意事项

- 上传前确认图片文件存在且大小合理（< 50MB）
- 如果用户没有指定图片路径，根据上下文推断（如截图保存路径）
- 外网地址上传失败时不要报错，静默切换到内网地址
- 返回给用户时只展示最终的 Markdown 图片，不要暴露上传过程的细节
