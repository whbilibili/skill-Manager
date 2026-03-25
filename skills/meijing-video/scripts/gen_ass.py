#!/usr/bin/env python3
"""
Generate ASS subtitle file from narration JSON.
Usage: python3 gen_ass.py <narration.json> [output.ass] [--width 1344] [--height 768] [--fontsize 40]
"""
import json, sys, argparse

def fmt_ass_time(s):
    h = int(s // 3600)
    m = int((s % 3600) // 60)
    sec = int(s % 60)
    cs = int((s % 1) * 100)
    return f"{h}:{m:02d}:{sec:02d}.{cs:02d}"

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("narration_json")
    parser.add_argument("output_ass", nargs="?", default=None)
    parser.add_argument("--width", type=int, default=1344)
    parser.add_argument("--height", type=int, default=768)
    parser.add_argument("--fontsize", type=int, default=40)
    parser.add_argument("--font", default="Noto Serif CJK SC")
    args = parser.parse_args()

    with open(args.narration_json, encoding="utf-8") as f:
        segs = json.load(f)

    if args.output_ass is None:
        import os
        args.output_ass = os.path.join(os.path.dirname(args.narration_json), "narration.ass")

    header = f"""[Script Info]
Title: Narration
ScriptType: v4.00+
WrapStyle: 0
ScaledBorderAndShadow: yes
YCbCr Matrix: TV.709
PlayResX: {args.width}
PlayResY: {args.height}

[V4+ Styles]
Format: Name, Fontname, Fontsize, PrimaryColour, SecondaryColour, OutlineColour, BackColour, Bold, Italic, Underline, StrikeOut, ScaleX, ScaleY, Spacing, Angle, BorderStyle, Outline, Shadow, Alignment, MarginL, MarginR, MarginV, Encoding
Style: Default,{args.font},{args.fontsize},&H00FFFFFF,&H000000FF,&H00000000,&H80000000,-1,0,0,0,100,100,0,0,1,3,1,2,20,20,50,1

[Events]
Format: Layer, Start, End, Style, Name, MarginL, MarginR, MarginV, Effect, Text
"""

    events = []
    for seg in segs:
        events.append(
            f"Dialogue: 0,{fmt_ass_time(seg['start'])},{fmt_ass_time(seg['end'])},Default,,0,0,0,,{seg['text']}"
        )

    with open(args.output_ass, "w", encoding="utf-8") as f:
        f.write(header)
        f.write("\n".join(events))
        f.write("\n")

    print(f"✅ Generated {args.output_ass} ({len(segs)} subtitles)")

if __name__ == "__main__":
    main()
