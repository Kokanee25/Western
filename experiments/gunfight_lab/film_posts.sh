#!/bin/bash
# A film of one lab fight with the camera on the gang's men at the posts (issue #566): the fight as
# run.py runs it (D+, the careful player, golden hour, the revolver), drawn under xvfb (lavapipe),
# Godot's Movie Maker at a fixed 30 fps (two physics steps a frame: game time runs true), the camera
# `gf_postcam` (behind his shoulder while a man's at a post, else your eyes), then an mp4 and the
# cuts (`postcam` lines: frame, game s, man, on/off) beside it.
#   experiments/gunfight_lab/film_posts.sh SETUP SEED OPENING OUT_DIR [SIZE] [MAX]
#   (OPENING: they | shoot; MAX: game seconds of fight, 60)
set -e
SETUP=$1; SEED=$2; OPEN=$3; OUT=$4; SIZE=${5:-640x360}; MAX=${6:-60}
[ "$OPEN" = "they" ] && OPEN=""
NAME="${SETUP}_s${SEED}${OPEN:+_$OPEN}"
mkdir -p "$OUT"
OUT=$(realpath "$OUT")
SCRIPT="$OUT/$NAME.txt"
printf 'gf_postcam\ngf_fight %s hour=golden weapon=revolver style=careful bodies=studio seed=%s variant=D opening=%s fixes=all+pain_fight+floor_fight+odds+flinch max=%s out=%s\nquit\n' \
    "$SETUP" "$SEED" "$OPEN" "$MAX" "$OUT/$NAME.json" > "$SCRIPT"
ROOT=$(cd "$(dirname "$0")/../.." && pwd)
xvfb-run -a -s "-screen 0 ${SIZE}x24" godot --path "$ROOT" --rendering-driver vulkan --resolution "$SIZE" --fixed-fps 30 \
    --write-movie "$OUT/$NAME.avi" -- --dev-bridge --deterministic --bridge-port=${PORT:-8772} \
    --bridge-script="$SCRIPT" > "$OUT/$NAME.log" 2>&1 || true
grep "^postcam" "$OUT/$NAME.log" > "$OUT/$NAME.cuts" || true
ffmpeg -v error -y -i "$OUT/$NAME.avi" -c:v libx264 -crf 26 -preset veryfast -pix_fmt yuv420p -c:a aac -b:a 96k "$OUT/$NAME.mp4"
rm -f "$OUT/$NAME.avi"
echo "film: $OUT/$NAME.mp4"
