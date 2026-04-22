---
name: xhs-browser-use
description: Use when a user needs to fetch Xiaohongshu (小红书) note content via a local Chrome profile with logged-in cookies using CDP, and download images with title/body/image URLs exported to JSON.

metadata:
  skillhub.creator: "zhuxiangyu04"
  skillhub.updater: "zhuxiangyu04"
  skillhub.version: "V2"
  skillhub.source: "FRIDAY Skillhub"
  skillhub.skill_id: "1414"
  skillhub.high_sensitive: "false"
---

# Xhs Browser Use

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
