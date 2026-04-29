---
name: xhs-browser-use
description: Use when a user needs to fetch Xiaohongshu (小红书) note content via a local Chrome profile with logged-in cookies using CDP, and download images with title/body/image URLs exported to JSON.

metadata:
  skillhub.creator: "zhuxiangyu04"
  skillhub.updater: "chenshengtao"
  skillhub.version: "V7"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "1414"
  skillhub.high_sensitive: "false"
---

# Xhs Browser Use

---

## 环境准备

**在执行任何操作前，按顺序完成以下准备：**

### 1. 检查 meigen-cli

执行 `meigen --version`，确认版本号 **>= 1.4.1**。

- **未安装**（命令不存在）：询问用户是否安装 meigen-cli，用户同意后执行 `npm install -g @meigen/meigen-cli@latest`
- **版本过低**：询问用户是否升级 meigen-cli，用户同意后执行 `npm install -g @meigen/meigen-cli@latest`

### 2. 同步 Skill 版本

```bash
DIRNAME="$(cd "$(dirname "<this-skill-md>")/.." && pwd)"
meigen sync "$DIRNAME" xhs-browser-use
```

| 退出码 | stderr 关键词 | 含义 | 后续动作 |
|-------|-------------|------|---------|
| 0 | `已是最新` / `已更新` / `已安装` | 正常 | 继续下一步 |
| 2 | `未检测到 mtskills` | 缺少依赖 | 用 `AskUserQuestion` 询问用户是否安装：`npm install -g @mtfe/mtskills --registry=http://r.npm.sankuai.com`，用户同意后执行安装，再重新执行 `meigen sync` |
| 1 | `失败` / `更新失败` | 同步异常 | 跳过同步继续（不阻塞） |

### 3. 确认脚本目录

```bash
SCRIPT_DIR="$(cd "$(dirname "<this-skill-md>")" && pwd)/scripts"
```

---

## Overview
Use local Chrome (CDP) to open a note URL and export `title`, `body`, `image_urls`, and `image_files` while saving images locally.

## Workflow
1. Ensure Node 18+ and dependencies are available (`npm install` in the repo).  
   - Image conversion defaults to PNG, so `sharp` is required.
2. Run the script from this skill:
   ```bash
   node skills/xhs-browser-use/scripts/xhs-browser-use.mjs "<小红书链接>" --out output
   ```
   - The script auto-launches Chrome with the specified profile if CDP is not running.
   - If Chrome is already open with the same profile, close it or set `--profile-dir` / `--user-data-dir`.
   - Upload to sankuai.com is enabled only when `IMAGE_UPLOAD_URL` is set (via `.env` or environment); use `--no-upload-sankuai` to disable even if configured.
3. Read results from `output/xhs-<noteId>/note.json` and the downloaded images.

## Parameters
- `--out` output directory (default: `output`).
- `--image-format` saved image format: `png|jpg|original` (default: `png`).
- `--cdp` CDP base URL (connect-only, no auto-launch).
- `--cdp-port` port used when auto-launching (default: `9222`).
- `--chrome-path` path to Chrome binary (macOS default is built in).
- `--user-data-dir` Chrome user data directory (default: `~/Library/Application Support/Google/Chrome`).
- `--profile-dir` Chrome profile directory (default: `Default`).
- `--keep-chrome` leave Chrome running if the script started it.
- `--no-upload-sankuai` disable image URL upload even if `IMAGE_UPLOAD_URL` is set.
- Upload requires `IMAGE_UPLOAD_URL` to be set (via `.env` or environment).

## Output
- `note.json` fields: `title`, `body`, `image_urls`, `image_files`.
- Images are saved as `image-01.png`, `image-02.png`, etc. by default.
- When upload is enabled (`IMAGE_UPLOAD_URL` configured and not disabled), upload is based on downloaded local images (after conversion).  
  `note.json` adds `image_urls_raw` (original URLs) and `image_urls` uses uploaded URLs (order preserved; failed uploads fall back to original URLs).
