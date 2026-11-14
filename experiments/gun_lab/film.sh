#!/bin/sh
# A film of both guns in your hands, film.txt: the revolver cocked, three aimed shots, a full reload
# and one more; the coach gun cocked, both barrels, broken open and reloaded. Movie Maker (30 fps on
# game time, with the sound), then an mp4. film_shotgun.txt: the coach gun alone, from the hip,
# walking, aimed down the sights. Usage: experiments/gun_lab/film.sh [OUTDIR] [WxH] [SCRIPT]
set -e
OUT=${1:-build/gun_film}
SIZE=${2:-960x540}
SCRIPT=${3:-film}
mkdir -p "$OUT"
python3 tools/bridge.py run "$(dirname "$0")/$SCRIPT.txt" --size="$SIZE" --movie="$OUT/$SCRIPT.avi" > "$OUT/$SCRIPT.log" 2>&1
ffmpeg -y -loglevel error -i "$OUT/$SCRIPT.avi" -c:v libx264 -crf 24 -preset slow -pix_fmt yuv420p -c:a aac -b:a 96k "$OUT/$SCRIPT.mp4"
rm -f "$OUT/$SCRIPT.avi"
