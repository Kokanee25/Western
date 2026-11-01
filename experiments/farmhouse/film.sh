#!/bin/bash
# A film of one scripted run from the player's view (issue #520): the game drawn under xvfb
# (lavapipe), Godot's Movie Maker at a fixed 30 fps (two physics steps a frame: game time runs true), the run as the game's own bridge script (it
# quits when done, so the AVI is closed), then an mp4.
#   experiments/farmhouse/film.sh WAY SEED OUT_DIR [SIZE] [MAX]   (MAX: game seconds, 200)
set -e
WAY=$1; SEED=$2; OUT=$3; SIZE=${4:-640x360}; MAX=${5:-200}
mkdir -p "$OUT"
SCRIPT="$OUT/film_${WAY}_s${SEED}.txt"
printf 'time 15\nfarm_run %s seed=%s max=%s out=%s\nquit\n' "$WAY" "$SEED" "$MAX" "$(realpath "$OUT")/film_${WAY}_s${SEED}.json" > "$SCRIPT"
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
xvfb-run -a -s "-screen 0 ${SIZE}x24" godot --path "$ROOT" --rendering-driver vulkan --resolution "$SIZE" --fixed-fps 30 \
    --write-movie "$(realpath "$OUT")/film_${WAY}_s${SEED}.avi" -- --dev-bridge --deterministic --bridge-port=8771 \
    --bridge-script="$(realpath "$SCRIPT")" > "$OUT/film_${WAY}_s${SEED}.log" 2>&1 || true
ffmpeg -v error -y -i "$OUT/film_${WAY}_s${SEED}.avi" -c:v libx264 -crf 28 -preset veryfast -pix_fmt yuv420p -c:a aac -b:a 96k \
    "$OUT/film_${WAY}_s${SEED}.mp4"
rm -f "$OUT/film_${WAY}_s${SEED}.avi"
echo "film: $OUT/film_${WAY}_s${SEED}.mp4"
