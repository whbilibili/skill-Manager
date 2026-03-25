#!/usr/bin/env node
/**
 * TTS Generator for MeiJing Video
 * 
 * Usage:
 *   node tts_generate.js <narration.json> <output_dir> [--voice zh-CN-YunxiaNeural] [--rate -5%]
 * 
 * narration.json format:
 *   [{"id": 1, "start": 0.5, "end": 5.0, "text": "旁白内容"}, ...]
 * 
 * Output: audio_edge/seg_01.mp3, seg_02.mp3, ...
 */

const { EdgeTTS } = require('node-edge-tts');
const fs = require('fs');
const path = require('path');

const PROXY = process.env.HTTPS_PROXY || process.env.https_proxy || '';
const DEFAULT_VOICE = 'zh-CN-YunxiaNeural';
const DEFAULT_RATE = '-5%';

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = {
    narrationFile: null,
    outputDir: null,
    voice: DEFAULT_VOICE,
    rate: DEFAULT_RATE
  };

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--voice' && args[i + 1]) {
      opts.voice = args[++i];
    } else if (args[i] === '--rate' && args[i + 1]) {
      opts.rate = args[++i];
    } else if (!opts.narrationFile) {
      opts.narrationFile = args[i];
    } else if (!opts.outputDir) {
      opts.outputDir = args[i];
    }
  }

  if (!opts.narrationFile) {
    console.error('Usage: node tts_generate.js <narration.json> [output_dir] [--voice VOICE] [--rate RATE]');
    process.exit(1);
  }

  if (!opts.outputDir) {
    opts.outputDir = path.join(path.dirname(opts.narrationFile), 'audio_edge');
  }

  return opts;
}

async function main() {
  const opts = parseArgs();

  const segs = JSON.parse(fs.readFileSync(opts.narrationFile, 'utf8'));
  fs.mkdirSync(opts.outputDir, { recursive: true });

  console.log(`=== TTS Generator ===`);
  console.log(`Voice: ${opts.voice}`);
  console.log(`Rate: ${opts.rate}`);
  console.log(`Proxy: ${PROXY ? 'YES' : 'NO'}`);
  console.log(`Segments: ${segs.length}`);
  console.log();

  for (const seg of segs) {
    const outFile = path.join(opts.outputDir, `seg_${String(seg.id).padStart(2, '0')}.mp3`);

    const ttsOpts = {
      voice: opts.voice,
      timeout: 15000,
      rate: opts.rate
    };
    if (PROXY) ttsOpts.proxy = PROXY;

    const tts = new EdgeTTS(ttsOpts);

    try {
      await tts.ttsPromise(seg.text, outFile);
      console.log(`  ✅ seg ${seg.id}: "${seg.text}" -> ${path.basename(outFile)}`);
    } catch (e) {
      console.error(`  ❌ seg ${seg.id}: ${e.message}`);
    }
  }

  console.log('\nDone!');
}

main();
