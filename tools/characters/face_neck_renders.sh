#!/bin/bash
# The renders for the whole man's face-and-neck sheet (claude/characters-whole-man-face), one man:
#   tools/characters/face_neck_renders.sh MODEL OUT
# plain light, whole and head close (tools/people_lineup.gd: front, side, three-quarter, back),
# the card table at night (screenshots.gd shot_match_close) and the street at golden hour close
# (man_store_golden). Logs to OUT/*.log; ~20-25 min under lavapipe.
MODEL=$1
OUT=$2
mkdir -p "$OUT"
SHOT="xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd --"
timeout 900 xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/people_lineup.gd -- \
    --out="$OUT/plain" --ids="$MODEL" --poses=stand > "$OUT/plain.log" 2>&1
timeout 900 xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/people_lineup.gd -- \
    --out="$OUT/plain" --ids="$MODEL" --poses=stand --head > "$OUT/plain_head.log" 2>&1
timeout 1500 $SHOT --out="$OUT/table" --only=shot_match_close --model="$MODEL" --fresh > "$OUT/table.log" 2>&1
timeout 1500 $SHOT --out="$OUT/near" --only=man_store_golden --model="$MODEL" --fresh > "$OUT/near.log" 2>&1
ls -R "$OUT" | grep png
