#!/bin/sh
# A film of the breach (step 2, #667): the rubble-stone panel, seeds 1-3, one stick at its foot,
# seen from the front, the side, high, and the back after (film.txt). Movie Maker at 30 fps on game
# time, then an mp4. Stills: stills.txt (front and back, before and after, each seed).
# Usage: experiments/masonry_lab/film.sh [OUTDIR] [WxH]
set -e
OUT=${1:-build/masonry_film}
SIZE=${2:-960x540}
mkdir -p "$OUT"
python3 tools/bridge.py run "$(dirname "$0")/film.txt" --size="$SIZE" --movie="$OUT/breach.avi" > "$OUT/film.log" 2>&1
ffmpeg -y -loglevel error -i "$OUT/breach.avi" -c:v libx264 -crf 24 -preset slow -pix_fmt yuv420p -an "$OUT/breach.mp4"
rm -f "$OUT/breach.avi"
