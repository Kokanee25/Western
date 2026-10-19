#!/bin/bash
# The renders for the two tests' morning sheet (docs/style_test/two-tests-2026-10-19), one man:
#   tools/characters/two_tests_renders.sh MODEL OUT
# plain light (tools/people_lineup.gd, whole and close), the card table at night
# (screenshots.gd shot_match_close / shot_match_saloon), the saloon at night and the street at
# golden hour (man_saloon_night, man_store_golden) close (3 m) and at game distance (--man-dist).
# Logs to OUT/*.log; a full set is ~30-40 min under lavapipe.
MODEL=$1
OUT=$2
mkdir -p "$OUT"
SHOT="xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/screenshots.gd --"
timeout 900 xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/people_lineup.gd -- \
    --out="$OUT/plain" --ids="$MODEL" --poses=stand > "$OUT/plain.log" 2>&1
timeout 900 xvfb-run -a godot --path . --rendering-driver vulkan -s res://tools/people_lineup.gd -- \
    --out="$OUT/plain" --ids="$MODEL" --poses=stand --head > "$OUT/plain_head.log" 2>&1
timeout 1500 $SHOT --out="$OUT/table" --only=shot_match_close,shot_match_saloon --model="$MODEL" --fresh \
    > "$OUT/table.log" 2>&1
timeout 1500 $SHOT --out="$OUT/near" --only=man_saloon_night,man_store_golden --model="$MODEL" --fresh \
    > "$OUT/near.log" 2>&1
timeout 1500 $SHOT --out="$OUT/saloon_far" --only=man_saloon_night --model="$MODEL" --man-dist=6.5 --fresh \
    > "$OUT/saloon_far.log" 2>&1
timeout 1500 $SHOT --out="$OUT/street_far" --only=man_store_golden --model="$MODEL" --man-dist=12 --fresh \
    > "$OUT/street_far.log" 2>&1
ls -R "$OUT" | grep png
