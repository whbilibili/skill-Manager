#!/bin/bash
# merge_audio.sh - Merge TTS audio segments by time offset
# Usage: bash merge_audio.sh <narration.json> <audio_dir> <output.mp3>
#
# Reads narration.json to get start times, uses adelay to position each segment.

set -e

NARRATION_JSON="$1"
AUDIO_DIR="$2"
OUTPUT="$3"

if [ -z "$NARRATION_JSON" ] || [ -z "$AUDIO_DIR" ] || [ -z "$OUTPUT" ]; then
  echo "Usage: bash merge_audio.sh <narration.json> <audio_dir> <output.mp3>"
  exit 1
fi

# Parse segment count and build ffmpeg command using python
python3 << PYEOF
import json, subprocess, sys

with open("$NARRATION_JSON") as f:
    segs = json.load(f)

valid = []
for seg in segs:
    fp = "$AUDIO_DIR/seg_{:02d}.mp3".format(seg['id'])
    import os
    if os.path.exists(fp):
        valid.append((fp, seg['start']))
    else:
        print(f"  WARN: missing {fp}")

if not valid:
    print("ERROR: no audio segments found")
    sys.exit(1)

cmd = ["ffmpeg", "-y"]
for fp, _ in valid:
    cmd += ["-i", fp]

parts = []
mix_inputs = []
for i, (_, start) in enumerate(valid):
    delay_ms = int(start * 1000)
    parts.append(f"[{i}]adelay={delay_ms}|{delay_ms}[d{i}]")
    mix_inputs.append(f"[d{i}]")

n = len(valid)
filter_str = ";".join(parts) + ";" + "".join(mix_inputs) + f"amix=inputs={n}:duration=longest:dropout_transition=0[out]"

cmd += ["-filter_complex", filter_str, "-map", "[out]", "-ac", "1", "-ar", "44100", "$OUTPUT"]

print(f"  Merging {n} segments...")
result = subprocess.run(cmd, capture_output=True, text=True)
if result.returncode != 0:
    print("ERROR:", result.stderr[-500:])
    sys.exit(1)

import os
dur_result = subprocess.run(
    ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", "$OUTPUT"],
    capture_output=True, text=True
)
print(f"  ✅ Output: $OUTPUT ({float(dur_result.stdout.strip()):.1f}s)")
PYEOF
