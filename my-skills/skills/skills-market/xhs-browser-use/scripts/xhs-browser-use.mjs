#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';
import os from 'node:os';
import { spawn } from 'node:child_process';
import { chromium } from 'playwright';

const args = process.argv.slice(2);
if (!args[0] || args.includes('-h') || args.includes('--help')) {
  console.log(`Usage: node scripts/xhs-browser-use.mjs <xhs_url> [options]

Options:
  --out <dir>        Output directory (default: output)
  --cdp <url>        Connect to existing Chrome CDP
  --cdp-port <port>        CDP port when auto-launching (default: 9222)
  --image-format <fmt>     Saved image format: png|jpg|original (default: png)
  --chrome-path <path>     Chrome binary path
  --user-data-dir <dir>    Chrome user data directory (default: ~/.xhs-browser-chrome-data)
  --profile-dir <name>     Chrome profile directory (default: Default)
  --keep-chrome      Keep Chrome running after script exits (default behavior)
  --close-chrome     Close Chrome process if this script launched it
  --connect-only       Only connect to existing Chrome
  --no-upload-sankuai   Disable uploading image_urls (requires IMAGE_UPLOAD_URL)

Note: Uses isolated Chrome profile to avoid conflicts. Login once when first running.
`);

  process.exit(args[0] ? 0 : 1);
}

const url = args[0];
const outDir = getArgValue(args, '--out') || 'output';
const cdpUrlArg = getArgValue(args, '--cdp');
const cdpPortArg = getArgValue(args, '--cdp-port');
const imageFormat = (getArgValue(args, '--image-format') || 'png').toLowerCase();
const chromePath = getArgValue(args, '--chrome-path') || defaultChromePath();
const userDataDir = expandHome(
  getArgValue(args, '--user-data-dir') || path.join(os.homedir(), '.xhs-browser-chrome-data')
);
const profileDir = getArgValue(args, '--profile-dir') || 'Default';
const keepChrome = !args.includes('--close-chrome');
const connectOnly = args.includes('--connect-only') || Boolean(cdpUrlArg);
const uploadUrl = await resolveUploadUrl();
const uploadSankuai = !args.includes('--no-upload-sankuai') && Boolean(uploadUrl);

let port = cdpPortArg || '9222';
if (!['png', 'jpg', 'original'].includes(imageFormat)) {
  throw new Error(`Invalid --image-format "${imageFormat}". Expected one of: png, jpg, original.`);
}
if (!cdpPortArg && cdpUrlArg) {
  try {
    port = new URL(cdpUrlArg).port || port;
  } catch {
    // Ignore invalid URL
  }
}
const cdpUrl = cdpUrlArg || `http://127.0.0.1:${port}`;

const noteId = extractNoteId(url) || `run-${new Date().toISOString().replace(/[:.]/g, '-')}`;
const baseDir = path.resolve(outDir, `xhs-${noteId}`);
await fs.mkdir(baseDir, { recursive: true });

const responseJson = [];
let chromeProcess = null;
let browser = null;
let sharpModule = null;

try {
  browser = await tryConnect(cdpUrl);
  if (!browser) {
    if (connectOnly) {
      throw new Error(`CDP not available at ${cdpUrl}. Start Chrome with --remote-debugging-port or drop --cdp to auto-launch.`);
    }
    chromeProcess = launchChrome({ chromePath, userDataDir, profileDir, port });
    await waitForCdp(cdpUrl, 20000);
    browser = await chromium.connectOverCDP(cdpUrl);
  }

  const context = browser.contexts()[0];
  if (!context) {
    throw new Error('No browser context found. Ensure Chrome is started with a user profile and CDP enabled.');
  }

  context.on('response', async (response) => {
    try {
      const headers = response.headers();
      const contentType = headers['content-type'] || '';
      if (!contentType.includes('application/json')) return;
      const data = await response.json();
      responseJson.push({ url: response.url(), data });
    } catch {
      // Ignore JSON parse failures
    }
  });

  const page = await context.newPage();
  await page.goto(url, { waitUntil: 'domcontentloaded', timeout: 60000 });
  try {
    await page.waitForSelector('#detail-title, #detail-desc', { timeout: 8000 });
  } catch {
    // Selector may not appear on some pages; fall back to metadata/JSON extraction.
  }
  await page.waitForTimeout(2000);

  const pageMeta = await page.evaluate(() => {
    const pickMeta = (key) =>
      document.querySelector(`meta[property="${key}"]`)?.content ||
      document.querySelector(`meta[name="${key}"]`)?.content ||
      '';
    const title = pickMeta('og:title') || document.title || '';
    const description = pickMeta('description') || pickMeta('og:description') || '';
    const metaImages = Array.from(
      document.querySelectorAll('meta[property="og:image"], meta[name="og:image"]')
    )
      .map((el) => el.content)
      .filter(Boolean);
    return { title, description, metaImages };
  });

  const pageState = await page.evaluate(() => {
    const roots = [];
    if (window.__INITIAL_STATE__) roots.push(window.__INITIAL_STATE__);
    if (window.__NUXT__) roots.push(window.__NUXT__);
    if (window.__NEXT_DATA__) roots.push(window.__NEXT_DATA__);

    const titleKeys = new Set(['title', 'noteTitle', 'displayTitle', 'name']);
    const bodyKeys = new Set(['desc', 'noteDesc', 'noteContent', 'content', 'description']);

    const isCommentKey = (key) => {
      const k = String(key || '').toLowerCase();
      if (!k) return false;
      if (k === 'comment' || k === 'comments' || k === 'commentlist' || k === 'comment_list') return true;
      if (k === 'commentid' || k === 'comment_id') return true;
      if (k === 'reply' || k === 'replies' || k === 'replylist' || k === 'reply_list') return true;
      if (k === 'subcomment' || k === 'sub_comment' || k === 'subcomments') return true;
      if (k.includes('comment') && (k.endsWith('list') || k.endsWith('detail') || k.endsWith('ids'))) return true;
      if (k.includes('reply') && (k.endsWith('list') || k.endsWith('detail'))) return true;
      return false;
    };
    const queue = roots.map((node) => ({ node, inComment: false }));
    const seen = new WeakSet();
    const maxNodes = 6000;
    let visited = 0;
    let best = { title: '', body: '', images: [], score: -999 };

    const looksLikeImage = (value) => {
      if (!value || typeof value !== 'string') return false;
      if (!value.startsWith('http')) return false;
      const lowered = value.toLowerCase();
      if (lowered.includes('avatar') || lowered.includes('logo')) return false;
      return /(jpg|jpeg|png|webp|gif)(\\?|$)/.test(lowered) || lowered.includes('xhscdn') || lowered.includes('xhs');
    };

    const extractImagesFromList = (list) => {
      if (!Array.isArray(list)) return [];
      const urls = [];
      for (const item of list) {
        if (!item) continue;
        if (typeof item === 'string' && looksLikeImage(item)) {
          urls.push(item.split('#')[0]);
          continue;
        }
        if (typeof item === 'object') {
          const candidates = [
            item.url,
            item.urlDefault,
            item.url_default,
            item.original,
            item.originalUrl,
            item.origin,
            item.originUrl,
            item.urlList && Array.isArray(item.urlList) ? item.urlList[0] : '',
          ].filter(Boolean);
          for (const url of candidates) {
            if (looksLikeImage(url)) urls.push(url.split('#')[0]);
          }
        }
      }
      return urls;
    };

    const scoreCandidate = (node, title, body, images) => {
      const hasNoteId = node && typeof node === 'object' && ('noteId' in node || 'note_id' in node || 'noteID' in node);
      let score = (title ? 4 : 0) + (body ? 4 : 0) + Math.min(images.length, 10);
      if (hasNoteId) score += 2;
      if (body && body.length > 40) score += 1;
      if (body && body.length > 120) score += 1;
      return score;
    };

    while (queue.length && visited < maxNodes) {
      const { node: current, inComment } = queue.shift();
      if (!current || typeof current !== 'object') continue;
      if (seen.has(current)) continue;
      seen.add(current);
      visited += 1;

      if (Array.isArray(current)) {
        for (const item of current) {
          if (item && typeof item === 'object') queue.push({ node: item, inComment });
        }
        continue;
      }

      const keys = Object.keys(current);
      const isCommentBlock = inComment || keys.some((key) => isCommentKey(key));

      const holder =
        current.noteCard && typeof current.noteCard === 'object'
          ? current.noteCard
          : current.note && typeof current.note === 'object'
            ? current.note
            : current.noteDetail && typeof current.noteDetail === 'object'
              ? current.noteDetail
              : current;

      const title = titleKeys.has('title') && typeof holder.title === 'string' ? holder.title.trim() : '';
      const fallbackTitle =
        title ||
        (typeof holder.noteTitle === 'string' ? holder.noteTitle.trim() : '') ||
        (typeof holder.displayTitle === 'string' ? holder.displayTitle.trim() : '') ||
        (typeof holder.name === 'string' ? holder.name.trim() : '');
      const body =
        (typeof holder.desc === 'string' && holder.desc.trim()) ||
        (typeof holder.noteDesc === 'string' && holder.noteDesc.trim()) ||
        (typeof holder.noteContent === 'string' && holder.noteContent.trim()) ||
        (typeof holder.content === 'string' && holder.content.trim()) ||
        (typeof holder.description === 'string' && holder.description.trim()) ||
        '';

      const list =
        holder.imageList ||
        holder.image_list ||
        holder.images ||
        holder.imageInfos ||
        holder.image_infos ||
        null;
      const images = extractImagesFromList(list);

      if (!isCommentBlock) {
        const score = scoreCandidate(holder, fallbackTitle, body, images);
        if (score > best.score) {
          best = { title: fallbackTitle, body, images, score };
        }
      }

      for (const [key, value] of Object.entries(current)) {
        if (value && typeof value === 'object') {
          queue.push({ node: value, inComment: isCommentBlock || isCommentKey(key) });
        }
      }
    }

    return best;
  });

  const domNote = await page.evaluate(() => {
    const titleEl =
      document.querySelector('#detail-title') ||
      document.querySelector('.note-content .title') ||
      document.querySelector('.note-content .note-title');
    const title = titleEl?.textContent?.trim() || '';

    const descRoot =
      document.querySelector('#detail-desc') ||
      document.querySelector('.note-content .desc') ||
      document.querySelector('.note-content .content');
    let body = '';
    if (descRoot) {
      body = (descRoot.innerText || descRoot.textContent || '').trim();
      body = body.replace(/\s+\n/g, '\n').replace(/\n{3,}/g, '\n\n');
    }

    const isInComment = (el) => {
      let cur = el;
      while (cur && cur.nodeType === 1) {
        const id = (cur.id || '').toLowerCase();
        const cls = String(cur.className || '').toLowerCase();
        if (id.includes('comment') || cls.includes('comment') || cls.includes('reply')) return true;
        cur = cur.parentElement;
      }
      return false;
    };

    const isUiImage = (img, src) => {
      const cls = (img.getAttribute('class') || '').toLowerCase();
      const alt = (img.getAttribute('alt') || '').toLowerCase();
      if (cls.includes('emoji') || cls.includes('icon') || cls.includes('logo') || cls.includes('avatar')) return true;
      if (alt.includes('emoji') || alt.includes('icon')) return true;
      if (/picasso-static\.xiaohongshu\.com\/fe-platform/i.test(src)) return true;
      if (/\/comment\//i.test(src)) return true;
      const rect = img.getBoundingClientRect();
      if (rect.width && rect.height && Math.min(rect.width, rect.height) < 60) return true;
      return false;
    };

    const collectImages = (roots) => {
      const urls = [];
      const seen = new Set();
      for (const root of roots) {
        if (!root) continue;
        const imgs = Array.from(root.querySelectorAll('img'));
        for (const img of imgs) {
          const src = img.getAttribute('src') || '';
          if (!src || !src.startsWith('http')) continue;
          if (isInComment(img)) continue;
          if (isUiImage(img, src)) continue;
          const normalized = src.split('#')[0].replace(/^http:/i, 'https:');
          if (!seen.has(normalized)) {
            seen.add(normalized);
            urls.push(normalized);
          }
        }
      }
      return urls;
    };

    const collectCarouselImages = () => {
      const slides = Array.from(
        document.querySelectorAll('.swiper-wrapper .swiper-slide[data-swiper-slide-index]')
      );
      const pairs = [];
      const seenIdx = new Set();
      for (const slide of slides) {
        const cls = String(slide.getAttribute('class') || '').toLowerCase();
        if (cls.includes('duplicate')) continue;
        const rawIndex = slide.getAttribute('data-swiper-slide-index');
        const idx = Number(rawIndex);
        if (!Number.isFinite(idx)) continue;
        if (seenIdx.has(idx)) continue;
        const img =
          slide.querySelector('.img-container img') ||
          slide.querySelector('.img-containner img') ||
          slide.querySelector('img');
        const src = img?.getAttribute('src') || '';
        if (!src || !src.startsWith('http')) continue;
        if (isUiImage(img, src)) continue;
        const normalized = src.split('#')[0].replace(/^http:/i, 'https:');
        pairs.push({ idx, url: normalized });
        seenIdx.add(idx);
      }
      pairs.sort((a, b) => a.idx - b.idx);
      return pairs.map((item) => item.url);
    };

    const mediaRoots = [
      document.querySelector('#noteContainer .media-container'),
      document.querySelector('#noteContainer .note-scroller .media-container'),
      document.querySelector('.media-container'),
      document.querySelector('.note-media'),
      document.querySelector('.note-content .media-container'),
    ];

    let imageUrls = collectImages(mediaRoots);
    if (!imageUrls.length) {
      const fallbackRoots = [
        document.querySelector('#noteContainer'),
        document.querySelector('.note-content'),
      ];
      imageUrls = collectImages(fallbackRoots);
    }

    const carouselImageUrls = collectCarouselImages();

    return { title, body, imageUrls, carouselImageUrls };
  });

  const candidates = [];
  if (domNote && (domNote.title || domNote.body || (domNote.imageUrls || []).length)) {
    candidates.push({
      data: {
        title: domNote.title,
        desc: domNote.body,
        imageList: domNote.imageUrls,
      },
      url: 'dom',
      source: 'dom',
    });
  }
  if (pageState) candidates.push({ data: pageState, url: 'pageState', source: 'page' });
  for (const item of responseJson) candidates.push({ data: item.data, url: item.url, source: 'response' });

  const best = pickBestCandidate(candidates);
  const title = best.title || pageMeta.title || '';
  const body = best.body || pageMeta.description || '';
  // Prefer carousel order extracted from swiper slide indexes (index 0 is cover).
  // Fall back to structured note data, then general DOM and metadata.
  const carouselOrderedImages = dedupeUrls(domNote?.carouselImageUrls || []);
  const extractedImages = dedupeUrls(best.images || []);
  const domOrderedImages = dedupeUrls(domNote?.imageUrls || []);
  const imageUrls = carouselOrderedImages.length
    ? dedupeUrls([
      ...carouselOrderedImages,
      ...extractedImages,
      ...domOrderedImages,
      ...pageMeta.metaImages,
    ])
    : extractedImages.length
      ? extractedImages
    : domOrderedImages.length
      ? domOrderedImages
    : dedupeUrls([
      ...pageMeta.metaImages,
    ]);

  const downloadedRecords = await downloadImages(imageUrls, baseDir, context, imageFormat);
  const downloaded = downloadedRecords.map((item) => item.filePath);
  const uploadedMap = uploadSankuai ? await uploadDownloadedImagesToSankuai(downloadedRecords) : new Map();
  const finalImageUrls = uploadSankuai
    ? imageUrls.map((rawUrl) => uploadedMap.get(rawUrl) || rawUrl)
    : imageUrls;

  const output = {
    url,
    title,
    body,
    image_urls: finalImageUrls,
    image_urls_raw: uploadSankuai ? imageUrls : undefined,
    image_files: downloaded,
  };

  await fs.writeFile(path.join(baseDir, 'note.json'), JSON.stringify(output, null, 2));

  console.log(`Saved to ${baseDir}`);
} finally {
  if (browser) {
    if (typeof browser.disconnect === 'function') {
      await browser.disconnect();
    } else {
      await browser.close();
    }
  }
  if (chromeProcess && !keepChrome) {
    stopChrome(chromeProcess);
  }
}

function getArgValue(argv, key) {
  const idx = argv.indexOf(key);
  if (idx === -1) return null;
  return argv[idx + 1];
}

function defaultChromePath() {
  return '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
}

function expandHome(input) {
  if (!input) return input;
  if (input.startsWith('~')) return path.join(os.homedir(), input.slice(1));
  return input;
}

function extractNoteId(input) {
  const match = input.match(/\/explore\/([a-zA-Z0-9]+)/) || input.match(/\/item\/([a-zA-Z0-9]+)/);
  return match ? match[1] : null;
}

async function tryConnect(url) {
  try {
    return await chromium.connectOverCDP(url);
  } catch {
    return null;
  }
}

function launchChrome({ chromePath, userDataDir, profileDir, port }) {
  const args = [
    `--remote-debugging-port=${port}`,
    `--user-data-dir=${userDataDir}`,
    `--profile-directory=${profileDir}`,
    '--no-first-run',
    '--no-default-browser-check',
  ];
  const child = spawn(chromePath, args, {
    detached: true,
    stdio: 'ignore',
  });
  child.unref();
  return child;
}

async function waitForCdp(baseUrl, timeoutMs) {
  const deadline = Date.now() + timeoutMs;
  const statusUrl = new URL('/json/version', baseUrl).toString();
  while (Date.now() < deadline) {
    try {
      const res = await fetch(statusUrl);
      if (res.ok) return;
    } catch {
      // Keep retrying
    }
    await new Promise((resolve) => setTimeout(resolve, 500));
  }
  throw new Error(
    `Failed to start Chrome with remote debugging on port ${port}.\n` +
    `  User data dir: ${userDataDir}\n` +
    `  Profile: ${profileDir}\n\n` +
    `Troubleshooting:\n` +
    `  1. Check if another Chrome instance is using port ${port}: lsof -i :${port}\n` +
    `  2. Try a different port: --cdp-port 9223\n` +
    `  3. Clean up lock files: rm -rf "${userDataDir}/SingletonLock"\n` +
    `4. Use --cdp to connect to existing Chrome instead of launching new one`
  );
}

function stopChrome(proc) {
  try {
    if (proc.pid) process.kill(-proc.pid);
  } catch {
    try {
      proc.kill('SIGTERM');
    } catch {
      // Ignore kill errors
    }
  }
}

function pickBestCandidate(items) {
  let best = { title: '', body: '', images: [], score: -999 };
  for (const item of items) {
    if (!item || typeof item !== 'object') continue;
    const candidate = extractCandidate(item.data, { url: item.url, source: item.source });
    if (candidate.score > best.score) best = candidate;
  }
  return best;
}

function extractCandidate(root, meta = {}) {
  const candidates = [];
  const queue = [{ node: root, path: '' }];
  const seen = new Set();
  const isCommentKey = (key) => {
    const k = String(key || '').toLowerCase();
    if (!k) return false;
    if (k === 'comment' || k === 'comments' || k === 'commentlist' || k === 'comment_list') return true;
    if (k === 'commentid' || k === 'comment_id') return true;
    if (k === 'reply' || k === 'replies' || k === 'replylist' || k === 'reply_list') return true;
    if (k === 'subcomment' || k === 'sub_comment' || k === 'subcomments') return true;
    if (k.includes('comment') && (k.endsWith('list') || k.endsWith('detail') || k.endsWith('ids'))) return true;
    if (k.includes('reply') && (k.endsWith('list') || k.endsWith('detail'))) return true;
    return false;
  };

  while (queue.length) {
    const { node, path } = queue.shift();
    if (!node || typeof node !== 'object') continue;
    if (seen.has(node)) continue;
    seen.add(node);

    if (Array.isArray(node)) {
      for (let i = 0; i < node.length; i += 1) {
        const item = node[i];
        if (item && typeof item === 'object') queue.push({ node: item, path: `${path}[${i}]` });
      }
      continue;
    }

    if (isNoteLike(node)) {
      candidates.push({ node, path });
    }

    for (const [key, value] of Object.entries(node)) {
      if (value && typeof value === 'object') queue.push({ node: value, path: path ? `${path}.${key}` : key });
    }
  }

  if (!candidates.length) candidates.push({ node: root, path: '' });

  let best = { title: '', body: '', images: [], score: -999 };
  for (const { node, path } of candidates) {
    const holder = unwrapNote(node);
    const title = pickString(holder, ['title', 'noteTitle', 'displayTitle', 'name']);
    const body = pickString(holder, ['desc', 'noteDesc', 'noteContent', 'content', 'description', 'body']);
    const images = extractImages(holder);

    let score = 0;
    score += title ? 4 : 0;
    score += body ? 4 : 0;
    score += Math.min(images.length, 10);
    if (hasNoteId(node) || hasNoteId(holder)) score += 2;
    if (body && body.length > 40) score += 1;
    if (body && body.length > 120) score += 1;
    if (title && title.length > 6) score += 1;

    const url = meta.url || '';
    if (meta.source === 'response') score += 1;
    if (meta.source === 'page') score -= 1;
    if (/(\/|_|-)comment/i.test(url)) score -= 6;
    if (/(\/|_|-)note/i.test(url)) score += 2;
    if (isCommentKey(path.split('.').pop())) score -= 4;
    if (isCommentObject(node) || isCommentObject(holder)) score -= 4;

    if (score > best.score) best = { title: title || '', body: body || '', images, score };
  }

  return best;
}

function unwrapNote(node) {
  if (node && typeof node === 'object') {
    if (node.noteCard && typeof node.noteCard === 'object') return node.noteCard;
    if (node.note && typeof node.note === 'object') return node.note;
    if (node.noteDetail && typeof node.noteDetail === 'object') return node.noteDetail;
    if (node.note_detail && typeof node.note_detail === 'object') return node.note_detail;
    if (node.data && typeof node.data === 'object' && isNoteLike(node.data)) return node.data;
  }
  return node;
}

function pickString(node, keys) {
  if (!node || typeof node !== 'object') return '';
  for (const key of keys) {
    const value = node[key];
    if (typeof value === 'string' && value.trim()) return value.trim();
  }
  return '';
}

function hasNoteId(node) {
  if (!node || typeof node !== 'object') return false;
  return Boolean(node.noteId || node.note_id || node.noteID || node.id);
}

function isNoteLike(node) {
  if (!node || typeof node !== 'object') return false;
  const keys = Object.keys(node);
  const keySet = new Set(keys);
  if (keySet.has('note') || keySet.has('noteCard') || keySet.has('noteDetail')) return true;
  if (keySet.has('noteId') || keySet.has('note_id') || keySet.has('noteID')) return true;
  if (keySet.has('noteDesc') || keySet.has('noteContent') || keySet.has('desc')) return true;
  if (keySet.has('imageList') || keySet.has('image_list') || keySet.has('imageInfos') || keySet.has('images'))
    return true;
  return false;
}

function isCommentObject(node) {
  if (!node || typeof node !== 'object') return false;
  return Boolean(
    node.comment || node.comments || node.commentId || node.comment_id || node.commentList || node.reply
  );
}

function extractImages(node) {
  if (!node || typeof node !== 'object') return [];
  const list =
    node.imageList ||
    node.image_list ||
    node.images ||
    node.imageInfos ||
    node.image_infos ||
    null;
  const fromList = extractImagesFromList(list);
  if (fromList.length) return fromList;
  return collectImageUrls(node);
}

function extractImagesFromList(list) {
  if (!Array.isArray(list)) return [];
  const urls = [];
  for (const item of list) {
    if (!item) continue;
    if (typeof item === 'string') {
      if (looksLikeImageUrl(item)) urls.push(normalizeUrl(item));
      continue;
    }
    if (typeof item !== 'object') continue;
    const candidates = [
      item.url,
      item.urlDefault,
      item.url_default,
      item.original,
      item.originalUrl,
      item.origin,
      item.originUrl,
      item.fileUrl,
      item.file_url,
      item.urlList && Array.isArray(item.urlList) ? item.urlList[0] : '',
      item.url_list && Array.isArray(item.url_list) ? item.url_list[0] : '',
    ].filter(Boolean);
    for (const url of candidates) {
      if (looksLikeImageUrl(url)) urls.push(normalizeUrl(url));
    }
  }
  return urls;
}

function collectImageUrls(root) {
  const urls = new Set();
  const queue = [{ node: root, inComment: false }];
  const seen = new Set();
  const isCommentKey = (key) => {
    const k = String(key || '').toLowerCase();
    if (!k) return false;
    if (k === 'comment' || k === 'comments' || k === 'commentlist' || k === 'comment_list') return true;
    if (k === 'commentid' || k === 'comment_id') return true;
    if (k === 'reply' || k === 'replies' || k === 'replylist' || k === 'reply_list') return true;
    if (k === 'subcomment' || k === 'sub_comment' || k === 'subcomments') return true;
    if (k.includes('comment') && (k.endsWith('list') || k.endsWith('detail') || k.endsWith('ids'))) return true;
    if (k.includes('reply') && (k.endsWith('list') || k.endsWith('detail'))) return true;
    return false;
  };

  while (queue.length) {
    const { node, inComment } = queue.shift();
    if (!node || typeof node !== 'object') continue;
    if (seen.has(node)) continue;
    seen.add(node);

    if (inComment) continue;

    if (Array.isArray(node)) {
      for (const item of node) {
        if (item && typeof item === 'object') queue.push({ node: item, inComment });
      }
      continue;
    }

    for (const [key, value] of Object.entries(node)) {
      const nextInComment = inComment || isCommentKey(key) || isCommentObject(value);
      if (typeof value === 'string') {
        if (!nextInComment && looksLikeImageUrl(value)) urls.add(normalizeUrl(value));
      } else if (value && typeof value === 'object') {
        queue.push({ node: value, inComment: nextInComment });
      }
    }
  }
  return Array.from(urls);
}

function looksLikeImageUrl(value) {
  if (!value.startsWith('http')) return false;
  const lowered = value.toLowerCase();
  if (lowered.includes('avatar') || lowered.includes('logo')) return false;
  return /\.(jpg|jpeg|png|webp|gif)(\?|$)/.test(lowered) || lowered.includes('xhscdn') || lowered.includes('xhs');
}

function normalizeUrl(value) {
  const trimmed = value.split('#')[0];
  return trimmed;
}

function dedupeUrls(list) {
  const seen = new Set();
  const out = [];
  for (const raw of list.filter(Boolean)) {
    let url = raw.split('#')[0];
    if (url.startsWith('http:')) url = `https:${url.slice(5)}`;
    if (!seen.has(url)) {
      seen.add(url);
      out.push(url);
    }
  }
  return out;
}

async function uploadDownloadedImagesToSankuai(records) {
  const uploaded = new Map();
  if (!records.length || !uploadUrl) return uploaded;

  for (const item of records) {
    const { sourceUrl, filePath } = item;
    try {
      const body = await fs.readFile(filePath);
      const base64Content = body.toString('base64');
      const result = await uploadImageToSankuai({ base64Content });
      if (result) uploaded.set(sourceUrl, result);
    } catch {
      uploaded.set(sourceUrl, sourceUrl);
    }
  }
  return uploaded;
}

async function uploadImageToSankuai({ imageUrl, base64Content }) {
  if (!imageUrl && !base64Content) {
    throw new Error('uploadImageToSankuai requires imageUrl or base64Content');
  }
  if (!uploadUrl) {
    throw new Error('IMAGE_UPLOAD_URL is not configured');
  }

  const payload = imageUrl ? { imageUrl } : { content: base64Content };
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 30000);

  try {
    const response = await fetch(uploadUrl, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(payload),
      signal: controller.signal,
    });

    if (!response.ok) {
      throw new Error(`Sankuai upload failed with HTTP ${response.status}`);
    }

    const data = await response.json();
    if (data?.code !== 0) {
      throw new Error(`Sankuai upload failed: ${data?.message || 'Unknown error'}`);
    }

    let resultUrl = data?.result?.imageUrl || '';
    if (resultUrl.includes('p.vip.sankuai.com')) {
      resultUrl = resultUrl.replace('p.vip.sankuai.com', 'p0.meituan.net');
    }
    return resultUrl || null;
  } finally {
    clearTimeout(timeout);
  }
}

async function downloadImages(urls, baseDir, context, targetFormat = 'png') {
  if (targetFormat !== 'original') {
    await getSharp(true);
  }
  const saved = [];
  for (let i = 0; i < urls.length; i += 1) {
    const url = urls[i];
    try {
      const response = await context.request.get(url);
      if (!response.ok()) continue;
      const contentType = response.headers()['content-type'] || '';
      const body = await response.body();
      let ext = contentTypeToExt(contentType) || guessExt(url) || 'jpg';
      let output = body;

      if (targetFormat === 'png' || targetFormat === 'jpg') {
        const normalizedTarget = targetFormat === 'jpg' ? 'jpg' : 'png';
        const sharp = await getSharp(true);
        if (normalizedTarget === 'png') {
          output = await sharp(body).png().toBuffer();
          ext = 'png';
        } else {
          output = await sharp(body).jpeg({ quality: 90 }).toBuffer();
          ext = 'jpg';
        }
      } else if (isWebp(contentType, ext)) {
        // Keep legacy behavior for --image-format original, but keep extension stable.
        ext = 'webp';
      }

      const filename = `image-${String(i + 1).padStart(2, '0')}.${ext}`;
      const target = path.join(baseDir, filename);
      await fs.writeFile(target, output);
      saved.push({ sourceUrl: url, filePath: target });
    } catch {
      // Skip download errors
    }
  }
  return saved;
}

function contentTypeToExt(contentType) {
  if (contentType.includes('image/jpeg')) return 'jpg';
  if (contentType.includes('image/png')) return 'png';
  if (contentType.includes('image/webp')) return 'webp';
  if (contentType.includes('image/gif')) return 'gif';
  return '';
}

function guessExt(url) {
  const match = url.match(/\.(jpg|jpeg|png|webp|gif)(\?|$)/i);
  return match ? match[1].toLowerCase().replace('jpeg', 'jpg') : '';
}

function isWebp(contentType, ext) {
  return contentType.includes('image/webp') || ext === 'webp';
}

async function getSharp(required = false) {
  if (sharpModule) return sharpModule;
  try {
    const mod = await import('sharp');
    sharpModule = mod.default || mod;
    return sharpModule;
  } catch {
    if (required) {
      throw new Error('sharp is required for image conversion. Run: npm install sharp');
    }
    return null;
  }
}

function parseEnvValue(content, key) {
  const lines = content.split(/\r?\n/);
  for (const rawLine of lines) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const idx = line.indexOf('=');
    if (idx === -1) continue;
    const k = line.slice(0, idx).trim();
    if (k !== key) continue;
    let value = line.slice(idx + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    return value;
  }
  return '';
}

async function resolveUploadUrl() {
  const key = 'IMAGE_UPLOAD_URL';
  if (process.env[key]) return process.env[key].trim();
  try {
    const envPath = path.resolve(process.cwd(), '.env');
    const content = await fs.readFile(envPath, 'utf8');
    const value = parseEnvValue(content, key);
    if (value) {
      process.env[key] = value;
      return value;
    }
  } catch {
    // ignore missing or unreadable .env
  }
  return '';
}
